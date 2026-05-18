import Foundation
import Testing
@testable import Subh

@Suite
struct HijriCalendarServiceTests {
    @Test
    func dayOfMonthMappingUsesStartPlusOffset() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.DayMapping")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.DayMapping")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let map = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let day1 = service.gregorianDate(for: key, dayOfMonth: 1, monthMap: map, timeZone: timeZone)
        let day13 = service.gregorianDate(for: key, dayOfMonth: 13, monthMap: map, timeZone: timeZone)
        let day15 = service.gregorianDate(for: key, dayOfMonth: 15, monthMap: map, timeZone: timeZone)

        #expect(day1 != nil)
        #expect(day13 != nil)
        #expect(day15 != nil)
        if let day1 {
            let expected13 = calendar.date(byAdding: .day, value: 12, to: day1)
            let expected15 = calendar.date(byAdding: .day, value: 14, to: day1)
            #expect(day13 == expected13)
            #expect(day15 == expected15)
        }
    }

    @Test
    func monthAdjustmentsShiftResolvedStart() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.Adjustments")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.Adjustments")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let baseline = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)
        store.setAdjustment(for: key, offsetDays: 1)
        let plusOne = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)
        store.setAdjustment(for: key, offsetDays: -1)
        let minusOne = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)

        #expect(baseline != nil)
        #expect(plusOne != nil)
        #expect(minusOne != nil)
        if let baseline {
            #expect(plusOne?.resolvedStart == calendar.date(byAdding: .day, value: 1, to: baseline.resolvedStart))
            #expect(minusOne?.resolvedStart == calendar.date(byAdding: .day, value: -1, to: baseline.resolvedStart))
        }
    }

    @Test
    func nonRamadanMonthAdjustmentsShiftResolvedStart() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.NonRamadanAdjustments")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.NonRamadanAdjustments")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(
            baselineProvider: { hijriYear, timeZone in
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = timeZone
                guard hijriYear == 1447 else { return [] }
                let start = calendar.date(from: DateComponents(year: 2025, month: 7, day: 26))!
                return [
                    HijriMonthBaselineStart(
                        key: HijriYearMonth(hijriYear: 1447, month: .safar),
                        gregorianStartDate: start,
                        source: "Test",
                        generatedAt: nil
                    )
                ]
            },
            adjustmentStore: store
        )
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .safar)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let baseline = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .safar)
        store.setAdjustment(for: key, offsetDays: 1)
        let plusOne = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .safar)

        #expect(baseline != nil)
        #expect(plusOne != nil)
        if let baseline {
            #expect(plusOne?.resolvedStart == calendar.date(byAdding: .day, value: 1, to: baseline.resolvedStart))
        }
    }

    @Test
    func keyEventsResolveFromMonthStarts() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.KeyEvents")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.KeyEvents")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let map = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let muharramStart = map.resolvedStart(for: .muharram)?.resolvedStart
        let ramadanStart = map.resolvedStart(for: .ramadan)?.resolvedStart
        let shawwalStart = map.resolvedStart(for: .shawwal)?.resolvedStart
        let dhulHijjahStart = map.resolvedStart(for: .dhulHijjah)?.resolvedStart

        let ashura = service.dateForAshura(hijriYear: 1447, timeZone: timeZone)
        let whiteDays = service.datesForWhiteDays(hijriYear: 1447, month: .ramadan, timeZone: timeZone)
        let eidAlFitr = service.dateForEidAlFitr(hijriYear: 1447, timeZone: timeZone)
        let arafah = service.dateForArafah(hijriYear: 1447, timeZone: timeZone)
        let eidAlAdha = service.dateForEidAlAdha(hijriYear: 1447, timeZone: timeZone)

        if let muharramStart {
            #expect(ashura == calendar.date(byAdding: .day, value: 9, to: muharramStart))
        }
        #expect(whiteDays.count == 3)
        if let ramadanStart {
            #expect(whiteDays.first == calendar.date(byAdding: .day, value: 12, to: ramadanStart))
            #expect(whiteDays.last == calendar.date(byAdding: .day, value: 14, to: ramadanStart))
        }
        #expect(eidAlFitr == shawwalStart)
        if let dhulHijjahStart {
            #expect(arafah == calendar.date(byAdding: .day, value: 8, to: dhulHijjahStart))
            #expect(eidAlAdha == calendar.date(byAdding: .day, value: 9, to: dhulHijjahStart))
        }
    }

    @Test
    func dstSafeDayAdditionStaysAtLocalMidnight() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.DST")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.DST")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(
            baselineProvider: { _, timeZone in
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = timeZone
                let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8))!
                return [
                    HijriMonthBaselineStart(
                        key: HijriYearMonth(hijriYear: 1447, month: .ramadan),
                        gregorianStartDate: start,
                        source: "Test",
                        generatedAt: nil
                    )
                ]
            },
            adjustmentStore: store
        )
        let timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let map = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone)
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let day1 = service.gregorianDate(for: key, dayOfMonth: 1, monthMap: map, timeZone: timeZone)
        let day3 = service.gregorianDate(for: key, dayOfMonth: 3, monthMap: map, timeZone: timeZone)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day1Components = calendar.dateComponents([.hour, .minute], from: day1 ?? .distantPast)
        let day3Components = calendar.dateComponents([.hour, .minute], from: day3 ?? .distantPast)

        #expect(day1Components.hour == 0)
        #expect(day1Components.minute == 0)
        #expect(day3Components.hour == 0)
        #expect(day3Components.minute == 0)
    }

    @Test
    func adjustedReverseLookupUsesShiftedMonthBoundaries() {
        let suiteName = "HijriCalendarServiceTests.ReverseLookup"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let adjustedCalendar = AdjustedHijriCalendar(calendarService: service)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let baselineStart = adjustedCalendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: timeZone)
        #expect(baselineStart != nil)
        let probeDate = calendar.date(byAdding: .day, value: 5, to: baselineStart ?? .distantPast) ?? .distantPast
        let baselineComponents = adjustedCalendar.adjustedComponents(for: probeDate, timeZone: timeZone)
        #expect(baselineComponents?.month == .ramadan)
        #expect(baselineComponents?.day == 6)
        #expect(baselineComponents?.isDerivedFromBaseline == true)

        store.setAdjustment(for: key, offsetDays: 1)
        let shiftedComponents = adjustedCalendar.adjustedComponents(for: probeDate, timeZone: timeZone)
        #expect(shiftedComponents?.month == .ramadan)
        #expect(shiftedComponents?.day == 5)
        #expect(shiftedComponents?.isDerivedFromBaseline == true)
    }

    @Test
    func adjustedMonthStartPreviewReflectsStoredOffset() {
        let suiteName = "HijriCalendarServiceTests.Preview"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let adjustedCalendar = AdjustedHijriCalendar(calendarService: service)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .shawwal)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let baselinePreview = adjustedCalendar.monthStartPreview(for: key, timeZone: timeZone)
        store.setAdjustment(for: key, offsetDays: 1)
        let shiftedPreview = adjustedCalendar.monthStartPreview(for: key, timeZone: timeZone)

        #expect(baselinePreview != nil)
        #expect(shiftedPreview != nil)
        #expect(shiftedPreview?.offsetDays == 1)
        if let baselinePreview {
            #expect(shiftedPreview?.adjustedStart == calendar.date(byAdding: .day, value: 1, to: baselinePreview.adjustedStart))
        }
    }

    @Test
    func formattedHijriStringChangesWhenSupportedMonthIsAdjusted() {
        let suiteName = "HijriCalendarServiceTests.Formatter"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let adjustedCalendar = AdjustedHijriCalendar(calendarService: service)
        let formatter = HijriDateFormatter(adjustedHijriCalendar: adjustedCalendar)
        let timeZone = TimeZone.current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let baselineStart = adjustedCalendar.gregorianDate(for: key, dayOfMonth: 10, timeZone: timeZone)

        #expect(baselineStart != nil)
        let baselineText = formatter.string(from: baselineStart ?? .distantPast)
        store.setAdjustment(for: key, offsetDays: 1)
        let shiftedText = formatter.string(from: baselineStart ?? .distantPast)

        #expect(baselineText != shiftedText)
    }
}

