import Foundation
import Testing
@testable import Suhoor

@Suite
struct HijriCalendarServiceTests {
    @Test
    func dayOfMonthMappingUsesStartPlusOffset() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.DayMapping")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.DayMapping")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(adjustmentStore: store)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let map = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone)

        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)
        let day1 = service.gregorianDate(for: key, dayOfMonth: 1, monthMap: map, timeZone: timeZone)
        let day13 = service.gregorianDate(for: key, dayOfMonth: 13, monthMap: map, timeZone: timeZone)
        let day15 = service.gregorianDate(for: key, dayOfMonth: 15, monthMap: map, timeZone: timeZone)

        #expect(day1 != nil)
        #expect(day13 != nil)
        #expect(day15 != nil)
        #expect(day13?.timeIntervalSince(day1 ?? .distantPast) == 12 * 24 * 60 * 60)
        #expect(day15?.timeIntervalSince(day1 ?? .distantPast) == 14 * 24 * 60 * 60)
    }

    @Test
    func monthAdjustmentsShiftResolvedStart() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.Adjustments")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.Adjustments")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(adjustmentStore: store)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)

        let baseline = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)
        store.setAdjustment(for: key, offsetDays: 1)
        let plusOne = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)
        store.setAdjustment(for: key, offsetDays: -1)
        let minusOne = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone).resolvedStart(for: .ramadan)

        #expect(baseline != nil)
        #expect(plusOne != nil)
        #expect(minusOne != nil)
        #expect(plusOne?.resolvedStart.timeIntervalSince(baseline?.resolvedStart ?? .distantPast) == 24 * 60 * 60)
        #expect(minusOne?.resolvedStart.timeIntervalSince(baseline?.resolvedStart ?? .distantPast) == -24 * 60 * 60)
    }

    @Test
    func keyEventsResolveFromMonthStarts() {
        let suite = UserDefaults(suiteName: "HijriCalendarServiceTests.KeyEvents")!
        suite.removePersistentDomain(forName: "HijriCalendarServiceTests.KeyEvents")
        let store = HijriMonthAdjustmentStore(defaults: suite)
        let service = HijriCalendarService(adjustmentStore: store)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let map = service.buildMonthMap(hijriYear: 1447, timeZone: timeZone)

        let muharramStart = map.resolvedStart(for: .muharram)?.resolvedStart
        let ramadanStart = map.resolvedStart(for: .ramadan)?.resolvedStart
        let shawwalStart = map.resolvedStart(for: .shawwal)?.resolvedStart
        let dhulHijjahStart = map.resolvedStart(for: .dhulHijjah)?.resolvedStart

        let ashura = service.dateForAshura(hijriYear: 1447, timeZone: timeZone)
        let whiteDays = service.datesForWhiteDays(hijriYear: 1447, month: .ramadan, timeZone: timeZone)
        let eidAlFitr = service.dateForEidAlFitr(hijriYear: 1447, timeZone: timeZone)
        let arafah = service.dateForArafah(hijriYear: 1447, timeZone: timeZone)
        let eidAlAdha = service.dateForEidAlAdha(hijriYear: 1447, timeZone: timeZone)

        #expect(ashura?.timeIntervalSince(muharramStart ?? .distantPast) == 9 * 24 * 60 * 60)
        #expect(whiteDays.count == 3)
        #expect(whiteDays.first?.timeIntervalSince(ramadanStart ?? .distantPast) == 12 * 24 * 60 * 60)
        #expect(whiteDays.last?.timeIntervalSince(ramadanStart ?? .distantPast) == 14 * 24 * 60 * 60)
        #expect(eidAlFitr == shawwalStart)
        #expect(arafah?.timeIntervalSince(dhulHijjahStart ?? .distantPast) == 8 * 24 * 60 * 60)
        #expect(eidAlAdha?.timeIntervalSince(dhulHijjahStart ?? .distantPast) == 9 * 24 * 60 * 60)
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
}
