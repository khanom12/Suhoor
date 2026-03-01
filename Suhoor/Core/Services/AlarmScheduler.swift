import Foundation
import os

final class AlarmScheduler {
    private let routineScheduler: RoutineScheduler

    init(routineScheduler: RoutineScheduler) {
        self.routineScheduler = routineScheduler
    }

    func scheduleAll(
        entries: [(DaySchedule, EffectiveDailyConfig)],
        settings: AppSettings,
        canUseAlarmKit: Bool,
        cancelWindowDays: Int
    ) async -> Bool {
        await routineScheduler.cancelAllUpcoming(days: cancelWindowDays)
        var success = true
        for (schedule, config) in entries {
            success = await scheduleDay(
                schedule: schedule,
                config: config,
                settings: settings,
                canUseAlarmKit: canUseAlarmKit
            ) && success
        }
        return success
    }

    func scheduleDay(
        schedule: DaySchedule,
        config: EffectiveDailyConfig,
        settings: AppSettings,
        canUseAlarmKit: Bool
    ) async -> Bool {
        if config.skipDay || !config.hasAnyEnabled {
            await cancelDay(schedule: schedule)
            return true
        }

        var success = true
        if config.suhoorEnabled {
            let suhoorSettings = settings.withSuhoorEnabled(true)
            success = await routineScheduler.scheduleWake(
                for: schedule,
                settings: suhoorSettings,
                canUseAlarmKit: canUseAlarmKit
            ) && success
        } else {
            await routineScheduler.cancelWake(for: schedule)
        }

        if config.reminderEnabled {
            if let reminderDate = schedule.reminderDate, reminderDate < schedule.wakeDate {
                Logging.scheduler.warning("Reminder earlier than Suhoor for \(schedule.id). Skipping reminder scheduling.")
                await routineScheduler.cancelReminder(for: schedule)
            } else {
                success = await routineScheduler.scheduleReminder(
                    for: schedule,
                    settings: settings,
                    canUseAlarmKit: canUseAlarmKit
                ) && success
            }
        } else {
            await routineScheduler.cancelReminder(for: schedule)
        }

        if config.fajrEnabled {
            success = await routineScheduler.scheduleAdhan(
                for: schedule,
                settings: settings,
                canUseAlarmKit: canUseAlarmKit
            ) && success
        } else {
            await routineScheduler.cancelAdhan(for: schedule)
        }

        return success
    }

    func cancelDay(schedule: DaySchedule) async {
        await routineScheduler.cancelWake(for: schedule)
        await routineScheduler.cancelReminder(for: schedule)
        await routineScheduler.cancelAdhan(for: schedule)
    }
}
