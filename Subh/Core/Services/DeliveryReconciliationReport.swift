import Foundation
import UserNotifications

enum AlarmDeliveryChannel: String, Codable, Sendable {
    case alarmKit
    case notification
}

enum DeliveryPlanningSkipReason: String, Codable, Sendable {
    case skippedPast
    case noDeliveryChannel
    case deliverySuppressed
    case wakeAlarmsPaused
}

struct SkippedAlarmDelivery: Equatable, Sendable {
    let dateKey: String
    let eventID: String
    let eventType: ScheduledEventType
    let deliveryKind: ScheduleEventKind?
    let fireDate: Date
    let reason: DeliveryPlanningSkipReason
}

struct DeliveryPermissionSnapshot: Equatable, Sendable {
    let alarmKit: AppPermissionState
    let notifications: AppPermissionState
    let selectedMode: SchedulingMode

    static func inferred(selectedMode: SchedulingMode) -> DeliveryPermissionSnapshot {
        switch selectedMode {
        case .alarmKit:
            return DeliveryPermissionSnapshot(alarmKit: .authorized, notifications: .notDetermined, selectedMode: selectedMode)
        case .notifications:
            return DeliveryPermissionSnapshot(alarmKit: .unavailable, notifications: .authorized, selectedMode: selectedMode)
        case .mixed:
            return DeliveryPermissionSnapshot(alarmKit: .authorized, notifications: .authorized, selectedMode: selectedMode)
        case .none:
            return DeliveryPermissionSnapshot(alarmKit: .unavailable, notifications: .denied, selectedMode: selectedMode)
        }
    }
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

enum DeliveryReconciliationCategory: String, Codable, Sendable {
    case matched
    case missingExpected
    case fireDateMismatch
    case unexpectedExtra
    case duplicate
    case permissionBlocked
    case platformUnavailable
    case schedulingFailed
    case verificationUnavailable
    case skippedPast
}

struct DeliveryReconciliationIssue: Equatable, Sendable {
    let category: DeliveryReconciliationCategory
    let channel: AlarmDeliveryChannel?
    let identifier: String?
    let alarmIdentifier: UUID?
    let dateKey: String?
    let eventID: String?
    let expectedFireDate: Date?
    let actualFireDate: Date?
    let message: String?
}

struct DeliveryPlan: Equatable, Sendable {
    let mode: SchedulingMode
    let generatedAt: Date
    let permissionSnapshot: DeliveryPermissionSnapshot
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let skippedDeliveries: [SkippedAlarmDelivery]

    var isMixed: Bool {
        expectedDeliveries.contains { $0.channel == .alarmKit }
            && expectedDeliveries.contains { $0.channel == .notification }
    }
}

struct DeliveryReconciliationReport: Equatable, Sendable {
    let mode: SchedulingMode
    let generatedAt: Date
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let skippedDeliveries: [SkippedAlarmDelivery]
    let issues: [DeliveryReconciliationIssue]
    let pendingNotificationCount: Int
    let pendingAlarmCount: Int
    let missingNotificationIdentifiers: [String]
    let mismatchedNotificationIdentifiers: [String]
    let unexpectedNotificationIdentifiers: [String]
    let duplicateNotificationIdentifiers: [String]
    let missingAlarmIdentifiers: [UUID]
    let mismatchedAlarmIdentifiers: [UUID]
    let unexpectedAlarmIdentifiers: [UUID]
    let duplicateAlarmIdentifiers: [UUID]

    var expectedDeliveryCount: Int {
        expectedDeliveries.count
    }

    var matchedCount: Int {
        issues.filter { $0.category == .matched }.count
    }

    var missingCount: Int {
        missingNotificationIdentifiers.count + missingAlarmIdentifiers.count
    }

    var mismatchCount: Int {
        mismatchedNotificationIdentifiers.count + mismatchedAlarmIdentifiers.count
    }

    var failedCount: Int {
        issues.filter {
            $0.category == .missingExpected
                || $0.category == .fireDateMismatch
                || $0.category == .schedulingFailed
        }.count
    }

