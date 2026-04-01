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
        #expect(selectedDay.primaryItems.contains(where: { $0.label == "Supported end (sunrise proxy)" }))
        #expect(selectedDay.comparisonItem?.label == "Fasting wake")
        #expect(selectedDay.statusText == "Changed for this date")
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
        #expect(snapshot.supportSummaries.contains(where: { $0.title == "Steadier rhythm" }))
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
        #expect(selectedDay.primaryItems.contains(where: { $0.label == "Current supported end" }))
    }

    @Test
    func datasetProjectionSupportsCheapSelectionUpdates() {
        let days = makeDays(count: 30)
        let dataset = provider.buildDataset(
            period: .thirtyDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let firstSnapshot = provider.surfaceSnapshot(
            dataset: dataset,
            requestedOverlay: .myWake,
            selectedDateKey: days[2].dateKey,
            overlaySeries: [],
            now: days[0].date,
            timeZone: .current
        )
        let secondSnapshot = provider.surfaceSnapshot(
            dataset: dataset,
            requestedOverlay: .myWake,
            selectedDateKey: days[8].dateKey,
            overlaySeries: [],
            now: days[0].date,
            timeZone: .current
        )

        #expect(firstSnapshot.points.count == secondSnapshot.points.count)
        #expect(firstSnapshot.points.map(\.dateKey) == secondSnapshot.points.map(\.dateKey))
        #expect(firstSnapshot.selectedDateKey == days[2].dateKey)
        #expect(secondSnapshot.selectedDateKey == days[8].dateKey)
    }

    @Test
    func yearlyChartKeepsDailyPointsButUsesReducedRenderSeries() {
        let days = makeDays(count: 365)
        let dataset = provider.buildDataset(
            period: .oneYear,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let snapshot = provider.surfaceSnapshot(
            dataset: dataset,
            requestedOverlay: .myWake,
            selectedDateKey: days[150].dateKey,
            overlaySeries: [],
            now: days[0].date,
            timeZone: .current
        )

        #expect(snapshot.points.count == 365)
        #expect(snapshot.renderPoints.count < snapshot.points.count)
        #expect(snapshot.renderPoints.contains(where: { $0.dateKey == days[0].dateKey }))
        #expect(snapshot.renderPoints.contains(where: { $0.dateKey == days[364].dateKey }))
    }

    @Test
    func compactSnapshotStaysOnNarrowSevenDayPath() {
        let days = makeDays(count: 30)
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: days[0].date,
            timeZone: .current
        )

        #expect(compact.period == .sevenDays)
        #expect(compact.points.count == 7)
        #expect(compact.chart.activeOverlay == .myWake)
        #expect(compact.compactInsight.isEmpty == false)
        #expect(compact.summary.primaryText.isEmpty == false)
        #expect(compact.selectedDay.relativeLabel.isEmpty == false)
        #expect(compact.compactYTicks.count == 4)
    }

    @Test
    func compactSnapshotSelectsTomorrowAfterTodayWakeHasPassed() {
        let days = makeDays(count: 7)
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let now = makeDate(dayOffset: 0, hour: 6, minute: 30)
        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: now,
            timeZone: .current
        )

        #expect(compact.selectedDateKey == days[1].dateKey)
        #expect(compact.selectedDay.relativeLabel == "TOMORROW")
    }

    @Test
    func compactSnapshotPrefersTenMinuteScaleWhenItFits() {
        let days = (0..<7).map { offset in
            makeDay(
                dayOffset: offset,
                wakeHour: 5,
                wakeMinute: 10,
                fajrStartHour: 5,
                fajrStartMinute: 0,
                boundaryHour: 5,
                boundaryMinute: 20
            )
        }
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: days[0].date,
            timeZone: .current
        )

        #expect(compact.compactYTicks.count == 4)
        #expect(compact.compactYTicks[1].minutes - compact.compactYTicks[0].minutes == 10)
    }

    @Test
    func compactSnapshotUsesSmallestValidTensOnlyScale() {
        let days = (0..<7).map { offset in
            makeDay(
                dayOffset: offset,
                wakeHour: 5,
                wakeMinute: 25,
                fajrStartHour: 5,
                fajrStartMinute: 5,
                boundaryHour: 5,
                boundaryMinute: 35
            )
        }
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: days[0].date,
            timeZone: .current
        )

        let tickMinutes = compact.compactYTicks.map(\.minutes)
        #expect(compact.compactYTicks.count == 4)
        #expect(compact.compactYTicks[1].minutes - compact.compactYTicks[0].minutes == 20)
        #expect(tickMinutes == [280, 300, 320, 340])
        #expect(tickMinutes.allSatisfy { $0 % 10 == 0 })
    }

    @Test
    func compactSnapshotNeverProducesFiveBasedTickMinutes() {
        let days = [
            makeDay(dayOffset: 0, wakeHour: 5, wakeMinute: 43, fajrStartHour: 5, fajrStartMinute: 7, boundaryHour: 6, boundaryMinute: 11),
            makeDay(dayOffset: 1, wakeHour: 5, wakeMinute: 49, fajrStartHour: 5, fajrStartMinute: 12, boundaryHour: 6, boundaryMinute: 18),
            makeDay(dayOffset: 2, wakeHour: 5, wakeMinute: 55, fajrStartHour: 5, fajrStartMinute: 18, boundaryHour: 6, boundaryMinute: 24),
            makeDay(dayOffset: 3, wakeHour: 6, wakeMinute: 1, fajrStartHour: 5, fajrStartMinute: 24, boundaryHour: 6, boundaryMinute: 30),
            makeDay(dayOffset: 4, wakeHour: 6, wakeMinute: 7, fajrStartHour: 5, fajrStartMinute: 29, boundaryHour: 6, boundaryMinute: 37),
            makeDay(dayOffset: 5, wakeHour: 6, wakeMinute: 12, fajrStartHour: 5, fajrStartMinute: 34, boundaryHour: 6, boundaryMinute: 42),
            makeDay(dayOffset: 6, wakeHour: 6, wakeMinute: 18, fajrStartHour: 5, fajrStartMinute: 39, boundaryHour: 6, boundaryMinute: 48)
        ]
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: days[0].date,
            timeZone: .current
        )

        #expect(compact.compactYTicks.map(\.minutes).allSatisfy { $0 % 10 == 0 })
    }

    @Test
    func compactSnapshotUsesExtraBottomRowAndBufferToAvoidInflatedStepSizes() {
        let days = (0..<7).map { offset in
            makeDay(
                dayOffset: offset,
                wakeHour: 4,
                wakeMinute: 40,
                fajrStartHour: 5,
                fajrStartMinute: 25,
                boundaryHour: 7,
                boundaryMinute: 5
            )
        }
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: days,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: days[0].date,
            timeZone: .current
        )

        let tickMinutes = compact.compactYTicks.map(\.minutes)
        let step = compact.compactYTicks[1].minutes - compact.compactYTicks[0].minutes
        let visibleEnd = compact.compactYTicks.last!.minutes + step
        #expect(compact.compactYTicks.count == 4)
        #expect(step == 50)
        #expect(tickMinutes == [250, 300, 350, 400])
        #expect(compact.compactChartDomain.lowerBound <= 270)
        #expect(visibleEnd >= 435)
    }

    @Test
    func compactSnapshotDefaultsToThirtyMinuteTicksWhenNoDataExists() {
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [],
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: Date(),
            timeZone: .current
        )

        #expect(compact.compactYTicks.map(\.minutes) == [270, 300, 330, 360])
    }

    @Test
    func compactSnapshotReportsSkippedTomorrowAlarm() {
        let first = makeDay(dayOffset: 0)
        let skippedTomorrow = makeDay(dayOffset: 1, skipDay: true)
        let remaining = (2..<7).map { makeDay(dayOffset: $0) }
        let dataset = provider.buildDataset(
            period: .sevenDays,
            activeDays: [first, skippedTomorrow] + remaining,
            overrideDateKeys: [],
            timeZone: .current
        )

        let compact = provider.compactSnapshot(
            dataset: dataset,
            now: makeDate(dayOffset: 0, hour: 6, minute: 30),
            timeZone: .current
        )

        #expect(compact.selectedDay.dateKey == skippedTomorrow.dateKey)
        #expect(compact.summary.primaryText == "Tomorrow's alarm is off for this date.")
        #expect(compact.selectedDay.timeMain == "Off")
        #expect(compact.selectedDay.iconName == "bell.slash.fill")
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
        truth: FajrWindowBoundaryTruth = .sunriseProxy,
        skipDay: Bool = false
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
