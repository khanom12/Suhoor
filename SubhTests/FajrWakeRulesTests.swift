import CoreLocation
import Foundation
import Testing
@testable import Subh

@Suite
struct FajrWakeRulesTests {
    private let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
    private let toronto = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
    private let vancouver = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)

    @Test
    func wakeAtFajrStartResolvesAsInFajr() {
        let day = makeDate(day: 10)
        let prayerWindow = makePrayerWindow(
            day: day,
            fajrStartHour: 5,
            fajrStartMinute: 0,
            fajrEndHour: 6,
            fajrEndMinute: 0
        )
        let wakeRule = MorningWakeRule(
            state: .inFajr,
            anchorType: .fajrStart,
            deltaMinutes: 0
        )
        let plan = makePlan(wakeRule: wakeRule)
        let anchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: day,
            wakeRule: wakeRule,
            timeZone: timeZone
        )

        let resolution = MorningScheduleResolver.resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: anchor,
            selectedPlan: plan,
            timeZone: timeZone
        )

        #expect(resolution.finalWakeTime == prayerWindow.fajrStart)
        #expect(resolution.resolvedWakeState == .inFajr)
    }

    @Test
    func wakeAtFajrEndResolvesAsPostFajr() {
        let day = makeDate(day: 10)
        let prayerWindow = makePrayerWindow(
            day: day,
            fajrStartHour: 5,
            fajrStartMinute: 0,
            fajrEndHour: 6,
            fajrEndMinute: 0
        )
        let wakeRule = MorningWakeRule(
            state: .postFajr,
            anchorType: .fajrEnd,
            deltaMinutes: 0
        )
        let plan = makePlan(wakeRule: wakeRule, kind: .explicitDateOverride)
        let anchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: day,
            wakeRule: wakeRule,
            timeZone: timeZone
        )

        let resolution = MorningScheduleResolver.resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: anchor,
            selectedPlan: plan,
            timeZone: timeZone
        )

        #expect(resolution.finalWakeTime == prayerWindow.fajrEnd)
        #expect(resolution.resolvedWakeState == .postFajr)
    }

    @Test
    func startAnchoredInFajrValidationEnforcesReserveBeforeEnd() {
        var settings = AppSettings.default
        settings.reserveBeforeEndMinutes = 15

        let defaultConfig = makeDefaultConfig(
            wakeState: .inFajr,
            anchorType: .fajrStart,
            deltaMinutes: 180
        )

        let result = DefaultWakeRuleValidator.validate(
            startDate: makeDate(day: 10),
            timeZone: timeZone,
            coordinate: toronto,
            settings: settings,
            defaultConfig: defaultConfig
        )

        #expect(result.isValid == false)
        #expect(result.firstInvalidDateKey != nil)
        #expect(result.message == "Start-anchored in-Fajr wakes must preserve the reserve before Fajr ends.")
    }

    @Test
    func endAnchoredInFajrValidationStaysWithinRawFajrWindow() {
        let defaultConfig = makeDefaultConfig(
            wakeState: .inFajr,
            anchorType: .fajrEnd,
            deltaMinutes: 180
        )

        let result = DefaultWakeRuleValidator.validate(
            startDate: makeDate(day: 10),
            timeZone: timeZone,
            coordinate: toronto,
            settings: .default,
            defaultConfig: defaultConfig
        )

        #expect(result.isValid == false)
        #expect(result.firstInvalidDateKey != nil)
        #expect(result.message == "End-anchored in-Fajr wakes must stay inside the raw Fajr window.")
    }

    @Test
    func defaultValidationUsesRolling365DayHorizonByDefault() {
        let defaultConfig = makeDefaultConfig(
            wakeState: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30
        )

        let implicit = DefaultWakeRuleValidator.validate(
            startDate: makeDate(day: 10),
            timeZone: timeZone,
            coordinate: toronto,
            settings: .default,
            defaultConfig: defaultConfig
        )
        let explicit = DefaultWakeRuleValidator.validate(
            startDate: makeDate(day: 10),
            timeZone: timeZone,
            coordinate: toronto,
            settings: .default,
            defaultConfig: defaultConfig,
            horizonDays: 365
        )

        #expect(implicit == explicit)
    }

    @Test
    func latestWakeCapCanPullInFajrDefaultIntoPreFajr() {
        let day = makeDate(day: 10)
        let prayerWindow = makePrayerWindow(
            day: day,
            fajrStartHour: 5,
            fajrStartMinute: 0,
            fajrEndHour: 6,
            fajrEndMinute: 0
        )
        let wakeRule = MorningWakeRule(
            state: .inFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30,
            latestWakeCapMinutesFromMidnight: 4 * 60 + 50
        )
        let plan = makePlan(wakeRule: wakeRule)
        let anchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: day,
            wakeRule: wakeRule,
            timeZone: timeZone
        )

        let resolution = MorningScheduleResolver.resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: anchor,
            selectedPlan: plan,
            timeZone: timeZone
        )

        #expect(resolution.candidateWakeTime == makeDate(day: 10, hour: 5, minute: 30))
        #expect(resolution.finalWakeTime == makeDate(day: 10, hour: 4, minute: 50))
        #expect(resolution.latestWakeCapApplied == true)
        #expect(resolution.latestWakeCapShiftedState == true)
        #expect(resolution.resolvedWakeState == .preFajr)
    }

    @Test
    func fixedWakeIgnoresLatestWakeCap() {
        let day = makeDate(day: 10)
        let prayerWindow = makePrayerWindow(
            day: day,
            fajrStartHour: 5,
            fajrStartMinute: 0,
            fajrEndHour: 6,
            fajrEndMinute: 0
        )
        let wakeRule = MorningWakeRule(
            state: .fixedWake,
            anchorType: .clockTime,
            deltaMinutes: 0,
            fixedWakeTimeMinutesFromMidnight: 7 * 60,
            latestWakeCapMinutesFromMidnight: 6 * 60
        )
        let plan = makePlan(wakeRule: wakeRule, kind: .explicitDateOverride)
        let anchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: day,
            wakeRule: wakeRule,
            timeZone: timeZone
        )

        let resolution = MorningScheduleResolver.resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: anchor,
            selectedPlan: plan,
            timeZone: timeZone
        )

        #expect(resolution.finalWakeTime == makeDate(day: 10, hour: 7, minute: 0))
        #expect(resolution.latestWakeCapApplied == false)
        #expect(resolution.resolvedWakeState == .postFajr)
    }

    @Test
    func preFajrResolutionCreatesTakeoverCheckpointAtFajrStart() {
        let defaultConfig = makeDefaultConfig(
            wakeState: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30
        )
        guard let snapshot = resolveSnapshot(
            date: makeDate(day: 12),
            settings: .default,
            defaultConfig: defaultConfig,
            tagResult: .empty
        ) else {
            Issue.record("Expected resolver snapshot.")
            return
        }

        let wakeEvent = snapshot.materializedEvents.first { $0.type == .wakeAlarm }
        let checkpoint = snapshot.materializedEvents.first { $0.type == .fajrBoundaryNotice }

        #expect(wakeEvent != nil)
        #expect(checkpoint != nil)
        #expect(wakeEvent?.wakeSessionRole == .primaryWake)
        #expect(wakeEvent?.soundRole == .preFajrWake)
        #expect(checkpoint?.wakeSessionRole == .checkpoint)
        #expect(checkpoint?.wakeSessionID == wakeEvent?.wakeSessionID)
        #expect(checkpoint?.soundRole == .fajrStart)
        #expect(checkpoint?.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue)
        #expect(checkpoint?.fireDate == snapshot.prayerWindow.fajrStart)
    }

    @Test
    @MainActor
    func alarmKitTakeoverCheckpointDoesNotScheduleCompetingBoundaryAlarm() async {
        let defaultConfig = makeDefaultConfig(
            wakeState: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30
        )
        guard let snapshot = resolveSnapshot(
            date: makeDate(day: 12),
            settings: .default,
            defaultConfig: defaultConfig,
            tagResult: .empty
        ) else {
            Issue.record("Expected resolver snapshot.")
            return
        }
        let effectiveConfig = makeEffectiveConfig(
            date: makeDate(day: 12),
            defaultConfig: defaultConfig,
            settings: .default
        )
        let schedule = LegacyResolvedDayAdapter.makeSchedule(
            snapshot: snapshot,
            effectiveConfig: effectiveConfig,
            settings: .default,
            locationDescription: "Toronto",
            timeZone: timeZone
        )
        guard let checkpoint = snapshot.materializedEvents.first(where: { $0.type == .fajrBoundaryNotice }) else {
            Issue.record("Expected Fajr-start checkpoint.")
            return
        }

        let recordingScheduler = RecordingAlarmScheduler()
        let recordStore = AlarmRecordStore()
        recordStore.clearAll()
        let routineScheduler = RoutineScheduler(
            notificationScheduler: NotificationScheduler(),
            alarmKitScheduler: nil,
            alarmCoordinator: AlarmCoordinator(
                alarmScheduler: recordingScheduler,
                recordStore: recordStore,
                stateStore: AlarmStateStore()
            )
        )

        let scheduled = await routineScheduler.scheduleEvent(
            identifier: SchedulingIdentifiers.dailyIdentifier(for: checkpoint, deliveryKind: .boundary),
            event: checkpoint,
            deliveryKind: .boundary,
            schedule: schedule,
            settings: .default,
            canUseAlarmKit: true,
            now: checkpoint.fireDate.addingTimeInterval(-60)
        )

        #expect(scheduled == true)
        #expect(recordStore.records().isEmpty)
        #expect(recordingScheduler.scheduled.isEmpty)
    }

    @Test
    func snoozedAcrossFajrStillTriggersTakeover() {
        let record = AlarmRecord(
            id: UUID(),
            kind: .boundary,
            scheduledDate: makeDate(day: 12, hour: 5, minute: 0),
            wakeSessionID: "wake-session",
            soundRole: .fajrStart,
            wakeSessionRole: .checkpoint,
            fajrStartBehavior: .takeoverIfUnresolvedOtherwiseCue,
            label: "Fajr start"
        )

        #expect(WakeSessionTakeoverResolver.shouldTakeOverAtFajrStart(record: record, alarmState: .paused))
        #expect(WakeSessionTakeoverResolver.shouldTakeOverAtFajrStart(record: record, alarmState: .countdown))
        #expect(WakeSessionTakeoverResolver.shouldTakeOverAtFajrStart(record: record, alarmState: .dismissed) == false)
    }

    @Test
    func takeoverUsesConfiguredFajrStartSoundMapping() {
        var settings = AppSettings.default
        settings.fajrStartSoundSelectionGlobal = .systemDefault

        let defaultConfig = makeDefaultConfig(
            wakeState: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30
        )
        guard let snapshot = resolveSnapshot(
            date: makeDate(day: 12),
            settings: settings,
            defaultConfig: defaultConfig,
            tagResult: .empty
        ) else {
            Issue.record("Expected resolver snapshot.")
            return
        }
        guard let checkpoint = snapshot.materializedEvents.first(where: { $0.type == .fajrBoundaryNotice }) else {
            Issue.record("Expected Fajr-start checkpoint.")
            return
        }

        #expect(checkpoint.soundRole == .fajrStart)
        #expect(settings.soundChoice(for: checkpoint.soundRole) == .systemDefault)
    }

    @Test
    func prayerCalculationAndLocationChangesPreserveWakeIntent() {
        var mwlSettings = AppSettings.default
        mwlSettings.calculationMethod = .muslimWorldLeague

        var northAmericaSettings = mwlSettings
        northAmericaSettings.calculationMethod = .northAmerica

        let defaultConfig = makeDefaultConfig(
            wakeState: .inFajr,
            anchorType: .fajrStart,
            deltaMinutes: 20
        )
        let date = makeDate(day: 18)

        guard let torontoMWL = resolveSnapshot(
            date: date,
            settings: mwlSettings,
            defaultConfig: defaultConfig,
            coordinate: toronto
        ), let torontoNorthAmerica = resolveSnapshot(
            date: date,
            settings: northAmericaSettings,
            defaultConfig: defaultConfig,
            coordinate: toronto
        ), let vancouverMWL = resolveSnapshot(
            date: date,
            settings: mwlSettings,
            defaultConfig: defaultConfig,
            coordinate: vancouver
        ) else {
            Issue.record("Expected resolver snapshots for calculation and location changes.")
            return
        }

        let snapshots = [torontoMWL, torontoNorthAmerica, vancouverMWL]
        #expect(snapshots.allSatisfy { $0.selectedPlan.wakeRule.state == .inFajr })
        #expect(snapshots.allSatisfy { $0.selectedPlan.wakeRule.anchorType == .fajrStart })
        #expect(torontoMWL.prayerWindow.fajrStart != torontoNorthAmerica.prayerWindow.fajrStart)
        #expect(torontoMWL.prayerWindow.fajrStart != vancouverMWL.prayerWindow.fajrStart)
    }

    @Test
    func fastingDayCanKeepSameWakeTimeAsNonFastingDay() {
        let defaultConfig = makeDefaultConfig(
            wakeState: .preFajr,
            anchorType: .fajrStart,
            deltaMinutes: 30
        )
        let date = makeDate(day: 20)
        let fastingTag = TagComputationResult(
            computedPrimaryIntent: .voluntary,
            computedSecondaryTags: [],
            secondaryDetails: [:],
            suppressedSecondaryTags: []
        )

        guard let ordinary = resolveSnapshot(
            date: date,
            settings: .default,
            defaultConfig: defaultConfig,
            tagResult: .empty
        ), let fasting = resolveSnapshot(
            date: date,
            settings: .default,
            defaultConfig: defaultConfig,
            tagResult: fastingTag
        ) else {
            Issue.record("Expected resolver snapshots.")
            return
        }

        #expect(ordinary.decisionLog.resolvedWakeTime == fasting.decisionLog.resolvedWakeTime)
        #expect(ordinary.resolvedDayContext.primaryContext == .standard)
        #expect(fasting.resolvedDayContext.primaryContext != .standard)
    }

    private func resolveSnapshot(
        date: Date,
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig,
        tagResult: TagComputationResult,
        coordinate: CLLocationCoordinate2D? = nil,
        effectiveConfig: EffectiveDailyConfig? = nil
    ) -> ResolvedDaySnapshot? {
        let resolvedConfig = effectiveConfig ?? makeEffectiveConfig(
            date: date,
            defaultConfig: defaultConfig,
            settings: settings
        )
        let stateSnapshot = MorningStateSnapshot(
            settings: settings,
            defaultConfig: defaultConfig,
            morningPlanState: MorningPlanState(
                schemaVersion: 2,
                activationMode: .dailyActive,
                defaultDailyPlan: makePlan(wakeRule: defaultConfig.defaultWakeRule),
                lastMigrationAt: nil
            ),
            dateAssignments: [],
            completionRecords: [],
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: "",
                baselineOwed: 0,
                completed: 0,
                remaining: 0
            ),
            coordinate: coordinate ?? toronto,
            timeZone: timeZone,
            locationDescription: "Test",
            fastTagSelections: [:],
            overridesByDateKey: [:]
        )
        let input = MorningScheduleResolutionInput(
            date: date,
            dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
            provenances: [defaultDailyProvenance],
            effectiveConfig: resolvedConfig,
            tagResult: tagResult,
            stateSnapshot: stateSnapshot
        )
        return MorningScheduleResolver.resolve(input: input)
    }

    private func makePrayerWindow(
        day: Date,
        fajrStartHour: Int,
        fajrStartMinute: Int,
        fajrEndHour: Int,
        fajrEndMinute: Int,
        maghribHour: Int = 19,
        maghribMinute: Int = 0
    ) -> DailyPrayerWindow {
        DailyPrayerWindow(
            date: day,
            fajrStart: date(on: day, hour: fajrStartHour, minute: fajrStartMinute),
            fajrEnd: date(on: day, hour: fajrEndHour, minute: fajrEndMinute),
            maghrib: date(on: day, hour: maghribHour, minute: maghribMinute)
        )
    }

    private func makePlan(
        wakeRule: MorningWakeRule,
        kind: MorningPlanKind = .defaultDaily
    ) -> MorningPlan {
        MorningPlan(
            id: "\(kind.rawValue)-plan",
            title: "Plan",
            kind: kind,
            wakeRule: wakeRule,
            wakeAnchorType: wakeRule.compatibilityWakeAnchorType,
            wakeDelta: wakeRule.compatibilityWakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: wakeRule.fixedWakeTimeMinutesFromMidnight,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: false
        )
    }

    private func makeDefaultConfig(
        wakeState: DefaultWakeState,
        anchorType: WakeAnchorType,
        deltaMinutes: Int,
        latestWakeCapMinutesFromMidnight: Int? = nil
    ) -> DefaultAlarmConfig {
        var config = DefaultAlarmConfig.default
        config.defaultWakeState = wakeState
        config.defaultWakeAnchorType = anchorType
        config.defaultWakeDeltaMinutes = deltaMinutes
        config.defaultLatestWakeCapMinutesFromMidnight = latestWakeCapMinutesFromMidnight
        return config
    }

    private func makeEffectiveConfig(
        date: Date,
        defaultConfig: DefaultAlarmConfig,
        resolvedWakeRule: MorningWakeRule? = nil,
        hasOverrides: Bool = false,
        settings: AppSettings
    ) -> EffectiveDailyConfig {
        let defaultWakeRule = defaultConfig.defaultWakeRule
        return EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: defaultConfig.suhoorEnabledDefault,
            reminderEnabled: defaultConfig.reminderEnabledDefault,
            fajrEnabled: defaultConfig.fajrEnabledDefault,
            iftarEnabled: defaultConfig.iftarEnabledDefault,
            defaultWakeRule: defaultWakeRule,
            resolvedWakeRule: resolvedWakeRule ?? defaultWakeRule,
            wakeRuleWasOverridden: hasOverrides,
            tahajjudRefinement: false,
            suhoorTimeMode: defaultConfig.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: defaultConfig.defaultSuhoorOffsetMinutes,
            reminderTimeMode: defaultConfig.defaultReminderTimeMode,
            reminderMinutesBeforeFajr: defaultConfig.defaultReminderMinutesBeforeFajr,
            reminderFixedTimeMinutes: defaultConfig.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: settings.fajrStartSoundSelectionGlobal,
            iftarDelivery: defaultConfig.defaultIftarDelivery.normalized(),
            iftarSoundChoice: defaultConfig.defaultIftarSoundChoice,
            hasOverrides: hasOverrides
        )
    }

    private var defaultDailyProvenance: ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: UUID(),
            groupID: nil,
            label: "Daily morning plan",
            stopSeriesLabel: nil,
            isExplicitOneOff: false,
            sourceOrigin: .defaultDailyPlan
        )
    }

    private func makeDate(day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = 2026
        components.month = 3
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? .distantPast
    }

    private func date(on day: Date, hour: Int, minute: Int) -> Date {
        var calendar = self.calendar
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start) ?? start
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

private final class RecordingAlarmScheduler: AlarmScheduling {
    struct Call: Equatable {
        let id: UUID
        let kind: ScheduleEventKind
        let date: Date
        let label: String
        let soundName: String?
        let snoozeDuration: TimeInterval?
    }

    private(set) var scheduled: [Call] = []

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?,
        snoozeDuration: TimeInterval?
    ) async throws {
        scheduled.append(
            Call(
                id: id,
                kind: kind,
                date: date,
                label: label,
                soundName: soundName,
                snoozeDuration: snoozeDuration
            )
        )
    }

    func cancel(id: UUID) {}
}
