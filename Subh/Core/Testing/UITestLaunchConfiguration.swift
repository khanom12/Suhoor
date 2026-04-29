import Foundation

#if DEBUG
enum UITestLaunchConfiguration {
    static let morningHeroFajrAdjusterArgument = "--ui-testing-morning-hero-fajr-adjuster"
    static let fixedNowArgumentPrefix = "--ui-testing-fixed-now="

    static var usesMorningHeroFajrAdjusterFixture: Bool {
        ProcessInfo.processInfo.arguments.contains(morningHeroFajrAdjusterArgument)
    }

    static var fixedNow: Date? {
        ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix(fixedNowArgumentPrefix) })
            .flatMap { argument in
                let value = String(argument.dropFirst(fixedNowArgumentPrefix.count))
                return fixedNowFormatter.date(from: value)
                    ?? fixedNowFormatterWithFractionalSeconds.date(from: value)
            }
    }

    static var timeProvider: any TimeProviding {
        if let fixedNow {
            return FixedTimeProvider(fixedNow: fixedNow)
        }
        return SystemTimeProvider()
    }

    static var suppressesFastingCalendarContext: Bool {
        usesMorningHeroFajrAdjusterFixture
    }

    private static var fixedNowFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    private static var fixedNowFormatterWithFractionalSeconds: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
#endif
