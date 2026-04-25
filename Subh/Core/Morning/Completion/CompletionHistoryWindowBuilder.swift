import Foundation

enum CompletionHistoryWindowBuilder {
    static func build(
        days: Int,
        now: Date,
        timeZone: TimeZone,
        resolveDay: (Date) -> ResolvedDaySnapshot?
    ) -> CompletionHistoryWindow {
        guard days > 0 else {
            return CompletionHistoryWindow(resolvedDays: [], dailyCompletions: [])
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)

        let resolvedDays = (0..<days).compactMap { offset -> ResolvedDaySnapshot? in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return resolveDay(date)
        }

        return CompletionHistoryWindow(
            resolvedDays: resolvedDays,
            dailyCompletions: resolvedDays.map(\.dailyCompletion)
        )
    }
}
