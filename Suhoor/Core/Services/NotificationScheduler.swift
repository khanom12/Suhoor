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

    func scheduleTestNotification(kind: ScheduleEventKind, settings: AppSettings, delaySeconds: Int = 5) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Test \(kind.title)"
        content.body = kind.body
        let dummySchedule = DaySchedule(
            date: Date(),
            fajrDate: Date(),
            wakeDate: Date(),
            reminderDate: nil,
            boundaryDate: nil,
            fajrSoundChoice: settings.atFajrSoundSelectionGlobal,
            locationDescription: "",
            offsetMinutes: 0,
            calculationMethodName: "",
            timeZone: .current
        )
        content.sound = notificationSound(for: kind, schedule: dummySchedule, settings: settings)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, delaySeconds)), repeats: false)
        let request = UNNotificationRequest(identifier: testIdentifier(for: kind), content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            Logging.scheduler.error("Test notification error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleFajrAdhanTest(delaySeconds: Int = 60) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Test Fajr alarm"
        content.body = ScheduleEventKind.boundary.body
        if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan_fajr.caf"))
        } else {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, delaySeconds)), repeats: false)
        let request = UNNotificationRequest(identifier: fajrAdhanTestIdentifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            Logging.scheduler.error("Fajr adhan test error: \(error.localizedDescription)")
            return false
        }
    }

    func cancelTestNotifications() async {
        let identifiers = ScheduleEventKind.allCases.map { testIdentifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers + [fajrAdhanTestIdentifier])
    }

    private func addNotificationRequest(
        identifier: String,
        kind: ScheduleEventKind,
        date: Date,
        settings: AppSettings,
        schedule: DaySchedule
    ) async throws -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = kind == .wake ? settings.label : kind.title
        content.body = kind.body
        content.sound = notificationSound(for: kind, schedule: schedule, settings: settings)

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

    private func testIdentifier(for kind: ScheduleEventKind) -> String {
        SchedulingIdentifiers.testIdentifier(for: kind)
    }

    private var fajrAdhanTestIdentifier: String {
        "suhoor.test.fajr-adhan"
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
                wakeDate: day,
                reminderDate: nil,
                boundaryDate: nil,
                fajrSoundChoice: nil,
                locationDescription: "",
                offsetMinutes: 0,
                calculationMethodName: "",
                timeZone: .current
            )
            results.append(identifier(for: schedule, kind: .wake))
            results.append(identifier(for: schedule, kind: .reminder))
            results.append(identifier(for: schedule, kind: .boundary))
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
                wakeDate: day,
                reminderDate: nil,
                boundaryDate: nil,
                fajrSoundChoice: nil,
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

    private func notificationSound(for kind: ScheduleEventKind, schedule: DaySchedule, settings: AppSettings) -> UNNotificationSound? {
        switch kind {
        case .wake:
            return .default
        case .reminder:
            return .default
        case .boundary:
            let soundChoice = schedule.fajrSoundChoice ?? settings.atFajrSoundSelectionGlobal
            if soundChoice == .adhanSoft,
               Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
                return UNNotificationSound(named: UNNotificationSoundName("adhan_fajr.caf"))
            }
            return .default
        }
    }
}
