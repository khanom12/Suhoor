import CoreLocation
import Foundation

struct ActiveWindowBuildInput: Sendable {
    let stateSnapshot: MorningStateSnapshot
    let resolvedEntries: [ResolvedScheduledDateEntry]
    let visibleHorizonDays: Int
    let scheduledHorizonDays: Int
}

enum ActiveWindowBuilder {
    static func build(input: ActiveWindowBuildInput) -> ActiveAlarmWindowSnapshot {
        let timeZone = input.stateSnapshot.timeZone
        let calculator = PrayerTimeCalculator()
        let sortedEntries = input.resolvedEntries.sorted { $0.date < $1.date }
        let tagSeeds = sortedEntries.map {
            ActiveTagComputationSeed(
                date: $0.date,
                dateKey: $0.dateKey,
                defaultPrimaryIntent: $0.provenances.defaultFastPrimaryIntent()
            )
        }
        let tagResults = TagComputationEngine.results(
            seeds: tagSeeds,
            selections: input.stateSnapshot.fastTagSelections,
            ruleset: .strict,
            timeZone: timeZone
        )

        var activeDays: [ActiveAlarmDay] = []
        activeDays.reserveCapacity(sortedEntries.count)

        for resolvedEntry in sortedEntries {
            let config = effectiveConfig(
                for: resolvedEntry.date,
                settings: input.stateSnapshot.settings,
                defaultConfig: input.stateSnapshot.defaultConfig,
                overridesByDay: input.stateSnapshot.overridesByDateKey,
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
                    sourceSummaryText: sourceSummary(from: resolvedEntry.provenances),
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

    static func effectiveConfig(
        for date: Date,
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig,
        overridesByDay: [String: DailyAlarmOverride],
        timeZone: TimeZone
    ) -> EffectiveDailyConfig {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let override = overridesByDay[key]
        let ruleSummary = ruleSummary(
            for: date,
            defaultConfig: defaultConfig,
            overridesByDay: overridesByDay,
            timeZone: timeZone
        )

        var wakeEnabled = override?.suhoorEnabled
            ?? (override?.hasSuhoorCustomization == true ? true : defaultConfig.suhoorEnabledDefault)
        var reminderEnabled = override?.reminderEnabled
            ?? (override?.hasReminderCustomization == true ? true : defaultConfig.reminderEnabledDefault)
        var fajrEnabled = override?.fajrEnabled
            ?? (override?.hasFajrCustomization == true ? true : defaultConfig.fajrEnabledDefault)
        var iftarEnabled = override?.iftarEnabled
            ?? (override?.hasIftarCustomization == true ? true : defaultConfig.iftarEnabledDefault)

        if override?.skipDay == true || ruleSummary.disabledForDay {
            wakeEnabled = false
            reminderEnabled = false
            fajrEnabled = false
            iftarEnabled = false
        }

        let reminderTimeMode: ReminderTimeMode
        if override?.reminderTimeOverrideMinutesFromMidnight != nil {
            reminderTimeMode = .fixedTime
        } else if override?.reminderOffsetOverrideMinutes != nil {
            reminderTimeMode = .beforeFajr
        } else {
            reminderTimeMode = defaultConfig.defaultReminderTimeMode
        }

        return EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: override?.skipDay ?? false,
            suhoorEnabled: wakeEnabled,
            reminderEnabled: reminderEnabled,
            fajrEnabled: fajrEnabled,
            iftarEnabled: iftarEnabled,
            suhoorTimeMode: defaultConfig.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: ruleSummary.finalOffsetMinutes,
            reminderTimeMode: reminderTimeMode,
            reminderMinutesBeforeFajr: override?.reminderOffsetOverrideMinutes ?? defaultConfig.defaultReminderMinutesBeforeFajr,
            reminderFixedTimeMinutes: defaultConfig.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: override?.suhoorTimeOverrideMinutesFromMidnight,
            reminderTimeOverrideMinutesFromMidnight: override?.reminderTimeOverrideMinutesFromMidnight,
            fajrSoundChoice: override?.fajrSoundOverride ?? settings.atFajrSoundSelectionGlobal,
            iftarDelivery: (override?.iftarDeliveryOverride ?? defaultConfig.defaultIftarDelivery).normalized(),
            iftarSoundChoice: override?.iftarSoundOverride ?? defaultConfig.defaultIftarSoundChoice,
            hasOverrides: override?.hasOverrides ?? false
        )
    }

    static func ruleSummary(
        for date: Date,
        defaultConfig: DefaultAlarmConfig,
        overridesByDay: [String: DailyAlarmOverride],
        timeZone: TimeZone
    ) -> RuleSummary {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let baseOffset = defaultConfig.defaultSuhoorOffsetMinutes
        if let override = overridesByDay[key] {
            if override.skipDay {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    finalOffsetMinutes: baseOffset,
                    overrideOffsetMinutes: override.suhoorOffsetOverrideMinutes,
                    disabledForDay: true
                )
            }
            if let overrideMinutes = override.suhoorOffsetOverrideMinutes {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    finalOffsetMinutes: overrideMinutes,
                    overrideOffsetMinutes: overrideMinutes,
                    disabledForDay: false
                )
            }
        }

        return RuleSummary(
            baseOffsetMinutes: baseOffset,
            finalOffsetMinutes: baseOffset,
            overrideOffsetMinutes: nil,
            disabledForDay: false
        )
    }

    static func sourceSummary(from provenances: [ResolvedScheduledDateProvenance]) -> String {
        let labels = provenances.map(\.label)
        return Array(NSOrderedSet(array: labels)).compactMap { $0 as? String }.joined(separator: " • ")
    }
}
