import Foundation

protocol AlarmKitScheduling {
    func scheduleAlarm(
        for schedule: DaySchedule,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws

    func scheduleAlarm(
        id: UUID,
        kind: ScheduleEventKind,
        date: Date,
        label: String,
        soundName: String?
    ) async throws

    func cancelAllUpcoming(days: Int) async
    func cancel(schedule: DaySchedule, kind: ScheduleEventKind)
}
