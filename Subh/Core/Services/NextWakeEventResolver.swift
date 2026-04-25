import Foundation

struct NextWakeEventResolver {
    func resolve(
        activeWindowSnapshot: ActiveAlarmWindowSnapshot,
        now: Date = Date()
    ) -> NextWakeEventSummary? {
        let priorityByType: [ScheduledEventType: Int] = [
            .wakeReminder: 0,
            .wakeAlarm: 1,
            .wakeFollowUp: 2,
        ]

        let candidates = activeWindowSnapshot.visibleDays.flatMap { day in
            day.scheduledEvents.compactMap { event -> NextWakeEventSummary? in
                guard let priority = priorityByType[event.type], event.fireDate >= now else { return nil }
                return NextWakeEventSummary(
                    day: day,
                    event: event,
                    priority: priority
                )
            }
        }

        return candidates.min {
            if $0.event.fireDate == $1.event.fireDate {
                return $0.priority < $1.priority
            }
            return $0.event.fireDate < $1.event.fireDate
        }
    }
}
