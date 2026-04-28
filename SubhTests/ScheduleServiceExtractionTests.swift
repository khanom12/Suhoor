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
    func tomorrowHeroSuppressesOrdinaryAndDiagnosticCopy() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let entry = Self.makeWakeEntry(
            date: Self.makeDate(year: 2026, month: 4, day: 27, timeZone: timeZone),
            timeZone: timeZone,
            providerNotes: "provider:solar_sunrise_proxy"
        )

        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: "",
            currentDate: Self.makeDate(year: 2026, month: 4, day: 26, timeZone: timeZone),
            timeZone: timeZone
        )

        #expect(display.title == "Tomorrow")
        #expect(display.statusText == "Wake alarm")
        #expect(display.detailText == "30 min before Fajr ends")
        #expect(display.chipTitles.isEmpty)
        #expect(display.accessibilityLabel.contains("sunrise-derived") == false)
        #expect(display.accessibilityLabel.contains("Ordinary") == false)
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
        #expect(skipped.statusText == "No wake scheduled")
        #expect(skipped.detailText == "No wake for this date")
        #expect(fixed.detailText == "Fixed wake")
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
    func morningcastForecastNamingIsStable() {
        #expect(MorningHomeSnapshot.forecastTitle == "10-Day Wake Forecast")
        #expect(MorningHomeSnapshot.forecastSubtitle == "Next 10 mornings")
    }

    @Test
    func settingsPrayerSummarySplitsMethodAndOffsets() {
        let summary = SettingsSummaryFormatter.prayerTimesSummary(settings: .default)

        #expect(summary.contains("Calculation method:"))
        #expect(summary.contains("\nPrayer offsets:"))
        #expect(summary.contains("Fajr +0 min"))
        #expect(summary.contains("Maghrib +0 min"))
    }

    @Test
    func trustCopyUsesHumanFajrBoundaryLanguage() {
        #expect(WakePagePresentation.ordinaryMeaningText == "Regular Fajr morning")
        #expect(FajrWindowBoundaryTruth.sunriseProxy.boundaryLabel == "Supported Fajr end")
        #expect(FajrWindowBoundaryTruth.sunriseProxy.explanationText == "The supported Fajr end is based on sunrise for this date.")
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
        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr begins at 5:00 AM • Fajr ends at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Tomorrow's alarm is 30 minutes before Fajr ends.")
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
        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr begins at 5:00 AM • Fajr ends at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Today's alarm is 30 minutes before Fajr ends.")
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

        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr begins at 5:00 AM • Fajr ends at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Today's alarm is off for this date.")
        #expect(snapshot.selectedDay.iconName == "bell.slash.fill")
        #expect(snapshot.selectedDay.timeMain == "Off")
        #expect(snapshot.selectedDay.timeSuffix == nil)
    }

    @Test
    func compactFajrcastUsesInProgressFajrFooterTense() {
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

        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr began at 5:00 AM • Fajr ends at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Today's alarm is 30 minutes before Fajr ends.")
    }

    @Test
    func compactFajrcastUsesPastFajrFooterAndAlarmTense() {
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

        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr began at 5:00 AM • Fajr ended at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Yesterday's alarm was 30 minutes before Fajr ended.")
        #expect(snapshot.selectedDay.relativeLabel == "YESTERDAY")
    }

    @Test
    func compactFajrcastUsesPastSkippedFooterTense() {
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

        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr began at 5:00 AM • Fajr ended at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Yesterday's alarm was off for this date.")
        #expect(snapshot.selectedDay.timeMain == "Off")
    }

    @Test
    func compactFajrcastPreservesAdjustedSecondarySummary() {
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

        #expect(Self.normalizedTimeSpaces(snapshot.summary.primaryText) == "Fajr begins at 5:00 AM • Fajr ends at 6:16 AM")
        #expect(snapshot.summary.secondaryText == "Today's alarm is 30 minutes before Fajr ends.")
        #expect(snapshot.compactInsight == "1 morning is adjusted this week.")
    }

    @Test
    func compactFajrcastUsesFocusedAdjustedFooterContext() {
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
        #expect(snapshot.summary.secondaryText == "Adjusted: Wednesday's alarm is 30 minutes before Fajr ends.")
    }

    @Test
    func compactFajrcastUsesFocusedFastingFooterContext() {
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
        #expect(snapshot.summary.secondaryText == "Fasting day: Tomorrow's alarm is 30 minutes before Fajr ends.")
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
        #expect(focusedSnapshot.summary.secondaryText == "Friday's alarm was 30 minutes before Fajr ended.")

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
        #expect(snapBackSnapshot.summary.secondaryText == "Tomorrow's alarm is 30 minutes before Fajr ends.")
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
        skipDay: Bool = false,
        hasDayOverride: Bool = false,
        plannedWakeState: MorningWakeRuleState = .inFajr,
        providerNotes: String? = nil
    ) -> WakeRowEntry {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)
        let fajrStart = calendar.date(byAdding: .hour, value: 5, to: start) ?? start
        let fajrEnd = calendar.date(byAdding: .minute, value: 76, to: fajrStart) ?? fajrStart
        let wake = plannedWakeState == .fixedWake
            ? (calendar.date(byAdding: .minute, value: 45, to: fajrStart) ?? fajrStart)
            : (calendar.date(byAdding: .minute, value: -30, to: fajrEnd) ?? fajrStart)
        let schedule = DaySchedule(
            date: start,
            fajrDate: fajrStart,
            maghribDate: calendar.date(byAdding: .hour, value: 14, to: fajrStart) ?? fajrStart,
            wakeDate: wake,
            reminderDate: nil,
            boundaryDate: fajrEnd,
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
            tagResult: .empty,
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
            : (schedule.boundaryDate ?? schedule.fajrDate)
        let delta = WakeDelta(relation: .before, minutes: plannedWakeState == .fixedWake ? 0 : 30)

        return RuleDecisionLog(
            dateKey: dateKey,
            resolverVersion: 1,
            decisionHash: "\(dateKey).test",
            prayerWindow: DailyPrayerWindow(
                date: schedule.date,
                fajrStart: schedule.fajrDate,
                fajrEnd: schedule.boundaryDate,
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
