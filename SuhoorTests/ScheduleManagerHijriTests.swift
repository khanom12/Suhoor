import Foundation
import CoreLocation
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

        let result = await manager.addIslamicQuickAdd(.nextMondayThursdayPair)
        let resolved = manager.upcomingResolvedEntries(limit: 10)
        let quickAddEntries = resolved.filter {
            $0.provenances.contains { $0.sourceOrigin == .islamicQuickAdd(.nextMondayThursdayPair) }
        }

        #expect(result.addedDates.count == 2)
        #expect(quickAddEntries.count == 2)
        #expect(quickAddEntries.allSatisfy { $0.provenances.contains { $0.sourceOrigin == .islamicQuickAdd(.nextMondayThursdayPair) } })
    }

    @Test
    @MainActor
    func previewGregorianRangeSkipsAlreadyActiveDatesAndStoresOnlyOpenSegments() {
        let suiteName = "ScheduleManagerHijriTests.RangeSkip"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let startDate = makeDate(year: 2026, month: 3, day: 3)
        let blockedDate = makeDate(year: 2026, month: 3, day: 4)
        let endDate = makeDate(year: 2026, month: 3, day: 5)
        alarmConfigStore.addSingleDaySource(blockedDate)

        let preview = alarmConfigStore.previewGregorianRangeAdd(startDate: startDate, endDate: endDate)
        #expect(preview.addedDates.count == 2)
        #expect(preview.skippedActiveDates == [blockedDate])

        let result = alarmConfigStore.addGregorianRangeSource(startDate: startDate, endDate: endDate)
        #expect(result == preview)

        let entries = alarmConfigStore.resolvedScheduledEntries(from: startDate, limit: 10)
        let blockedKey = DateHelpers.dayIdentifier(for: blockedDate, timeZone: .current)
        let blockedEntry = entries.first { $0.dateKey == blockedKey }
        #expect(blockedEntry?.provenances.count == 1)
        #expect(blockedEntry?.provenances.first?.sourceOrigin == .manualSingleDay)
    }

    @Test
    @MainActor
    func quickAddAvailabilityDisablesWhenAllDatesAlreadyActive() async {
        let suiteName = "ScheduleManagerHijriTests.QuickAddAvailability"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        let initial = await manager.addIslamicQuickAdd(.nextMondayThursdayPair)
        #expect(initial.addedDates.count == 2)

        let availability = manager.islamicQuickAddAvailability(.nextMondayThursdayPair)
        #expect(availability.state == .disabled)
        #expect(availability.addResult.addedDates.isEmpty)
        #expect(availability.addResult.skippedActiveDates.count == 2)
    }

    @Test
    @MainActor
    func recurringWhiteDaysDefaultsToVoluntaryTagsWithoutStoredSelections() async {
        let suiteName = "ScheduleManagerHijriTests.RecurringDefaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let fastTagStore = FastTagStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        let added = await manager.addRecurringIslamicRule(.whiteDays)
        #expect(added == true)
        guard let activeDay = manager.activeWindowSnapshot.visibleDays.first(where: {
            $0.provenances.contains(where: { $0.sourceOrigin == .recurringIslamic(.whiteDays) })
        }) else {
            Issue.record("Expected a visible recurring white-days entry.")
            return
        }

        #expect(fastTagStore.selection(for: activeDay.date, timeZone: .current) == nil)
        #expect(activeDay.tagResult.computedPrimaryIntent == .voluntarySunnah)
        #expect(activeDay.tagResult.computedSecondaryTags.contains(.whiteDays))
    }

    @Test
    func cleanupMigrationRemovesDisallowedRamadanAndEidSources() throws {
        let suiteName = "ScheduleManagerHijriTests.CleanupMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let sources = [
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(SingleDaySource(dateKey: "2026-03-03", date: makeDate(year: 2026, month: 3, day: 3))),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualSingleDay,
                groupID: nil
            ),
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(SingleDaySource(dateKey: "2026-03-20", date: makeDate(year: 2026, month: 3, day: 20))),
                createdAt: Date(),
                isEnabled: true,
                origin: .islamicQuickAdd(.nextEidAlFitr),
                groupID: nil
            ),
            ScheduledDateSource(
                id: UUID(),
                kind: .recurringIslamic(RecurringIslamicSource(rule: .ramadan, startDate: makeDate(year: 2026, month: 2, day: 18))),
                createdAt: Date(),
                isEnabled: true,
                origin: .recurringIslamic(.ramadan),
                groupID: nil
            )
        ]
        defaults.set(try JSONEncoder().encode(sources), forKey: "Suhoor.ScheduledDateSources")
        defaults.set(2, forKey: "Suhoor.ScheduledDateSourcesMigrationVersion")

        let store = ScheduledDateSourceStore(defaults: defaults)

        #expect(store.sources.count == 1)
        #expect(store.sources.first?.origin == .manualSingleDay)
    }

    @Test
    @MainActor
    func refreshSchedulesKeepsVisibleRowsWithoutSchedulingPermissions() async {
        let suiteName = "ScheduleManagerHijriTests.VisibleRowsWithoutPermissions"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let testDate = makeDate(year: 2026, month: 3, day: 3)
        let testDateKey = DateHelpers.dayIdentifier(for: testDate, timeZone: .current)
        alarmConfigStore.addSingleDaySource(testDate)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)

        #expect(manager.activeWindowSnapshot.byDateKey[testDateKey] != nil)
    }

    @Test
    @MainActor
    func refreshSchedulesKeepsLastVisibleRowsWhileAutoLocationIsRelocating() async {
        let suiteName = "ScheduleManagerHijriTests.RelocatingKeepsRows"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .auto
        }

        let locationService = LocationService()
        locationService.authorizationStatus = .authorizedWhenInUse
        locationService.lastLocation = CLLocation(latitude: 43.6532, longitude: -79.3832)

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let testDate = makeDate(year: 2026, month: 3, day: 4)
        let testDateKey = DateHelpers.dayIdentifier(for: testDate, timeZone: .current)
        alarmConfigStore.addSingleDaySource(testDate)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)
        #expect(manager.activeWindowSnapshot.byDateKey[testDateKey] != nil)

        locationService.lastLocation = nil
        await manager.refreshSchedules(force: true)

        #expect(manager.activeWindowSnapshot.byDateKey[testDateKey] != nil)
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Self.makeDate(year: year, month: month, day: day)
    }
}
