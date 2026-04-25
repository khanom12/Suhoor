import Foundation

enum SurfaceDateLabelFormatter {
    static func dayLabel(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return TimeFormatters.dayFormatter.string(from: date)
    }
}
