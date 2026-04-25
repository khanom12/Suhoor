import Foundation
import os

@MainActor
final class AlarmCoordinator {
    private let alarmScheduler: AlarmScheduling?

    init(
        alarmScheduler: AlarmScheduling?
    ) {
        self.alarmScheduler = alarmScheduler
    }

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        fajrDateTime: Date?,
        dateKey: String? = nil,
        wakeSessionID: String? = nil,
        soundRole: MorningSoundRole? = nil,
        wakeSessionRole: WakeSessionEventRole? = nil,
        fajrStartBehavior: FajrStartBehavior = .none,
        soundName: String? = nil,
        snoozeDuration: TimeInterval? = nil
    ) async -> Bool {
        guard let alarmScheduler else { return false }
        do {
            try await alarmScheduler.scheduleAlarm(
                id: id,
                kind: kind,
                date: date,
                label: label,
                soundName: soundName,
                snoozeDuration: snoozeDuration
            )
            return true
        } catch {
            Logging.scheduler.error("AlarmKit schedule error: \(error.localizedDescription)")
            return false
        }
    }

    func cancel(id: UUID) {
        guard let alarmScheduler else { return }
        alarmScheduler.cancel(id: id)
    }

    func cancel(ids: [UUID]) {
        ids.forEach { cancel(id: $0) }
    }
}
