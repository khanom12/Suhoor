import Foundation

enum EarlyWorshipBoundaryResolver {
    static func finalThirdStart(
        targetFajrStart: Date,
        maghrib: Date,
        timeZone: TimeZone
    ) -> Date? {
        let previousMaghrib = previousEveningMaghrib(
            for: targetFajrStart,
            resolvedMaghrib: maghrib,
            timeZone: timeZone
        )
        guard previousMaghrib < targetFajrStart else { return nil }

        let nightDuration = targetFajrStart.timeIntervalSince(previousMaghrib)
        guard nightDuration > 0 else { return nil }

        return targetFajrStart.addingTimeInterval(-(nightDuration / 3))
    }

    private static func previousEveningMaghrib(
        for targetFajrStart: Date,
        resolvedMaghrib: Date,
        timeZone: TimeZone
    ) -> Date {
        guard resolvedMaghrib > targetFajrStart else {
            return resolvedMaghrib
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .day, value: -1, to: resolvedMaghrib)
            ?? resolvedMaghrib.addingTimeInterval(-24 * 60 * 60)
    }
}