@Suite
struct MonthPlanningPresentationTests {
    @Test
    func gregorianHorizonStartsWithCurrentMonthAndIncludesNextTwelve() {
        let timeZone = Self.timeZone
        let now = Self.makeDate(year: 2026, month: 5, day: 18, hour: 9, minute: 30, timeZone: timeZone)

        let months = MonthPlanningPresentation.gregorianMonthIdentities(
            now: now,
            count: MonthPlanningPresentation.horizonMonthCount,
            timeZone: timeZone
        )

        #expect(months.count == 13)
        #expect(months.first == .gregorian(year: 2026, month: 5))
        #expect(months.last == .gregorian(year: 2027, month: 5))
    }

    @Test
    func gregorianPickerUsesWakeActionabilityForCurrentMonthOnly() throws {
        let timeZone = Self.timeZone
        let now = Self.makeDate(year: 2026, month: 5, day: 18, hour: 5, minute: 0, timeZone: timeZone)
        let fixtureDays = [
            Self.makeActiveDay(year: 2026, month: 5, day: 17, wakeHour: 4, wakeMinute: 20, timeZone: timeZone),
            Self.makeActiveDay(year: 2026, month: 5, day: 18, wakeHour: 6, wakeMinute: 0, timeZone: timeZone),
            Self.makeActiveDay(year: 2026, month: 5, day: 19, wakeHour: 4, wakeMinute: 10, timeZone: timeZone)
        ]
        let byDateKey = Dictionary(uniqueKeysWithValues: fixtureDays.map { ($0.dateKey, $0) })

        let months = MonthPlanningPresentation.gregorianPickerMonths(
            now: now,
            timeZone: timeZone,
            activeDayProvider: { date in
                byDateKey[DateHelpers.dayIdentifier(for: date, timeZone: timeZone)]
            }
        )

        let current = try #require(months.first)
        let next = try #require(months.dropFirst().first)
        #expect(current.title == "May 2026")
        #expect(current.countText == "2 mornings left")
        #expect(current.availability.isAvailable)
        #expect(next.title == "June 2026")
        #expect(next.countText == "30 mornings")
    }

