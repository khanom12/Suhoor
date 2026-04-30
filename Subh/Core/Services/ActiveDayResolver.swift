import CoreLocation
import Foundation

struct ResolvedDayBuildContext: Sendable {
    let snapshot: ResolvedDaySnapshot
    let effectiveConfig: EffectiveDailyConfig
    let provenances: [ResolvedScheduledDateProvenance]
    let tagResult: TagComputationResult
    let settings: AppSettings
    let locationDescription: String
    let timeZone: TimeZone

    var isImplicitRamadan: Bool {
        provenances.contains(where: { $0.sourceOrigin == .defaultRamadan })
    }

    var isExplicitOneOff: Bool {
        !provenances.isEmpty && provenances.allSatisfy(\.isExplicitOneOff)
    }
}

@MainActor
final class ActiveDayResolver {
    enum TagStrategy {
        case preview
        case resolved
    }

    struct Dependencies {
        let settings: () -> AppSettings
        let currentCoordinate: () -> CLLocationCoordinate2D?
        let cachedActiveDay: (String) -> ActiveAlarmDay?
        let resolvedTagResult: (Date, String, TagComputationResult, TimeZone) -> TagComputationResult
        let tagPreviewResult: (Date, FastIntentSelection?, FastPrimaryIntent?, TimeZone) -> TagComputationResult
    }

    private let alarmConfigStore: AlarmConfigStore
    private let morningPlanStore: MorningPlanStore
    private let fastTagStore: FastTagStore
    private let fastLogStore: FastLogStore
    private let fajrLogStore: FajrLogStore
    private let qadaBacklogStore: QadaBacklogStore
    private let qadaBatchStore: QadaBatchStore
    private let usesLegacyContexts: Bool
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let calculator: PrayerTimeCalculator
    private let dependencies: Dependencies

    init(
        alarmConfigStore: AlarmConfigStore,
        morningPlanStore: MorningPlanStore,
        fastTagStore: FastTagStore,
        fastLogStore: FastLogStore,
        fajrLogStore: FajrLogStore,
        qadaBacklogStore: QadaBacklogStore,
        qadaBatchStore: QadaBatchStore,
        usesLegacyContexts: Bool = true,
        adjustedHijriCalendar: AdjustedHijriCalendar,
        calculator: PrayerTimeCalculator,
        dependencies: Dependencies
    ) {
        self.alarmConfigStore = alarmConfigStore
        self.morningPlanStore = morningPlanStore
        self.fastTagStore = fastTagStore
        self.fastLogStore = fastLogStore
        self.fajrLogStore = fajrLogStore
        self.qadaBacklogStore = qadaBacklogStore
        self.qadaBatchStore = qadaBatchStore
        self.usesLegacyContexts = usesLegacyContexts
        self.adjustedHijriCalendar = adjustedHijriCalendar
        self.calculator = calculator
        self.dependencies = dependencies
    }

    func syncMorningPlanState() {
        morningPlanStore.syncFromLegacy(
            legacySettings: dependencies.settings(),
            defaultConfig: alarmConfigStore.defaults
        )
    }

    func buildMorningStateSnapshot(
        settings: AppSettings,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        locationDescription: String,
        provenancesByDateKey: [String: [ResolvedScheduledDateProvenance]]
    ) -> MorningStateSnapshot {
        MorningStateAssembler.assemble(
            settings: settings,
            defaultConfig: alarmConfigStore.defaults,
            morningPlanStore: morningPlanStore,
            fastTagSelections: usesLegacyContexts ? fastTagStore.selections : [:],
            fastLogEntries: usesLegacyContexts ? fastLogStore.entriesByDateKey : [:],
            fajrLogEntries: usesLegacyContexts ? fajrLogStore.entriesByDateKey : [:],
            qadaBacklogState: usesLegacyContexts
                ? qadaBacklogStore.state
                : QadaBacklogState.empty(startDateKey: DateHelpers.dayIdentifier(for: Date(), timeZone: timeZone)),
            qadaBatchState: usesLegacyContexts ? qadaBatchStore.state : .empty,
            overridesByDateKey: alarmConfigStore.overridesByDay,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: locationDescription,
            provenancesByDateKey: provenancesByDateKey
        )
    }

    func dateParticipatesInWakePlan(
        _ date: Date,
        timeZone: TimeZone = .current
    ) -> Bool {
        morningPlanStore.usesDailyActivation || alarmConfigStore.isDefaultsActive(on: date, timeZone: timeZone)
    }

    func mergedProvenances(
        for date: Date,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateProvenance] {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let legacy = alarmConfigStore.provenance(for: normalizedDate, timeZone: timeZone)
        guard morningPlanStore.usesDailyActivation else { return legacy }
        return [defaultDailyPlanProvenance()] + legacy.filter { $0.sourceOrigin != .defaultDailyPlan }
    }

