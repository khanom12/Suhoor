import SwiftUI

struct PlanOthersView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    @State private var purpose: FastPrimaryIntent = .voluntary
    @State private var scheduleCount: Int = 1
    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var selectedKeys: Set<String> = []
    @State private var isApplying = false

    var body: some View {
        Form {
            Section("Purpose") {
                Picker("Purpose", selection: $purpose) {
                    Text("Voluntary").tag(FastPrimaryIntent.voluntary)
                    Text("Vow (Nadhr)").tag(FastPrimaryIntent.vowNadhr)
                    Text("Kaffarah").tag(FastPrimaryIntent.kaffarahExpiation)
                    Text("Other").tag(FastPrimaryIntent.other)
                }
            }

            Section("Schedule") {
                Stepper(value: $scheduleCount, in: 1...60) {
                    Text("Schedule now: \(scheduleCount) day\(scheduleCount == 1 ? "" : "s")")
                }
            }

            Section {
                PlanMultiSelectCalendar(
                    displayedMonth: $displayedMonth,
                    allowedDateRange: allowedRange,
                    selectedDateKeys: selectedKeys,
                    recommendedDateKeys: [],
                    disablesAlreadyActive: false,
                    isSelectable: isSelectable(_:),
                    onToggle: toggleDate(_:))
            }

            Section {
                HStack {
                    Text("\(selectedKeys.count)/\(scheduleCount) selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Button(isApplying ? "Applying..." : "Add to schedule") {
                    Task { await applyPlan() }
                }
                .disabled(isApplying || selectedKeys.count != scheduleCount)
            } footer: {
                Text("Selecting an already scheduled day updates its purpose without duplicating alarms.")
            }
        }
        .navigationTitle("Other Fasts")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scheduleCount) { _, _ in
            if selectedKeys.count > scheduleCount {
                selectedKeys = Set(selectedKeys.prefix(scheduleCount))
            }
        }
    }

    private var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
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

    private func applyPlan() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }

        let dates = selectedKeys.compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: .current) }
        let selection = FastIntentSelection(primaryIntent: purpose, secondaryTags: [])
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
}
