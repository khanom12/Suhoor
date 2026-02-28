import Foundation
import Testing
@testable import Suhoor

@Suite
struct SuhoorTests {
    @Test
    func settingsEncodeDecode() throws {
        let settings = AppSettings.default
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded == settings)
    }

    @Test
    func ramadanRangeComputesFor2026() {
        let engine = RamadanProfileEngine()
        let range = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        )
        #expect(range != nil)
        #expect((range?.dayCount ?? 0) >= 29)
    }

    @Test
    func ramadanAdjustmentsShiftRange() {
        let engine = RamadanProfileEngine()
        let base = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        )
        let shifted = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 1,
            endAdjustmentDays: -1,
            timeZone: .current
        )
        #expect(base != nil)
        #expect(shifted != nil)
        #expect(base?.startDate != shifted?.startDate)
        #expect(base?.endDate != shifted?.endDate)
    }

    @Test
    func dayNumberWithinRange() {
        let engine = RamadanProfileEngine()
        guard let range = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        ) else {
            #expect(false)
            return
        }

        let startDay = engine.computeRamadanDayNumber(for: range.startDate, range: range, timeZone: .current)
        let endDay = engine.computeRamadanDayNumber(for: range.endDate, range: range, timeZone: .current)
        #expect(startDay == 1)
        #expect(endDay == range.dayCount)
    }

    @Test
    func perDayOverrideWinsOverLayers() {
        var settings = AppSettings.default
        settings.ramadanModeEnabled = true
        settings.weekendBoostEnabled = true
        settings.weekendBoostMinutes = 60
        settings.last10Enabled = true
        settings.last10BoostMinutes = 90
        settings.lqEnabled = true
        settings.lqBoostMinutes = 120

        let engine = RamadanProfileEngine()
        guard let range = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        ) else {
            #expect(false)
            return
        }

        let overrideDate = range.startDate
        let key = DateHelpers.dayIdentifier(for: overrideDate, timeZone: .current)
        settings.perDayExceptions[key] = DayException(
            disabledForDay: false,
            wakeOffsetOverrideMinutes: 90,
            reminderEnabledOverride: nil,
            atFajrEnabledOverride: nil,
            reminderMinutesOverride: nil,
            atFajrSoundOverride: nil
        )

        let ruleEngine = RuleEngine(settings: settings, timeZone: .current)
        #expect(ruleEngine.effectiveWakeOffsetMinutes(for: overrideDate) == 90)
    }

    @Test
    func precedenceWinsWhenMultipleApply() {
        var settings = AppSettings.default
        settings.ramadanModeEnabled = true
        settings.last10Enabled = true
        settings.last10BoostMinutes = 50
        settings.lqEnabled = true
        settings.lqBoostMinutes = 40
        settings.baseWakeOffsetMinutes = 30

        let profileEngine = RamadanProfileEngine()
        guard let range = profileEngine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        ) else {
            #expect(false)
            return
        }

        let date = range.endDate
        let dayNumber = profileEngine.computeRamadanDayNumber(for: date, range: range, timeZone: .current) ?? 1
        settings.lqNightNumbers = [dayNumber]

        let ruleEngine = RuleEngine(settings: settings, timeZone: .current)
        #expect(ruleEngine.effectiveWakeOffsetMinutes(for: date) == 70)
    }

    @Test
    func badgesIncludeCustomWhenOverrideExists() {
        var settings = AppSettings.default
        settings.ramadanModeEnabled = true

        let profileEngine = RamadanProfileEngine()
        guard let range = profileEngine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        ) else {
            #expect(false)
            return
        }

        let date = range.startDate
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        settings.perDayExceptions[key] = DayException(
            disabledForDay: false,
            wakeOffsetOverrideMinutes: 45,
            reminderEnabledOverride: nil,
            atFajrEnabledOverride: nil,
            reminderMinutesOverride: nil,
            atFajrSoundOverride: nil
        )

        let ruleEngine = RuleEngine(settings: settings, timeZone: .current)
        let badges = ruleEngine.applicableBadges(for: date)
        #expect(badges.contains(.custom))
    }

    @Test
    func skippedDayReturnsDisabledSummary() {
        var settings = AppSettings.default
        let date = Date()
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        settings.perDayExceptions[key] = DayException(
            disabledForDay: true,
            wakeOffsetOverrideMinutes: nil,
            reminderEnabledOverride: nil,
            atFajrEnabledOverride: nil,
            reminderMinutesOverride: nil,
            atFajrSoundOverride: nil
        )

        let summary = RuleEngine(settings: settings, timeZone: .current).ruleSummary(for: date)
        #expect(summary.disabledForDay == true)
    }

    @Test
    func laylatulQadrSpecificDateOverridesNightSelection() {
        var settings = AppSettings.default
        settings.ramadanModeEnabled = true
        settings.lqEnabled = true
        settings.lqBoostMinutes = 60
        settings.lqNightNumbers = [27]

        let engine = RamadanProfileEngine()
        guard let range = engine.computeRamadanRange(
            forGregorianYear: 2026,
            startAdjustmentDays: 0,
            endAdjustmentDays: 0,
            timeZone: .current
        ) else {
            #expect(false)
            return
        }

        let date = range.startDate
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        settings.lqSpecificDateKey = key

        let ruleEngine = RuleEngine(settings: settings, timeZone: .current)
        #expect(ruleEngine.appliedLayer(for: date)?.kind == .laylatulQadr)
    }

    @Test
    func eventTimesMatchFajrOffsets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let fajr = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 30))
        #expect(fajr != nil)
        guard let fajr else { return }

        let wake = ScheduleEventCalculator.wakeDate(for: fajr, offsetMinutes: 45, calendar: calendar)
        let reminder = ScheduleEventCalculator.reminderDate(for: fajr, reminderMinutes: 15, calendar: calendar)

        let wakeComponents = calendar.dateComponents([.hour, .minute, .day], from: wake)
        let reminderComponents = calendar.dateComponents([.hour, .minute, .day], from: reminder)
        let fajrComponents = calendar.dateComponents([.hour, .minute, .day], from: fajr)

        #expect(wakeComponents.hour == 4)
        #expect(wakeComponents.minute == 45)
        #expect(wakeComponents.day == fajrComponents.day)

        #expect(reminderComponents.hour == 5)
        #expect(reminderComponents.minute == 15)
        #expect(reminderComponents.day == fajrComponents.day)
    }

    @Test
    func dstBoundaryMaintainsOffsets() {
        let timeZone = TimeZone(identifier: "America/New_York") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let fajr = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 5, minute: 30))
        #expect(fajr != nil)
        guard let fajr else { return }

        let wake = ScheduleEventCalculator.wakeDate(for: fajr, offsetMinutes: 45, calendar: calendar)
        let reminder = ScheduleEventCalculator.reminderDate(for: fajr, reminderMinutes: 15, calendar: calendar)

        let wakeComponents = calendar.dateComponents([.hour, .minute, .day], from: wake)
        let reminderComponents = calendar.dateComponents([.hour, .minute, .day], from: reminder)

        #expect(wakeComponents.hour == 4)
        #expect(wakeComponents.minute == 45)
        #expect(reminderComponents.hour == 5)
        #expect(reminderComponents.minute == 15)
    }

    @Test
    func scheduleUpcomingIncludesReminderAfterWake() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 0))
        let wake = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 4, minute: 45))
        let reminder = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 15))
        let boundary = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 30))
        #expect(now != nil)
        #expect(wake != nil)
        #expect(reminder != nil)
        #expect(boundary != nil)
        guard let now, let wake, let reminder, let boundary else { return }

        let schedule = DaySchedule(
            date: wake,
            fajrDate: boundary,
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            fajrSoundChoice: .systemDefault,
            locationDescription: "",
            offsetMinutes: 45,
            calculationMethodName: "",
            timeZone: calendar.timeZone
        )
        var settings = AppSettings.default
        settings.isEnabled = true
        settings.reminderEnabledGlobal = true
        settings.atFajrEnabledGlobal = true

        #expect(RoutineScheduler.isScheduleUpcoming(schedule, settings: settings, now: now) == true)
    }

    @Test
    func scheduleUpcomingSkipsWhenAllPast() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 6, minute: 0))
        let wake = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 4, minute: 45))
        let reminder = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 15))
        let boundary = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 5, minute: 30))
        #expect(now != nil)
        #expect(wake != nil)
        #expect(reminder != nil)
        #expect(boundary != nil)
        guard let now, let wake, let reminder, let boundary else { return }

        let schedule = DaySchedule(
            date: wake,
            fajrDate: boundary,
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            fajrSoundChoice: .systemDefault,
            locationDescription: "",
            offsetMinutes: 45,
            calculationMethodName: "",
            timeZone: calendar.timeZone
        )
        var settings = AppSettings.default
        settings.isEnabled = true
        settings.reminderEnabledGlobal = true
        settings.atFajrEnabledGlobal = true

        #expect(RoutineScheduler.isScheduleUpcoming(schedule, settings: settings, now: now) == false)
    }

    @Test
    func schedulingIdentifiersAreStableAndDistinct() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)) ?? Date()
        let schedule = DaySchedule(
            date: day,
            fajrDate: day,
            wakeDate: day,
            reminderDate: nil,
            boundaryDate: nil,
            fajrSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: 0,
            calculationMethodName: "",
            timeZone: timeZone
        )

        let wakeId = SchedulingIdentifiers.alarmID(for: schedule, kind: .wake)
        let reminderId = SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder)
        let boundaryId = SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary)

        #expect(wakeId != reminderId)
        #expect(reminderId != boundaryId)
        #expect(boundaryId != wakeId)
        #expect(wakeId == SchedulingIdentifiers.alarmID(for: schedule, kind: .wake))
    }

    @Test
    func dateHelpersDayIdentifierStableForTimeZone() {
        let timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20, hour: 23, minute: 30)) ?? Date()
        let dayId = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        #expect(dayId == "2026-02-20")
    }

    @Test
    func alarmKnownStateIsScheduledMapping() {
        #expect(AlarmKnownState.scheduled.isScheduled == true)
        #expect(AlarmKnownState.alerting.isScheduled == true)
        #expect(AlarmKnownState.countdown.isScheduled == true)
        #expect(AlarmKnownState.paused.isScheduled == true)
        #expect(AlarmKnownState.dismissed.isScheduled == false)
        #expect(AlarmKnownState.unknown.isScheduled == false)
    }

    @Test
    func scheduleCacheStoreRoundTrip() throws {
        let defaults = UserDefaults(suiteName: "SuhoorTests.ScheduleCacheStore") ?? .standard
        defaults.removeObject(forKey: "Suhoor.ScheduleCache")
        let store = ScheduleCacheStore(defaults: defaults)
        let schedule = DaySchedule(
            date: Date(),
            fajrDate: Date().addingTimeInterval(3600),
            wakeDate: Date().addingTimeInterval(1800),
            reminderDate: nil,
            boundaryDate: nil,
            fajrSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: 0,
            calculationMethodName: "",
            timeZone: .current
        )
        let cache = ScheduleCacheStore.Cache(
            lastScheduledDate: Date(),
            lastUpdated: Date(),
            schedulingMode: .notifications,
            schedules: [schedule]
        )
        store.save(cache)

        let loaded = store.load()
        #expect(loaded.schedulingMode == .notifications)
        #expect(loaded.schedules.count == 1)
        store.clear()
    }

    @Test
    func alarmRecordStoreUpsertRemoveAndClear() {
        let store = AlarmRecordStore()
        store.clearAll()
        let id = UUID()
        let record = AlarmRecord(
            id: id,
            kind: .wake,
            scheduledDate: Date(),
            fajrDateTime: nil,
            isTest: true,
            testRunId: UUID(),
            label: "Test"
        )
        store.upsert(record)
        #expect(store.record(for: id) != nil)

        let updated = AlarmRecord(
            id: id,
            kind: .wake,
            scheduledDate: Date().addingTimeInterval(60),
            fajrDateTime: nil,
            isTest: true,
            testRunId: record.testRunId,
            label: "Updated"
        )
        store.upsert(updated)
        #expect(store.record(for: id)?.label == "Updated")

        store.remove(id: id)
        #expect(store.record(for: id) == nil)

        store.upsert(record)
        store.clearAllTests()
        #expect(store.record(for: id) == nil)
        store.clearAll()
    }

    @Test
    func alarmStateStoreUpdateRemoveAndClear() {
        let store = AlarmStateStore()
        store.clear()
        let id = UUID()
        store.update(id: id, state: .scheduled, timestamp: Date())
        #expect(store.entry(for: id)?.state == .scheduled)
        store.update(id: id, state: .dismissed, timestamp: Date())
        #expect(store.entry(for: id)?.state == .dismissed)
        store.remove(id: id)
        #expect(store.entry(for: id) == nil)
        store.clear()
    }

    @Test
    @MainActor
    func countdownStartsOnReminderFiredAndPersistsOnDismiss() async {
        guard #available(iOS 26.0, *) else { return }
        let liveActivityManager = MockLiveActivityManager()
        let countdownManager = CountdownManager(
            store: CountdownSessionStore(),
            activityManager: liveActivityManager,
            timeProvider: FixedTimeProvider(now: Date())
        )
        let recordStore = AlarmRecordStore()
        let stateStore = AlarmStateStore()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: MockAlarmScheduler(),
            recordStore: recordStore,
            stateStore: stateStore
        )
        let router = AlarmEventRouter(
            recordStore: recordStore,
            stateStore: stateStore,
            countdownManager: countdownManager,
            enableCountdown: true
        )

        let fajrDate = Date().addingTimeInterval(300)
        let record = AlarmRecord(
            id: UUID(),
            kind: .reminder,
            scheduledDate: Date(),
            fajrDateTime: fajrDate,
            isTest: true,
            testRunId: nil,
            label: "Test"
        )
        recordStore.upsert(record)

        await router.handleAlarmFired(record: record)
        #expect(countdownManager.currentSession?.status == .running)

        await router.handleAlarmDismissed(id: record.id)
        #expect(countdownManager.currentSession?.status == .running)
    }

    @Test
    @MainActor
    func stopCountdownDoesNotCancelAdhan() async {
        let alarmScheduler = MockAlarmScheduler()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: AlarmRecordStore(),
            stateStore: AlarmStateStore()
        )
        let countdownManager = CountdownManager(
            store: CountdownSessionStore(),
            activityManager: MockLiveActivityManager()
        )

        await countdownManager.startCountdown(fajrDateTime: Date().addingTimeInterval(120))
        await countdownManager.stopCountdownByUser()

        #expect(alarmScheduler.canceledIds.isEmpty)
        _ = alarmCoordinator
    }

    @Test
    @MainActor
    func countdownEndsWhenTimeReached() async {
        let now = Date()
        let countdownManager = CountdownManager(
            store: CountdownSessionStore(),
            activityManager: MockLiveActivityManager(),
            timeProvider: FixedTimeProvider(now: now.addingTimeInterval(10))
        )
        await countdownManager.startCountdown(fajrDateTime: now)
        await countdownManager.reconcileIfNeeded()
        #expect(countdownManager.currentSession?.status == .ended)
    }

    @Test
    @MainActor
    func alarmCoordinatorUpdatesRecordAndStateOnScheduleAndCancel() async {
        let recordStore = AlarmRecordStore()
        let stateStore = AlarmStateStore()
        recordStore.clearAll()
        stateStore.clear()

        let alarmScheduler = MockAlarmScheduler()
        let coordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: recordStore,
            stateStore: stateStore
        )

        let id = UUID()
        let scheduled = await coordinator.scheduleAlarm(
            id: id,
            kind: .wake,
            date: Date().addingTimeInterval(60),
            label: "Test",
            fajrDateTime: nil,
            soundName: nil,
            snoozeDuration: nil
        )
        #expect(scheduled == true)
        #expect(recordStore.record(for: id) != nil)
        #expect(stateStore.entry(for: id)?.state == .scheduled)

        coordinator.cancel(id: id)
        #expect(recordStore.record(for: id) == nil)
        #expect(stateStore.entry(for: id)?.state == .dismissed)

        recordStore.clearAll()
        stateStore.clear()
    }

    @Test
    @MainActor
    func scheduleTestScenarioIsIdempotent() async {
        let alarmScheduler = MockAlarmScheduler()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: AlarmRecordStore(),
            stateStore: AlarmStateStore(),
            timeProvider: FixedTimeProvider(now: Date())
        )
        let runner = AlarmKitTestScenarioRunner(
            alarmCoordinator: alarmCoordinator,
            testRunStore: AlarmKitTestRunStore(),
            timeProvider: FixedTimeProvider(now: Date())
        )
        let settings = AlarmKitTestSettings.default

        let first = await runner.run(
            settings: settings,
            label: "Test",
            soundName: nil,
            snoozeDuration: nil
        )
        let second = await runner.run(
            settings: settings,
            label: "Test",
            soundName: nil,
            snoozeDuration: nil
        )

        #expect(first == true)
        #expect(second == true)
        #expect(Set(alarmScheduler.scheduledIds).count == 3)
        #expect(alarmScheduler.cancelCount >= 3)
    }

    @Test
    @MainActor
    func eventLogRecordsSequence() async {
        guard #available(iOS 26.0, *) else { return }
        DebugEventLog.shared.clear()
        let alarmScheduler = MockAlarmScheduler()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: AlarmRecordStore(),
            stateStore: AlarmStateStore()
        )
        let countdownManager = CountdownManager(
            store: CountdownSessionStore(),
            activityManager: MockLiveActivityManager()
        )
        let recordStore = AlarmRecordStore()
        let router = AlarmEventRouter(
            recordStore: recordStore,
            stateStore: AlarmStateStore(),
            countdownManager: countdownManager,
            enableCountdown: true
        )

        let record = AlarmRecord(
            id: UUID(),
            kind: .reminder,
            scheduledDate: Date(),
            fajrDateTime: Date().addingTimeInterval(60),
            isTest: true,
            testRunId: nil,
            label: "Test"
        )
        recordStore.upsert(record)
        await router.handleAlarmFired(record: record)
        await countdownManager.endCountdownIfNeeded(reason: "test")

        let events = DebugEventLog.shared.events(limit: 5).map { $0.type }
        #expect(events.contains(.firedFajrReminder))
        #expect(events.contains(.countdownStarted))
        #expect(events.contains(.countdownEnded))
    }

    @Test
    @MainActor
    func dismissReminderDoesNotCancelAdhan() async {
        guard #available(iOS 26.0, *) else { return }
        let alarmScheduler = MockAlarmScheduler()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: AlarmRecordStore(),
            stateStore: AlarmStateStore()
        )
        let recordStore = AlarmRecordStore()
        let router = AlarmEventRouter(
            recordStore: recordStore,
            stateStore: AlarmStateStore(),
            countdownManager: CountdownManager(
                store: CountdownSessionStore(),
                activityManager: MockLiveActivityManager()
            ),
            enableCountdown: false
        )

        let adhanId = UUID()
        _ = await alarmCoordinator.scheduleAlarm(
            id: adhanId,
            kind: .boundary,
            date: Date().addingTimeInterval(180),
            label: "Prod",
            fajrDateTime: Date().addingTimeInterval(180),
            soundName: nil,
            snoozeDuration: nil
        )

        let reminder = AlarmRecord(
            id: UUID(),
            kind: .reminder,
            scheduledDate: Date(),
            fajrDateTime: Date().addingTimeInterval(60),
            isTest: false,
            testRunId: nil,
            label: "Prod"
        )
        recordStore.upsert(reminder)

        await router.handleAlarmDismissed(id: reminder.id)
        #expect(!alarmScheduler.canceledIds.contains(adhanId))
    }

    @Test
    @MainActor
    func stopCountdownDoesNotCancelAnyAlarmIds() async {
        let alarmScheduler = MockAlarmScheduler()
        let alarmCoordinator = AlarmCoordinator(
            alarmScheduler: alarmScheduler,
            recordStore: AlarmRecordStore(),
            stateStore: AlarmStateStore()
        )
        let countdownManager = CountdownManager(
            store: CountdownSessionStore(),
            activityManager: MockLiveActivityManager()
        )

        await countdownManager.startCountdown(fajrDateTime: Date().addingTimeInterval(120))
        await countdownManager.stopCountdownByUser()

        #expect(alarmScheduler.canceledIds.isEmpty)
        _ = alarmCoordinator
    }

    @Test
    @MainActor
    func productionSchedulingIdsAreDeterministic() async {
        let alarmKitScheduler = MockAlarmKitScheduler()
        let routineScheduler = RoutineScheduler(
            notificationScheduler: NotificationScheduler(),
            alarmKitScheduler: alarmKitScheduler,
            alarmCoordinator: nil
        )

        let schedule = DaySchedule(
            date: Date(),
            fajrDate: Date().addingTimeInterval(3600),
            wakeDate: Date().addingTimeInterval(1800),
            reminderDate: Date().addingTimeInterval(2400),
            boundaryDate: Date().addingTimeInterval(3600),
            fajrSoundChoice: .systemDefault,
            locationDescription: "",
            offsetMinutes: 30,
            calculationMethodName: "",
            timeZone: .current
        )
        var settings = AppSettings.default
        settings.isEnabled = true
        settings.reminderEnabledGlobal = true
        settings.atFajrEnabledGlobal = true

        _ = await routineScheduler.scheduleAllEnabledEvents(
            schedules: [schedule],
            settings: settings,
            canUseAlarmKit: true
        )
        let firstRunIds = alarmKitScheduler.scheduledIds
        alarmKitScheduler.scheduledIds = []
        _ = await routineScheduler.scheduleAllEnabledEvents(
            schedules: [schedule],
            settings: settings,
            canUseAlarmKit: true
        )
        let secondRunIds = alarmKitScheduler.scheduledIds

        let expected = Set([
            SchedulingIdentifiers.alarmID(for: schedule, kind: .wake),
            SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder),
            SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary)
        ])
        #expect(Set(firstRunIds) == expected)
        #expect(Set(secondRunIds) == expected)
        #expect(firstRunIds.count == firstRunIds.uniqueCount)
    }
}

