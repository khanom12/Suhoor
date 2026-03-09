import Foundation

@MainActor
final class CompletionHistoryResolver {
    private let resolver: ActiveDayResolver

    init(resolver: ActiveDayResolver) {
        self.resolver = resolver
    }

    func resolveDaySnapshot(
        for date: Date,
        timeZone: TimeZone = .current
    ) -> ResolvedDaySnapshot? {
        resolver.resolveDaySnapshot(
            for: date,
            timeZone: timeZone,
            tagStrategy: .resolved
        )
    }
}
