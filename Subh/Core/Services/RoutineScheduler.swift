import Foundation
import UserNotifications
import os
#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
protocol RoutineScheduling: AnyObject {
    func scheduleEvent(
        identifier: String,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        schedule: DaySchedule,
        settings: AppSettings,
        canUseAlarmKit: Bool,
        now: Date
    ) async -> Bool

    func cancelEvent(
        identifier: String,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        schedule: DaySchedule
    ) async

    func cancelIdentifiers(_ identifiers: SchedulingIdentifierSet) async
    func cancelAllUpcoming(days: Int) async
}

@MainActor
final class RoutineScheduler: RoutineScheduling {
    private let notificationScheduler: NotificationScheduler
    private let alarmKitScheduler: AlarmKitScheduling?
    private let alarmCoordinator: AlarmCoordinator?
    private let eventLog = EventTimelineLog.shared

    init(
        notificationScheduler: NotificationScheduler,
        alarmKitScheduler: AlarmKitScheduling?,
        alarmCoordinator: AlarmCoordinator?
    ) {
        self.notificationScheduler = notificationScheduler
        self.alarmKitScheduler = alarmKitScheduler
        self.alarmCoordinator = alarmCoordinator
    }

    func scheduleEvent(
        identifier: String,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        schedule: DaySchedule,
        settings: AppSettings,
        canUseAlarmKit: Bool,
        now: Date
    ) async -> Bool {
        guard event.fireDate > now else {
            eventLog.record(category: "schedule", message: "Skip event in past id=\(identifier) date=\(event.fireDate)")
            return true
        }

        if canUseAlarmKit,
           event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue,
           deliveryKind == .boundary {
            eventLog.record(category: "schedule", message: "Checkpoint retained for in-session takeover id=\(identifier)")
            return true
        }

        if canUseAlarmKit, deliveryKind != .iftarNotification, #available(iOS 26.0, *) {
            let soundName = alarmSoundName(
                for: event.soundRole,
                kind: deliveryKind,
                schedule: schedule,
                settings: settings
            )
            let alarmID = SchedulingIdentifiers.alarmID(
                for: event,
                deliveryKind: deliveryKind,
                channel: .alarmKit
            )
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: alarmID,
                    kind: deliveryKind,
                    date: event.fireDate,
                    label: settings.label,
                    fajrDateTime: schedule.fajrDate,
                    dateKey: event.dateKey,
                    wakeSessionID: event.wakeSessionID,
                    soundRole: event.soundRole,
                    wakeSessionRole: event.wakeSessionRole,
                    fajrStartBehavior: event.fajrStartBehavior,
                    soundName: soundName,
                    snoozeDuration: nil
                )
                eventLog.record(category: "schedule", message: "Scheduled AlarmKit event id=\(identifier) date=\(event.fireDate) kind=\(deliveryKind.rawValue)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        id: alarmID,
                        kind: deliveryKind,
                        date: event.fireDate,
                        label: settings.label,
                        soundName: soundName
                    )
                    eventLog.record(category: "schedule", message: "Scheduled AlarmKit event id=\(identifier) date=\(event.fireDate) kind=\(deliveryKind.rawValue)")
                    return true
                } catch {
                    Logging.scheduler.error("AlarmKit scheduling error: \(error.localizedDescription)")
                    eventLog.record(category: "schedule", message: "AlarmKit scheduling error: \(error.localizedDescription)")
                    return false
                }
            }
        }

        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            event: event,
            deliveryKind: deliveryKind,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled notification event id=\(identifier) date=\(event.fireDate) kind=\(deliveryKind.rawValue)")
        return scheduled
    }

    func cancelEvent(
        identifier: String,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        schedule: DaySchedule
    ) async {
        if deliveryKind != .iftarNotification {
            let identifiers = SchedulingIdentifierSet.forEvent(event, deliveryKind: deliveryKind)
            if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
                alarmCoordinator.cancel(ids: identifiers.alarmIdentifiers)
            } else if #available(iOS 26.0, *), let alarmKitScheduler {
                alarmKitScheduler.cancel(ids: identifiers.alarmIdentifiers)
            }
        }
        await notificationScheduler.cancelNotifications(identifiers: [identifier])
        eventLog.record(category: "schedule", message: "Cancelled event id=\(identifier) kind=\(deliveryKind.rawValue) day=\(schedule.id)")
    }

    func cancelWake(for schedule: DaySchedule) async {
        eventLog.record(category: "schedule", message: "Cancel wake for \(schedule.id)")
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            alarmCoordinator.cancel(id: SchedulingIdentifiers.alarmID(for: schedule, kind: .wake))
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancel(schedule: schedule, kind: .wake)
        }
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake)])
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .wake)])
    }

    func cancelReminder(for schedule: DaySchedule) async {
        eventLog.record(category: "schedule", message: "Cancel reminder for \(schedule.id)")
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            alarmCoordinator.cancel(id: SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder))
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancel(schedule: schedule, kind: .reminder)
        }
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .reminder)])
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .reminder)])
    }

    func cancelAdhan(for schedule: DaySchedule) async {
        eventLog.record(category: "schedule", message: "Cancel adhan for \(schedule.id)")
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            alarmCoordinator.cancel(id: SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary))
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancel(schedule: schedule, kind: .boundary)
        }
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .boundary)])
        await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .boundary)])
    }

    func cancelIftar(for schedule: DaySchedule) async {
        eventLog.record(category: "schedule", message: "Cancel iftar for \(schedule.id)")
        let kinds: [ScheduleEventKind] = [.iftarNotification, .iftarAlarm, .iftarAdhan]
        for kind in kinds {
            if kind != .iftarNotification {
                if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
                    alarmCoordinator.cancel(id: SchedulingIdentifiers.alarmID(for: schedule, kind: kind))
                } else if #available(iOS 26.0, *), let alarmKitScheduler {
                    alarmKitScheduler.cancel(schedule: schedule, kind: kind)
                }
            }
            await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: kind)])
            await notificationScheduler.cancelNotifications(identifiers: [SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: kind)])
        }
    }

    func cancelAllUpcoming(days: Int) async {
        eventLog.record(category: "schedule", message: "Cancel all upcoming schedules (days=\(days))")
        let identifiers = SchedulingIdentifierSet.forUpcoming(days: days)
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            alarmCoordinator.cancel(ids: identifiers.alarmIdentifiers)
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancel(ids: identifiers.alarmIdentifiers)
        }
        await notificationScheduler.cancelNotifications(identifiers: identifiers.notificationIdentifiers)
    }

    func cancelIdentifiers(_ identifiers: SchedulingIdentifierSet) async {
        eventLog.record(
            category: "schedule",
            message: "Cancel identifier set notifications=\(identifiers.notificationIdentifiers.count) alarms=\(identifiers.alarmIdentifiers.count)"
        )
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            alarmCoordinator.cancel(ids: identifiers.alarmIdentifiers)
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancel(ids: identifiers.alarmIdentifiers)
        }
        await notificationScheduler.cancelNotifications(identifiers: identifiers.notificationIdentifiers)
    }

    private func alarmSoundName(
        for soundRole: MorningSoundRole?,
        kind: ScheduleEventKind,
        schedule: DaySchedule,
        settings: AppSettings
    ) -> String? {
        if let soundRole {
            return alarmSoundName(for: settings.soundChoice(for: soundRole), role: soundRole)
        }

        switch kind {
        case .boundary:
            return alarmSoundName(for: schedule.fajrSoundChoice ?? settings.atFajrSoundSelectionGlobal, role: .fajrStart)
        case .iftarAdhan:
            let soundChoice = schedule.iftarSoundChoice
            return alarmSoundName(for: soundChoice ?? .adhanSoft, role: .iftar)
        default:
            return nil
        }
    }

    private func alarmSoundName(for kind: ScheduleEventKind, schedule: DaySchedule, settings: AppSettings) -> String? {
        alarmSoundName(for: nil, kind: kind, schedule: schedule, settings: settings)
    }

    private func alarmSoundName(for soundChoice: SoundChoice, role: MorningSoundRole) -> String? {
        guard soundChoice == .adhanSoft else { return nil }
        switch role {
        case .preFajrWake, .fajrStart, .inFajrWake, .postFajrWake, .fixedWake:
            if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
                return "adhan_fajr.caf"
            }
            return nil
        case .reminder:
            return nil
        case .iftar:
            if Bundle.main.url(forResource: "adhan", withExtension: "caf") != nil {
                return "adhan.caf"
            }
            if Bundle.main.url(forResource: "adhan_maghrib", withExtension: "caf") != nil {
                return "adhan_maghrib.caf"
            }
            return nil
        }
    }

    private func legacyAlarmSoundName(for kind: ScheduleEventKind, schedule: DaySchedule, settings: AppSettings) -> String? {
        switch kind {
        case .boundary:
            let soundChoice = schedule.fajrSoundChoice ?? settings.atFajrSoundSelectionGlobal
            guard soundChoice == .adhanSoft else { return nil }
            if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
                return "adhan_fajr.caf"
            }
            return nil
        case .iftarAdhan:
            let soundChoice = schedule.iftarSoundChoice
            guard soundChoice == .adhanSoft else { return nil }
            if Bundle.main.url(forResource: "adhan", withExtension: "caf") != nil {
                return "adhan.caf"
            }
            if Bundle.main.url(forResource: "adhan_maghrib", withExtension: "caf") != nil {
                return "adhan_maghrib.caf"
            }
            return nil
        default:
            return nil
        }
    }

    private func notificationIdentifiers(days: Int) -> [String] {
        collectNotificationIdentifiers(days: days) { schedule, kind in
            SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: kind)
        }
    }

    private func legacyNotificationIdentifiers(days: Int) -> [String] {
        collectNotificationIdentifiers(days: days) { schedule, kind in
            SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: kind)
        }
    }

    private func collectNotificationIdentifiers(
        days: Int,
        identifier: (DaySchedule, ScheduleEventKind) -> String
    ) -> [String] {
        let start = DateHelpers.startOfToday()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var results: [String] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let schedule = stubSchedule(for: day)
            results.append(identifier(schedule, .wake))
            results.append(identifier(schedule, .reminder))
            results.append(identifier(schedule, .boundary))
            results.append(identifier(schedule, .iftarNotification))
            results.append(identifier(schedule, .iftarAlarm))
            results.append(identifier(schedule, .iftarAdhan))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .wakeAlarm), deliveryKind: .wake))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .wakeReminder), deliveryKind: .reminder))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .fajrBoundaryNotice), deliveryKind: .boundary))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .iftarReminder), deliveryKind: .iftarNotification))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .iftarReminder), deliveryKind: .iftarAlarm))
            results.append(SchedulingIdentifiers.identifier(for: eventStub(for: schedule, type: .iftarReminder), deliveryKind: .iftarAdhan))
        }
        return results
    }

    private func stubSchedule(for day: Date) -> DaySchedule {
        DaySchedule(
            date: day,
            fajrDate: day,
            maghribDate: day,
            wakeDate: day,
            reminderDate: nil,
            boundaryDate: nil,
            iftarDate: nil,
            fajrSoundChoice: nil,
            iftarSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: 0,
            calculationMethodName: "",
            timeZone: .current
        )
    }

    private func eventStub(for schedule: DaySchedule, type: ScheduledEventType) -> ScheduledEvent {
        ScheduledEvent(
            id: "\(schedule.id).\(type.rawValue)",
            type: type,
            dateKey: schedule.id,
            fireDate: schedule.date,
            relativeTo: .absolute,
            isUserVisible: true,
            affectsCompletion: type == .wakeAlarm,
            deliveryKinds: []
        )
    }

    private func upcomingSchedules(days: Int) -> [DaySchedule] {
        let start = DateHelpers.startOfToday()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var schedules: [DaySchedule] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            schedules.append(stubSchedule(for: day))
        }
        return schedules
    }
}
