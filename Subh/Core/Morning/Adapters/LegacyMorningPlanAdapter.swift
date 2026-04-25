import Foundation

enum LegacyMorningPlanAdapter {
    static func loadState(from store: MorningPlanStore) -> MorningPlanState {
        store.state
    }

    static func loadState(
        defaults: UserDefaults,
        legacySettings: AppSettings,
        defaultConfig: DefaultAlarmConfig
    ) -> MorningPlanState {
        MorningPlanStore(
            defaults: defaults,
            legacySettings: legacySettings,
            defaultConfig: defaultConfig
        ).state
    }
}
