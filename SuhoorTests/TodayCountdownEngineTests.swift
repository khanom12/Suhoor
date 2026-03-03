import Foundation
import Testing
@testable import Suhoor

@Suite
struct TodayCountdownEngineTests {
    @Test
    func countdownTargetBeforeFajrIsFajr() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let dayStart = makeDate(year: 2026, month: 3, day: 3, hour: 0, minute: 0, timeZone: timeZone)
        let now = makeDate(year: 2026, month: 3, day: 3, hour: 4, minute: 0, timeZone: timeZone)

        let snapshot = makeSnapshot(
            todayStart: dayStart,
            fajrHour: 5,
            fajrMinute: 0,
            maghribHour: 18,
            maghribMinute: 0,
            iftarOffsetMinutes: nil,
            timeZone: timeZone
        )

        let target = TodayCountdownEngine.target(now: now, snapshot: snapshot, timeZone: timeZone)
        #expect(target?.kind == .fajr)
        #expect(target?.targetDate == makeDate(year: 2026, month: 3, day: 3, hour: 5, minute: 0, timeZone: timeZone))
    }

    @Test
    func countdownTargetBetweenFajrAndMaghribIsIftar() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let dayStart = makeDate(year: 2026, month: 3, day: 3, hour: 0, minute: 0, timeZone: timeZone)
        let now = makeDate(year: 2026, month: 3, day: 3, hour: 12, minute: 0, timeZone: timeZone)

        let snapshot = makeSnapshot(
            todayStart: dayStart,
            fajrHour: 5,
            fajrMinute: 0,
            maghribHour: 18,
            maghribMinute: 0,
            iftarOffsetMinutes: nil,
            timeZone: timeZone
        )

        let target = TodayCountdownEngine.target(now: now, snapshot: snapshot, timeZone: timeZone)
        #expect(target?.kind == .iftar)
        #expect(target?.targetDate == makeDate(year: 2026, month: 3, day: 3, hour: 18, minute: 0, timeZone: timeZone))
    }

    @Test
    func countdownTargetUsesIftarDateWhenPresent() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let dayStart = makeDate(year: 2026, month: 3, day: 3, hour: 0, minute: 0, timeZone: timeZone)
        let now = makeDate(year: 2026, month: 3, day: 3, hour: 17, minute: 50, timeZone: timeZone)

        let snapshot = makeSnapshot(
            todayStart: dayStart,
            fajrHour: 5,
            fajrMinute: 0,
            maghribHour: 18,
            maghribMinute: 0,
            iftarOffsetMinutes: 5,
            timeZone: timeZone
        )

        let target = TodayCountdownEngine.target(now: now, snapshot: snapshot, timeZone: timeZone)
        #expect(target?.kind == .iftar)
        #expect(target?.targetDate == makeDate(year: 2026, month: 3, day: 3, hour: 18, minute: 5, timeZone: timeZone))
    }

    @Test
    func countdownTargetAfterMaghribIsTomorrowFajr() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let dayStart = makeDate(year: 2026, month: 3, day: 3, hour: 0, minute: 0, timeZone: timeZone)
        let now = makeDate(year: 2026, month: 3, day: 3, hour: 20, minute: 0, timeZone: timeZone)

        let snapshot = makeSnapshot(
            todayStart: dayStart,
            fajrHour: 5,
            fajrMinute: 0,
            maghribHour: 18,
            maghribMinute: 0,
            iftarOffsetMinutes: nil,
            timeZone: timeZone
        )

        let target = TodayCountdownEngine.target(now: now, snapshot: snapshot, timeZone: timeZone)
        #expect(target?.kind == .fajr)
        #expect(target?.targetDate == makeDate(year: 2026, month: 3, day: 4, hour: 5, minute: 0, timeZone: timeZone))
    }

    // MARK: - Helpers

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

    private func makeSnapshot(
        todayStart: Date,
        fajrHour: Int,
        fajrMinute: Int,
        maghribHour: Int,
        maghribMinute: Int,
        iftarOffsetMinutes: Int?,
        timeZone: TimeZone
    ) -> ActiveAlarmWindowSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        func makeSchedule(dayStart: Date) -> DaySchedule {
            let fajr = calendar.date(byAdding: .hour, value: fajrHour, to: dayStart)!
            let fajrWithMinutes = calendar.date(byAdding: .minute, value: fajrMinute, to: fajr)!
            let maghrib = calendar.date(byAdding: .hour, value: maghribHour, to: dayStart)!
            let maghribWithMinutes = calendar.date(byAdding: .minute, value: maghribMinute, to: maghrib)!
            let iftar = iftarOffsetMinutes.map { calendar.date(byAdding: .minute, value: $0, to: maghribWithMinutes)! }
            let wake = calendar.date(byAdding: .minute, value: -30, to: fajrWithMinutes)!

            return DaySchedule(
                date: dayStart,
                fajrDate: fajrWithMinutes,
                maghribDate: maghribWithMinutes,
                wakeDate: wake,
                reminderDate: nil,
                boundaryDate: nil,
                iftarDate: iftar,
                fajrSoundChoice: nil,
                iftarSoundChoice: nil,
                locationDescription: "Test",
                offsetMinutes: 0,
                calculationMethodName: "Test",
                timeZone: timeZone
            )
        }

        let todaySchedule = makeSchedule(dayStart: todayStart)
        let tomorrowSchedule = makeSchedule(dayStart: tomorrowStart)

        let todayKey = DateHelpers.dayIdentifier(for: todayStart, timeZone: timeZone)
        let tomorrowKey = DateHelpers.dayIdentifier(for: tomorrowStart, timeZone: timeZone)

        let todayDay = ActiveAlarmDay(
            date: todayStart,
            dateKey: todayKey,
            schedule: todaySchedule,
            effectiveConfig: sampleEffectiveDailyConfig(date: todayStart),
            provenances: [],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: nil,
            sourceSummaryText: "Test"
        )

        let tomorrowDay = ActiveAlarmDay(
            date: tomorrowStart,
            dateKey: tomorrowKey,
            schedule: tomorrowSchedule,
            effectiveConfig: sampleEffectiveDailyConfig(date: tomorrowStart),
            provenances: [],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: nil,
            sourceSummaryText: "Test"
        )

        return ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: [todayDay, tomorrowDay],
            scheduledDays: [todayDay, tomorrowDay],
            visibleHorizonDays: 60,
            scheduledHorizonDays: 30
        )
    }

    private func sampleEffectiveDailyConfig(date: Date) -> EffectiveDailyConfig {
        EffectiveDailyConfig(
            date: date,
            defaultsActive: true,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: false,
            fajrEnabled: false,
            iftarEnabled: false,
            suhoorTimeMode: .relativeToFajrMinusMinutes,
            suhoorOffsetMinutes: 30,
            reminderTimeMode: .beforeFajr,
            reminderMinutesBeforeFajr: 10,
            reminderFixedTimeMinutes: 0,
            suhoorTimeOverrideMinutesFromMidnight: nil,
            reminderTimeOverrideMinutesFromMidnight: nil,
            fajrSoundChoice: .systemDefault,
            iftarDelivery: .notificationOnly,
            iftarSoundChoice: .adhanSoft,
            hasOverrides: false
        )
    }
}

