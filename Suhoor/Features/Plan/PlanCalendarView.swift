import SwiftUI

struct PlanCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var selectedDate = DateHelpers.startOfToday()
    @State private var showsAddSheet = false
    @State private var selectedSchedule: DaySchedule?

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacingM) {
                SuhoorCalendarView(
                    displayedMonth: $displayedMonth,
                    focusedDate: $selectedDate,
                    selectedDate: selectedDate,
                    allowedDateRange: allowedRange,
                    onSelectDate: { selectedDate = $0 }
                )
                .padding(.horizontal, DesignTokens.spacingL)

                SuhoorCalendarDetailCard(
                    detail: detail,
                    notScheduledText: "No special plan yet"
                )
                .padding(.horizontal, DesignTokens.spacingL)

                VStack(spacing: DesignTokens.spacingS) {
                    Button(primaryActionTitle) {
                        if let existingSchedule {
                            selectedSchedule = existingSchedule
                        } else {
                            showsAddSheet = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DawnColor.accent)

                    Text(primaryActionSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let secondaryActionTitle {
                        Button(secondaryActionTitle) {
                            triggerSecondaryAction()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingL)
            }
        }
        .navigationTitle("Plan by Date")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showsAddSheet) {
            NavigationStack {
                AddScheduleSheet(
                    isPresented: $showsAddSheet,
                    onOpenExistingDay: { date in
                        selectedDate = date
                        selectedSchedule = scheduleManager.schedule(for: date)
                    },
                    initialSelectedDate: selectedDate
                )
            }
        }
        .sheet(item: $selectedSchedule) { schedule in
            NavigationStack {
                AlarmDayDetailView(schedule: schedule)
            }
        }
    }

    private var detail: CalendarDayDetail {
        scheduleManager.calendarDayDetail(for: normalizedSelectedDate)
    }

    private var existingSchedule: DaySchedule? {
        scheduleManager.schedule(for: normalizedSelectedDate)
    }

    private var normalizedSelectedDate: Date {
        DateHelpers.startOfDay(selectedDate, in: .current)
    }

    private var primaryActionTitle: String {
        existingSchedule == nil ? "Plan This Date" : "Edit This Morning"
    }

    private var primaryActionSubtitle: String {
        if existingSchedule == nil {
            return "Use this for one-day changes, fasting days, and Qada dates."
        }
        return "Open this morning to adjust its wake, meaning, or source."
    }

    private var secondaryActionTitle: String? {
        guard detail.warnings.isEmpty else { return nil }
        if detail.computedPrimaryIntent == .other {
            return "Mark as Fasting Day"
        }
        return "Edit Day Meaning"
    }

    private func triggerSecondaryAction() {
        if detail.computedPrimaryIntent == .other {
            Task {
                let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])
                if existingSchedule != nil {
                    fastTagStore.setSelection(selection, for: normalizedSelectedDate, timeZone: .current)
                    selectedSchedule = scheduleManager.schedule(for: normalizedSelectedDate) ?? existingSchedule
                } else {
                    let result = await scheduleManager.addSingleScheduledDate(
                        normalizedSelectedDate,
                        selection: selection
                    )
                    if let date = result.addedDates.first {
                        selectedSchedule = scheduleManager.schedule(for: date)
                    }
                }
            }
        } else if let existingSchedule {
            selectedSchedule = existingSchedule
        } else {
            showsAddSheet = true
        }
    }

    private var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
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