    func resolvedEntriesForActiveWindow(
        from startDate: Date,
        limit: Int,
        timeZone: TimeZone
    ) -> [ResolvedScheduledDateEntry] {
        syncMorningPlanState()

        if morningPlanStore.usesDailyActivation {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let normalizedStart = calendar.startOfDay(for: startDate)
            return DateHelpers.dates(startingFrom: normalizedStart, count: limit, calendar: calendar).map { date in
                ResolvedScheduledDateEntry(
                    date: date,
                    dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                    provenances: mergedProvenances(for: date, timeZone: timeZone)
                )
            }
        }

        return alarmConfigStore.resolvedScheduledEntries(
            from: startDate,
            limit: limit,
            timeZone: timeZone
        )
    }

    func resolvedEntriesForHijriMonth(
        _ key: HijriYearMonth,
        timeZone: TimeZone
    ) -> [ResolvedScheduledDateEntry] {
        syncMorningPlanState()

        guard morningPlanStore.usesDailyActivation else {
            return alarmConfigStore.resolvedScheduledEntries(forHijriMonth: key, timeZone: timeZone)
        }

        guard let start = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: timeZone) else {
            return []
        }

        let nextMonthValue = key.month.rawValue == 12 ? 1 : key.month.rawValue + 1
        let nextYear = key.month.rawValue == 12 ? key.hijriYear + 1 : key.hijriYear
        guard
            let nextMonth = HijriMonth(rawValue: nextMonthValue),
            let endExclusive = adjustedHijriCalendar.gregorianDate(
                for: HijriYearMonth(hijriYear: nextYear, month: nextMonth),
                dayOfMonth: 1,
                timeZone: timeZone
            )
        else {
            return []
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let endDate = calendar.date(byAdding: .day, value: -1, to: endExclusive) ?? start
        return DateHelpers.dates(from: start, to: endDate, calendar: calendar).map { date in
            ResolvedScheduledDateEntry(
                date: date,
                dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                provenances: mergedProvenances(for: date, timeZone: timeZone)
            )
        }
    }

    func effectiveConfig(
        for date: Date,
        settings: AppSettings? = nil,
        timeZone: TimeZone = .current
    ) -> EffectiveDailyConfig {
        Self.effectiveConfig(
            for: date,
            settings: settings ?? dependencies.settings(),
            defaultConfig: alarmConfigStore.defaults,
            overridesByDay: alarmConfigStore.overridesByDay,
            additionalDefaultsActive: morningPlanStore.usesDailyActivation,
            timeZone: timeZone
        )
    }

    func resolveDaySnapshot(
        for date: Date,
        timeZone: TimeZone = .current,
        tagStrategy: TagStrategy = .resolved
    ) -> ResolvedDaySnapshot? {
        dayBuildContext(for: date, timeZone: timeZone, tagStrategy: tagStrategy)?.snapshot
    }

    func buildActiveDayIfNeeded(
        for date: Date,
        timeZone: TimeZone = .current,
        preferCached: Bool = true
    ) -> ActiveAlarmDay? {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        if preferCached, let cached = dependencies.cachedActiveDay(key) {
            return cached
        }

        guard let context = dayBuildContext(for: normalizedDate, timeZone: timeZone, tagStrategy: .resolved) else {
            return nil
        }
        return activeDay(from: context)
    }

    func scheduleAndConfig(
        for date: Date,
        builder: DayScheduleBuilder,
        timeZone: TimeZone = .current
    ) -> (schedule: DaySchedule, config: EffectiveDailyConfig)? {
        guard let context = dayBuildContext(for: date, timeZone: timeZone, tagStrategy: .preview) else {
            return nil
        }
        return (builder.buildSchedule(from: context), context.effectiveConfig)
    }

    func replacingTagResult(
        _ day: ActiveAlarmDay,
        with tagResult: TagComputationResult,
        timeZone: TimeZone
    ) -> ActiveAlarmDay {
        guard
            let coordinate = dependencies.currentCoordinate(),
            let activeDay = resolveActiveDay(
                for: day.date,
                provenances: day.provenances,
                tagResult: tagResult,
                coordinate: coordinate,
                settings: dependencies.settings(),
                timeZone: timeZone
            )
        else {
            return ActiveAlarmDay(
                date: day.date,
                dateKey: day.dateKey,
                schedule: day.schedule,
                effectiveConfig: day.effectiveConfig,
                provenances: day.provenances,
                isImplicitRamadan: day.isImplicitRamadan,
                isExplicitOneOff: day.isExplicitOneOff,
                tagResult: tagResult,
                primaryDisplay: day.primaryDisplay,
                sourceSummaryText: day.sourceSummaryText,
                resolvedDayContext: day.resolvedDayContext,
                scheduledEvents: day.scheduledEvents,
                decisionLog: day.decisionLog,
                dailyCompletion: day.dailyCompletion
            )
        }

        return activeDay
    }

