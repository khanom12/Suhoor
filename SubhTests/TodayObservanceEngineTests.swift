import Foundation
import Testing
@testable import Subh

@Suite
struct TodayObservanceEngineTests {
    @Test
    func liveContextSuppressesNonRamadanCardsDuringRamadan() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 15, calendar: calendar, timeZone: timeZone)

        let context = TodayObservanceEngine.liveContext(now: now, calendar: calendar, timeZone: timeZone)

        #expect(context?.isRamadan == true)
    }

    @Test
    func liveContextPrioritizesArafahOverDhulHijjahWindow() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .dhulHijjah, day: 9, calendar: calendar, timeZone: timeZone)

        let context = TodayObservanceEngine.liveContext(now: now, calendar: calendar, timeZone: timeZone)

        #expect(TodayObservanceEngine.primaryTag(for: context!) == .arafah)
        #expect(context?.secondaryTags.contains(.dhulHijjahFirstNine) == true)
    }

    @Test
    func whiteDaysReferenceAdvancesAfterFifteenth() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 20, calendar: calendar, timeZone: timeZone)

        let key = TodayObservanceEngine.whiteDaysTargetMonthKey(
            now: now,
            mode: .reference,
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(key?.month == .dhulQadah)
    }

    @Test
    func ashuraTrackerCountsTaggedDays() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1448, month: .muharram, day: 10, calendar: calendar, timeZone: timeZone)
        let targetMonth = TodayObservanceEngine.muharramTargetMonthKey(
            now: now,
            mode: .live,
            calendar: calendar,
            timeZone: timeZone
        )!

        let dates = (9...11).map {
            makeAdjustedHijriDate(year: 1448, month: .muharram, day: $0, calendar: calendar, timeZone: timeZone)
        }
        let logEntries = Dictionary(uniqueKeysWithValues: dates.enumerated().map { index, date in
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let status: FastLogStatus = index == 0 ? .completed : (index == 1 ? .inProgress : .unknown)
            return (
                key,
                FastLogEntry(
                    dateKey: key,
                    status: status,
                    updatedAt: now,
                    intentSnapshot: FastIntentSnapshot(primaryIntent: .voluntary, secondaryTags: [])
                )
            )
        })

        let model = TodayObservanceEngine.trackerModel(
            now: now,
            mode: .live,
            targetMonthKey: targetMonth,
            trackedDays: 9...11,
            trackedTag: .ashura,
            scheduledEntries: [],
            selections: [:],
            logEntries: logEntries,
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(model?.completedCount == 1)
        #expect(model?.hasPendingToday == true)
    }

    private func makeAdjustedCalendar() -> AdjustedHijriCalendar {
        let suiteName = "TodayObservanceEngineTests.\(UUID().uuidString)"
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
