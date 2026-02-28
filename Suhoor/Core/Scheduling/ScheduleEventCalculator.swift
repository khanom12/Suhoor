import Foundation

struct ScheduleEventCalculator {
    static func wakeDate(for fajrDate: Date, offsetMinutes: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .minute, value: -offsetMinutes, to: fajrDate) ?? fajrDate
    }

    static func reminderDate(for fajrDate: Date, reminderMinutes: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .minute, value: -reminderMinutes, to: fajrDate) ?? fajrDate
    }
}