    @Test
    func currentMonthWithNoActionableMorningsStaysVisibleAsUnavailable() throws {
        let timeZone = Self.timeZone
        let now = Self.makeDate(year: 2026, month: 5, day: 18, hour: 5, minute: 0, timeZone: timeZone)
        let past = Self.makeActiveDay(year: 2026, month: 5, day: 18, wakeHour: 4, wakeMinute: 20, timeZone: timeZone)

        let months = MonthPlanningPresentation.gregorianPickerMonths(
            now: now,
            timeZone: timeZone,
            activeDayProvider: { date in
                DateHelpers.dayIdentifier(for: date, timeZone: timeZone) == past.dateKey ? past : nil
            }
        )

        let current = try #require(months.first)
        #expect(current.title == "May 2026")
        #expect(current.countText == "No remaining mornings")
        #expect(current.availability == .unavailable(reason: "No remaining mornings"))
    }

    @Test
    func detailSnapshotFiltersPastCurrentMonthMorningsAndOrdersDateLabelsByMode() throws {
        let timeZone = Self.timeZone
        let now = Self.makeDate(year: 2026, month: 5, day: 18, hour: 5, minute: 0, timeZone: timeZone)
        let past = Self.makeActiveDay(year: 2026, month: 5, day: 17, wakeHour: 4, wakeMinute: 20, timeZone: timeZone)
        let future = Self.makeActiveDay(year: 2026, month: 5, day: 21, wakeHour: 4, wakeMinute: 18, timeZone: timeZone)
        let gregorianIdentity = MonthPlanningMonthIdentity.gregorian(year: 2026, month: 5)
        let range = try #require(MonthPlanningPresentation.dateRange(for: gregorianIdentity, timeZone: timeZone))
        let hijriProvider: (Date, TimeZone) -> AdjustedHijriDateComponents? = { _, _ in
            AdjustedHijriDateComponents(
                hijriYear: 1447,
                month: .dhulHijjah,
                day: 4,
                monthTitle: "Dhul Hijjah",
                isDerivedFromBaseline: true
            )
        }

        let gregorianSnapshot = MonthPlanningPresentation.detailSnapshot(
            identity: gregorianIdentity,
            dateRange: range,
            activeDays: [past, future],
            now: now,
            timeZone: timeZone,
            entitlement: .plus,
            hijriComponentsProvider: hijriProvider
        )

        #expect(gregorianSnapshot.navigationTitle == "May 2026")
        #expect(gregorianSnapshot.sectionTitle == "May mornings")
        #expect(gregorianSnapshot.rows.count == 1)
        let gregorianRow = try #require(gregorianSnapshot.rows.first)
        #expect(gregorianRow.primaryDateLabel == "Thu, May 21")
        #expect(gregorianRow.secondaryDateLabel == "Dhul Hijjah 4")
        #expect(gregorianRow.statusLine == "Wake 4:18 AM · Fajr")

        let hijriSnapshot = MonthPlanningPresentation.detailSnapshot(
            identity: .hijri(year: 1447, month: .dhulHijjah),
            dateRange: range,
            activeDays: [future],
            now: now,
            timeZone: timeZone,
            entitlement: .plus,
            hijriComponentsProvider: hijriProvider
        )

        #expect(hijriSnapshot.navigationTitle == "Dhul Hijjah 1447")
        #expect(hijriSnapshot.sectionTitle == "Dhul Hijjah mornings")
        let hijriRow = try #require(hijriSnapshot.rows.first)
        #expect(hijriRow.primaryDateLabel == "Dhul Hijjah 4")
        #expect(hijriRow.secondaryDateLabel == "Thu, May 21")
    }

