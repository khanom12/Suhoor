import SwiftUI

struct ShawwalPlannerView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @Environment(\.dismiss) private var dismiss

    @State private var strategy: ShawwalPlanStrategy = .maximizeReward
    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var focusedDate = DateHelpers.startOfToday()
    @State private var recommendedKeys: Set<String> = []
    @State private var selectedKeys: Set<String> = []
    @State private var isApplying = false
    @State private var cachedRemaining: Int = 6

    var body: some View {
        let model = shawwalModel()
        let remaining = model?.remainingCount ?? cachedRemaining

        Form {
            Section {
                Picker("Strategy", selection: $strategy) {
                    ForEach(ShawwalPlanStrategy.allCases) { strategy in
                        Text(strategy.title).tag(strategy)
                    }
                }
                .pickerStyle(.segmented)

                Text(strategy.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Shawwal 6")
            } footer: {
                if let model {
                    Text(model.isComplete ? "All six are complete." : "\(model.remainingCount) remaining in Shawwal \(model.hijriYear).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                PlanMultiSelectCalendar(
                    displayedMonth: $displayedMonth,
                    allowedDateRange: shawwalRange(),
                    selectedDateKeys: selectedKeys,
                    recommendedDateKeys: recommendedKeys,
                    disablesAlreadyActive: false,
                    isSelectable: isSelectable(_:),
                    onToggle: toggleDate(_:),
                    focusedDate: $focusedDate)
            }

            Section {
                SuhoorCalendarDetailCard(
                    detail: scheduleManager.calendarDayDetail(
                        for: focusedDate,
                        overrideSelection: FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])
                    ),
                    notScheduledText: "Not scheduled for Shawwal"
                )
            }

            Section {
                HStack {
                    Text("\(selectedKeys.count)/\(remaining) selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Regenerate") { regeneratePlan(remaining: remaining) }
                        .disabled(remaining == 0)
                }
            }

            Section {
                Button(isApplying ? "Applying..." : "Add Shawwal Days") {
                    Task { await applyPlan() }
                }
                .disabled(isApplying || remaining == 0 || selectedKeys.count != remaining)
            }
        }
        .navigationTitle("Shawwal Planner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cachedRemaining = max(1, model?.remainingCount ?? 6)
            regeneratePlan(remaining: remaining)
        }
        .onChange(of: strategy) { _, _ in
            regeneratePlan(remaining: remaining)
        }
    }

    private func shawwalModel() -> ShawwalSixProgressEngine.Model? {
        let now = Date()
        let mode: TodaySeasonalCardMode = isLiveShawwalDay() ? .live : .reference
        guard let monthKey = targetShawwalMonthKey() else { return nil }
        let entries = alarmConfigStore.resolvedScheduledEntries(forHijriMonth: monthKey, timeZone: .current)
        return ShawwalSixProgressEngine.model(
            now: now,
            mode: mode,
            scheduledEntries: entries,
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func isLiveShawwalDay() -> Bool {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: Date(), timeZone: .current) else { return false }
        return components.month == .shawwal && components.day >= 2
    }

    private func targetShawwalMonthKey() -> HijriYearMonth? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: Date(), timeZone: .current) else {
            return nil
        }
        let targetYear = components.month.rawValue <= HijriMonth.shawwal.rawValue
            ? components.hijriYear
            : components.hijriYear + 1
        return HijriYearMonth(hijriYear: targetYear, month: .shawwal)
    }

    private func shawwalDates() -> [Date] {
        guard let monthKey = targetShawwalMonthKey() else { return [] }
        let calendar = AdjustedHijriCalendar.shared
        let days = (2...30).compactMap {
            calendar.gregorianDate(for: monthKey, dayOfMonth: $0, timeZone: .current)
        }
        return days
    }

    private func shawwalRange() -> ClosedRange<Date> {
        let dates = shawwalDates()
        guard let start = dates.first, let end = dates.last else {
            let today = DateHelpers.startOfToday()
            return today...today
        }
        return start...end
    }

    private func regeneratePlan(remaining: Int) {
        guard remaining > 0 else {
            recommendedKeys = []
            selectedKeys = []
            return
        }
        let eligibleDates = shawwalDates().filter { isSelectable($0) }
        let result = ShawwalAutoPlanner.generate(
            dates: eligibleDates,
            desiredCount: remaining,
            strategy: strategy
        )
        let keys = Set(result.map { DateHelpers.dayIdentifier(for: $0, timeZone: .current) })
        recommendedKeys = keys
        selectedKeys = keys
        if let first = result.first {
            displayedMonth = monthStart(for: first)
            focusedDate = first
        }
    }

    private func toggleDate(_ date: Date) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
            return
        }
        guard selectedKeys.count < cachedRemaining else { return }
        selectedKeys.insert(key)
    }

    private func isSelectable(_ date: Date) -> Bool {
        if FastIntentEngine.isForbiddenToFast(date, timeZone: .current) {
            return false
        }
        if let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: .current),
           components.month != .shawwal || components.day == 1 {
            return false
        }
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        let status = fastLogStore.status(for: key)
        if status == .completed || status == .inProgress {
            return false
        }
        if fastTagStore.selection(for: date, timeZone: .current)?.primaryIntent == .qadaMakeup {
            return false
        }
        return true
    }

    private func applyPlan() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }

        let dates = selectedKeys.compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])
        _ = await scheduleManager.planDates(dates, selection: selection, groupID: nil)
        NotificationCenter.default.post(name: .switchToWakeTab, object: nil)
        dismiss()
    }

    private func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
