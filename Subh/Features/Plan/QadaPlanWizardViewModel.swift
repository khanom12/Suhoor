import SwiftUI
import Combine

@MainActor
final class QadaPlanWizardViewModel: ObservableObject {
    @Published var step: QadaPlanWizardStep = .setup
    @Published var setupPage: QadaSetupPage
    @Published var draft: QadaPlanDraft = .empty
    @Published var displayedMonth = DateHelpers.startOfToday()
    @Published var focusedDate = DateHelpers.startOfToday()
    @Published var scrollResetToken = UUID()
    @Published private(set) var progressSnapshot = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)
    @Published private(set) var backlogSuggestion: QadaBacklogSuggestion?
    @Published private(set) var sortedSelectedDates: [Date] = []
    @Published private(set) var recommendedKeys: Set<String> = []
    @Published private(set) var selectedKeys: Set<String> = []
    @Published private(set) var fallbackNote: String?
    @Published private(set) var lastGeneratedDates: [Date] = []
    @Published private(set) var estimatedBatchFinishText: String?
    @Published private(set) var hasGeneratedPlan = false
    @Published private(set) var isApplying = false
    @Published var isShowingSuccess = false
    @Published var shouldDismissFlow = false
    @Published var isShowingDateDetail = false
    @Published private(set) var focusedDateDetail: CalendarDayDetail?
    @Published private(set) var focusedDateSelectionStatus: SuhoorCalendarSelectionStatus?

    private weak var scheduleManager: ScheduleManager?
    private weak var alarmConfigStore: AlarmConfigStore?
    private weak var fastTagStore: FastTagStore?
    private weak var fastLogStore: FastLogStore?
    private weak var qadaBacklogStore: QadaBacklogStore?
    private weak var qadaBatchStore: QadaBatchStore?
    private var maintenanceService: QadaPlanMaintenanceService
    private let launchMode: QadaWizardLaunchMode
    private var hasLoadedDefaults = false
    private var batchKeysBeingEdited: Set<String> = []
    private var cachedExistingScheduleKeys: Set<String> = []
    private var cachedExistingQadaSelectionKeys: Set<String> = []

    init(
        launchMode: QadaWizardLaunchMode = .fresh,
        maintenanceService: QadaPlanMaintenanceService? = nil
    ) {
        self.launchMode = launchMode
        self.maintenanceService = maintenanceService ?? NoOpQadaPlanMaintenanceService()
        self.setupPage = launchMode.initialSetupPage
    }

    var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
    }

    var maxPlanBatchCount: Int {
        let remainingCeiling = progressSnapshot.remaining > 0 ? progressSnapshot.remaining : 60
        let trackedBatchCeiling = max(batchKeysBeingEdited.count, qadaBatchStore?.state.targetCount ?? 0)
        return min(60, max(1, max(remainingCeiling, trackedBatchCeiling)))
    }

    var navigationTitle: String {
        step == .review ? "Your plan" : "Plan Your Qada"
    }

    var setupProgressText: String {
        "\(setupPage.rawValue + 1) of \(QadaSetupPage.allCases.count)"
    }

    var setupTitle: String {
        switch setupPage {
        case .intake:
            return "What do you need to make up?"
        case .pace:
            return "Choose your pace"
        case .preferences:
            return "Set your preferences"
        }
    }

    var setupSubtitle: String {
        switch setupPage {
        case .intake:
            return "Start with what you know. You can refine this later."
        case .pace:
            return "Pick the rhythm that feels most realistic."
        case .preferences:
            return "We’ll use these to build a clean starting batch."
        }
    }

    var setupPrimaryActionTitle: String {
        setupPage == .preferences ? "Build my Qada plan" : "Continue"
    }

    var canReturnToSetupFromReview: Bool {
        !launchMode.startsInReview
    }

    var planSummary: QadaPlanSummary {
        return QadaPlanSummary(
            plannedCount: selectedKeys.count,
            targetCount: draft.planBatchCount,
            startDate: sortedSelectedDates.first,
            finishDate: sortedSelectedDates.last,
            paceTitle: draft.pace.title,
            protectedSummary: protectedSummary
        )
    }

    var selectedDates: [Date] {
        sortedSelectedDates
    }

    var nextPlannedDate: Date? {
        selectedDates.first(where: { $0 >= DateHelpers.startOfToday() })
    }

    var canConfirmSchedule: Bool {
        selectedKeys.count == draft.planBatchCount && draft.planBatchCount > 0
    }

    var progressLineText: String? {
        guard progressSnapshot.baselineOwed > 0 || progressSnapshot.completed > 0 else { return nil }
        let remainingText = "Remaining: \(progressSnapshot.remaining)"
        guard progressSnapshot.completed > 0 else { return remainingText }
        return "Completed: \(progressSnapshot.completed)  •  \(remainingText)"
    }

    var intakeSuggestionHelperText: String? {
        guard let backlogSuggestion else { return nil }
        guard draft.baselineOwed > 0 else { return nil }
        return "Ramadan check-ins suggest about \(backlogSuggestion.suggestedOwed) fasts to make up. Keep or adjust this total as needed."
    }

    var batchRecommendationText: String {
        if progressSnapshot.remaining > 0, progressSnapshot.remaining <= 3 {
            return "You can plan them all at once."
        }
        return "Many people start with 1–3 so it feels easier to keep going."
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
            return "To fit your target, this suggestion includes a few important Sunnah dates. You can still change any of them below."
        case let note where note.contains("Shawwal"):
            return "To fit your target, this suggestion reaches into Shawwal. You can keep it or adjust it below."
        default:
            return "There were not enough open days before Ramadan to match your full target, so this plan uses the best dates available for now."
        }
    }

    var protectedDatesHelperText: String {
        "We’ll avoid these when suggesting dates. You can still choose them yourself."
    }

    func configure(
        scheduleManager: ScheduleManager,
        alarmConfigStore: AlarmConfigStore,
        fastTagStore: FastTagStore,
        fastLogStore: FastLogStore,
        qadaBacklogStore: QadaBacklogStore,
        qadaBatchStore: QadaBatchStore
    ) {
        self.scheduleManager = scheduleManager
        self.alarmConfigStore = alarmConfigStore
        self.fastTagStore = fastTagStore
        self.fastLogStore = fastLogStore
        self.qadaBacklogStore = qadaBacklogStore
        self.qadaBatchStore = qadaBatchStore

        refreshProgressSnapshot()
        backlogSuggestion = QadaBacklogSuggestionEngine.currentRamadanSuggestion(logEntries: fastLogStore.entriesByDateKey)

        guard !hasLoadedDefaults else { return }
        hasLoadedDefaults = true

        draft.baselineOwed = qadaBacklogStore.state.baselineOwed

        if qadaBatchStore.state.targetCount > 0 {
            draft.pace = qadaBatchStore.state.pace
            draft.avoidShawwal = qadaBatchStore.state.avoidShawwal
            draft.avoidImportantSunnah = qadaBatchStore.state.avoidImportantSunnah
            draft.planBatchCount = qadaBatchStore.state.targetCount
        } else {
            draft.planBatchCount = smartDefaultBatchCount(for: progressSnapshot.remaining)
        }
        clampPlanBatchCount()

        switch launchMode {
        case .fresh:
            step = .setup
            setupPage = .intake
        case .adjustTotal:
            step = .setup
            setupPage = .intake
        case .nextBatch:
            step = .setup
            setupPage = .pace
            draft.planBatchCount = smartDefaultBatchCount(for: progressSnapshot.remaining)
        case .reviewCurrentBatch, .recoverMissedDay:
            if !loadExistingBatch() {
                step = .setup
                setupPage = .intake
            }
        }

        refreshAvailabilityCaches()
        refreshPreviewData()
        refreshFocusedDateDetailIfNeeded()
        resetScrollPosition()
    }

    func updateBaselineOwed(_ newValue: Int) {
        draft.baselineOwed = max(0, newValue)
        persistBaseline()
        refreshProgressSnapshot()
        clampPlanBatchCount()
        refreshPreviewData()
    }

    func useSuggestedBacklog() {
        guard let backlogSuggestion else { return }
        draft.baselineOwed = backlogSuggestion.suggestedOwed
        persistBaseline()
        refreshProgressSnapshot()
        clampPlanBatchCount()
        refreshPreviewData()
    }

    func updatePace(_ pace: QadaPlanPace) {
        draft.pace = pace
        refreshPreviewData()
    }

    func updateAvoidShawwal(_ isOn: Bool) {
        draft.avoidShawwal = isOn
        refreshPreviewData()
    }

    func updateAvoidImportantSunnah(_ isOn: Bool) {
        draft.avoidImportantSunnah = isOn
        refreshPreviewData()
    }

    func updatePlanBatchCount(_ newValue: Int) {
        draft.planBatchCount = newValue
        clampPlanBatchCount()
        refreshPreviewData()
    }

    func advanceSetup() {
        switch setupPage {
        case .intake:
            setupPage = .pace
        case .pace:
            setupPage = .preferences
        case .preferences:
            createPlan()
            return
        }
        resetScrollPosition()
    }

    func goBackWithinFlow() -> Bool {
        switch step {
        case .review:
            guard canReturnToSetupFromReview else { return false }
            step = .setup
            setupPage = .preferences
            resetScrollPosition()
            return true
        case .setup:
            switch setupPage {
            case .preferences:
                setupPage = .pace
            case .pace:
                setupPage = .intake
            case .intake:
                return false
            }
            resetScrollPosition()
            return true
        }
    }

    func createPlan() {
        clampPlanBatchCount()
        refreshAvailabilityCaches()
        generatePlan()
        step = .review
        resetScrollPosition()
    }

    func regeneratePlan() {
        refreshAvailabilityCaches()
        generatePlan()
        resetScrollPosition()
    }

    func editSetup() {
        step = .setup
        setupPage = .preferences
        resetScrollPosition()
    }

    func toggleDate(_ date: Date) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
            syncSelectedDates()
            return
        }
        guard selectedKeys.count < draft.planBatchCount else { return }
        guard isSelectable(date) || batchKeysBeingEdited.contains(key) else { return }
        selectedKeys.insert(key)
        syncSelectedDates()
    }

    func openDateDetail(for date: Date) {
        focusedDate = date
        refreshFocusedDateDetail()
        isShowingDateDetail = true
    }

    func dismissDateDetail() {
        isShowingDateDetail = false
        focusedDateDetail = nil
        focusedDateSelectionStatus = nil
    }

    func isSelectable(_ date: Date) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        if FastIntentEngine.isForbiddenToFast(date, timeZone: .current) {
            return false
        }
        if FastIntentEngine.isRamadan(date, timeZone: .current) {
            return false
        }
        if batchKeysBeingEdited.contains(key) {
            return true
        }
        return !cachedExistingScheduleKeys.contains(key)
    }

    func detailCardData() -> CalendarDayDetail? {
        focusedDateDetail
    }

    func detailSelectionStatus() -> SuhoorCalendarSelectionStatus? {
        focusedDateSelectionStatus
    }

    func applyPlan() async {
        guard !isApplying,
              canConfirmSchedule,
              let scheduleManager else { return }

        isApplying = true
        defer { isApplying = false }

        let removedKeys = batchKeysBeingEdited.subtracting(selectedKeys)
        for key in removedKeys {
            guard let date = DateHelpers.date(fromDayIdentifier: key, timeZone: .current) else { continue }
            await scheduleManager.deleteExplicitScheduledDate(date)
            fastTagStore?.removeSelection(for: date, timeZone: .current)
        }

        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        _ = await scheduleManager.planDates(selectedDates, selection: selection, groupID: nil)

        qadaBatchStore?.saveBatch(dateKeys: selectedKeys, draft: draft)
        persistBaseline()

        // TODO: when missed Qada logs are detected, use the maintenance service to suggest a replacement date.
        // TODO: Surface recovery support here: "One planned Qada day still needs to be rescheduled. Move it to the next available date?"
        _ = maintenanceService

        refreshProgressSnapshot()
        isShowingSuccess = true
    }

    func proceedToAlarms() {
        AppNavigationBridge.send(.switchToWake)
        shouldDismissFlow = true
    }

    func finishFlow() {
        shouldDismissFlow = true
    }

    private func loadExistingBatch() -> Bool {
        guard let qadaBatchStore, !qadaBatchStore.state.plannedDateKeys.isEmpty else { return false }
        let state = qadaBatchStore.state
        batchKeysBeingEdited = state.plannedDateKeys
        selectedKeys = state.plannedDateKeys
        syncSelectedDates()
        recommendedKeys = state.plannedDateKeys
        draft.planBatchCount = max(state.targetCount, state.plannedDateKeys.count)
        draft.pace = state.pace
        draft.avoidShawwal = state.avoidShawwal
        draft.avoidImportantSunnah = state.avoidImportantSunnah
        hasGeneratedPlan = true
        lastGeneratedDates = sortedSelectedDates
        step = .review

        let preferredFocusDate = recoveryFocusDate() ?? nextPlannedDate ?? sortedSelectedDates.first ?? allowedRange.lowerBound
        focusedDate = preferredFocusDate
        displayedMonth = monthStart(for: preferredFocusDate)
        refreshFocusedDateDetailIfNeeded()
        return true
    }

    private func generatePlan() {
        guard draft.planBatchCount > 0 else {
            recommendedKeys = []
            selectedKeys = []
            sortedSelectedDates = []
            lastGeneratedDates = []
            fallbackNote = nil
            estimatedBatchFinishText = nil
            hasGeneratedPlan = false
            return
        }

        let result = makeAutoPlanResult()

        let keys = Set(result.dates.map { DateHelpers.dayIdentifier(for: $0, timeZone: .current) })
        recommendedKeys = keys
        selectedKeys = keys
        let sortedDates = result.dates.sorted()
        sortedSelectedDates = sortedDates
        lastGeneratedDates = sortedDates
        fallbackNote = result.fallbackNote
        hasGeneratedPlan = true
        estimatedBatchFinishText = sortedDates.last.map { Self.weekdayFinishFormatter.string(from: $0) }

        if let first = result.dates.first {
            displayedMonth = monthStart(for: first)
            focusedDate = first
        } else {
            displayedMonth = monthStart(for: allowedRange.lowerBound)
            focusedDate = allowedRange.lowerBound
        }
        refreshFocusedDateDetailIfNeeded()
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
            return min(3, remaining)
        }
        return 3
    }

    private func computeExistingScheduleKeys() -> Set<String> {
        guard let alarmConfigStore else { return [] }
        let interval = DateInterval(start: allowedRange.lowerBound, end: allowedRange.upperBound)
        let entries = alarmConfigStore.resolvedScheduledEntries(in: interval, timeZone: .current)
        let keys = Set(entries.map(\.dateKey))
        return keys.subtracting(batchKeysBeingEdited)
    }

    private func computeExistingQadaSelectionKeys() -> Set<String> {
        guard let fastTagStore else { return [] }
        let keys = Set(fastTagStore.selections.compactMap { key, selection in
            selection.primaryIntent == .qadaMakeup ? key : nil
        })
        return keys.subtracting(batchKeysBeingEdited)
    }

    private func refreshAvailabilityCaches() {
        cachedExistingScheduleKeys = computeExistingScheduleKeys()
        cachedExistingQadaSelectionKeys = computeExistingQadaSelectionKeys()
    }

    private func refreshPreviewData() {
        guard hasLoadedDefaults else { return }
        guard draft.planBatchCount > 0 else {
            estimatedBatchFinishText = nil
            return
        }
        let result = makeAutoPlanResult()
        let sortedDates = result.dates.sorted()
        estimatedBatchFinishText = sortedDates.last.map { Self.weekdayFinishFormatter.string(from: $0) }
    }

    private func makeAutoPlanResult() -> QadaAutoPlanResult {
        QadaAutoPlanner.generate(
            desiredCount: draft.planBatchCount,
            startDate: allowedRange.lowerBound,
            endDate: allowedRange.upperBound,
            options: QadaAutoPlanOptions(
                strategy: draft.pace.strategy,
                avoidShawwal: draft.avoidShawwal,
                avoidMajorSunnah: draft.avoidImportantSunnah
            ),
            existingDateKeys: cachedExistingScheduleKeys,
            existingQadaKeys: cachedExistingQadaSelectionKeys
        )
    }

    private func recoveryFocusDate() -> Date? {
        guard launchMode == .recoverMissedDay,
              let fastLogStore,
              let qadaBatchStore else { return nil }
        let todayKey = DateHelpers.dayIdentifier(for: DateHelpers.startOfToday(), timeZone: .current)
        let completedKeys = fastLogStore.entriesByDateKey.reduce(into: Set<String>()) { partialResult, item in
            let (key, entry) = item
            guard entry.status == .completed,
                  entry.intentSnapshot?.primaryIntent == .qadaMakeup,
                  qadaBatchStore.state.plannedDateKeys.contains(key) else {
                return
            }
            partialResult.insert(key)
        }
        return qadaBatchStore.state.plannedDateKeys
            .subtracting(completedKeys)
            .filter { $0 < todayKey }
            .compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }
            .sorted()
            .first
    }

    private func detailCardReasonForAvailableDate(_ detail: CalendarDayDetail?) -> String {
        guard let detail else {
            return "No conflicts or observances on this date."
        }
        if let tag = detail.previewSecondaryTags.first {
            return "This date is open for Qada. It also coincides with \(tag.shortTitle) if you want to keep that in mind."
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

    private func syncSelectedDates() {
        sortedSelectedDates = selectedKeys
            .compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }
            .sorted()
    }

    private func refreshFocusedDateDetailIfNeeded() {
        guard isShowingDateDetail else { return }
        refreshFocusedDateDetail()
    }

    private func refreshFocusedDateDetail() {
        guard let scheduleManager else {
            focusedDateDetail = nil
            focusedDateSelectionStatus = nil
            return
        }

        let detail = scheduleManager.calendarDayDetail(
            for: focusedDate,
            overrideSelection: FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        )
        focusedDateDetail = detail
        focusedDateSelectionStatus = buildSelectionStatus(for: detail)
    }

    private func buildSelectionStatus(for detail: CalendarDayDetail) -> SuhoorCalendarSelectionStatus {
        let key = DateHelpers.dayIdentifier(for: focusedDate, timeZone: .current)
        if selectedKeys.contains(key) {
            return SuhoorCalendarSelectionStatus(
                title: "Selected for Qada",
                detailLabel: "Why",
                reason: "This date is currently part of your batch.",
                color: DawnColor.accent
            )
        }
        if recommendedKeys.contains(key) {
            return SuhoorCalendarSelectionStatus(
                title: "Suggested for Qada",
                detailLabel: "Why this date was suggested",
                reason: "It matches your chosen pace and protected-date settings.",
                color: DawnColor.lightGold200
            )
        }
        if detail.isAlreadyActive {
            return SuhoorCalendarSelectionStatus(
                title: "Already scheduled",
                detailLabel: "Why",
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
                detailLabel: "Why",
                reason: subtitle,
                color: FastPrimaryIntent.forbidden.style.color
            )
        }
        return SuhoorCalendarSelectionStatus(
            title: "Available to add",
            detailLabel: "Why this date works",
            reason: detailCardReasonForAvailableDate(detail),
            color: DawnColor.highlight
        )
    }

    private func resetScrollPosition() {
        scrollResetToken = UUID()
    }

    private static let weekdayFinishFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()
}
