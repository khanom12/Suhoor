import Foundation
import Testing
@testable import Suhoor

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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [])

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
                    defaultPrimaryIntent: .voluntarySunnah
                )
            ],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(result?.computedPrimaryIntent == .voluntarySunnah)
        #expect(result?.computedSecondaryTags.contains(.mondayThursday) == true)
        #expect(result?.computedSecondaryTags.contains(.whiteDays) == true)
    }

    @Test
    func arafahCoexistsWithDhulHijjahFirstNine() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 9, timeZone: timeZone)
        let schedule = makeSchedule(date: date, timeZone: timeZone)
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [])

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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [.whiteDays, .dhulHijjahFirstNine, .arafah])

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
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: []))
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
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: []))
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
            (DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone), FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: []))
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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [])

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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [])

        let result = TagComputationEngine.result(
            for: date,
            schedules: [],
            selections: [:],
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: selection
        )

        #expect(result.computedPrimaryIntent == .voluntarySunnah)
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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [.whiteDays, .mondayThursday])

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
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [])

        let results = TagComputationEngine.results(
            schedules: [schedule],
            selections: [DateHelpers.dayIdentifier(for: date, timeZone: timeZone): selection],
            ruleset: .strict,
            timeZone: timeZone
        )

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let result = results[key]
        #expect(FastIntentEngine.warnings(for: date, timeZone: timeZone).contains(.tashreeq))
        #expect(result?.computedSecondaryTags.isEmpty == true)
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
}
