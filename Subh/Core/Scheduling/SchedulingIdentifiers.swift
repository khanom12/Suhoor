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

    static func identifier(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        channel: AlarmDeliveryChannel
    ) -> String {
        switch channel {
        case .notification:
            return identifier(for: event, deliveryKind: deliveryKind)
        case .alarmKit:
            return "\(identifier(for: event, deliveryKind: deliveryKind)).alarmKit"
        }
    }

    static func alarmID(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind
    ) -> UUID {
        DateHelpers.stableUUID(from: identifier(for: event, deliveryKind: deliveryKind))
    }

    static func alarmID(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        channel: AlarmDeliveryChannel
    ) -> UUID {
        switch channel {
        case .notification:
            return alarmID(for: event, deliveryKind: deliveryKind)
        case .alarmKit:
            return DateHelpers.stableUUID(from: identifier(for: event, deliveryKind: deliveryKind, channel: channel))
        }
    }

    static func testWakeSessionID(scenarioID: String) -> String {
        "test.wakeSession.\(scenarioID)"
    }

    static func testWakePrimaryEventID(scenarioID: String) -> String {
        "\(testWakeSessionID(scenarioID: scenarioID)).primary"
    }

    static func testWakeCheckEventID(scenarioID: String, index: Int) -> String {
        "\(testWakeSessionID(scenarioID: scenarioID)).check.\(index)"
    }

    static func isTestIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix("test.")
    }
}
