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
    func forbiddenSuggestionPrecedenceOverOtherPatterns() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let forbiddenDate = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 1, timeZone: timeZone)
        let suggestions = FastIntentEngine.suggestions(for: forbiddenDate, timeZone: timeZone)

        #expect(suggestions.suggestedPrimary == .forbidden)
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
        let selection = FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [.mondayThursday])
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

        #expect(suggestions.suggestedPrimary == .voluntary)
        #expect(suggestions.suggestedSecondary.contains(.shawwalSix))
    }

    @Test
    func defaultAddFlowSelectionDefaultsToVoluntaryWhenNoObservance() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = findEligibleDateWithoutObservance(timeZone: timeZone)
        let selection = FastIntentEngine.defaultAddFlowSelection(for: date, timeZone: timeZone)

        #expect(FastIntentEngine.isForbiddenToFast(date, timeZone: timeZone) == false)
        #expect(FastIntentEngine.isRamadan(date, timeZone: timeZone) == false)
        #expect(FastIntentEngine.dateDerivedObservanceTags(for: date, timeZone: timeZone, includeShawwalPotential: true).isEmpty)
        #expect(selection.primaryIntent == .voluntary)
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
        let calendarService = HijriCalendarService(baselineProvider: HijriBaselineMonthStarts.starts, adjustmentStore: store)
        let adjustedCalendar = AdjustedHijriCalendar(calendarService: calendarService)
        let originalResolver = FastIntentEngine.adjustedHijriCalendar
        FastIntentEngine.adjustedHijriCalendar = adjustedCalendar
        defer { FastIntentEngine.adjustedHijriCalendar = originalResolver }

        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let previewBefore = adjustedCalendar.monthStartPreview(for: key, timeZone: timeZone)
        #expect(previewBefore != nil)
        #expect(previewBefore?.offsetDays == 0)

        store.setAdjustment(for: key, offsetDays: 1)
        let previewAfter = adjustedCalendar.monthStartPreview(for: key, timeZone: timeZone)
        #expect(previewAfter != nil)
        #expect(previewAfter?.offsetDays == 1)

        if let previewAfter {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let shift = calendar.dateComponents([.day], from: previewAfter.baselineStart, to: previewAfter.adjustedStart).day ?? 0
            #expect(shift == 1)
        }

        let suggestions = FastIntentEngine.suggestions(for: previewAfter?.adjustedStart ?? .distantPast, timeZone: timeZone)
        #expect(suggestions.suggestedPrimary == .ramadanObligatory)
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
        #expect(FastIntentEngine.allowsSecondaryTags(primary: .voluntary, ruleset: .strict))
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

    private func findEligibleDateWithoutObservance(timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var date = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 20, timeZone: timeZone)
        for _ in 0..<400 {
            let isForbidden = FastIntentEngine.isForbiddenToFast(date, timeZone: timeZone)
            let isRamadan = FastIntentEngine.isRamadan(date, timeZone: timeZone)
            let derived = FastIntentEngine.dateDerivedObservanceTags(for: date, timeZone: timeZone, includeShawwalPotential: true)
            if !isForbidden && !isRamadan && derived.isEmpty {
                return date
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        Issue.record("Unable to find an eligible non-observance date")
        return Date()
    }
}
