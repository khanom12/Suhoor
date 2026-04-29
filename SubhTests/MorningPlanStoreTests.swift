import Foundation
import Testing
@testable import Subh

@Suite
struct MorningPlanStoreTests {
    @Test
    func freshStoreDefaultsToDailyActivation() {
        let suiteName = "MorningPlanStoreTests.FreshDaily"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = MorningPlanStore(
            defaults: defaults,
            legacySettings: .default,
            defaultConfig: .default
        )

        #expect(store.usesDailyActivation)
        #expect(store.state.activationMode == .dailyActive)
    }

    @Test
    func legacySettingsWithoutMorningPlanStateDefaultsToDailyActivation() throws {
        let suiteName = "MorningPlanStoreTests.LegacySettingsNoPlanState"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(try JSONEncoder().encode(AppSettings.default), forKey: "Suhoor.AppSettings")
        defaults.set(try JSONEncoder().encode(DefaultAlarmConfig.default), forKey: "Suhoor.DefaultAlarmConfig")

        let now = Date(timeIntervalSince1970: 1_777_500_000)
        let store = MorningPlanStore(
            defaults: defaults,
            legacySettings: .default,
            defaultConfig: .default,
            timeProvider: FixedTimeProvider(fixedNow: now)
        )

        #expect(store.usesDailyActivation)
        #expect(store.state.activationMode == .dailyActive)
        #expect(store.state.lastMigrationAt == now)
    }

    @Test
    func persistedLegacyCompatMigratesToDailyActivation() throws {
        let suiteName = "MorningPlanStoreTests.LegacyMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyState = MorningPlanState(
            schemaVersion: 2,
            activationMode: .legacyCompat,
            defaultDailyPlan: MorningPlanStoreTests.defaultPlan(),
            lastMigrationAt: nil
        )
        defaults.set(try JSONEncoder().encode(legacyState), forKey: "Suhoor.MorningPlanState")

        let store = MorningPlanStore(
            defaults: defaults,
            legacySettings: .default,
            defaultConfig: .default,
            timeProvider: FixedTimeProvider(fixedNow: Date(timeIntervalSince1970: 1_800_000_000))
        )

        #expect(store.usesDailyActivation)
        #expect(store.state.activationMode == .dailyActive)
        #expect(store.state.lastMigrationAt != nil)

        let persistedData = try #require(defaults.data(forKey: "Suhoor.MorningPlanState"))
        let persistedState = try JSONDecoder().decode(MorningPlanState.self, from: persistedData)
        #expect(persistedState.activationMode == .dailyActive)
    }

    @Test
    func persistedDailyActivationRemainsUnchanged() throws {
        let suiteName = "MorningPlanStoreTests.PersistedDaily"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let existingState = MorningPlanState(
            schemaVersion: 2,
            activationMode: .dailyActive,
            defaultDailyPlan: MorningPlanStoreTests.defaultPlan(),
            lastMigrationAt: timestamp
        )
        defaults.set(try JSONEncoder().encode(existingState), forKey: "Suhoor.MorningPlanState")

        let store = MorningPlanStore(
            defaults: defaults,
            legacySettings: .default,
            defaultConfig: .default
        )

        #expect(store.state.activationMode == .dailyActive)
        #expect(store.state.lastMigrationAt == timestamp)
    }

    private static func defaultPlan() -> MorningPlan {
        MorningPlan(
            id: "default-daily",
            title: "Daily morning plan",
            kind: .defaultDaily,
            wakeRule: .init(state: .inFajr, anchorType: .fajrEnd, deltaMinutes: 30),
            wakeAnchorType: .fajrEnd,
            wakeDelta: .init(relation: .before, minutes: 30),
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: false
        )
    }
}
