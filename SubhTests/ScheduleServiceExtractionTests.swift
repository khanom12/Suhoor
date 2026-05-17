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
    func refreshReasonsCoverDeliveryReliabilityTriggers() {
        #expect(ScheduleRefreshReason.notificationPermissionChanged.diagnosticLabel == "notificationPermissionChanged")
        #expect(ScheduleRefreshReason.alarmKitPermissionChanged.diagnosticLabel == "alarmKitPermissionChanged")
        #expect(ScheduleRefreshReason.timeZoneChanged.debounceDurationNanoseconds == 0)
        #expect(ScheduleRefreshReason.identifierMigration.debounceDurationNanoseconds == 0)
        #expect(ScheduleRefreshReason.dateSpecificWakeChanged.isLifecycleRefresh == false)
        #expect(ScheduleRefreshReason.fastPurposeChanged.isLifecycleRefresh == false)
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

        let planningWindow = snapshotResult.planningWindowSnapshot
        #expect(planningWindow.visibleDateKeys == snapshotResult.visibleDays.map(\.dateKey))
        #expect(planningWindow.activeScheduledDateKeys == snapshotResult.scheduledDays.map(\.dateKey))
        #expect(planningWindow.visibleOnlyDateKeys == [
            DateHelpers.dayIdentifier(for: date.addingTimeInterval(24 * 60 * 60), timeZone: timeZone)
        ])
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
        #expect(identifiers.alarmIdentifiers.contains(DateHelpers.stableUUID(from: "\(schedule.id).wakeAlarm.wake.alarmKit")))
    }

    @Test
    @MainActor
    func scheduleDayCancelsStaleIdentifiersWhenNoPriorPlanIsKnown() async {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let activeDay = Self.makeSchedulerActiveDay(
            date: DateHelpers.startOfDay(Date().addingTimeInterval(2 * 24 * 60 * 60), in: timeZone),
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
        #expect(cancelled.alarmIdentifiers.contains(SchedulingIdentifiers.alarmID(for: activeDay.scheduledEvents[0], deliveryKind: .wake, channel: .alarmKit)))
        #expect(routineScheduler.scheduledEventIdentifiers == [
            SchedulingIdentifiers.identifier(for: activeDay.scheduledEvents[0], deliveryKind: .wake)
        ])
    }

    @Test
    func deliveryPlanUsesNotificationsFallbackForActiveFastWhenAlarmKitUnavailable() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 5, day: 1, hour: 0, timeZone: timeZone)
        let activeDay = Self.makeSchedulerActiveDay(
            date: now.addingTimeInterval(2 * 24 * 60 * 60),
            timeZone: timeZone
        )
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [activeDay],
            scheduledDays: [activeDay],
            visibleHorizonDays: 7,
            scheduledHorizonDays: 7
        )

        let plan = DeliveryReconciliation.plan(
            snapshot: snapshot,
            settings: .default,
            mode: .notifications,
            now: now
        )

        #expect(plan.mode == .notifications)
        #expect(plan.expectedDeliveries.count == 1)
        #expect(plan.expectedDeliveries.first?.channel == .notification)
        #expect(plan.skippedDeliveries.isEmpty)
    }

    @Test
    func deliveryPlanDoesNotScheduleVisibleOnlyRows() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 5, day: 1, hour: 0, timeZone: timeZone)
        let visibleOnlyDay = Self.makeSchedulerActiveDay(
            date: now.addingTimeInterval(2 * 24 * 60 * 60),
            timeZone: timeZone
        )
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [visibleOnlyDay],
            scheduledDays: [],
            visibleHorizonDays: 7,
            scheduledHorizonDays: 0
        )

        let plan = DeliveryReconciliation.plan(
            snapshot: snapshot,
            settings: .default,
            mode: .notifications,
            now: now
        )

        #expect(snapshot.planningWindowSnapshot.visibleOnlyDateKeys == [visibleOnlyDay.dateKey])
        #expect(plan.expectedDeliveries.isEmpty)
        #expect(plan.skippedDeliveries.isEmpty)
    }

    @Test
    func deliveryPlanSupportsMixedAlarmKitWakeAndNotificationCues() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 5, day: 1, hour: 0, timeZone: timeZone)
        let activeDay = Self.makeSchedulerActiveDayWithSecondaryEvents(
            date: now.addingTimeInterval(2 * 24 * 60 * 60),
            timeZone: timeZone
        )
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [activeDay],
            scheduledDays: [activeDay],
            visibleHorizonDays: 7,
            scheduledHorizonDays: 7
        )

        let plan = DeliveryReconciliation.plan(
            snapshot: snapshot,
            settings: .default,
            mode: .mixed,
            now: now
        )

        #expect(plan.isMixed)
        #expect(plan.expectedDeliveries.first { $0.deliveryKind == .wake }?.channel == .alarmKit)
        #expect(plan.expectedDeliveries.first { $0.deliveryKind == .reminder }?.channel == .notification)
        #expect(plan.expectedDeliveries.first { $0.deliveryKind == .boundary }?.channel == .notification)
    }

    @Test
    @MainActor
    func alarmSchedulerMixedModeRoutesWakeToAlarmKitAndCueToNotifications() async {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let activeDay = Self.makeSchedulerActiveDayWithSecondaryEvents(
            date: DateHelpers.startOfDay(Date().addingTimeInterval(2 * 24 * 60 * 60), in: timeZone),
            timeZone: timeZone
        )
        let routineScheduler = RecordingRoutineScheduler()
        let scheduler = AlarmScheduler(routineScheduler: routineScheduler)

        let scheduled = await scheduler.scheduleDay(
            day: activeDay,
            settings: .default,
            mode: .mixed
        )

        #expect(scheduled)
        #expect(routineScheduler.scheduledEventIdentifiers.count == 3)
        #expect(routineScheduler.scheduledCanUseAlarmKit == [false, false, true])
        #expect(routineScheduler.scheduledFireDates.sorted() == activeDay.scheduledEvents.map(\.fireDate).sorted())
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
    func deliveryReconciliationReportsUnexpectedDuplicateAndVerificationUnavailable() {
        let now = Date()
        let expected = Self.expectedDelivery(
            identifier: "expected.one",
            alarmIDSeed: "alarm.one",
            fireDate: now.addingTimeInterval(600),
            channel: .notification
        )
        let unexpectedAlarmID = DateHelpers.stableUUID(from: "unexpected.alarm")

        let report = DeliveryReconciliation.report(
            mode: .mixed,
            generatedAt: now,
            expectedDeliveries: [expected],
            pendingNotifications: [
                PendingNotificationDelivery(identifier: "expected.one", fireDate: expected.fireDate),
                PendingNotificationDelivery(identifier: "stale.extra", fireDate: now.addingTimeInterval(900)),
                PendingNotificationDelivery(identifier: "stale.extra", fireDate: now.addingTimeInterval(900))
            ],
            pendingAlarms: [
                ScheduledAlarmDelivery(id: unexpectedAlarmID, fireDate: now.addingTimeInterval(900))
            ],
            alarmKitVerificationAvailable: false
        )

        #expect(report.unexpectedNotificationIdentifiers == ["stale.extra"])
        #expect(report.duplicateNotificationIdentifiers == ["stale.extra"])
        #expect(report.unexpectedAlarmIdentifiers == [unexpectedAlarmID])
        #expect(report.issues.contains { $0.category == .unexpectedExtra })
        #expect(report.issues.contains { $0.category == .duplicate })
    }

    @Test
    func deliveryReconciliationMarksAlarmKitVerificationUnavailableInsteadOfMissing() {
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
            pendingAlarms: [],
            alarmKitVerificationAvailable: false
        )

        #expect(report.missingAlarmIdentifiers.isEmpty)
        #expect(report.issues.contains { $0.category == .verificationUnavailable })
        #expect(report.summaryText.contains("Verification limited"))
    }

    @Test
    func deliveryPlanSkipsPastEventsWithoutMissingWarning() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 5, day: 3, hour: 12, timeZone: timeZone)
        let activeDay = Self.makeSchedulerActiveDay(
            date: Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone),
            timeZone: timeZone
        )
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [activeDay],
            scheduledDays: [activeDay],
            visibleHorizonDays: 7,
            scheduledHorizonDays: 7
        )

        let report = DeliveryReconciliation.report(
            snapshot: snapshot,
            settings: .default,
            mode: .notifications,
            now: now,
            pendingNotifications: [],
            pendingAlarms: []
        )

        #expect(report.expectedDeliveries.isEmpty)
        #expect(report.missingNotificationIdentifiers.isEmpty)
        #expect(report.skippedDeliveries.contains { $0.reason == .skippedPast })
        #expect(report.issues.contains { $0.category == .skippedPast })
    }

    @Test
    func alarmDeliveryLedgerRecordsLocalSummaryWithoutDiagnosticIdentifierLeak() {
        let defaults = UserDefaults(suiteName: "alarm-ledger-\(UUID().uuidString)") ?? .standard
        let store = AlarmDeliveryLedgerStore(defaults: defaults)
        store.clear()

        store.record(
            AlarmDeliveryLedgerEntry(
                timestamp: Date(timeIntervalSince1970: 1_777_777_777),
                action: .reconciliation,
                dateKey: nil,
                eventID: nil,
                eventType: nil,
                deliveryKind: nil,
                fireDate: nil,
                channel: SchedulingMode.mixed.rawValue,
                platformIdentifier: "raw-platform-identifier-should-stay-out-of-diagnostics",
                permissionMode: "Mixed",
                wakeRuleSignature: "rule:fajr-end-30",
                refreshReason: ScheduleRefreshReason.foreground.diagnosticLabel,
                result: "Scheduled",
                message: "expected=2 matched=2 missing=0 failed=0"
            )
        )

        let entries = store.entries()
        #expect(entries.count == 1)
        #expect(entries.first?.message == "expected=2 matched=2 missing=0 failed=0")

        let diagnostics = store.diagnosticsText()
        #expect(diagnostics.contains("reconciliation"))
        #expect(diagnostics.contains("Scheduled"))
        #expect(!diagnostics.contains("raw-platform-identifier-should-stay-out-of-diagnostics"))
        #expect(!diagnostics.contains("expected=2 matched=2"))

        store.clear()
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
        #expect(snapshot.morningcast.count == MorningHomeSnapshot.maximumMorningcastCount)
        #expect(snapshot.morningcast.first?.id == tomorrowKey)
        #expect(snapshot.weeklyFajrcast.points.first?.dateKey == tomorrowKey)
        #expect(snapshot.weeklyFajrcast.points.map(\.dateKey) == snapshot.morningcast.map(\.id))
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

        let adjustedToFifteenBeforeEnd = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: (entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake).addingTimeInterval(-15 * 60),
            timeZone: timeZone
        )
        #expect(adjustedToFifteenBeforeEnd.detailText == "Wake up 15 min before Fajr ends")
        #expect(adjustedToFifteenBeforeEnd.relationTone == .normal)

        let adjustedToFourteenBeforeEnd = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: (entry.activeDay.decisionLog.prayerWindow.fajrEnd ?? adjustedWake).addingTimeInterval(-14 * 60),
            timeZone: timeZone
        )
        #expect(adjustedToFourteenBeforeEnd.detailText == "Wake up 14 min before Fajr ends")
        #expect(adjustedToFourteenBeforeEnd.relationTone == .urgentRed)

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

        #expect(display.primaryTime == nil)
        #expect(display.primaryText == "Wake time unavailable")
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
    func tomorrowHeroUsesModeAwareRangeForFastingAndOutOfWindowStates() {
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
        let fastingAfterFajrBegins = MorningHomePresentation.heroDisplay(
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
        let fastingBeforeFajrBegins = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .fasting,
                    secondaryContexts: [],
                    supportingTags: [.ramadan],
                    explanation: .empty
                ),
                wakeOffsetMinutesFromFajrStart: -30
            ),
            permissionSummary: "",
            timeZone: timeZone
        )
        let tahajjudBeforeFajrBegins = MorningHomePresentation.heroDisplay(
            entry: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .tahajjud,
                    secondaryContexts: [],
                    supportingTags: [],
                    explanation: .empty
                ),
                wakeOffsetMinutesFromFajrStart: -45
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
        #expect(fastingAfterFajrBegins.fajrWindowVisualMode == .hiddenOutOfWindow)
        #expect(fastingAfterFajrBegins.wakeAdjustmentEnabled == false)
        #expect(fastingBeforeFajrBegins.fajrWindowVisualMode == .interactiveEarlyWorshipWindow)
        #expect(fastingBeforeFajrBegins.wakeAdjustmentEnabled)
        #expect(fastingBeforeFajrBegins.leftBoundaryMarkerStyle == .verticalLine)
        #expect(fastingBeforeFajrBegins.rightBoundaryMarkerStyle == .endpointCircle)
        #expect(fastingBeforeFajrBegins.detailText == "Wake up 30 min before Fajr begins")
        #expect(Self.normalizedTimeSpaces(fastingBeforeFajrBegins.fajrEndDisplayText ?? "") == "5:00 AM")
        #expect(fastingBeforeFajrBegins.fajrWindowAccessibilityText?.contains("Final third of the night begins") == true)
        #expect(fastingBeforeFajrBegins.wakeAdjustmentAccessibilityValue?.contains("Adjustable between the final third of the night") == true)
        #expect(tahajjudBeforeFajrBegins.fajrWindowVisualMode == .hiddenOutOfWindow)
        #expect(tahajjudBeforeFajrBegins.wakeAdjustmentEnabled == false)
        #expect(tahajjudBeforeFajrBegins.detailText == "Wake up 121 min before Fajr ends")
        #expect(outOfWindow.fajrWindowVisualMode == .hiddenOutOfWindow)
        #expect(outOfWindow.wakeAdjustmentEnabled == false)
        #expect(outOfWindow.fajrBeginDisplayText != nil)
        #expect(outOfWindow.fajrEndDisplayText != nil)
    }

    @Test
    func tomorrowHeroEarlyWorshipAdjusterUsesEndpointCopyAndLiveRelation() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)
        let entry = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [.ramadan],
                explanation: .empty
            ),
            wakeOffsetMinutesFromFajrStart: -30
        )
        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            timeZone: timeZone
        )

        let minTime = display.wakeAdjustmentMinTime ?? entry.schedule.wakeDate
        let maxTime = display.wakeAdjustmentMaxTime ?? entry.activeDay.decisionLog.prayerWindow.fajrStart

        #expect(display.fajrWindowVisualMode == .interactiveEarlyWorshipWindow)
        #expect(display.detailText == "Wake up 30 min before Fajr begins")
        #expect(display.wakeWindowPositionRatio != nil)

        let adjustedToLeft = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: minTime,
            timeZone: timeZone
        )
        #expect(adjustedToLeft.detailText == "Wake up for the last third of the night")
        #expect(adjustedToLeft.relationTone == .normal)
        #expect(adjustedToLeft.wakeWindowPositionRatio == 0)

        let adjustedToRight = MorningHomePresentation.heroDisplay(
            adjusting: display,
            tentativeWakeTime: maxTime,
            timeZone: timeZone
        )
        #expect(adjustedToRight.detailText == "Wake up as Fajr begins")
        #expect(adjustedToRight.relationTone == .normal)
        #expect(adjustedToRight.wakeWindowPositionRatio == 1)
    }

    @Test
    func tomorrowHeroQuickWakeModesDriveHeroAndForecastPresentation() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone)
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)

        let fajrEntry = Self.makeWakeEntry(date: date, timeZone: timeZone)
        let fajrDisplay = MorningHomePresentation.heroDisplay(
            entry: fajrEntry,
            permissionSummary: "",
            currentDate: today,
            timeZone: timeZone
        )

        #expect(fajrDisplay.selectedQuickWakeMode == .fajr)
        #expect(fajrDisplay.quickWakeModeOptions.map(\.title) == ["Suhoor", "Fajr", "Quiet"])
        #expect(fajrDisplay.quickWakeModeOptions.first(where: { $0.mode == .fajr })?.isSelected == true)
        #expect(fajrDisplay.primaryTime == fajrEntry.schedule.wakeDate)
        #expect(fajrDisplay.detailText == "Wake up 30 min before Fajr ends")
        #expect(fajrDisplay.fajrWindowVisualMode == .interactiveWithinFajrWindow)
        #expect(fajrDisplay.accessibilityLabel.contains("Fajr mode selected"))

        let adjustedFajr = MorningHomePresentation.heroDisplay(
            adjusting: fajrDisplay,
            tentativeWakeTime: fajrEntry.activeDay.decisionLog.prayerWindow.fajrStart,
            timeZone: timeZone
        )
        #expect(adjustedFajr.selectedQuickWakeMode == .fajr)
        #expect(adjustedFajr.quickWakeModeOptions.first(where: { $0.mode == .fajr })?.isSelected == true)
        #expect(adjustedFajr.detailText == "Wake up as Fajr begins")

        let fastEntry = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            hasDayOverride: true,
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fast
        )
        let fastDisplay = MorningHomePresentation.heroDisplay(
            entry: fastEntry,
            permissionSummary: "",
            currentDate: today,
            timeZone: timeZone
        )
        let fastForecastRow = MorningHomePresentation.nextTenMorningsRowDisplay(
            for: fastEntry,
            index: 0,
            currentDate: today,
            timeZone: timeZone
        )

        #expect(fastDisplay.selectedQuickWakeMode == .suhoor)
        #expect(fastDisplay.quickWakeModeOptions.first(where: { $0.mode == .suhoor })?.isSelected == true)
        #expect(fastDisplay.detailText == "Wake up 30 min before Fajr begins")
        #expect(fastDisplay.fajrWindowVisualMode == .interactiveEarlyWorshipWindow)
        #expect(fastDisplay.wakeAdjustmentRelationAnchor == .fajrStart)
        #expect(fastDisplay.accessibilityLabel.contains("Suhoor mode selected"))
        #expect(fastForecastRow.tags.map(\.title) == ["Fasting"])

        let quietEntry = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            skipDay: true,
            quickWakeModeOverride: .quiet
        )
        let quietDisplay = MorningHomePresentation.heroDisplay(
            entry: quietEntry,
            permissionSummary: "",
            currentDate: today,
            timeZone: timeZone
        )
        let quietForecastRow = MorningHomePresentation.nextTenMorningsRowDisplay(
            for: quietEntry,
            index: 0,
            currentDate: today,
            timeZone: timeZone
        )

        #expect(quietDisplay.selectedQuickWakeMode == .quiet)
        #expect(quietDisplay.quickWakeModeOptions.first(where: { $0.mode == .quiet })?.isSelected == true)
        #expect(quietDisplay.primaryText == "Quiet mode")
        #expect(quietDisplay.detailText == "No alarm will ring for tomorrow")
        #expect(quietDisplay.accessibilityLabel.contains("Quiet mode selected"))
        #expect(quietDisplay.wakeWindowIndicatorState == .none)
        #expect(quietDisplay.wakeWindowIndicatorIconName == nil)
        #expect(quietDisplay.fajrWindowVisualMode == .staticWithinFajrWindow)
        #expect(quietDisplay.wakeAdjustmentEnabled == false)
        #expect(quietDisplay.wakeAdjustmentAccessibilityValue == nil)
        #expect(quietForecastRow.tags.map(\.title) == ["Quiet mode"])
    }

    @Test
    func alarmDayDetailPresentationUsesHeroStateWithoutDiagnostics() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 30, timeZone: timeZone)
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)

        let dateLine = AlarmDayDetailPresentation.dateLine(
            for: date,
            timeZone: timeZone,
            hijriDateTextProvider: { _, _ in "14 Dhul Qi'dah" }
        )
        #expect(dateLine == "Friday, May 1 · 14 Dhul Qi'dah")

        let fajrEntry = Self.makeWakeEntry(date: date, timeZone: timeZone)
        let fajrDisplay = MorningHomePresentation.heroDisplay(
            entry: fajrEntry,
            permissionSummary: "",
            locationDisplayText: dateLine,
            currentDate: today,
            timeZone: timeZone
        )
        #expect(fajrDisplay.locationText == dateLine)
        #expect(AlarmDayDetailPresentation.modeOptions(for: fajrDisplay).map(\.title) == ["Suhoor", "Fajr", "Quiet"])
        #expect(AlarmDayDetailPresentation.purpose(for: fajrEntry) == nil)
        #expect(AlarmDayDetailPresentation.relationText(for: fajrDisplay) == "Wake up 30 min before Fajr ends")
        #expect(AlarmDayDetailPresentation.fajrAdhanSetting(for: fajrEntry, purpose: nil) == nil)
        let fajrContext = AlarmDayDetailPresentation.context(
            for: fajrEntry,
            display: fajrDisplay,
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        )
        #expect(fajrContext.summary == "There are no Sunnah fasting opportunities for this day. You can still choose Suhoor to plan a Voluntary, Qada, Vow, Kaffarah, or Other fast.")
        #expect(fajrContext.sentenceChips.isEmpty)
        #expect(fajrContext.significance == nil)
        #expect(fajrContext.hasContent)

        let quietEntry = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            skipDay: true,
            quickWakeModeOverride: .quiet
        )
        let quietDisplay = MorningHomePresentation.heroDisplay(
            entry: quietEntry,
            permissionSummary: "",
            locationDisplayText: dateLine,
            currentDate: today,
            timeZone: timeZone
        )
        #expect(AlarmDayDetailPresentation.isQuiet(quietDisplay))
        let quietDetailDisplay = AlarmDayDetailPresentation.detailHeroDisplay(quietDisplay)
        #expect(quietDetailDisplay.primaryText == "Quiet Mode")
        #expect(quietDetailDisplay.wakeIconName == "moon.fill")
        #expect(AlarmDayDetailPresentation.relationText(for: quietDisplay) == "No alarm will ring for this date")
        #expect(AlarmDayDetailPresentation.purpose(for: quietEntry) == nil)
        #expect(AlarmDayDetailPresentation.accessibilitySummary(
            dateLine: dateLine,
            display: quietDisplay,
            purpose: nil,
            fastType: nil,
            fajrAdhan: AlarmDayDetailPresentation.fajrAdhanSetting(for: quietEntry, purpose: nil)
        ).contains("Quiet Mode. No alarm will ring for this date"))
        #expect(AlarmDayDetailPresentation.context(
            for: quietEntry,
            display: quietDisplay,
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        ).summary == "Quiet Mode is on for this date. No alarm will ring. There are no Sunnah fasting opportunities for this day.")

        let ramadanQuietEntry = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [.ramadan],
                explanation: .empty
            ),
            quickWakeModeOverride: .quiet,
            alarmDetailAudioPlanOverride: .fajrAdhan
        )
        let ramadanQuietDisplay = MorningHomePresentation.heroDisplay(
            entry: ramadanQuietEntry,
            permissionSummary: "",
            locationDisplayText: dateLine,
            currentDate: today,
            timeZone: timeZone
        )
        #expect(AlarmDayDetailPresentation.isQuiet(ramadanQuietDisplay))
        let ramadanQuietAdhan = AlarmDayDetailPresentation.fajrAdhanSetting(for: ramadanQuietEntry, purpose: nil)
        #expect(ramadanQuietAdhan?.isEnabled == true)
        #expect(ramadanQuietAdhan?.isLocked == true)
        #expect(ramadanQuietAdhan?.lockedNote == "Fajr adhan remains on for Ramadan")
    }

    @Test
    func alarmDayDetailSuhoorIntentionCoversRamadanAndFastingOpportunities() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)

        let ramadan = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [],
                supportingTags: [.ramadan],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor
        )
        #expect(AlarmDayDetailPresentation.purpose(for: ramadan) == nil)
        Self.expectAlarmDetailFastType(
            AlarmDayDetailPresentation.fastType(
                for: ramadan,
                purpose: nil
            ),
            title: "Ramadan fast",
            defaultOptionTitle: "Ramadan fast",
            isLocked: true,
            selectedOpportunityTitles: ["Ramadan fast"],
            options: ["Ramadan fast"]
        )
        #expect(AlarmDayDetailPresentation.context(
            for: ramadan,
            display: MorningHomePresentation.heroDisplay(
                entry: ramadan,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: date,
                timeZone: timeZone
            ),
            purpose: nil,
            fastType: AlarmDayDetailPresentation.fastType(for: ramadan, purpose: nil),
            fajrAdhan: AlarmDayDetailPresentation.fajrAdhanSetting(for: ramadan, purpose: nil),
            showsReset: false
        ).summary == "You are waking before Fajr for Ramadan. Ramadan fast is locked for this date.")
        #expect(AlarmDayDetailPresentation.fajrAdhanSetting(
            for: ramadan,
            purpose: nil
        )?.isLocked == true)

        let legacyTahajjud = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .tahajjud,
                secondaryContexts: [],
                supportingTags: [],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -45,
            quickWakeModeOverride: .suhoor
        )
        #expect(AlarmDayDetailPresentation.purpose(for: legacyTahajjud) == nil)
        #expect(AlarmDayDetailPresentation.context(
            for: legacyTahajjud,
            display: MorningHomePresentation.heroDisplay(
                entry: legacyTahajjud,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: date,
                timeZone: timeZone
            ),
            purpose: nil,
            fastType: AlarmDayDetailPresentation.fastType(for: legacyTahajjud, purpose: nil),
            fajrAdhan: AlarmDayDetailPresentation.fajrAdhanSetting(for: legacyTahajjud, purpose: nil),
            showsReset: false
        ).summary == "You are waking before Fajr for suhoor. This will be saved as a Voluntary fast unless you choose another Suhoor intention.")

        let fastWithTahajjudContext = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .fasting,
                secondaryContexts: [.tahajjud],
                supportingTags: [.voluntary],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -45,
            quickWakeModeOverride: .suhoor
        )
        #expect(AlarmDayDetailPresentation.purpose(for: fastWithTahajjudContext) == nil)

        let whiteDays = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.whiteDays],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fast
        )
        #expect(AlarmDayDetailPresentation.purpose(for: whiteDays) == nil)
        Self.expectAlarmDetailFastType(
            AlarmDayDetailPresentation.fastType(
                for: whiteDays,
                purpose: AlarmDayDetailPresentation.purpose(for: whiteDays)
            ),
            title: "Today's opportunities",
            defaultOptionTitle: "Today's opportunities",
            isLocked: false,
            selectedOpportunityTitles: ["White Days fast"],
            options: ["Voluntary fast", "Qada fast", "Vow / Nadhr fast", "Kaffarah fast", "Other fast"]
        )
        let whiteDaysContext = AlarmDayDetailPresentation.context(
            for: whiteDays,
            display: MorningHomePresentation.heroDisplay(
                entry: whiteDays,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: date,
                timeZone: timeZone
            ),
            purpose: AlarmDayDetailPresentation.purpose(for: whiteDays),
            fastType: AlarmDayDetailPresentation.fastType(for: whiteDays, purpose: AlarmDayDetailPresentation.purpose(for: whiteDays)),
            fajrAdhan: AlarmDayDetailPresentation.fajrAdhanSetting(for: whiteDays, purpose: AlarmDayDetailPresentation.purpose(for: whiteDays)),
            showsReset: false
        )
        #expect(whiteDaysContext.summary == "You are waking before Fajr for suhoor. This fast will use today's Sunnah opportunities by default: White Days fast.")
        #expect(whiteDaysContext.sentencePrefix == "You are waking before Fajr for suhoor. This fast will use today's Sunnah opportunities by default:")
        #expect(whiteDaysContext.sentenceChips.map(\.title) == ["White Days fast"])
        #expect(whiteDaysContext.significance == nil)

        let whiteDaysQada = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.whiteDays],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fast,
            alarmDetailFastTypeOverride: .qada
        )
        Self.expectAlarmDetailFastType(
            AlarmDayDetailPresentation.fastType(
                for: whiteDaysQada,
                purpose: AlarmDayDetailPresentation.purpose(for: whiteDaysQada)
            ),
            title: "Qada fast",
            defaultOptionTitle: "Today's opportunities",
            isLocked: false,
            selection: .qada,
            selectedOpportunityTitles: [],
            options: ["Voluntary fast", "Qada fast", "Vow / Nadhr fast", "Kaffarah fast", "Other fast"]
        )
        let whiteDaysQadaContext = AlarmDayDetailPresentation.context(
            for: whiteDaysQada,
            display: MorningHomePresentation.heroDisplay(
                entry: whiteDaysQada,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: date,
                timeZone: timeZone
            ),
            purpose: AlarmDayDetailPresentation.purpose(for: whiteDaysQada),
            fastType: AlarmDayDetailPresentation.fastType(for: whiteDaysQada, purpose: AlarmDayDetailPresentation.purpose(for: whiteDaysQada)),
            fajrAdhan: AlarmDayDetailPresentation.fajrAdhanSetting(for: whiteDaysQada, purpose: AlarmDayDetailPresentation.purpose(for: whiteDaysQada)),
            showsReset: false
        )
        #expect(whiteDaysQadaContext.summary == "You are waking before Fajr for a Qada fast.")
        #expect(whiteDaysQadaContext.sentenceChips.map(\.title) == ["Qada fast"])

        let whiteDaysVoluntaryReturn = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.whiteDays],
                explanation: .empty
            ),
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fast,
            alarmDetailFastTypeOverride: .voluntary
        )
        Self.expectAlarmDetailFastType(
            AlarmDayDetailPresentation.fastType(
                for: whiteDaysVoluntaryReturn,
                purpose: AlarmDayDetailPresentation.purpose(for: whiteDaysVoluntaryReturn)
            ),
            title: "Today's opportunities",
            defaultOptionTitle: "Today's opportunities",
            isLocked: false,
            selection: nil,
            selectedOpportunityTitles: ["White Days fast"],
            options: ["Voluntary fast", "Qada fast", "Vow / Nadhr fast", "Kaffarah fast", "Other fast"]
        )

        let multipleOpportunities = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.whiteDays, .shawwalSix, .mondayThursday],
                explanation: .empty
            ),
            plannedWakeState: .inFajr,
            quickWakeModeOverride: .fajr
        )
        let multipleContext = AlarmDayDetailPresentation.context(
            for: multipleOpportunities,
            display: MorningHomePresentation.heroDisplay(
                entry: multipleOpportunities,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: date,
                timeZone: timeZone
            ),
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        )
        #expect(multipleContext.summary == "This day has Sunnah fasting opportunities: White Days fast, Shawwal Six fast, and Monday / Thursday fast.")
        #expect(multipleContext.sentenceChips.map(\.title) == ["White Days fast", "Shawwal Six fast", "Monday / Thursday fast"])
        #expect(multipleContext.significance == nil)

        let monday = Self.makeDate(year: 2026, month: 5, day: 4, timeZone: timeZone)
        let mondayOpportunity = Self.makeWakeEntry(
            date: monday,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.mondayThursday],
                explanation: .empty
            ),
            plannedWakeState: .inFajr,
            quickWakeModeOverride: .fajr
        )
        let mondayContext = AlarmDayDetailPresentation.context(
            for: mondayOpportunity,
            display: MorningHomePresentation.heroDisplay(
                entry: mondayOpportunity,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: monday,
                timeZone: timeZone
            ),
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        )
        #expect(mondayContext.summary == "This day has Sunnah fasting opportunities: Monday fast.")
        #expect(mondayContext.sentenceChips.map(\.title) == ["Monday fast"])

        let thursday = Self.makeDate(year: 2026, month: 5, day: 7, timeZone: timeZone)
        let thursdayQuiet = Self.makeWakeEntry(
            date: thursday,
            timeZone: timeZone,
            context: ResolvedDayContext(
                primaryContext: .standard,
                secondaryContexts: [],
                supportingTags: [.mondayThursday],
                explanation: .empty
            ),
            skipDay: true,
            quickWakeModeOverride: .quiet
        )
        let thursdayQuietContext = AlarmDayDetailPresentation.context(
            for: thursdayQuiet,
            display: MorningHomePresentation.heroDisplay(
                entry: thursdayQuiet,
                permissionSummary: "",
                locationDisplayText: "",
                currentDate: thursday,
                timeZone: timeZone
            ),
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        )
        #expect(thursdayQuietContext.summary == "Quiet Mode is on for this date. No alarm will ring. This day has Sunnah fasting opportunities: Thursday fast.")
        #expect(thursdayQuietContext.sentenceChips.map(\.title) == ["Thursday fast"])

        let selectedFastAndTahajjud = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -45,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fastAndTahajjud
        )
        #expect(AlarmDayDetailPresentation.purpose(for: selectedFastAndTahajjud) == nil)

        let selectedOtherFast = Self.makeWakeEntry(
            date: date,
            timeZone: timeZone,
            plannedWakeState: .preFajr,
            wakeOffsetMinutesFromFajrStart: -30,
            quickWakeModeOverride: .suhoor,
            earlyWakePurposeOverride: .fast,
            alarmDetailFastTypeOverride: .other
        )
        Self.expectAlarmDetailFastType(
            AlarmDayDetailPresentation.fastType(
                for: selectedOtherFast,
                purpose: AlarmDayDetailPresentation.purpose(for: selectedOtherFast)
            ),
            title: "Other fast",
            defaultOptionTitle: "Voluntary fast",
            isLocked: false,
            selection: .other,
            selectedOpportunityTitles: [],
            options: ["Voluntary fast", "Qada fast", "Vow / Nadhr fast", "Kaffarah fast", "Other fast"]
        )
        let voluntaryOptionCount = AlarmDayDetailPresentation.fastType(
            for: selectedOtherFast,
            purpose: AlarmDayDetailPresentation.purpose(for: selectedOtherFast)
        )?.options.filter { $0.title == "Voluntary fast" }.count
        #expect(voluntaryOptionCount == 1)
    }

    @Test
    func resolvedMorningWakeStateCoversV02SelectionAndBoundaryMatrix() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone)

        let fajr = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(date: date, timeZone: timeZone).activeDay,
            timeZone: timeZone
        )

        #expect(fajr.quickWakeSelection == .fajr)
        #expect(fajr.underlyingWakeMode == .fajr)
        #expect(fajr.boundaryRegime == .defaultFajrWindow)
        #expect(fajr.wakeTimeResolution.origin == .globalDefaultFajrOffset)
        #expect(fajr.alarmActivation == .active)
        #expect(fajr.visualMode == .interactiveDefaultFajr)
        #expect(fajr.copyState.finalRelationText == "Wake up 30 min before Fajr ends")
        #expect(fajr.copyState.relationTone == .normal)

        let fast = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                plannedWakeState: .preFajr,
                wakeOffsetMinutesFromFajrStart: -30,
                quickWakeModeOverride: .suhoor
            ).activeDay,
            timeZone: timeZone
        )

        #expect(fast.quickWakeSelection == .suhoor)
        #expect(fast.dayContext == .fastingIntended)
        #expect(fast.underlyingWakeMode == .earlyWorship)
        #expect(fast.boundaryRegime == .earlyWorshipWindow)
        #expect(fast.wakeBoundaryResolution.finalThirdStart != nil)
        #expect(fast.wakeTimeResolution.origin == .quickSelectorDefault)
        #expect(fast.copyState.finalRelationText == "Wake up 30 min before Fajr begins")
        #expect(fast.copyState.relationTone == .normal)

        let fajrAdhanWakeAudio = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                quickWakeModeOverride: .fajr,
                alarmDetailAudioPlanOverride: .fajrAdhan
            ).activeDay,
            timeZone: timeZone
        )

        #expect(fajrAdhanWakeAudio.quickWakeSelection == .fajr)
        #expect(fajrAdhanWakeAudio.alarmActivation == .active)
        #expect(fajrAdhanWakeAudio.scheduleStatus != .notScheduledBecauseQuiet)

        let quietFajr = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                skipDay: true,
                quickWakeModeOverride: .quiet
            ).activeDay,
            timeZone: timeZone
        )

        #expect(quietFajr.quickWakeSelection == .quiet)
        #expect(quietFajr.underlyingWakeMode == .fajr)
        #expect(quietFajr.boundaryRegime == .quietDefaultFajrWindow)
        #expect(quietFajr.alarmActivation == .quietSuppressed)
        #expect(quietFajr.scheduleStatus == .notScheduledBecauseQuiet)
        #expect(quietFajr.visualMode == .staticDefaultFajrQuiet)
        #expect(quietFajr.copyState.finalRelationText == "No alarm will ring for tomorrow")

        let quietFast = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                skipDay: true,
                plannedWakeState: .preFajr,
                wakeOffsetMinutesFromFajrStart: -30,
                quickWakeModeOverride: .quiet
            ).activeDay,
            timeZone: timeZone
        )

        #expect(quietFast.quickWakeSelection == .quiet)
        #expect(quietFast.underlyingWakeMode == .earlyWorship)
        #expect(quietFast.boundaryRegime == .quietEarlyWorshipWindow)
        #expect(quietFast.visualMode == .staticEarlyWorshipQuiet)

        let opportunityOnly = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .standard,
                    secondaryContexts: [],
                    supportingTags: [.mondayThursday],
                    explanation: .empty
                )
            ).activeDay,
            timeZone: timeZone
        )

        #expect(opportunityOnly.dayContext == .fastingOpportunity)
        #expect(opportunityOnly.underlyingWakeMode == .fajr)
        #expect(opportunityOnly.boundaryRegime == .defaultFajrWindow)

        let tahajjud = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                context: ResolvedDayContext(
                    primaryContext: .tahajjud,
                    secondaryContexts: [],
                    supportingTags: [],
                    explanation: .empty
                ),
                wakeOffsetMinutesFromFajrStart: -45
            ).activeDay,
            timeZone: timeZone
        )

        #expect(tahajjud.dayContext == .ordinary)
        #expect(tahajjud.underlyingWakeMode == .fajr)
        #expect(tahajjud.boundaryRegime == .customOutOfRange)

        let adjusted = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(
                date: date,
                timeZone: timeZone,
                hasDayOverride: true,
                plannedWakeState: .fixedWake
            ).activeDay,
            timeZone: timeZone
        )

        #expect(adjusted.wakeTimeResolution.origin == .manualDragOverride)
        #expect(adjusted.underlyingWakeMode == .fajr)
        #expect(adjusted.dayContext == .adjusted)

        let permissionBlocked = MorningWakeResolutionService.resolve(
            for: Self.makeWakeEntry(date: date, timeZone: timeZone).activeDay,
            scheduleStatusOverride: .permissionBlocked,
            timeZone: timeZone
        )

        #expect(permissionBlocked.alarmActivation == .active)
        #expect(permissionBlocked.scheduleStatus == .permissionBlocked)
        #expect(permissionBlocked.copyState.scheduleWarningText == "Alarm permission needed")
    }

    @Test
    func morningPlanResolverUsesEarlyWakeOnlyForFastIntentions() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let defaultRule = MorningWakeRule(state: .inFajr, anchorType: .fajrEnd, deltaMinutes: 30)
        let defaultPlan = MorningPlan(
            id: "default-daily",
            title: "Daily morning plan",
            kind: .defaultDaily,
            wakeRule: defaultRule,
            wakeAnchorType: .fajrEnd,
            wakeDelta: WakeDelta(relation: .before, minutes: 30),
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: false,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: false,
            iftarReminderEnabled: false
        )
        let planState = MorningPlanState(
            schemaVersion: 2,
            activationMode: .dailyActive,
            defaultDailyPlan: defaultPlan,
            lastMigrationAt: nil
        )
        let config = Self.makeWakeEntry(date: date, timeZone: timeZone).activeDay.effectiveConfig

        let opportunityOnly = MorningPlanResolver.resolve(
            dateKey: dateKey,
            provenances: [],
            effectiveConfig: config,
            tagResult: TagComputationResult(
                computedPrimaryIntent: .other,
                computedSecondaryTags: [.whiteDays],
                secondaryDetails: [:],
                suppressedSecondaryTags: []
            ),
            morningPlanState: planState
        )
        let qada = MorningPlanResolver.resolve(
            dateKey: dateKey,
            provenances: [],
            effectiveConfig: config,
            tagResult: TagComputationResult(
                computedPrimaryIntent: .qadaMakeup,
                computedSecondaryTags: [.whiteDays],
                secondaryDetails: [:],
                suppressedSecondaryTags: [.whiteDays]
            ),
            morningPlanState: planState
        )
        let ramadan = MorningPlanResolver.resolve(
            dateKey: dateKey,
            provenances: [],
            effectiveConfig: config,
            tagResult: TagComputationResult(
                computedPrimaryIntent: .ramadanObligatory,
                computedSecondaryTags: [],
                secondaryDetails: [:],
                suppressedSecondaryTags: []
            ),
            morningPlanState: planState
        )

        #expect(opportunityOnly.selectedPlan.wakeRule.state == .inFajr)
        #expect(opportunityOnly.selectedPlan.wakeRule.anchorType == .fajrEnd)
        #expect(qada.selectedPlan.kind == .qadaAssignment)
        #expect(qada.selectedPlan.wakeRule.state == .preFajr)
        #expect(qada.selectedPlan.wakeRule.anchorType == .fajrStart)
        #expect(ramadan.selectedPlan.wakeRule.state == .preFajr)
        #expect(ramadan.selectedPlan.wakeRule.anchorType == .fajrStart)
    }

    @Test
    func swiftUIViewFilesDoNotOwnMorningResolutionOrScheduling() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let featuresRoot = repoRoot.appendingPathComponent("Subh/Features")
        let viewFiles = FileManager.default
            .enumerator(at: featuresRoot, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.lastPathComponent.hasSuffix("View.swift") } ?? []
        let forbiddenPatterns = [
            "EarlyWorshipBoundaryResolver.finalThirdStart",
            "DailyAlarmOverride(",
            ".updateOverride(",
            ".scheduleDay(",
            ".cancelDay(",
            "NotificationScheduler(",
            "AlarmScheduler(",
            "AlarmKitScheduler(",
            "SchedulingIdentifiers.",
            "UNUserNotificationCenter.current().pendingNotificationRequests",
            ".pendingNotificationRequests()",
            "AlarmManager.shared"
        ]

        let violations = try viewFiles.flatMap { file -> [String] in
            let contents = try String(contentsOf: file, encoding: .utf8)
            return forbiddenPatterns
                .filter { contents.contains($0) }
                .map { "\(file.lastPathComponent): \($0)" }
        }

        #expect(violations.isEmpty, "SwiftUI view ownership violations: \(violations.joined(separator: ", "))")
    }

    @Test
    func finalThirdUsesRealInstantsAcrossDstBoundary() throws {
        let timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let maghrib = Self.makeDate(year: 2026, month: 3, day: 7, hour: 18, minute: 0, timeZone: timeZone)
        let fajr = Self.makeDate(year: 2026, month: 3, day: 8, hour: 5, minute: 30, timeZone: timeZone)
        let finalThird = try #require(EarlyWorshipBoundaryResolver.finalThirdStart(
            targetFajrStart: fajr,
            maghrib: maghrib,
            timeZone: timeZone
        ))
        let nightDuration = fajr.timeIntervalSince(maghrib)

        #expect(finalThird > maghrib)
        #expect(finalThird < fajr)
        #expect(abs(finalThird.timeIntervalSince(fajr) + nightDuration / 3) < 1)
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
    func morningHeroRangeMarkerHandoffUsesExpectedQuickModeDirections() {
        #expect(
            MorningHeroRangeMarkerHandoff.sequence(
                from: .interactiveWithinFajrWindow,
                to: .interactiveEarlyWorshipWindow
            ) == MorningHeroRangeMarkerHandoff(exitRatio: 0, entryRatio: 1)
        )
        #expect(
            MorningHeroRangeMarkerHandoff.sequence(
                from: .interactiveEarlyWorshipWindow,
                to: .interactiveWithinFajrWindow
            ) == MorningHeroRangeMarkerHandoff(exitRatio: 1, entryRatio: 0)
        )
        #expect(
            MorningHeroRangeMarkerHandoff.sequence(
                from: .staticEarlyWorshipWindow,
                to: .interactiveWithinFajrWindow
            ) == nil
        )
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
        #expect(tahajjud.statusText == "Suhoor planned")
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
    func morningcastEntriesIncludeTodayWhenWakeIsUpcoming() {
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

        #expect(visible.map(\.schedule.date) == entries.map(\.schedule.date))
    }

    @Test
    func morningcastEntriesStartWithTomorrowAfterTodaysWakePasses() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, hour: 12, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let todayStart = calendar.startOfDay(for: today)
        let entries = (0..<4).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: todayStart) ?? todayStart,
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
        #expect(MorningHomeSnapshot.forecastTitle == "NEXT 7 DAYS")

        let snapshot = MorningHomePresentation.nextTenMorningsSnapshot(from: [])
        #expect(snapshot.title == "NEXT 7 DAYS")
        #expect(snapshot.loadingState == .empty)
    }

    @Test
    func nextTenMorningsForecastUsesSevenRowsWhenReady() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let startDate = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let entries = (0..<8).map { offset in
            Self.makeWakeEntry(
                date: calendar.date(byAdding: .day, value: offset, to: startDate) ?? startDate,
                timeZone: timeZone
            )
        }

        let snapshot = MorningHomePresentation.nextTenMorningsSnapshot(
            from: entries,
            currentDate: startDate,
            timeZone: timeZone
        )

        #expect(snapshot.rows.count == 7)
        #expect(snapshot.rows.map(\.id) == Array(entries.prefix(7)).map(\.id))
        #expect(snapshot.loadingState == .ready)
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
        #expect(Self.nextTenTagTitles(opportunities: [.ashura], selectedQuickWakeMode: .suhoor) == ["Fasting"])
        #expect(Self.nextTenTagTitles(opportunities: [.mondayThursday]) == ["Fajr"])
        #expect(Self.nextTenTagTitles(primary: .voluntary, secondary: [.mondayThursday]) == ["Fasting", "Mon/Thu"])
        #expect(Self.nextTenTagTitles(opportunities: [.whiteDays]) == ["Fajr", "White Days"])
        #expect(Self.nextTenTagTitles(primary: .voluntary, secondary: [.whiteDays]) == ["Fasting", "White Days"])
        #expect(Self.nextTenTagTitles(opportunities: [.shawwalSix]) == ["Fajr", "Shawwal 6"])
        #expect(Self.nextTenTagTitles(opportunities: [.shawwalSix], shawwalComplete: true) == ["Fajr"])
    }

    @Test
    func nextTenMorningsOpportunityTagsUseResolvedContext() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 5, day: 1, timeZone: timeZone)
        let resolution = NextTenMorningsTagResolver.resolve(
            NextTenMorningsTagResolverInput(
                date: date,
                dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                resolvedContext: Self.context(primary: .standard, tags: [.whiteDays]),
                tagResult: Self.tagResult(primary: .other),
                compatibleOpportunityTags: [],
                quietModeState: .inactive,
                selectedQuickWakeMode: nil,
                shawwalSixProgress: .incomplete,
                hasDayOverride: false
            )
        )

        #expect(resolution.visibleTags.map(\.title) == ["Fajr", "White Days"])
        #expect(resolution.accessibilityTags.map(\.title) == ["Fajr", "White Days"])
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
            dateLabel: "Wed, May 6",
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
        #expect(metrics.minimumDateToTagGap == NextTenMorningsRowMetrics.minimumDateToTagGap)
        #expect(metrics.minimumTagToTimeGap == NextTenMorningsRowMetrics.minimumTagToTimeGap)
        #expect(narrowLanes.dateLaneWidth == wideLanes.dateLaneWidth)
        #expect(narrowLanes.trailingLaneWidth == wideLanes.trailingLaneWidth)
        #expect(narrowLanes.dateLaneWidth == metrics.dateLaneWidth)
        #expect(narrowLanes.trailingLaneWidth == metrics.trailingLaneWidth)
        #expect(narrowLanes.dateToTagGap == metrics.minimumDateToTagGap)
        #expect(narrowLanes.tagToTrailingGap == metrics.minimumTagToTimeGap)
        #expect(narrowLanes.tagLaneWidth >= metrics.minimumTagLaneWidth)
        #expect(narrowLanes.tagLaneCenterX == narrowLanes.dateLaneWidth + narrowLanes.dateToTagGap + (narrowLanes.tagLaneWidth / 2))
        #expect(wideLanes.tagLaneCenterX == wideLanes.dateLaneWidth + wideLanes.dateToTagGap + (wideLanes.tagLaneWidth / 2))
        #expect(narrowLanes.tagLaneCenterX == 156)
        #expect(wideLanes.tagLaneCenterX == 206)
        #expect(narrowLanes.tagLaneWidth >= 132)
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
    func compactFajrcastAppliesLiveWakeAdjustmentToVisibleDay() {
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
        let focusedDay = activeDays[3]
        let provisionalWake = Self.makeDate(year: 2026, month: 4, day: 30, hour: 3, minute: 42, timeZone: timeZone)
        let provisionalMinutes = DateHelpers.minutesFromMidnight(for: provisionalWake, timeZone: timeZone)
        let provider = FajrWindowSurfaceProvider()
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: activeDays,
            overrideDateKeys: [],
            timeZone: timeZone
        )

        let snapshot = provider.compactSnapshot(
            dataset: dataset,
            anchorDateKey: focusedDay.dateKey,
            selectedDateKey: focusedDay.dateKey,
            liveWakeAdjustment: FajrWindowLiveWakeAdjustment(
                dateKey: focusedDay.dateKey,
                provisionalWakeTime: provisionalWake,
                source: .heroWakeSlider,
                phase: .changing
            ),
            now: monday,
            timeZone: timeZone
        )
        let focusedPoint = snapshot.chart.points.first { $0.dateKey == focusedDay.dateKey }

        #expect(snapshot.liveWakeAdjustment?.dateKey == focusedDay.dateKey)
        #expect(focusedPoint?.primaryWake == provisionalWake)
        #expect(focusedPoint?.primaryWakeMinutes == provisionalMinutes)
        #expect(snapshot.selectedDay.timeMain == "3:42")
        #expect(snapshot.chart.compactYTicks.first?.minutes ?? 0 <= provisionalMinutes)
        #expect(snapshot.points.map(\.dateKey) == activeDays.map(\.dateKey))
    }

    @Test
    func compactFajrcastIgnoresLiveWakeAdjustmentOutsideVisibleWindow() {
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
            liveWakeAdjustment: FajrWindowLiveWakeAdjustment(
                dateKey: "2026-05-20",
                provisionalWakeTime: Self.makeDate(year: 2026, month: 5, day: 20, hour: 3, minute: 42, timeZone: timeZone),
                source: .heroWakeSlider,
                phase: .changing
            ),
            now: monday,
            timeZone: timeZone
        )

        #expect(snapshot.liveWakeAdjustment == nil)
        #expect(snapshot.points.map(\.primaryWake) == activeDays.map(\.schedule.wakeDate))
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
    func compactFajrcastGeometryComputesRotatedBoundingRect() {
        let rect = CompactFajrcastGeometry.rotatedBoundingRect(
            center: CGPoint(x: 40, y: 50),
            labelWidth: 40,
            labelHeight: 10,
            angleRadians: .pi / 4
        )

        #expect(rect.minX < 40)
        #expect(rect.maxX > 40)
        #expect(rect.minY < 50)
        #expect(rect.maxY > 50)
        #expect(rect.width > 30)
        #expect(rect.height > 10)
    }

    @Test
    func compactFajrcastGeometryCanClampPointToInsetBounds() {
        let bounds = CompactFajrcastGeometry.insetBounds(
            for: CGRect(x: 0, y: 0, width: 100, height: 80),
            halfExtents: CGSize(width: 12, height: 6),
            clearance: 6
        )
        let clamped = CompactFajrcastGeometry.clamped(
            CGPoint(x: -20, y: 100),
            inside: bounds
        )

        #expect(bounds.minX == 18)
        #expect(bounds.minY == 12)
        #expect(clamped.x == bounds.minX)
        #expect(clamped.y == bounds.maxY)
    }

    @Test
    func compactFajrcastUsesForwardVisibleWindow() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let today = Self.makeDate(year: 2026, month: 4, day: 26, hour: 22, minute: 34, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let windowStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
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
            selectedDateKey: activeDays[0].dateKey,
            now: today,
            timeZone: timeZone
        )

        let anchorKey = activeDays[0].dateKey
        let visibleDateKeys = activeDays.map { $0.dateKey }
        let snapshotDateKeys = snapshot.points.map { $0.dateKey }

        #expect(snapshot.anchorDateKey == anchorKey)
        #expect(snapshot.points.first?.dateKey == activeDays.first?.dateKey)
        #expect(snapshot.selectedDay.dateKey == anchorKey)
        #expect(snapshot.chart.points.firstIndex(where: { $0.dateKey == snapshot.selectedDay.dateKey }) == 0)
        #expect(snapshotDateKeys == visibleDateKeys)
        #expect(snapshot.chart.points.count == 7)
        #expect(snapshot.chart.compactYTicks.count == 4)
        #expect(snapshot.chart.points.map { Self.weekdayInitial(for: $0.date, timeZone: timeZone) } == ["M", "T", "W", "T", "F", "S", "S"])

        let focusedSnapshot = provider.compactSnapshot(
            dataset: dataset,
            anchorDateKey: anchorKey,
            selectedDateKey: activeDays[3].dateKey,
            now: today,
            timeZone: timeZone
        )
        let focusedDateKeys = focusedSnapshot.points.map { $0.dateKey }

        #expect(focusedSnapshot.anchorDateKey == anchorKey)
        #expect(focusedSnapshot.selectedDay.dateKey == activeDays[3].dateKey)
        #expect(focusedSnapshot.chart.points.firstIndex(where: { $0.dateKey == anchorKey }) == 0)
        #expect(focusedSnapshot.chart.points.firstIndex(where: { $0.dateKey == focusedSnapshot.selectedDay.dateKey }) == 3)
        #expect(focusedDateKeys == visibleDateKeys)
        #expect(focusedSnapshot.selectedDay.relativeLabel == "THURSDAY")
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
        #expect(snapBackSnapshot.chart.points.firstIndex(where: { $0.dateKey == snapBackSnapshot.selectedDay.dateKey }) == 0)
        #expect(snapBackDateKeys == visibleDateKeys)
        #expect(snapBackSnapshot.summary.primaryText == focusedSnapshot.summary.primaryText)
        #expect(snapBackSnapshot.summary.secondaryText == focusedSnapshot.summary.secondaryText)
    }

    @MainActor
    private final class RecordingRoutineScheduler: RoutineScheduling {
        var cancelledIdentifierSets: [SchedulingIdentifierSet] = []
        var scheduledEventIdentifiers: [String] = []
        var scheduledCanUseAlarmKit: [Bool] = []
        var scheduledFireDates: [Date] = []
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
            scheduledCanUseAlarmKit.append(canUseAlarmKit)
            scheduledFireDates.append(event.fireDate)
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

    private static func makeSchedulerActiveDayWithSecondaryEvents(date: Date, timeZone: TimeZone) -> ActiveAlarmDay {
        let activeDay = makeSchedulerActiveDay(date: date, timeZone: timeZone)
        let reminder = ScheduledEvent(
            id: "\(activeDay.dateKey).wakeReminder",
            type: .wakeReminder,
            dateKey: activeDay.dateKey,
            fireDate: activeDay.schedule.wakeDate.addingTimeInterval(-10 * 60),
            relativeTo: .wakeAlarm(offsetMinutes: -10),
            isUserVisible: true,
            affectsCompletion: false,
            deliveryKinds: [.reminder],
            soundRole: .reminder,
            wakeSessionID: "\(activeDay.dateKey).wake-session",
            wakeSessionRole: .companion
        )
        let boundary = ScheduledEvent(
            id: "\(activeDay.dateKey).fajrBoundaryNotice",
            type: .fajrBoundaryNotice,
            dateKey: activeDay.dateKey,
            fireDate: activeDay.schedule.fajrDate,
            relativeTo: .prayerBoundary(boundary: .fajrStart, offsetMinutes: 0),
            isUserVisible: true,
            affectsCompletion: false,
            deliveryKinds: [.boundary],
            soundRole: .fajrStart,
            wakeSessionID: "\(activeDay.dateKey).wake-session",
            wakeSessionRole: .checkpoint
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
            scheduledEvents: activeDay.scheduledEvents + [reminder, boundary],
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

    private static func expectAlarmDetailPurpose(
        _ purpose: AlarmDetailPurposePresentation?,
        title: String,
        isLocked: Bool,
        selection: EarlyWakePurposeOverride? = nil
    ) {
        #expect(purpose?.title == title)
        #expect(purpose?.isLocked == isLocked)
        #expect(purpose?.selection?.rawValue == selection?.rawValue)
    }

    private static func expectAlarmDetailFastType(
        _ fastType: AlarmDetailFastPurposePresentation?,
        title: String,
        defaultOptionTitle: String,
        isLocked: Bool,
        selection: AlarmDetailFastTypeOverride? = nil,
        selectedOpportunityTitles: [String] = [],
        options: [String]? = nil
    ) {
        #expect(fastType?.title == title)
        #expect(fastType?.defaultOptionTitle == defaultOptionTitle)
        #expect(fastType?.isLocked == isLocked)
        #expect(fastType?.selection?.rawValue == selection?.rawValue)
        #expect(fastType?.selectedOpportunityTitles == selectedOpportunityTitles)
        if let options {
            #expect(fastType?.options.map(\.title) == options)
        }
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
        fajrStartMinuteOffset: Int = 0,
        quickWakeModeOverride: QuickWakeMode? = nil,
        earlyWakePurposeOverride: EarlyWakePurposeOverride? = nil,
        alarmDetailFastTypeOverride: AlarmDetailFastTypeOverride? = nil,
        alarmDetailAudioPlanOverride: AlarmDetailAudioPlan? = nil
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
        let wakeAnchorType: WakeAnchorType
        switch plannedWakeState {
        case .fixedWake:
            wakeAnchorType = .clockTime
        case .preFajr:
            wakeAnchorType = .fajrStart
        case .inFajr, .postFajr:
            wakeAnchorType = .fajrEnd
        }
        let wakeRule = MorningWakeRule(
            state: plannedWakeState,
            anchorType: wakeAnchorType,
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
            quickWakeModeOverride: quickWakeModeOverride,
            earlyWakePurposeOverride: earlyWakePurposeOverride,
            alarmDetailFastTypeOverride: alarmDetailFastTypeOverride,
            alarmDetailAudioPlanOverride: alarmDetailAudioPlanOverride,
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
            hasOverrides: hasDayOverride
                || skipDay
                || quickWakeModeOverride != nil
                || earlyWakePurposeOverride != nil
                || alarmDetailFastTypeOverride != nil
                || alarmDetailAudioPlanOverride != nil
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
        selectedQuickWakeMode: QuickWakeMode? = nil,
        shawwalComplete: Bool = false
    ) -> [String] {
        nextTenTagResolution(
            quietModeState: quietModeState,
            primary: primary,
            secondary: secondary,
            opportunities: opportunities,
            selectedQuickWakeMode: selectedQuickWakeMode,
            shawwalComplete: shawwalComplete
        ).visibleTags.map(\.title)
    }

    private static func nextTenTagResolution(
        quietModeState: NextTenMorningsQuietModeState = .inactive,
        primary: FastPrimaryIntent = .other,
        secondary: Set<FastSecondaryVirtueTag> = [],
        opportunities: [FastSecondaryVirtueTag] = [],
        selectedQuickWakeMode: QuickWakeMode? = nil,
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
                selectedQuickWakeMode: selectedQuickWakeMode,
                shawwalSixProgress: shawwalComplete
                    ? ShawwalSixProgressSummary(
                        completedIntendedShawwalSixCount: 6,
                        remainingCount: 0,
                        completedDateKeys: [],
                        isComplete: true
                    )
                    : .incomplete,
                hasDayOverride: false
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
