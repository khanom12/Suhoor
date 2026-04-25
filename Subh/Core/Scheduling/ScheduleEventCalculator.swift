import Foundation

struct ScheduleEventCalculator {
    static func reminderDate(for fajrDate: Date, reminderMinutes: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .minute, value: -reminderMinutes, to: fajrDate) ?? fajrDate
    }
}
