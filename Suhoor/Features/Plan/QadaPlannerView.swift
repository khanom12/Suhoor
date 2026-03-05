import SwiftUI

struct QadaPlannerView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @Environment(\.dismiss) private var dismiss

    @State private var baselineOwed: Int = 0
    @State private var scheduleCount: Int = 10
    @State private var strategy: QadaPlanStrategy = .focused
    @State private var avoidShawwal = true
    @State private var avoidMajorSunnah = true
    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var focusedDate = DateHelpers.startOfToday()
    @State private var recommendedKeys: Set<String> = []
    @State private var selectedKeys: Set<String> = []
    @State private var fallbackNote: String?
    @State private var isApplying = false

    var body: some View {
        let progress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )

        Form {
            Section {
                Stepper(value: $baselineOwed, in: 0...366) {
                    Text("Total Qada owed: \(baselineOwed)")
                }
                if progress.baselineOwed > 0 {
                    Text("\(progress.remaining) remaining")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Optional: set your backlog to track progress.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Backlog (Optional)")
            } footer: {
                Text("This does not affect scheduling. It's for tracking only.")
            }

            Section {
                Stepper(value: $scheduleCount, in: 1...maxScheduleCount) {
                    Text("Schedule now: \(scheduleCount) day\(scheduleCount == 1 ? "" : "s")")
                }

                Picker("Strategy", selection: $strategy) {
                    ForEach(QadaPlanStrategy.allCases) { strategy in
                        Text(strategy.title).tag(strategy)
                    }
                }
                Toggle("Avoid Shawwal", isOn: $avoidShawwal)
                Toggle("Avoid major Sunnah dates", isOn: $avoidMajorSunnah)
            } header: {
                Text("Schedule Qada")
            } footer: {
                Text(strategy.description)
            }

            Section {
                PlanMultiSelectCalendar(
                    displayedMonth: $displayedMonth,
                    allowedDateRange: allowedRange,
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
                        overrideSelection: FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
                    ),
                    notScheduledText: "Not scheduled for Qada"
                )
            }

            Section {
                if let fallbackNote {
                    Text(fallbackNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("\(selectedKeys.count)/\(scheduleCount) selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Suggest days") { regeneratePlan() }
                        .disabled(scheduleCount == 0)
                }

                Button(isApplying ? "Applying..." : "Add to schedule") {
                    Task { await applyPlan() }
                }
                .disabled(isApplying || scheduleCount == 0 || selectedKeys.count != scheduleCount)
            }
        }
        .navigationTitle("Qada Planner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            baselineOwed = qadaBacklogStore.state.baselineOwed
            syncScheduleCount(progress: progress)
            regeneratePlan()
        }
        .onChange(of: baselineOwed) { _, newValue in
            qadaBacklogStore.setBaseline(
                owed: newValue,
                trackingStartDateKey: qadaBacklogStore.state.trackingStartDateKey
            )
            syncScheduleCount(progress: progress)
            regeneratePlan()
        }
        .onChange(of: scheduleCount) { _, _ in regeneratePlan() }
        .onChange(of: strategy) { _, _ in regeneratePlan() }
        .onChange(of: avoidShawwal) { _, _ in regeneratePlan() }
        .onChange(of: avoidMajorSunnah) { _, _ in regeneratePlan() }
    }

    private var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
    }

    private var maxScheduleCount: Int {
        min(60, max(1, progressLimit()))
    }

    private func progressLimit() -> Int {
        let remaining = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        ).remaining
        return remaining > 0 ? remaining : 60
    }

    private func syncScheduleCount(progress: QadaProgressSnapshot) {
        let limit = progress.remaining > 0 ? min(progress.remaining, 60) : 60
        if scheduleCount <= 0 {
            scheduleCount = min(10, limit)
        } else {
            scheduleCount = min(scheduleCount, limit)
        }
    }

    private func regeneratePlan() {
        guard scheduleCount > 0 else {
            recommendedKeys = []
            selectedKeys = []
            fallbackNote = nil
            return
        }

        let options = QadaAutoPlanOptions(
            strategy: strategy,
            avoidShawwal: avoidShawwal,
            avoidMajorSunnah: avoidMajorSunnah
        )
        let existingDateKeys = existingScheduleKeys()
        let existingQadaKeys = existingQadaSelectionKeys()

        let result = QadaAutoPlanner.generate(
            desiredCount: scheduleCount,
            startDate: allowedRange.lowerBound,
            endDate: allowedRange.upperBound,
            options: options,
            existingDateKeys: existingDateKeys,
            existingQadaKeys: existingQadaKeys
        )

        let keys = Set(result.dates.map { DateHelpers.dayIdentifier(for: $0, timeZone: .current) })
        recommendedKeys = keys
        selectedKeys = keys
        fallbackNote = result.fallbackNote

        if let first = result.dates.first {
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
        guard selectedKeys.count < scheduleCount else { return }
        selectedKeys.insert(key)
    }

    private func isSelectable(_ date: Date) -> Bool {
        if FastIntentEngine.isForbiddenToFast(date, timeZone: .current) {
            return false
        }
        if FastIntentEngine.isRamadan(date, timeZone: .current) {
            return false
        }
        return true
    }

    private func existingScheduleKeys() -> Set<String> {
        let interval = DateInterval(start: allowedRange.lowerBound, end: allowedRange.upperBound)
        let entries = alarmConfigStore.resolvedScheduledEntries(in: interval, timeZone: .current)
        return Set(entries.map(\.dateKey))
    }

    private func existingQadaSelectionKeys() -> Set<String> {
        Set(fastTagStore.selections.compactMap { key, selection in
            selection.primaryIntent == .qadaMakeup ? key : nil
        })
    }

    private func applyPlan() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }

        let dateKeys = selectedKeys
        let dates = dateKeys.compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }

        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        _ = await scheduleManager.planDates(dates, selection: selection, groupID: nil)
        NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
        dismiss()
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
}