    func activeDay(from context: ResolvedDayBuildContext) -> ActiveAlarmDay {
        LegacyResolvedDayAdapter.makeActiveAlarmDay(
            snapshot: context.snapshot,
            effectiveConfig: context.effectiveConfig,
            provenances: context.provenances,
            isImplicitRamadan: context.isImplicitRamadan,
            isExplicitOneOff: context.isExplicitOneOff,
            tagResult: context.tagResult,
            sourceSummaryText: Self.sourceSummary(from: context.provenances),
            settings: context.settings,
            locationDescription: context.locationDescription,
            timeZone: context.timeZone
        )
    }

    func dayBuildContext(
        for date: Date,
        timeZone: TimeZone = .current,
        tagStrategy: TagStrategy
    ) -> ResolvedDayBuildContext? {
        syncMorningPlanState()

        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard
            dateParticipatesInWakePlan(normalizedDate, timeZone: timeZone),
            let coordinate = dependencies.currentCoordinate()
        else {
            return nil
        }

        let settings = dependencies.settings()
        let provenances = mergedProvenances(for: normalizedDate, timeZone: timeZone)
        let tagResult = resolvedTagResult(
            for: normalizedDate,
            provenances: provenances,
            strategy: tagStrategy,
            timeZone: timeZone
        )
        return dayBuildContext(
            for: normalizedDate,
            provenances: provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settings,
            timeZone: timeZone
        )
    }

    func resolvedTagResult(
        for date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        strategy: TagStrategy,
        timeZone: TimeZone
    ) -> TagComputationResult {
        guard usesLegacyContexts else { return .empty }
        let defaultPrimaryIntent = provenances.defaultFastPrimaryIntent()
        let fallback = dependencies.tagPreviewResult(date, nil, defaultPrimaryIntent, timeZone)
        guard strategy == .resolved else { return fallback }
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return dependencies.resolvedTagResult(date, key, fallback, timeZone)
    }

    func resolveActiveDay(
        for date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        coordinate: CLLocationCoordinate2D,
        settings: AppSettings,
        timeZone: TimeZone
    ) -> ActiveAlarmDay? {
        guard let context = dayBuildContext(
            for: date,
            provenances: provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settings,
            timeZone: timeZone
        ) else {
            return nil
        }

        return activeDay(from: context)
    }

    func dayBuildContext(
        for date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        coordinate: CLLocationCoordinate2D,
        settings: AppSettings,
        timeZone: TimeZone,
        locationDescription: String = "Based on your location"
    ) -> ResolvedDayBuildContext? {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        let effectiveConfig = effectiveConfig(
            for: normalizedDate,
            settings: settings,
            timeZone: timeZone
        )
        let stateSnapshot = buildMorningStateSnapshot(
            settings: settings,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: locationDescription,
            provenancesByDateKey: [key: provenances]
        )
        guard let snapshot = ResolvedDayPipeline.resolve(
            date: normalizedDate,
            dateKey: key,
            provenances: provenances,
            effectiveConfig: effectiveConfig,
            tagResult: tagResult,
            stateSnapshot: stateSnapshot,
            calculator: calculator
        ) else {
            return nil
        }

        return ResolvedDayBuildContext(
            snapshot: snapshot,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            tagResult: tagResult,
            settings: settings,
            locationDescription: stateSnapshot.locationDescription,
            timeZone: timeZone
        )
    }

    private func defaultDailyPlanProvenance() -> ResolvedScheduledDateProvenance {
        let sourceID = DateHelpers.stableUUID(from: "suhoor.defaultDailyPlan")
        return ResolvedScheduledDateProvenance(
            sourceID: sourceID,
            groupID: nil,
            label: ScheduledDateSourceOrigin.defaultDailyPlan.label,
            stopSeriesLabel: ScheduledDateSourceOrigin.defaultDailyPlan.stopSeriesLabel,
            isExplicitOneOff: ScheduledDateSourceOrigin.defaultDailyPlan.isExplicitOneOff,
            sourceOrigin: .defaultDailyPlan
        )
    }

