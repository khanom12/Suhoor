import Foundation

protocol AlarmScheduling {
    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?,
        snoozeDuration: TimeInterval?
    ) async throws

    func cancel(id: UUID)
}
