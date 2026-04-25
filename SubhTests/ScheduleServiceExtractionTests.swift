import Foundation
import CoreLocation
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

        try? await Task.sleep(nanoseconds: 350_000_000)

        #expect(received == [PendingScheduleRefresh(reason: .manual, force: true)])
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
    func homeSurfaceAssemblerUsesScheduleFallbackWhenTodayIsNotCached() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 10, hour: 6, minute: 0, timeZone: timeZone)
        let schedule = Self.makeSchedule(for: now, timeZone: timeZone)

        let input = HomeSurfaceAssembler().makeInput(
            now: now,
            dismissedWarnings: [],
            activeWindowSnapshot: .empty,
            nextWakeEventSummary: nil,
            settings: .default,
            permissionSnapshot: .empty,
            adjustedHijriCalendar: AdjustedHijriCalendar.shared,
            scheduleLookup: { _ in schedule },
            timeZone: timeZone
        )

        #expect(input.currentDay == nil)
        #expect(input.todaySchedule == schedule)
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
            scheduledHorizonDays: 1
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
            reminderDate: wake.addingTimeInterval(-15 * 60),
            boundaryDate: fajr,
            iftarDate: maghrib,
            locationDescription: "Test",
            offsetMinutes: 45,
            calculationMethodName: "Test",
            timeZone: timeZone
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
