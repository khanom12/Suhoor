import Foundation

final class HijriDateFormatter {
    static let shared = HijriDateFormatter()

    private let adjustedHijriCalendar: AdjustedHijriCalendar

    init(adjustedHijriCalendar: AdjustedHijriCalendar = .shared) {
        self.adjustedHijriCalendar = adjustedHijriCalendar
    }

    func string(from date: Date) -> String {
        let normalized = normalizedDate(for: date)
        return adjustedHijriCalendar.formattedHijriString(for: normalized, timeZone: .current)
    }

    private func normalizedDate(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.startOfDay(for: date)
    }
}

final class GregorianDateFormatter {
    static let shared = GregorianDateFormatter()

    private let headerFormatter: DateFormatter
    private let cardFormatter: DateFormatter
    private let monthYearFormatter: DateFormatter

    private init() {
        headerFormatter = DateFormatter()
        cardFormatter = DateFormatter()
        monthYearFormatter = DateFormatter()
        headerFormatter.dateFormat = "EEE, MMM d, yyyy"
        cardFormatter.dateFormat = "EEE, MMM d"
        monthYearFormatter.dateFormat = "MMMM yyyy"
    }

    func headerString(for date: Date) -> String {
        let normalized = normalizedDate(for: date)
        configure(formatter: headerFormatter)
        return headerFormatter.string(from: normalized)
    }

    func cardString(for date: Date) -> String {
        let normalized = normalizedDate(for: date)
        configure(formatter: cardFormatter)
        return cardFormatter.string(from: normalized)
    }

    func monthYearString(for date: Date) -> String {
        let normalized = normalizedDate(for: date)
        configure(formatter: monthYearFormatter)
        return monthYearFormatter.string(from: normalized)
    }

    private func normalizedDate(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.startOfDay(for: date)
    }

    private func configure(formatter: DateFormatter) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        formatter.calendar = calendar
        formatter.timeZone = .current
        formatter.locale = Locale.current
    }
}
