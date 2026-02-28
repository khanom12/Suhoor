import Foundation
import UserNotifications

struct AlarmKitAuditItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let scheduleDescription: String
    let nextTriggerDate: Date?
    let stateDescription: String
}

struct ExpectedScheduledEvent: Identifiable, Equatable {
    enum Channel: String {
        case alarmKit
        case notification
    }

    let id: UUID
    let kind: ScheduleEventKind
    let date: Date
    let dayLabel: String
    let scheduleId: String
    let channel: Channel
    let identifier: String
    let isPast: Bool

    init(kind: ScheduleEventKind, date: Date, dayLabel: String, scheduleId: String, channel: Channel, identifier: String, isPast: Bool) {
        self.id = UUID()
        self.kind = kind
        self.date = date
        self.dayLabel = dayLabel
        self.scheduleId = scheduleId
        self.channel = channel
        self.identifier = identifier
        self.isPast = isPast
    }
}

struct NotificationAuditItem: Identifiable, Equatable {
    let id: String
    let title: String
    let triggerDate: Date?

    init(request: UNNotificationRequest) {
        id = request.identifier
        title = request.content.title
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
            triggerDate = trigger.nextTriggerDate()
        } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
            triggerDate = Date().addingTimeInterval(trigger.timeInterval)
        } else {
            triggerDate = nil
        }
    }
}

struct AuditMismatch: Identifiable, Equatable {
    enum Severity: String {
        case error
        case warning
    }

    let id: UUID
    let severity: Severity
    let message: String

    init(severity: Severity, message: String) {
        self.id = UUID()
        self.severity = severity
        self.message = message
    }
}

struct SchedulingAuditSnapshot: Equatable {
    let generatedAt: Date
    let expectedEvents: [ExpectedScheduledEvent]
    let notificationItems: [NotificationAuditItem]
    let alarmKitItems: [AlarmKitAuditItem]
    let mismatches: [AuditMismatch]
}
