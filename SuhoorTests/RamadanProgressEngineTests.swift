import Foundation
import Testing
@testable import Suhoor

@Suite
struct RamadanProgressEngineTests {
    @Test
    func returnsNilOutsideRamadan() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let calendar = makeCalendar()

        // After Shawwal 1 (baseline table has Shawwal 1447 start on March 20, 2026).
        let notRamadan = makeDate(year: 2026, month: 3, day: 25, hour: 12, minute: 0, timeZone: timeZone)
        let model = RamadanProgressEngine.model(now: notRamadan, calendar: calendar, timeZone: timeZone)
        #expect(model == nil)
    }

    @Test
    func dayNumberIncrementsWithinRamadan() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let calendar = makeCalendar()

        // Baseline: Ramadan 1447 starts Feb 18, 2026.
        let day1 = makeDate(year: 2026, month: 2, day: 18, hour: 12, minute: 0, timeZone: timeZone)
        let day2 = makeDate(year: 2026, month: 2, day: 19, hour: 12, minute: 0, timeZone: timeZone)

        let model1 = RamadanProgressEngine.model(now: day1, calendar: calendar, timeZone: timeZone)
        let model2 = RamadanProgressEngine.model(now: day2, calendar: calendar, timeZone: timeZone)

        #expect(model1 != nil)
        #expect(model2 != nil)

        if let model1, let model2 {
            #expect(model1.dayNumber == 1)
            #expect(model2.dayNumber == 2)
            #expect((29...30).contains(model1.totalDays))
            #expect(model2.totalDays == model1.totalDays)
            #expect(model1.progress > 0 && model1.progress < 1)
            #expect(model2.progress > model1.progress)
            #expect(model1.eidDateText != nil)
        }
    }

    @Test
    func ramadanAdjustmentShiftsDayOne() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let suiteName = "SuhoorTests.RamadanProgressEngine.ShiftedRamadan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        adjustmentStore.setAdjustment(
            for: HijriYearMonth(hijriYear: 1447, month: .ramadan),
            offsetDays: 1
        )
        let calendar = makeCalendar(defaults: defaults)

        let feb18 = makeDate(year: 2026, month: 2, day: 18, hour: 12, minute: 0, timeZone: timeZone)
        let feb19 = makeDate(year: 2026, month: 2, day: 19, hour: 12, minute: 0, timeZone: timeZone)

        let modelBeforeShift = RamadanProgressEngine.model(now: feb18, calendar: calendar, timeZone: timeZone)
        let modelOnShiftedStart = RamadanProgressEngine.model(now: feb19, calendar: calendar, timeZone: timeZone)

        #expect(modelBeforeShift == nil)
        #expect(modelOnShiftedStart?.dayNumber == 1)
    }

    @Test
    func shawwalAdjustmentChangesTotalDaysAndEidDate() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let suiteName = "SuhoorTests.RamadanProgressEngine.ShawwalShift"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let baselineCalendar = makeCalendar(defaults: defaults)
        let checkDate = makeDate(year: 2026, month: 3, day: 10, hour: 12, minute: 0, timeZone: timeZone)
        let baselineModel = RamadanProgressEngine.model(now: checkDate, calendar: baselineCalendar, timeZone: timeZone)

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        adjustmentStore.setAdjustment(
            for: HijriYearMonth(hijriYear: 1447, month: .shawwal),
            offsetDays: 1
        )
        let shiftedCalendar = makeCalendar(defaults: defaults)
        let shiftedModel = RamadanProgressEngine.model(now: checkDate, calendar: shiftedCalendar, timeZone: timeZone)

        #expect(baselineModel != nil)
        #expect(shiftedModel != nil)

        if let baselineModel, let shiftedModel {
            #expect(shiftedModel.totalDays == baselineModel.totalDays + 1)
            #expect(shiftedModel.eidDateText != baselineModel.eidDateText)
        }
    }

    // MARK: - Helpers

    private func makeCalendar(defaults: UserDefaults? = nil) -> AdjustedHijriCalendar {
        let resolvedDefaults: UserDefaults
        if let defaults {
            resolvedDefaults = defaults
        } else {
            let suiteName = "SuhoorTests.RamadanProgressEngine"
            let freshDefaults = UserDefaults(suiteName: suiteName)!
            freshDefaults.removePersistentDomain(forName: suiteName)
            resolvedDefaults = freshDefaults
        }

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: resolvedDefaults)
        let service = HijriCalendarService(
            baselineProvider: HijriBaselineMonthStarts.starts,
            adjustmentStore: adjustmentStore
        )
        return AdjustedHijriCalendar(calendarService: service)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
