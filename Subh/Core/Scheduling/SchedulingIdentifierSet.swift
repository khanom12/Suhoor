import Foundation

struct SchedulingIdentifierSet: Equatable, Sendable {
    let notificationIdentifiers: [String]
    let alarmIdentifiers: [UUID]

    init(
        notificationIdentifiers: some Sequence<String> = [],
        alarmIdentifiers: some Sequence<UUID> = []
    ) {
        self.notificationIdentifiers = Array(Set(notificationIdentifiers)).sorted()
        self.alarmIdentifiers = Array(Set(alarmIdentifiers)).sorted { $0.uuidString < $1.uuidString }
    }

    func union(_ other: SchedulingIdentifierSet) -> SchedulingIdentifierSet {
        SchedulingIdentifierSet(
            notificationIdentifiers: notificationIdentifiers + other.notificationIdentifiers,
            alarmIdentifiers: alarmIdentifiers + other.alarmIdentifiers
        )
    }

    static func forSchedule(
        _ schedule: DaySchedule,
        events: [ScheduledEvent] = []
    ) -> SchedulingIdentifierSet {
        var notificationIdentifiers: [String] = []
        var alarmIdentifiers: [UUID] = []

        for kind in ScheduleEventKind.allCases {
            notificationIdentifiers.append(SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: kind))
            notificationIdentifiers.append(SchedulingIdentifiers.legacyDailyIdentifier(for: schedule, kind: kind))
            notificationIdentifiers.append(SchedulingIdentifiers.legacyDailyIdentifierV1(for: schedule, kind: kind))

            alarmIdentifiers.append(SchedulingIdentifiers.alarmID(for: schedule, kind: kind))
            alarmIdentifiers.append(SchedulingIdentifiers.legacyAlarmID(for: schedule, kind: kind))
            alarmIdentifiers.append(SchedulingIdentifiers.legacyAlarmIDV1(for: schedule, kind: kind))
        }

        for event in eventStubs(for: schedule) + events {
            for deliveryKind in event.deliveryKinds {
                notificationIdentifiers.append(SchedulingIdentifiers.identifier(for: event, deliveryKind: deliveryKind))
                alarmIdentifiers.append(SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind))
                alarmIdentifiers.append(
                    SchedulingIdentifiers.alarmID(
                        for: event,
                        deliveryKind: deliveryKind,
                        channel: .alarmKit
                    )
                )
            }
        }

        return SchedulingIdentifierSet(
            notificationIdentifiers: notificationIdentifiers,
            alarmIdentifiers: alarmIdentifiers
        )
    }

    static func forEvent(
        _ event: ScheduledEvent,
        deliveryKind: ScheduleEventKind
    ) -> SchedulingIdentifierSet {
        SchedulingIdentifierSet(
            notificationIdentifiers: [SchedulingIdentifiers.identifier(for: event, deliveryKind: deliveryKind)],
            alarmIdentifiers: [
                SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind),
                SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind, channel: .alarmKit)
            ]
        )
    }

    static func forUpcoming(days: Int, now: Date = Date(), timeZone: TimeZone = .current) -> SchedulingIdentifierSet {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: now)
        var result = SchedulingIdentifierSet()

        for offset in 0..<max(0, days) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            result = result.union(forSchedule(stubSchedule(for: day, timeZone: timeZone)))
        }

        return result
    }

    private static func eventStubs(for schedule: DaySchedule) -> [ScheduledEvent] {
        [
            ScheduledEvent(
                id: "\(schedule.id).wakeReminder",
                type: .wakeReminder,
                dateKey: schedule.id,
                fireDate: schedule.reminderDate ?? schedule.wakeDate,
                relativeTo: .absolute,
                isUserVisible: true,
                affectsCompletion: false,
                deliveryKinds: [.reminder]
            ),
            ScheduledEvent(
                id: "\(schedule.id).wakeAlarm",
                type: .wakeAlarm,
                dateKey: schedule.id,
                fireDate: schedule.wakeDate,
                relativeTo: .absolute,
                isUserVisible: true,
                affectsCompletion: true,
                deliveryKinds: [.wake]
            ),
            ScheduledEvent(
                id: "\(schedule.id).fajrBoundaryNotice",
                type: .fajrBoundaryNotice,
                dateKey: schedule.id,
                fireDate: schedule.boundaryDate ?? schedule.fajrDate,
                relativeTo: .absolute,
                isUserVisible: true,
                affectsCompletion: false,
                deliveryKinds: [.boundary]
            ),
            ScheduledEvent(
                id: "\(schedule.id).iftarReminder",
                type: .iftarReminder,
                dateKey: schedule.id,
                fireDate: schedule.iftarDate ?? schedule.maghribDate,
                relativeTo: .absolute,
                isUserVisible: true,
                affectsCompletion: false,
                deliveryKinds: [.iftarNotification, .iftarAlarm, .iftarAdhan]
            )
        ]
    }

    private static func stubSchedule(for day: Date, timeZone: TimeZone) -> DaySchedule {
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
            timeZone: timeZone
        )
    }
}
