import Foundation

@MainActor
final class MonthTagResultProvider {
    struct Dependencies {
        let currentRevision: () -> Int
        let selections: () -> [String: FastIntentSelection]
        let resolvedEntriesForHijriMonth: (HijriYearMonth, TimeZone) -> [ResolvedScheduledDateEntry]
        let replaceActiveDayTagResult: (ActiveAlarmDay, TagComputationResult, TimeZone) -> ActiveAlarmDay
    }

    private let dependencies: Dependencies
    private var tagResultMonthCache: [HijriMonthKey: MonthTagCache] = [:]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func invalidate() {
        tagResultMonthCache.removeAll()
    }

    func resolvedTagResult(
        for date: Date,
        dateKey: String,
        fallback: TagComputationResult,
        timeZone: TimeZone
    ) -> TagComputationResult {
        guard let key = shawwalMonthKey(for: date, timeZone: timeZone) else {
            return fallback
        }
        return monthTagResults(for: key, timeZone: timeZone)[dateKey] ?? fallback
    }

    func monthTagResults(
        for key: HijriMonthKey,
        timeZone: TimeZone
    ) -> [String: TagComputationResult] {
        if let cached = tagResultMonthCache[key],
           cached.revision == dependencies.currentRevision() {
            return cached.results
        }

        guard let month = HijriMonth(rawValue: key.month) else { return [:] }
        let resolvedEntries = dependencies.resolvedEntriesForHijriMonth(
            HijriYearMonth(hijriYear: key.year, month: month),
            timeZone
        )
        let seeds = resolvedEntries.map {
            ActiveTagComputationSeed(
                date: $0.date,
                dateKey: $0.dateKey,
                defaultPrimaryIntent: $0.provenances.defaultFastPrimaryIntent()
            )
        }
        let results = TagComputationEngine.results(
            seeds: seeds,
            selections: dependencies.selections(),
            ruleset: .strict,
            timeZone: timeZone
        )
        tagResultMonthCache[key] = MonthTagCache(
            revision: dependencies.currentRevision(),
            results: results
        )
        return results
    }

    func applyShawwalTagResults(
        to days: [ActiveAlarmDay],
        timeZone: TimeZone
    ) -> [ActiveAlarmDay] {
        guard days.contains(where: { shawwalMonthKey(for: $0.date, timeZone: timeZone) != nil }) else {
            return days
        }

        var resultsByMonth: [HijriMonthKey: [String: TagComputationResult]] = [:]
        var updated: [ActiveAlarmDay] = []
        updated.reserveCapacity(days.count)
        var didChange = false

        for day in days {
            guard let monthKey = shawwalMonthKey(for: day.date, timeZone: timeZone) else {
                updated.append(day)
                continue
            }
            let results = resultsByMonth[monthKey] ?? monthTagResults(for: monthKey, timeZone: timeZone)
            resultsByMonth[monthKey] = results
            if let monthResult = results[day.dateKey], monthResult != day.tagResult {
                didChange = true
                updated.append(dependencies.replaceActiveDayTagResult(day, monthResult, timeZone))
            } else {
                updated.append(day)
            }
        }

        return didChange ? updated : days
    }

    func shawwalMonthKey(for date: Date, timeZone: TimeZone) -> HijriMonthKey? {
        guard let components = FastIntentEngine.adjustedComponents(for: date, timeZone: timeZone),
              components.month == .shawwal else {
            return nil
        }
        return FastIntentEngine.hijriMonthKey(for: date, timeZone: timeZone)
    }
}

private struct MonthTagCache: Equatable, Sendable {
    let revision: Int
    let results: [String: TagComputationResult]
}
