import Foundation
import UserNotifications
import os

final class NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    var authorizationStateText: String {
        get async {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            case .notDetermined: return "Not Determined"
            default: return "Unknown"
            }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func appPermissionState() async -> AppPermissionState {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .restricted
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            EventTimelineLog.shared.record(category: "permissions", message: "Notifications authorization requested -> \(granted)")
            return granted
        } catch {
            Logging.scheduler.error("Notification authorization error: \(error.localizedDescription)")
            EventTimelineLog.shared.record(category: "permissions", message: "Notifications authorization error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleNotifications(
        schedules: [DaySchedule],
        settings: AppSettings,
        includeWake: Bool,
        includeReminder: Bool,
        includeBoundary: Bool
    ) async -> Bool {
        await cancelAll()
        do {
            for schedule in schedules {
                if includeWake {
                    _ = try await addNotificationRequest(
                        identifier: identifier(for: schedule, kind: .wake),
                        kind: .wake,
                        date: schedule.wakeDate,
                        settings: settings,
                        schedule: schedule
                    )
                }
                if includeReminder, let reminderDate = schedule.reminderDate {
                    _ = try await addNotificationRequest(
                        identifier: identifier(for: schedule, kind: .reminder),
                        kind: .reminder,
                        date: reminderDate,
                        settings: settings,
                        schedule: schedule
                    )
                }
                if includeBoundary, let boundaryDate = schedule.boundaryDate {
                    _ = try await addNotificationRequest(
                        identifier: identifier(for: schedule, kind: .boundary),
                        kind: .boundary,
                        date: boundaryDate,
                        settings: settings,
                        schedule: schedule
                    )
                }
            }
            return true
        } catch {
            Logging.scheduler.error("Notification scheduling error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleNotification(
        identifier: String,
        kind: ScheduleEventKind,
        date: Date,
        settings: AppSettings,
        schedule: DaySchedule
    ) async -> Bool {
        do {
            _ = try await addNotificationRequest(
                identifier: identifier,
                kind: kind,
                date: date,
                settings: settings,
                schedule: schedule
            )
            return true
        } catch {
            Logging.scheduler.error("Notification scheduling error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleNotification(
        identifier: String,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        settings: AppSettings,
        schedule: DaySchedule
    ) async -> Bool {
        do {
            _ = try await addNotificationRequest(
                identifier: identifier,
                kind: deliveryKind,
                date: event.fireDate,
                settings: settings,
                schedule: schedule,
                soundRole: event.soundRole
            )
            return true
        } catch {
            Logging.scheduler.error("Notification scheduling error: \(error.localizedDescription)")
            return false
        }
    }

    func cancelAll() async {
        let identifiers = upcomingIdentifiers(days: 30) + legacyUpcomingIdentifiers(days: 30)
        await cancelNotifications(identifiers: identifiers)
    }

    func cancelNotifications(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    private func addNotificationRequest(
        identifier: String,
        kind: ScheduleEventKind,
        date: Date,
        settings: AppSettings,
        schedule: DaySchedule,
        soundRole: MorningSoundRole? = nil
    ) async throws -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: kind, settings: settings)
        content.body = notificationBody(for: kind)
        content.sound = notificationSound(for: soundRole, kind: kind, schedule: schedule, settings: settings)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
        return request
    }

    private func identifier(for schedule: DaySchedule, kind: ScheduleEventKind) -> String {
        SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: kind)
    }

    private func upcomingIdentifiers(days: Int) -> [String] {
        let start = DateHelpers.startOfToday()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var results: [String] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let schedule = DaySchedule(
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
            results.append(identifier(for: schedule, kind: .wake))
            results.append(identifier(for: schedule, kind: .reminder))
            results.append(identifier(for: schedule, kind: .boundary))
            results.append(identifier(for: schedule, kind: .iftarNotification))
            results.append(identifier(for: schedule, kind: .iftarAlarm))
            results.append(identifier(for: schedule, kind: .iftarAdhan))
        }
        return results
    }

    private func legacyUpcomingIdentifiers(days: Int) -> [String] {
        let start = DateHelpers.startOfToday()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var results: [String] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let schedule = DaySchedule(
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
            results.append(SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .wake))
            results.append(SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .reminder))
            results.append(SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: .boundary))
        }
        return results
    }

    private func notificationTitle(for kind: ScheduleEventKind, settings: AppSettings) -> String {
        switch kind {
        case .wake:
            return settings.label
        case .iftarNotification:
            return "It’s time to break your fast"
        default:
            return kind.title
        }
    }

    private func notificationBody(for kind: ScheduleEventKind) -> String {
        switch kind {
        case .iftarNotification:
            return "Maghrib has begun."
        default:
            return kind.body
        }
    }

    private func notificationSound(
        for kind: ScheduleEventKind,
        schedule: DaySchedule,
        settings: AppSettings
    ) -> UNNotificationSound? {
        notificationSound(for: nil, kind: kind, schedule: schedule, settings: settings)
    }

    private func notificationSound(
        for soundRole: MorningSoundRole?,
        kind: ScheduleEventKind,
        schedule: DaySchedule,
        settings: AppSettings
    ) -> UNNotificationSound? {
        if let soundRole {
            return notificationSound(for: settings.soundChoice(for: soundRole), role: soundRole)
        }

        switch kind {
        case .wake:
            return .default
        case .reminder:
            return .default
        case .boundary:
            return notificationSound(for: schedule.fajrSoundChoice ?? settings.atFajrSoundSelectionGlobal, role: .fajrStart)
        case .iftarNotification:
            return .default
        case .iftarAlarm:
            return .default
        case .iftarAdhan:
            if Bundle.main.url(forResource: "adhan", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan.caf"))
            }
            if Bundle.main.url(forResource: "adhan_maghrib", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan_maghrib.caf"))
            }
            return .default
        }
    }

    private func notificationSound(
        for soundChoice: SoundChoice,
        role: MorningSoundRole
    ) -> UNNotificationSound? {
        guard soundChoice == .adhanSoft else { return .default }
        switch role {
        case .preFajrWake, .fajrStart, .inFajrWake, .postFajrWake, .fixedWake:
            if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan_fajr.caf"))
            }
            return .default
        case .reminder:
            return .default
        case .iftar:
            if Bundle.main.url(forResource: "adhan", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan.caf"))
            }
            if Bundle.main.url(forResource: "adhan_maghrib", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan_maghrib.caf"))
            }
            return .default
        }
    }

}
