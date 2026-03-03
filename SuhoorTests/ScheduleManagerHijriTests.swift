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
            from: Self.makeDate(year: 2026, month: 2, day: 1),
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
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let startDate = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: adjustmentStore
        )

        let result = await manager.addIslamicQuickAdd(
            .nextMondayThursdayPair,
            startDate: startDate,
            timeZone: timeZone
        )
        let resolved = alarmConfigStore.resolvedScheduledEntries(
            from: startDate,
            limit: 10,
            timeZone: timeZone
        )
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
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let startDate = Self.makeDate(year: 2026, month: 7, day: 3, timeZone: timeZone)
        let blockedDate = Self.makeDate(year: 2026, month: 7, day: 4, timeZone: timeZone)
        let endDate = Self.makeDate(year: 2026, month: 7, day: 5, timeZone: timeZone)
        alarmConfigStore.addSingleDaySource(blockedDate, timeZone: timeZone)

        let preview = alarmConfigStore.previewGregorianRangeAdd(
            startDate: startDate,
            endDate: endDate,
            timeZone: timeZone
        )
        #expect(preview.addedDates.count == 2)
        #expect(preview.skippedActiveDates.map {
            DateHelpers.dayIdentifier(for: $0, timeZone: timeZone)
        } == [DateHelpers.dayIdentifier(for: blockedDate, timeZone: timeZone)])

        let result = alarmConfigStore.addGregorianRangeSource(
            startDate: startDate,
            endDate: endDate,
            timeZone: timeZone
        )
        #expect(result == preview)

        let entries = alarmConfigStore.resolvedScheduledEntries(from: startDate, limit: 10, timeZone: timeZone)
        let blockedKey = DateHelpers.dayIdentifier(for: blockedDate, timeZone: timeZone)
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
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let startDate = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        let initial = await manager.addIslamicQuickAdd(
            .nextMondayThursdayPair,
            startDate: startDate,
            timeZone: timeZone
        )
        #expect(initial.addedDates.count == 2)

        let availability = manager.islamicQuickAddAvailability(
            .nextMondayThursdayPair,
            startDate: startDate,
            timeZone: timeZone
        )
        #expect(availability.state == IslamicQuickAddAvailabilityState.disabled)
        #expect(availability.addResult.addedDates.isEmpty)
        #expect(availability.addResult.skippedActiveDates.count == 2)
    }

    @Test
    @MainActor
    func hijriSingleDaySourceResolvesAndShiftsWithAdjustment() {
        let suiteName = "ScheduleManagerHijriTests.HijriSingleDayShift"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let calendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        let referenceDate = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)
        let components = calendar.adjustedComponents(for: referenceDate, timeZone: timeZone)
        #expect(components != nil)
        guard let components else { return }

        let hijriSource = HijriSingleDaySource(
            hijriYear: components.hijriYear,
            month: components.month,
            day: components.day
        )
        alarmConfigStore.addHijriSingleDaySource(
            hijriSource,
            origin: .islamicQuickAdd(.nextWhiteDays),
            timeZone: timeZone
        )

        let resolvedBefore = alarmConfigStore.resolvedScheduledEntries(
            from: referenceDate,
            limit: 5,
            timeZone: timeZone
        )
        let beforeKey = DateHelpers.dayIdentifier(for: referenceDate, timeZone: timeZone)
        #expect(resolvedBefore.contains(where: { $0.dateKey == beforeKey }))

        adjustmentStore.setAdjustment(
            for: HijriYearMonth(hijriYear: components.hijriYear, month: components.month),
            offsetDays: 1
        )
        let shiftedDate = calendar.gregorianDate(
            for: HijriYearMonth(hijriYear: components.hijriYear, month: components.month),
            dayOfMonth: components.day,
            timeZone: timeZone
        )
        #expect(shiftedDate != nil)
        guard let shiftedDate else { return }

        let resolvedAfter = alarmConfigStore.resolvedScheduledEntries(
            from: referenceDate,
            limit: 10,
            timeZone: timeZone
        )
        let shiftedKey = DateHelpers.dayIdentifier(for: shiftedDate, timeZone: timeZone)
        #expect(resolvedAfter.contains(where: { $0.dateKey == shiftedKey }))
    }

    @Test
    @MainActor
    func adjustmentChangeCarriesSuppressionOverridesAndTags() async {
        let suiteName = "ScheduleManagerHijriTests.AdjustmentCarryOver"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let changeStore = HijriAdjustmentChangeStore(defaults: defaults)
        let fastTagStore = FastTagStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: adjustmentStore,
            hijriAdjustmentChangeStore: changeStore
        )

        let calendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        let referenceDate = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)
        guard let components = calendar.adjustedComponents(for: referenceDate, timeZone: timeZone) else {
            #expect(false)
            return
        }

        let hijriSource = HijriSingleDaySource(
            hijriYear: components.hijriYear,
            month: components.month,
            day: components.day
        )
        alarmConfigStore.addHijriSingleDaySource(
            hijriSource,
            origin: .islamicQuickAdd(.nextWhiteDays),
            timeZone: timeZone
        )

        let oldDate = calendar.gregorianDate(
            for: HijriYearMonth(hijriYear: components.hijriYear, month: components.month),
            dayOfMonth: components.day,
            timeZone: timeZone
        )
        #expect(oldDate != nil)
        guard let oldDate else { return }

        alarmConfigStore.updateOverride(for: oldDate, timeZone: timeZone) { override in
            override.skipDay = true
            override.suhoorEnabled = false
        }
        alarmConfigStore.addDeletedDate(oldDate, timeZone: timeZone)
        if let selection = FastIntentEngine.defaultAddFlowSelection(for: oldDate, timeZone: timeZone) {
            fastTagStore.setSelection(selection, for: oldDate, timeZone: timeZone)
        }

        await manager.setHijriMonthAdjustment(
            for: components.month,
            hijriYear: components.hijriYear,
            offsetDays: 1
        )

        let newDate = calendar.gregorianDate(
            for: HijriYearMonth(hijriYear: components.hijriYear, month: components.month),
            dayOfMonth: components.day,
            timeZone: timeZone
        )
        #expect(newDate != nil)
        guard let newDate else { return }

        #expect(alarmConfigStore.isDeletedDate(on: oldDate, timeZone: timeZone) == false)
        #expect(alarmConfigStore.isDeletedDate(on: newDate, timeZone: timeZone) == true)
        #expect(alarmConfigStore.override(for: oldDate, timeZone: timeZone) == nil)
        #expect(alarmConfigStore.override(for: newDate, timeZone: timeZone)?.skipDay == true)
        #expect(fastTagStore.selection(for: oldDate, timeZone: timeZone) == nil)
        #expect(fastTagStore.selection(for: newDate, timeZone: timeZone) != nil)

        let pending = changeStore.pendingChanges()
        #expect(pending.isEmpty == false)
    }

    @Test
    @MainActor
    func alarmConfigMigrationTurnsAllDefaultsOnWithoutDroppingOverrides() throws {
        let suiteName = "ScheduleManagerHijriTests.DefaultMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyDefaults = DefaultAlarmConfig(
            suhoorEnabledDefault: false,
            reminderEnabledDefault: false,
            fajrEnabledDefault: false,
            defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
            defaultSuhoorOffsetMinutes: 30,
            defaultReminderTimeMode: .beforeFajr,
            defaultReminderMinutesBeforeFajr: 10,
            defaultReminderFixedTimeMinutes: 0,
            activationMode: .alwaysOn,
            activeStartDate: nil,
            activeEndDate: nil,
            scheduleWindowDays: 14
        )
        defaults.set(try JSONEncoder().encode(legacyDefaults), forKey: "Suhoor.DefaultAlarmConfig")

        let date = Self.makeDate(year: 2026, month: 3, day: 3)
        var override = DailyAlarmOverride(date: date)
        override.skipDay = true
        override.suhoorOffsetOverrideMinutes = 45
        defaults.set(
            try JSONEncoder().encode([DateHelpers.dayIdentifier(for: date, timeZone: .current): override]),
            forKey: "Suhoor.DailyAlarmOverrides"
        )

        let store = AlarmConfigStore(defaultsStore: defaults)

        #expect(store.defaults.suhoorEnabledDefault == true)
        #expect(store.defaults.reminderEnabledDefault == true)
        #expect(store.defaults.fajrEnabledDefault == true)
        #expect(store.override(for: date)?.skipDay == true)
        #expect(store.override(for: date)?.suhoorOffsetOverrideMinutes == 45)
    }

    @Test
    @MainActor
    func dayMasterToggleRestoresDefaultsWhenEverythingWasExplicitlyOff() {
        let suiteName = "ScheduleManagerHijriTests.DayToggleRestore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlarmConfigStore(defaultsStore: defaults)
        let date = Self.makeDate(year: 2026, month: 3, day: 3)
        store.addSingleDaySource(date)
        store.updateOverride(for: date) { override in
            override.suhoorEnabled = false
            override.reminderEnabled = false
            override.fajrEnabled = false
        }

        store.setDayEnabled(true, for: date)

        let ruleEngine = RuleEngine(
            settings: .default,
            defaultConfig: store.defaults,
            overridesByDay: store.overridesByDay,
            timeZone: .current
        )
        let config = store.effectiveConfig(
            for: date,
            ruleSummary: ruleEngine.ruleSummary(for: date),
            settings: .default,
            timeZone: .current
        )

        #expect(config.hasAnyEnabled == true)
        #expect(config.suhoorEnabled == true)
        #expect(config.reminderEnabled == true)
        #expect(config.fajrEnabled == true)
    }

    @Test
    @MainActor
    func dayMasterTogglePreservesMixedOverridesAcrossOffAndOn() {
        let suiteName = "ScheduleManagerHijriTests.DayTogglePreserve"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlarmConfigStore(defaultsStore: defaults)
        let date = Self.makeDate(year: 2026, month: 3, day: 4)
        store.addSingleDaySource(date)
        store.updateOverride(for: date) { override in
            override.suhoorEnabled = false
            override.reminderEnabled = true
            override.fajrEnabled = false
        }

        store.setDayEnabled(false, for: date)
        store.setDayEnabled(true, for: date)

        let override = store.override(for: date)
        #expect(override?.skipDay == false)
        #expect(override?.suhoorEnabled == false)
        #expect(override?.reminderEnabled == true)
        #expect(override?.fajrEnabled == false)
    }

    @Test
    func ashuraQuickAddPatternsResolveExpectedDates() {
        let suiteName = "ScheduleManagerHijriTests.AshuraPatterns"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let calendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(
                baselineProvider: HijriBaselineMonthStarts.starts,
                adjustmentStore: adjustmentStore
            )
        )
        let generator = IslamicQuickAddGenerator(adjustedHijriCalendar: calendar)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let startDate = Self.makeDate(year: 2025, month: 6, day: 20)

        let nineTen = generator.ashuraDates(for: .nineTen, startDate: startDate, timeZone: timeZone)
        let tenEleven = generator.ashuraDates(for: .tenEleven, startDate: startDate, timeZone: timeZone)
        let allThree = generator.ashuraDates(for: .allThree, startDate: startDate, timeZone: timeZone)

        #expect(nineTen.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) } == ["2025-07-04", "2025-07-05"])
        #expect(tenEleven.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) } == ["2025-07-05", "2025-07-06"])
        #expect(allThree.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) } == ["2025-07-04", "2025-07-05", "2025-07-06"])
        #expect(generator.recommendedAshuraPattern(startDate: startDate, timeZone: timeZone) == .nineTen)

        let laterStart = Self.makeDate(year: 2025, month: 7, day: 5)
        #expect(generator.recommendedAshuraPattern(startDate: laterStart, timeZone: timeZone) == .tenEleven)

        adjustmentStore.setAdjustment(for: HijriYearMonth(hijriYear: 1447, month: .muharram), offsetDays: 1)
        let shifted = generator.ashuraDates(for: .nineTen, startDate: startDate, timeZone: timeZone)
        #expect(shifted.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) } == ["2025-07-05", "2025-07-06"])
    }

    @Test
    @MainActor
    func ashuraQuickAddAvailabilityReflectsActiveDates() {
        let suiteName = "ScheduleManagerHijriTests.AshuraAvailability"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlarmConfigStore(defaultsStore: defaults)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let startDate = Self.makeDate(year: 2025, month: 6, day: 20)
        let firstDate = Self.makeDate(year: 2025, month: 7, day: 4)
        let secondDate = Self.makeDate(year: 2025, month: 7, day: 5)

        store.addSingleDaySource(firstDate, timeZone: timeZone)

        let partial = store.ashuraQuickAddAvailability(.nineTen, startDate: startDate, timeZone: timeZone)
        #expect(partial.state == .partial)
        #expect(partial.addResult.addedDates == [secondDate])
        #expect(partial.addResult.skippedActiveDates == [firstDate])

        store.addSingleDaySource(secondDate, timeZone: timeZone)

        let disabled = store.ashuraQuickAddAvailability(.nineTen, startDate: startDate, timeZone: timeZone)
        #expect(disabled.state == .disabled)
        #expect(disabled.addResult.addedDates.isEmpty)
        #expect(disabled.addResult.skippedActiveDates.count == 2)
    }

    @Test
    @MainActor
    func recurringWhiteDaysDefaultsToVoluntaryTagsWithoutStoredSelections() async {
        let suiteName = "ScheduleManagerHijriTests.RecurringDefaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let recurringStartDate = Self.makeDate(year: 2026, month: 3, day: 20, timeZone: timeZone)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let fastTagStore = FastTagStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
        )

        let added = await manager.addRecurringIslamicRule(
            .whiteDays,
            startDate: recurringStartDate,
            timeZone: timeZone
        )
        #expect(added == true)
        guard let activeDay = manager.activeWindowSnapshot.visibleDays.first(where: {
            $0.provenances.contains(where: { $0.sourceOrigin == .recurringIslamic(.whiteDays) })
        }) else {
            Issue.record("Expected a visible recurring white-days entry.")
            return
        }

        #expect(fastTagStore.selection(for: activeDay.date, timeZone: timeZone) == nil)
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
                kind: .singleDay(SingleDaySource(dateKey: "2026-03-03", date: Self.makeDate(year: 2026, month: 3, day: 3))),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualSingleDay,
                groupID: nil
            ),
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(SingleDaySource(dateKey: "2026-03-20", date: Self.makeDate(year: 2026, month: 3, day: 20))),
                createdAt: Date(),
                isEnabled: true,
                origin: .islamicQuickAdd(.nextEidAlFitr),
                groupID: nil
            ),
            ScheduledDateSource(
                id: UUID(),
                kind: .recurringIslamic(RecurringIslamicSource(rule: .ramadan, startDate: Self.makeDate(year: 2026, month: 2, day: 18))),
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
        let testDate = Self.makeDate(year: 2026, month: 3, day: 3)
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
        let testDate = Self.makeDate(year: 2026, month: 3, day: 4)
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

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0) ?? .current
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

}
