import Foundation

enum ResolvedDayPipeline {
    static func resolve(
        date: Date,
        dateKey: String,
        provenances: [ResolvedScheduledDateProvenance],
        effectiveConfig: EffectiveDailyConfig,
        tagResult: TagComputationResult,
        stateSnapshot: MorningStateSnapshot,
        calculator: PrayerTimeCalculator = PrayerTimeCalculator()
    ) -> ResolvedDaySnapshot? {
        MorningScheduleResolver.resolve(
            input: MorningScheduleResolutionInput(
                date: date,
                dateKey: dateKey,
                provenances: provenances,
                effectiveConfig: effectiveConfig,
                tagResult: tagResult,
                stateSnapshot: stateSnapshot
            ),
            calculator: calculator
        )
    }
}
