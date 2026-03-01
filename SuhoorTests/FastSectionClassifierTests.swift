import Foundation
import Testing
@testable import Suhoor

@Suite
struct FastSectionClassifierTests {
    @Test
    func ramadanMonthGroupsAsRamadan() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeHijriDate(year: 1447, month: 9, day: 10, timeZone: timeZone)
        let category = FastSectionClassifier.category(
            for: date,
            shawwalFirstSixDayIdentifiers: [],
            timeZone: timeZone
        )
        #expect(category == .ramadan)
    }

    @Test
    func ashuraDaysGroupAsMuharram() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let dayNine = makeHijriDate(year: 1447, month: 1, day: 9, timeZone: timeZone)
        let dayTen = makeHijriDate(year: 1447, month: 1, day: 10, timeZone: timeZone)
        let categoryNine = FastSectionClassifier.category(
            for: dayNine,
            shawwalFirstSixDayIdentifiers: [],
            timeZone: timeZone
        )
        let categoryTen = FastSectionClassifier.category(
            for: dayTen,
            shawwalFirstSixDayIdentifiers: [],
            timeZone: timeZone
        )
        #expect(categoryNine == .muharram)
        #expect(categoryTen == .muharram)
    }

    @Test
    func arafahGroupsAsDhulHijjah() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeHijriDate(year: 1447, month: 12, day: 9, timeZone: timeZone)
        let category = FastSectionClassifier.category(
            for: date,
            shawwalFirstSixDayIdentifiers: [],
            timeZone: timeZone
        )
        #expect(category == .dhulHijjah)
    }

    @Test
    func shawwalLimitSixSendsSeventhToOther() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let dates = (1...7).map { day in
            makeHijriDate(year: 1447, month: 10, day: day, timeZone: timeZone)
        }
        let shawwalIdentifiers = FastSectionClassifier.shawwalFirstSixDayIdentifiers(for: dates, timeZone: timeZone)
        let firstCategory = FastSectionClassifier.category(
            for: dates[0],
            shawwalFirstSixDayIdentifiers: shawwalIdentifiers,
            timeZone: timeZone
        )
        let seventhCategory = FastSectionClassifier.category(
            for: dates[6],
            shawwalFirstSixDayIdentifiers: shawwalIdentifiers,
            timeZone: timeZone
        )
        #expect(firstCategory == .shawwal)
        #expect(seventhCategory == .other)
    }

    private func makeHijriDate(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        let date = calendar.date(from: components)
        #expect(date != nil)
        return date ?? Date()
    }
}