    var hasWarnings: Bool {
        !missingNotificationIdentifiers.isEmpty
            || !mismatchedNotificationIdentifiers.isEmpty
            || !unexpectedNotificationIdentifiers.isEmpty
            || !duplicateNotificationIdentifiers.isEmpty
            || !missingAlarmIdentifiers.isEmpty
            || !mismatchedAlarmIdentifiers.isEmpty
            || !unexpectedAlarmIdentifiers.isEmpty
            || !duplicateAlarmIdentifiers.isEmpty
            || issues.contains { issue in
                issue.category == .permissionBlocked
                    || issue.category == .platformUnavailable
                    || issue.category == .schedulingFailed
                    || issue.category == .verificationUnavailable
            }
    }

    var summaryText: String {
        guard mode != .none else { return "Not ready" }
        guard expectedDeliveryCount > 0 else { return "No future deliveries" }
        guard hasWarnings else { return "Verified \(expectedDeliveryCount) future deliveries" }

        var parts: [String] = []
        if missingCount > 0 {
            parts.append("Missing \(missingCount)")
        }
        if mismatchCount > 0 {
            parts.append("Time mismatch \(mismatchCount)")
        }
        let unexpectedCount = unexpectedNotificationIdentifiers.count + unexpectedAlarmIdentifiers.count
        if unexpectedCount > 0 {
            parts.append("Unexpected \(unexpectedCount)")
        }
        let duplicateCount = duplicateNotificationIdentifiers.count + duplicateAlarmIdentifiers.count
        if duplicateCount > 0 {
            parts.append("Duplicate \(duplicateCount)")
        }
        if issues.contains(where: { $0.category == .verificationUnavailable }) {
            parts.append("Verification limited")
        }
        if issues.contains(where: { $0.category == .permissionBlocked }) {
            parts.append("Permission blocked")
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
        if !unexpectedNotificationIdentifiers.isEmpty {
            lines.append("Unexpected notifications: \(unexpectedNotificationIdentifiers.prefix(8).joined(separator: ", "))")
        }
        if !duplicateNotificationIdentifiers.isEmpty {
            lines.append("Duplicate notifications: \(duplicateNotificationIdentifiers.prefix(8).joined(separator: ", "))")
        }
        if !missingAlarmIdentifiers.isEmpty {
            let ids = missingAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Missing AlarmKit IDs: \(ids)")
        }
        if !mismatchedAlarmIdentifiers.isEmpty {
            let ids = mismatchedAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Mismatched AlarmKit IDs: \(ids)")
        }
        if !unexpectedAlarmIdentifiers.isEmpty {
            let ids = unexpectedAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Unexpected AlarmKit IDs: \(ids)")
        }
        if !duplicateAlarmIdentifiers.isEmpty {
            let ids = duplicateAlarmIdentifiers.prefix(8).map(\.uuidString).joined(separator: ", ")
            lines.append("Duplicate AlarmKit IDs: \(ids)")
        }
        return lines.joined(separator: "\n")
    }
}

enum DeliveryReconciliation {
    static func plan(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date
    ) -> DeliveryPlan {
        guard settings.isEnabled, mode != .none else {
            return DeliveryPlan(
                mode: mode,
                generatedAt: now,
                permissionSnapshot: .inferred(selectedMode: mode),
                expectedDeliveries: [],
                skippedDeliveries: []
            )
        }

        var expectedDeliveries: [ExpectedAlarmDelivery] = []
        var skippedDeliveries: [SkippedAlarmDelivery] = []

        for day in snapshot.scheduledDays {
            guard !day.effectiveConfig.skipDay else {
                for event in day.scheduledEvents {
                    skippedDeliveries.append(
                        SkippedAlarmDelivery(
                            dateKey: day.dateKey,
                            eventID: event.id,
                            eventType: event.type,
                            deliveryKind: nil,
                            fireDate: event.fireDate,
                            reason: .deliverySuppressed
                        )
                    )
                }
                continue
            }

            for event in day.scheduledEvents {
                guard event.fireDate > now else {
                    skippedDeliveries.append(
                        SkippedAlarmDelivery(
                            dateKey: day.dateKey,
                            eventID: event.id,
                            eventType: event.type,
                            deliveryKind: nil,
                            fireDate: event.fireDate,
                            reason: .skippedPast
                        )
                    )
                    continue
                }

                for deliveryKind in event.deliveryKinds {
                    if let suppressionReason = wakeDeliverySuppressionReason(
                        day: day,
                        event: event,
                        deliveryKind: deliveryKind,
                        settings: settings
                    ) {
                        skippedDeliveries.append(
                            SkippedAlarmDelivery(
                                dateKey: day.dateKey,
                                eventID: event.id,
                                eventType: event.type,
                                deliveryKind: deliveryKind,
                                fireDate: event.fireDate,
                                reason: suppressionReason
                            )
                        )
                        continue
                    }

                    guard let channel = channel(
                        for: event,
                        deliveryKind: deliveryKind,
                        mode: mode
                    ) else {
                        skippedDeliveries.append(
                            SkippedAlarmDelivery(
                                dateKey: day.dateKey,
                                eventID: event.id,
                                eventType: event.type,
                                deliveryKind: deliveryKind,
                                fireDate: event.fireDate,
                                reason: .noDeliveryChannel
                            )
                        )
                        continue
                    }
                    expectedDeliveries.append(ExpectedAlarmDelivery(
                        dateKey: day.dateKey,
                        eventID: event.id,
                        eventType: event.type,
                        deliveryKind: deliveryKind,
                        fireDate: event.fireDate,
                        channel: channel,
                        notificationIdentifier: SchedulingIdentifiers.identifier(
                            for: event,
                            deliveryKind: deliveryKind,
                            channel: .notification
                        ),
                        alarmIdentifier: SchedulingIdentifiers.alarmID(
                            for: event,
                            deliveryKind: deliveryKind,
                            channel: channel
                        )
                    ))
                }
            }
        }

        return DeliveryPlan(
            mode: mode,
            generatedAt: now,
            permissionSnapshot: .inferred(selectedMode: mode),
            expectedDeliveries: expectedDeliveries,
            skippedDeliveries: skippedDeliveries
        )
    }

