import Foundation
import Testing
@testable import Suhoor

@Suite
struct HijriSpecialDayPlannerTests {
    @Test
    func disabledMasterToggleProducesNoDates() {
        let suiteName = "HijriSpecialDayPlannerTests.Disabled"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)
        let planner = HijriSpecialDayPlanner(calendarService: HijriCalendarService(adjustmentStore: store))
        let plan = planner.plan(
            settings: .default,
            startDate: makeDate(year: 2026, month: 2, day: 1),
            days: 90,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        #expect(plan.datesByScope.isEmpty)
    }

    @Test
    func enabledFeaturesYieldExpectedDatesInsideHorizon() {
        let suiteName = "HijriSpecialDayPlannerTests.Enabled"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)
        let planner = HijriSpecialDayPlanner(calendarService: HijriCalendarService(adjustmentStore: store))
        let settings = HijriSpecialDaySettings(
            isEnabled: true,
            ramadanDailyEnabled: true,
            whiteDaysEnabled: true,
            ashuraEnabled: false,
            arafahEnabled: true,
            eidAlFitrEnabled: true,
            eidAlAdhaEnabled: false
        )
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let plan = planner.plan(
            settings: settings,
            startDate: makeDate(year: 2026, month: 2, day: 1),
            days: 140,
            timeZone: timeZone
        )

        #expect(!(plan.dates(for: .ramadanDaily)).isEmpty)
        #expect(plan.dates(for: .whiteDays).count >= 3)
        #expect(plan.dates(for: .eidAlFitr).count == 1)
        #expect(plan.dates(for: .arafah).count == 1)
    }

    @Test
    func missingBaselineOmitsDatesWithoutThrowing() {
        let suiteName = "HijriSpecialDayPlannerTests.Missing"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)
        let service = HijriCalendarService(
            baselineProvider: { _, _ in [] },
            adjustmentStore: store
        )
        let planner = HijriSpecialDayPlanner(calendarService: service)
        let settings = HijriSpecialDaySettings(
            isEnabled: true,
            ramadanDailyEnabled: true,
            whiteDaysEnabled: true,
            ashuraEnabled: true,
            arafahEnabled: true,
            eidAlFitrEnabled: true,
            eidAlAdhaEnabled: true
        )
        let plan = planner.plan(
            settings: settings,
            startDate: makeDate(year: 2026, month: 2, day: 1),
            days: 120,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        #expect(plan.datesByScope.isEmpty)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
