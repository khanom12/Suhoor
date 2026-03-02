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

    func cancelAllUpcoming(days: Int) async {
        eventLog.record(category: "schedule", message: "Cancel all upcoming schedules (days=\(days))")
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let alarmCoordinator {
            var ids: [UUID] = []
            let upcoming = upcomingSchedules(days: days)
            for schedule in upcoming {
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .wake))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder))
                ids.append(SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary))
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
            wakeDate: wakeDate,
            reminderDate: reminderDate,
            boundaryDate: adhanDate,
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
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

    private func alarmSoundName(for kind: ScheduleEventKind, schedule: DaySchedule, settings: AppSettings) -> String? {
        guard kind == .boundary else { return nil }
        let soundChoice = schedule.fajrSoundChoice ?? settings.atFajrSoundSelectionGlobal
        guard soundChoice == .adhanSoft else { return nil }
        if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
            return "adhan_fajr.caf"
        }
        return nil
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
        }
        return results
    }

    private func stubSchedule(for day: Date) -> DaySchedule {
        DaySchedule(
            date: day,
            fajrDate: day,
            wakeDate: day,
            reminderDate: nil,
            boundaryDate: nil,
            fajrSoundChoice: nil,
            locationDescription: "",
            offsetMinutes: 0,
            calculationMethodName: "",
            timeZone: .current
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
