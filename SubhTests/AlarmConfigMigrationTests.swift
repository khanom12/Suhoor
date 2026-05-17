import Foundation
import CoreLocation
import Testing
@testable import Subh

@Suite
@MainActor
struct AlarmConfigMigrationTests {
    @Test
    func debugInstallResetClearsStateOnFirstFingerprint() {
        let suiteName = "SubhTests.DebugInstallReset.FirstFingerprint"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("stale", forKey: "Suhoor.DefaultAlarmConfig")
        var resetCount = 0

        let didReset = DeveloperInstallReset.resetIfNeeded(
            defaults: defaults,
            bundleIdentifier: suiteName,
            fingerprint: "debug-build-a",
            mode: .onInstallChange
        ) {
            resetCount += 1
        }

        #expect(didReset)
        #expect(resetCount == 1)
        #expect(defaults.string(forKey: "Suhoor.DefaultAlarmConfig") == nil)
        #expect(defaults.string(forKey: DeveloperInstallReset.fingerprintKey) == "debug-build-a")
    }

    @Test
    func debugInstallResetSkipsMatchingFingerprint() {
        let suiteName = "SubhTests.DebugInstallReset.MatchingFingerprint"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("debug-build-a", forKey: DeveloperInstallReset.fingerprintKey)
        defaults.set("kept", forKey: "Suhoor.DefaultAlarmConfig")
        var resetCount = 0

        let didReset = DeveloperInstallReset.resetIfNeeded(
            defaults: defaults,
            bundleIdentifier: suiteName,
            fingerprint: "debug-build-a",
            mode: .onInstallChange
        ) {
            resetCount += 1
        }

        #expect(didReset == false)
        #expect(resetCount == 0)
        #expect(defaults.string(forKey: "Suhoor.DefaultAlarmConfig") == "kept")
        #expect(defaults.string(forKey: DeveloperInstallReset.fingerprintKey) == "debug-build-a")
    }

    @Test
    func debugInstallResetClearsStateWhenFingerprintChanges() {
        let suiteName = "SubhTests.DebugInstallReset.ChangedFingerprint"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("debug-build-a", forKey: DeveloperInstallReset.fingerprintKey)
        defaults.set("stale", forKey: "Suhoor.DefaultAlarmConfig")
        var resetCount = 0

        let didReset = DeveloperInstallReset.resetIfNeeded(
            defaults: defaults,
            bundleIdentifier: suiteName,
            fingerprint: "debug-build-b",
            mode: .onInstallChange
        ) {
            resetCount += 1
        }

        #expect(didReset)
        #expect(resetCount == 1)
        #expect(defaults.string(forKey: "Suhoor.DefaultAlarmConfig") == nil)
        #expect(defaults.string(forKey: DeveloperInstallReset.fingerprintKey) == "debug-build-b")
    }

    @Test
    func freshDefaultsUseSubhFajrEndWake() {
        let suiteName = "SubhTests.AlarmConfig.FreshDefaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AlarmConfigStore(defaultsStore: defaults)

        #expect(store.defaults.defaultWakeState == .inFajr)
        #expect(store.defaults.defaultWakeAnchorType == .fajrEnd)
        #expect(store.defaults.defaultWakeDeltaMinutes == 30)
        #expect(store.defaults.defaultWakeRule.anchorType == .fajrEnd)
    }

    @Test
    func debugInstallResetIsDisabledByDefault() {
        let suiteName = "SubhTests.DebugInstallReset.DisabledByDefault"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("kept", forKey: "Suhoor.DefaultAlarmConfig")

        let didReset = DeveloperInstallReset.resetIfNeeded(
            defaults: defaults,
            bundleIdentifier: suiteName,
            fingerprint: "debug-build-a"
        )

        #expect(didReset == false)
        #expect(defaults.string(forKey: "Suhoor.DefaultAlarmConfig") == "kept")
    }

    @Test
    func debugInstallResetModeCanBeSetFromEnvironment() {
        let suiteName = "SubhTests.DebugInstallReset.ModeEnvironment"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let mode = DeveloperInstallReset.configuredMode(
            defaults: defaults,
            environment: [DeveloperInstallReset.modeEnvironmentKey: "onInstallChange"]
        )

        #expect(mode == .onInstallChange)
    }

