import Foundation
import Testing
@testable import Suhoor

@Suite
struct TagComputationEngineTests {
    @Test
    func ramadanForcesPrimaryAndClearsSecondaryInStrict() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ramadanDate = makeHijriDate(year: 1447, month: 9, day: 10, timeZone: timeZone)
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
    func mondayAndWhiteDaysStack() {
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
        #expect(result?.computedSecondaryTags.contains(.mondayThursday) == true)
        #expect(result?.computedSecondaryTags.contains(.whiteDays) == true)
    }

    @Test
    func voluntaryTagsStackWithUserSelections() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeHijriDate(year: 1447, month: 12, day: 9, timeZone: timeZone)
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
        #expect(result?.computedSecondaryTags.contains(.arafah) == true)
        #expect(result?.computedSecondaryTags.contains(.dhulHijjahFirstNine) == true)
        #expect(result?.computedSecondaryTags.contains(.whiteDays) == true)
        #expect(result?.computedSecondaryTags.contains(.mondayThursday) == true)
    }

    @Test
    func strictClearsSecondaryForObligatoryPrimary() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeHijriDate(year: 1447, month: 8, day: 14, timeZone: timeZone)
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
    }

    @Test
    func shawwalFirstSixAllocationIsDeterministic() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let schedules = (1...8).map { day -> DaySchedule in
            let date = makeHijriDate(year: 1447, month: 10, day: day, timeZone: timeZone)
            return makeSchedule(date: date, timeZone: timeZone)
        }

        let results = TagComputationEngine.results(
            schedules: schedules,
            selections: [:],
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

    private func makeHijriDate(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        let date = calendar.date(from: components)
        #expect(date != nil)
        return date ?? Date()
    }

    private func findDate(hijriDay: Int, weekday: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var date = Date(timeIntervalSinceReferenceDate: 0)
        for _ in 0..<2000 {
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
            wakeDate: date,
            reminderDate: nil,
            boundaryDate: nil,
            locationDescription: "Test",
            offsetMinutes: 0,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
    }
}
