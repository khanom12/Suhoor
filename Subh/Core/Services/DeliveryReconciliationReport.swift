import Foundation
import UserNotifications

enum AlarmDeliveryChannel: String, Codable, Sendable {
    case alarmKit
    case notification
}

struct ExpectedAlarmDelivery: Equatable, Sendable {
    let dateKey: String
    let eventID: String
    let eventType: ScheduledEventType
    let deliveryKind: ScheduleEventKind
    let fireDate: Date
    let channel: AlarmDeliveryChannel
    let notificationIdentifier: String
    let alarmIdentifier: UUID
}

struct PendingNotificationDelivery: Equatable, Sendable {
    let identifier: String
    let fireDate: Date?

    init(identifier: String, fireDate: Date?) {
        self.identifier = identifier
        self.fireDate = fireDate
    }

    init(request: UNNotificationRequest, calendar: Calendar = .current) {
        self.identifier = request.identifier
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            self.fireDate = nil
            return
        }
        self.fireDate = trigger.nextTriggerDate() ?? calendar.date(from: trigger.dateComponents)
    }
}

struct ScheduledAlarmDelivery: Equatable, Sendable {
    let id: UUID
    let fireDate: Date?
}

struct DeliveryReconciliationReport: Equatable, Sendable {
    let mode: SchedulingMode
    let generatedAt: Date
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let pendingNotificationCount: Int
    let pendingAlarmCount: Int
    let missingNotificationIdentifiers: [String]
    let mismatchedNotificationIdentifiers: [String]
    let missingAlarmIdentifiers: [UUID]
    let mismatchedAlarmIdentifiers: [UUID]

    var expectedDeliveryCount: Int {
        expectedDeliveries.count
    }

    var hasWarnings: Bool {
        !missingNotificationIdentifiers.isEmpty
            || !mismatchedNotificationIdentifiers.isEmpty
            || !missingAlarmIdentifiers.isEmpty
            || !mismatchedAlarmIdentifiers.isEmpty
    }

    var summaryText: String {
        guard mode != .none else { return "Not ready" }
        guard expectedDeliveryCount > 0 else { return "No future deliveries" }
        guard hasWarnings else { return "Verified \(expectedDeliveryCount) future deliveries" }

        var parts: [String] = []
        let missingCount = missingNotificationIdentifiers.count + missingAlarmIdentifiers.count
        let mismatchCount = mismatchedNotificationIdentifiers.count + mismatchedAlarmIdentifiers.count
        if missingCount > 0 {
            parts.append("Missing \(missingCount)")
        }
        if mismatchCount > 0 {
            parts.append("Time mismatch \(mismatchCount)")
        }
        return parts.joined(separator: " · ")
    }

    var diagnosticsText: String {
        var lines = [
            "Delivery check: \(summaryText)",
            "Expected deliveries: \(expectedDeliveryCount)",
            "Pending notifications: \(pendingNotificationCount)",
            "Pending alarms: \(pendingAlarmCount)"
        ]
        if !missingNotificationIdentifiers.isEmpty {
            lines.append("Missing notifications: \(missingNotificationIdentifiers.prefix(8).joined(separator: ", "))")
        }
        if !mismatchedNotificationIdentifiers.isEmpty {
            lines.append("Mismatched notifications: \(mismatchedNotificationIdentifiers.prefix(8).joined(separator: ", "))")
        }
        if !missingAlarmIdentifiers.isEmpty {
            let ids = missingAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Missing AlarmKit IDs: \(ids)")
        }
        if !mismatchedAlarmIdentifiers.isEmpty {
            let ids = mismatchedAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Mismatched AlarmKit IDs: \(ids)")
        }
        return lines.joined(separator: "\n")
    }
}

