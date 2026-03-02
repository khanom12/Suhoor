import Foundation

enum HijriBaselineMonthStarts {
    private struct StaticEntry {
        let key: HijriYearMonth
        let year: Int
        let month: Int
        let day: Int
        let source: String
    }

    private static let entries: [StaticEntry] = [
        StaticEntry(key: HijriYearMonth(hijriYear: 1447, month: .muharram), year: 2025, month: 6, day: 26, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1447, month: .ramadan), year: 2026, month: 2, day: 18, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1447, month: .shawwal), year: 2026, month: 3, day: 20, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1447, month: .dhulHijjah), year: 2026, month: 5, day: 18, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1448, month: .muharram), year: 2026, month: 6, day: 16, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1448, month: .ramadan), year: 2027, month: 2, day: 8, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1448, month: .shawwal), year: 2027, month: 3, day: 9, source: "LocalTable"),
        StaticEntry(key: HijriYearMonth(hijriYear: 1448, month: .dhulHijjah), year: 2027, month: 5, day: 7, source: "LocalTable")
    ]

    static let supportedHijriYears: [Int] = [1447, 1448]

    static func starts(for hijriYear: Int, timeZone: TimeZone) -> [HijriMonthBaselineStart] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return entries.compactMap { entry in
            guard entry.key.hijriYear == hijriYear else { return nil }
            let components = DateComponents(year: entry.year, month: entry.month, day: entry.day)
            guard let date = calendar.date(from: components) else { return nil }
            return HijriMonthBaselineStart(
                key: entry.key,
                gregorianStartDate: calendar.startOfDay(for: date),
                source: entry.source,
                generatedAt: nil
            )
        }
    }

    static func contains(_ key: HijriYearMonth) -> Bool {
        entries.contains { $0.key == key }
    }
}
