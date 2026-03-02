import Foundation
import Testing
@testable import Suhoor

@Suite
struct FastClassificationEngineTests {
    @Test
    func ramadanSuggestionPrecedenceOverOtherPatterns() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ramadanDate = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 13, timeZone: timeZone)
        let suggestions = FastIntentEngine.suggestions(for: ramadanDate, timeZone: timeZone)
        #expect(suggestions.suggestedPrimary == .ramadanObligatory)
        #expect(suggestions.suggestedSecondary.isEmpty)
    }

    @Test
    func strictRulesetBlocksSecondaryForObligatory() {
        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [.whiteDays])
        let normalized = FastIntentEngine.normalizedSelection(selection, ruleset: .strict)
        #expect(normalized.secondaryTags.isEmpty)
    }

    @Test
    func permissiveAllowsSecondaryForObligatory() {
        let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [.whiteDays])
        let normalized = FastIntentEngine.normalizedSelection(selection, ruleset: .permissive)
        #expect(normalized.secondaryTags.contains(.whiteDays))
        #expect(normalized.primaryIntent == .qadaMakeup)
    }

    @Test
    func changingPrimaryClearsSecondaryInStrict() {
        let selection = FastIntentSelection(primaryIntent: .voluntarySunnah, secondaryTags: [.mondayThursday])
        let newSelection = FastIntentSelection(primaryIntent: .ramadanObligatory, secondaryTags: selection.secondaryTags)
        let normalized = FastIntentEngine.normalizedSelection(newSelection, ruleset: .strict)
        #expect(normalized.secondaryTags.isEmpty)
    }

    @Test
    func compatibilityMatrixMatchesStrictPolicy() {
        #expect(FastIntentEngine.observanceTagsCanCoexist(.mondayThursday, .whiteDays))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.mondayThursday, .ashura))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.mondayThursday, .arafah))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.mondayThursday, .dhulHijjahFirstNine))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.mondayThursday, .shawwalSix))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.whiteDays, .shawwalSix))
        #expect(FastIntentEngine.observanceTagsCanCoexist(.arafah, .dhulHijjahFirstNine))

        #expect(FastIntentEngine.observanceTagsCanCoexist(.ashura, .arafah) == false)
        #expect(FastIntentEngine.observanceTagsCanCoexist(.ashura, .dhulHijjahFirstNine) == false)
        #expect(FastIntentEngine.observanceTagsCanCoexist(.ashura, .shawwalSix) == false)
        #expect(FastIntentEngine.observanceTagsCanCoexist(.arafah, .shawwalSix) == false)
        #expect(FastIntentEngine.observanceTagsCanCoexist(.whiteDays, .arafah) == false)
        #expect(FastIntentEngine.observanceTagsCanCoexist(.whiteDays, .dhulHijjahFirstNine) == false)
    }

    @Test
    func shawwalDateSuggestsVoluntaryPurpose() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 2, timeZone: timeZone)
        let suggestions = FastIntentEngine.suggestions(for: date, timeZone: timeZone)

        #expect(suggestions.suggestedPrimary == .voluntarySunnah)
        #expect(suggestions.suggestedSecondary.contains(.shawwalSix))
    }

    @Test
    func ramadanPrimaryIsNotSelectableOutsideRamadan() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 2, timeZone: timeZone)

        #expect(FastIntentEngine.isPrimarySelectable(.ramadanObligatory, on: date, timeZone: timeZone) == false)
        #expect(FastIntentEngine.normalizedPrimaryIntent(.ramadanObligatory, on: date, timeZone: timeZone) == .other)
    }

    @Test
    func hijriMonthKeyStableForSameMonth() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let first = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 1, timeZone: timeZone)
        let second = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 15, timeZone: timeZone)
        let firstKey = FastIntentEngine.hijriMonthKey(for: first, timeZone: timeZone)
        let secondKey = FastIntentEngine.hijriMonthKey(for: second, timeZone: timeZone)
        #expect(firstKey == secondKey)
    }

    @Test
    func monthAdjustmentMovesRamadanSuggestionBoundary() {
        let suiteName = "FastClassificationEngineTests.Adjustment"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let calendarService = HijriCalendarService(adjustmentStore: store)
        let adjustedCalendar = AdjustedHijriCalendar(calendarService: calendarService)
        let originalResolver = FastIntentEngine.adjustedHijriCalendar
        FastIntentEngine.adjustedHijriCalendar = adjustedCalendar
        defer { FastIntentEngine.adjustedHijriCalendar = originalResolver }

        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let baselineStart = adjustedCalendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: timeZone)
        #expect(baselineStart != nil)

        let before = FastIntentEngine.suggestions(for: baselineStart ?? .distantPast, timeZone: timeZone)
        #expect(before.suggestedPrimary == .ramadanObligatory)

        store.setAdjustment(for: key, offsetDays: 1)
        let after = FastIntentEngine.suggestions(for: baselineStart ?? .distantPast, timeZone: timeZone)
        #expect(after.suggestedPrimary != .ramadanObligatory)
    }

    @Test
    func primaryTagMetadataHasAboutText() {
        for intent in FastPrimaryIntent.allCases {
            #expect(!intent.about.aboutText.isEmpty)
        }
    }

    @Test
    func secondaryTagMetadataHasAboutTextAndBullets() {
        for tag in FastSecondaryVirtueTag.allCases {
            #expect(!tag.about.aboutText.isEmpty)
            #expect(!tag.about.bullets.isEmpty)
        }
    }

    @Test
    func strictOnlyUiContractRemainsInPlace() {
        #expect(FastIntentEngine.allowsSecondaryTags(primary: .other, ruleset: .strict) == false)
        #expect(FastIntentEngine.allowsSecondaryTags(primary: .voluntarySunnah, ruleset: .strict))
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
        let suiteName = "FastClassificationEngineTests.Helper.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let service = AdjustedHijriCalendar(calendarService: HijriCalendarService(adjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)))
        let date = service.gregorianDate(for: HijriYearMonth(hijriYear: year, month: month), dayOfMonth: day, timeZone: timeZone)
        #expect(date != nil)
        return date ?? Date()
    }
}
