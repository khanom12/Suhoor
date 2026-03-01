import Foundation

enum FastSectionCategory: Int, CaseIterable {
    case ramadan
    case shawwal
    case muharram
    case dhulHijjah
    case other

    var displayTitle: String {
        switch self {
        case .ramadan:
            return "Ramadan"
        case .shawwal:
            return "Six of Shawwal"
        case .muharram:
            return "Muharram (Ashura)"
        case .dhulHijjah:
            return "Dhul Hijjah (Arafah)"
        case .other:
            return "Other"
        }
    }

    static var ordered: [FastSectionCategory] {
        [.ramadan, .shawwal, .muharram, .dhulHijjah, .other]
    }
}

struct FastSectionClassifier {
    static func shawwalFirstSixDayIdentifiers(for dates: [Date], timeZone: TimeZone) -> Set<String> {
        let calendar = islamicCalendar(timeZone: timeZone)
        let shawwalDates = dates.filter { date in
            calendar.dateComponents([.month], from: date).month == 10
        }
        let firstSix = shawwalDates.sorted().prefix(6)
        return Set(firstSix.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) })
    }

    static func category(
        for date: Date,
        shawwalFirstSixDayIdentifiers: Set<String>,
        timeZone: TimeZone,
        includeAshuraDay11: Bool = true
    ) -> FastSectionCategory {
        let components = hijriComponents(for: date, timeZone: timeZone)
        guard let month = components.month, let day = components.day else {
            return .other
        }

        if month == 9 {
            return .ramadan
        }

        if month == 10 {
            let identifier = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            return shawwalFirstSixDayIdentifiers.contains(identifier) ? .shawwal : .other
        }

        if month == 1 {
            let ashuraDays: Set<Int> = includeAshuraDay11 ? [9, 10, 11] : [9, 10]
            return ashuraDays.contains(day) ? .muharram : .other
        }

        if month == 12, day == 9 {
            return .dhulHijjah
        }

        return .other
    }

    private static func hijriComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        let calendar = islamicCalendar(timeZone: timeZone)
        return calendar.dateComponents([.month, .day], from: date)
    }

    private static func islamicCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        return calendar
    }
}
