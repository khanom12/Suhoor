import Foundation
import os

@MainActor
final class AlarmScheduler {
    private let routineScheduler: RoutineScheduler
    private var lastPlannedEvents: [String: PlannedScheduledEvent] = [:]

    init(routineScheduler: RoutineScheduler) {
        self.routineScheduler = routineScheduler
    }

    func resetReconciliationState() {
        lastPlannedEvents.removeAll()
    }

    func scheduleAll(
        entries: [(DaySchedule, EffectiveDailyConfig)],
        settings: AppSettings,
        canUseAlarmKit: Bool,
        cancelWindowDays: Int
    ) async -> Bool {
        let nextPlans = buildPlannedEvents(
            entries: entries,
            settings: settings,
            canUseAlarmKit: canUseAlarmKit
        )

        if lastPlannedEvents.isEmpty {
            await routineScheduler.cancelAllUpcoming(days: cancelWindowDays)
        }

        return await reconcile(
            to: nextPlans,
            settings: settings,
            affectedDayIDs: nil
        )
    }

    func scheduleDay(
        schedule: DaySchedule,
        config: EffectiveDailyConfig,
        settings: AppSettings,
        canUseAlarmKit: Bool
    ) async -> Bool {
        let nextPlans = buildPlannedEvents(
            entries: [(schedule, config)],
            settings: settings,
            canUseAlarmKit: canUseAlarmKit
        )
        return await reconcile(
            to: nextPlans,
            settings: settings,
            affectedDayIDs: [schedule.id]
        )
    }

    func cancelDay(schedule: DaySchedule) async {
        if lastPlannedEvents.values.contains(where: { $0.dayID == schedule.id }) == false {
            await routineScheduler.cancelWake(for: schedule)
            await routineScheduler.cancelReminder(for: schedule)
            await routineScheduler.cancelAdhan(for: schedule)
            return
        }
        _ = await reconcile(
            to: [:],
            settings: nil,
            affectedDayIDs: [schedule.id]
        )
    }

    private func reconcile(
        to nextPlans: [String: PlannedScheduledEvent],
        settings: AppSettings?,
        affectedDayIDs: Set<String>?
    ) async -> Bool {
        let previousPlans: [String: PlannedScheduledEvent]
        let scopedNextPlans: [String: PlannedScheduledEvent]

        if let affectedDayIDs {
            previousPlans = lastPlannedEvents.filter { affectedDayIDs.contains($0.value.dayID) }
            scopedNextPlans = nextPlans.filter { affectedDayIDs.contains($0.value.dayID) }
        } else {
            previousPlans = lastPlannedEvents
            scopedNextPlans = nextPlans
        }

        var success = true

        for previous in previousPlans.values.sorted(by: { $0.fireDate < $1.fireDate }) {
            if let next = scopedNextPlans[previous.planID], next == previous {
                continue
            }
            await cancel(previous)
        }

        if let settings {
            for next in scopedNextPlans.values.sorted(by: { $0.fireDate < $1.fireDate }) {
                if previousPlans[next.planID] == next {
                    continue
                }
                success = await schedule(next, settings: settings) && success
            }
        }

        if let affectedDayIDs {
            lastPlannedEvents = lastPlannedEvents.filter { !affectedDayIDs.contains($0.value.dayID) }
            for (id, plan) in scopedNextPlans {
                lastPlannedEvents[id] = plan
            }
        } else {
            lastPlannedEvents = scopedNextPlans
        }

        return success
    }

    private func buildPlannedEvents(
        entries: [(DaySchedule, EffectiveDailyConfig)],
        settings: AppSettings,
        canUseAlarmKit: Bool
    ) -> [String: PlannedScheduledEvent] {
        let now = Date()
        let channel: PlannedScheduledEvent.Channel = canUseAlarmKit ? .alarmKit : .notification
        var plans: [String: PlannedScheduledEvent] = [:]

        for (schedule, config) in entries {
            guard !config.skipDay else { continue }

            if config.suhoorEnabled, schedule.wakeDate > now {
                let plan = PlannedScheduledEvent(
                    planID: SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake),
                    dayID: schedule.id,
                    kind: .wake,
                    channel: channel,
                    fireDate: schedule.wakeDate,
                    schedule: schedule,
                    label: settings.label,
                    snoozeMinutes: FeatureFlags.enableSnooze && settings.snoozeEnabled ? settings.snoozeMinutes : nil
                )
                plans[plan.planID] = plan
            }

            if config.reminderEnabled, let reminderDate = schedule.reminderDate, reminderDate > now {
                if reminderDate < schedule.wakeDate {
                    Logging.scheduler.warning("Reminder earlier than Suhoor for \(schedule.id). Skipping reminder scheduling.")
                } else {
                    let plan = PlannedScheduledEvent(
                        planID: SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .reminder),
                        dayID: schedule.id,
                        kind: .reminder,
                        channel: channel,
                        fireDate: reminderDate,
                        schedule: schedule,
                        label: settings.label,
                        snoozeMinutes: nil
                    )
                    plans[plan.planID] = plan
                }
            }

            if config.fajrEnabled, let boundaryDate = schedule.boundaryDate, boundaryDate > now {
                let plan = PlannedScheduledEvent(
                    planID: SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .boundary),
                    dayID: schedule.id,
                    kind: .boundary,
                    channel: channel,
                    fireDate: boundaryDate,
                    schedule: schedule,
                    label: settings.label,
                    snoozeMinutes: nil
                )
                plans[plan.planID] = plan
            }
        }

        return plans
    }

    private func schedule(_ plan: PlannedScheduledEvent, settings: AppSettings) async -> Bool {
        switch plan.kind {
        case .wake:
            let suhoorSettings = settings.withSuhoorEnabled(true)
            return await routineScheduler.scheduleWake(
                for: plan.schedule,
                settings: suhoorSettings,
                canUseAlarmKit: plan.channel == .alarmKit
            )
        case .reminder:
            return await routineScheduler.scheduleReminder(
                for: plan.schedule,
                settings: settings,
                canUseAlarmKit: plan.channel == .alarmKit
            )
        case .boundary:
            return await routineScheduler.scheduleAdhan(
                for: plan.schedule,
                settings: settings,
                canUseAlarmKit: plan.channel == .alarmKit
            )
        }
    }

    private func cancel(_ plan: PlannedScheduledEvent) async {
        switch plan.kind {
        case .wake:
            await routineScheduler.cancelWake(for: plan.schedule)
        case .reminder:
            await routineScheduler.cancelReminder(for: plan.schedule)
        case .boundary:
            await routineScheduler.cancelAdhan(for: plan.schedule)
        }
    }
}

private struct PlannedScheduledEvent: Equatable {
    enum Channel: Equatable {
        case alarmKit
        case notification
    }

    let planID: String
    let dayID: String
    let kind: ScheduleEventKind
    let channel: Channel
    let fireDate: Date
    let schedule: DaySchedule
    let label: String
    let snoozeMinutes: Int?
}
