import Foundation
import os

@MainActor
final class AlarmCoordinator {
    private let alarmScheduler: AlarmScheduling?
    private let recordStore: AlarmRecordStore
    private let stateStore: AlarmStateStore
    private let eventLog: DebugEventLog
    private let timeProvider: TimeProviding

    init(
        alarmScheduler: AlarmScheduling?,
        recordStore: AlarmRecordStore,
        stateStore: AlarmStateStore,
        eventLog: DebugEventLog? = nil,
        timeProvider: TimeProviding? = nil
    ) {
        self.alarmScheduler = alarmScheduler
        self.recordStore = recordStore
        self.stateStore = stateStore
        self.eventLog = eventLog ?? .shared
        self.timeProvider = timeProvider ?? SystemTimeProvider()
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
        snoozeDuration: TimeInterval? = nil,
        isTest: Bool = false,
        testRunId: UUID? = nil
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
            let record = AlarmRecord(
                id: id,
                kind: kind,
                scheduledDate: date,
                fajrDateTime: fajrDateTime,
                dateKey: dateKey,
                wakeSessionID: wakeSessionID,
                soundRole: soundRole,
                wakeSessionRole: wakeSessionRole,
                fajrStartBehavior: fajrStartBehavior,
                isTest: isTest,
                testRunId: testRunId,
                label: label
            )
            recordStore.upsert(record)
            stateStore.update(id: id, state: .scheduled)
            logScheduled(kind: kind, id: id, date: date, isTest: isTest, testRunId: testRunId)
            return true
        } catch {
            Logging.scheduler.error("AlarmKit schedule error: \(error.localizedDescription)")
            return false
        }
    }

    func cancel(id: UUID) {
        guard let alarmScheduler else { return }
        alarmScheduler.cancel(id: id)
        stateStore.update(id: id, state: .dismissed)
        recordStore.remove(id: id)
    }

    func cancel(ids: [UUID]) {
        ids.forEach { cancel(id: $0) }
    }

    func scheduleSnooze(
        for baseAlarmId: UUID,
        date: Date,
        label: String,
        snoozeDuration: TimeInterval,
        testRunId: UUID? = nil
    ) async -> UUID? {
        let snoozeId = UUID()
        let scheduled = await scheduleAlarm(
            id: snoozeId,
            kind: .wake,
            date: date,
            label: label,
            fajrDateTime: nil,
            soundName: nil,
            snoozeDuration: snoozeDuration,
            isTest: testRunId != nil,
            testRunId: testRunId
        )
        if scheduled {
            eventLog.record(
                .scheduledSuhoorSnooze,
                metadata: [
                    "baseAlarmId": baseAlarmId.uuidString,
                    "snoozeAlarmId": snoozeId.uuidString,
                    "date": date.description
                ]
            )
            return snoozeId
        }
        return nil
    }

    private func logScheduled(kind: ScheduleEventKind, id: UUID, date: Date, isTest: Bool, testRunId: UUID?) {
        let metadata: [String: String] = [
            "id": id.uuidString,
            "date": date.description,
            "isTest": "\(isTest)",
            "testRunId": testRunId?.uuidString ?? ""
        ]
        switch kind {
        case .wake:
            eventLog.record(.scheduledSuhoor, metadata: metadata)
        case .reminder:
            eventLog.record(.scheduledFajrReminder, metadata: metadata)
        case .boundary:
            eventLog.record(.scheduledFajrAdhan, metadata: metadata)
        case .iftarNotification, .iftarAlarm, .iftarAdhan:
            eventLog.record(.scheduledFajrAdhan, metadata: metadata.merging(["phase": "iftar"]) { _, new in new })
        }
    }

}
