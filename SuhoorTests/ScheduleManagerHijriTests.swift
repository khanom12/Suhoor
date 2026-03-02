import Foundation
import Testing
@testable import Suhoor

@Suite
struct ScheduleManagerHijriTests {
    @Test
    @MainActor
    func legacyExtraOneOffDayMigratesButLegacyAlwaysRangeDoesNot() {
        let suiteName = "ScheduleManagerHijriTests.LegacyMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var legacyDefaults = DefaultAlarmConfig.default
        legacyDefaults.extraOneOffDates = ["2026-02-20"]
        let data = try? JSONEncoder().encode(legacyDefaults)
        defaults.set(data, forKey: "Suhoor.DefaultAlarmConfig")

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let entries = alarmConfigStore.resolvedScheduledEntries(
            from: makeDate(year: 2026, month: 2, day: 1),
            limit: 60
        )

        #expect(entries.contains(where: { $0.dateKey == "2026-02-20" }))
        #expect(entries.contains(where: { $0.provenances.contains { $0.sourceOrigin == .defaultRamadan } }))
        #expect(entries.contains(where: { $0.provenances.contains { $0.sourceOrigin == .migratedLegacyAlways } }) == false)
    }

    @Test
    @MainActor
    func quickAddCreatesVisibleEntries() async {
        let suiteName = "ScheduleManagerHijriTests.QuickAdd"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: adjustmentStore
        )

        let dates = await manager.addIslamicQuickAdd(.nextMondayThursdayPair)
        let resolved = manager.upcomingResolvedEntries(limit: 10)

        #expect(dates.count == 2)
        #expect(resolved.count == 2)
        #expect(resolved.allSatisfy { $0.provenances.first?.sourceOrigin == .islamicQuickAdd(.nextMondayThursdayPair) })
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