private struct FixedTimeProvider: TimeProviding {
    let now: Date
    func now() -> Date { now }
}

private final class MockAlarmScheduler: AlarmScheduling {
    private(set) var scheduledIds: [UUID] = []
    private(set) var canceledIds: [UUID] = []

    var cancelCount: Int { canceledIds.count }

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?,
        snoozeDuration: TimeInterval?
    ) async throws {
        scheduledIds.append(id)
    }

    func cancel(id: UUID) {
        canceledIds.append(id)
    }
}

private final class MockLiveActivityManager: LiveActivityManaging {
    private(set) var startCount = 0
    private(set) var endCount = 0

    func start(session: CountdownSession) async -> String? {
        startCount += 1
        return UUID().uuidString
    }

    func update(session: CountdownSession, activityId: String) async {}

    func end(activityId: String) async {
        endCount += 1
    }

    func cleanupOrphans(activeActivityId: String?) async -> Int { 0 }
}

private final class MockAlarmKitScheduler: AlarmKitScheduling {
    var scheduledIds: [UUID] = []

    func scheduleAlarm(
        for schedule: DaySchedule,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws {
        scheduledIds.append(SchedulingIdentifiers.alarmID(for: schedule, kind: kind))
    }

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws {
        scheduledIds.append(id)
    }

    func cancelAllUpcoming(days: Int) async {}

    func cancelTestAlarms() {}

    func cancel(schedule: DaySchedule, kind: ScheduleEventKind) {}
}

private extension Array where Element: Hashable {
    var uniqueCount: Int { Set(self).count }
}
