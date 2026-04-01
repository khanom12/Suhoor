import Foundation

final class MorningPlanStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.MorningPlanState"
    private let currentSchemaVersion = 2

    private(set) var state: MorningPlanState

    init(
        defaults: UserDefaults = .standard,
        legacySettings: AppSettings,
        defaultConfig: DefaultAlarmConfig
    ) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(MorningPlanState.self, from: data) {
            self.state = decoded
        } else {
            self.state = MorningPlanStore.makeInitialState(
                defaults: defaults,
                schemaVersion: currentSchemaVersion,
                legacySettings: legacySettings,
                defaultConfig: defaultConfig
            )
            persist()
        }
    }

    var usesDailyActivation: Bool {
        state.activationMode == .dailyActive
    }

    func syncFromLegacy(
        legacySettings: AppSettings,
        defaultConfig: DefaultAlarmConfig
    ) {
        let nextPlan = Self.makeDefaultPlan(defaultConfig: defaultConfig, settings: legacySettings)
        guard nextPlan != state.defaultDailyPlan else { return }
        state.defaultDailyPlan = nextPlan
        persist()
    }

    func activateDailyPlanIfNeeded() {
        guard state.activationMode != .dailyActive else { return }
        state.activationMode = .dailyActive
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func makeInitialState(
        defaults: UserDefaults,
        schemaVersion: Int,
        legacySettings: AppSettings,
        defaultConfig: DefaultAlarmConfig
    ) -> MorningPlanState {
        let hasPersistedLegacyData =
            defaults.data(forKey: "Suhoor.AppSettings") != nil ||
            defaults.data(forKey: "Suhoor.DefaultAlarmConfig") != nil ||
            defaults.data(forKey: "Suhoor.DailyAlarmOverrides") != nil ||
            defaults.data(forKey: "Suhoor.ScheduledDateSources") != nil

        return MorningPlanState(
            schemaVersion: schemaVersion,
            activationMode: hasPersistedLegacyData ? .legacyCompat : .dailyActive,
            defaultDailyPlan: makeDefaultPlan(defaultConfig: defaultConfig, settings: legacySettings),
            lastMigrationAt: Date()
        )
    }

    private static func makeDefaultPlan(
        defaultConfig: DefaultAlarmConfig,
        settings: AppSettings
    ) -> MorningPlan {
        let baseRule = defaultConfig.defaultWakeRule
        let wakeRule: MorningWakeRule
        let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?

        if defaultConfig.defaultSuhoorTimeMode == .fixedTime {
            wakeRule = MorningWakeRule(
                state: baseRule.state,
                anchorType: baseRule.anchorType,
                deltaMinutes: max(0, settings.baseWakeOffsetMinutes),
                fixedWakeTimeMinutesFromMidnight: defaultConfig.defaultSuhoorOffsetMinutes,
                latestWakeCapMinutesFromMidnight: baseRule.latestWakeCapMinutesFromMidnight,
                bypassLatestWakeCap: baseRule.bypassLatestWakeCap,
                isLegacyFixedWakeCompatibility: true
            )
            fixedWakeTimeCompatibilityMinutesFromMidnight = defaultConfig.defaultSuhoorOffsetMinutes
        } else {
            wakeRule = baseRule
            fixedWakeTimeCompatibilityMinutesFromMidnight = nil
        }

        return MorningPlan(
            id: "default-daily",
            title: "Daily morning plan",
            kind: .defaultDaily,
            wakeRule: wakeRule,
            wakeAnchorType: wakeRule.compatibilityWakeAnchorType,
            wakeDelta: wakeRule.compatibilityWakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: fixedWakeTimeCompatibilityMinutesFromMidnight,
            reminderEnabled: defaultConfig.reminderEnabledDefault,
            wakeAlarmEnabled: defaultConfig.suhoorEnabledDefault,
            fajrBoundaryNoticeEnabled: defaultConfig.fajrEnabledDefault,
            iftarReminderEnabled: defaultConfig.iftarEnabledDefault
        )
    }
}
