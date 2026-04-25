import CoreLocation
import Foundation
import os

@MainActor
final class DayScheduleBuilder {
    private let calculator: PrayerTimeCalculator

    init(calculator: PrayerTimeCalculator = PrayerTimeCalculator()) {
        self.calculator = calculator
    }

    func buildSchedule(from context: ResolvedDayBuildContext) -> DaySchedule {
        LegacyResolvedDayAdapter.makeSchedule(
            snapshot: context.snapshot,
            effectiveConfig: context.effectiveConfig,
            settings: context.settings,
            locationDescription: context.locationDescription,
            timeZone: context.timeZone
        )
    }

    func buildSchedule(
        for day: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        method: CalculationMethod,
        adjustmentMinutes: Int,
        maghribAdjustmentMinutes: Int,
        effectiveConfig: EffectiveDailyConfig,
        locationDescription: String
    ) -> DaySchedule? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let fajr = calculator.fajrDate(
            for: day,
            location: coordinate,
            timeZone: timeZone,
            method: method,
            adjustmentMinutes: adjustmentMinutes
        ) else {
            return nil
        }
        guard let maghrib = calculator.maghribDate(
            for: day,
            location: coordinate,
            timeZone: timeZone,
            adjustmentMinutes: maghribAdjustmentMinutes
        ) else {
            return nil
        }

        let fajrEnd = calculator.sunriseDate(
            for: day,
            location: coordinate,
            timeZone: timeZone,
            adjustmentMinutes: 0
        )
        let prayerWindow = DailyPrayerWindow(
            date: day,
            fajrStart: fajr,
            fajrEnd: fajrEnd,
            maghrib: maghrib
        )
        let wakeAnchor = MorningScheduleResolver.resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: day,
            wakeRule: effectiveConfig.resolvedWakeRule,
            timeZone: timeZone
        )
        let wakeResolution = MorningScheduleResolver.resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: wakeAnchor,
            wakeRule: effectiveConfig.resolvedWakeRule,
            timeZone: timeZone
        )
        let wake = wakeResolution.finalWakeTime
        let offsetMinutes = Int(round(fajr.timeIntervalSince(wake) / 60))
        let reminder = effectiveConfig.reminderEnabled
            ? resolvedReminderDate(for: day, suhoor: wake, fajr: fajr, config: effectiveConfig, calendar: calendar)
            : nil
        let boundary = effectiveConfig.fajrEnabled && wake < fajr ? fajr : nil
        let iftar = effectiveConfig.iftarEnabled ? maghrib : nil

        return DaySchedule(
            date: day,
            fajrDate: fajr,
            maghribDate: maghrib,
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            iftarDate: iftar,
            fajrSoundChoice: effectiveConfig.fajrSoundChoice,
            iftarSoundChoice: effectiveConfig.iftarSoundChoice,
            locationDescription: locationDescription,
            offsetMinutes: offsetMinutes,
            calculationMethodName: method.displayName,
            timeZone: timeZone
        )
    }

    private func resolvedReminderDate(
        for day: Date,
        suhoor: Date,
        fajr: Date,
        config: EffectiveDailyConfig,
        calendar: Calendar
    ) -> Date? {
        let result = computedReminderTime(
            for: day,
            suhoor: suhoor,
            fajr: fajr,
            config: config,
            calendar: calendar
        )
        if result.wasClampedToSuhoor {
            Logging.scheduler.info("Reminder clamped to main wake for \(DateHelpers.dayIdentifier(for: day, timeZone: calendar.timeZone)).")
        }
        return result.reminderTime
    }

    private func computedReminderTime(
        for day: Date,
        suhoor: Date,
        fajr: Date,
        config: EffectiveDailyConfig,
        calendar: Calendar
    ) -> TimeValidationResult {
        let reminderDate: Date
        if let overrideMinutes = config.reminderTimeOverrideMinutesFromMidnight {
            reminderDate = dateFromMidnight(for: day, minutes: overrideMinutes, calendar: calendar)
        } else if config.reminderTimeMode == .fixedTime {
            reminderDate = dateFromMidnight(for: day, minutes: config.reminderFixedTimeMinutes, calendar: calendar)
        } else {
            reminderDate = ScheduleEventCalculator.reminderDate(
                for: fajr,
                reminderMinutes: config.reminderMinutesBeforeFajr,
                calendar: calendar
            )
        }
        return TimeValidation.validateDailyTimes(suhoorTime: suhoor, reminderTime: reminderDate)
    }

    private func dateFromMidnight(for day: Date, minutes: Int, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}
