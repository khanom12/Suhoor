import Foundation
import Testing
@testable import Suhoor

@Suite
struct FastClassificationEngineTests {
    @Test
    func ramadanSuggestionPrecedenceOverOtherPatterns() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let ramadanDate = makeHijriDate(year: 1447, month: 9, day: 13, timeZone: timeZone)
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
    func hijriMonthKeyStableForSameMonth() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let first = makeHijriDate(year: 1447, month: 8, day: 1, timeZone: timeZone)
        let second = makeHijriDate(year: 1447, month: 8, day: 15, timeZone: timeZone)
        let firstKey = FastIntentEngine.hijriMonthKey(for: first, timeZone: timeZone)
        let secondKey = FastIntentEngine.hijriMonthKey(for: second, timeZone: timeZone)
        #expect(firstKey == secondKey)
    }

    @Test
    func primaryTagMetadataHasAboutText() {
        for intent in FastPrimaryIntent.allCases {
            #expect(!intent.about.aboutText.isEmpty)
        }
    }

    @Test
    func secondaryTagMetadataHasAboutText() {
        for tag in FastSecondaryVirtueTag.allCases {
            #expect(!tag.about.aboutText.isEmpty)
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
}
