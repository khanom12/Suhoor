import CoreLocation
import CoreGraphics
import Foundation
import Testing
@testable import Subh

@Suite
struct ScheduleServiceExtractionTests {
    @Test
    @MainActor
    func refreshCoordinatorMergesRequestsUsingLatestReason() async {
        var received: [PendingScheduleRefresh] = []
        let coordinator = ScheduleRefreshCoordinator { request in
            received.append(request)
        }

        coordinator.requestRefresh(reason: .settingsChanged, force: false)
        coordinator.requestRefresh(reason: .manual, force: true)

        #expect(coordinator.pendingRefreshForTesting == PendingScheduleRefresh(reason: .manual, force: true))
        coordinator.cancelAll()
        #expect(received.isEmpty)
    }

    @Test
    @MainActor
    func refreshCoordinatorCancelDropsPendingRefresh() async {
        var received: [PendingScheduleRefresh] = []
        let coordinator = ScheduleRefreshCoordinator { request in
            received.append(request)
        }

        coordinator.requestRefresh(reason: .settingsChanged, force: true)
        coordinator.cancelAll()

        try? await Task.sleep(nanoseconds: 350_000_000)

        #expect(received.isEmpty)
    }

    @Test
    @MainActor
    func refreshCoordinatorDropsDuplicateLifecycleRequestsWhileRefreshIsScheduled() async {
        var received: [PendingScheduleRefresh] = []
        let coordinator = ScheduleRefreshCoordinator { request in
            received.append(request)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        coordinator.requestRefresh(reason: .appLaunch)
        coordinator.requestRefresh(reason: .foreground)
        coordinator.requestRefresh(reason: .foreground)

        #expect(coordinator.pendingRefreshForTesting == PendingScheduleRefresh(reason: .appLaunch, force: true))
        coordinator.cancelAll()
        #expect(received.isEmpty)
    }

    @Test
    func performanceTraceRecorderCapturesNamedOperations() {
        PerformanceTraceRecorder.shared.reset()

        _ = PerformanceTrace.measure("test.trace") {
            "done"
        }

        #expect(PerformanceTraceRecorder.shared.snapshot().contains { $0.name == "test.trace" })
    }

    @Test
    func activeDayResolverEffectiveConfigHonorsDailyActivationDefaults() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 10, timeZone: timeZone)
        var defaults = DefaultAlarmConfig.default
        defaults.activationMode = .dateRange
        defaults.activeStartDate = nil
        defaults.activeEndDate = nil

        let config = ActiveDayResolver.effectiveConfig(
            for: date,
            settings: .default,
            defaultConfig: defaults,
            overridesByDay: [:],
            additionalDefaultsActive: true,
            timeZone: timeZone
        )

