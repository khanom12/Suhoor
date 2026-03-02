import Foundation
import Testing
@testable import Suhoor

@Suite
struct ScheduleManagerHijriTests {
    @Test
    @MainActor
    func legacyAlwaysMigratesTo60VisibleSourceDays() {
        let suiteName = "ScheduleManagerHijriTests.LegacyAlways"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let legacyDefaults = DefaultAlarmConfig.default
        let data = try? JSONEncoder().encode(legacyDefaults)
        defaults.set(data, forKey: "Suhoor.DefaultAlarmConfig")

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let entries = alarmConfigStore.resolvedScheduledEntries(
            from: DateHelpers.startOfToday(),
            limit: 60
        )

        #expect(entries.count == 60)
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
