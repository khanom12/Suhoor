import SwiftUI
import Combine

@MainActor
final class QadaPlanWizardViewModel: ObservableObject {
    @Published var step: QadaPlanWizardStep = .setup
    @Published var draft: QadaPlanDraft = .empty
    @Published var displayedMonth = DateHelpers.startOfToday()
    @Published var focusedDate = DateHelpers.startOfToday()
    @Published private(set) var progressSnapshot = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)
    @Published private(set) var recommendedKeys: Set<String> = []
    @Published private(set) var selectedKeys: Set<String> = []
    @Published private(set) var fallbackNote: String?
    @Published private(set) var lastGeneratedDates: [Date] = []
    @Published private(set) var hasGeneratedPlan = false
    @Published private(set) var isApplying = false
    @Published var isShowingSuccess = false
    @Published var shouldDismissFlow = false

    private weak var scheduleManager: ScheduleManager?
    private weak var alarmConfigStore: AlarmConfigStore?
    private weak var fastTagStore: FastTagStore?
    private weak var fastLogStore: FastLogStore?
    private weak var qadaBacklogStore: QadaBacklogStore?
    private var maintenanceService: QadaPlanMaintenanceService
    private var hasLoadedDefaults = false

    init() {
        self.maintenanceService = NoOpQadaPlanMaintenanceService()
    }

    init(maintenanceService: QadaPlanMaintenanceService) {
        self.maintenanceService = maintenanceService
    }

    var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
    }

    var maxPlanBatchCount: Int {
        min(60, max(1, progressSnapshot.remaining > 0 ? progressSnapshot.remaining : 60))
    }

    var planSummary: QadaPlanSummary {
        let sorted = selectedDates
        return QadaPlanSummary(
            plannedCount: selectedKeys.count,
            targetCount: draft.planBatchCount,
            startDate: sorted.first,
            finishDate: sorted.last,
            paceTitle: draft.pace.title,
            protectedSummary: protectedSummary
        )
    }

    var selectedDates: [Date] {
        selectedKeys
            .compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }
            .sorted()
    }

    var nextPlannedDate: Date? {
        selectedDates.first(where: { $0 >= DateHelpers.startOfToday() })
    }

    var canConfirmSchedule: Bool {
        selectedKeys.count == draft.planBatchCount && draft.planBatchCount > 0
    }

    var progressLineText: String? {
        guard progressSnapshot.baselineOwed > 0 || progressSnapshot.completed > 0 else { return nil }
        return "Completed: \(progressSnapshot.completed)  •  Remaining: \(progressSnapshot.remaining)"
    }

    var batchRecommendationText: String {
        if progressSnapshot.remaining > 0, progressSnapshot.remaining <= 10 {
            return "You can plan them all at once."
        }
        return "Most people start with 6-10 to keep it manageable."
    }

    var estimatedBatchFinishText: String? {
        let dates = previewBatchDates()
        guard let last = dates.last else { return nil }
        return weekdayFinishFormatter.string(from: last)
    }

    var protectedSummary: String {
        var items: [String] = []
        if draft.avoidShawwal {
            items.append("Shawwal")
        }
        if draft.avoidImportantSunnah {
            items.append("Sunnah days")
        }
        return items.isEmpty ? "None" : items.joined(separator: ", ")
    }

    var planSummaryProtectionChips: [String] {
        var chips: [String] = []
        if draft.avoidShawwal {
            chips.append("Shawwal protected")
        }
        if draft.avoidImportantSunnah {
            chips.append("Sunnah days protected")
        }
        return chips
    }

    var summaryDateRange: String? {
        let start = formattedDate(planSummary.startDate)
        let end = formattedDate(planSummary.finishDate)
        guard let start else { return end }
        guard let end else { return start }
        return start == end ? start : "\(start) – \(end)"
    }

    var fallbackDisplayCopy: String? {
        guard let fallbackNote else { return nil }

        switch fallbackNote {
        case let note where note.contains("major Sunnah"):
            return "To fit your target, the suggestion now includes a few important Sunnah dates. You can still adjust any of them below."
        case let note where note.contains("Shawwal"):
            return "To fit your target, the suggestion now reaches into Shawwal. You can keep it or edit the dates below."
        default:
            return "There were not enough open days to match your full target before Ramadan, so this plan uses the best available dates for now."
        }
    }

    func configure(
        scheduleManager: ScheduleManager,
        alarmConfigStore: AlarmConfigStore,
        fastTagStore: FastTagStore,
        fastLogStore: FastLogStore,
        qadaBacklogStore: QadaBacklogStore
    ) {
        self.scheduleManager = scheduleManager
        self.alarmConfigStore = alarmConfigStore
        self.fastTagStore = fastTagStore
        self.fastLogStore = fastLogStore
        self.qadaBacklogStore = qadaBacklogStore

        refreshProgressSnapshot()

        guard !hasLoadedDefaults else { return }
        hasLoadedDefaults = true

        draft.baselineOwed = qadaBacklogStore.state.baselineOwed
        draft.planBatchCount = smartDefaultBatchCount(for: progressSnapshot.remaining)
        clampPlanBatchCount()
    }

    func updateBaselineOwed(_ newValue: Int) {
        draft.baselineOwed = max(0, newValue)
        persistBaseline()
        refreshProgressSnapshot()
        clampPlanBatchCount()
    }

    func updateInputMode(_ mode: QadaPlanInputMode) {
        draft.inputMode = mode
    }

    func updatePace(_ pace: QadaPlanPace) {
        draft.pace = pace
    }

    func updateAvoidShawwal(_ isOn: Bool) {
        draft.avoidShawwal = isOn
    }

    func updateAvoidImportantSunnah(_ isOn: Bool) {
        draft.avoidImportantSunnah = isOn
    }

    func updatePlanBatchCount(_ newValue: Int) {
        draft.planBatchCount = newValue
        clampPlanBatchCount()
    }

    func createPlan() {
        clampPlanBatchCount()
        generatePlan()
        step = .review
    }

    func regeneratePlan() {
        generatePlan()
    }

    func editSetup() {
        step = .setup
    }

    func toggleDate(_ date: Date) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
            return
        }
        guard selectedKeys.count < draft.planBatchCount else { return }
        selectedKeys.insert(key)
    }

    func isSelectable(_ date: Date) -> Bool {
        if FastIntentEngine.isForbiddenToFast(date, timeZone: .current) {
            return false
        }
        if FastIntentEngine.isRamadan(date, timeZone: .current) {
            return false
        }
        return true
    }

    func detailCardData() -> CalendarDayDetail? {
        scheduleManager?.calendarDayDetail(
            for: focusedDate,
            overrideSelection: FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        )
    }

    func detailSelectionStatus() -> SuhoorCalendarSelectionStatus? {
        let detail = detailCardData()
        let key = DateHelpers.dayIdentifier(for: focusedDate, timeZone: .current)
        if selectedKeys.contains(key) {
            return SuhoorCalendarSelectionStatus(
                title: "Selected for Qada",
                reason: "This date is currently part of your batch.",
                color: DawnColor.accent
            )
        }
        if recommendedKeys.contains(key) {
            return SuhoorCalendarSelectionStatus(
                title: "Suggested for Qada",
                reason: "Matches your chosen pace and protected date settings.",
                color: DawnColor.lightGold200
            )
        }
        if let detail, detail.isAlreadyActive {
            return SuhoorCalendarSelectionStatus(
                title: "Already scheduled",
                reason: activeDetailReason(detail),
                color: detail.computedPrimaryIntent.style.color
            )
        }
        if !isSelectable(focusedDate) {
            let subtitle = FastIntentEngine.isRamadan(focusedDate, timeZone: .current)
                ? "This date falls in Ramadan, so fasting here is not part of Qada planning."
                : "Fasting is not allowed on this date."
            return SuhoorCalendarSelectionStatus(
                title: "Unavailable",
                reason: subtitle,
                color: FastPrimaryIntent.forbidden.style.color
            )
        }
        return SuhoorCalendarSelectionStatus(
            title: "Available to add",
            reason: detailCardReasonForAvailableDate(),
            color: DawnColor.highlight
        )
    }

    func applyPlan() async {
        guard !isApplying,
              canConfirmSchedule,
              let scheduleManager else { return }

        isApplying = true
        defer { isApplying = false }

        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        _ = await scheduleManager.planDates(selectedDates, selection: selection, groupID: nil)

        // TODO: when missed Qada logs are detected, use the maintenance service to suggest a replacement date.
        // TODO: Surface recovery support here: "You missed a planned Qada fast. Move it to the next available date?"
        _ = maintenanceService
        refreshProgressSnapshot()
        isShowingSuccess = true
    }

    func proceedToAlarms() {
        NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
        shouldDismissFlow = true
    }

    func finishFlow() {
        shouldDismissFlow = true
    }

    private func generatePlan() {
        guard draft.planBatchCount > 0 else {
            recommendedKeys = []
            selectedKeys = []
            lastGeneratedDates = []
            fallbackNote = nil
            hasGeneratedPlan = false
            return
        }

        let result = QadaAutoPlanner.generate(
            desiredCount: draft.planBatchCount,
            startDate: allowedRange.lowerBound,
            endDate: allowedRange.upperBound,
            options: QadaAutoPlanOptions(
                strategy: draft.pace.strategy,
                avoidShawwal: draft.avoidShawwal,
                avoidMajorSunnah: draft.avoidImportantSunnah
            ),
            existingDateKeys: existingScheduleKeys(),
            existingQadaKeys: existingQadaSelectionKeys()
        )

        let keys = Set(result.dates.map { DateHelpers.dayIdentifier(for: $0, timeZone: .current) })
        recommendedKeys = keys
        selectedKeys = keys
        lastGeneratedDates = result.dates.sorted()
        fallbackNote = result.fallbackNote
        hasGeneratedPlan = true

        if let first = result.dates.first {
            displayedMonth = monthStart(for: first)
            focusedDate = first
        } else {
            displayedMonth = monthStart(for: allowedRange.lowerBound)
            focusedDate = allowedRange.lowerBound
        }
    }

    private func refreshProgressSnapshot() {
        guard let qadaBacklogStore, let fastLogStore else { return }
        progressSnapshot = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func persistBaseline() {
        qadaBacklogStore?.setBaseline(
            owed: draft.baselineOwed,
            trackingStartDateKey: qadaBacklogStore?.state.trackingStartDateKey
        )
    }

    private func clampPlanBatchCount() {
        if draft.planBatchCount <= 0 {
            draft.planBatchCount = smartDefaultBatchCount(for: progressSnapshot.remaining)
        }
        draft.planBatchCount = min(max(1, draft.planBatchCount), maxPlanBatchCount)
    }

    private func smartDefaultBatchCount(for remaining: Int) -> Int {
        if remaining > 0 {
            return min(8, remaining)
        }
        return 6
    }

    private func existingScheduleKeys() -> Set<String> {
        guard let alarmConfigStore else { return [] }
        let interval = DateInterval(start: allowedRange.lowerBound, end: allowedRange.upperBound)
        let entries = alarmConfigStore.resolvedScheduledEntries(in: interval, timeZone: .current)
        return Set(entries.map(\.dateKey))
    }

    private func existingQadaSelectionKeys() -> Set<String> {
        guard let fastTagStore else { return [] }
        return Set(fastTagStore.selections.compactMap { key, selection in
            selection.primaryIntent == .qadaMakeup ? key : nil
        })
    }

    private func previewBatchDates() -> [Date] {
        guard draft.planBatchCount > 0 else { return [] }
        let result = QadaAutoPlanner.generate(
            desiredCount: draft.planBatchCount,
            startDate: allowedRange.lowerBound,
            endDate: allowedRange.upperBound,
            options: QadaAutoPlanOptions(
                strategy: draft.pace.strategy,
                avoidShawwal: draft.avoidShawwal,
                avoidMajorSunnah: draft.avoidImportantSunnah
            ),
            existingDateKeys: existingScheduleKeys(),
            existingQadaKeys: existingQadaSelectionKeys()
        )
        return result.dates.sorted()
    }

    private func detailCardReasonForAvailableDate() -> String {
        guard let detail = detailCardData() else {
            return "No conflicts or observances on this date."
        }
        if let tag = detail.previewSecondaryTags.first {
            return "This date overlaps with \(tag.shortTitle)."
        }
        return "No conflicts or observances on this date."
    }

    private func activeDetailReason(_ detail: CalendarDayDetail) -> String {
        if detail.computedPrimaryIntent == .qadaMakeup {
            return "This date is already scheduled for Qada."
        }
        return "This date is already scheduled as \(detail.computedPrimaryIntent.shortTitle)."
    }

    private func nextRamadanStart() -> Date {
        let calendar = AdjustedHijriCalendar.shared
        let now = Date()
        let components = calendar.adjustedComponents(for: now, timeZone: .current)
        let targetYear: Int
        if let components {
            if components.month == .ramadan {
                targetYear = components.hijriYear + 1
            } else if components.month.rawValue < HijriMonth.ramadan.rawValue {
                targetYear = components.hijriYear
            } else {
                targetYear = components.hijriYear + 1
            }
        } else {
            targetYear = Calendar(identifier: .islamicUmmAlQura).component(.year, from: now) + 1
        }
        let key = HijriYearMonth(hijriYear: targetYear, month: .ramadan)
        return calendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: .current) ?? now
    }

    private func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return GregorianDateFormatter.shared.headerString(for: date)
    }

    private var weekdayFinishFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }
}
