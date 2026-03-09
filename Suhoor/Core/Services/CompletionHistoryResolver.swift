import Foundation
import CoreLocation

@MainActor
final class CompletionHistoryResolver {
    struct Dependencies {
        let syncMorningPlanState: () -> Void
        let currentCoordinate: () -> CLLocationCoordinate2D?
        let settings: () -> AppSettings
        let mergedProvenances: (Date, TimeZone) -> [ResolvedScheduledDateProvenance]
        let tagPreviewResult: (Date, FastIntentSelection?, FastPrimaryIntent?, TimeZone) -> TagComputationResult
        let buildMorningStateSnapshot: (AppSettings, CLLocationCoordinate2D, TimeZone, String, [String: [ResolvedScheduledDateProvenance]]) -> MorningStateSnapshot
        let monthTagResultProvider: MonthTagResultProvider
        let defaultConfig: () -> DefaultAlarmConfig
        let overridesByDay: () -> [String: DailyAlarmOverride]
        let calculator: PrayerTimeCalculator
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func resolveDaySnapshot(
        for date: Date,
        timeZone: TimeZone = .current
    ) -> ResolvedDaySnapshot? {
        dependencies.syncMorningPlanState()
        guard let coordinate = dependencies.currentCoordinate() else { return nil }

        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        let provenances = dependencies.mergedProvenances(normalizedDate, timeZone)
        let settings = dependencies.settings()
        let defaultPrimaryIntent = provenances.defaultFastPrimaryIntent()
        let fallbackTagResult = dependencies.tagPreviewResult(
            normalizedDate,
            nil,
            defaultPrimaryIntent,
            timeZone
        )
        let tagResult = dependencies.monthTagResultProvider.resolvedTagResult(
            for: normalizedDate,
            dateKey: key,
            fallback: fallbackTagResult,
            timeZone: timeZone
        )

        let effectiveConfig = ActiveWindowBuilder.effectiveConfig(
            for: normalizedDate,
            settings: settings,
            defaultConfig: dependencies.defaultConfig(),
            overridesByDay: dependencies.overridesByDay(),
            timeZone: timeZone
        )
        let stateSnapshot = dependencies.buildMorningStateSnapshot(
            settings,
            coordinate,
            timeZone,
            "Based on your location",
            [key: provenances]
        )

        return ResolvedDayPipeline.resolve(
            date: normalizedDate,
            dateKey: key,
            provenances: provenances,
            effectiveConfig: effectiveConfig,
            tagResult: tagResult,
            stateSnapshot: stateSnapshot,
            calculator: dependencies.calculator
        )
    }
}