enum DeliveryReconciliation {
    static func expectedDeliveries(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date
    ) -> [ExpectedAlarmDelivery] {
        guard settings.isEnabled, mode != .none else { return [] }

        return snapshot.scheduledDays.flatMap { day in
            day.scheduledEvents.flatMap { event -> [ExpectedAlarmDelivery] in
                guard event.fireDate > now else { return [] }
                return event.deliveryKinds.compactMap { deliveryKind in
                    guard let channel = channel(
                        for: event,
                        deliveryKind: deliveryKind,
                        mode: mode
                    ) else {
                        return nil
                    }
                    return ExpectedAlarmDelivery(
                        dateKey: day.dateKey,
                        eventID: event.id,
                        eventType: event.type,
                        deliveryKind: deliveryKind,
                        fireDate: event.fireDate,
                        channel: channel,
                        notificationIdentifier: SchedulingIdentifiers.identifier(for: event, deliveryKind: deliveryKind),
                        alarmIdentifier: SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind)
                    )
                }
            }
        }
    }

    static func report(
        mode: SchedulingMode,
        generatedAt: Date,
        expectedDeliveries: [ExpectedAlarmDelivery],
        pendingNotifications: [PendingNotificationDelivery],
        pendingAlarms: [ScheduledAlarmDelivery],
        tolerance: TimeInterval = 60
    ) -> DeliveryReconciliationReport {
        let pendingNotificationsByID = Dictionary(uniqueKeysWithValues: pendingNotifications.map { ($0.identifier, $0) })
        let pendingAlarmsByID = Dictionary(uniqueKeysWithValues: pendingAlarms.map { ($0.id, $0) })

        var missingNotificationIdentifiers: [String] = []
        var mismatchedNotificationIdentifiers: [String] = []
        var missingAlarmIdentifiers: [UUID] = []
        var mismatchedAlarmIdentifiers: [UUID] = []

        for expected in expectedDeliveries {
            switch expected.channel {
            case .notification:
                guard let pending = pendingNotificationsByID[expected.notificationIdentifier] else {
                    missingNotificationIdentifiers.append(expected.notificationIdentifier)
                    continue
                }
                if !matches(expected: expected.fireDate, actual: pending.fireDate, tolerance: tolerance) {
                    mismatchedNotificationIdentifiers.append(expected.notificationIdentifier)
                }
            case .alarmKit:
                guard let pending = pendingAlarmsByID[expected.alarmIdentifier] else {
                    missingAlarmIdentifiers.append(expected.alarmIdentifier)
                    continue
                }
                if !matches(expected: expected.fireDate, actual: pending.fireDate, tolerance: tolerance) {
                    mismatchedAlarmIdentifiers.append(expected.alarmIdentifier)
                }
            }
        }

        return DeliveryReconciliationReport(
            mode: mode,
            generatedAt: generatedAt,
            expectedDeliveries: expectedDeliveries,
            pendingNotificationCount: pendingNotifications.count,
            pendingAlarmCount: pendingAlarms.count,
            missingNotificationIdentifiers: missingNotificationIdentifiers.sorted(),
            mismatchedNotificationIdentifiers: mismatchedNotificationIdentifiers.sorted(),
            missingAlarmIdentifiers: missingAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString },
            mismatchedAlarmIdentifiers: mismatchedAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString }
        )
    }

    static func report(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date,
        pendingNotifications: [PendingNotificationDelivery],
        pendingAlarms: [ScheduledAlarmDelivery]
    ) -> DeliveryReconciliationReport {
        report(
            mode: mode,
            generatedAt: now,
            expectedDeliveries: expectedDeliveries(
                snapshot: snapshot,
                settings: settings,
                mode: mode,
                now: now
            ),
            pendingNotifications: pendingNotifications,
            pendingAlarms: pendingAlarms
        )
    }

    private static func channel(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        mode: SchedulingMode
    ) -> AlarmDeliveryChannel? {
        switch mode {
        case .none:
            return nil
        case .notifications:
            return .notification
        case .alarmKit:
            if deliveryKind == .iftarNotification {
                return .notification
            }
            if event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue,
               deliveryKind == .boundary {
                return nil
            }
            return .alarmKit
        }
    }

    private static func matches(expected: Date, actual: Date?, tolerance: TimeInterval) -> Bool {
        guard let actual else { return false }
        return abs(expected.timeIntervalSince(actual)) <= tolerance
    }
}
