import Foundation
import Testing
@testable import Suhoor

@Suite
struct AlarmDayDetailPresentationTests {
    @Test
    func usesUsualPlanLanguageForDefaultDates() {
        let day = makeActiveDay(
            day: 17,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance]
        )

        let presentation = AlarmDayDetailPresentation(
            day: day,
            computedIntentSelection: .default,
            warnings: [],
            draftSelection: .defaultPlan,
            draftAnchor: .fajrStart,
            draftDeltaMinutes: 30,
            draftFixedWakeMinutes: 300
        )

        #expect(presentation.adjustStatusText == "Using your usual plan")
        #expect(presentation.why.statusTitle == "Using your usual morning plan")
        #expect(presentation.why.rows.map(\.title) == ["Usual plan"])
        #expect(presentation.why.rows.first?.detail.contains("Before Fajr") == true)
    }

    @Test
    func showsCurrentAndUsualSummariesForAdjustedDates() {
        let day = makeActiveDay(
            day: 18,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance]
        )

        let presentation = AlarmDayDetailPresentation(
            day: day,
            computedIntentSelection: .default,
            warnings: [],
            draftSelection: .inFajr,
            draftAnchor: .fajrEnd,
            draftDeltaMinutes: 40,
            draftFixedWakeMinutes: 300
        )

        #expect(presentation.adjustStatusText == "Adjusted for this date")
        #expect(presentation.why.statusTitle == "This date is adjusted")
        #expect(presentation.why.rows.prefix(2).map(\.title) == ["Current", "Usual plan"])
        #expect(presentation.why.rows.first?.detail == "During Fajr, 40 min before Fajr ends")
        #expect(presentation.why.rows.dropFirst().first?.detail == "Before Fajr, 30 min before Fajr")
    }

    @Test
    func clarifiesSkippedDates() {
        let day = makeActiveDay(
            day: 19,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance],
            skipDay: true
        )

        let presentation = AlarmDayDetailPresentation(
            day: day,
            computedIntentSelection: .default,
            warnings: [],
            draftSelection: .defaultPlan,
            draftAnchor: .fajrStart,
            draftDeltaMinutes: 30,
            draftFixedWakeMinutes: 300
        )

        #expect(presentation.heroSummaryText == "No wake on this date")
        #expect(presentation.why.statusTitle == "No wake on this date")
        #expect(presentation.why.rows.first?.detail == "No wake on this date.")
    }

    @Test
    func remapsDefaultPlanSourceCopy() {
        let day = makeActiveDay(
            day: 20,
            context: .standard,
            supportingTags: [.dailyPlan],
            provenances: [Self.defaultDailyProvenance],
            sourceSummaryTextOverride: "Provided by your daily morning plan"
        )

        let presentation = AlarmDayDetailPresentation(
            day: day,
            computedIntentSelection: .default,
            warnings: [],
            draftSelection: .defaultPlan,
            draftAnchor: .fajrStart,
            draftDeltaMinutes: 30,
            draftFixedWakeMinutes: 300
        )

        #expect(presentation.advancedSourceText == "Based on your usual morning plan")
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

    private func makeActiveDay(
        day: Int,
        context: MorningContextType,
        supportingTags: [DayTag],
        provenances: [ResolvedScheduledDateProvenance],
        skipDay: Bool = false,
        sourceSummaryTextOverride: String? = nil
    ) -> ActiveAlarmDay {
        let date = makeDate(day: day, hour: 0, minute: 0)
        let fajr = makeDate(day: day, hour: 5, minute: 30)
        let fajrEnd = makeDate(day: day, hour: 6, minute: 45)
        let wake = makeDate(day: day, hour: 5, minute: 0)
        let wakeDelta = WakeDelta(relation: .before, minutes: 30)
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
            skipDay: skipDay,
            suhoorEnabled: true,
            reminderEnabled: true,
            fajrEnabled: true,
            iftarEnabled: false,
            defaultWakeRule: DefaultAlarmConfig.default.defaultWakeRule,
            resolvedWakeRule: DefaultAlarmConfig.default.defaultWakeRule,
            wakeRuleWasOverridden: false,
            tahajjudRefinement: false,
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
            hasOverrides: skipDay
        )
        let resolvedContext = ResolvedDayContext(
            primaryContext: context,
            secondaryContexts: [],
            supportingTags: supportingTags,
            explanation: ContextExplanation(summary: "Context test", details: [])
        )
        let prayerWindow = DailyPrayerWindow(
            date: date,
            fajrStart: fajr,
            fajrEnd: fajrEnd,
            maghrib: makeDate(day: day, hour: 18, minute: 30)
        )
        let behavior = MorningBehaviorProfile(
            wakeAnchorType: .fajrStart,
            wakeDelta: wakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: !skipDay,
            wakeFollowUpEnabled: false,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: false,
            resolvedWakeState: .preFajr,
            plannedWakeState: .preFajr,
            latestWakeCapMinutesFromMidnight: nil,
            latestWakeCapApplied: false
        )
        let decisionLog = RuleDecisionLog(
            dateKey: dayKey(day: day),
            resolverVersion: 1,
            decisionHash: "decision-\(day)",
            prayerWindow: prayerWindow,
            candidateContexts: [context],
            resolvedDayContext: resolvedContext,
            candidatePlans: [],
            selectedPlanID: "plan-\(day)",
            precedenceReason: "test",
            resolvedBehaviorProfile: behavior,
            resolvedAnchor: WakeAnchor(type: .fajrStart, date: prayerWindow.fajrStart, providerNotes: nil),
            resolvedDelta: wakeDelta,
            candidateWakeTime: wake,
            resolvedWakeTime: wake,
            resolvedWakeState: .preFajr,
            plannedWakeState: .preFajr,
            latestWakeCapMinutesFromMidnight: nil,
            latestWakeCapApplied: false,
            resolvedSequenceTemplate: WakeSequenceTemplate(id: "sequence-\(day)", name: "Test", steps: []),
            materializedEvents: [],
            compatibilityNotes: []
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
            sourceSummaryText: sourceSummaryTextOverride ?? provenances.map(\.label).joined(separator: " • "),
            resolvedDayContext: resolvedContext,
            scheduledEvents: [],
            decisionLog: decisionLog,
            dailyCompletion: nil
        )
    }

    private func dayKey(day: Int) -> String {
        DateHelpers.dayIdentifier(for: makeDate(day: day, hour: 0, minute: 0), timeZone: .current)
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
