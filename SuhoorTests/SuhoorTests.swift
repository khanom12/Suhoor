import Foundation
import CoreLocation
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
    func fajrLogStorePersistsAndClearsStatuses() {
        let suiteName = "SuhoorTests.FajrLogStore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FajrLogStore(defaults: defaults)
        store.setStatus(.completed, for: "2026-03-08", now: .distantPast)
        #expect(store.status(for: "2026-03-08") == .completed)

#if DEBUG
        store.flushPersistenceForTesting()
#endif

        let reloaded = FajrLogStore(defaults: defaults)
        #expect(reloaded.status(for: "2026-03-08") == .completed)

        reloaded.clear(for: "2026-03-08")
        #expect(reloaded.status(for: "2026-03-08") == .unknown)
    }

    @Test
    func qadaProgressOnlyDecrementsForCompletedQadaFasts() {
        let state = QadaBacklogState(trackingStartDateKey: "2026-03-01", baselineOwed: 4)
        let logEntries: [String: FastLogEntry] = [
            "2026-03-02": FastLogEntry(
                dateKey: "2026-03-02",
                status: .completed,
                updatedAt: .distantPast,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
            ),
            "2026-03-03": FastLogEntry(
                dateKey: "2026-03-03",
                status: .missed,
                updatedAt: .distantPast,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
            ),
            "2026-03-04": FastLogEntry(
                dateKey: "2026-03-04",
                status: .completed,
                updatedAt: .distantPast,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .voluntary, secondaryTags: [])
            )
        ]

        let snapshot = QadaProgressEngine.snapshot(state: state, logEntries: logEntries)

        #expect(snapshot.completed == 1)
        #expect(snapshot.remaining == 3)
        #expect(snapshot.baselineOwed == 4)
    }

    @Test
    func iftarDeliveryNormalizesAudibleChoice() {
        let selection = IftarDeliverySelection(notification: true, alarm: true, adhan: true).normalized()
        #expect(selection.notification == true)
        #expect(selection.alarm == false)
        #expect(selection.adhan == true)
        #expect(selection.audibleMode == .adhan)
    }

    @Test
    func maghribAdjustmentShiftsCalculatedDate() {
        let calculator = PrayerTimeCalculator()
        let date = Date(timeIntervalSince1970: 1_772_409_600) // March 3, 2026 UTC noon-ish seed
        let location = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let baseline = calculator.maghribDate(for: date, location: location, timeZone: timeZone, adjustmentMinutes: 0)
        let adjusted = calculator.maghribDate(for: date, location: location, timeZone: timeZone, adjustmentMinutes: 5)

        #expect(baseline != nil)
        #expect(adjusted != nil)
        if let baseline, let adjusted {
            #expect(Int(adjusted.timeIntervalSince(baseline)) == 300)
        }
    }

    @Test
    func ramadanStartAndEidAreResolvableForKnownHijriYear() {
        let suiteName = "SuhoorTests.RamadanDates"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let service = HijriCalendarService(adjustmentStore: adjustmentStore)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let hijriYear = 1447

        let start = service.dateForRamadanStart(hijriYear: hijriYear, timeZone: timeZone)
        let eid = service.dateForEidAlFitr(hijriYear: hijriYear, timeZone: timeZone)
        #expect(start != nil)
        #expect(eid != nil)

        if let start, let eid {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let deltaDays = calendar.dateComponents([.day], from: start, to: eid).day ?? 0
            #expect(deltaDays == 29 || deltaDays == 30)
        }
    }

    @Test
    func hijriAdjustmentsShiftRamadanAndEidDates() {
        let suiteName = "SuhoorTests.RamadanAdjustments"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let service = HijriCalendarService(adjustmentStore: adjustmentStore)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let hijriYear = 1447

        let baselineStart = service.dateForRamadanStart(hijriYear: hijriYear, timeZone: timeZone)
        let baselineEid = service.dateForEidAlFitr(hijriYear: hijriYear, timeZone: timeZone)
        #expect(baselineStart != nil)
        #expect(baselineEid != nil)

        adjustmentStore.setAdjustment(for: HijriYearMonth(hijriYear: hijriYear, month: .ramadan), offsetDays: 1)
        adjustmentStore.setAdjustment(for: HijriYearMonth(hijriYear: hijriYear, month: .shawwal), offsetDays: -1)

        let adjustedStart = service.dateForRamadanStart(hijriYear: hijriYear, timeZone: timeZone)
        let adjustedEid = service.dateForEidAlFitr(hijriYear: hijriYear, timeZone: timeZone)
        #expect(adjustedStart != nil)
        #expect(adjustedEid != nil)

        if let baselineStart, let baselineEid, let adjustedStart, let adjustedEid {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let startShift = calendar.dateComponents([.day], from: baselineStart, to: adjustedStart).day ?? 0
            let eidShift = calendar.dateComponents([.day], from: baselineEid, to: adjustedEid).day ?? 0
            #expect(startShift == 1)
            #expect(eidShift == -1)
        }
    }

    @Test
    func ruleEngineUsesOffsetOverridesAndSkipDay() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Date(timeIntervalSince1970: 1_772_409_600) // March 3, 2026 seed
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)

        var overrideEnabled = DailyAlarmOverride(date: date, timeZone: timeZone)
        overrideEnabled.suhoorOffsetOverrideMinutes = 42

        let engineWithOverride = RuleEngine(
            settings: .default,
            defaultConfig: .default,
            overridesByDay: [key: overrideEnabled],
            timeZone: timeZone
        )
        #expect(engineWithOverride.effectiveWakeOffsetMinutes(for: date) == 42)
        #expect(engineWithOverride.ruleSummary(for: date).disabledForDay == false)

        var overrideSkipped = DailyAlarmOverride(date: date, timeZone: timeZone)
        overrideSkipped.skipDay = true
        overrideSkipped.suhoorOffsetOverrideMinutes = 15

        let engineWithSkip = RuleEngine(
            settings: .default,
            defaultConfig: .default,
            overridesByDay: [key: overrideSkipped],
            timeZone: timeZone
        )
        #expect(engineWithSkip.ruleSummary(for: date).disabledForDay == true)
        #expect(engineWithSkip.effectiveWakeOffsetMinutes(for: date) == DefaultAlarmConfig.default.defaultSuhoorOffsetMinutes)
    }

    @Test
    func locationPermissionStateTracksAuthorizationAndFix() {
        let service = LocationService()
        service.authorizationStatus = .authorizedWhenInUse
        service.lastLocation = nil
        #expect(service.permissionState == .authorizedNoFixYet)

        service.lastLocation = CLLocation(latitude: 43.6532, longitude: -79.3832)
        #expect(service.permissionState == .authorizedWithFix)

        service.authorizationStatus = .denied
        #expect(service.permissionState == .denied)
    }

    @Test
    @MainActor
    func fixedLocationSchedulesEvenWhenDenied() async {
        let suiteName = "SuhoorTests.FixedLocation"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()
        locationService.authorizationStatus = .denied

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)
        #expect(!scheduleManager.activeWindowSnapshot.visibleDays.isEmpty)
    }

    @Test
    @MainActor
    func onboardingPermissionsStayInExpectedOrder() async {
        let suiteName = "SuhoorTests.PermissionOrder"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()
        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let permissions = await scheduleManager.requiredOnboardingPermissions()
        #expect(permissions == [.location, .alarmKit, .notifications])
    }

    @Test
    @MainActor
    func locationPermissionPresentationShowsWaitingWhenAuthorizedWithoutFix() async {
        let suiteName = "SuhoorTests.LocationPresentation"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()
        locationService.authorizationStatus = .authorizedWhenInUse
        locationService.lastLocation = nil

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        let presentation = await scheduleManager.permissionPresentation(for: .location)
        #expect(presentation.state == .needsFollowUp)
        #expect(presentation.actionTitle == Strings.LocationAccess.tryAgain)
    }

    @Test
    func settingsStoreDebouncesPersistenceAndSavesLatestSnapshot() async throws {
        let suiteName = "SuhoorTests.SettingsDebounce"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SuhoorSettingsStore(defaults: defaults)
        store.update { draft in
            draft.label = "First"
        }
        store.update { draft in
            draft.label = "Final"
        }

        #expect(defaults.data(forKey: "Suhoor.AppSettings") == nil)

        try await Task.sleep(nanoseconds: 450_000_000)

        let data = try #require(defaults.data(forKey: "Suhoor.AppSettings"))
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded.label == "Final")
    }

    @Test
    @MainActor
    func refreshSchedulesPublishesPermissionSnapshot() async {
        let suiteName = "SuhoorTests.PermissionSnapshot"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        #expect(!scheduleManager.permissionSnapshot.summaryText.isEmpty)
        #expect(scheduleManager.permissionSnapshot.presentations[.location] != nil)
        #expect(scheduleManager.permissionSnapshot.presentations[.alarmKit] != nil)
        #expect(scheduleManager.permissionSnapshot.presentations[.notifications] != nil)
    }

    @Test
    func settingsStoreMigrationTurnsLegacyAlarmFlagsOn() throws {
        let suiteName = "SuhoorTests.SettingsMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var legacy = AppSettings.default
        legacy.isEnabled = false
        legacy.reminderEnabledGlobal = false
        legacy.atFajrEnabledGlobal = false
        defaults.set(try JSONEncoder().encode(legacy), forKey: "Suhoor.AppSettings")

        let store = SuhoorSettingsStore(defaults: defaults)

        #expect(store.settings.isEnabled == true)
        #expect(store.settings.reminderEnabledGlobal == true)
        #expect(store.settings.atFajrEnabledGlobal == true)
    }

    @Test
    func bootstrapStateUsesWelcomeForFreshInstall() {
        let state = ScheduleManager.resolveBootstrapState(
            settings: .default,
            permissionStates: [
                .location: .authorized,
                .alarmKit: .authorized,
                .notifications: .authorized
            ],
            hasVisibleDays: true
        )

        #expect(state == .welcome)
    }

    @Test
    func bootstrapStateUsesPermissionsForConfiguredUserWithRevokedPermission() {
        var settings = AppSettings.default
        settings.isConfigured = true

        let state = ScheduleManager.resolveBootstrapState(
            settings: settings,
            permissionStates: [
                .location: .denied,
                .alarmKit: .authorized,
                .notifications: .authorized
            ],
            hasVisibleDays: true
        )

        #expect(state == .permissions)
    }

    @Test
    func bootstrapStateStaysGatedUntilLocationHasFix() {
        var settings = AppSettings.default
        settings.isConfigured = true

        let state = ScheduleManager.resolveBootstrapState(
            settings: settings,
            permissionStates: [
                .location: .needsFollowUp,
                .alarmKit: .authorized,
                .notifications: .authorized
            ],
            hasVisibleDays: true
        )

        #expect(state == .permissions)
    }

    @Test
    func bootstrapStateUsesHomeWhenConfiguredAndReady() {
        var settings = AppSettings.default
        settings.isConfigured = true

        let state = ScheduleManager.resolveBootstrapState(
            settings: settings,
            permissionStates: [
                .location: .authorized,
                .alarmKit: .authorized,
                .notifications: .authorized
            ],
            hasVisibleDays: true
        )

        #expect(state == .home)
    }

    @Test
    func appLaunchDoesNotReuseEmptyScheduleWindowEvenIfScheduledToday() {
        let now = makeDate(year: 2026, month: 3, day: 2)

        let shouldReuse = ScheduleManager.shouldReuseScheduleWindow(
            reason: .appLaunch,
            lastScheduledDate: now,
            snapshot: .empty,
            now: now,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        #expect(shouldReuse == false)
    }

    @Test
    func appLaunchReusesNonEmptyScheduleWindowGeneratedToday() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = makeDate(year: 2026, month: 3, day: 2)
        let day = ActiveAlarmDay(
            date: now,
            dateKey: DateHelpers.dayIdentifier(for: now, timeZone: timeZone),
            schedule: sampleDaySchedule(date: now),
            effectiveConfig: sampleEffectiveDailyConfig(date: now),
            provenances: [],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: nil,
            sourceSummaryText: ""
        )
        let snapshot = ActiveAlarmWindowSnapshot(
            generatedAt: now,
            visibleDays: [day],
            scheduledDays: [day],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )

        let shouldReuse = ScheduleManager.shouldReuseScheduleWindow(
            reason: .appLaunch,
            lastScheduledDate: now,
            snapshot: snapshot,
            now: now,
            timeZone: timeZone
        )

        #expect(shouldReuse == true)
    }

    @Test
    func alarmRowDateLabelUsesRelativeLabelsForTodayAndTomorrow() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let currentDate = makeDate(year: 2026, month: 2, day: 18)
        let todayLabel = AlarmRowPresentation.dateLabel(
            for: currentDate,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let tomorrow = makeDate(year: 2026, month: 2, day: 19)
        let tomorrowLabel = AlarmRowPresentation.dateLabel(
            for: tomorrow,
            currentDate: currentDate,
            timeZone: timeZone
        )

        #expect(todayLabel == "Today")
        #expect(tomorrowLabel == "Tomorrow")
    }

    @Test
    func alarmRowDateLabelUsesRamadanWeekdayAndHijriDayOnly() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ramadanStart = HijriCalendarService().dateForRamadanStart(hijriYear: 1447, timeZone: timeZone)

        #expect(ramadanStart != nil)
        guard let ramadanStart else { return }

        let label = AlarmRowPresentation.dateLabel(
            for: ramadanStart,
            currentDate: makeDate(year: 2026, month: 1, day: 1),
            timeZone: timeZone
        )

        #expect(label.contains("Ramadan"))
        #expect(label.contains(","))
        #expect(label.contains("1447") == false)
        #expect(label.contains("Jan") == false)
        #expect(label.contains("Feb") == false)
    }

    @Test
    func alarmRowDateLabelUsesGregorianOnlyOutsideRamadan() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ashura = HijriCalendarService().dateForAshura(hijriYear: 1447, timeZone: timeZone)

        #expect(ashura != nil)
        guard let ashura else { return }

        let label = AlarmRowPresentation.dateLabel(
            for: ashura,
            currentDate: makeDate(year: 2026, month: 1, day: 1),
            timeZone: timeZone
        )

        #expect(label.contains("Ramadan") == false)
        #expect(label.contains("Muharram") == false)
        #expect(label.contains(","))
        #expect(label.range(of: #"[A-Z][a-z]{2}, [A-Z][a-z]{2} \d{1,2}"#, options: .regularExpression) != nil)
    }

    @Test
    func nextAlarmSelectionSkipsPastEnabledEntryAndChoosesUpcomingOne() {
        let calendar = Calendar(identifier: .gregorian)
        let now = makeDate(year: 2026, month: 3, day: 2).addingTimeInterval(12 * 60 * 60)
        let pastDate = calendar.date(byAdding: .hour, value: -2, to: now) ?? now
        let upcomingDate = calendar.date(byAdding: .hour, value: 10, to: now) ?? now
        let pastEntry = AlarmRowEntry(
            activeDay: ActiveAlarmDay(
                date: makeDate(year: 2026, month: 3, day: 2),
                dateKey: DateHelpers.dayIdentifier(for: makeDate(year: 2026, month: 3, day: 2), timeZone: .current),
                schedule: sampleDaySchedule(date: makeDate(year: 2026, month: 3, day: 2), wakeDate: pastDate),
                effectiveConfig: sampleEffectiveDailyConfig(date: makeDate(year: 2026, month: 3, day: 2)),
                provenances: [],
                isImplicitRamadan: false,
                isExplicitOneOff: false,
                tagResult: .empty,
                primaryDisplay: PrimaryDisplay(time: pastDate, kind: .suhoor),
                sourceSummaryText: ""
            )
        )
        let upcomingEntry = AlarmRowEntry(
            activeDay: ActiveAlarmDay(
                date: makeDate(year: 2026, month: 3, day: 3),
                dateKey: DateHelpers.dayIdentifier(for: makeDate(year: 2026, month: 3, day: 3), timeZone: .current),
                schedule: sampleDaySchedule(date: makeDate(year: 2026, month: 3, day: 3), wakeDate: upcomingDate),
                effectiveConfig: sampleEffectiveDailyConfig(date: makeDate(year: 2026, month: 3, day: 3)),
                provenances: [],
                isImplicitRamadan: false,
                isExplicitOneOff: false,
                tagResult: .empty,
                primaryDisplay: PrimaryDisplay(time: upcomingDate, kind: .suhoor),
                sourceSummaryText: ""
            )
        )

        let selected = AlarmListSelection.nextAlarmEntry(from: [pastEntry, upcomingEntry], now: now)

        #expect(selected?.id == upcomingEntry.id)
    }

    @Test
    func nextAlarmEntriesKeepDisabledPinnedRowsAndAppendNextEnabledEntry() {
        let now = makeDate(year: 2026, month: 3, day: 2).addingTimeInterval(8 * 60 * 60)
        let firstEntry = sampleAlarmRowEntry(
            date: makeDate(year: 2026, month: 3, day: 2),
            wakeDate: now.addingTimeInterval(60 * 60),
            isEnabled: false
        )
        let secondEntry = sampleAlarmRowEntry(
            date: makeDate(year: 2026, month: 3, day: 3),
            wakeDate: now.addingTimeInterval(24 * 60 * 60),
            isEnabled: true
        )
        let thirdEntry = sampleAlarmRowEntry(
            date: makeDate(year: 2026, month: 3, day: 4),
            wakeDate: now.addingTimeInterval(48 * 60 * 60),
            isEnabled: true
        )

        let pinnedEntries = AlarmListSelection.nextAlarmEntries(
            from: [firstEntry, secondEntry, thirdEntry],
            pinnedEntryIDs: [firstEntry.id],
            now: now
        )

        #expect(pinnedEntries.map(\.id) == [firstEntry.id, secondEntry.id])
    }

    @Test
    func reEnablingPinnedRowTrimsPinnedRowsBelowIt() {
        let firstID = "2026-03-02"
        let secondID = "2026-03-03"
        let thirdID = "2026-03-04"

        let updatedPinnedIDs = AlarmListSelection.pinnedEntryIDs(
            afterToggling: secondID,
            isOn: true,
            currentPinnedEntryIDs: [firstID, secondID, thirdID]
        )

        #expect(updatedPinnedIDs == [firstID, secondID])
    }

    @Test
    func alarmRowSecondaryTagsAreLimitedToFive() {
        let result = TagComputationResult(
            computedPrimaryIntent: .voluntary,
            computedSecondaryTags: Set(FastSecondaryVirtueTag.allCases),
            secondaryDetails: [:],
            suppressedSecondaryTags: []
        )

        let secondaryTags = AlarmRowPresentation.secondaryTags(for: result)

        #expect(secondaryTags.count == 5)
        #expect(AlarmRowPresentation.showsTags(primaryIntent: .other, secondaryTags: []) == false)
    }

    @Test
    func scheduledSourceLabelsUsePlainLanguage() {
        #expect(ScheduledDateSourceOrigin.islamicQuickAdd(.nextArafah).label == "Added from Arafah")
        #expect(ScheduledDateSourceOrigin.islamicQuickAdd(.nextArafah).stopSeriesLabel == "Remove Arafah schedule")
        #expect(ScheduledDateSourceOrigin.recurringIslamic(.mondayThursday).label == "Generated by the Monday & Thursday recurring schedule")
        #expect(ScheduledDateSourceOrigin.recurringIslamic(.mondayThursday).stopSeriesLabel == "Stop Monday & Thursday schedule")
        #expect(ScheduledDateSourceOrigin.manualGregorianRange.label == "Part of a saved date range")
        #expect(ScheduledDateSourceOrigin.manualGregorianRange.stopSeriesLabel == "Remove date range")
    }

    @Test
    @MainActor
    func requestRescheduleDayAppliesLatestOverrideAfterBurstEdits() async throws {
        let suiteName = "SuhoorTests.DayRescheduleBurst"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorOffsetOverrideMinutes = 25
        }
        scheduleManager.requestRescheduleDay(targetDate)

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorOffsetOverrideMinutes = 55
        }
        scheduleManager.requestRescheduleDay(targetDate)

        try await Task.sleep(nanoseconds: 500_000_000)

        let refreshed = scheduleManager.activeWindowSnapshot.visibleDays.first {
            DateHelpers.isSameDay($0.date, targetDate, in: .current)
        }
        #expect(refreshed?.schedule.offsetMinutes == 55)
    }

    @Test
    @MainActor
    func activeDayBypassesCachedSnapshotWhenOverridesChange() async throws {
        let suiteName = "SuhoorTests.ActiveDayFreshOverride"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        let cached = scheduleManager.activeDay(for: targetDate)
        let initialOffset = cached?.schedule.offsetMinutes

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorOffsetOverrideMinutes = 65
        }

        let refreshed = scheduleManager.refreshedActiveDay(for: targetDate)

        #expect(initialOffset != 65)
        #expect(refreshed?.schedule.offsetMinutes == 65)
    }

    @Test
    @MainActor
    func perDayWakeCustomizationOverridesDisabledDefaultWakeAlarm() async {
        let suiteName = "SuhoorTests.DayWakeOverrideBeatsDisabledDefault"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        alarmConfigStore.defaults.suhoorEnabledDefault = false
        alarmConfigStore.defaults.reminderEnabledDefault = true
        alarmConfigStore.defaults.fajrEnabledDefault = false
        alarmConfigStore.defaults.iftarEnabledDefault = false

        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        let cached = scheduleManager.activeDay(for: targetDate)
        #expect(cached?.effectiveConfig.suhoorEnabled == false)
        #expect(cached?.effectiveConfig.reminderEnabled == true)
        #expect(cached?.primaryDisplay?.kind == .reminder)

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorEnabled = true
            draft.suhoorOffsetOverrideMinutes = 30
        }

        let refreshed = scheduleManager.refreshedActiveDay(for: targetDate)

        #expect(refreshed?.effectiveConfig.suhoorEnabled == true)
        #expect(refreshed?.effectiveConfig.reminderEnabled == true)
        #expect(refreshed?.schedule.offsetMinutes == 30)
        #expect(refreshed?.primaryDisplay?.kind == .suhoor)
        #expect(refreshed?.primaryDisplay?.time == refreshed?.schedule.wakeDate)
    }

    @Test
    @MainActor
    func explicitDayDisableStillWinsOverWakeCustomization() {
        let suiteName = "SuhoorTests.ExplicitWakeDisableWins"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)
        alarmConfigStore.defaults.suhoorEnabledDefault = false

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorOffsetOverrideMinutes = 45
            draft.suhoorEnabled = false
        }

        let summary = RuleEngine(
            settings: .default,
            defaultConfig: alarmConfigStore.defaults,
            overridesByDay: alarmConfigStore.overridesByDay,
            timeZone: .current
        ).ruleSummary(for: targetDate)
        let config = alarmConfigStore.effectiveConfig(
            for: targetDate,
            ruleSummary: summary,
            settings: .default,
            timeZone: .current
        )

        #expect(config.suhoorEnabled == false)
        #expect(config.suhoorOffsetMinutes == 45)
    }

    @Test
    @MainActor
    func refreshedActiveDayBypassesCachedPrimaryDisplay() async {
        let suiteName = "SuhoorTests.RefreshedActiveDayBypassesCachedPrimary"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        alarmConfigStore.defaults.suhoorEnabledDefault = false
        alarmConfigStore.defaults.reminderEnabledDefault = true
        alarmConfigStore.defaults.fajrEnabledDefault = false
        alarmConfigStore.defaults.iftarEnabledDefault = false

        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        let cached = scheduleManager.activeDay(for: targetDate)
        #expect(cached?.primaryDisplay?.kind == .reminder)

        alarmConfigStore.updateOverride(for: targetDate) { draft in
            draft.suhoorEnabled = true
            draft.suhoorOffsetOverrideMinutes = 30
        }

        let stillCached = scheduleManager.activeDay(for: targetDate)
        let refreshed = scheduleManager.refreshedActiveDay(for: targetDate)

        #expect(stillCached?.primaryDisplay?.kind == .reminder)
        #expect(refreshed?.primaryDisplay?.kind == .suhoor)
        #expect(refreshed?.primaryDisplay?.time == refreshed?.schedule.wakeDate)
    }

    @Test
    @MainActor
    func duplicateStatusReturnsExistingActiveDayFromSnapshot() async {
        let suiteName = "SuhoorTests.DuplicateStatus"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        let targetDate = DateHelpers.startOfTomorrow(in: .current)
        alarmConfigStore.addSingleDaySource(targetDate)

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        switch scheduleManager.duplicateStatus(for: targetDate) {
        case .available:
            #expect(false)
        case .active(let provenances, let existingDay):
            #expect(!provenances.isEmpty)
            #expect(DateHelpers.isSameDay(existingDay.date, targetDate, in: .current))
        }
    }

    @Test
    @MainActor
    func activeWindowSchedulesOnlyVisiblePrefix() async {
        let suiteName = "SuhoorTests.ActiveWindowPrefix"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let locationService = LocationService()

        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startDate = DateHelpers.startOfTomorrow(in: .current)
        for offset in 0..<40 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            alarmConfigStore.addSingleDaySource(date)
        }

        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )

        await scheduleManager.refreshSchedules(force: true)

        let snapshot = scheduleManager.activeWindowSnapshot
        let visibleKeys = snapshot.visibleDays.map(\.dateKey)
        let scheduledKeys = snapshot.scheduledDays.map(\.dateKey)
        #expect(!visibleKeys.isEmpty)
        #expect(scheduledKeys == Array(visibleKeys.prefix(snapshot.scheduledHorizonDays)))
    }

    @Test
    func fastIntentEngineWarnsAndSuppressesDerivedTagsOnEid() {
        let suiteName = "SuhoorTests.FastIntentEid"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let service = HijriCalendarService(adjustmentStore: adjustmentStore)
        let calendar = AdjustedHijriCalendar(calendarService: service)

        let originalCalendar = FastIntentEngine.adjustedHijriCalendar
        FastIntentEngine.adjustedHijriCalendar = calendar
        defer { FastIntentEngine.adjustedHijriCalendar = originalCalendar }

        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let hijriYear = 1447
        let eid = service.dateForEidAlFitr(hijriYear: hijriYear, timeZone: timeZone)
        #expect(eid != nil)
        guard let eid else { return }

        let warnings = FastIntentEngine.warnings(for: eid, timeZone: timeZone)
        #expect(warnings.contains(.eidAlFitr))

        let derived = FastIntentEngine.dateDerivedObservanceTags(for: eid, timeZone: timeZone, includeShawwalPotential: true)
        #expect(derived.isEmpty)
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
            maghribDate: boundary.addingTimeInterval(12 * 3600),
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            iftarDate: boundary.addingTimeInterval(12 * 3600),
            fajrSoundChoice: .systemDefault,
            iftarSoundChoice: nil,
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
            maghribDate: boundary.addingTimeInterval(12 * 3600),
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            iftarDate: boundary.addingTimeInterval(12 * 3600),
            fajrSoundChoice: .systemDefault,
            iftarSoundChoice: nil,
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
            maghribDate: day,
            wakeDate: day,
            reminderDate: nil,
            boundaryDate: nil,
            iftarDate: nil,
            fajrSoundChoice: nil,
            iftarSoundChoice: nil,
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
            maghribDate: Date().addingTimeInterval(12 * 3600),
            wakeDate: Date().addingTimeInterval(1800),
            reminderDate: nil,
            boundaryDate: nil,
            iftarDate: nil,
            fajrSoundChoice: nil,
            iftarSoundChoice: nil,
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
            maghribDate: Date().addingTimeInterval(12 * 3600),
            wakeDate: Date().addingTimeInterval(1800),
            reminderDate: Date().addingTimeInterval(2400),
            boundaryDate: Date().addingTimeInterval(3600),
            iftarDate: Date().addingTimeInterval(12 * 3600),
            fajrSoundChoice: .systemDefault,
            iftarSoundChoice: nil,
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

    @Test
    func settingsDefaultAlarmSummaryUsesCanonicalLabels() {
        let config = DefaultAlarmConfig(
            suhoorEnabledDefault: true,
            reminderEnabledDefault: false,
            fajrEnabledDefault: false,
            iftarEnabledDefault: true,
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

        let summary = SettingsSummaryFormatter.defaultAlarmsSummary(config: config)

        #expect(summary == "Wake 30 min before Fajr · Reminder off · Fajr adhan off")
    }

    @Test
    func settingsIssuesStayEmptyUntilPermissionsLoad() {
        let issues = SettingsSummaryFormatter.issues(
            settings: .default,
            schedulingMode: .none,
            presentations: [:]
        )

        #expect(issues.isEmpty)
        #expect(
            SettingsSummaryFormatter.permissionsSummary(
                settings: .default,
                schedulingMode: .none,
                presentations: [:]
            ) == "Checking status"
        )
    }

    @Test
    func settingsIssuesIncludeLocationWhenAutomaticModeIsDenied() {
        let issues = SettingsSummaryFormatter.issues(
            settings: .default,
            schedulingMode: .none,
            presentations: [
                .location: makePermissionPresentation(kind: .location, state: .denied),
                .alarmKit: makePermissionPresentation(kind: .alarmKit, state: .authorized),
                .notifications: makePermissionPresentation(kind: .notifications, state: .authorized)
            ]
        )

        #expect(issues.contains(where: { $0.destination == .location }))
    }

    @Test
    func permissionsSummaryShowsNotificationFallback() {
        let summary = SettingsSummaryFormatter.permissionsSummary(
            settings: .default,
            schedulingMode: .notifications,
            presentations: [
                .location: makePermissionPresentation(kind: .location, state: .authorized),
                .alarmKit: makePermissionPresentation(kind: .alarmKit, state: .unavailable),
                .notifications: makePermissionPresentation(kind: .notifications, state: .authorized)
            ]
        )

        #expect(summary == "Using notifications")
    }

    private func makePermissionPresentation(kind: AppPermissionKind, state: AppPermissionState) -> PermissionPresentation {
        PermissionPresentation(
            kind: kind,
            state: state,
            title: kind.rawValue,
            statusText: "",
            message: "",
            actionTitle: nil,
            secondaryActionTitle: nil,
            showsProgress: false,
            showsSimulatorHint: false,
            isBlocking: false
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func sampleDaySchedule(date: Date, wakeDate: Date? = nil) -> DaySchedule {
        DaySchedule(
            date: date,
            fajrDate: date.addingTimeInterval(120),
            maghribDate: date.addingTimeInterval(3600),
            wakeDate: wakeDate ?? date.addingTimeInterval(60),
            reminderDate: nil,
            boundaryDate: date.addingTimeInterval(120),
            iftarDate: nil,
            fajrSoundChoice: .systemDefault,
            iftarSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: 30,
            calculationMethodName: "",
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )
    }

    private func sampleEffectiveDailyConfig(date: Date) -> EffectiveDailyConfig {
        EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: false,
            fajrEnabled: false,
            iftarEnabled: false,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .systemDefault,
            iftarDelivery: .notificationOnly,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: false
        )
    }

    private func sampleAlarmRowEntry(
        date: Date,
        wakeDate: Date,
        isEnabled: Bool
    ) -> AlarmRowEntry {
        AlarmRowEntry(
            activeDay: ActiveAlarmDay(
                date: date,
                dateKey: DateHelpers.dayIdentifier(for: date, timeZone: .current),
                schedule: sampleDaySchedule(date: date, wakeDate: wakeDate),
                effectiveConfig: sampleEffectiveDailyConfig(date: date, isEnabled: isEnabled),
                provenances: [],
                isImplicitRamadan: false,
                isExplicitOneOff: false,
                tagResult: .empty,
                primaryDisplay: PrimaryDisplay(time: wakeDate, kind: .suhoor),
                sourceSummaryText: ""
            )
        )
    }

    private func sampleEffectiveDailyConfig(date: Date, isEnabled: Bool) -> EffectiveDailyConfig {
        EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: isEnabled == false,
            suhoorEnabled: isEnabled,
            reminderEnabled: false,
            fajrEnabled: false,
            iftarEnabled: false,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .systemDefault,
            iftarDelivery: .notificationOnly,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: false
        )
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
