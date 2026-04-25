import Foundation
import UserNotifications
import os
#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
final class RoutineScheduler {
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

    // Root cause & fix summary:
    // - We were filtering daily schedules by wake time only. If Wake fired and the app re-scheduled
    //   afterward, the day was dropped and the Reminder/Adhan were never re-added.
    // - Identifiers were shared between legacy and new formats without explicit collision handling.
    // Fixes:
    // - Schedule eligibility now considers all enabled events, not just Wake.
    // - Each event type uses distinct, stable identifiers and we cancel legacy IDs explicitly.
    // - Scheduling now skips past events while keeping future ones and logs every decision.

    func scheduleAllEnabledEvents(
        schedules: [DaySchedule],
        settings: AppSettings,
        canUseAlarmKit: Bool
    ) async -> Bool {
        eventLog.record(category: "schedule", message: "scheduleAllEnabledEvents start days=\(schedules.count) canUseAlarmKit=\(canUseAlarmKit)")
        await cancelAllUpcoming(days: 30)
        let now = Date()
        var success = true
        for schedule in schedules {
            success = await scheduleWakeIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: now) && success
            success = await scheduleReminderIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: now) && success
            success = await scheduleAdhanIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: now) && success
            success = await scheduleIftarIfNeeded(for: schedule, settings: settings, now: now) && success
        }
        eventLog.record(category: "schedule", message: "scheduleAllEnabledEvents finished success=\(success)")
        return success
    }

    func scheduleWake(for schedule: DaySchedule, settings: AppSettings, canUseAlarmKit: Bool) async -> Bool {
        await scheduleWakeIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: Date())
    }

    func scheduleReminder(for schedule: DaySchedule, settings: AppSettings, canUseAlarmKit: Bool) async -> Bool {
        await scheduleReminderIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: Date())
    }

    func scheduleAdhan(for schedule: DaySchedule, settings: AppSettings, canUseAlarmKit: Bool) async -> Bool {
        await scheduleAdhanIfNeeded(for: schedule, settings: settings, canUseAlarmKit: canUseAlarmKit, now: Date())
    }

    func scheduleIftarNotification(for schedule: DaySchedule, settings: AppSettings) async -> Bool {
        guard let iftarDate = schedule.iftarDate else { return true }
        let identifier = SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .iftarNotification)
        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            kind: .iftarNotification,
            date: iftarDate,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled iftar notification id=\(identifier) date=\(iftarDate)")
        return scheduled
    }

    func scheduleIftarAudible(for schedule: DaySchedule, settings: AppSettings, canUseAlarmKit: Bool, kind: ScheduleEventKind) async -> Bool {
        guard let iftarDate = schedule.iftarDate else { return true }
        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let id = SchedulingIdentifiers.alarmID(for: schedule, kind: kind)
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: id,
                    kind: kind,
                    date: iftarDate,
                    label: settings.label,
                    fajrDateTime: schedule.fajrDate,
                    soundName: alarmSoundName(for: kind, schedule: schedule, settings: settings),
                    snoozeDuration: nil
                )
                eventLog.record(category: "schedule", message: "Scheduled iftar AlarmKit id=\(id.uuidString) date=\(iftarDate) kind=\(kind.rawValue)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        for: schedule,
                        kind: kind,
                        date: iftarDate,
                        label: settings.label,
                        soundName: alarmSoundName(for: kind, schedule: schedule, settings: settings)
                    )
                    eventLog.record(category: "schedule", message: "Scheduled iftar AlarmKit id=\(SchedulingIdentifiers.alarmID(for: schedule, kind: kind).uuidString) date=\(iftarDate) kind=\(kind.rawValue)")
                    return true
                } catch {
                    Logging.scheduler.error("AlarmKit iftar scheduling error: \(error.localizedDescription)")
                    eventLog.record(category: "schedule", message: "AlarmKit iftar scheduling error: \(error.localizedDescription)")
                    return false
                }
            }
        }

        let identifier = SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: kind)
        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            kind: kind,
            date: iftarDate,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled iftar fallback notification id=\(identifier) date=\(iftarDate) kind=\(kind.rawValue)")
        return scheduled
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
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind),
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
                    snoozeDuration: event.wakeSessionRole == .primaryWake && FeatureFlags.enableSnooze && settings.snoozeEnabled
                        ? TimeInterval(settings.snoozeMinutes * 60)
                        : nil
                )
                eventLog.record(category: "schedule", message: "Scheduled AlarmKit event id=\(identifier) date=\(event.fireDate) kind=\(deliveryKind.rawValue)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        id: SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind),
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
            if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
                alarmCoordinator.cancel(id: SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind))
            } else if #available(iOS 26.0, *), let alarmKitScheduler {
                alarmKitScheduler.cancel(schedule: schedule, kind: deliveryKind)
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
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            var ids: [UUID] = []
            let upcoming = upcomingSchedules(days: days)
            for schedule in upcoming {
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .wake))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .iftarAlarm))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .iftarAdhan))
                ids.append(SchedulingIdentifiers.alarmID(for: eventStub(for: schedule, type: .wakeAlarm), deliveryKind: .wake))
                ids.append(SchedulingIdentifiers.alarmID(for: eventStub(for: schedule, type: .wakeReminder), deliveryKind: .reminder))
                ids.append(SchedulingIdentifiers.alarmID(for: eventStub(for: schedule, type: .fajrBoundaryNotice), deliveryKind: .boundary))
                ids.append(SchedulingIdentifiers.alarmID(for: eventStub(for: schedule, type: .iftarReminder), deliveryKind: .iftarAlarm))
                ids.append(SchedulingIdentifiers.alarmID(for: eventStub(for: schedule, type: .iftarReminder), deliveryKind: .iftarAdhan))
                ids.append(SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: .wake))
                ids.append(SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: .reminder))
                ids.append(SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: .boundary))
            }
            alarmCoordinator.cancel(ids: ids)
        } else if #available(iOS 26.0, *), let alarmKitScheduler {
            await alarmKitScheduler.cancelAllUpcoming(days: days)
        }
        await notificationScheduler.cancelNotifications(identifiers: notificationIdentifiers(days: days))
        await notificationScheduler.cancelNotifications(identifiers: legacyNotificationIdentifiers(days: days))
    }

    func scheduleTestEvents(settings: AppSettings, canUseAlarmKit: Bool) async -> Bool {
        let details = await scheduleTestEventsDetails(settings: settings, canUseAlarmKit: canUseAlarmKit)
        return details.allSatisfy { $0.success }
    }

    struct TestEventDetail {
        let kind: ScheduleEventKind
        let channel: String
        let success: Bool
        let message: String
    }

    func scheduleTestEventsDetails(settings: AppSettings, canUseAlarmKit: Bool) async -> [TestEventDetail] {
        let now = Date()
        let wakeDate = now.addingTimeInterval(60)
        let reminderDate = now.addingTimeInterval(120)
        let adhanDate = now.addingTimeInterval(180)

        await notificationScheduler.cancelTestNotifications()
        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let ids = ScheduleEventKind.allCases.map { SchedulingIdentifiers.testAlarmID(for: $0) }
                alarmCoordinator.cancel(ids: ids)
            } else if let alarmKitScheduler {
                alarmKitScheduler.cancelTestAlarms()
            }
        }

        let dummySchedule = DaySchedule(
            date: now,
            fajrDate: adhanDate,
            maghribDate: now.addingTimeInterval(240),
            wakeDate: wakeDate,
            reminderDate: reminderDate,
            boundaryDate: adhanDate,
            iftarDate: now.addingTimeInterval(240),
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
            iftarSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: settings.baseWakeOffsetMinutes,
            calculationMethodName: settings.calculationMethod.displayName,
            timeZone: .current
        )

        eventLog.record(category: "schedule", message: "Scheduling test events +1/+2/+3 min")
        let wakeID = SchedulingIdentifiers.testAlarmID(for: .wake)
        let wakeNotificationID = SchedulingIdentifiers.testIdentifier(for: .wake)
        let reminderNotificationID = SchedulingIdentifiers.testIdentifier(for: .reminder)
        let reminderAlarmID = SchedulingIdentifiers.testAlarmID(for: .reminder)
        let adhanNotificationID = SchedulingIdentifiers.testIdentifier(for: .boundary)
        let adhanAlarmID = SchedulingIdentifiers.testAlarmID(for: .boundary)

        var results: [TestEventDetail] = []

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: wakeID,
                    kind: .wake,
                    date: wakeDate,
                    label: settings.label,
                    fajrDateTime: adhanDate,
                    soundName: nil,
                    snoozeDuration: FeatureFlags.enableSnooze && settings.snoozeEnabled
                        ? TimeInterval(settings.snoozeMinutes * 60)
                        : nil,
                    isTest: true,
                    testRunId: nil
                )
                eventLog.record(category: "schedule", message: "Test wake AlarmKit id=\(wakeID.uuidString) date=\(wakeDate)")
                results.append(TestEventDetail(
                    kind: .wake,
                    channel: "AlarmKit",
                    success: scheduled,
                    message: scheduled ? "Scheduled alarm." : "AlarmKit scheduling failed."
                ))
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        id: wakeID,
                        kind: .wake,
                        date: wakeDate,
                        label: settings.label,
                        soundName: nil
                    )
                    eventLog.record(category: "schedule", message: "Test wake AlarmKit id=\(wakeID.uuidString) date=\(wakeDate)")
                    results.append(TestEventDetail(
                        kind: .wake,
                        channel: "AlarmKit",
                        success: true,
                        message: "Scheduled alarm."
                    ))
                } catch {
                    eventLog.record(category: "schedule", message: "Test wake AlarmKit error: \(error.localizedDescription)")
                    results.append(TestEventDetail(
                        kind: .wake,
                        channel: "AlarmKit",
                        success: false,
                        message: error.localizedDescription
                    ))
                }
            }
        } else {
            let scheduled = await notificationScheduler.scheduleNotification(
                identifier: wakeNotificationID,
                kind: .wake,
                date: wakeDate,
                settings: settings,
                schedule: dummySchedule
            )
            eventLog.record(category: "schedule", message: "Test wake notification id=\(wakeNotificationID) date=\(wakeDate)")
            results.append(TestEventDetail(
                kind: .wake,
                channel: "Notification",
                success: scheduled,
                message: scheduled ? "Scheduled notification." : "Notification scheduling failed."
            ))
        }

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: reminderAlarmID,
                    kind: .reminder,
                    date: reminderDate,
                    label: settings.label,
                    fajrDateTime: adhanDate,
                    soundName: nil,
                    snoozeDuration: nil,
                    isTest: true,
                    testRunId: nil
                )
                eventLog.record(category: "schedule", message: "Test reminder AlarmKit id=\(reminderAlarmID.uuidString) date=\(reminderDate)")
                results.append(TestEventDetail(
                    kind: .reminder,
                    channel: "AlarmKit",
                    success: scheduled,
                    message: scheduled ? "Scheduled alarm." : "AlarmKit scheduling failed."
                ))
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        id: reminderAlarmID,
                        kind: .reminder,
                        date: reminderDate,
                        label: settings.label,
                        soundName: nil
                    )
                    eventLog.record(category: "schedule", message: "Test reminder AlarmKit id=\(reminderAlarmID.uuidString) date=\(reminderDate)")
                    results.append(TestEventDetail(
                        kind: .reminder,
                        channel: "AlarmKit",
                        success: true,
                        message: "Scheduled alarm."
                    ))
                } catch {
                    eventLog.record(category: "schedule", message: "Test reminder AlarmKit error: \(error.localizedDescription)")
                    results.append(TestEventDetail(
                        kind: .reminder,
                        channel: "AlarmKit",
                        success: false,
                        message: error.localizedDescription
                    ))
                }
            }
        } else {
            let reminderScheduled = await notificationScheduler.scheduleNotification(
                identifier: reminderNotificationID,
                kind: .reminder,
                date: reminderDate,
                settings: settings,
                schedule: dummySchedule
            )
            eventLog.record(category: "schedule", message: "Test reminder notification id=\(reminderNotificationID) date=\(reminderDate)")
            results.append(TestEventDetail(
                kind: .reminder,
                channel: "Notification",
                success: reminderScheduled,
                message: reminderScheduled ? "Scheduled notification." : "Notification scheduling failed."
            ))
        }

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let soundName = alarmSoundName(for: .boundary, schedule: dummySchedule, settings: settings)
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: adhanAlarmID,
                    kind: .boundary,
                    date: adhanDate,
                    label: settings.label,
                    fajrDateTime: adhanDate,
                    soundName: soundName,
                    snoozeDuration: nil,
                    isTest: true,
                    testRunId: nil
                )
                eventLog.record(category: "schedule", message: "Test adhan AlarmKit id=\(adhanAlarmID.uuidString) date=\(adhanDate)")
                results.append(TestEventDetail(
                    kind: .boundary,
                    channel: "AlarmKit",
                    success: scheduled,
                    message: scheduled ? (soundName == nil ? "Scheduled alarm with default sound." : "Scheduled alarm with Adhan sound.") : "AlarmKit scheduling failed."
                ))
            } else if let alarmKitScheduler {
                let soundName = alarmSoundName(for: .boundary, schedule: dummySchedule, settings: settings)
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        id: adhanAlarmID,
                        kind: .boundary,
                        date: adhanDate,
                        label: settings.label,
                        soundName: soundName
                    )
                    eventLog.record(category: "schedule", message: "Test adhan AlarmKit id=\(adhanAlarmID.uuidString) date=\(adhanDate)")
                    results.append(TestEventDetail(
                        kind: .boundary,
                        channel: "AlarmKit",
                        success: true,
                        message: soundName == nil ? "Scheduled alarm with default sound." : "Scheduled alarm with Adhan sound."
                    ))
                } catch {
                    eventLog.record(category: "schedule", message: "Test adhan AlarmKit error: \(error.localizedDescription)")
                    results.append(TestEventDetail(
                        kind: .boundary,
                        channel: "AlarmKit",
                        success: false,
                        message: error.localizedDescription
                    ))
                }
            }
        } else {
            let adhanScheduled = await notificationScheduler.scheduleNotification(
                identifier: adhanNotificationID,
                kind: .boundary,
                date: adhanDate,
                settings: settings,
                schedule: dummySchedule
            )
            eventLog.record(category: "schedule", message: "Test adhan notification id=\(adhanNotificationID) date=\(adhanDate)")
            results.append(TestEventDetail(
                kind: .boundary,
                channel: "Notification",
                success: adhanScheduled,
                message: adhanScheduled ? "Scheduled notification." : "Notification scheduling failed."
            ))
        }

        return results
    }

    static func isScheduleUpcoming(_ schedule: DaySchedule, settings: AppSettings, now: Date) -> Bool {
        var candidateDates: [Date] = []
        if settings.isEnabled {
            candidateDates.append(schedule.wakeDate)
        }
        if let reminderDate = schedule.reminderDate {
            candidateDates.append(reminderDate)
        }
        if let boundaryDate = schedule.boundaryDate {
            candidateDates.append(boundaryDate)
        }
        if let iftarDate = schedule.iftarDate {
            candidateDates.append(iftarDate)
        }
        return candidateDates.contains { $0 > now }
    }

    private func scheduleWakeIfNeeded(
        for schedule: DaySchedule,
        settings: AppSettings,
        canUseAlarmKit: Bool,
        now: Date
    ) async -> Bool {
        guard settings.isEnabled else { return true }
        guard schedule.wakeDate > now else {
            eventLog.record(category: "schedule", message: "Skip wake in past for \(schedule.id) date=\(schedule.wakeDate)")
            return true
        }

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let snoozeSeconds = FeatureFlags.enableSnooze && settings.snoozeEnabled
                    ? TimeInterval(settings.snoozeMinutes * 60)
                    : nil
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: SchedulingIdentifiers.alarmID(for: schedule, kind: .wake),
                    kind: .wake,
                    date: schedule.wakeDate,
                    label: settings.label,
                    fajrDateTime: schedule.fajrDate,
                    soundName: nil,
                    snoozeDuration: snoozeSeconds
                )
                eventLog.record(category: "schedule", message: "Scheduled wake AlarmKit id=\(SchedulingIdentifiers.alarmID(for: schedule, kind: .wake).uuidString) date=\(schedule.wakeDate)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        for: schedule,
                        kind: .wake,
                        date: schedule.wakeDate,
                        label: settings.label,
                        soundName: nil
                    )
                    eventLog.record(category: "schedule", message: "Scheduled wake AlarmKit id=\(SchedulingIdentifiers.alarmID(for: schedule, kind: .wake).uuidString) date=\(schedule.wakeDate)")
                    return true
                } catch {
                    Logging.scheduler.error("AlarmKit wake scheduling error: \(error.localizedDescription)")
                    eventLog.record(category: "schedule", message: "AlarmKit wake scheduling error: \(error.localizedDescription)")
                    return false
                }
            }
        }

        let identifier = SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake)
        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            kind: .wake,
            date: schedule.wakeDate,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled wake notification id=\(identifier) date=\(schedule.wakeDate)")
        return scheduled
    }

    private func scheduleReminderIfNeeded(
        for schedule: DaySchedule,
        settings: AppSettings,
        canUseAlarmKit: Bool,
        now: Date
    ) async -> Bool {
        guard let reminderDate = schedule.reminderDate else { return true }
        guard reminderDate > now else {
            eventLog.record(category: "schedule", message: "Skip reminder in past for \(schedule.id) date=\(reminderDate)")
            return true
        }

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let id = SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder)
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: id,
                    kind: .reminder,
                    date: reminderDate,
                    label: settings.label,
                    fajrDateTime: schedule.fajrDate,
                    soundName: nil,
                    snoozeDuration: nil
                )
                eventLog.record(category: "schedule", message: "Scheduled reminder AlarmKit id=\(id.uuidString) date=\(reminderDate)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        for: schedule,
                        kind: .reminder,
                        date: reminderDate,
                        label: settings.label,
                        soundName: nil
                    )
                    eventLog.record(category: "schedule", message: "Scheduled reminder AlarmKit id=\(SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder).uuidString) date=\(reminderDate)")
                    return true
                } catch {
                    Logging.scheduler.error("AlarmKit reminder scheduling error: \(error.localizedDescription)")
                    eventLog.record(category: "schedule", message: "AlarmKit reminder scheduling error: \(error.localizedDescription)")
                    return false
                }
            }
        }

        let identifier = SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .reminder)
        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            kind: .reminder,
            date: reminderDate,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled reminder notification id=\(identifier) date=\(reminderDate)")
        return scheduled
    }

    private func scheduleAdhanIfNeeded(
        for schedule: DaySchedule,
        settings: AppSettings,
        canUseAlarmKit: Bool,
        now: Date
    ) async -> Bool {
        guard let boundaryDate = schedule.boundaryDate else { return true }
        guard boundaryDate > now else {
            eventLog.record(category: "schedule", message: "Skip adhan in past for \(schedule.id) date=\(boundaryDate)")
            return true
        }

        if canUseAlarmKit, #available(iOS 26.0, *) {
            if FeatureFlags.useAlarmCoordinatorForScheduling, let alarmCoordinator {
                let id = SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary)
                let scheduled = await alarmCoordinator.scheduleAlarm(
                    id: id,
                    kind: .boundary,
                    date: boundaryDate,
                    label: settings.label,
                    fajrDateTime: schedule.fajrDate,
                    soundName: alarmSoundName(for: .boundary, schedule: schedule, settings: settings),
                    snoozeDuration: nil
                )
                eventLog.record(category: "schedule", message: "Scheduled adhan AlarmKit id=\(id.uuidString) date=\(boundaryDate)")
                return scheduled
            } else if let alarmKitScheduler {
                do {
                    try await alarmKitScheduler.scheduleAlarm(
                        for: schedule,
                        kind: .boundary,
                        date: boundaryDate,
                        label: settings.label,
                        soundName: alarmSoundName(for: .boundary, schedule: schedule, settings: settings)
                    )
                    eventLog.record(category: "schedule", message: "Scheduled adhan AlarmKit id=\(SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary).uuidString) date=\(boundaryDate)")
                    return true
                } catch {
                    Logging.scheduler.error("AlarmKit adhan scheduling error: \(error.localizedDescription)")
                    eventLog.record(category: "schedule", message: "AlarmKit adhan scheduling error: \(error.localizedDescription)")
                    return false
                }
            }
        }

        let identifier = SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .boundary)
        let scheduled = await notificationScheduler.scheduleNotification(
            identifier: identifier,
            kind: .boundary,
            date: boundaryDate,
            settings: settings,
            schedule: schedule
        )
        eventLog.record(category: "schedule", message: "Scheduled adhan notification id=\(identifier) date=\(boundaryDate)")
        return scheduled
    }

    private func scheduleIftarIfNeeded(
        for schedule: DaySchedule,
        settings: AppSettings,
        now: Date
    ) async -> Bool {
        guard let iftarDate = schedule.iftarDate else { return true }
        guard iftarDate > now else {
            eventLog.record(category: "schedule", message: "Skip iftar in past for \(schedule.id) date=\(iftarDate)")
            return true
        }
        return await scheduleIftarNotification(for: schedule, settings: settings)
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