    @Test
    func entitlementGatesShareMonthPlanningAndSuhoorRules() {
        #expect(SubhEntitlementSnapshot.free.allows(.monthPlanning) == false)
        #expect(SubhEntitlementSnapshot.plus.allows(.monthPlanning))
        #expect(SubhEntitlementSnapshot.plus.allows(.suhoorPlanning) == false)
        #expect(SubhEntitlementSnapshot.complete.allows(.monthPlanning))
        #expect(SubhEntitlementSnapshot.complete.allows(.suhoorPlanning))
    }

    @Test
    @MainActor
    func entitlementStoreFallsBackConservativelyWhenUnset() {
        let suiteName = "MonthPlanningPresentationTests.EntitlementFallback"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)

        let store = SubhEntitlementStore(defaults: suite, environment: [:])

        #expect(store.snapshot == .free)
    }

    private static let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

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
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    private static func makeActiveDay(
        year: Int,
        month: Int,
        day: Int,
        wakeHour: Int,
        wakeMinute: Int,
        timeZone: TimeZone
    ) -> ActiveAlarmDay {
        let date = makeDate(year: year, month: month, day: day, timeZone: timeZone)
        let fajr = makeDate(year: year, month: month, day: day, hour: 4, minute: 0, timeZone: timeZone)
        let fajrEnd = makeDate(year: year, month: month, day: day, hour: 5, minute: 45, timeZone: timeZone)
        let wake = makeDate(year: year, month: month, day: day, hour: wakeHour, minute: wakeMinute, timeZone: timeZone)
        let maghrib = makeDate(year: year, month: month, day: day, hour: 20, minute: 45, timeZone: timeZone)
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let schedule = DaySchedule(
            date: date,
            fajrDate: fajr,
            fajrEndDate: fajrEnd,
            maghribDate: maghrib,
            wakeDate: wake,
            reminderDate: nil,
            boundaryDate: fajr,
            iftarDate: nil,
            locationDescription: "Toronto",
            offsetMinutes: 30,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
        let wakeRule = MorningWakeRule(
            state: .inFajr,
            anchorType: .fajrEnd,
            deltaMinutes: 30
        )
        let config = EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: false,
            fajrEnabled: true,
            iftarEnabled: false,
            defaultWakeRule: wakeRule,
            resolvedWakeRule: wakeRule,
            wakeRuleWasOverridden: false,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .adhanSoft,
            iftarDelivery: .off,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: false
        )

        return ActiveAlarmDay(
            date: date,
            dateKey: dateKey,
            schedule: schedule,
            effectiveConfig: config,
            provenances: [],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: nil,
            sourceSummaryText: "Test fixture",
            resolvedDayContext: .standard,
            scheduledEvents: Self.scheduledEvents(dateKey: dateKey, wake: wake),
            decisionLog: Self.decisionLog(
                date: date,
                dateKey: dateKey,
                fajr: fajr,
                fajrEnd: fajrEnd,
                wake: wake,
                maghrib: maghrib
            )
        )
    }

    private static func scheduledEvents(dateKey: String, wake: Date) -> [ScheduledEvent] {
        [
            ScheduledEvent(
                id: "\(dateKey).wakeAlarm",
                type: .wakeAlarm,
                dateKey: dateKey,
                fireDate: wake,
                relativeTo: .wakeAnchor(type: .fajrEnd, offsetMinutes: -30),
                isUserVisible: true,
                affectsCompletion: true,
                deliveryKinds: [.wake]
            )
        ]
    }

    private static func decisionLog(
        date: Date,
        dateKey: String,
        fajr: Date,
        fajrEnd: Date,
        wake: Date,
        maghrib: Date
    ) -> RuleDecisionLog {
        let delta = WakeDelta(relation: .before, minutes: 30)
        let events = scheduledEvents(dateKey: dateKey, wake: wake)
        return RuleDecisionLog(
            dateKey: dateKey,
            resolverVersion: 1,
            decisionHash: "\(dateKey)|month-planning-test",
            prayerWindow: DailyPrayerWindow(
                date: date,
                fajrStart: fajr,
                fajrEnd: fajrEnd,
                maghrib: maghrib,
                fajrEndSource: .solarSunrise
            ),
            candidateContexts: [.standard],
            resolvedDayContext: .standard,
            candidatePlans: [
                RulePlanCandidate(id: "test-plan", title: "Test plan", kind: .defaultDaily)
            ],
            selectedPlanID: "test-plan",
            precedenceReason: "Test fixture.",
            resolvedBehaviorProfile: MorningBehaviorProfile(
                wakeAnchorType: .fajrEnd,
                wakeDelta: delta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
                reminderEnabled: false,
                wakeAlarmEnabled: true,
                wakeFollowUpEnabled: false,
                fajrBoundaryNoticeEnabled: true,
                iftarReminderEnabled: false,
                resolvedWakeState: .inFajr,
                plannedWakeState: .inFajr,
                primaryWakeSoundRole: .inFajrWake
            ),
            resolvedAnchor: WakeAnchor(type: .fajrEnd, date: fajrEnd, providerNotes: "test"),
            resolvedDelta: delta,
            candidateWakeTime: wake,
            resolvedWakeTime: wake,
            resolvedWakeState: .inFajr,
            plannedWakeState: .inFajr,
            resolvedSequenceTemplate: WakeSequenceTemplate(
                id: "\(dateKey).test-sequence",
                name: "Test sequence",
                steps: events.map {
                    WakeSequenceStep(
                        eventType: $0.type,
                        relativeTo: $0.relativeTo,
                        isUserVisible: $0.isUserVisible,
                        affectsCompletion: $0.affectsCompletion,
                        soundRole: $0.soundRole,
                        wakeSessionRole: $0.wakeSessionRole,
                        fajrStartBehavior: $0.fajrStartBehavior
                    )
                }
            ),
            materializedEvents: events,
            compatibilityNotes: ["month_planning_test_fixture"]
        )
    }
}