    nonisolated static func effectiveConfig(
        for date: Date,
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig,
        overridesByDay: [String: DailyAlarmOverride],
        additionalDefaultsActive: Bool,
        timeZone: TimeZone
    ) -> EffectiveDailyConfig {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let override = overridesByDay[key]
        let ruleSummary = RuleEngine(
            settings: settings,
            defaultConfig: defaultConfig,
            overridesByDay: overridesByDay,
            timeZone: timeZone
        ).ruleSummary(for: date)

        let defaultsActive = defaultConfig.activationMode == .alwaysOn
            || additionalDefaultsActive
            || defaultConfig.extraOneOffDates.contains(key)
            || {
                guard defaultConfig.activationMode == .dateRange else { return false }
                if defaultConfig.deletedDates.contains(key) {
                    return false
                }
                guard let start = defaultConfig.activeStartDate, let end = defaultConfig.activeEndDate else {
                    return false
                }
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = timeZone
                let target = calendar.startOfDay(for: date)
                return target >= calendar.startOfDay(for: start) && target <= calendar.startOfDay(for: end)
            }()
        let defaultWakeRule = defaultConfig.defaultWakeRule
        let overrideWakeRule = override?.resolvedWakeRule(defaults: defaultConfig)
        let resolvedWakeRule = overrideWakeRule ?? defaultWakeRule

        let baseSuhoorEnabled = defaultsActive && !defaultConfig.deletedDates.contains(key) ? defaultConfig.suhoorEnabledDefault : false
        let baseReminderEnabled = defaultsActive && !defaultConfig.deletedDates.contains(key) ? defaultConfig.reminderEnabledDefault : false
        let baseFajrEnabled = defaultsActive && !defaultConfig.deletedDates.contains(key) ? defaultConfig.fajrEnabledDefault : false
        let baseIftarEnabled = defaultsActive && !defaultConfig.deletedDates.contains(key) ? defaultConfig.iftarEnabledDefault : false

        var suhoorEnabled = override?.suhoorEnabled
            ?? (override?.hasSuhoorCustomization == true ? true : baseSuhoorEnabled)
        var reminderEnabled = override?.reminderEnabled
            ?? (override?.hasReminderCustomization == true ? true : baseReminderEnabled)
        var fajrEnabled = override?.fajrEnabled
            ?? (override?.hasFajrCustomization == true ? true : baseFajrEnabled)
        var iftarEnabled = override?.iftarEnabled
            ?? (override?.hasIftarCustomization == true ? true : baseIftarEnabled)

        if override?.skipDay == true || ruleSummary.disabledForDay {
            suhoorEnabled = false
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

        let suhoorTimeMode: SuhoorTimeMode
        let suhoorOffsetMinutes: Int
        let suhoorTimeOverrideMinutesFromMidnight: Int?
        if let fixedMinutes = resolvedWakeRule.fixedWakeTimeMinutesFromMidnight {
            suhoorTimeMode = .fixedTime
            suhoorOffsetMinutes = fixedMinutes
            suhoorTimeOverrideMinutesFromMidnight = fixedMinutes
        } else {
            suhoorTimeMode = .relativeToFajrMinusMinutes
            suhoorOffsetMinutes = resolvedWakeRule.deltaMinutes
            suhoorTimeOverrideMinutesFromMidnight = override?.suhoorTimeOverrideMinutesFromMidnight
        }

        return EffectiveDailyConfig(
            date: date,
            defaultsActive: defaultsActive,
            skipDay: override?.skipDay ?? false,
            suhoorEnabled: suhoorEnabled,
            reminderEnabled: reminderEnabled,
            fajrEnabled: fajrEnabled,
            iftarEnabled: iftarEnabled,
            defaultWakeRule: defaultWakeRule,
            resolvedWakeRule: resolvedWakeRule,
            wakeRuleWasOverridden: overrideWakeRule != nil,
            quickWakeModeOverride: override?.quickWakeModeOverride,
            tahajjudRefinement: override?.tahajjudRefinement ?? false,
            suhoorTimeMode: suhoorTimeMode,
            suhoorOffsetMinutes: suhoorOffsetMinutes,
            reminderTimeMode: reminderTimeMode,
            reminderMinutesBeforeFajr: override?.reminderOffsetOverrideMinutes ?? defaultConfig.defaultReminderMinutesBeforeFajr,
            reminderFixedTimeMinutes: defaultConfig.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: suhoorTimeOverrideMinutesFromMidnight,
            reminderTimeOverrideMinutesFromMidnight: override?.reminderTimeOverrideMinutesFromMidnight,
            fajrSoundChoice: override?.fajrSoundOverride ?? settings.fajrStartSoundSelectionGlobal,
            iftarDelivery: (override?.iftarDeliveryOverride ?? defaultConfig.defaultIftarDelivery).normalized(),
            iftarSoundChoice: override?.iftarSoundOverride ?? defaultConfig.defaultIftarSoundChoice,
            hasOverrides: override?.hasOverrides ?? false
        )
    }

    nonisolated static func sourceSummary(from provenances: [ResolvedScheduledDateProvenance]) -> String {
        let labels = provenances.map(\.label)
        return Array(NSOrderedSet(array: labels)).compactMap { $0 as? String }.joined(separator: " • ")
    }
}
