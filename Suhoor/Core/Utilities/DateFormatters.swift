import Foundation

final class HijriDateFormatter {
    static let shared = HijriDateFormatter()

    private let primaryFormatter: DateFormatter
    private let fallbackFormatter: DateFormatter

    private init() {
        primaryFormatter = DateFormatter()
        fallbackFormatter = DateFormatter()
        primaryFormatter.dateFormat = "d MMMM yyyy"
        fallbackFormatter.dateFormat = "d MMMM yyyy"
    }

    func string(from date: Date) -> String {
        let normalized = normalizedDate(for: date)
        configure(formatter: primaryFormatter, calendarIdentifier: .islamicUmmAlQura)
        let primaryText = primaryFormatter.string(from: normalized)
        if !primaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return primaryText
        }
        configure(formatter: fallbackFormatter, calendarIdentifier: .islamicCivil)
        return fallbackFormatter.string(from: normalized)
    }

    private func normalizedDate(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.startOfDay(for: date)
    }

    private func configure(formatter: DateFormatter, calendarIdentifier: Calendar.Identifier) {
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.timeZone = .current
        formatter.calendar = calendar
        formatter.timeZone = .current
        formatter.locale = Locale.current
    }
}

final class GregorianDateFormatter {
    static let shared = GregorianDateFormatter()

    private let headerFormatter: DateFormatter
    private let cardFormatter: DateFormatter

    private init() {
        headerFormatter = DateFormatter()
        cardFormatter = DateFormatter()
        headerFormatter.dateFormat = "EEE, MMM d, yyyy"
        cardFormatter.dateFormat = "EEE, MMM d"
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