    @Test
    func debugInstallResetModeCanBeSetFromDefaults() {
        let suiteName = "SubhTests.DebugInstallReset.ModeDefaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("on-install-change", forKey: DeveloperInstallReset.modeDefaultsKey)

        let mode = DeveloperInstallReset.configuredMode(
            defaults: defaults,
            environment: [:]
        )

        #expect(mode == .onInstallChange)
    }

    @Test
    func oldFactoryDefaultMigratesToSubhDefault() throws {
        let suiteName = "SubhTests.AlarmConfig.LegacyFactoryMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            try JSONEncoder().encode(DefaultAlarmConfig.legacySuhoorFactoryDefault),
            forKey: "Suhoor.DefaultAlarmConfig"
        )
        defaults.set(3, forKey: "Suhoor.AlarmConfigMigrationVersion")

        let store = AlarmConfigStore(defaultsStore: defaults)

        #expect(store.defaults.defaultWakeState == .inFajr)
        #expect(store.defaults.defaultWakeAnchorType == .fajrEnd)
        #expect(store.defaults.defaultWakeDeltaMinutes == 30)

        let persistedData = try #require(defaults.data(forKey: "Suhoor.DefaultAlarmConfig"))
        let persisted = try JSONDecoder().decode(DefaultAlarmConfig.self, from: persistedData)
        #expect(persisted.defaultWakeState == .inFajr)
        #expect(persisted.defaultWakeAnchorType == .fajrEnd)
        #expect(persisted.defaultWakeDeltaMinutes == 30)
    }

    @Test
    func oldFortyFiveMinuteFajrStartDefaultMigratesToSubhDefault() throws {
        let suiteName = "SubhTests.AlarmConfig.LegacyFortyFiveMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var legacyDefault = DefaultAlarmConfig.legacySuhoorFactoryDefault
        legacyDefault.defaultWakeDeltaMinutes = 45
        legacyDefault.defaultSuhoorOffsetMinutes = 45
        defaults.set(try JSONEncoder().encode(legacyDefault), forKey: "Suhoor.DefaultAlarmConfig")
        defaults.set(4, forKey: "Suhoor.AlarmConfigMigrationVersion")

        let store = AlarmConfigStore(defaultsStore: defaults)

        #expect(store.defaults.defaultWakeState == .inFajr)
        #expect(store.defaults.defaultWakeAnchorType == .fajrEnd)
        #expect(store.defaults.defaultWakeDeltaMinutes == 30)
        #expect(store.defaults.defaultWakeRule.anchorType == .fajrEnd)
    }

    @Test
    func migratedFortyFiveMinuteDefaultFeedsResolvedDailyConfig() throws {
        let suiteName = "SubhTests.AlarmConfig.LegacyFortyFiveEffectiveConfig"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var legacyDefault = DefaultAlarmConfig.legacySuhoorFactoryDefault
        legacyDefault.defaultWakeDeltaMinutes = 45
        legacyDefault.defaultSuhoorOffsetMinutes = 45
        defaults.set(try JSONEncoder().encode(legacyDefault), forKey: "Suhoor.DefaultAlarmConfig")
        defaults.set(4, forKey: "Suhoor.AlarmConfigMigrationVersion")

        let store = AlarmConfigStore(defaultsStore: defaults)
        let config = ActiveDayResolver.effectiveConfig(
            for: Date(timeIntervalSince1970: 1_767_139_200),
            settings: .default,
            defaultConfig: store.defaults,
            overridesByDay: [:],
            additionalDefaultsActive: true,
            timeZone: TimeZone(identifier: "America/Toronto") ?? .current
        )

        #expect(config.resolvedWakeRule.state == .inFajr)
        #expect(config.resolvedWakeRule.anchorType == .fajrEnd)
        #expect(config.resolvedWakeRule.deltaMinutes == 30)
        #expect(config.suhoorOffsetMinutes == 30)
    }

    @Test
    func dayScheduleBuilderUsesFajrEndDefaultWakeRule() throws {
        let calculator = PrayerTimeCalculator()
        let builder = DayScheduleBuilder(calculator: calculator)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 10, timeZone: timeZone)
        let settings = AppSettings.default
        let coordinate = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        let config = ActiveDayResolver.effectiveConfig(
            for: date,
            settings: settings,
            defaultConfig: .default,
            overridesByDay: [:],
            additionalDefaultsActive: true,
            timeZone: timeZone
        )

        let schedule = try #require(
            builder.buildSchedule(
                for: date,
                coordinate: coordinate,
                timeZone: timeZone,
                method: settings.calculationMethod,
                adjustmentMinutes: settings.fajrAdjustmentMinutes,
                maghribAdjustmentMinutes: settings.maghribAdjustmentMinutes,
                effectiveConfig: config,
                locationDescription: "Test"
            )
        )
        let fajrEnd = try #require(
            calculator.sunriseDate(
                for: date,
                location: coordinate,
                timeZone: timeZone,
                adjustmentMinutes: 0
            )
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let expectedWake = calendar.date(byAdding: .minute, value: -30, to: fajrEnd)
        let prayerWindow = DailyPrayerWindow(
            date: date,
            fajrStart: schedule.fajrDate,
            fajrEnd: fajrEnd,
            maghrib: schedule.maghribDate
        )
        let anchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: date,
            wakeRule: config.resolvedWakeRule,
            timeZone: timeZone
        )
        let resolverWake = MorningScheduleResolver.resolveWakeTime(
            day: date,
            prayerWindow: prayerWindow,
            anchor: anchor,
            wakeRule: config.resolvedWakeRule,
            timeZone: timeZone
        )

        #expect(schedule.wakeDate == expectedWake)
        #expect(schedule.wakeDate == resolverWake.finalWakeTime)
        #expect(schedule.wakeDate > schedule.fajrDate)
        #expect(schedule.boundaryDate == nil)
    }

    @Test
    func scheduleManagerIgnoresWakeRuleMismatchedCache() throws {
        let suiteName = "SubhTests.AlarmConfig.StaleWakeRuleCache"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 10, timeZone: timeZone)
        let staleSchedule = Self.makeSchedule(for: date, timeZone: timeZone)
        let staleCache = ScheduleCacheStore.Cache(
            lastScheduledDate: date,
            lastUpdated: date,
            schedulingMode: .notifications,
            schedules: [staleSchedule],
            activeWindowSnapshot: nil,
            tagSelectionRevision: nil,
            wakeRuleSignature: "state=preFajr|anchor=fajrStart|delta=45"
        )
        defaults.set(try JSONEncoder().encode(staleCache), forKey: "Suhoor.ScheduleCache")

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

        #expect(manager.schedules.isEmpty)
        #expect(manager.activeWindowSnapshot.visibleDays.isEmpty)
    }

    @Test
    func customPersistedWakeDefaultIsPreserved() throws {
        let suiteName = "SubhTests.AlarmConfig.CustomWakePreserved"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        var custom = DefaultAlarmConfig.legacySuhoorFactoryDefault
        custom.defaultWakeDeltaMinutes = 60
        custom.defaultSuhoorOffsetMinutes = 60
        defaults.set(try JSONEncoder().encode(custom), forKey: "Suhoor.DefaultAlarmConfig")
        defaults.set(4, forKey: "Suhoor.AlarmConfigMigrationVersion")

        let store = AlarmConfigStore(defaultsStore: defaults)

        #expect(store.defaults.defaultWakeState == .preFajr)
        #expect(store.defaults.defaultWakeAnchorType == .fajrStart)
        #expect(store.defaults.defaultWakeDeltaMinutes == 60)
        #expect(store.defaults.defaultSuhoorOffsetMinutes == 60)
    }

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components) ?? .distantPast
    }

    private static func makeSchedule(for date: Date, timeZone: TimeZone) -> DaySchedule {
        let dayStart = DateHelpers.startOfDay(date, in: timeZone)
        let fajr = dayStart.addingTimeInterval(5 * 60 * 60)
        let wake = fajr.addingTimeInterval(-45 * 60)
        let maghrib = dayStart.addingTimeInterval(19 * 60 * 60)
        return DaySchedule(
            date: dayStart,
            fajrDate: fajr,
            maghribDate: maghrib,
            wakeDate: wake,
            reminderDate: nil,
            boundaryDate: nil,
            iftarDate: nil,
            locationDescription: "Stale",
            offsetMinutes: 45,
            calculationMethodName: "Stale",
            timeZone: timeZone
        )
    }
}

@Suite
struct MorningHomeSnapshotTests {
    @Test
    func mvpCardKindsStayFocusedOnFirstWaveHome() {
        #expect(MorningHomeSnapshot.mvpCardKinds == [
            .tomorrowMorning,
            .weeklyFajrcast,
            .morningcast
        ])
        #expect(MorningHomeSnapshot.maximumMorningcastCount == 7)
    }
}