    static func expectedDeliveries(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date
    ) -> [ExpectedAlarmDelivery] {
        plan(snapshot: snapshot, settings: settings, mode: mode, now: now).expectedDeliveries
    }

    private static func wakeDeliverySuppressionReason(
        day: ActiveAlarmDay,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        settings: AppSettings
    ) -> DeliveryPlanningSkipReason? {
        guard deliveryKind == .wake || event.wakeSessionRole == .primaryWake || event.wakeSessionRole == .wakeCheck else {
            return nil
        }
        if day.effectiveConfig.dateAlarmOverride == .quiet {
            return .deliverySuppressed
        }
        if settings.wakeAlarmsPausedIndefinitely,
           day.effectiveConfig.dateAlarmOverride != .ringDespitePause {
            return .wakeAlarmsPaused
        }
        return nil
    }

    static func report(
        mode: SchedulingMode,
        generatedAt: Date,
        expectedDeliveries: [ExpectedAlarmDelivery],
        pendingNotifications: [PendingNotificationDelivery],
        pendingAlarms: [ScheduledAlarmDelivery],
        skippedDeliveries: [SkippedAlarmDelivery] = [],
        alarmKitVerificationAvailable: Bool = true,
        notificationVerificationAvailable: Bool = true,
        permissionBlockedReasons: [String] = [],
        schedulingFailedReasons: [String] = [],
        tolerance: TimeInterval = 60
    ) -> DeliveryReconciliationReport {
        let pendingNotificationsByID = Dictionary(grouping: pendingNotifications, by: \.identifier)
        let pendingAlarmsByID = Dictionary(grouping: pendingAlarms, by: \.id)
        let expectedNotificationIDs = Set(expectedDeliveries.filter { $0.channel == .notification }.map(\.notificationIdentifier))
        let expectedAlarmIDs = Set(expectedDeliveries.filter { $0.channel == .alarmKit }.map(\.alarmIdentifier))

        var missingNotificationIdentifiers: [String] = []
        var mismatchedNotificationIdentifiers: [String] = []
        var unexpectedNotificationIdentifiers: [String] = []
        var duplicateNotificationIdentifiers: [String] = []
        var missingAlarmIdentifiers: [UUID] = []
        var mismatchedAlarmIdentifiers: [UUID] = []
        var unexpectedAlarmIdentifiers: [UUID] = []
        var duplicateAlarmIdentifiers: [UUID] = []
        var issues: [DeliveryReconciliationIssue] = []

        for expected in expectedDeliveries {
            switch expected.channel {
            case .notification:
                guard notificationVerificationAvailable else {
                    issues.append(issue(.verificationUnavailable, expected: expected, message: "Notification pending-state verification is unavailable."))
                    continue
                }
                guard let pending = pendingNotificationsByID[expected.notificationIdentifier]?.first else {
                    missingNotificationIdentifiers.append(expected.notificationIdentifier)
                    issues.append(issue(.missingExpected, expected: expected))
                    continue
                }
                if !matches(expected: expected.fireDate, actual: pending.fireDate, tolerance: tolerance) {
                    mismatchedNotificationIdentifiers.append(expected.notificationIdentifier)
                    issues.append(issue(.fireDateMismatch, expected: expected, actualFireDate: pending.fireDate))
                } else {
                    issues.append(issue(.matched, expected: expected, actualFireDate: pending.fireDate))
                }
            case .alarmKit:
                guard alarmKitVerificationAvailable else {
                    issues.append(issue(.verificationUnavailable, expected: expected, message: "AlarmKit pending-state verification is unavailable or limited."))
                    continue
                }
                guard let pending = pendingAlarmsByID[expected.alarmIdentifier]?.first else {
                    missingAlarmIdentifiers.append(expected.alarmIdentifier)
                    issues.append(issue(.missingExpected, expected: expected))
                    continue
                }
                if !matches(expected: expected.fireDate, actual: pending.fireDate, tolerance: tolerance) {
                    mismatchedAlarmIdentifiers.append(expected.alarmIdentifier)
                    issues.append(issue(.fireDateMismatch, expected: expected, actualFireDate: pending.fireDate))
                } else {
                    issues.append(issue(.matched, expected: expected, actualFireDate: pending.fireDate))
                }
            }
        }

        for (identifier, deliveries) in pendingNotificationsByID {
            if deliveries.count > 1 {
                duplicateNotificationIdentifiers.append(identifier)
                issues.append(
                    DeliveryReconciliationIssue(
                        category: .duplicate,
                        channel: .notification,
                        identifier: identifier,
                        alarmIdentifier: nil,
                        dateKey: nil,
                        eventID: nil,
                        expectedFireDate: nil,
                        actualFireDate: deliveries.first?.fireDate,
                        message: "Duplicate pending notification delivery."
                    )
                )
            }
            if !expectedNotificationIDs.contains(identifier) {
                unexpectedNotificationIdentifiers.append(identifier)
                issues.append(
                    DeliveryReconciliationIssue(
                        category: .unexpectedExtra,
                        channel: .notification,
                        identifier: identifier,
                        alarmIdentifier: nil,
                        dateKey: nil,
                        eventID: nil,
                        expectedFireDate: nil,
                        actualFireDate: deliveries.first?.fireDate,
                        message: "Unexpected pending notification delivery."
                    )
                )
            }
        }

        for (identifier, deliveries) in pendingAlarmsByID {
            if deliveries.count > 1 {
                duplicateAlarmIdentifiers.append(identifier)
                issues.append(
                    DeliveryReconciliationIssue(
                        category: .duplicate,
                        channel: .alarmKit,
                        identifier: nil,
                        alarmIdentifier: identifier,
                        dateKey: nil,
                        eventID: nil,
                        expectedFireDate: nil,
                        actualFireDate: deliveries.first?.fireDate,
                        message: "Duplicate pending AlarmKit delivery."
                    )
                )
            }
            if !expectedAlarmIDs.contains(identifier) {
                unexpectedAlarmIdentifiers.append(identifier)
                issues.append(
                    DeliveryReconciliationIssue(
                        category: .unexpectedExtra,
                        channel: .alarmKit,
                        identifier: nil,
                        alarmIdentifier: identifier,
                        dateKey: nil,
                        eventID: nil,
                        expectedFireDate: nil,
                        actualFireDate: deliveries.first?.fireDate,
                        message: "Unexpected pending AlarmKit delivery."
                    )
                )
            }
        }

        for skipped in skippedDeliveries where skipped.reason == .skippedPast {
            issues.append(
                DeliveryReconciliationIssue(
                    category: .skippedPast,
                    channel: nil,
                    identifier: nil,
                    alarmIdentifier: nil,
                    dateKey: skipped.dateKey,
                    eventID: skipped.eventID,
                    expectedFireDate: skipped.fireDate,
                    actualFireDate: nil,
                    message: "Past resolved event was not scheduled."
                )
            )
        }

        for reason in permissionBlockedReasons {
            issues.append(
                DeliveryReconciliationIssue(
                    category: .permissionBlocked,
                    channel: nil,
                    identifier: nil,
                    alarmIdentifier: nil,
                    dateKey: nil,
                    eventID: nil,
                    expectedFireDate: nil,
                    actualFireDate: nil,
                    message: reason
                )
            )
        }

        for reason in schedulingFailedReasons {
            issues.append(
                DeliveryReconciliationIssue(
                    category: .schedulingFailed,
                    channel: nil,
                    identifier: nil,
                    alarmIdentifier: nil,
                    dateKey: nil,
                    eventID: nil,
                    expectedFireDate: nil,
                    actualFireDate: nil,
                    message: reason
                )
            )
        }

        return DeliveryReconciliationReport(
            mode: mode,
            generatedAt: generatedAt,
            expectedDeliveries: expectedDeliveries,
            skippedDeliveries: skippedDeliveries,
            issues: issues,
            pendingNotificationCount: pendingNotifications.count,
            pendingAlarmCount: pendingAlarms.count,
            missingNotificationIdentifiers: missingNotificationIdentifiers.sorted(),
            mismatchedNotificationIdentifiers: mismatchedNotificationIdentifiers.sorted(),
            unexpectedNotificationIdentifiers: unexpectedNotificationIdentifiers.sorted(),
            duplicateNotificationIdentifiers: duplicateNotificationIdentifiers.sorted(),
            missingAlarmIdentifiers: missingAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString },
            mismatchedAlarmIdentifiers: mismatchedAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString },
            unexpectedAlarmIdentifiers: unexpectedAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString },
            duplicateAlarmIdentifiers: duplicateAlarmIdentifiers.sorted { $0.uuidString < $1.uuidString }
        )
    }

    static func report(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date,
        pendingNotifications: [PendingNotificationDelivery],
        pendingAlarms: [ScheduledAlarmDelivery],
        alarmKitVerificationAvailable: Bool = true,
        notificationVerificationAvailable: Bool = true,
        permissionBlockedReasons: [String] = [],
        schedulingFailedReasons: [String] = []
    ) -> DeliveryReconciliationReport {
        let plan = plan(snapshot: snapshot, settings: settings, mode: mode, now: now)
        return report(
            mode: mode,
            generatedAt: now,
            expectedDeliveries: plan.expectedDeliveries,
            pendingNotifications: pendingNotifications,
            pendingAlarms: pendingAlarms,
            skippedDeliveries: plan.skippedDeliveries,
            alarmKitVerificationAvailable: alarmKitVerificationAvailable,
            notificationVerificationAvailable: notificationVerificationAvailable,
            permissionBlockedReasons: permissionBlockedReasons,
            schedulingFailedReasons: schedulingFailedReasons
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
        case .mixed:
            if event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue,
               deliveryKind == .boundary {
                return nil
            }
            if deliveryKind == .wake || deliveryKind == .iftarAlarm || deliveryKind == .iftarAdhan {
                return .alarmKit
            }
            return .notification
        }
    }

    private static func matches(expected: Date, actual: Date?, tolerance: TimeInterval) -> Bool {
        guard let actual else { return false }
        return abs(expected.timeIntervalSince(actual)) <= tolerance
    }

    private static func issue(
        _ category: DeliveryReconciliationCategory,
        expected: ExpectedAlarmDelivery,
        actualFireDate: Date? = nil,
        message: String? = nil
    ) -> DeliveryReconciliationIssue {
        DeliveryReconciliationIssue(
            category: category,
            channel: expected.channel,
            identifier: expected.channel == .notification ? expected.notificationIdentifier : nil,
            alarmIdentifier: expected.channel == .alarmKit ? expected.alarmIdentifier : nil,
            dateKey: expected.dateKey,
            eventID: expected.eventID,
            expectedFireDate: expected.fireDate,
            actualFireDate: actualFireDate,
            message: message
        )
    }
}
