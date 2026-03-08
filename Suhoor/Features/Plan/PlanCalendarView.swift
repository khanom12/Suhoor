import SwiftUI

struct PlanCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

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
