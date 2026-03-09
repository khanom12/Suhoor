import Foundation
import Testing
@testable import Suhoor

@Suite
struct ProductSurfacePresentationTests {
    @Test
    func secondaryContextTitlesOmitStandardAndDuplicatesAndLimitToTwo() {
        let resolved = ResolvedDayContext(
            primaryContext: .qadaFast,
            secondaryContexts: [.standard, .qadaFast, .sunnahFast, .specialDay, .tahajjud],
            supportingTags: [.qada],
            explanation: .empty
        )

        let titles = ProductSurfacePresentation.meaningfulSecondaryContextTitles(from: resolved)

        #expect(titles == ["Sunnah", "Special day"])
    }

    @Test
    func configuredPlansSnapshotIncludesOverridesAndNonDefaultMornings() {
        let overrideDay = makeActiveDay(
            day: 1,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [defaultDailyProvenance]
        )
        let qadaDay = makeActiveDay(
            day: 2,
            context: .qadaFast,
            supportingTags: [.qada],
            provenances: [manualProvenance(label: "Qada plan")]
        )
        let selectedFastDay = makeActiveDay(
            day: 3,
            context: .fasting,
            supportingTags: [.whiteDays],
            provenances: [manualProvenance(label: "Selected fasting day")]
        )
        let defaultDay = makeActiveDay(
            day: 4,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [defaultDailyProvenance]
        )

        let snapshot = ProductSurfacePresentation.configuredPlansSnapshot(
            upcomingDays: [overrideDay, qadaDay, selectedFastDay, defaultDay],
            overrideDateKeys: [overrideDay.dateKey],
            qadaProgress: QadaProgressSnapshot(remaining: 4, completed: 2, baselineOwed: 6)
        )

        #expect(snapshot.upcomingSpecialMornings.count == 3)
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Adjusted" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Qada fast" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Fasting day" }))
        #expect(snapshot.qadaSummary == "2 completed · 4 remaining")
    }

