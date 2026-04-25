import Foundation

struct SchedulingIdentifiers {
    static func dailyIdentifier(for schedule: DaySchedule, kind: ScheduleEventKind) -> String {
        switch kind {
        case .wake:
            return "suhoor-\(schedule.id)"
        case .reminder:
            return "reminder-\(schedule.id)"
        case .boundary:
            return "fajr-\(schedule.id)"
        case .iftarNotification:
            return "iftar-notification-\(schedule.id)"
        case .iftarAlarm:
            return "iftar-alarm-\(schedule.id)"
        case .iftarAdhan:
            return "iftar-adhan-\(schedule.id)"
        }
    }

    static func legacyDailyIdentifier(for schedule: DaySchedule, kind: ScheduleEventKind) -> String {
        "suhoor.\(schedule.id).\(kind.rawValue)"
    }

    static func legacyDailyIdentifierV1(for schedule: DaySchedule, kind: ScheduleEventKind) -> String {
        "suhoor-\(schedule.id)-\(kind.rawValue)"
    }

    static func alarmID(for schedule: DaySchedule, kind: ScheduleEventKind) -> UUID {
        DateHelpers.stableUUID(from: dailyIdentifier(for: schedule, kind: kind))
    }

    static func legacyAlarmID(for schedule: DaySchedule, kind: ScheduleEventKind) -> UUID {
        DateHelpers.stableUUID(from: legacyDailyIdentifier(for: schedule, kind: kind))
    }

    static func legacyAlarmIDV1(for schedule: DaySchedule, kind: ScheduleEventKind) -> UUID {
        DateHelpers.stableUUID(from: legacyDailyIdentifierV1(for: schedule, kind: kind))
    }

    static func identifier(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind
    ) -> String {
        "\(event.id).\(deliveryKind.rawValue)"
    }

    static func alarmID(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind
    ) -> UUID {
        DateHelpers.stableUUID(from: identifier(for: event, deliveryKind: deliveryKind))
    }
}
