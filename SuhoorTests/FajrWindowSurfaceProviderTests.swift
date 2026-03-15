import Foundation
import Testing
@testable import Suhoor

@Suite
struct FajrWindowSurfaceProviderTests {
    private let provider = FajrWindowSurfaceProvider()

    @Test
    func pointGenerationSupportsSevenThirtyAndYearPeriods() {
        let days = makeDays(count: 400)

        let weekly = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .myWake,
            selectedDateKey: nil,
            activeDays: days,
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )
        let monthly = provider.snapshot(
            period: .thirtyDays,
            requestedOverlay: .myWake,
            selectedDateKey: nil,
            activeDays: days,
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )
        let yearly = provider.snapshot(
            period: .oneYear,
            requestedOverlay: .myWake,
            selectedDateKey: nil,
            activeDays: days,
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )

        #expect(weekly.points.count == 7)
        #expect(monthly.points.count == 30)
        #expect(yearly.points.count == 365)
        #expect(yearly.points.first?.dateKey == days.first?.dateKey)
    }

    @Test
    func derivedMinutesPreserveEarlierHigherOrdering() {
        let day = makeDay(
            dayOffset: 0,
            wakeHour: 5,
            wakeMinute: 0,
            fajrStartHour: 5,
            fajrStartMinute: 30,
            boundaryHour: 6,
            boundaryMinute: 45,
            truth: .sunriseProxy
        )

        let snapshot = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .myWake,
            selectedDateKey: nil,
            activeDays: [day],
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )

        let point = try #require(snapshot.points.first)
        #expect(point.primaryWakeMinutes < point.fajrStartMinutes)
        #expect(point.fajrStartMinutes < point.fajrEndOrBoundaryMinutes)
        #expect(snapshot.chartDomain.lowerBound <= point.primaryWakeMinutes)
        #expect(snapshot.chartDomain.upperBound >= point.fajrEndOrBoundaryMinutes)
    }

    @Test
    func overlayAvailabilityIncludesFastingOnlyWhenDistinctPreviewExists() {
        let first = makeDay(dayOffset: 0)
        let second = makeDay(dayOffset: 1)
        let comparison = makeDay(dayOffset: 1, wakeHour: 4, wakeMinute: 35)

        let noDistinctOverlay = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .compareFasting,
            selectedDateKey: second.dateKey,
            activeDays: [first, second],
            overrideDateKeys: [],
            comparisonDay: { day, overlay in
                guard overlay == .compareFasting else { return nil }
                return day
            }
        )

        let distinctOverlay = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .compareFasting,
            selectedDateKey: second.dateKey,
            activeDays: [first, second],
            overrideDateKeys: [],
            comparisonDay: { day, overlay in
                guard overlay == .compareFasting, day.dateKey == second.dateKey else { return nil }
                return comparison
            }
        )

        #expect(noDistinctOverlay.activeOverlay == .myWake)
        #expect(noDistinctOverlay.availableOverlays == [.myWake, .compareSafe])
        #expect(distinctOverlay.activeOverlay == .compareFasting)
        #expect(distinctOverlay.availableOverlays.contains(.compareFasting))
    }

    @Test
    func saferWakeAnchorsLeadToLowerBoundary() {
        let day = makeDay(
            dayOffset: 0,
            wakeHour: 5,
            wakeMinute: 0,
            fajrStartHour: 5,
            fajrStartMinute: 30,
            boundaryHour: 6,
            boundaryMinute: 45
        )

        let snapshot = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .compareSafe,
            selectedDateKey: day.dateKey,
            activeDays: [day],
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )

        let point = try #require(snapshot.points.first)
        #expect(snapshot.activeOverlay == .compareSafe)
        #expect(point.saferWakeMinutes == ((6 * 60) + 15))
        #expect(point.saferWakeMinutes == point.fajrEndOrBoundaryMinutes - 30)
    }

    @Test
    func selectedDaySnapshotUsesBoundaryTruthAndComparisonValues() {
        let day = makeDay(dayOffset: 0)
        let fastingComparison = makeDay(dayOffset: 0, wakeHour: 4, wakeMinute: 25)

        let snapshot = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .compareFasting,
            selectedDateKey: day.dateKey,
            activeDays: [day],
            overrideDateKeys: [day.dateKey],
            comparisonDay: { _, overlay in
                overlay == .compareFasting ? fastingComparison : nil
            }
        )

        let selectedDay = try #require(snapshot.selectedDay)
        #expect(selectedDay.boundaryTruth == .sunriseProxy)
        #expect(selectedDay.primaryItems.contains(where: { $0.label == "Fajr end (sunrise proxy)" }))
        #expect(selectedDay.comparisonItem?.label == "Fasting comparison")
        #expect(selectedDay.statusText == "Adjusted for this date")
    }

    @Test
    func yearSummaryIncludesSteadierStrategyGuidance() {
        let days = makeDays(count: 365)

        let snapshot = provider.snapshot(
            period: .oneYear,
            requestedOverlay: .myWake,
            selectedDateKey: nil,
            activeDays: days,
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )

        #expect(snapshot.supportSummaries.contains(where: { $0.id == "year-strategy" }))
        #expect(snapshot.supportSummaries.contains(where: { $0.title == "Steadier strategy" }))
    }

    @Test
    func boundaryFallbackUsesSupportedBoundaryWhenPrayerWindowLacksEnd() {
        let fallbackDay = makeDay(
            dayOffset: 0,
            wakeHour: 5,
            wakeMinute: 0,
            fajrStartHour: 5,
            fajrStartMinute: 30,
            boundaryHour: 5,
            boundaryMinute: 30,
            truth: .supportedFallback
        )

        let snapshot = provider.snapshot(
            period: .sevenDays,
            requestedOverlay: .myWake,
            selectedDateKey: fallbackDay.dateKey,
            activeDays: [fallbackDay],
            overrideDateKeys: [],
            comparisonDay: { _, _ in nil }
        )

        let point = try #require(snapshot.points.first)
        let selectedDay = try #require(snapshot.selectedDay)
        #expect(point.boundaryTruth == .supportedFallback)
        #expect(selectedDay.boundaryTruth == .supportedFallback)
        #expect(selectedDay.primaryItems.contains(where: { $0.label == "Supported boundary" }))
    }

    private func makeDays(count: Int) -> [ActiveAlarmDay] {
        (0..<count).map { offset in
            makeDay(dayOffset: offset)
        }
    }

    private func makeDay(
        dayOffset: Int,
        wakeHour: Int = 5,
        wakeMinute: Int = 0,
        fajrStartHour: Int = 5,
        fajrStartMinute: Int = 30,
        boundaryHour: Int = 6,
        boundaryMinute: Int = 45,
        truth: FajrWindowBoundaryTruth = .sunriseProxy
    ) -> ActiveAlarmDay {
        let date = makeDate(dayOffset: dayOffset, hour: 0, minute: 0)
        let wakeDate = makeDate(dayOffset: dayOffset, hour: wakeHour, minute: wakeMinute)
        let fajrStart = makeDate(dayOffset: dayOffset, hour: fajrStartHour, minute: fajrStartMinute)
        let boundaryDate = makeDate(dayOffset: dayOffset, hour: boundaryHour, minute: boundaryMinute)
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: .current)

        let schedule = DaySchedule(
            date: date,
            fajrDate: fajrStart,
            maghribDate: makeDate(dayOffset: dayOffset, hour: 18, minute: 30),
            wakeDate: wakeDate,
            reminderDate: makeDate(dayOffset: dayOffset, hour: 4, minute: 45),
            boundaryDate: truth == .supportedFallback ? boundaryDate : fajrStart,
            iftarDate: makeDate(dayOffset: dayOffset, hour: 18, minute: 30),
            locationDescription: "Toronto",
            offsetMinutes: Int(round(fajrStart.timeIntervalSince(wakeDate) / 60)),
            calculationMethodName: "Muslim World League",
            timeZone: .current
        )

        let prayerWindow = DailyPrayerWindow(
            date: date,
            fajrStart: fajrStart,
            fajrEnd: truth == .supportedFallback ? nil : boundaryDate,
            maghrib: makeDate(dayOffset: dayOffset, hour: 18, minute: 30)
        )

        let delta = WakeDelta(
            relation: wakeDate <= fajrStart ? .before : .after,
            minutes: Int(round(abs(fajrStart.timeIntervalSince(wakeDate)) / 60))
        )
        let behavior = MorningBehaviorProfile(
            wakeAnchorType: .fajrStart,
            wakeDelta: delta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            wakeFollowUpEnabled: false,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: false
        )
        let resolvedContext = ResolvedDayContext(
            primaryContext: .standard,
            secondaryContexts: [],
            supportingTags: [.dailyPlan],
            explanation: .empty
        )
        let decisionLog = RuleDecisionLog(
            dateKey: dateKey,
            resolverVersion: 1,
            decisionHash: "test-\(dayOffset)",
            prayerWindow: prayerWindow,
            candidateContexts: [.standard],
            resolvedDayContext: resolvedContext,
            candidatePlans: [],
            selectedPlanID: "default",
            precedenceReason: "test",
            resolvedBehaviorProfile: behavior,
            resolvedAnchor: WakeAnchor(type: .fajrStart, date: fajrStart, providerNotes: nil),
            resolvedDelta: delta,
            resolvedWakeTime: wakeDate,
            resolvedSequenceTemplate: WakeSequenceTemplate(id: "default", name: "Default", steps: []),
            materializedEvents: [],
            compatibilityNotes: []
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
            suhoorOffsetMinutes: delta.minutes,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 15,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .adhanSoft,
            iftarDelivery: .off,
            iftarSoundChoice: .systemDefault,
            hasOverrides: false
        )

        return ActiveAlarmDay(
            date: date,
            dateKey: dateKey,
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: [defaultDailyProvenance],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: PrimaryDisplay(time: wakeDate, kind: .suhoor),
            sourceSummaryText: defaultDailyProvenance.label,
            resolvedDayContext: resolvedContext,
            scheduledEvents: [],
            decisionLog: decisionLog
        )
    }

    private var defaultDailyProvenance: ResolvedScheduledDateProvenance {
        ResolvedScheduledDateProvenance(
            sourceID: UUID(),
            groupID: nil,
            label: "Daily plan",
            stopSeriesLabel: nil,
            isExplicitOneOff: false,
            sourceOrigin: .defaultDailyPlan
        )
    }

    private func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let startComponents = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 3,
            day: 1,
            hour: hour,
            minute: minute
        )
        let startDate = calendar.date(from: startComponents) ?? .distantPast
        return calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
    }
}