        #expect(config.defaultsActive)
        #expect(config.suhoorEnabled == defaults.suhoorEnabledDefault)
        #expect(config.reminderEnabled == defaults.reminderEnabledDefault)
    }

    @Test
    @MainActor
    func dayScheduleBuilderClampsReminderToWake() {
        let builder = DayScheduleBuilder(calculator: PrayerTimeCalculator())
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 10, timeZone: timeZone)
        let settings = AppSettings.default
        let config = EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: true,
            fajrEnabled: true,
            iftarEnabled: false,
            defaultWakeRule: DefaultAlarmConfig.default.defaultWakeRule,
            resolvedWakeRule: DefaultAlarmConfig.default.defaultWakeRule,
            wakeRuleWasOverridden: true,
            tahajjudRefinement: false,
            suhoorTimeMode: .fixedTime,
            suhoorOffsetMinutes: 270,
            reminderTimeMode: .fixedTime,
            reminderMinutesBeforeFajr: settings.reminderMinutesBeforeFajrGlobal,
            reminderFixedTimeMinutes: 285,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
            iftarDelivery: .off,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: true
        )

        let schedule = builder.buildSchedule(
            for: date,
            coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            timeZone: timeZone,
            method: settings.calculationMethod,
            adjustmentMinutes: settings.fajrAdjustmentMinutes,
            maghribAdjustmentMinutes: settings.maghribAdjustmentMinutes,
            effectiveConfig: config,
            locationDescription: "Test"
        )

        #expect(schedule != nil)
        #expect(schedule?.wakeDate == schedule?.reminderDate)
    }

    @Test
    @MainActor
    func calculationMethodProfilesPreserveAnglesAndCanonicalIDs() throws {
        let expectations: [(CalculationMethod, String, Double)] = [
            (.muslimWorldLeague, "muslimWorldLeague", 18.0),
            (.northAmerica, "isna", 15.0),
            (.egyptian, "egyptianGeneralAuthority", 19.5),
            (.karachi, "karachi", 18.0),
            (.makkah, "ummAlQura", 18.5)
        ]

        for (method, canonicalID, angle) in expectations {
            #expect(method.canonicalID == canonicalID)
            #expect(method.fajrAngle == angle)
            #expect(method.profile.isBuiltIn)
        }

        let legacyNorthAmerica = try JSONDecoder().decode(CalculationMethod.self, from: Data(#""northAmerica""#.utf8))
        let legacyMakkah = try JSONDecoder().decode(CalculationMethod.self, from: Data(#""makkah""#.utf8))
        let legacyEgyptian = try JSONDecoder().decode(CalculationMethod.self, from: Data(#""egyptian""#.utf8))
        #expect(legacyNorthAmerica == .northAmerica)
        #expect(legacyMakkah == .makkah)
        #expect(legacyEgyptian == .egyptian)

        let encodedISNA = try JSONEncoder().encode(CalculationMethod.northAmerica)
        #expect(String(data: encodedISNA, encoding: .utf8) == #""isna""#)
    }

    @Test
    func localPrayerWindowUsesSelectedTimezoneDayOfYearAndRoundsToMinute() throws {
        let calculator = PrayerTimeCalculator()
        let instant = Self.makeDate(year: 2026, month: 1, day: 1, hour: 8, minute: 30, timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt)
        let honoluluTimeZone = TimeZone(identifier: "Pacific/Honolulu") ?? .current
        let kiritimatiTimeZone = TimeZone(identifier: "Pacific/Kiritimati") ?? .current

        let honolulu = try #require(calculator.localPrayerWindow(
            for: instant,
            location: CLLocationCoordinate2D(latitude: 21.3069, longitude: -157.8583),
            timeZone: honoluluTimeZone,
            method: .northAmerica,
            fajrBeginAdjustmentMinutes: 0,
            fajrEndAdjustmentMinutes: 0,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        ))
        let kiritimati = try #require(calculator.localPrayerWindow(
            for: instant,
            location: CLLocationCoordinate2D(latitude: 1.8721, longitude: -157.4278),
            timeZone: kiritimatiTimeZone,
            method: .muslimWorldLeague,
            fajrBeginAdjustmentMinutes: 0,
            fajrEndAdjustmentMinutes: 0,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        ))

        #expect(honolulu.diagnostics.dayOfYearUsed == 365)
        #expect(kiritimati.diagnostics.dayOfYearUsed == 1)
        #expect(Calendar(identifier: .gregorian).component(.second, from: honolulu.fajrStart) == 0)
        #expect(Calendar(identifier: .gregorian).component(.second, from: honolulu.fajrEnd ?? honolulu.fajrStart) == 0)
        #expect(Calendar(identifier: .gregorian).component(.second, from: honolulu.maghrib) == 0)
        #expect(honolulu.fajrEndSource == .solarSunrise)
    }

    @Test
    func localPrayerWindowAppliesBoundaryAdjustmentsIndependently() throws {
        let calculator = PrayerTimeCalculator()
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        let location = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)

        let base = try #require(calculator.localPrayerWindow(
            for: date,
            location: location,
            timeZone: timeZone,
            method: .northAmerica,
            fajrBeginAdjustmentMinutes: 0,
            fajrEndAdjustmentMinutes: 0,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        ))
        let beginAdjusted = try #require(calculator.localPrayerWindow(
            for: date,
            location: location,
            timeZone: timeZone,
            method: .northAmerica,
            fajrBeginAdjustmentMinutes: 5,
            fajrEndAdjustmentMinutes: 0,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        ))
        let endAdjusted = try #require(calculator.localPrayerWindow(
            for: date,
            location: location,
            timeZone: timeZone,
            method: .northAmerica,
            fajrBeginAdjustmentMinutes: 0,
            fajrEndAdjustmentMinutes: 5,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        ))

        #expect(beginAdjusted.fajrStart == base.fajrStart.addingTimeInterval(5 * 60))
        #expect(beginAdjusted.fajrEnd == base.fajrEnd)
        #expect(endAdjusted.fajrStart == base.fajrStart)
        #expect(endAdjusted.fajrEnd == base.fajrEnd?.addingTimeInterval(5 * 60))
        #expect(endAdjusted.adjustmentsApplied.fajrEndMinutes == 5)
    }

    @Test
    func localPrayerWindowRejectsInvalidBoundaryOrdering() {
        let calculator = PrayerTimeCalculator()
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)

        let invalid = calculator.localPrayerWindow(
            for: date,
            location: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            timeZone: timeZone,
            method: .northAmerica,
            fajrBeginAdjustmentMinutes: 500,
            fajrEndAdjustmentMinutes: -500,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
        )

        #expect(invalid == nil)
    }

    @Test
    @MainActor
    func activeWindowSnapshotBuilderPreservesResolvedEntryOrdering() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 10, timeZone: timeZone)
        let settings = AppSettings.default
        let defaults = DefaultAlarmConfig.default
        let coordinate = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        let planStore = MorningPlanStore(
            defaults: UserDefaults(suiteName: "ScheduleServiceExtractionTests.ActiveWindowBuilder") ?? .standard,
            legacySettings: settings,
            defaultConfig: defaults
        )
        let snapshot = MorningStateSnapshot(
            settings: settings,
            defaultConfig: defaults,
            morningPlanState: planStore.state,
            dateAssignments: [],
            completionRecords: [],
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: "2026-01-01",
                baselineOwed: 0,
                completed: 0,
                remaining: 0
            ),
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: "Test",
            fastTagSelections: [:],
            overridesByDateKey: [:]
        )
        let input = ActiveWindowBuildInput(
            stateSnapshot: snapshot,
            resolvedEntries: [
                ResolvedScheduledDateEntry(
                    date: date.addingTimeInterval(24 * 60 * 60),
                    dateKey: DateHelpers.dayIdentifier(for: date.addingTimeInterval(24 * 60 * 60), timeZone: timeZone),
                    provenances: [Self.defaultDailyPlanProvenance()]
                ),
                ResolvedScheduledDateEntry(
                    date: date,
                    dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                    provenances: [Self.defaultDailyPlanProvenance()]
                )
            ],
            visibleHorizonDays: 2,
            scheduledHorizonDays: 1,
            usesLegacyContexts: false
        )

        let snapshotResult = ActiveWindowSnapshotBuilder().build(input: input)

        #expect(snapshotResult.visibleDays.count == 2)
        #expect(snapshotResult.visibleDays.map(\.dateKey) == [
            DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
            DateHelpers.dayIdentifier(for: date.addingTimeInterval(24 * 60 * 60), timeZone: timeZone)
        ])
        #expect(snapshotResult.scheduledDays.count == 1)
        #expect(snapshotResult.scheduledDays.first?.dateKey == DateHelpers.dayIdentifier(for: date, timeZone: timeZone))
    }

    @Test
    func scheduleWindowReuseAcceptsCurrentDailyWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        let today = DateHelpers.startOfDay(now, in: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [
                Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay,
                Self.makeWakeEntry(date: tomorrow, timeZone: timeZone).activeDay
            ],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .appLaunch,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ))
    }

    @Test
    func scheduleWindowReuseRejectsStaleGeneratedDate() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        let yesterday = Self.makeDate(year: 2026, month: 4, day: 28, hour: 12, timeZone: timeZone)
        let today = DateHelpers.startOfDay(now, in: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: yesterday,
            visibleDays: [
                Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay,
                Self.makeWakeEntry(date: tomorrow, timeZone: timeZone).activeDay
            ],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .foreground,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ) == false)
    }

    @Test
    func scheduleWindowReuseRejectsDailyWindowMissingTomorrow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        let today = DateHelpers.startOfDay(now, in: timeZone)
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .appLaunch,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ) == false)
    }

    @Test
    func scheduleWindowReuseRejectsFutureRamadanOnlyWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        let ramadan1448Start = Self.makeDate(year: 2027, month: 2, day: 8, timeZone: timeZone)
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [Self.makeWakeEntry(date: ramadan1448Start, timeZone: timeZone).activeDay],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .appLaunch,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ) == false)
    }

    @Test
    func scheduleWindowReuseUsesLocalDayAcrossUtcBoundary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 0, minute: 30, timeZone: timeZone)
        let today = DateHelpers.startOfDay(now, in: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [
                Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay,
                Self.makeWakeEntry(date: tomorrow, timeZone: timeZone).activeDay
            ],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .foreground,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ))
    }

    @Test
    func scheduleWindowReuseRejectsClockAndTimezoneChanges() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        let today = DateHelpers.startOfDay(now, in: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [
                Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay,
                Self.makeWakeEntry(date: tomorrow, timeZone: timeZone).activeDay
            ],
            scheduledDays: [],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .timeChanged,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ) == false)
        #expect(ScheduleManager.shouldReuseScheduleWindow(
            reason: .timeZoneChanged,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone,
            requiresDailyWindow: true
        ) == false)
    }

    @Test
    func schedulingIdentifierSetIncludesCurrentLegacyAndEventIDs() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        let schedule = Self.makeSchedule(for: date, timeZone: timeZone)

        let identifiers = SchedulingIdentifierSet.forSchedule(schedule)

        #expect(identifiers.notificationIdentifiers.contains(SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake)))
        #expect(identifiers.notificationIdentifiers.contains(SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .wake)))
        #expect(identifiers.notificationIdentifiers.contains(SchedulingIdentifiers.legacyDailyIdentifierV1(for: schedule, kind: .wake)))
        #expect(identifiers.notificationIdentifiers.contains("\(schedule.id).wakeAlarm.wake"))
        #expect(identifiers.alarmIdentifiers.contains(SchedulingIdentifiers.alarmID(for: schedule, kind: .wake)))
        #expect(identifiers.alarmIdentifiers.contains(SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: .wake)))
        #expect(identifiers.alarmIdentifiers.contains(SchedulingIdentifiers.legacyAlarmIDV1(for: schedule, kind: .wake)))
    }

    @Test
    @MainActor
    func scheduleDayCancelsStaleIdentifiersWhenNoPriorPlanIsKnown() async {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let activeDay = Self.makeSchedulerActiveDay(
            date: Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone),
            timeZone: timeZone
        )
        let routineScheduler = RecordingRoutineScheduler()
        let scheduler = AlarmScheduler(routineScheduler: routineScheduler)

        let scheduled = await scheduler.scheduleDay(
            day: activeDay,
            settings: .default,
            canUseAlarmKit: false
        )

        #expect(scheduled)
        #expect(routineScheduler.cancelledIdentifierSets.count == 1)
        let cancelled = routineScheduler.cancelledIdentifierSets[0]
        #expect(cancelled.notificationIdentifiers.contains(SchedulingIdentifiers.legacyDailyIdentifierV1(for: activeDay.schedule, kind: .wake)))
        #expect(cancelled.alarmIdentifiers.contains(SchedulingIdentifiers.legacyAlarmIDV1(for: activeDay.schedule, kind: .wake)))
        #expect(routineScheduler.scheduledEventIdentifiers == [
            SchedulingIdentifiers.identifier(for: activeDay.scheduledEvents[0], deliveryKind: .wake)
        ])
    }

    @Test
    func deliveryReconciliationWarnsWhenOneOfSeveralNotificationsIsMissing() {
        let now = Date()
        let expected = [
            Self.expectedDelivery(
                identifier: "expected.one",
                alarmIDSeed: "alarm.one",
                fireDate: now.addingTimeInterval(600),
                channel: .notification
            ),
            Self.expectedDelivery(
                identifier: "expected.two",
                alarmIDSeed: "alarm.two",
                fireDate: now.addingTimeInterval(900),
                channel: .notification
            )
        ]

        let report = DeliveryReconciliation.report(
            mode: .notifications,
            generatedAt: now,
            expectedDeliveries: expected,
            pendingNotifications: [
                PendingNotificationDelivery(identifier: "expected.one", fireDate: expected[0].fireDate)
            ],
            pendingAlarms: []
        )

        #expect(report.expectedDeliveryCount == 2)
        #expect(report.missingNotificationIdentifiers == ["expected.two"])
        #expect(report.hasWarnings)
    }

    @Test
    func deliveryReconciliationWarnsWhenAlarmKitFireDateDiffers() {
        let now = Date()
        let alarmID = DateHelpers.stableUUID(from: "alarmkit.expected")
        let expected = Self.expectedDelivery(
            identifier: "notification.unused",
            alarmID: alarmID,
            fireDate: now.addingTimeInterval(600),
            channel: .alarmKit
        )

        let report = DeliveryReconciliation.report(
            mode: .alarmKit,
            generatedAt: now,
            expectedDeliveries: [expected],
            pendingNotifications: [],
            pendingAlarms: [
                ScheduledAlarmDelivery(id: alarmID, fireDate: expected.fireDate.addingTimeInterval(180))
            ]
        )

        #expect(report.mismatchedAlarmIdentifiers == [alarmID])
        #expect(report.hasWarnings)
    }

    @Test
    @MainActor
    func scheduleManagerRejectsCachedFebruaryRamadanWindowOnInitialization() throws {
        let suiteName = "ScheduleServiceExtractionTests.StaleRamadanCache"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone.current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        var settings = AppSettings.default
        settings.locationMode = .fixed
        settings.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        defaults.set(try JSONEncoder().encode(settings), forKey: "Suhoor.AppSettings")
        defaults.set(try JSONEncoder().encode(DefaultAlarmConfig.default), forKey: "Suhoor.DefaultAlarmConfig")

        let ramadan1448Start = Self.makeDate(year: 2027, month: 2, day: 8, timeZone: timeZone)
        let staleDay = Self.makeWakeEntry(date: ramadan1448Start, timeZone: timeZone).activeDay
        let staleSnapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [staleDay],
            scheduledDays: [staleDay],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )
        let staleCache = ScheduleCacheStore.Cache(
            lastScheduledDate: now,
            lastUpdated: now,
            schedulingMode: .notifications,
            schedules: [staleDay.schedule],
            activeWindowSnapshot: staleSnapshot,
            tagSelectionRevision: nil,
            wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: .default)
        )
        defaults.set(try JSONEncoder().encode(staleCache), forKey: "Suhoor.ScheduleCache")

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            usesLegacyContexts: false,
            cacheStore: ScheduleCacheStore(defaults: defaults),
            timeProvider: FixedTimeProvider(fixedNow: now)
        )

        #expect(manager.activeWindowSnapshot.visibleDays.isEmpty)
        #expect(manager.schedules.isEmpty)
    }

    @Test
    @MainActor
    func legacySettingsWithoutMorningPlanStateRefreshesFromCurrentDay() async throws {
        let suiteName = "ScheduleServiceExtractionTests.LegacySettingsDailyRefresh"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone.current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        var settings = AppSettings.default
        settings.locationMode = .fixed
        settings.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        defaults.set(try JSONEncoder().encode(settings), forKey: "Suhoor.AppSettings")
        defaults.set(try JSONEncoder().encode(DefaultAlarmConfig.default), forKey: "Suhoor.DefaultAlarmConfig")

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            usesLegacyContexts: false,
            cacheStore: ScheduleCacheStore(defaults: defaults),
            timeProvider: FixedTimeProvider(fixedNow: now)
        )

        await manager.refreshSchedules(force: true)

        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)
        let tomorrowKey = DateHelpers.dayIdentifier(
            for: DateHelpers.startOfTomorrow(in: timeZone, now: now),
            timeZone: timeZone
        )
        #expect(manager.activeWindowSnapshot.byDateKey[todayKey] != nil)
        #expect(manager.activeWindowSnapshot.byDateKey[tomorrowKey] != nil)
        #expect(manager.activeWindowSnapshot.visibleDays.first?.dateKey == todayKey)
        #expect(manager.activeWindowSnapshot.visibleDays.first?.dateKey != "2027-02-08")
    }

    @Test
    @MainActor
    func morningHomeSnapshotUsesInjectedCurrentDate() async throws {
        let suiteName = "ScheduleServiceExtractionTests.HomeUsesInjectedCurrentDate"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone.current
        let now = Self.makeDate(year: 2026, month: 4, day: 29, hour: 12, timeZone: timeZone)
        var settings = AppSettings.default
        settings.locationMode = .fixed
        settings.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        defaults.set(try JSONEncoder().encode(settings), forKey: "Suhoor.AppSettings")

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            usesLegacyContexts: false,
            cacheStore: ScheduleCacheStore(defaults: defaults),
            timeProvider: FixedTimeProvider(fixedNow: now)
        )

        await manager.refreshSchedules(force: true)
        let snapshot = manager.morningHomeSnapshot(timeZone: timeZone)

        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone, now: now)
        let tomorrowKey = DateHelpers.dayIdentifier(for: tomorrow, timeZone: timeZone)
        #expect(snapshot.tomorrow?.schedule.date == tomorrow)
        #expect(snapshot.weeklyFajrcast.selectedDay.dateKey == tomorrowKey)
    }

    @Test
    func tomorrowHeroSuppressesOrdinaryAndDiagnosticCopy() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let entry = Self.makeWakeEntry(
            date: Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone),
            timeZone: timeZone,
            providerNotes: "source:solar_sunrise_fajr_end"
        )

        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            locationDisplayText: "Toronto",
            currentDate: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(display.locationText == "Toronto")
        #expect(display.locationIconName == nil)
        #expect(display.title == "Tomorrow")
        #expect(display.dateLine == "April 27 • Dhul Qadah 10")
        #expect(display.dateLine?.contains("Mon") == false)
        #expect(display.dateLine?.contains("ZQ") == false)
        #expect(display.wakeState == .active)
        #expect(display.primaryTime == entry.schedule.wakeDate)
        #expect(display.primaryText.contains(":"))
        #expect(display.wakeIconName == "alarm.fill")
        #expect(display.statusText == "Wake alarm")
        #expect(display.detailText == "Wake up 30 min before Fajr ends")
        #expect(display.relationTone == .normal)
        #expect(Self.normalizedTimeSpaces(display.fajrWindowLine) == "Fajr begins: 5:00 AM • Fajr ends: 6:16 AM")
        #expect(Self.normalizedTimeSpaces(display.fajrBeginDisplayText ?? "") == "5:00 AM")
        #expect(Self.normalizedTimeSpaces(display.fajrEndDisplayText ?? "") == "6:16 AM")
        #expect(abs((display.wakeWindowPositionRatio ?? -1) - (46.0 / 76.0)) < 0.0001)
        #expect(display.wakeWindowIndicatorState == .active)
        #expect(display.wakeWindowIndicatorIconName == "alarm.fill")
        #expect(display.fajrWindowVisualMode == .interactiveWithinFajrWindow)
        #expect(display.wakeAdjustmentEnabled)
        #expect(display.wakeAdjustmentMinTime == entry.activeDay.decisionLog.prayerWindow.fajrStart)
        #expect(display.wakeAdjustmentMaxTime == entry.activeDay.decisionLog.prayerWindow.fajrEnd)
        #expect(display.wakeAdjustmentAccessibilityValue?.contains("Adjustable between Fajr begin") == true)
        #expect(display.wakeAdjustmentAccessibilityValue?.contains("Wake up 30 min before Fajr ends") == true)
        #expect(Self.normalizedTimeSpaces(display.fajrWindowAccessibilityText ?? "") == "Fajr begins: 5:00 AM. Fajr ends: 6:16 AM")
        #expect(display.chipTitles.isEmpty)
        #expect(display.accessibilityLabel.hasPrefix("Toronto. Tomorrow."))
        #expect(display.accessibilityLabel.contains("Wake alarm at"))
        #expect(Self.normalizedTimeSpaces(display.accessibilityLabel).contains("Fajr begins: 5:00 AM"))
        #expect(display.accessibilityLabel.contains("sunrise-derived") == false)
        #expect(display.accessibilityLabel.contains("Ordinary") == false)

        let adjustedWake = entry.activeDay.decisionLog.prayerWindow.fajrEnd?.addingTimeInterval(-28 * 60)
            ?? entry.schedule.wakeDate
        let adjusted = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: adjustedWake,
            timeZone: timeZone
        )
        #expect(adjusted.primaryTime == adjustedWake)
        #expect(adjusted.detailText == "Wake up 28 min before Fajr ends")
        #expect(adjusted.relationTone == .normal)
        #expect(abs((adjusted.wakeWindowPositionRatio ?? -1) - (48.0 / 76.0)) < 0.0001)

        let adjustedToStart = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: entry.activeDay.decisionLog.prayerWindow.fajrStart,
            timeZone: timeZone
        )
        #expect(adjustedToStart.detailText == "Wake up as Fajr begins")
        #expect(adjustedToStart.relationTone == .normal)

        let adjustedWithinStartGranularity = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: entry.activeDay.decisionLog.prayerWindow.fajrStart.addingTimeInterval(59),
            timeZone: timeZone
        )
        #expect(adjustedWithinStartGranularity.detailText == "Wake up as Fajr begins")
        #expect(adjustedWithinStartGranularity.relationTone == .normal)

        let adjustedToElevenBeforeEnd = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: (entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake).addingTimeInterval(-11 * 60),
            timeZone: timeZone
        )
        #expect(adjustedToElevenBeforeEnd.detailText == "Wake up 11 min before Fajr ends")
        #expect(adjustedToElevenBeforeEnd.relationTone == .normal)

        let adjustedToTenBeforeEnd = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: (entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake).addingTimeInterval(-10 * 60),
            timeZone: timeZone
        )
        #expect(adjustedToTenBeforeEnd.detailText == "Wake up 10 min before Fajr ends")
        #expect(adjustedToTenBeforeEnd.relationTone == .urgentRed)

        let adjustedToEnd = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake,
            timeZone: timeZone
        )
        #expect(adjustedToEnd.detailText == "Wake up as Fajr ends")
        #expect(adjustedToEnd.relationTone == .urgentRed)

        let adjustedWithinEndGranularity = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: (entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake).addingTimeInterval(-59),
            timeZone: timeZone
        )
        #expect(adjustedWithinEndGranularity.detailText == "Wake up as Fajr ends")
        #expect(adjustedWithinEndGranularity.relationTone == .urgentRed)
    }

    @Test
    func tomorrowHeroShowsAutomaticLocationIconWhenProvided() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let entry = Self.makeWakeEntry(
            date: Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone),
            timeZone: timeZone
        )

        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            locationDisplayText: "East York",
            locationIconName: "location.fill",
            currentDate: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(display.locationText == "East York")
        #expect(display.locationIconName == "location.fill")
        #expect(display.dateLine == "April 27 • Dhul Qadah 10")
        #expect(display.accessibilityLabel.hasPrefix("East York. Tomorrow."))
    }

    @Test
    func tomorrowHeroFallsBackToGregorianDateWithoutHijriDelimiter() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let entry = Self.makeWakeEntry(
            date: Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone),
            timeZone: timeZone
        )

        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            currentDate: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone,
            hijriDateTextProvider: { _, _ in nil },
            accessibleHijriDateTextProvider: { _, _ in nil }
        )

        #expect(display.dateLine == "April 27")
        #expect(display.dateLine?.contains("•") == false)
        #expect(display.dateLine?.contains("Mon") == false)
    }

    @Test
    func tomorrowHeroUsesMissingFajrFallbackWithoutInventingWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let entry = Self.makeWakeEntry(
            date: Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone),
            timeZone: timeZone,
            includeFajrEnd: false
        )

        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            currentDate: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(display.primaryTime == entry.schedule.wakeDate)
        #expect(display.detailText == "Fajr times are not available yet")
        #expect(display.fajrWindowLine == "Fajr times are not available yet")
        #expect(display.fajrBeginDisplayText == nil)
        #expect(display.fajrEndDisplayText == nil)
        #expect(display.wakeWindowPositionRatio == nil)
        #expect(display.wakeWindowIndicatorState == .unavailable)
        #expect(display.fajrWindowVisualMode == .hiddenUnavailable)
        #expect(display.wakeAdjustmentEnabled == false)
        #expect(display.fajrWindowAccessibilityText == nil)
        #expect(display.accessibilityLabel.contains("Fajr ends:") == false)
    }

    @Test
    func tomorrowHeroHidesV3RangeWhenFastingOrOutOfWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        let ordinarySuhoor = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .standard,
                    secondaryContexts: [.suhoor],
                    supportingTags: [],
                    explanation: .empty
                )
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let fasting = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .fasting,
                    secondaryContexts: [],
                    supportingTags: [.ramadan],
                    explanation: .empty
                )
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let outOfWindow = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                wakeOffsetMinutesFromFajrStart: -15
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let atFajrBegin = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                wakeOffsetMinutesFromFajrStart: 0
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let atFajrEnd = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                wakeOffsetMinutesFromFajrStart: 76
            ),
            permissionSummary: "",
            timeZone: timeZone
        )

        #expect(ordinarySuhoor.fajrWindowVisualMode == .interactiveWithinFajrWindow)
        #expect(ordinarySuhoor.wakeAdjustmentEnabled)
        #expect(ordinarySuhoor.fajrBeginDisplayText != nil)
        #expect(ordinarySuhoor.fajrEndDisplayText != nil)
        #expect(atFajrBegin.fajrWindowVisualMode == .interactiveWithinFajrWindow)
        #expect(atFajrBegin.wakeAdjustmentEnabled)
        #expect(atFajrBegin.wakeWindowPositionRatio == 0)
        #expect(atFajrEnd.fajrWindowVisualMode == .interactiveWithinFajrWindow)
        #expect(atFajrEnd.wakeAdjustmentEnabled)
        #expect(atFajrEnd.wakeWindowPositionRatio == 1)
        #expect(fasting.fajrWindowVisualMode == .hiddenFasting)
        #expect(fasting.wakeAdjustmentEnabled == false)
        #expect(outOfWindow.fajrWindowVisualMode == .hiddenOutOfWindow)
        #expect(outOfWindow.wakeAdjustmentEnabled == false)
        #expect(outOfWindow.fajrBeginDisplayText != nil)
        #expect(outOfWindow.fajrEndDisplayText != nil)
    }

    @Test
    func morningHeroWakeAdjustmentMapperClampsAndRounds() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let start = Self.makeDate(year: 2026, month: 4, day: 27, hour: 5, minute: 0, timeZone: timeZone)
        let end = start.addingTimeInterval(80 * 60)

        let beforeStart = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: -40,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 5
        )
        let atEnd = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: 160,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 5
        )
        let nearStartEdge = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: 3,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 1
        )
        let nearEndEdge = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: 157,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 1
        )
        let afterEnd = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: 240,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 5
        )
        let roundedMiddle = MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: 53,
            width: 160,
            minTime: start,
            maxTime: end,
            stepMinutes: 5
        )

        #expect(beforeStart == start)
        #expect(atEnd == end)
        #expect(nearStartEdge == start)
        #expect(nearEndEdge == end)
        #expect(afterEnd == end)
        #expect(abs(roundedMiddle.timeIntervalSince(start.addingTimeInterval(25 * 60))) < 1)
    }

    @Test
    func tomorrowHeroNamesMeaningfulMorningStates() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)

        let fasting = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .fasting,
                    secondaryContexts: [],
                    supportingTags: [.ramadan],
                    explanation: .empty
                )
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let qada = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .qadaFast,
                    secondaryContexts: [],
                    supportingTags: [.qada],
                    explanation: .empty
                )
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let tahajjud = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .tahajjud,
                    secondaryContexts: [],
                    supportingTags: [],
                    explanation: .empty
                )
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let changed = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(date: date, timeZone: timeZone, hasDayOverride: true),
            permissionSummary: "",
            timeZone: timeZone
        )
        let skipped = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(date: date, timeZone: timeZone, skipDay: true),
            permissionSummary: "",
            timeZone: timeZone
        )
        let fixed = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(date: date, timeZone: timeZone, plannedWakeState: .fixedWake),
            permissionSummary: "",
            timeZone: timeZone
        )

        #expect(fasting.statusText == "Fasting morning")
        #expect(qada.statusText == "Qada planned")
        #expect(tahajjud.statusText == "Tahajjud planned")
        #expect(changed.statusText == "Changed wake")
        #expect(skipped.wakeState == .offWithAnchor)
        #expect(skipped.primaryTime == nil)
        #expect(skipped.primaryText == "Alarm off")
        #expect(skipped.wakeIconName == "bell.slash.fill")
        #expect(skipped.statusText == "Alarm off")
        #expect(skipped.detailText == "Planned wake was 30 min before Fajr ends")
        #expect(skipped.relationTone == .normal)
        #expect(skipped.wakeWindowIndicatorState == .offAnchor)
        #expect(skipped.wakeWindowIndicatorIconName == "bell.slash.fill")
        #expect(skipped.wakeWindowPositionRatio != nil)
        #expect(skipped.fajrWindowVisualMode == .staticWithinFajrWindow)
        #expect(skipped.wakeAdjustmentEnabled == false)
        #expect(fixed.detailText == "Wake up 31 min before Fajr ends")
        #expect(fixed.relationTone == .normal)
    }

    @Test
    func morningcastEntriesStartWithTomorrow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let entries = (0..<4).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: today) ?? today,
                timeZone: timeZone
            )
        }

        let visible = MorningHomeSnapshot.morningcastEntries(
            from: entries,
            currentDate: today,
            timeZone: timeZone
        )

        #expect(visible.map(\.schedule.date) == Array(entries.dropFirst(1)).map(\.schedule.date))
    }

    @Test
    func nextTenMorningsForecastNamingIsStable() {
        #expect(MorningHomeSnapshot.forecastTitle == "NEXT 10 MORNINGS")

        let snapshot = MorningHomePresentation.nextTenMorningsSnapshot(from: [])
        #expect(snapshot.title == "NEXT 10 MORNINGS")
        #expect(snapshot.loadingState == .empty)
    }

    @Test
    func nextTenMorningsRowUsesGregorianDateTagsAndWakeTime() throws {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let seedDate = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        let ordinaryDate = Self.nextDateWithoutForecastOpportunity(startingAt: seedDate, timeZone: timeZone)
        let currentDate = try #require(Self.gregorianCalendar(timeZone: timeZone).date(byAdding: .day, value: -1, to: ordinaryDate))
        let entry = Self.makeWakeEntry(date: ordinaryDate, timeZone: timeZone)

        let row = MorningHomePresentation.nextTenMorningsRowDisplay(
            for: entry,
            index: 0,
            currentDate: currentDate,
            timeZone: timeZone
        )

        #expect(row.dateLabel == "Tomorrow")
        #expect(row.tags.map(\.title) == ["Fajr"])
        #expect(row.trailingTime == entry.schedule.wakeDate)
        #expect(row.trailingStatusText == nil)
        #expect(row.accessibilityLabel.contains("Fajr morning"))
        #expect(row.accessibilityLabel.contains("Wake at"))
        #expect(row.accessibilityLabel.contains("Double tap for details"))
        #expect(row.accessibilityLabel.contains("30 min before Fajr ends") == false)
    }

    @Test
    func nextTenMorningsLaterRowsDoNotUseRamadanDateLabel() throws {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let currentDate = Self.makeDate(year: 2026, month: 4, day: 30, timeZone: timeZone)
        let laterDate = try #require(Calendar(identifier: .gregorian).date(byAdding: .day, value: 2, to: currentDate))
        let context = Self.context(primary: .fasting, tags: [.ramadan])
        let entry = Self.makeWakeEntry(
            date: laterDate,
            timeZone: timeZone,
            context: context,
            tagResult: Self.tagResult(primary: .ramadanObligatory)
        )

        let row = MorningHomePresentation.nextTenMorningsRowDisplay(
            for: entry,
            index: 1,
            currentDate: currentDate,
            timeZone: timeZone
        )

        #expect(row.dateLabel == "Sat, May 2")
        #expect(row.dateLabel.contains("Ramadan") == false)
        #expect(row.tags.map(\.title) == ["Ramadan"])
    }

    @Test
    func nextTenMorningsTagDoctrineMatchesForecastSpec() {
        #expect(Self.nextTenTagTitles() == ["Fajr"])
        #expect(Self.nextTenTagTitles(primary: .ramadanObligatory, opportunities: [.ashura]) == ["Ramadan"])
        #expect(Self.nextTenTagTitles(quietModeState: .active, primary: .voluntary, secondary: [.ashura]) == ["Quiet mode"])
        #expect(Self.nextTenTagTitles(primary: .voluntary, secondary: [.ashura]) == ["Fasting", "Ashura"])
        #expect(Self.nextTenTagTitles(opportunities: [.ashura]) == ["Fajr", "Ashura"])
        #expect(Self.nextTenTagTitles(primary: .qadaMakeup, secondary: [.whiteDays]) == ["Fasting", "Qada"])
        #expect(Self.nextTenTagTitles(opportunities: [.ashura], tahajjudIntended: true) == ["Tahajjud", "Ashura"])
        #expect(Self.nextTenTagTitles(opportunities: [.mondayThursday]) == ["Fajr"])
        #expect(Self.nextTenTagTitles(primary: .voluntary, secondary: [.mondayThursday]) == ["Fasting", "Mon/Thu"])
        #expect(Self.nextTenTagTitles(opportunities: [.whiteDays]) == ["Fajr", "White Days"])
        #expect(Self.nextTenTagTitles(primary: .voluntary, secondary: [.whiteDays]) == ["Fasting", "White Days"])
        #expect(Self.nextTenTagTitles(opportunities: [.shawwalSix]) == ["Fajr", "Shawwal 6"])
        #expect(Self.nextTenTagTitles(opportunities: [.shawwalSix], shawwalComplete: true) == ["Fajr"])
    }

    @Test
    func nextTenMorningsTagCapPreservesAccessibilityTags() {
        let resolution = Self.nextTenTagResolution(
            primary: .voluntary,
            secondary: [.arafah, .dhulHijjahFirstNine, .whiteDays],
            opportunities: []
        )

        #expect(resolution.visibleTags.map(\.title) == ["Fasting", "Arafah", "Dhul Hijjah"])
        #expect(resolution.visibleTags.count == 3)
        #expect(resolution.accessibilityTags.map(\.title) == ["Fasting", "Arafah", "Dhul Hijjah", "White Days"])

        let opportunityResolution = Self.nextTenTagResolution(
            opportunities: [.arafah, .dhulHijjahFirstNine, .whiteDays, .shawwalSix]
        )
        #expect(opportunityResolution.visibleTags.map(\.title) == ["Fajr", "Arafah", "Dhul Hijjah"])
        #expect(opportunityResolution.visibleTags.count == 3)
        #expect(opportunityResolution.accessibilityTags.map(\.title) == ["Fajr", "Arafah", "Dhul Hijjah", "White Days", "Shawwal 6"])
    }

    @Test
    func nextTenMorningsRowMetricsShareStableGridLanes() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        let shortRow = Self.nextTenRowDisplay(
            date: date,
            dateLabel: "Tomorrow",
            trailingTime: date,
            trailingStatusText: nil
        )
        let longRow = Self.nextTenRowDisplay(
            date: date,
            dateLabel: "Wednesday, May 6",
            trailingTime: Self.makeDate(year: 2026, month: 5, day: 1, hour: 10, minute: 10, timeZone: timeZone),
            trailingStatusText: nil
        )
        let statusRow = Self.nextTenRowDisplay(
            date: date,
            dateLabel: "Fri, May 8",
            trailingTime: nil,
            trailingStatusText: "No wake"
        )

        let metrics = MorningHomePresentation.nextTenMorningsRowMetrics(
            for: [shortRow, longRow, statusRow],
            timeZone: timeZone
        )
        let narrowLanes = metrics.resolvedLanes(for: 320)
        let wideLanes = metrics.resolvedLanes(for: 420)

        #expect(metrics.dateLaneWidth > NextTenMorningsRowMetrics.minimumDateLaneWidth)
        #expect(metrics.trailingLaneWidth >= NextTenMorningsRowMetrics.minimumTrailingLaneWidth)
        #expect(narrowLanes.dateLaneWidth == wideLanes.dateLaneWidth)
        #expect(narrowLanes.trailingLaneWidth == wideLanes.trailingLaneWidth)
        #expect(narrowLanes.tagLaneWidth >= metrics.minimumTagLaneWidth)
        #expect(wideLanes.tagLaneCenterX > narrowLanes.tagLaneCenterX)
    }

    @Test
    func settingsPrayerSummarySplitsMethodAndOffsets() {
        let summary = SettingsSummaryFormatter.prayerTimesSummary(settings: .default)

        #expect(summary.contains("Calculation method:"))
        #expect(summary.contains("\nPrayer offsets:"))
        #expect(summary.contains("Fajr begin +0 min"))
        #expect(summary.contains("Fajr end +0 min"))
        #expect(summary.contains("Maghrib +0 min"))
    }

    @Test
    func trustCopyUsesHumanFajrBoundaryLanguage() {
        #expect(WakePagePresentation.ordinaryMeaningText == "Regular Fajr morning")
        #expect(FajrWindowBoundaryTruth.solarSunrise.boundaryLabel == "Fajr ends")
        #expect(FajrWindowBoundaryTruth.solarSunrise.explanationText == "Fajr end is based on sunrise for this date.")
        #expect(Strings.SettingsIssues.fallbackTitle == "Wake delivery is limited")
        #expect(Strings.SettingsIssues.fallbackMessage == "This device is using notifications instead of AlarmKit.")
    }

    @Test
    func compactFajrcastHonorsTomorrowSelection() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let activeDays = (0..<3).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: today) ?? today,
                timeZone: timeZone
            ).activeDay
        }
        let tomorrowKey = activeDays[1].dateKey
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: tomorrowKey,
            now: today,
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.dateKey == tomorrowKey)
        #expect(snapshot.selectedDay.relativeLabel == "TOMORROW")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(Self.normalizedTimeSpaces(snapshot.selectedDay.accessibilityValue).contains("Fajr begins at 5:00 AM. Fajr ends at 6:16 AM."))
    }

    @Test
    func compactFajrcastUsesTodayCalloutForTodaySelection() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let activeDays = (0..<3).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: today) ?? today,
                timeZone: timeZone
            ).activeDay
        }
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDays[0].dateKey,
            now: today,
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.relativeLabel == "TODAY")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
    }

    @Test
    func compactFajrcastUsesSkippedSelectedDaySummary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: today,
            timeZone: timeZone,
            skipDay: true
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: today,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(snapshot.selectedDay.iconName == "bell.slash.fill")
        #expect(snapshot.selectedDay.timeMain == "Off")
        #expect(snapshot.selectedDay.timeSuffix == nil)
        #expect(snapshot.selectedDay.accessibilityValue.contains("Alarm is off for this date."))
    }

    @Test
    func compactFajrcastUsesInProgressFajrAccessibilityTense() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        let now = Self.makeDate(year: 2026, month: 4, day: 26, hour: 5, minute: 30, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(date: today, timeZone: timeZone).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: now,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(Self.normalizedTimeSpaces(snapshot.selectedDay.accessibilityValue).contains("Fajr began at 5:00 AM. Fajr ends at 6:16 AM."))
    }

    @Test
    func compactFajrcastUsesPastFajrAccessibilityTense() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let yesterday = Self.makeDate(year: 2026, month: 4, day: 25, timeZone: timeZone)
        let today = Self.makeDate(year: 2026, month: 4, day: 26, hour: 9, minute: 0, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(date: yesterday, timeZone: timeZone).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: today,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(snapshot.selectedDay.relativeLabel == "YESTERDAY")
        #expect(Self.normalizedTimeSpaces(snapshot.selectedDay.accessibilityValue).contains("Fajr began at 5:00 AM. Fajr ended at 6:16 AM."))
    }

    @Test
    func compactFajrcastUsesPastSkippedAccessibilityTense() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let yesterday = Self.makeDate(year: 2026, month: 4, day: 25, timeZone: timeZone)
        let today = Self.makeDate(year: 2026, month: 4, day: 26, hour: 9, minute: 0, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: yesterday,
            timeZone: timeZone,
            skipDay: true
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: today,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(snapshot.selectedDay.timeMain == "Off")
        #expect(snapshot.selectedDay.accessibilityValue.contains("Alarm was off for this date."))
    }

    @Test
    func compactFajrcastPreservesAdjustedCompactInsightWithoutFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let monday = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let activeDays = (0..<7).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: monday) ?? monday,
                timeZone: timeZone
            ).activeDay
        }
        let adjustedKey = activeDays[2].dateKey
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [adjustedKey],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDays[0].dateKey,
            now: monday,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(snapshot.compactInsight == "1 morning is adjusted this week.")
    }

    @Test
    func compactFajrcastOmitsFocusedAdjustedFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let monday = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let activeDays = (0..<7).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: monday) ?? monday,
                timeZone: timeZone
            ).activeDay
        }
        let adjustedKey = activeDays[2].dateKey
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [adjustedKey],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: adjustedKey,
            now: monday,
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.dateKey == adjustedKey)
        #expect(snapshot.selectedDay.relativeLabel == "WEDNESDAY")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
    }

    @Test
    func compactFajrcastSuppressesRoutineFastingFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let tomorrow = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: tomorrow,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [],
                explanation: .empty
            )
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.relativeLabel == "TOMORROW")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
    }

    @Test
    func compactFajrcastSuppressesPastRoutineFastingFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let yesterday = Self.makeDate(year: 2026, month: 4, day: 25, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: yesterday,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [],
                explanation: .empty
            )
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: Self.makeDate(year: 2026, month: 4, day: 26, hour: 9, minute: 0, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.relativeLabel == "YESTERDAY")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
        #expect(Self.normalizedTimeSpaces(snapshot.selectedDay.accessibilityValue).contains("Fajr began at 5:00 AM. Fajr ended at 6:16 AM."))
    }

    @Test
    func compactFajrcastOmitsRamadanFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let tomorrow = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: tomorrow,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [.ramadan],
                explanation: .empty
            )
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(snapshot.selectedDay.relativeLabel == "TOMORROW")
        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == nil)
    }

    @Test
    func compactFajrcastUsesWeeklyFajrTrendFooterPrimary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let monday = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let activeDays = (0..<7).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: monday) ?? monday,
                timeZone: timeZone,
                fajrStartMinuteOffset: -offset
            ).activeDay
        }
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDays[3].dateKey,
            now: monday,
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins 6 minutes earlier by week’s end.")
        #expect(snapshot.summary.secondaryText == nil)
    }

    @Test
    func compactFajrcastUsesSpecialNonRamadanFastingFooterSecondary() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let thursday = Self.makeDate(year: 2026, month: 4, day: 30, timeZone: timeZone)
        let activeDay = Self.makeWakeEntry(
            date: thursday,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [.arafah],
                explanation: .empty
            )
        ).activeDay
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [activeDay],
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDay.dateKey,
            now: Self.makeDate(year: 2026, month: 4, day: 29, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(snapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(snapshot.summary.secondaryText == "Fasting planned: Arafah on Thursday.")
    }

    @Test
    func compactFajrcastGeometryCentersBottomCalloutInPocket() {
        let plotBottom: CGFloat = 160
        let chartBottom: CGFloat = 210
        let calloutHeight: CGFloat = 40
        let calloutTop = CompactFajrcastGeometry.centeredCalloutTop(
            plotBottom: plotBottom,
            chartBottom: chartBottom,
            calloutHeight: calloutHeight,
            minimumGap: 5
        )

        let topGap = calloutTop - plotBottom
        let bottomGap = chartBottom - (calloutTop + calloutHeight)

        #expect(abs(topGap - bottomGap) < 0.001)
        #expect(topGap == 5)
    }

    @Test
    func compactFajrcastGeometryUsesBoundaryTangentAndOutwardNormals() {
        let angle = CompactFajrcastGeometry.tangentAngleRadians(
            x0: 0,
            y0: 10,
            x1: 20,
            y1: 14
        )
        let aboveNormal = CompactFajrcastGeometry.outwardNormal(for: angle, placement: .above)
        let belowNormal = CompactFajrcastGeometry.outwardNormal(for: angle, placement: .below)

        #expect(angle > 0)
        #expect(aboveNormal.y < 0)
        #expect(belowNormal.y > 0)
    }

    @Test
    func compactFajrcastUsesCenteredVisibleWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, hour: 22, minute: 34, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let selected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        let windowStart = calendar.date(byAdding: .day, value: -3, to: selected) ?? selected
        let activeDays = (0..<7).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: windowStart) ?? windowStart,
                timeZone: timeZone
            ).activeDay
        }
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [],
            timeZone: timeZone
        )
        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDays[3].dateKey,
            now: today,
            timeZone: timeZone
        )

        let anchorKey = activeDays[3].dateKey
        let visibleDateKeys = activeDays.map { $0.dateKey }
        let snapshotDateKeys = snapshot.points.map { $0.dateKey }

        #expect(snapshot.points.first?.dateKey == activeDays.first?.dateKey)
        #expect(snapshot.selectedDay.dateKey == anchorKey)
        #expect(snapshot.chart.points.firstIndex(where: { $0.dateKey == snapshot.selectedDay.dateKey }) == 3)
        #expect(snapshotDateKeys == visibleDateKeys)
        #expect(snapshot.chart.points.count == 7)
        #expect(snapshot.chart.compactYTicks.count == 4)
        #expect(snapshot.chart.points.map { Self.weekdayInitial(for: $0.date, timeZone: timeZone) } == ["F", "S", "S", "M", "T", "W", "T"])

        let focusedSnapshot = provider.compactSnapshot(
            dataset: dataset,
            selectedDateKey: activeDays[0].dateKey,
            now: today,
            timeZone: timeZone
        )
        let focusedDateKeys = focusedSnapshot.points.map { $0.dateKey }

        #expect(focusedSnapshot.selectedDay.dateKey == activeDays[0].dateKey)
        #expect(focusedSnapshot.chart.points.firstIndex(where: { $0.dateKey == anchorKey }) == 3)
        #expect(focusedSnapshot.chart.points.firstIndex(where: { $0.dateKey == focusedSnapshot.selectedDay.dateKey }) == 0)
        #expect(focusedDateKeys == visibleDateKeys)
        #expect(focusedSnapshot.selectedDay.relativeLabel == "FRIDAY")
        #expect(focusedSnapshot.summary.primaryText == "Fajr begins around the same time this week.")
        #expect(focusedSnapshot.summary.secondaryText == nil)

        let snapBackSnapshot = provider.compactSnapshot(
            dataset: dataset,
            anchorDateKey: anchorKey,
            selectedDateKey: nil,
            now: today,
            timeZone: timeZone
        )
        let snapBackDateKeys = snapBackSnapshot.points.map { $0.dateKey }

        #expect(snapBackSnapshot.selectedDay.dateKey == anchorKey)
        #expect(snapBackSnapshot.chart.points.firstIndex(where: { $0.dateKey == snapBackSnapshot.selectedDay.dateKey }) == 3)
        #expect(snapBackDateKeys == visibleDateKeys)
        #expect(snapBackSnapshot.summary.primaryText == focusedSnapshot.summary.primaryText)
        #expect(snapBackSnapshot.summary.secondaryText == focusedSnapshot.summary.secondaryText)
    }

    @MainActor
    private final class RecordingRoutineScheduler: RoutineScheduling {
        var cancelledIdentifierSets: [SchedulingIdentifierSet] = []
        var scheduledEventIdentifiers: [String] = []
        var cancelledEventIdentifiers: [String] = []
        var cancelAllUpcomingDays: [Int] = []

        func scheduleEvent(
            identifier: String,
            event: ScheduledEvent,
            deliveryKind: ScheduleEventKind,
            schedule: DaySchedule,
            settings: AppSettings,
            canUseAlarmKit: Bool,
            now: Date
        ) async -> Bool {
            scheduledEventIdentifiers.append(identifier)
            return true
        }

        func cancelEvent(
            identifier: String,
            event: ScheduledEvent,
            deliveryKind: ScheduleEventKind,
            schedule: DaySchedule
        ) async {
            cancelledEventIdentifiers.append(identifier)
        }

        func cancelIdentifiers(_ identifiers: SchedulingIdentifierSet) async {
            cancelledIdentifierSets.append(identifiers)
        }

        func cancelAllUpcoming(days: Int) async {
            cancelAllUpcomingDays.append(days)
        }
    }

    private static func makeSchedulerActiveDay(date: Date, timeZone: TimeZone) -> ActiveAlarmDay {
        let activeDay = makeWakeEntry(date: date, timeZone: timeZone).activeDay
        let event = ScheduledEvent(
            id: "\(activeDay.dateKey).wakeAlarm",
            type: .wakeAlarm,
            dateKey: activeDay.dateKey,
            fireDate: activeDay.schedule.wakeDate,
            relativeTo: .wakeAnchor(type: .fajrEnd, offsetMinutes: -30),
            isUserVisible: true,
            affectsCompletion: true,
            deliveryKinds: [.wake],
            soundRole: .inFajrWake,
            wakeSessionID: "\(activeDay.dateKey).wake-session",
            wakeSessionRole: .primaryWake
        )

        return ActiveAlarmDay(
            date: activeDay.date,
            dateKey: activeDay.dateKey,
            schedule: activeDay.schedule,
            effectiveConfig: activeDay.effectiveConfig,
            provenances: activeDay.provenances,
            isImplicitRamadan: activeDay.isImplicitRamadan,
            isExplicitOneOff: activeDay.isExplicitOneOff,
            tagResult: activeDay.tagResult,
            primaryDisplay: activeDay.primaryDisplay,
            sourceSummaryText: activeDay.sourceSummaryText,
            resolvedDayContext: activeDay.resolvedDayContext,
            scheduledEvents: [event],
            decisionLog: activeDay.decisionLog,
            dailyCompletion: activeDay.dailyCompletion
        )
    }

    private static func expectedDelivery(
        identifier: String,
        alarmIDSeed: String,
        fireDate: Date,
        channel: AlarmDeliveryChannel
    ) -> ExpectedAlarmDelivery {
        expectedDelivery(
            identifier: identifier,
            alarmID: DateHelpers.stableUUID(from: alarmIDSeed),
            fireDate: fireDate,
            channel: channel
        )
    }

    private static func expectedDelivery(
        identifier: String,
        alarmID: UUID,
        fireDate: Date,
        channel: AlarmDeliveryChannel
    ) -> ExpectedAlarmDelivery {
        ExpectedAlarmDelivery(
            dateKey: "2026-05-01",
            eventID: "2026-05-01.wakeAlarm",
            eventType: .wakeAlarm,
            deliveryKind: .wake,
            fireDate: fireDate,
            channel: channel,
            notificationIdentifier: identifier,
            alarmIdentifier: alarmID
        )
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

    private static func normalizedTimeSpaces(_ value: String) -> String {
        value.replacingOccurrences(of: "\u{202F}", with: " ")
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
            reminderDate: wake.addingTimeInterval(-15 * 60),
            boundaryDate: fajr,
            iftarDate: maghrib,
            locationDescription: "Test",
            offsetMinutes: 45,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
    }

    private static func weekdayInitial(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        switch calendar.component(.weekday, from: date) {
        case 2:
            return "M"
        case 3:
            return "T"
        case 4:
            return "W"
        case 5:
            return "T"
        case 6:
            return "F"
        case 7:
            return "S"
        default:
            return "S"
        }
    }

    private static func makeWakeEntry(
        date: Date,
        timeZone: TimeZone,
        context: ResolvedDayContext = .standard,
        tagResult: TagComputationResult = .empty,
        skipDay: Bool = false,
        hasDayOverride: Bool = false,
        plannedWakeState: MorningWakeRuleState = .inFajr,
        providerNotes: String? = nil,
        includeFajrEnd: Bool = true,
        wakeOffsetMinutesFromFajrStart: Int? = nil,
        fajrStartMinuteOffset: Int = 0
    ) -> WakeRowEntry {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)
        let baseFajrStart = calendar.date(byAdding: .hour, value: 5, to: start) ?? start
        let fajrStart = calendar.date(byAdding: .minute, value: fajrStartMinuteOffset, to: baseFajrStart) ?? baseFajrStart
        let fajrEnd = calendar.date(byAdding: .minute, value: 76, to: fajrStart) ?? fajrStart
        let wake: Date
        if let wakeOffsetMinutesFromFajrStart {
            wake = calendar.date(byAdding: .minute, value: wakeOffsetMinutesFromFajrStart, to: fajrStart) ?? fajrStart
        } else if plannedWakeState == .fixedWake {
            wake = calendar.date(byAdding: .minute, value: 45, to: fajrStart) ?? fajrStart
        } else {
            wake = calendar.date(byAdding: .minute, value: -30, to: fajrEnd) ?? fajrStart
        }
        let schedule = DaySchedule(
            date: start,
            fajrDate: fajrStart,
            maghribDate: calendar.date(byAdding: .hour, value: 14, to: fajrStart) ?? fajrStart,
            wakeDate: wake,
            reminderDate: nil,
            boundaryDate: includeFajrEnd ? fajrEnd : nil,
            iftarDate: nil,
            locationDescription: "Toronto",
            offsetMinutes: 30,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
        let dateKey = DateHelpers.dayIdentifier(for: start, timeZone: timeZone)
        let wakeRule = MorningWakeRule(
            state: plannedWakeState,
            anchorType: plannedWakeState == .fixedWake ? .clockTime : .fajrEnd,
            deltaMinutes: 30,
            fixedWakeTimeMinutesFromMidnight: plannedWakeState == .fixedWake
                ? DateHelpers.minutesFromMidnight(for: wake, timeZone: timeZone)
                : nil
        )
        let config = EffectiveDailyConfig(
            date: start,
            defaultsActive: true,
            skipDay: skipDay,
            suhoorEnabled: !skipDay,
            reminderEnabled: false,
            fajrEnabled: true,
            iftarEnabled: false,
            defaultWakeRule: wakeRule,
            resolvedWakeRule: wakeRule,
            wakeRuleWasOverridden: hasDayOverride,
            tahajjudRefinement: context.primaryContext == .tahajjud,
            suhoorTimeMode: plannedWakeState == .fixedWake ? .fixedTime : .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .adhanSoft,
            iftarDelivery: .off,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: hasDayOverride || skipDay
        )
        let decisionLog = makeDecisionLog(
            dateKey: dateKey,
            schedule: schedule,
            context: context,
            plannedWakeState: plannedWakeState,
            providerNotes: providerNotes
        )
        let activeDay = ActiveAlarmDay(
            date: start,
            dateKey: dateKey,
            schedule: schedule,
            effectiveConfig: config,
            provenances: [defaultDailyPlanProvenance()],
            isImplicitRamadan: context.supportingTags.contains(.ramadan),
            isExplicitOneOff: hasDayOverride,
            tagResult: tagResult,
            primaryDisplay: config.primaryDisplay(schedule: schedule),
            sourceSummaryText: "Default Subh morning plan.",
            resolvedDayContext: context,
            decisionLog: decisionLog
        )

        return WakeRowEntry(
            activeDay: activeDay,
            secondaryTags: [],
            deleteCapability: .series,
            stoppableProvenances: [],
            excludableProvenances: [],
            hasExplicitOneOff: hasDayOverride,
            hasDayOverride: hasDayOverride,
            rowPresentation: ProductSurfacePresentation.scheduleRowPresentation(
                for: activeDay,
                hasDayOverride: hasDayOverride
            )
        )
    }

    private static func nextTenTagTitles(
        quietModeState: NextTenMorningsQuietModeState = .inactive,
        primary: FastPrimaryIntent = .other,
        secondary: Set<FastSecondaryVirtueTag> = [],
        opportunities: [FastSecondaryVirtueTag] = [],
        tahajjudIntended: Bool = false,
        shawwalComplete: Bool = false
    ) -> [String] {
        nextTenTagResolution(
            quietModeState: quietModeState,
            primary: primary,
            secondary: secondary,
            opportunities: opportunities,
            tahajjudIntended: tahajjudIntended,
            shawwalComplete: shawwalComplete
        ).visibleTags.map(\.title)
    }

    private static func nextTenTagResolution(
        quietModeState: NextTenMorningsQuietModeState = .inactive,
        primary: FastPrimaryIntent = .other,
        secondary: Set<FastSecondaryVirtueTag> = [],
        opportunities: [FastSecondaryVirtueTag] = [],
        tahajjudIntended: Bool = false,
        shawwalComplete: Bool = false
    ) -> NextTenMorningsTagResolution {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        return NextTenMorningsTagResolver.resolve(
            NextTenMorningsTagResolverInput(
                date: date,
                dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                resolvedContext: context(for: primary, secondary: secondary),
                tagResult: tagResult(primary: primary, secondary: secondary),
                compatibleOpportunityTags: opportunities,
                quietModeState: quietModeState,
                shawwalSixProgress: shawwalComplete
                    ? ShawwalSixProgressSummary(
                        completedIntendedShawwalSixCount: 6,
                        remainingCount: 0,
                        completedDateKeys: [],
                        isComplete: true
                    )
                    : .incomplete,
                hasDayOverride: false,
                tahajjudIntended: tahajjudIntended
            )
        )
    }

    private static func nextTenRowDisplay(
        date: Date,
        dateLabel: String,
        trailingTime: Date?,
        trailingStatusText: String?
    ) -> NextTenMorningsRowDisplay {
        NextTenMorningsRowDisplay(
            id: dateLabel,
            dateKey: dateLabel,
            date: date,
            dateLabel: dateLabel,
            tags: [],
            allAccessibilityTags: [],
            trailingTime: trailingTime,
            trailingStatusText: trailingStatusText,
            isInactive: trailingTime == nil,
            accessibilityLabel: dateLabel
        )
    }

    private static func nextDateWithoutForecastOpportunity(
        startingAt date: Date,
        timeZone: TimeZone
    ) -> Date {
        let calendar = gregorianCalendar(timeZone: timeZone)
        for offset in 1..<160 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
            let tags = FastIntentEngine.dateDerivedObservanceTags(
                for: candidate,
                timeZone: timeZone,
                includeShawwalPotential: true
            )
            if tags.isEmpty,
               FastIntentEngine.isRamadan(candidate, timeZone: timeZone) == false,
               FastIntentEngine.isForbiddenToFast(candidate, timeZone: timeZone) == false {
                return candidate
            }
        }
        Issue.record("Unable to find an ordinary forecast date")
        return date
    }

    private static func gregorianCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func tagResult(
        primary: FastPrimaryIntent,
        secondary: Set<FastSecondaryVirtueTag> = []
    ) -> TagComputationResult {
        TagComputationResult(
            computedPrimaryIntent: primary,
            computedSecondaryTags: secondary,
            secondaryDetails: [:],
            suppressedSecondaryTags: []
        )
    }

    private static func context(
        primary: MorningContextType,
        tags: [DayTag]
    ) -> ResolvedDayContext {
        ResolvedDayContext(
            primaryContext: primary,
            secondaryContexts: [],
            supportingTags: tags,
            explanation: .empty
        )
    }

    private static func context(
        for primary: FastPrimaryIntent,
        secondary: Set<FastSecondaryVirtueTag>
    ) -> ResolvedDayContext {
        let primaryContext: MorningContextType
        var tags: [DayTag] = []

        switch primary {
        case .ramadanObligatory:
            primaryContext = .fasting
            tags.append(.ramadan)
        case .qadaMakeup:
            primaryContext = .qadaFast
            tags.append(.qada)
        case .kaffarahExpiation:
            primaryContext = .fasting
            tags.append(.kaffarah)
        case .vowNadhr:
            primaryContext = .fasting
            tags.append(.vow)
        case .voluntary:
            primaryContext = .sunnahFast
            tags.append(.voluntary)
        case .forbidden, .other:
            primaryContext = .standard
        }

        for tag in secondary {
            switch tag {
            case .shawwalSix:
                tags.append(.shawwalSix)
            case .arafah:
                tags.append(.arafah)
            case .ashura:
                tags.append(.ashura)
            case .whiteDays:
                tags.append(.whiteDays)
            case .mondayThursday:
                tags.append(.mondayThursday)
            case .dhulHijjahFirstNine:
                tags.append(.dhulHijjahFirstNine)
            }
        }

        return context(primary: primaryContext, tags: tags)
    }

    private static func makeDecisionLog(
        dateKey: String,
        schedule: DaySchedule,
        context: ResolvedDayContext,
        plannedWakeState: MorningWakeRuleState,
        providerNotes: String?
    ) -> RuleDecisionLog {
        let anchorType: WakeAnchorType = plannedWakeState == .fixedWake ? .clockTime : .fajrEnd
        let anchorDate = plannedWakeState == .fixedWake
            ? schedule.wakeDate
            : (schedule.fajrEndDate ?? schedule.boundaryDate ?? schedule.fajrDate)
        let delta = WakeDelta(relation: .before, minutes: plannedWakeState == .fixedWake ? 0 : 30)

        return RuleDecisionLog(
            dateKey: dateKey,
            resolverVersion: 1,
            decisionHash: "\(dateKey).test",
            prayerWindow: DailyPrayerWindow(
                date: schedule.date,
                fajrStart: schedule.fajrDate,
                fajrEnd: schedule.fajrEndDate ?? schedule.boundaryDate,
                maghrib: schedule.maghribDate
            ),
            candidateContexts: [context.primaryContext],
            resolvedDayContext: context,
            candidatePlans: [
                RulePlanCandidate(id: "test", title: "Test", kind: .defaultDaily)
            ],
            selectedPlanID: "test",
            precedenceReason: "Test fixture.",
            resolvedBehaviorProfile: MorningBehaviorProfile(
                wakeAnchorType: anchorType,
                wakeDelta: delta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: plannedWakeState == .fixedWake
                    ? DateHelpers.minutesFromMidnight(for: schedule.wakeDate, timeZone: .current)
                    : nil,
                reminderEnabled: false,
                wakeAlarmEnabled: true,
                wakeFollowUpEnabled: false,
                fajrBoundaryNoticeEnabled: true,
                iftarReminderEnabled: false,
                resolvedWakeState: .inFajr,
                plannedWakeState: plannedWakeState
            ),
            resolvedAnchor: WakeAnchor(type: anchorType, date: anchorDate, providerNotes: providerNotes),
            resolvedDelta: delta,
            candidateWakeTime: schedule.wakeDate,
            resolvedWakeTime: schedule.wakeDate,
            resolvedWakeState: .inFajr,
            plannedWakeState: plannedWakeState,
            resolvedSequenceTemplate: WakeSequenceTemplate(
                id: "\(dateKey).test-sequence",
                name: "Test sequence",
                steps: []
            ),
            materializedEvents: [],
            compatibilityNotes: []
        )
    }

    private static func defaultDailyPlanProvenance() -> ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: DateHelpers.stableUUID(from: "suhoor.defaultDailyPlan"),
            groupID: nil,
            label: ScheduledDateSourceOrigin.defaultDailyPlan.label,
            stopSeriesLabel: ScheduledDateSourceOrigin.defaultDailyPlan.stopSeriesLabel,
            isExplicitOneOff: ScheduledDateSourceOrigin.defaultDailyPlan.isExplicitOneOff,
            sourceOrigin: .defaultDailyPlan
        )
    }
}
