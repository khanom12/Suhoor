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
