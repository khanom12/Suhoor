import CoreLocation
import Foundation
import Testing
@testable import Subh

@Suite
struct TagComputationEngineTests {
    @Test
    func ramadanForcesPrimaryAndClearsSecondaryInStrict() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ramadanDate = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 10, timeZone: timeZone)
        let schedule = makeSchedule(date: ramadanDate, timeZone: timeZone)

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: ramadanDate, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .ramadanObligatory)
        #expect(result?.computedSecondaryTags.isEmpty == true)
    }

    @Test
    func forbiddenForcesPrimaryAndClearsSecondary() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let forbiddenDate = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 11, timeZone: timeZone)
        let schedule = makeSchedule(date: forbiddenDate, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [.whiteDays])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: forbiddenDate, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: forbiddenDate, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .forbidden)
        #expect(result?.computedSecondaryTags.isEmpty == true)
        #expect(result?.suppressedSecondaryTags.isEmpty == true)
    }

    @Test
    func otherDoesNotCarryObservanceTags() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 13, weekday: 2, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .other)
        #expect(result?.computedSecondaryTags.isEmpty == true)
        #expect(result?.suppressedSecondaryTags.contains(.mondayThursday) == true)
        #expect(result?.suppressedSecondaryTags.contains(.whiteDays) == true)
    }

    @Test
    func voluntaryAllowsMondayThursdayAndWhiteDaysTogether() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 13, weekday: 2, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedSecondaryTags == [.mondayThursday, .whiteDays])
    }

    @Test
    func implicitVoluntarySeedComputesObservancesWithoutStoredSelection() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 13, weekday: 2, timeZone: timeZone)

        let results = TagComputationEngine.results(
            seeds: [
                ActiveTagComputationSeed(
                    date: date,
                    dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                    defaultPrimaryIntent: .voluntary
                )
            ],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .voluntary)
        #expect(result?.computedSecondaryTags.contains(.mondayThursday) == true)
        #expect(result?.computedSecondaryTags.contains(.whiteDays) == true)
    }

    @Test
    func arafahCoexistsWithDhulHijjahFirstNine() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 9, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedSecondaryTags.contains(.arafah) == true)
        #expect(result?.computedSecondaryTags.contains(.dhulHijjahFirstNine) == true)
    }

    @Test
    func ashuraNeverCoexistsWithDhulHijjahFirstNine() {
        #expect(FastIntentEngine.observanceTagsCanCoexist(.ashura, .dhulHijjahFirstNine) == false)
    }

    @Test
    func obligatoryPrimarySuppressesAllDerivedObservances() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 13, weekday: 2, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [.whiteDays, .mondayThursday])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .qadaMakeup)
        #expect(result?.computedSecondaryTags.isEmpty == true)
        #expect(result?.suppressedSecondaryTags == [.mondayThursday, .whiteDays])
    }

    @Test
    func storedInvalidSecondaryTagsAreNormalizedAway() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 9, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [.whiteDays, .dhulHijjahFirstNine, .arafah])

        let normalized = FastIntentEngine.normalizedSelection(
            selection,
            for: date,
            ruleset: .strict,
            timeZone: timeZone
        )

        #expect(normalized.secondaryTags.contains(.arafah) == true)
        #expect(normalized.secondaryTags.contains(.dhulHijjahFirstNine) == true)
        #expect(normalized.secondaryTags.contains(.whiteDays) == false)
    }

    @Test
    func shawwalFirstSixAllocationIsDeterministic() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let schedules = (2...9).map { day -> DaySchedule in
            let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: day, timeZone: timeZone)
            return makeSchedule(date: date, timeZone: timeZone)
        }
        let selections = Dictionary(uniqueKeysWithValues: schedules.map {
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []))
        })

        let results = TagComputationEngine.results(
            schedules: schedules,
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone
        )

        let keys = schedules.map { DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone) }
        for (index, key) in keys.enumerated() {
            let result = results[key]
            let shouldHave = index < 6
            #expect(result?.computedSecondaryTags.contains(.shawwalSix) == shouldHave)
        }
    }

    @Test
    func shawwalSkipsDatesMarkedQada() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let schedules = (2...8).map { day -> DaySchedule in
            let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: day, timeZone: timeZone)
            return makeSchedule(date: date, timeZone: timeZone)
        }
        var selections = Dictionary(uniqueKeysWithValues: schedules.map {
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []))
        })
        let blockedKey = DateHelpers.dayIdentifier(for: schedules[1].date, timeZone: timeZone)
        selections[blockedKey] = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: schedules,
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone
        )

        #expect(results[blockedKey]?.computedSecondaryTags.contains(.shawwalSix) == false)
        let lastKey = DateHelpers.dayIdentifier(for: schedules.last!.date, timeZone: timeZone)
        #expect(results[lastKey]?.computedSecondaryTags.contains(.shawwalSix) == true)
    }

    @Test
    func shawwalReallocatesWhenEligibleDateBecomesObligatory() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let schedules = (2...8).map { day -> DaySchedule in
            let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: day, timeZone: timeZone)
            return makeSchedule(date: date, timeZone: timeZone)
        }
        let baseSelections = Dictionary(uniqueKeysWithValues: schedules.map {
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []))
        })

        let baseResults = TagComputationEngine.results(
            schedules: schedules,
            selections: baseSelections,
            ruleset: .strict,
            timeZone: timeZone
        )
        let originalSixthKey = DateHelpers.dayIdentifier(for: schedules[5].date, timeZone: timeZone)
        #expect(baseResults[originalSixthKey]?.computedSecondaryTags.contains(.shawwalSix) == true)

        var changedSelections = baseSelections
        let thirdKey = DateHelpers.dayIdentifier(for: schedules[2].date, timeZone: timeZone)
        changedSelections[thirdKey] = FastIntentSelection(primaryIntent: .vowNadhr, secondaryTags: [])

        let changedResults = TagComputationEngine.results(
            schedules: schedules,
            selections: changedSelections,
            ruleset: .strict,
            timeZone: timeZone
        )
        let seventhKey = DateHelpers.dayIdentifier(for: schedules[6].date, timeZone: timeZone)

        #expect(changedResults[thirdKey]?.computedSecondaryTags.contains(.shawwalSix) == false)
        #expect(changedResults[seventhKey]?.computedSecondaryTags.contains(.shawwalSix) == true)
    }

    @Test
    func shawwalCanCoexistWithWhiteDaysWhenChronologyAndDateAllow() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 13, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedSecondaryTags.contains(.whiteDays) == true)
        #expect(result?.computedSecondaryTags.contains(.shawwalSix) == true)
    }

    @Test
    func singleDateResultAllocatesShawwalForEligibleVoluntaryDate() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 2, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])

        let result = TagComputationEngine.result(
            for: date,
            schedules: [],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: selection
        )

        #expect(result.computedPrimaryIntent == .voluntary)
        #expect(result.computedSecondaryTags.contains(.shawwalSix))
    }

    @Test
    func invalidRamadanSelectionOutsideRamadanNormalizesAway() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 5, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .ramadanObligatory, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .other)
    }

    @Test
    func ramadanSuppressesAllObservanceTagsEvenIfStored() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 13, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [.whiteDays, .mondayThursday])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .ramadanObligatory)
        #expect(result?.computedSecondaryTags.isEmpty == true)
    }

    @Test
    func tashriqProducesWarningButNoDerivedObservanceTags() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 13, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(FastIntentEngine.warnings(for: date, timeZone: timeZone).contains(.tashreeq))
        #expect(result?.computedPrimaryIntent == .forbidden)
        #expect(result?.computedSecondaryTags.isEmpty == true)
    }

    @Test
    func dayPurposeMondayOpportunityStaysDefaultFajr() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 12, weekday: 2, timeZone: timeZone)
        let purpose = resolvePurpose(for: date, timeZone: timeZone)

        #expect(purpose.opportunities.contains { $0.kind == .mondayThursday })
        #expect(purpose.intention.kind == .defaultFajr)
        #expect(purpose.requiredActions.contains(.fastCompletion) == false)
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .keptDefault))
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .planned) == false)
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .missedAfterPlanning) == false)
    }

    @Test
    func dayPurposeWhiteDayOpportunityStaysDefaultFajr() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 13, timeZone: timeZone)
        let purpose = resolvePurpose(for: date, timeZone: timeZone)

        #expect(purpose.opportunities.contains { $0.kind == .whiteDays })
        #expect(purpose.intention.kind == .defaultFajr)
        #expect(hasCredit(purpose, kind: .whiteDays, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .whiteDays, type: .planned) == false)
        #expect(hasCredit(purpose, kind: .whiteDays, type: .missedAfterPlanning) == false)
    }

    @Test
    func dayPurposeVoluntaryMondayCompletedCreditsMonday() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findDate(hijriDay: 12, weekday: 2, timeZone: timeZone)
        let purpose = resolvePurpose(
            for: date,
            selection: FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
            fastStatus: .completed,
            timeZone: timeZone
        )

        #expect(purpose.intention.kind == .fast)
        #expect(purpose.requiredActions.contains(.fastCompletion))
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .planned))
        #expect(hasCredit(purpose, kind: .mondayThursday, type: .completed))
    }

    @Test
    func dayPurposeVoluntaryWhiteDayNotCompletedCreditsMissedAfterPlanning() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 13, timeZone: timeZone)
        let purpose = resolvePurpose(
            for: date,
            selection: FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
            fastStatus: .notCompleted,
            timeZone: timeZone
        )

        #expect(purpose.intention.kind == .fast)
        #expect(hasCredit(purpose, kind: .whiteDays, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .whiteDays, type: .planned))
        #expect(hasCredit(purpose, kind: .whiteDays, type: .missedAfterPlanning))
    }

    @Test
    func dayPurposeQadaOnWhiteDayDoesNotCreditWhiteDayCompletion() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 13, timeZone: timeZone)
        let purpose = resolvePurpose(
            for: date,
            selection: FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: []),
            fastStatus: .completed,
            timeZone: timeZone
        )

        #expect(purpose.intention.fastIntent?.primaryIntent == .qadaMakeup)
        #expect(hasCredit(purpose, kind: .whiteDays, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .qadaAssignable, type: .planned))
        #expect(hasCredit(purpose, kind: .qadaAssignable, type: .completed))
        #expect(hasCredit(purpose, kind: .whiteDays, type: .completed) == false)
    }

    @Test
    func dayPurposeRamadanAutoPlansFast() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 10, timeZone: timeZone)
        let purpose = resolvePurpose(for: date, timeZone: timeZone)

        #expect(purpose.opportunities.contains { $0.kind == .ramadan })
        #expect(purpose.intention.kind == .fast)
        #expect(purpose.intention.source == .autoRamadan)
        #expect(purpose.intention.fastIntent?.primaryIntent == .ramadanObligatory)
        #expect(hasCredit(purpose, kind: .ramadan, type: .opportunityAvailable))
        #expect(hasCredit(purpose, kind: .ramadan, type: .planned))
    }

    @Test
    func dayPurposeForbiddenFastLogsInvalidCreditOnly() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 1, timeZone: timeZone)
        let purpose = resolvePurpose(
            for: date,
            fastStatus: .completed,
            timeZone: timeZone
        )

        #expect(purpose.opportunities.contains { $0.kind == .eidAlFitr && $0.eligibility == .forbidden })
        #expect(purpose.intention.kind == .defaultFajr)
        #expect(hasCredit(purpose, kind: .eidAlFitr, type: .invalidForbiddenFast))
        #expect(purpose.analyticsCredits.contains { $0.creditType == .completed } == false)
    }

    private func makeHijriDate(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        let date = calendar.date(from: components)
        #expect(date != nil)
        return date ?? Date()
    }

    private func makeAdjustedHijriDate(year: Int, month: HijriMonth, day: Int, timeZone: TimeZone) -> Date {
        let suiteName = "TagComputationEngineTests.Helper.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let service = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(
                baselineProvider: HijriBaselineMonthStarts.starts,
                adjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
            )
        )
        let date = service.gregorianDate(for: HijriYearMonth(hijriYear: year, month: month), dayOfMonth: day, timeZone: timeZone)
        #expect(date != nil)
        return date ?? Date()
    }

    private func findDate(hijriDay: Int, weekday: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var date = Date(timeIntervalSinceReferenceDate: 0)
        for _ in 0..<4000 {
            let hijri = hijriComponents(for: date, timeZone: timeZone)
            let gregorianWeekday = calendar.component(.weekday, from: date)
            if hijri.day == hijriDay, gregorianWeekday == weekday {
                return date
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        #expect(false)
        return Date()
    }

    private func hijriComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }

    private func makeSchedule(date: Date, timeZone: TimeZone) -> DaySchedule {
        DaySchedule(
            date: date,
            fajrDate: date,
            maghribDate: date,
            wakeDate: date,
            reminderDate: nil,
            boundaryDate: nil,
            iftarDate: nil,
            fajrSoundChoice: nil,
            iftarSoundChoice: nil,
            locationDescription: "Test",
            offsetMinutes: 0,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
    }

    private func resolvePurpose(
        for date: Date,
        selection: FastIntentSelection? = nil,
        fastStatus: FastCompletionStatus = .notRequired,
        timeZone: TimeZone
    ) -> ResolvedDayPurpose {
        let dateKey = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let selections = selection.map { [dateKey: $0] } ?? [:]
        let tagResult = TagComputationEngine.result(
            for: date,
            seeds: [
                ActiveTagComputationSeed(
                    date: date,
                    dateKey: dateKey,
                    defaultPrimaryIntent: nil
                )
            ],
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: selection
        )
        let completionRecords = completionRecords(
            dateKey: dateKey,
            fastStatus: fastStatus,
            selection: selection
        )
        let qadaEffect = selection?.primaryIntent == .qadaMakeup && fastStatus == .completed
            ? QadaEffect(
                countsTowardQada: true,
                completedDelta: 1,
                remainingAfterEffect: 0,
                explanation: "Completed Qada fasts reduce what remains."
            )
            : .none
        let dailyCompletion = DailyCompletionSnapshot(
            dateKey: dateKey,
            prayer: .empty,
            fast: FastCompletionState(
                status: fastStatus,
                intentSnapshot: selection.map {
                    FastIntentSnapshot(primaryIntent: $0.primaryIntent, secondaryTags: $0.secondaryTags)
                },
                updatedAt: nil,
                source: nil
            ),
            qadaEffect: qadaEffect,
            wakeSupport: .none,
            outstandingAction: nil,
            isMeaningfullyResolved: true
        )
        let selectedPlan = makeMorningPlan()
        let wakeAnchor = WakeAnchor(type: .fajrEnd, date: date, providerNotes: nil)
        let wakeResolution = WakeResolutionResult(
            candidateWakeTime: date,
            finalWakeTime: date,
            resolvedWakeState: .inFajr,
            latestWakeCapMinutesFromMidnight: nil,
            latestWakeCapApplied: false,
            latestWakeCapShiftedState: false
        )

        return DayPurposeResolver.resolve(
            date: date,
            dateKey: dateKey,
            provenances: [],
            tagResult: tagResult,
            effectiveConfig: makeEffectiveConfig(for: date),
            stateSnapshot: makeStateSnapshot(
                dateKey: dateKey,
                selectedPlan: selectedPlan,
                selections: selections,
                completionRecords: completionRecords,
                timeZone: timeZone
            ),
            selectedPlan: selectedPlan,
            wakeAnchor: wakeAnchor,
            wakeResolution: wakeResolution,
            completionRecords: completionRecords,
            dailyCompletion: dailyCompletion
        )
    }

    private func completionRecords(
        dateKey: String,
        fastStatus: FastCompletionStatus,
        selection: FastIntentSelection?
    ) -> [CompletionRecord] {
        guard fastStatus != .notRequired else { return [] }
        let status: CompletionStatus = fastStatus == .completed ? .completed : .missed
        var metadata: [String: String] = [:]
        if let selection {
            metadata["primaryIntent"] = selection.primaryIntent.rawValue
        }
        return [
            CompletionRecord(
                id: "\(dateKey).fast",
                dateKey: dateKey,
                kind: .fast,
                status: status,
                updatedAt: Date(timeIntervalSinceReferenceDate: 0),
                source: "test",
                metadata: metadata
            )
        ]
    }

    private func makeEffectiveConfig(for date: Date) -> EffectiveDailyConfig {
        let defaults = DefaultAlarmConfig.default
        let settings = AppSettings.default
        return EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: true,
            fajrEnabled: true,
            iftarEnabled: true,
            defaultWakeRule: defaults.defaultWakeRule,
            resolvedWakeRule: defaults.defaultWakeRule,
            wakeRuleWasOverridden: false,
            tahajjudRefinement: false,
            suhoorTimeMode: defaults.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: defaults.defaultSuhoorOffsetMinutes,
            reminderTimeMode: defaults.defaultReminderTimeMode,
            reminderMinutesBeforeFajr: defaults.defaultReminderMinutesBeforeFajr,
            reminderFixedTimeMinutes: defaults.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
            iftarDelivery: defaults.defaultIftarDelivery,
            iftarSoundChoice: defaults.defaultIftarSoundChoice,
            hasOverrides: false
        )
    }

    private func makeMorningPlan() -> MorningPlan {
        let rule = DefaultAlarmConfig.default.defaultWakeRule
        return MorningPlan(
            id: "default-daily",
            title: "Daily morning plan",
            kind: .defaultDaily,
            wakeRule: rule,
            wakeAnchorType: rule.compatibilityWakeAnchorType,
            wakeDelta: rule.compatibilityWakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: nil,
            reminderEnabled: true,
            wakeAlarmEnabled: true,
            fajrBoundaryNoticeEnabled: true,
            iftarReminderEnabled: true
        )
    }

    private func makeStateSnapshot(
        dateKey: String,
        selectedPlan: MorningPlan,
        selections: [String: FastIntentSelection],
        completionRecords: [CompletionRecord],
        timeZone: TimeZone
    ) -> MorningStateSnapshot {
        MorningStateSnapshot(
            settings: .default,
            defaultConfig: .default,
            morningPlanState: MorningPlanState(
                schemaVersion: 2,
                activationMode: .dailyActive,
                defaultDailyPlan: selectedPlan,
                lastMigrationAt: nil
            ),
            dateAssignments: selections[dateKey]?.primaryIntent == .qadaMakeup
                ? [PlanDateAssignment(dateKey: dateKey, planID: "qada-\(dateKey)")]
                : [],
            completionRecords: completionRecords,
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: dateKey,
                baselineOwed: 1,
                completed: 0,
                remaining: 1
            ),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZone: timeZone,
            locationDescription: "Test",
            fastTagSelections: selections,
            overridesByDateKey: [:]
        )
    }

    private func hasCredit(
        _ purpose: ResolvedDayPurpose,
        kind: ObservanceKind,
        type: ObservanceCreditType
    ) -> Bool {
        purpose.analyticsCredits.contains {
            $0.kind == kind && $0.creditType == type
        }
    }
}
