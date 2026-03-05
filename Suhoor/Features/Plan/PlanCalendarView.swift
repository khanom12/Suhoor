import SwiftUI

struct PlanCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var selectedDate = DateHelpers.startOfToday()

    var body: some View {
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
                detail: scheduleManager.calendarDayDetail(for: selectedDate),
                notScheduledText: "Not scheduled"
            )
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.bottom, DesignTokens.spacingL)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
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
