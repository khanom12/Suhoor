import Foundation
import AlarmKit
import ActivityKit
import SwiftUI
import os

@available(iOS 26.0, *)
final class AlarmKitScheduler {
    private let alarmManager = AlarmManager.shared
    private let isRunningOnSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    private var updatesTask: Task<Void, Never>?
    var alarmUpdateRecorder: (@MainActor @Sendable (_ deliveries: [ObservedAlarmKitDelivery], _ timestamp: Date) -> Void)?

    init() {
        startObservingAlarmUpdates()
    }

    var isAuthorized: Bool {
        alarmManager.authorizationState == .authorized
    }

    var authorizationState: AlarmManager.AuthorizationState {
        alarmManager.authorizationState
    }

    var authorizationStateText: String {
        switch alarmManager.authorizationState {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    var isAvailableOnCurrentDevice: Bool {
        !isRunningOnSimulator
    }

    var isRequestable: Bool {
        isAvailableOnCurrentDevice && authorizationState == .notDetermined
    }

    var appPermissionState: AppPermissionState {
        guard isAvailableOnCurrentDevice else { return .unavailable }
        switch authorizationState {
        case .authorized:
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
        if isRunningOnSimulator {
            return false
        }
        do {
            let state = try await alarmManager.requestAuthorization()
            EventTimelineLog.shared.record(category: "permissions", message: "AlarmKit authorization requested -> \(String(describing: state))")
            return state == .authorized
        } catch {
            Logging.scheduler.error("AlarmKit authorization error: \(error.localizedDescription)")
            EventTimelineLog.shared.record(category: "permissions", message: "AlarmKit authorization error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleAlarm(
        for schedule: DaySchedule,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String? = nil,
        snoozeDuration: TimeInterval? = nil
    ) async throws -> Alarm {
        let id = SchedulingIdentifiers.alarmID(for: schedule, kind: kind)
        return try await scheduleAlarm(
            id: id,
            kind: kind,
            date: date,
            label: label,
            soundName: soundName,
            snoozeDuration: snoozeDuration
        )
    }

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String? = nil,
        snoozeDuration: TimeInterval? = nil
    ) async throws -> Alarm {
        let title = kind == .wake ? label : kind.title
        let alertTitle = LocalizedStringResource(stringLiteral: title)
        let alert = AlarmPresentation.Alert(title: alertTitle, secondaryButton: nil, secondaryButtonBehavior: nil)
        let presentation = AlarmPresentation(alert: alert)
        let metadata = SuhoorAlarmMetadata(kind: kind.rawValue)
        let attributes = AlarmAttributes(presentation: presentation, metadata: metadata, tintColor: .teal)
        let resolvedSound: AlertConfiguration.AlertSound
        if let soundName, !soundName.isEmpty {
            resolvedSound = .named(soundName)
        } else {
            resolvedSound = .default
        }
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: nil,
            sound: resolvedSound
        )
        return try await alarmManager.schedule(id: id, configuration: configuration)
    }

    func cancelAllUpcoming(days: Int) async {
        cancel(ids: SchedulingIdentifierSet.forUpcoming(days: days).alarmIdentifiers)
    }

    func cancel(schedule: DaySchedule, kind: ScheduleEventKind) {
        let identifiers = SchedulingIdentifierSet.forSchedule(schedule)
            .alarmIdentifiers
            .filter {
                $0 == SchedulingIdentifiers.alarmID(for: schedule, kind: kind)
                    || $0 == SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: kind)
                    || $0 == SchedulingIdentifiers.legacyAlarmIDV1(for: schedule, kind: kind)
            }
        cancel(ids: identifiers)
    }

    func cancel(ids: [UUID]) {
        for id in ids {
            try? alarmManager.cancel(id: id)
        }
    }

    func scheduledAlarmDeliveries() -> [ScheduledAlarmDelivery] {
        guard let alarms = try? alarmManager.alarms else { return [] }
        return alarms.map { alarm in
            ScheduledAlarmDelivery(
                id: alarm.id,
                fireDate: Self.scheduleInfo(for: alarm.schedule).1
            )
        }
    }

    private static func scheduleInfo(for schedule: Alarm.Schedule?) -> (String, Date?) {
        guard let schedule else { return ("None", nil) }
        switch schedule {
        case .fixed(let date):
            return ("Fixed", date)
        case .relative:
            return ("Relative", nil)
        @unknown default:
            return ("Unknown", nil)
        }
    }

    private func upcomingSchedules(days: Int) -> [DaySchedule] {
        let start = DateHelpers.startOfToday()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var schedules: [DaySchedule] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dummy = DaySchedule(
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
            schedules.append(dummy)
        }
        return schedules
    }

    private func startObservingAlarmUpdates() {
        updatesTask?.cancel()
        updatesTask = Task { [alarmManager] in
            for await alarms in alarmManager.alarmUpdates {
                let ids = alarms.map { $0.id.uuidString }.joined(separator: ", ")
                EventTimelineLog.shared.record(category: "alarmkit", message: "Alarm updates: \(ids)")
                let deliveries = alarms.map { alarm in
                    ObservedAlarmKitDelivery(
                        id: alarm.id,
                        fireDate: Self.scheduleInfo(for: alarm.schedule).1,
                        state: Self.observedState(for: alarm)
                    )
                }
                Task { @MainActor [weak self] in
                    self?.alarmUpdateRecorder?(deliveries, Date())
                }
            }
        }
    }

    private static func observedState(for alarm: Alarm) -> ObservedAlarmDeliveryState {
        switch String(describing: alarm.state).lowercased() {
        case let value where value.contains("fire"):
            return .fired
        case let value where value.contains("stop"):
            return .stopped
        default:
            return .scheduled
        }
    }
}

@available(iOS 26.0, *)
struct SuhoorAlarmMetadata: AlarmMetadata, Codable {
    let kind: String

    init(kind: String = "") {
        self.kind = kind
    }
}

@available(iOS 26.0, *)
extension AlarmKitScheduler: AlarmScheduling {
    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?,
        snoozeDuration: TimeInterval?
    ) async throws {
        let _: Alarm = try await scheduleAlarm(
            id: id,
            kind: kind,
            date: date,
            label: label,
            soundName: soundName,
            snoozeDuration: snoozeDuration
        )
    }

    func cancel(id: UUID) {
        try? alarmManager.cancel(id: id)
    }
}

@available(iOS 26.0, *)
extension AlarmKitScheduler: AlarmKitScheduling {
    func scheduleAlarm(
        for schedule: DaySchedule,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws {
        let _: Alarm = try await scheduleAlarm(
            for: schedule,
            kind: kind,
            date: date,
            label: label,
            soundName: soundName
        )
    }

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws {
        let _: Alarm = try await scheduleAlarm(
            id: id,
            kind: kind,
            date: date,
            label: label,
            soundName: soundName
        )
    }
}
