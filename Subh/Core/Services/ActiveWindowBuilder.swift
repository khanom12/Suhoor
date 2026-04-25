import CoreLocation
import Foundation

struct ActiveWindowBuildInput: Sendable {
    let stateSnapshot: MorningStateSnapshot
    let resolvedEntries: [ResolvedScheduledDateEntry]
    let visibleHorizonDays: Int
    let scheduledHorizonDays: Int
    let usesLegacyContexts: Bool
}

struct ActiveWindowSnapshotBuilder: Sendable {
    func build(input: ActiveWindowBuildInput) -> ActiveAlarmWindowSnapshot {
        let timeZone = input.stateSnapshot.timeZone
        let calculator = PrayerTimeCalculator()
        let sortedEntries = input.resolvedEntries.sorted { $0.date < $1.date }
        let tagResults: [String: TagComputationResult]
        if input.usesLegacyContexts {
            let tagSeeds = sortedEntries.map {
                ActiveTagComputationSeed(
                    date: $0.date,
                    dateKey: $0.dateKey,
                    defaultPrimaryIntent: $0.provenances.defaultFastPrimaryIntent()
                )
            }
            tagResults = TagComputationEngine.results(
                seeds: tagSeeds,
                selections: input.stateSnapshot.fastTagSelections,
                ruleset: .strict,
                timeZone: timeZone
            )
        } else {
            tagResults = [:]
        }

        var activeDays: [ActiveAlarmDay] = []
        activeDays.reserveCapacity(sortedEntries.count)

        for resolvedEntry in sortedEntries {
            let config = ActiveDayResolver.effectiveConfig(
                for: resolvedEntry.date,
                settings: input.stateSnapshot.settings,
                defaultConfig: input.stateSnapshot.defaultConfig,
                overridesByDay: input.stateSnapshot.overridesByDateKey,
                additionalDefaultsActive: input.stateSnapshot.morningPlanState.activationMode == .dailyActive,
                timeZone: timeZone
            )
            let tagResult = tagResults[resolvedEntry.dateKey] ?? .empty
            guard let snapshot = ResolvedDayPipeline.resolve(
                date: resolvedEntry.date,
                dateKey: resolvedEntry.dateKey,
                provenances: resolvedEntry.provenances,
                effectiveConfig: config,
                tagResult: tagResult,
                stateSnapshot: input.stateSnapshot,
                calculator: calculator
            ) else {
                continue
            }

            activeDays.append(
                LegacyResolvedDayAdapter.makeActiveAlarmDay(
                    snapshot: snapshot,
                    effectiveConfig: config,
                    provenances: resolvedEntry.provenances,
                    isImplicitRamadan: resolvedEntry.provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }),
                    isExplicitOneOff: resolvedEntry.isExplicitOneOff,
                    tagResult: tagResult,
                    sourceSummaryText: ActiveDayResolver.sourceSummary(from: resolvedEntry.provenances),
                    settings: input.stateSnapshot.settings,
                    locationDescription: input.stateSnapshot.locationDescription,
                    timeZone: timeZone
                )
            )
        }

        let visibleDays = Array(activeDays.prefix(input.visibleHorizonDays))
        return ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: visibleDays,
            scheduledDays: Array(visibleDays.prefix(input.scheduledHorizonDays)),
            visibleHorizonDays: input.visibleHorizonDays,
            scheduledHorizonDays: input.scheduledHorizonDays
        )
    }
}

typealias ActiveWindowBuilder = ActiveWindowSnapshotBuilder
