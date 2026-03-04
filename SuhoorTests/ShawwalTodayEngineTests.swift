import Foundation
import Testing
@testable import Suhoor

@Suite
struct ShawwalTodayEngineTests {
    @Test
    func progressModelIsUnavailableOnFirstOfShawwal() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 1, calendar: calendar, timeZone: timeZone)

        let model = ShawwalSixProgressEngine.model(
            now: now,
            mode: .live,
            scheduledEntries: [],
            selections: [:],
            logEntries: [:],
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(model == nil)
    }

    @Test
    func progressModelCountsCompletedAndPendingTaggedDays() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 4, calendar: calendar, timeZone: timeZone)

        let dates = (2...7).map {
            makeAdjustedHijriDate(year: 1447, month: .shawwal, day: $0, calendar: calendar, timeZone: timeZone)
        }
        let logEntries = Dictionary(uniqueKeysWithValues: dates.enumerated().map { index, date in
            let status: FastLogStatus
            switch index {
            case 0, 1:
                status = .completed
            case 2:
                status = .inProgress
            default:
                status = .unknown
            }
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
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

        let model = ShawwalSixProgressEngine.model(
            now: now,
            mode: .live,
            scheduledEntries: [],
            selections: [:],
            logEntries: logEntries,
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(model?.completedCount == 2)
        #expect(model?.hasPendingToday == true)
        #expect(model?.displayFilledCount == 3)
    }

    @Test
    func forbiddenDayEngineSupportsLiveAndReferenceStates() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let eidAlFitr = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 1, calendar: calendar, timeZone: timeZone)
        let regularShawwalDay = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 5, calendar: calendar, timeZone: timeZone)

        let liveModel = ForbiddenFastDayEngine.model(
            kind: .eidAlFitr,
            mode: .live,
            now: eidAlFitr,
            calendar: calendar,
            timeZone: timeZone
        )
        let previewModel = ForbiddenFastDayEngine.model(
            kind: .eidAlFitr,
            mode: .reference,
            now: regularShawwalDay,
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(liveModel?.title == "Eid al-Fitr")
        #expect(previewModel?.title == "Eid al-Fitr")
        #expect(liveModel?.message == "It is not allowed to fast today.")
        #expect(previewModel?.message == "It is not allowed to fast on this day.")
    }

    @Test
    func referenceModelExistsOutsideShawwalWithoutPendingState() {
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = makeAdjustedCalendar()
        let now = makeAdjustedHijriDate(year: 1447, month: .ramadan, day: 15, calendar: calendar, timeZone: timeZone)

        let shawwalDate = makeAdjustedHijriDate(year: 1447, month: .shawwal, day: 2, calendar: calendar, timeZone: timeZone)
        let key = DateHelpers.dayIdentifier(for: shawwalDate, timeZone: timeZone)
        let logEntries = [
            key: FastLogEntry(
                dateKey: key,
                status: .inProgress,
                updatedAt: now,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .voluntary, secondaryTags: [])
            )
        ]

        let model = ShawwalSixProgressEngine.model(
            now: now,
            mode: .reference,
            scheduledEntries: [],
            selections: [:],
            logEntries: logEntries,
            calendar: calendar,
            timeZone: timeZone
        )

        #expect(model?.hijriYear == 1447)
        #expect(model?.hasPendingToday == false)
    }

    private func makeAdjustedCalendar() -> AdjustedHijriCalendar {
        let suiteName = "ShawwalTodayEngineTests.\(UUID().uuidString)"
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