    @Test
    func homeSupportDecisionPrefersBlockingIssuesOverFajrAndFasting() {
        let currentDay = makeActiveDay(
            day: 5,
            context: .fasting,
            supportingTags: [.ramadan],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 5),
                prayer: .empty,
                fast: FastCompletionState(status: .unknown, intentSnapshot: voluntaryFastIntent, updatedAt: nil, source: nil),
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: .prayerCheckIn,
                isMeaningfullyResolved: false
            )
        )
        let permissionSnapshot = PermissionSnapshot(
            summaryText: "Needs attention",
            alarmAuthorizationText: "--",
            notificationAuthorizationText: "--",
            presentations: [
                .location: PermissionPresentation(
                    kind: .location,
                    state: .denied,
                    title: "Location",
                    statusText: "Needs attention",
                    message: "Location is required.",
                    actionTitle: "Open Settings",
                    secondaryActionTitle: nil,
                    showsProgress: false,
                    showsSimulatorHint: false,
                    isBlocking: true
                )
            ]
        )
        let components = AdjustedHijriDateComponents(
            hijriYear: 1447,
            month: .ramadan,
            day: 12,
            monthTitle: HijriMonth.ramadan.displayName,
            isDerivedFromBaseline: true
        )

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 5, hour: 6, minute: 0),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: .default,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: components,
            dismissedWarnings: []
        ).supportDecision?.presentation

        #expect(result == .blockingIssue(.location))
    }

    @Test
    func homeSupportDecisionShowsFajrCheckInBeforeFastingCheckInDuringMorningWindow() {
        let currentDay = makeActiveDay(
            day: 5,
            context: .fasting,
            supportingTags: [.ramadan],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 5),
                prayer: .empty,
                fast: FastCompletionState(status: .unknown, intentSnapshot: voluntaryFastIntent, updatedAt: nil, source: nil),
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: .prayerCheckIn,
                isMeaningfullyResolved: false
            )
        )

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 5, hour: 6, minute: 30),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: .default,
            permissionSnapshot: PermissionSnapshot(
                summaryText: "",
                alarmAuthorizationText: "",
                notificationAuthorizationText: "",
                presentations: [:]
            ),
            hijriComponents: nil,
            dismissedWarnings: []
        ).supportDecision?.presentation

        switch result {
        case .fajrCompletionPrompt:
            #expect(Bool(true))
        default:
            Issue.record("Expected Fajr completion prompt during morning window.")
        }
    }

    @Test
    func homeSupportDecisionShowsFastingStatusLaterInDayBeforeLingeringFajrPrompt() {
        let currentDay = makeActiveDay(
            day: 5,
            context: .fasting,
            supportingTags: [.voluntary],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 5),
                prayer: .empty,
                fast: FastCompletionState(status: .unknown, intentSnapshot: voluntaryFastIntent, updatedAt: nil, source: nil),
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: .fastingStatus,
                isMeaningfullyResolved: false
            )
        )

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 5, hour: 14, minute: 0),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: .default,
            permissionSnapshot: PermissionSnapshot(
                summaryText: "",
                alarmAuthorizationText: "",
                notificationAuthorizationText: "",
                presentations: [:]
            ),
            hijriComponents: nil,
            dismissedWarnings: []
        ).supportDecision?.presentation

        switch result {
        case .fasting(let presentation):
            #expect(presentation.phase == .fastingStatusPrompt)
        default:
            Issue.record("Expected fasting status prompt later in the day.")
        }
    }

    @Test
    func homeSupportDecisionShowsFastCompletionPromptAfterMaghribWhenStillUnknown() {
        let currentDay = makeActiveDay(
            day: 5,
            context: .qadaFast,
            supportingTags: [.qada],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 5),
                prayer: .empty,
                fast: FastCompletionState(status: .unknown, intentSnapshot: qadaFastIntent, updatedAt: nil, source: nil),
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: .fastCompletion,
                isMeaningfullyResolved: false
            )
        )

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 5, hour: 19, minute: 15),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: .default,
            permissionSnapshot: PermissionSnapshot(
                summaryText: "",
                alarmAuthorizationText: "",
                notificationAuthorizationText: "",
                presentations: [:]
            ),
            hijriComponents: nil,
            dismissedWarnings: []
        ).supportDecision?.presentation

        switch result {
        case .fasting(let presentation):
            #expect(presentation.phase == .fastCompletionPrompt)
            #expect(presentation.title == "How did today go?")
        default:
            Issue.record("Expected fast completion prompt after Maghrib.")
        }
    }

    @Test
    func homeSupportDecisionCanStayQuietWhenDayIsMeaningfullyResolved() {
        let currentDay = makeActiveDay(
            day: 6,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 6),
                prayer: PrayerCompletionState(status: .completed, updatedAt: makeDate(day: 6, hour: 6, minute: 0), source: "test"),
                fast: .notRequired,
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: nil,
                isMeaningfullyResolved: true
            )
        )

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 6, hour: 13, minute: 0),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: .default,
            permissionSnapshot: PermissionSnapshot(
                summaryText: "",
                alarmAuthorizationText: "",
                notificationAuthorizationText: "",
                presentations: [:]
            ),
            hijriComponents: nil,
            dismissedWarnings: []
        )

        #expect(result.supportDecision == nil)
    }

    @Test
    func homeSupportDecisionSuppressesPrayerPromptDuringQuietPeriod() {
        let currentDay = makeActiveDay(
            day: 6,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [defaultDailyProvenance],
            dailyCompletion: .init(
                dateKey: dayKey(day: 6),
                prayer: .empty,
                fast: .notRequired,
                qadaEffect: .none,
                wakeSupport: .none,
                outstandingAction: .prayerCheckIn,
                isMeaningfullyResolved: false
            )
        )
        var settings = AppSettings.default
        settings.quietPeriodEnabled = true
        settings.pausePrayerPrompts = true

        let result = CompletionProjectionBuilder.buildHome(
            now: makeDate(day: 6, hour: 6, minute: 15),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            settings: settings,
            permissionSnapshot: .empty,
            hijriComponents: nil,
            dismissedWarnings: []
        )

        #expect(result.supportDecision == nil)
    }

    @Test
    func wakeProgressSnapshotUsesWakeEventsOnly() {
        let events = [
            DebugEvent(timestamp: makeDate(day: 8, hour: 5, minute: 10), type: .firedSuhoor),
            DebugEvent(timestamp: makeDate(day: 8, hour: 5, minute: 12), type: .dismissedSuhoor),
            DebugEvent(timestamp: makeDate(day: 8, hour: 5, minute: 15), type: .scheduledSuhoorSnooze),
            DebugEvent(timestamp: makeDate(day: 8, hour: 5, minute: 16), type: .firedFajrAdhan),
        ]

        let snapshot = ProductSurfacePresentation.wakeProgressSnapshot(from: events)

        #expect(snapshot.summaryTitle == "1 recent wake event")
        #expect(snapshot.recentActivityLines.count == 3)
        #expect(snapshot.recentActivityLines.allSatisfy { !$0.contains("fajr") })
        #expect(snapshot.emptyStateText == nil)
    }

    @Test
    func dailyCompletionResolverMapsQadaCompletionToQadaEffectOnlyWhenCompleted() {
        let dateKey = dayKey(day: 9)
        let resolvedContext = ResolvedDayContext(
            primaryContext: .qadaFast,
            secondaryContexts: [],
            supportingTags: [.qada],
            explanation: .empty
        )
        let completedRecord = CompletionRecord(
            id: "fast-\(dateKey)",
            dateKey: dateKey,
            kind: .fast,
            status: .completed,
            updatedAt: makeDate(day: 9, hour: 20, minute: 0),
            source: "test",
            metadata: [
                "legacyStatus": FastLogStatus.completed.rawValue,
                "primaryIntent": FastPrimaryIntent.qadaMakeup.rawValue,
            ]
        )
        let state = CompletionStateAssembler.assemble(
            completionRecords: [completedRecord],
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: dateKey,
                baselineOwed: 5,
                completed: 2,
                remaining: 3
            )
        )

        let snapshot = DailyCompletionResolver.resolve(
            dateKey: dateKey,
            resolvedDayContext: resolvedContext,
            completionState: state
        )

        #expect(snapshot.fast.status == .completed)
        #expect(snapshot.qadaEffect.countsTowardQada)
        #expect(snapshot.qadaEffect.completedDelta == 1)
        #expect(snapshot.qadaEffect.remainingAfterEffect == 3)
    }

    @Test
    func progressProjectionReadsCanonicalCompletionState() {
        let todayKey = dayKey(day: 10)
        let records = [
            CompletionRecord(
                id: "fajr-\(todayKey)",
                dateKey: todayKey,
                kind: .fajr,
                status: .completed,
                updatedAt: makeDate(day: 10, hour: 6, minute: 0),
                source: "test",
                metadata: [:]
            ),
            CompletionRecord(
                id: "fast-\(todayKey)",
                dateKey: todayKey,
                kind: .fast,
                status: .completed,
                updatedAt: makeDate(day: 10, hour: 19, minute: 0),
                source: "test",
                metadata: ["legacyStatus": FastLogStatus.completed.rawValue]
            ),
        ]
        let completionState = CompletionStateAssembler.assemble(
            completionRecords: records,
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: todayKey,
                baselineOwed: 2,
                completed: 1,
                remaining: 1
            )
        )
        let todayCompletion = DailyCompletionSnapshot(
            dateKey: todayKey,
            prayer: PrayerCompletionState(status: .completed, updatedAt: makeDate(day: 10, hour: 6, minute: 0), source: "test"),
            fast: FastCompletionState(status: .completed, intentSnapshot: voluntaryFastIntent, updatedAt: makeDate(day: 10, hour: 19, minute: 0), source: "test"),
            qadaEffect: .none,
            wakeSupport: .none,
            outstandingAction: nil,
            isMeaningfullyResolved: true
        )

        let snapshot = CompletionProjectionBuilder.buildProgress(
            todayCompletion: todayCompletion,
            recentDateKeys: [todayKey],
            completionState: completionState,
            settings: .default,
            wakeProgress: .empty
        )

        #expect(snapshot.fajrTodaySummary == "Fajr completed")
        #expect(snapshot.fastTodaySummary == "Completed")
        #expect(snapshot.headlineText == "You're making progress on Qada.")
        #expect(snapshot.qadaProgress.remaining == 1)
        #expect(snapshot.wakeProgress == .empty)
    }

    @Test
    func fajrHistoryProjectionUsesCanonicalPrayerCompletionOnly() {
        let window = CompletionHistoryWindow(
            resolvedDays: [
                makeResolvedDay(
                    day: 11,
                    context: .standard,
                    supportingTags: [.dailyPlan],
                    prayerStatus: .completed,
                    fastStatus: .notRequired
                ),
                makeResolvedDay(
                    day: 10,
                    context: .standard,
                    supportingTags: [.dailyPlan],
                    prayerStatus: .missed,
                    fastStatus: .notRequired
                ),
            ],
            dailyCompletions: []
        )

        let snapshot = CompletionHistoryProjectionBuilder.buildFajr(window: window)

        #expect(snapshot.rows.count == 2)
        #expect(snapshot.rows[0].status == .completed)
        #expect(snapshot.rows[0].statusText == "Prayed")
        #expect(snapshot.rows[1].status == .missed)
        #expect(snapshot.summaryText == "1 prayed · 1 missed")
    }

    @Test
    func fastHistoryProjectionShowsQadaEffectAndSkipsNonFastingDays() {
        let qadaDay = makeResolvedDay(
            day: 12,
            context: .qadaFast,
            supportingTags: [.qada],
            prayerStatus: .completed,
            fastStatus: .completed,
            intentSnapshot: qadaFastIntent,
            qadaEffect: QadaEffect(
                countsTowardQada: true,
                completedDelta: 1,
                remainingAfterEffect: 2,
                explanation: "Completed Qada fasts reduce what remains."
            )
        )
        let standardDay = makeResolvedDay(
            day: 11,
            context: .standard,
            supportingTags: [.dailyPlan],
            prayerStatus: .completed,
            fastStatus: .notRequired
        )

        let snapshot = CompletionHistoryProjectionBuilder.buildFast(
            window: CompletionHistoryWindow(
                resolvedDays: [qadaDay, standardDay],
                dailyCompletions: []
            )
        )

        #expect(snapshot.rows.count == 1)
        #expect(snapshot.rows[0].meaningText == "Qada fast")
        #expect(snapshot.rows[0].qadaEffectText == "Counts toward Qada · 2 remaining")
        #expect(snapshot.rows[0].status == .completed)
    }

    @Test
    func wakeSurfaceProviderPreservesCanonicalWakeInputs() {
        let firstDay = makeActiveDay(
            day: 14,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance]
        )
        let secondDay = makeActiveDay(
            day: 15,
            context: .fasting,
            supportingTags: [.voluntary],
            provenances: [Self.manualProvenance(label: "Selected fasting day")]
        )
        let activeWindow = makeActiveWindowSnapshot(days: [firstDay, secondDay])
        let nextWakeSummary = makeNextWakeSummary(for: firstDay)

        let snapshot = WakeSurfaceProvider().wakeSurfaceSnapshot(
            activeWindowSnapshot: activeWindow,
            nextWakeEventSummary: nextWakeSummary,
            overrideDateKeys: [secondDay.dateKey]
        )

        #expect(snapshot.visibleDays == activeWindow.visibleDays)
        #expect(snapshot.nextWakeEventSummary == nextWakeSummary)
        #expect(snapshot.overrideDateKeys == [secondDay.dateKey])
    }

    @Test
    func nextWakeEventResolverPrefersReminderWhenTimesMatchAndReturnsEarliestUpcoming() {
        let firstDay = makeActiveDay(
            day: 22,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance],
            scheduledEvents: [
                ScheduledEvent(
                    id: "reminder",
                    type: .wakeReminder,
                    dateKey: dayKey(day: 22),
                    fireDate: makeDate(day: 22, hour: 5, minute: 0),
                    relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: -30),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.reminder]
                ),
                ScheduledEvent(
                    id: "wake",
                    type: .wakeAlarm,
                    dateKey: dayKey(day: 22),
                    fireDate: makeDate(day: 22, hour: 5, minute: 0),
                    relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: -30),
                    isUserVisible: true,
                    affectsCompletion: true,
                    deliveryKinds: [.wake]
                ),
            ]
        )
        let secondDay = makeActiveDay(
            day: 23,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance],
            scheduledEvents: [
                ScheduledEvent(
                    id: "later",
                    type: .wakeAlarm,
                    dateKey: dayKey(day: 23),
                    fireDate: makeDate(day: 23, hour: 5, minute: 0),
                    relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: -30),
                    isUserVisible: true,
                    affectsCompletion: true,
                    deliveryKinds: [.wake]
                )
            ]
        )

        let resolved = NextWakeEventResolver().resolve(
            activeWindowSnapshot: makeActiveWindowSnapshot(days: [firstDay, secondDay]),
            now: makeDate(day: 22, hour: 4, minute: 30)
        )

        #expect(resolved?.day.dateKey == firstDay.dateKey)
        #expect(resolved?.event.type == .wakeReminder)
    }

    @Test
    func nextWakeEventResolverReturnsNilWhenNothingIsUpcoming() {
        let pastDay = makeActiveDay(
            day: 24,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance],
            scheduledEvents: [
                ScheduledEvent(
                    id: "past",
                    type: .wakeAlarm,
                    dateKey: dayKey(day: 24),
                    fireDate: makeDate(day: 24, hour: 5, minute: 0),
                    relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: -30),
                    isUserVisible: true,
                    affectsCompletion: true,
                    deliveryKinds: [.wake]
                )
            ]
        )

        let resolved = NextWakeEventResolver().resolve(
            activeWindowSnapshot: makeActiveWindowSnapshot(days: [pastDay]),
            now: makeDate(day: 24, hour: 6, minute: 0)
        )

        #expect(resolved == nil)
    }

    @Test
    func wakeListSnapshotBuilderKeepsNextWakePinnedAndOutOfMonthSections() {
        let firstDay = makeActiveDay(
            day: 16,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance]
        )
        let secondDay = makeActiveDay(
            day: 17,
            context: .qadaFast,
            supportingTags: [.qada],
            provenances: [Self.manualProvenance(label: "Qada plan")]
        )
        let wakeSnapshot = WakeSurfaceSnapshot(
            visibleDays: [firstDay, secondDay],
            nextWakeEventSummary: makeNextWakeSummary(for: firstDay),
            overrideDateKeys: [secondDay.dateKey]
        )
        let monthKey = HijriMonthKey(year: 1447, month: HijriMonth.ramadan.rawValue, title: "Ramadan 1447")

        let result = WakeListSnapshotBuilder.build(
            wakeSnapshot: wakeSnapshot,
            tagFilter: WakeTagFilter(),
            pinnedEntryIDs: ["missing-id"],
            timeZone: .current,
            totalScheduledCount: { key in key == monthKey ? 2 : 0 },
            rollingHijriMonths: { [] },
            monthPreview: { _ in nil },
            cachedMonthEntries: { key in key == monthKey ? [firstDay, secondDay] : nil }
        )

        #expect(result.pinnedEntryIDs.isEmpty)
        #expect(result.snapshot.nextWakeEntries.count == 1)
        #expect(result.snapshot.nextWakeEntries.first?.id == firstDay.dateKey)
        #expect(result.snapshot.sections.count == 1)
        #expect(result.snapshot.sections[0].entries.map(\.id) == [secondDay.dateKey])
        #expect(result.snapshot.sections[0].entries.first?.hasDayOverride == true)
    }

    @Test
    func homeSurfaceProviderPassesThroughCompletionDrivenSupportDecision() {
        let currentDay = makeActiveDay(
            day: 25,
            context: .qadaFast,
            supportingTags: [.qada],
            provenances: [Self.manualProvenance(label: "Qada plan")]
        )
        let supportDecision = HomeSupportDecision(
            presentation: .fajrCompletionPrompt(
                FajrHomeSupportPresentation(
                    dateKey: currentDay.dateKey,
                    title: "Did you pray Fajr?",
                    detail: "Check in when you are ready."
                )
            ),
            reason: "Prayer is still unresolved.",
            isDismissible: false
        )

        let snapshot = HomeSurfaceProvider().homeSurfaceSnapshot(
            now: makeDate(day: 25, hour: 6, minute: 0),
            currentDay: currentDay,
            todaySchedule: currentDay.schedule,
            nextWakeEventSummary: nil,
            settings: .default,
            permissionSnapshot: .empty,
            hijriComponents: nil,
            supportDecision: supportDecision,
            dayLabel: { _ in "Today" }
        )

        #expect(snapshot.contextSummaryText == "Today • Qada fast")
        #expect(snapshot.supportDecision == supportDecision)
    }

    @Test
    func plansSurfaceProviderBuildsConfiguredPlansAndQadaSummaryFromInputs() {
        var settings = AppSettings.default
        settings.snoozeEnabled = false

        var defaults = DefaultAlarmConfig.default
        defaults.defaultSuhoorOffsetMinutes = 45
        defaults.iftarEnabledDefault = true

        let qadaDay = makeActiveDay(
            day: 18,
            context: .qadaFast,
            supportingTags: [.qada],
            provenances: [Self.manualProvenance(label: "Qada plan")]
        )
        let adjustedDay = makeActiveDay(
            day: 19,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance]
        )
        let fastEntries = [
            qadaDay.dateKey: FastLogEntry(
                status: .completed,
                loggedAt: makeDate(day: 18, hour: 19, minute: 0),
                intentSnapshot: qadaFastIntent
            )
        ]

        let snapshot = PlansSurfaceProvider().plansSurfaceSnapshot(
            defaults: defaults,
            settings: settings,
            upcomingDays: [qadaDay, adjustedDay],
            overrideDateKeys: [adjustedDay.dateKey],
            qadaBacklogState: QadaBacklogState(trackingStartDateKey: qadaDay.dateKey, baselineOwed: 3),
            fastLogEntries: fastEntries
        )

        #expect(snapshot.defaultMorningPlanSummary.wakeRelation == "45 min before Fajr")
        #expect(snapshot.defaultMorningPlanSummary.followUp == "Off")
        #expect(snapshot.defaultMorningPlanSummary.fastingDaySupport == "Iftar support on")
        #expect(snapshot.configuredPlansSnapshot.upcomingSpecialMornings.count == 2)
        #expect(snapshot.qadaProgress.completed == 1)
        #expect(snapshot.qadaProgress.remaining == 2)
    }

    @Test
    func calendarPlanningProviderUsesCanonicalDuplicateBoundary() {
        let activeDay = makeActiveDay(
            day: 20,
            context: .fasting,
            supportingTags: [.whiteDays],
            provenances: [Self.manualProvenance(label: "White Days")]
        )
        let activeWindow = makeActiveWindowSnapshot(days: [activeDay])
        let provider = CalendarPlanningProvider()
        let dependencies = CalendarPlanningProvider.Dependencies(
            activeWindowSnapshot: activeWindow,
            fastTagSelections: [:],
            provenance: { _, _ in [] },
            activeDay: { _, _ in nil },
            tagPreviewResult: { _, _, _, _ in .empty }
        )

        let activeStatus = provider.duplicateStatus(
            for: activeDay.date,
            timeZone: .current,
            dependencies: dependencies
        )
        let availableStatus = provider.duplicateStatus(
            for: makeDate(day: 21, hour: 0, minute: 0),
            timeZone: .current,
            dependencies: dependencies
        )

        switch activeStatus {
        case .active(let provenances, let existingDay):
            #expect(provenances == activeDay.provenances)
            #expect(existingDay.dateKey == activeDay.dateKey)
        case .available:
            Issue.record("Expected active duplicate status for existing day.")
        }

        switch availableStatus {
        case .available:
            #expect(Bool(true))
        case .active:
            Issue.record("Expected available duplicate status for open day.")
        }
    }

    @Test
    @MainActor
    func completionCommandGatewayWritesPrayerAndFastEditsThroughTypedIntents() {
        let suiteName = "CompletionCommandGatewayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let fajrStore = FajrLogStore(defaults: defaults)
        let fastStore = FastLogStore(defaults: defaults)
        let gateway = CompletionCommandGateway(
            fajrLogStore: fajrStore,
            fastLogStore: fastStore
        )
        let dateKey = dayKey(day: 13)

        gateway.perform(.setPrayerStatus(dateKey: dateKey, status: .completed), now: makeDate(day: 13, hour: 6, minute: 0))
        gateway.perform(.setFastStatus(dateKey: dateKey, status: .notCompleted, intentSnapshot: qadaFastIntent), now: makeDate(day: 13, hour: 20, minute: 0))

        #expect(fajrStore.status(for: dateKey) == .completed)
        #expect(fastStore.status(for: dateKey) == .missed)
        #expect(fastStore.entry(for: dateKey)?.intentSnapshot == qadaFastIntent)

        gateway.perform(.clearPrayerStatus(dateKey: dateKey))
        gateway.perform(.clearFastStatus(dateKey: dateKey))

        #expect(fajrStore.status(for: dateKey) == .unknown)
        #expect(fastStore.status(for: dateKey) == .unknown)

        defaults.removePersistentDomain(forName: suiteName)
    }

    private static var defaultDailyProvenance: ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: DateHelpers.stableUUID(from: "default-daily"),
            groupID: nil,
            label: "Daily morning plan",
            stopSeriesLabel: nil,
            isExplicitOneOff: false,
            sourceOrigin: .defaultDailyPlan
        )
    }

    private static func manualProvenance(label: String) -> ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: UUID(),
            groupID: nil,
            label: label,
            stopSeriesLabel: "Stop \(label)",
            isExplicitOneOff: true,
            sourceOrigin: .manualSingleDay
        )
    }

    private func makeActiveDay(
        day: Int,
        context: MorningContextType,
        supportingTags: [DayTag],
        provenances: [ResolvedScheduledDateProvenance],
        dailyCompletion: DailyCompletionSnapshot? = nil,
        scheduledEvents: [ScheduledEvent] = []
    ) -> ActiveAlarmDay {
        let date = makeDate(day: day, hour: 0, minute: 0)
        let fajr = makeDate(day: day, hour: 5, minute: 30)
        let wake = makeDate(day: day, hour: 5, minute: 0)
        let schedule = DaySchedule(
            date: date,
            fajrDate: fajr,
            maghribDate: makeDate(day: day, hour: 18, minute: 30),
            wakeDate: wake,
            reminderDate: makeDate(day: day, hour: 4, minute: 50),
            boundaryDate: fajr,
            iftarDate: makeDate(day: day, hour: 18, minute: 30),
            locationDescription: "Toronto",
            offsetMinutes: 30,
            calculationMethodName: "Muslim World League",
            timeZone: .current
        )

        let effectiveConfig = EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: true,
            fajrEnabled: true,
            iftarEnabled: false,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 290,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .adhanSoft,
            iftarDelivery: .off,
            iftarSoundChoice: .systemDefault,
            hasOverrides: false
        )

        let resolvedContext = ResolvedDayContext(
            primaryContext: context,
            secondaryContexts: [],
            supportingTags: supportingTags,
            explanation: ContextExplanation(summary: "Context test", details: [])
        )

        return ActiveAlarmDay(
            date: date,
            dateKey: dayKey(day: day),
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: supportingTags.contains(.ramadan),
            isExplicitOneOff: provenances.allSatisfy(\.isExplicitOneOff),
            tagResult: .empty,
            primaryDisplay: PrimaryDisplay(time: wake, kind: .suhoor),
            sourceSummaryText: provenances.map(\.label).joined(separator: " • "),
            resolvedDayContext: resolvedContext,
            scheduledEvents: scheduledEvents,
            dailyCompletion: dailyCompletion
        )
    }

    private func dayKey(day: Int) -> String {
        DateHelpers.dayIdentifier(for: makeDate(day: day, hour: 0, minute: 0), timeZone: .current)
    }

    private var voluntaryFastIntent: FastIntentSnapshot {
        FastIntentSnapshot(primaryIntent: .voluntary, secondaryTags: [])
    }

    private var qadaFastIntent: FastIntentSnapshot {
        FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
    }

    private func makeDate(day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "America/Toronto")
        return Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
    }

    private func makeResolvedDay(
        day: Int,
        context: MorningContextType,
        supportingTags: [DayTag],
        prayerStatus: PrayerCompletionStatus,
        fastStatus: FastCompletionStatus,
        intentSnapshot: FastIntentSnapshot? = nil,
        qadaEffect: QadaEffect = .none
    ) -> ResolvedDaySnapshot {
        let date = makeDate(day: day, hour: 0, minute: 0)
        let prayerWindow = DailyPrayerWindow(
            date: date,
            fajrStart: makeDate(day: day, hour: 5, minute: 30),
            fajrEnd: makeDate(day: day, hour: 6, minute: 45),
            maghrib: makeDate(day: day, hour: 18, minute: 30)
        )
        let resolvedContext = ResolvedDayContext(
            primaryContext: context,
            secondaryContexts: [],
            supportingTags: supportingTags,
            explanation: .empty
        )
        let selectedPlan = MorningPlan(
            id: "plan-\(day)",
            title: "Daily plan",
            kind: .defaultDaily,
            wakeAnchorType: .fajrStart,
            wakeDelta: WakeDelta(relation: .before, minutes: 30),
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: fastStatus != .notRequired
        )
        let behavior = MorningBehaviorProfile(
            wakeAnchorType: .fajrStart,
            wakeDelta: WakeDelta(relation: .before, minutes: 30),
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            wakeFollowUpEnabled: false,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: fastStatus != .notRequired
        )
        let decisionLog = RuleDecisionLog(
            dateKey: dayKey(day: day),
            resolverVersion: 1,
            decisionHash: "decision-\(day)",
            prayerWindow: prayerWindow,
            candidateContexts: [context],
            resolvedDayContext: resolvedContext,
            candidatePlans: [],
            selectedPlanID: selectedPlan.id,
            precedenceReason: "test",
            resolvedBehaviorProfile: behavior,
            resolvedAnchor: WakeAnchor(type: .fajrStart, date: prayerWindow.fajrStart, providerNotes: nil),
            resolvedDelta: WakeDelta(relation: .before, minutes: 30),
            resolvedWakeTime: makeDate(day: day, hour: 5, minute: 0),
            resolvedSequenceTemplate: WakeSequenceTemplate(id: "sequence-\(day)", name: "Test", steps: []),
            materializedEvents: [],
            compatibilityNotes: []
        )
        let dailyCompletion = DailyCompletionSnapshot(
            dateKey: dayKey(day: day),
            prayer: PrayerCompletionState(
                status: prayerStatus,
                updatedAt: makeDate(day: day, hour: 6, minute: 0),
                source: "test"
            ),
            fast: FastCompletionState(
                status: fastStatus,
                intentSnapshot: intentSnapshot,
                updatedAt: makeDate(day: day, hour: 19, minute: 0),
                source: "test"
            ),
            qadaEffect: qadaEffect,
            wakeSupport: .none,
            outstandingAction: nil,
            isMeaningfullyResolved: prayerStatus != .unknown && fastStatus != .unknown
        )

        return ResolvedDaySnapshot(
            date: date,
            dateKey: dayKey(day: day),
            prayerWindow: prayerWindow,
            resolvedDayContext: resolvedContext,
            selectedPlan: selectedPlan,
            resolvedBehaviorProfile: behavior,
            materializedEvents: [],
            decisionLog: decisionLog,
            completionRecords: [],
            dailyCompletion: dailyCompletion,
            completionSummary: nil
        )
    }

    private func makeActiveWindowSnapshot(days: [ActiveAlarmDay]) -> ActiveAlarmWindowSnapshot {
        ActiveAlarmWindowSnapshot(
            generatedAt: makeDate(day: 1, hour: 0, minute: 0),
            visibleDays: days,
            scheduledDays: days,
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )
    }

    private func makeNextWakeSummary(for day: ActiveAlarmDay) -> NextWakeEventSummary {
        NextWakeEventSummary(
            day: day,
            event: ScheduledEvent(
                id: "\(day.dateKey).wakeAlarm",
                type: .wakeAlarm,
                dateKey: day.dateKey,
                fireDate: day.schedule.wakeDate,
                relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: -30),
                isUserVisible: true,
                affectsCompletion: true,
                deliveryKinds: [.wake]
            ),
            priority: 0
        )
    }
}
