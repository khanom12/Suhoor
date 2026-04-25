import Foundation
import CoreLocation
import Testing
@testable import Subh

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
            hijriAdjustmentStore: adjustmentStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
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
    func islamicQuickAddDefaultsToVoluntaryTagsWithoutStoredSelections() async {
        let suiteName = "ScheduleManagerHijriTests.QuickAddTagFallback"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let fastTagStore = FastTagStore(defaults: defaults)
        let startDate = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)
        let result = alarmConfigStore.addIslamicQuickAdd(
            .nextMondayThursdayPair,
            startDate: startDate,
            timeZone: timeZone
        )
        #expect(result.addedDates.isEmpty == false)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)

        guard let targetDate = result.addedDates.first else {
            Issue.record("Expected at least one quick-add date.")
            return
        }
        guard let activeDay = manager.activeDay(for: targetDate, timeZone: timeZone) else {
            Issue.record("Expected quick-add date to resolve in the schedule manager.")
            return
        }

        #expect(fastTagStore.selection(for: targetDate, timeZone: timeZone) == nil)
        #expect(activeDay.tagResult.computedPrimaryIntent == .voluntary)
        #expect(activeDay.tagResult.computedSecondaryTags.contains(.mondayThursday))
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
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let initial = await manager.addIslamicQuickAdd(
            .nextMondayThursdayPair,
            startDate: startDate,
            timeZone: timeZone
        )
        #expect(initial.addedDates.count == 2)

        let availability = alarmConfigStore.islamicQuickAddAvailability(
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
            hijriAdjustmentChangeStore: changeStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
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
        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        fastTagStore.setSelection(selection, for: oldDate, timeZone: timeZone)
        #expect(fastTagStore.selection(for: oldDate, timeZone: timeZone) != nil)

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
            fastingReminderEnabledDefault: false,
            fajrEnabledDefault: false,
            iftarEnabledDefault: true,
            defaultWakeState: .preFajr,
            defaultWakeAnchorType: .fajrStart,
            defaultWakeDeltaMinutes: 30,
            defaultLatestWakeCapMinutesFromMidnight: nil,
            defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
            defaultSuhoorOffsetMinutes: 30,
            defaultReminderTimeMode: .beforeFajr,
            defaultReminderMinutesBeforeFajr: 10,
            defaultReminderFixedTimeMinutes: 0,
            defaultIftarDelivery: .notificationOnly,
            defaultIftarSoundChoice: .adhanSoft,
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
            override.iftarEnabled = false
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
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
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
        #expect(activeDay.tagResult.computedPrimaryIntent == .voluntary)
        #expect(activeDay.tagResult.computedSecondaryTags.contains(.whiteDays))
    }

    @Test
    @MainActor
    func ensureScheduleWindowRetagsWhenSelectionRevisionChanges() async {
        let suiteName = "ScheduleManagerHijriTests.TagRevisionRetag"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        guard let targetDate = Self.firstGregorianDate(
            onOrAfter: Self.makeDate(year: 2026, month: 4, day: 1, timeZone: timeZone),
            timeZone: timeZone,
            matcher: { weekday in weekday == 2 || weekday == 5 }
        ) else {
            Issue.record("Expected to find a Monday or Thursday within the next two weeks.")
            return
        }

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        alarmConfigStore.addSingleDaySource(targetDate, timeZone: timeZone)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: FastTagStore(defaults: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)
        try? await Task.sleep(nanoseconds: 600_000_000)

        let fastTagStore = FastTagStore(defaults: defaults)
        fastTagStore.setSelection(
            FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
            for: targetDate,
            timeZone: timeZone
        )

        let freshSettingsStore = SuhoorSettingsStore(defaults: defaults)
        freshSettingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let refreshedManager = ScheduleManager(
            settingsStore: freshSettingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await refreshedManager.ensureScheduleWindow(reason: .appLaunch)

        let key = DateHelpers.dayIdentifier(for: targetDate, timeZone: timeZone)
        guard let activeDay = refreshedManager.activeWindowSnapshot.byDateKey[key] else {
            Issue.record("Expected cached date to remain in the active window.")
            return
        }

        #expect(activeDay.tagResult.computedPrimaryIntent == .voluntary)
        #expect(activeDay.tagResult.computedSecondaryTags.contains(.mondayThursday))
    }

    @Test
    @MainActor
    func monthEntriesRetagAfterSelectionRevisionChanges() async {
        let suiteName = "ScheduleManagerHijriTests.MonthEntriesRetag"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        guard let targetDate = Self.firstGregorianDate(
            onOrAfter: Self.makeDate(year: 2026, month: 4, day: 1, timeZone: timeZone),
            timeZone: timeZone,
            matcher: { weekday in weekday == 2 || weekday == 5 }
        ) else {
            Issue.record("Expected to find a Monday or Thursday within the next two weeks.")
            return
        }

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        alarmConfigStore.addSingleDaySource(targetDate, timeZone: timeZone)
        let fastTagStore = FastTagStore(defaults: defaults)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)

        guard let monthKey = FastIntentEngine.hijriMonthKey(for: targetDate, timeZone: timeZone) else {
            Issue.record("Expected a hijri month key for the target date.")
            return
        }

        let dateKey = DateHelpers.dayIdentifier(for: targetDate, timeZone: timeZone)
        let initialEntries = await manager.monthEntries(for: monthKey, timeZone: timeZone)
        guard let initial = initialEntries.first(where: { $0.dateKey == dateKey }) else {
            Issue.record("Expected cached month entries to include the target date.")
            return
        }

        #expect(initial.tagResult.computedPrimaryIntent == .other)

        fastTagStore.setSelection(
            FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
            for: targetDate,
            timeZone: timeZone
        )

        let updatedEntries = await manager.monthEntries(for: monthKey, timeZone: timeZone)
        guard let updated = updatedEntries.first(where: { $0.dateKey == dateKey }) else {
            Issue.record("Expected updated month entries to include the target date.")
            return
        }

        #expect(updated.tagResult.computedPrimaryIntent == .voluntary)
        #expect(updated.tagResult.computedSecondaryTags.contains(.mondayThursday))
    }

    @Test
    @MainActor
    func recurringMondayThursdayStopsAfterOneHijriYear() {
        let suiteName = "ScheduleManagerHijriTests.RecurringHijriYearBound"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let adjustedCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        guard let startDate = Self.firstDateMatching(
            start: Self.makeDate(year: 2026, month: 6, day: 1, timeZone: timeZone),
            timeZone: timeZone,
            adjustedCalendar: adjustedCalendar,
            matcher: { components, _ in
                components.month == .muharram && components.day <= 5
            }
        ) else {
            Issue.record("Expected to find an early Muharram date.")
            return
        }

        let store = AlarmConfigStore(defaultsStore: defaults)
        #expect(store.addRecurringIslamicSource(.mondayThursday, startDate: startDate, timeZone: timeZone) == true)

        let recurringEntries = store.resolvedScheduledEntries(from: startDate, limit: 160, timeZone: timeZone)
            .filter { entry in
                entry.provenances.contains { $0.sourceOrigin == .recurringIslamic(.mondayThursday) }
            }
        #expect(recurringEntries.isEmpty == false)

        guard let startComponents = adjustedCalendar.adjustedComponents(for: startDate, timeZone: timeZone) else {
            Issue.record("Expected adjusted Hijri components for recurring start date.")
            return
        }
        let startMonth = HijriYearMonth(hijriYear: startComponents.hijriYear, month: startComponents.month)
        guard
            let monthAfterWindow = startMonth.advanced(byMonths: 12),
            let endExclusive = adjustedCalendar.gregorianDate(
                for: monthAfterWindow,
                dayOfMonth: 1,
                timeZone: timeZone
            )
        else {
            Issue.record("Expected a recurring horizon boundary.")
            return
        }

        #expect(recurringEntries.allSatisfy { $0.date < endExclusive })

        guard let firstFutureMatch = Self.firstGregorianDate(
            onOrAfter: endExclusive,
            timeZone: timeZone,
            matcher: { weekday in weekday == 2 || weekday == 5 }
        ) else {
            Issue.record("Expected a Monday or Thursday after the recurring horizon.")
            return
        }

        #expect(store.provenance(for: firstFutureMatch, timeZone: timeZone).isEmpty)
    }

    @Test
    @MainActor
    func recurringWhiteDaysStartsFromCurrentHijriMonthForwardOnly() {
        let suiteName = "ScheduleManagerHijriTests.WhiteDaysMidMonth"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let adjustedCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        guard let startDate = Self.firstDateMatching(
            start: Self.makeDate(year: 2026, month: 1, day: 1, timeZone: timeZone),
            timeZone: timeZone,
            adjustedCalendar: adjustedCalendar,
            matcher: { components, _ in components.day == 14 && components.month != .ramadan }
        ) else {
            Issue.record("Expected to find a mid-month White Days start date.")
            return
        }

        let store = AlarmConfigStore(defaultsStore: defaults)
        #expect(store.addRecurringIslamicSource(.whiteDays, startDate: startDate, timeZone: timeZone) == true)

        let recurringEntries = store.resolvedScheduledEntries(from: startDate, limit: 48, timeZone: timeZone)
            .filter { entry in
                entry.provenances.contains { $0.sourceOrigin == .recurringIslamic(.whiteDays) }
            }
        #expect(recurringEntries.isEmpty == false)

        guard let startComponents = adjustedCalendar.adjustedComponents(for: startDate, timeZone: timeZone) else {
            Issue.record("Expected adjusted Hijri components for White Days start date.")
            return
        }
        let startMonth = HijriYearMonth(hijriYear: startComponents.hijriYear, month: startComponents.month)
        guard
            let day13 = adjustedCalendar.gregorianDate(for: startMonth, dayOfMonth: 13, timeZone: timeZone),
            let day15 = adjustedCalendar.gregorianDate(for: startMonth, dayOfMonth: 15, timeZone: timeZone)
        else {
            Issue.record("Expected White Days within the start month.")
            return
        }

        let recurringKeys = Set(recurringEntries.map(\.dateKey))
        #expect(recurringKeys.contains(DateHelpers.dayIdentifier(for: startDate, timeZone: timeZone)))
        #expect(recurringKeys.contains(DateHelpers.dayIdentifier(for: day15, timeZone: timeZone)))
        #expect(recurringKeys.contains(DateHelpers.dayIdentifier(for: day13, timeZone: timeZone)) == false)
    }

    @Test
    @MainActor
    func recurringOverlapMergesToOneDateInEitherAddOrder() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        for (index, order) in [[RecurringIslamicRule.mondayThursday, .whiteDays], [.whiteDays, .mondayThursday]].enumerated() {
            let suiteName = "ScheduleManagerHijriTests.RecurringOverlapOrder\(index)"
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)

            let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
            let adjustedCalendar = AdjustedHijriCalendar(
                calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
            )
            guard let overlapDate = Self.firstDateMatching(
                start: Self.makeDate(year: 2026, month: 1, day: 1, timeZone: timeZone),
                timeZone: timeZone,
                adjustedCalendar: adjustedCalendar,
                matcher: { components, weekday in
                    components.month != .ramadan &&
                    (13...15).contains(components.day) &&
                    (weekday == 2 || weekday == 5)
                }
            ) else {
                Issue.record("Expected to find an overlapping White Days and Monday/Thursday date.")
                return
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let recurringStartDate = calendar.date(byAdding: .day, value: -30, to: overlapDate) ?? overlapDate
            let store = AlarmConfigStore(defaultsStore: defaults)

            for rule in order {
                #expect(store.addRecurringIslamicSource(rule, startDate: recurringStartDate, timeZone: timeZone) == true)
            }

            let provenance = store.provenance(for: overlapDate, timeZone: timeZone)
            #expect(provenance.contains { $0.sourceOrigin == .recurringIslamic(.mondayThursday) })
            #expect(provenance.contains { $0.sourceOrigin == .recurringIslamic(.whiteDays) })

            let overlapKey = DateHelpers.dayIdentifier(for: overlapDate, timeZone: timeZone)
            let resolved = store.resolvedScheduledEntries(from: recurringStartDate, limit: 120, timeZone: timeZone)
            #expect(resolved.filter { $0.dateKey == overlapKey }.count == 1)
        }
    }

    @Test
    @MainActor
    func stoppingOneRecurringSeriesKeepsOverlapActiveUntilBothAreRemoved() {
        let suiteName = "ScheduleManagerHijriTests.RecurringOverlapStop"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let adjustedCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        guard let overlapDate = Self.firstDateMatching(
            start: Self.makeDate(year: 2026, month: 1, day: 1, timeZone: timeZone),
            timeZone: timeZone,
            adjustedCalendar: adjustedCalendar,
            matcher: { components, weekday in
                components.month != .ramadan &&
                (13...15).contains(components.day) &&
                (weekday == 2 || weekday == 5)
            }
        ) else {
            Issue.record("Expected to find an overlapping recurring date.")
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let recurringStartDate = calendar.date(byAdding: .day, value: -30, to: overlapDate) ?? overlapDate
        let store = AlarmConfigStore(defaultsStore: defaults)
        #expect(store.addRecurringIslamicSource(.mondayThursday, startDate: recurringStartDate, timeZone: timeZone) == true)
        #expect(store.addRecurringIslamicSource(.whiteDays, startDate: recurringStartDate, timeZone: timeZone) == true)

        guard let mondayThursday = store.provenance(for: overlapDate, timeZone: timeZone)
            .first(where: { $0.sourceOrigin == .recurringIslamic(.mondayThursday) }) else {
            Issue.record("Expected Monday & Thursday provenance on overlap date.")
            return
        }

        store.stopSeries(for: mondayThursday)
        let remainingAfterFirstStop = store.provenance(for: overlapDate, timeZone: timeZone)
        #expect(remainingAfterFirstStop.contains { $0.sourceOrigin == .recurringIslamic(.whiteDays) })
        #expect(remainingAfterFirstStop.contains { $0.sourceOrigin == .recurringIslamic(.mondayThursday) } == false)

        guard let whiteDays = remainingAfterFirstStop
            .first(where: { $0.sourceOrigin == .recurringIslamic(.whiteDays) }) else {
            Issue.record("Expected White Days provenance to remain after stopping Monday & Thursday.")
            return
        }

        store.stopSeries(for: whiteDays)
        #expect(store.provenance(for: overlapDate, timeZone: timeZone).isEmpty)
    }

    @Test
    @MainActor
    func monthEntriesCanResolveFutureRollingMonthOutsideActiveWindow() async {
        let suiteName = "ScheduleManagerHijriTests.FutureMonthEntries"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let adjustedCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: HijriMonthAdjustmentStore(defaults: defaults))
        )

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            fastTagStore: FastTagStore(defaults: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let added = await manager.addRecurringIslamicRule(
            .whiteDays,
            startDate: Self.makeDate(year: 2026, month: 3, day: 20, timeZone: timeZone),
            timeZone: timeZone
        )
        #expect(added == true)

        guard
            let futureMonth = manager.rollingHijriMonths(count: 12, timeZone: timeZone).dropFirst(8).first
        else {
            Issue.record("Expected future month and visible horizon data.")
            return
        }

        let monthKey = HijriMonthKey(
            year: futureMonth.hijriYear,
            month: futureMonth.month.rawValue,
            title: "\(futureMonth.month.displayName) \(futureMonth.hijriYear)"
        )
        #expect(manager.cachedMonthEntries(for: monthKey) == nil)
        let entries = await manager.monthEntries(for: monthKey, timeZone: timeZone)
        #expect(manager.cachedMonthEntries(for: monthKey) != nil)
        #expect(entries.isEmpty == false)
        #expect(entries.allSatisfy {
            guard let components = adjustedCalendar.adjustedComponents(for: $0.date, timeZone: timeZone) else {
                return false
            }
            return components.hijriYear == futureMonth.hijriYear && components.month == futureMonth.month
        })
    }

    @Test
    @MainActor
    func monthEntriesRefreshAfterRecurringRulesChange() async {
        let suiteName = "ScheduleManagerHijriTests.MonthEntriesInvalidate"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            fastTagStore: FastTagStore(defaults: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let startDate = Self.makeDate(year: 2026, month: 3, day: 20, timeZone: timeZone)
        #expect(await manager.addRecurringIslamicRule(.whiteDays, startDate: startDate, timeZone: timeZone) == true)

        guard let targetMonth = manager.rollingHijriMonths(count: 12, timeZone: timeZone).dropFirst(1).first else {
            Issue.record("Expected a target month for cached browsing.")
            return
        }
        let monthKey = HijriMonthKey(
            year: targetMonth.hijriYear,
            month: targetMonth.month.rawValue,
            title: "\(targetMonth.month.displayName) \(targetMonth.hijriYear)"
        )

        let whiteDaysEntries = await manager.monthEntries(for: monthKey, timeZone: timeZone)
        #expect(whiteDaysEntries.contains(where: { $0.provenances.contains { $0.sourceOrigin == .recurringIslamic(.whiteDays) } }))

        #expect(await manager.addRecurringIslamicRule(.mondayThursday, startDate: startDate, timeZone: timeZone) == true)
        let refreshedEntries = await manager.monthEntries(for: monthKey, timeZone: timeZone)

        #expect(refreshedEntries.contains(where: { $0.provenances.contains { $0.sourceOrigin == .recurringIslamic(.whiteDays) } }))
        #expect(refreshedEntries.contains(where: { $0.provenances.contains { $0.sourceOrigin == .recurringIslamic(.mondayThursday) } }))
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
        let testDate = DateHelpers.startOfTomorrow(in: .current)
        let testDateKey = DateHelpers.dayIdentifier(for: testDate, timeZone: .current)
        alarmConfigStore.addSingleDaySource(testDate)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
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
        let testDate = DateHelpers.startOfTomorrow(in: .current)
        let testDateKey = DateHelpers.dayIdentifier(for: testDate, timeZone: .current)
        alarmConfigStore.addSingleDaySource(testDate)

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)
        #expect(manager.activeWindowSnapshot.byDateKey[testDateKey] != nil)

        locationService.lastLocation = nil
        await manager.refreshSchedules(force: true)

        #expect(manager.activeWindowSnapshot.byDateKey[testDateKey] != nil)
    }

    @Test
    @MainActor
    func morningPlanStoreSeedsLegacyCompatFromExistingPersistence() throws {
        let suiteName = "ScheduleManagerHijriTests.MorningPlanLegacyCompat"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(try JSONEncoder().encode(AppSettings.default), forKey: "Suhoor.AppSettings")

        let store = MorningPlanStore(
            defaults: defaults,
            legacySettings: .default,
            defaultConfig: .default
        )

        #expect(store.state.activationMode == .legacyCompat)
    }

    @Test
    @MainActor
    func freshInstallUsesDefaultDailyPlanProvenance() {
        let suiteName = "ScheduleManagerHijriTests.DailyPlanFreshInstall"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 1, day: 10, timeZone: timeZone)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let provenances = manager.provenance(for: date, timeZone: timeZone)
        #expect(provenances.map(\.sourceOrigin).contains(.defaultDailyPlan))
    }

    @Test
    @MainActor
    func legacyCompatDoesNotInjectDailyPlanProvenanceForExistingUsers() throws {
        let suiteName = "ScheduleManagerHijriTests.NoSurpriseDailyPlan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(try JSONEncoder().encode(AppSettings.default), forKey: "Suhoor.AppSettings")
        defaults.set(try JSONEncoder().encode(DefaultAlarmConfig.default), forKey: "Suhoor.DefaultAlarmConfig")
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 1, day: 10, timeZone: timeZone)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let provenances = manager.provenance(for: date, timeZone: timeZone)
        #expect(provenances.map(\.sourceOrigin).contains(.defaultDailyPlan) == false)
    }

    @Test
    @MainActor
    func resolverProducesDecisionLogAndKeepsBoundaryOptional() {
        let suiteName = "ScheduleManagerHijriTests.ResolverDecisionLog"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 1, day: 10, timeZone: timeZone)
        let settings = AppSettings.default
        let defaultConfig = DefaultAlarmConfig.legacySuhoorFactoryDefault
        let planStore = MorningPlanStore(
            defaults: defaults,
            legacySettings: settings,
            defaultConfig: defaultConfig
        )
        let effectiveConfig = Self.makeEffectiveConfig(
            date: date,
            settings: settings,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            fajrEnabled: false
        )
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let stateSnapshot = MorningStateSnapshot(
            settings: settings,
            defaultConfig: defaultConfig,
            morningPlanState: planStore.state,
            dateAssignments: [PlanDateAssignment(dateKey: dateKey, planID: "default-daily")],
            completionRecords: [],
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: dateKey,
                baselineOwed: 0,
                completed: 0,
                remaining: 0
            ),
            coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            timeZone: timeZone,
            locationDescription: "Toronto",
            fastTagSelections: [:],
            overridesByDateKey: [:]
        )
        let input = MorningScheduleResolutionInput(
            date: date,
            dateKey: dateKey,
            provenances: [Self.defaultDailyPlanProvenance()],
            effectiveConfig: effectiveConfig,
            tagResult: .empty,
            stateSnapshot: stateSnapshot
        )

        let resolution = MorningScheduleResolver.resolve(input: input)
        let boundaryEvent = resolution?.decisionLog.materializedEvents.first(where: { $0.type == .fajrBoundaryNotice })

        #expect(resolution != nil)
        #expect(resolution?.decisionLog.dateKey == dateKey)
        #expect(resolution?.decisionLog.materializedEvents.isEmpty == false)
        #expect(boundaryEvent != nil)
        #expect(boundaryEvent?.deliveryKinds.isEmpty == true)
        #expect(boundaryEvent?.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue)
        #expect(resolution?.resolvedDayContext.primaryContext == .standard)
    }

    @Test
    @MainActor
    func resolverMarksFixedTimeWakeAsCompatibilityOnly() {
        let suiteName = "ScheduleManagerHijriTests.FixedTimeCompatibility"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 1, day: 10, timeZone: timeZone)
        var settings = AppSettings.default
        settings.baseWakeOffsetMinutes = 45
        var defaultConfig = DefaultAlarmConfig.default
        defaultConfig.defaultSuhoorTimeMode = .fixedTime
        defaultConfig.defaultSuhoorOffsetMinutes = 255
        defaultConfig.fajrEnabledDefault = false
        let planStore = MorningPlanStore(
            defaults: defaults,
            legacySettings: settings,
            defaultConfig: defaultConfig
        )
        let effectiveConfig = Self.makeEffectiveConfig(
            date: date,
            settings: settings,
            suhoorTimeMode: .fixedTime,
            suhoorOffsetMinutes: 255,
            fajrEnabled: false
        )
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let stateSnapshot = MorningStateSnapshot(
            settings: settings,
            defaultConfig: defaultConfig,
            morningPlanState: planStore.state,
            dateAssignments: [PlanDateAssignment(dateKey: dateKey, planID: "default-daily")],
            completionRecords: [],
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: dateKey,
                baselineOwed: 0,
                completed: 0,
                remaining: 0
            ),
            coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            timeZone: timeZone,
            locationDescription: "Toronto",
            fastTagSelections: [:],
            overridesByDateKey: [:]
        )
        let input = MorningScheduleResolutionInput(
            date: date,
            dateKey: dateKey,
            provenances: [Self.defaultDailyPlanProvenance()],
            effectiveConfig: effectiveConfig,
            tagResult: .empty,
            stateSnapshot: stateSnapshot
        )

        let resolution = MorningScheduleResolver.resolve(input: input)

        #expect(resolution?.decisionLog.compatibilityNotes.contains("fixed_time_wake_compatibility") == true)
        #expect(resolution?.resolvedDayContext.supportingTags.contains(.fixedTimeCompatibility) == true)
    }

    @Test
    func legacyCompletionAdapterMapsFajrFastAndQadaConsequences() {
        let snapshot = LegacyCompletionAdapter.records(
            fajrEntries: [
                "2026-03-09": FajrLogEntry(
                    dateKey: "2026-03-09",
                    status: .completed,
                    updatedAt: Date(timeIntervalSince1970: 10)
                )
            ],
            fastEntries: [
                "2026-03-09": FastLogEntry(
                    dateKey: "2026-03-09",
                    status: .completed,
                    updatedAt: Date(timeIntervalSince1970: 20),
                    intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
                ),
                "2026-03-10": FastLogEntry(
                    dateKey: "2026-03-10",
                    status: .inProgress,
                    updatedAt: Date(timeIntervalSince1970: 30),
                    intentSnapshot: FastIntentSnapshot(primaryIntent: .voluntary, secondaryTags: [])
                )
            ],
            qadaBacklogState: QadaBacklogState(
                trackingStartDateKey: "2026-03-01",
                baselineOwed: 4
            )
        )

        #expect(snapshot.records.count == 3)
        #expect(snapshot.records.first(where: { $0.kind == .fajr })?.status == .completed)
        #expect(snapshot.records.first(where: { $0.dateKey == "2026-03-10" && $0.kind == .fast })?.status == .unknown)
        #expect(snapshot.qadaLedgerSnapshot.completed == 1)
        #expect(snapshot.qadaLedgerSnapshot.remaining == 3)
    }

    @Test
    func morningPlanResolverPrefersExplicitOverrideOverContextPlans() {
        let wakeRule = MorningWakeRule(
            state: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 45
        )
        let defaultPlan = MorningPlan(
            id: "default-daily",
            title: "Daily morning plan",
            kind: .defaultDaily,
            wakeRule: wakeRule,
            wakeAnchorType: .fajrStart,
            wakeDelta: WakeDelta(relation: .before, minutes: 45),
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: false,
            iftarReminderEnabled: false
        )
        let state = MorningPlanState(
            schemaVersion: 1,
            activationMode: .dailyActive,
            defaultDailyPlan: defaultPlan,
            lastMigrationAt: nil
        )
        let resolution = MorningPlanResolver.resolve(
            dateKey: "2026-03-09",
            provenances: [
                ResolvedScheduledDateProvenance(
                    sourceID: UUID(),
                    groupID: nil,
                    label: "Selected day",
                    stopSeriesLabel: nil,
                    isExplicitOneOff: true,
                    sourceOrigin: .manualSingleDay,
                )
            ],
            effectiveConfig: Self.makeEffectiveConfig(
                date: Self.makeDate(year: 2026, month: 3, day: 9, timeZone: TimeZone(identifier: "America/Toronto") ?? .current),
                settings: .default,
                suhoorTimeMode: .relativeToFajrMinusMinutes,
                suhoorOffsetMinutes: 30,
                fajrEnabled: false,
                hasOverrides: true
            ),
            tagResult: TagComputationResult(
                computedPrimaryIntent: .qadaMakeup,
                computedSecondaryTags: [],
                secondaryDetails: [:],
                suppressedSecondaryTags: []
            ),
            morningPlanState: state
        )

        #expect(resolution.selectedPlan.kind == MorningPlanKind.explicitDateOverride)
        #expect(resolution.precedenceReason == "Explicit single-date override takes precedence.")
    }

    @Test
    @MainActor
    func morningStateAssemblerBuildsCanonicalSnapshotFromLegacyInputs() {
        let suiteName = "ScheduleManagerHijriTests.MorningStateAssembler"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        var settings = AppSettings.default
        settings.isConfigured = true
        settings.locationMode = .fixed
        settings.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        settings.baseWakeOffsetMinutes = 35

        var defaultConfig = DefaultAlarmConfig.default
        defaultConfig.defaultSuhoorTimeMode = .fixedTime
        defaultConfig.defaultSuhoorOffsetMinutes = 305

        let morningPlanStore = MorningPlanStore(
            defaults: defaults,
            legacySettings: settings,
            defaultConfig: defaultConfig
        )

        let overrideDate = Self.makeDate(year: 2026, month: 3, day: 10, timeZone: timeZone)
        let qadaDate = Self.makeDate(year: 2026, month: 3, day: 11, timeZone: timeZone)
        let sourceDate = Self.makeDate(year: 2026, month: 3, day: 12, timeZone: timeZone)
        let forbiddenDate = Self.makeDate(year: 2026, month: 3, day: 13, timeZone: timeZone)

        var override = DailyAlarmOverride(date: overrideDate, timeZone: timeZone)
        override.suhoorOffsetOverrideMinutes = 20

        let overrideKey = DateHelpers.dayIdentifier(for: overrideDate, timeZone: timeZone)
        let qadaKey = DateHelpers.dayIdentifier(for: qadaDate, timeZone: timeZone)
        let sourceKey = DateHelpers.dayIdentifier(for: sourceDate, timeZone: timeZone)
        let forbiddenKey = DateHelpers.dayIdentifier(for: forbiddenDate, timeZone: timeZone)

        let snapshot = MorningStateAssembler.assemble(
            settings: settings,
            defaultConfig: defaultConfig,
            morningPlanStore: morningPlanStore,
            fastTagSelections: [
                qadaKey: FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: []),
                forbiddenKey: FastIntentSelection(primaryIntent: .forbidden, secondaryTags: [])
            ],
            fastLogEntries: [
                qadaKey: FastLogEntry(
                    dateKey: qadaKey,
                    status: .completed,
                    updatedAt: Date(timeIntervalSince1970: 200),
                    intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
                )
            ],
            fajrLogEntries: [
                overrideKey: FajrLogEntry(
                    dateKey: overrideKey,
                    status: .completed,
                    updatedAt: Date(timeIntervalSince1970: 100)
                )
            ],
            qadaBacklogState: QadaBacklogState(
                trackingStartDateKey: "2026-03-01",
                baselineOwed: 3
            ),
            qadaBatchState: QadaBatchState(
                plannedDateKeys: [qadaKey],
                targetCount: 1,
                pace: .steady,
                avoidShawwal: true,
                avoidImportantSunnah: true,
                createdAt: nil,
                updatedAt: nil
            ),
            overridesByDateKey: [overrideKey: override],
            coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            timeZone: timeZone,
            locationDescription: "Toronto",
            provenancesByDateKey: [
                sourceKey: [
                    ResolvedScheduledDateProvenance(
                        sourceID: UUID(),
                        groupID: nil,
                        label: "Selected day",
                        stopSeriesLabel: nil,
                        isExplicitOneOff: true,
                        sourceOrigin: .manualSingleDay
                    )
                ]
            ]
        )

        #expect(snapshot.morningPlanState.defaultDailyPlan.id == "default-daily")
        #expect(snapshot.morningPlanState.defaultDailyPlan.fixedWakeTimeCompatibilityMinutesFromMidnight == 305)
        #expect(snapshot.dateAssignments.contains(where: { $0.dateKey == overrideKey && $0.planID == "override-\(overrideKey)" }))
        #expect(snapshot.dateAssignments.contains(where: { $0.dateKey == qadaKey && $0.planID == "qada-\(qadaKey)" }))
        #expect(snapshot.dateAssignments.contains(where: { $0.dateKey == forbiddenKey && $0.planID == "context-\(forbiddenKey)" }))
        #expect(snapshot.dateAssignments.contains(where: { $0.dateKey == sourceKey && $0.planID == "source-\(sourceKey)" }))
        #expect(snapshot.completionRecords.count == 2)
        let overrideFajrRecord = snapshot.completionRecords.first {
            $0.dateKey == overrideKey && $0.kind == .fajr
        }
        let qadaFastRecord = snapshot.completionRecords.first {
            $0.dateKey == qadaKey && $0.kind == .fast
        }
        #expect(overrideFajrRecord?.status == .completed)
        #expect(qadaFastRecord?.status == .completed)
        #expect(snapshot.qadaLedgerSnapshot.completed == 1)
        #expect(snapshot.qadaLedgerSnapshot.remaining == 2)
    }

    @Test
    @MainActor
    func appNavigatorRoutesLiveNotificationsToMvpSurfaces() {
        let notificationCenter = NotificationCenter()
        let navigator = AppNavigator(notificationCenter: notificationCenter)

        notificationCenter.post(name: .switchToAlarmTab, object: nil)
        #expect(navigator.latestRequest?.intent == .switchToWake)

        AppNavigationBridge.send(.openHijriCorrections, notificationCenter: notificationCenter)
        #expect(navigator.latestRequest?.intent == .openHijriCorrections)
    }

    @Test
    @MainActor
    func fajrWindowCachingReusesDatasetAndOverlayWorkUntilRevisionChanges() async throws {
        let suiteName = "ScheduleManagerHijriTests.FajrWindowCaching"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.isConfigured = true
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)
        let firstSelectedKey = try #require(manager.activeWindowSnapshot.visibleDays.first?.dateKey)
        let secondSelectedKey = try #require(manager.activeWindowSnapshot.visibleDays.dropFirst().first?.dateKey)

        _ = manager.fajrWindowSurfaceSnapshot(
            period: .oneYear,
            overlay: .myWake,
            selectedDateKey: firstSelectedKey,
            timeZone: timeZone
        )
        let datasetBuildCount = manager.fajrWindowDatasetBuildCount

        _ = manager.fajrWindowSurfaceSnapshot(
            period: .oneYear,
            overlay: .myWake,
            selectedDateKey: secondSelectedKey,
            timeZone: timeZone
        )
        #expect(manager.fajrWindowDatasetBuildCount == datasetBuildCount)

        _ = manager.fajrWindowSurfaceSnapshot(
            period: .oneYear,
            overlay: .compareFasting,
            selectedDateKey: firstSelectedKey,
            timeZone: timeZone
        )
        let fastingOverlayBuildCount = manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0

        _ = manager.fajrWindowSurfaceSnapshot(
            period: .oneYear,
            overlay: .compareFasting,
            selectedDateKey: secondSelectedKey,
            timeZone: timeZone
        )
        #expect((manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0) == fastingOverlayBuildCount)

        await manager.refreshSchedules(force: true)
        _ = manager.fajrWindowSurfaceSnapshot(
            period: .oneYear,
            overlay: .myWake,
            selectedDateKey: firstSelectedKey,
            timeZone: timeZone
        )
        #expect(manager.fajrWindowDatasetBuildCount == datasetBuildCount + 1)
    }

    @Test
    @MainActor
    func fajrWindowDetailStoreDoesNotEagerlyBuildFastingOverlayOnLoadOrPeriodChange() async throws {
        let suiteName = "ScheduleManagerHijriTests.FajrWindowNoPrefetch"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .autoupdatingCurrent
        let manager = await makeConfiguredScheduleManager(defaults: defaults)
        let store = FajrWindowDetailStore()

        store.load(using: manager, timeZone: timeZone)
        #expect((manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0) == 0)

        store.setPeriod(.thirtyDays, using: manager, timeZone: timeZone)
        #expect((manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0) == 0)
    }

    @Test
    @MainActor
    func fajrWindowDetailStoreBuildsFastingOverlayOnDemandAndReusesCache() async throws {
        let suiteName = "ScheduleManagerHijriTests.FajrWindowOnDemandOverlay"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .autoupdatingCurrent
        let manager = await makeConfiguredScheduleManager(defaults: defaults)
        let store = FajrWindowDetailStore()

        store.load(using: manager, timeZone: timeZone)
        store.setOverlay(.compareFasting, using: manager, timeZone: timeZone)
        #expect(store.requestedOverlay == .compareFasting)

        await waitForFajrOverlayLoad(in: store)
        let firstBuildCount = manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0
        #expect(firstBuildCount == 1)

        store.setOverlay(.myWake, using: manager, timeZone: timeZone)
        store.setOverlay(.compareFasting, using: manager, timeZone: timeZone)
        await waitForFajrOverlayLoad(in: store)

        #expect((manager.fajrWindowOverlayBuildCounts[.compareFasting] ?? 0) == firstBuildCount)
    }

    @Test
    @MainActor
    func fajrWindowDetailStoreRefreshContextReloadsForTimezoneChanges() async throws {
        let suiteName = "ScheduleManagerHijriTests.FajrWindowRefreshContext"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let manager = await makeConfiguredScheduleManager(defaults: defaults)
        let store = FajrWindowDetailStore()
        let toronto = TimeZone(identifier: "America/Toronto") ?? .autoupdatingCurrent
        let london = TimeZone(identifier: "Europe/London") ?? .autoupdatingCurrent
        let now = Date(timeIntervalSince1970: 1_774_337_200)

        store.refreshIfNeeded(
            using: manager,
            refreshContext: .current(revision: manager.currentRevision, now: now, timeZone: toronto),
            timeZone: toronto
        )
        let initialBuildCount = manager.fajrWindowDatasetBuildCount
        #expect(initialBuildCount == 1)

        store.refreshIfNeeded(
            using: manager,
            refreshContext: .current(revision: manager.currentRevision, now: now, timeZone: toronto),
            timeZone: toronto
        )
        #expect(manager.fajrWindowDatasetBuildCount == initialBuildCount)

        store.refreshIfNeeded(
            using: manager,
            refreshContext: .current(revision: manager.currentRevision, now: now, timeZone: london),
            timeZone: london
        )
        #expect(manager.fajrWindowDatasetBuildCount == initialBuildCount + 1)
    }

    @Test
    @MainActor
    func wakeRowPresentationUsesResolvedStateAndAdjustmentCopy() async {
        let suiteName = "ScheduleManagerHijriTests.WakeRowPresentation"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.isConfigured = true
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let fastTagStore = FastTagStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore,
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.date(byAdding: .day, value: 1, to: DateHelpers.startOfDay(Date(), in: timeZone)) ?? Date()
        guard let tomorrow = Self.firstDateMatching(
            start: start,
            timeZone: timeZone,
            adjustedCalendar: AdjustedHijriCalendar.shared,
            matcher: { components, _ in
                components.month != .ramadan
            }
        ) else {
            Issue.record("Expected a future non-Ramadan date.")
            return
        }
        alarmConfigStore.addSingleDaySource(tomorrow, timeZone: timeZone)
        alarmConfigStore.updateOverride(for: tomorrow, timeZone: timeZone) { draft in
            draft.suhoorOffsetOverrideMinutes = 25
        }
        fastTagStore.setSelection(
            FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: []),
            for: tomorrow,
            timeZone: timeZone
        )

        await manager.refreshSchedules(force: true)

        guard let activeDay = manager.activeDay(for: tomorrow, timeZone: timeZone) else {
            Issue.record("Expected tomorrow to resolve as an active day.")
            return
        }

        let presentation = ProductSurfacePresentation.scheduleRowPresentation(for: activeDay, hasDayOverride: true)
        #expect(presentation.meaningText.isEmpty == false)
        #expect(presentation.stateLabel.isEmpty == false)
        #expect(presentation.secondaryExplanation == "Changed for this date")
        #expect(presentation.detailText.contains("before Fajr"))
        #expect(presentation.chipTitles.contains("Changed"))
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

    private static func firstDateMatching(
        start: Date,
        timeZone: TimeZone,
        adjustedCalendar: AdjustedHijriCalendar,
        matcher: (AdjustedHijriDateComponents, Int) -> Bool
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: start)

        for offset in 0..<730 {
            let candidate = calendar.date(byAdding: .day, value: offset, to: normalizedStart) ?? normalizedStart
            guard let components = adjustedCalendar.adjustedComponents(for: candidate, timeZone: timeZone) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            if matcher(components, weekday) {
                return candidate
            }
        }

        return nil
    }

    private static func firstGregorianDate(
        onOrAfter start: Date,
        timeZone: TimeZone,
        matcher: (Int) -> Bool
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: start)

        for offset in 0..<14 {
            let candidate = calendar.date(byAdding: .day, value: offset, to: normalizedStart) ?? normalizedStart
            if matcher(calendar.component(.weekday, from: candidate)) {
                return candidate
            }
        }

        return nil
    }

    private static func defaultDailyPlanProvenance() -> ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: DateHelpers.stableUUID(from: "suhoor.defaultDailyPlan"),
            groupID: nil,
            label: ScheduledDateSourceOrigin.defaultDailyPlan.label,
            stopSeriesLabel: nil,
            isExplicitOneOff: false,
            sourceOrigin: .defaultDailyPlan
        )
    }

    private static func makeEffectiveConfig(
        date: Date,
        settings: AppSettings,
        suhoorTimeMode: SuhoorTimeMode,
        suhoorOffsetMinutes: Int,
        fajrEnabled: Bool,
        hasOverrides: Bool = false
    ) -> EffectiveDailyConfig {
        let wakeRule = MorningWakeRule(
            state: suhoorTimeMode == .fixedTime ? .fixedWake : .preFajr,
            anchorType: suhoorTimeMode == .fixedTime ? .clockTime : .fajrStart,
            deltaMinutes: suhoorTimeMode == .fixedTime ? 0 : suhoorOffsetMinutes,
            fixedWakeTimeMinutesFromMidnight: suhoorTimeMode == .fixedTime ? suhoorOffsetMinutes : nil,
            isLegacyFixedWakeCompatibility: suhoorTimeMode == .fixedTime
        )
        return EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: true,
            fajrEnabled: fajrEnabled,
            iftarEnabled: false,
            defaultWakeRule: wakeRule,
            resolvedWakeRule: wakeRule,
            wakeRuleWasOverridden: hasOverrides,
            tahajjudRefinement: false,
            suhoorTimeMode: suhoorTimeMode,
            suhoorOffsetMinutes: suhoorOffsetMinutes,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: settings.reminderMinutesBeforeFajrGlobal,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
            iftarDelivery: .off,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: hasOverrides
        )
    }

    @MainActor
    private func makeConfiguredScheduleManager(defaults: UserDefaults) async -> ScheduleManager {
        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        settingsStore.update { draft in
            draft.isConfigured = true
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await manager.refreshSchedules(force: true)
        return manager
    }

    @MainActor
    private func waitForFajrOverlayLoad(in store: FajrWindowDetailStore) async {
        for _ in 0..<12 {
            if store.loadingOverlay == nil {
                return
            }
            await Task.yield()
        }
    }

}
