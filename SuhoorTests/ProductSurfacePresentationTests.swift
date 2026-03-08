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
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Day-specific morning" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Qada" }))
        #expect(snapshot.upcomingSpecialMornings.contains(where: { $0.title == "Fasting" }))
        #expect(snapshot.qadaSummary == "2 completed · 4 remaining")
    }

    @Test
    func homeSupportCardPrefersBlockingIssuesOverFastingAndObservances() {
        let currentDay = makeActiveDay(
            day: 5,
            context: .fasting,
            supportingTags: [.ramadan],
            provenances: [defaultDailyProvenance]
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

        let result = ProductSurfacePresentation.homeSupportCard(
            currentDay: currentDay,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: components,
            dismissedWarnings: []
        )

        #expect(result == .blockingIssue(.location))
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

        #expect(snapshot.summaryTitle == "1 recent wake event fired")
        #expect(snapshot.recentActivityLines.count == 3)
        #expect(snapshot.recentActivityLines.allSatisfy { !$0.contains("fajr") })
        #expect(snapshot.emptyStateText == nil)
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
        provenances: [ResolvedScheduledDateProvenance]
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
            dateKey: DateHelpers.dayIdentifier(for: date, timeZone: .current),
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: supportingTags.contains(.ramadan),
            isExplicitOneOff: provenances.allSatisfy(\.isExplicitOneOff),
            tagResult: .empty,
            primaryDisplay: PrimaryDisplay(time: wake, kind: .suhoor),
            sourceSummaryText: provenances.map(\.label).joined(separator: " • "),
            resolvedDayContext: resolvedContext
        )
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
