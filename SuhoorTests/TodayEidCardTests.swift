import Foundation
import Testing
@testable import Suhoor

@Suite
struct TodayEidCardTests {
    @Test
    func eidMubarakIsLiveOnEidAlFitr() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 1, calendar: calendar, timeZone: timeZone)

        let model = EidMubarakEngine.model(now: now, mode: .live, calendar: calendar, timeZone: timeZone)

        #expect(model?.subtitle == "Eid al-Fitr")
    }

    @Test
    func eidMubarakIsLiveOnEidAlAdha() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 10, calendar: calendar, timeZone: timeZone)

        let model = EidMubarakEngine.model(now: now, mode: .live, calendar: calendar, timeZone: timeZone)

        #expect(model?.subtitle == "Eid al-Adha")
    }

    @Test
    func eidMubarakIsUnavailableOnTashreeq() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 11, calendar: calendar, timeZone: timeZone)

        let model = EidMubarakEngine.model(now: now, mode: .live, calendar: calendar, timeZone: timeZone)

        #expect(model == nil)
    }

    @Test
    func eidMubarakReferenceUsesNormalCopyOutsideLiveDay() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 20, calendar: calendar, timeZone: timeZone)

        let model = EidMubarakEngine.model(now: now, mode: .reference, calendar: calendar, timeZone: timeZone)

        #expect(model?.subtitle == "Eid al-Fitr")
        #expect(model?.message.contains("Preview") == false)
    }

    private func makeAdjustedCalendar() -> AdjustedHijriCalendar {
        let suiteName = "TodayEidCardTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return AdjustedHijriCalendar(
            calendarService: HijriCalendarService(
                baselineProvider: HijriBaselineMonthStarts.starts,
                adjustmentStore: HijriMonthAdjustmentStore(defaults: defaults)
            )
        )
    }

    private func makeAdjustedHijriDate(
        year: Int,
        month: HijriMonth,
        day: Int,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> Date {
        let date = calendar.gregorianDate(
            for: HijriYearMonth(hijriYear: year, month: month),
            dayOfMonth: day,
            timeZone: timeZone
        )
        #expect(date != nil)
        return date ?? Date()
    }
}
