import Foundation

enum QadaBacklogSuggestionEngine {
    static func currentRamadanSuggestion(
        logEntries: [String: FastLogEntry],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> QadaBacklogSuggestion? {
        let calendar = AdjustedHijriCalendar.shared
        let targetYear = mostRecentRamadanYear(now: now, calendar: calendar, timeZone: timeZone)
        let ramadanKey = HijriYearMonth(hijriYear: targetYear, month: .ramadan)
        let shawwalKey = HijriYearMonth(hijriYear: targetYear, month: .shawwal)

        guard let ramadanStart = calendar.gregorianDate(for: ramadanKey, dayOfMonth: 1, timeZone: timeZone),
              let shawwalStart = calendar.gregorianDate(for: shawwalKey, dayOfMonth: 1, timeZone: timeZone) else {
            return nil
        }

        let lowerBoundKey = DateHelpers.dayIdentifier(for: ramadanStart, timeZone: timeZone)
        let upperBoundKey = DateHelpers.dayIdentifier(for: shawwalStart, timeZone: timeZone)

        let count = logEntries.values.reduce(into: 0) { partialResult, entry in
            guard entry.dateKey >= lowerBoundKey,
                  entry.dateKey < upperBoundKey,
                  entry.status == .missed,
                  entry.intentSnapshot?.primaryIntent == .ramadanObligatory else {
                return
            }
            partialResult += 1
        }

        guard count > 0 else { return nil }
        let sourceSummary = count == 1
            ? "Ramadan check-ins suggest 1 fast to make up."
            : "Ramadan check-ins suggest \(count) fasts to make up."
        return QadaBacklogSuggestion(suggestedOwed: count, sourceSummary: sourceSummary)
    }

    private static func mostRecentRamadanYear(
        now: Date,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> Int {
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone) else {
            return Calendar(identifier: .islamicUmmAlQura).component(.year, from: now)
        }

        if components.month.rawValue >= HijriMonth.ramadan.rawValue {
            return components.hijriYear
        }
        return components.hijriYear - 1
    }
}
