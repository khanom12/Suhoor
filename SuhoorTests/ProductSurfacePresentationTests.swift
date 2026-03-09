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
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Adjusted morning" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Qada" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Fasting" }))
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
            #expect(presentation.title == "Did you complete the Qada fast?")
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
            wakeProgress: .empty
        )

        #expect(snapshot.fajrTodaySummary == "Made Fajr")
        #expect(snapshot.fastTodaySummary == "Completed")
        #expect(snapshot.qadaProgress.remaining == 1)
        #expect(snapshot.wakeProgress == .empty)
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
        dailyCompletion: DailyCompletionSnapshot? = nil
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
}
