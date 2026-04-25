import Foundation
import AlarmKit

@available(iOS 26.0, *)
@MainActor
final class AlarmEventRouter {
    private let recordStore: AlarmRecordStore
    private let stateStore: AlarmStateStore
    private let countdownManager: CountdownManager
    private let eventLog: DebugEventLog
    private let enableCountdown: Bool

    private var updatesTask: Task<Void, Never>?
    private var lastStates: [UUID: AlarmKnownState] = [:]

    init(
        recordStore: AlarmRecordStore,
        stateStore: AlarmStateStore,
        countdownManager: CountdownManager,
        eventLog: DebugEventLog = .shared,
        enableCountdown: Bool
    ) {
        self.recordStore = recordStore
        self.stateStore = stateStore
        self.countdownManager = countdownManager
        self.eventLog = eventLog
        self.enableCountdown = enableCountdown
    }

    func start() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard #available(iOS 26.0, *) else { return }
            guard let self else { return }
            for await alarms in AlarmManager.shared.alarmUpdates {
                await self.handleUpdate(alarms: alarms)
            }
        }
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    private func handleUpdate(alarms: [Alarm]) async {
        var currentStates: [UUID: AlarmKnownState] = [:]

        for alarm in alarms {
            let id = alarm.id
            let newState = mapState(alarm.state)
            currentStates[id] = newState
            let previousState = lastStates[id]

            if previousState != newState {
                await handleStateChange(id: id, newState: newState, previousState: previousState)
            }
        }

        let missingIds = Set(lastStates.keys).subtracting(currentStates.keys)
        for id in missingIds {
            await handleAlarmDismissed(id: id)
        }

        lastStates = currentStates
    }

    private func handleStateChange(id: UUID, newState: AlarmKnownState, previousState: AlarmKnownState?) async {
        stateStore.update(id: id, state: newState)
        guard let record = recordStore.record(for: id) else { return }

        if newState == .alerting, previousState != .alerting {
            await handleAlarmFired(record: record)
            return
        }
    }

    func handleAlarmFired(record: AlarmRecord) async {
        switch record.kind {
        case .wake:
            eventLog.record(.firedSuhoor, metadata: ["id": record.id.uuidString])
        case .reminder:
            eventLog.record(.firedFajrReminder, metadata: ["id": record.id.uuidString])
            if enableCountdown, let fajrDateTime = record.fajrDateTime {
                await countdownManager.startCountdown(fajrDateTime: fajrDateTime, testRunId: record.testRunId)
            }
        case .boundary:
            eventLog.record(.firedFajrAdhan, metadata: ["id": record.id.uuidString])
            if enableCountdown {
                await countdownManager.endCountdownIfNeeded(reason: "adhan_fired")
            }
        case .iftarNotification, .iftarAlarm, .iftarAdhan:
            eventLog.record(.firedFajrAdhan, metadata: [
                "id": record.id.uuidString,
                "phase": "iftar"
            ])
        }
    }

    func handleAlarmDismissed(id: UUID) async {
        stateStore.update(id: id, state: .dismissed)
        guard let record = recordStore.record(for: id) else { return }
        if record.kind == .wake {
            eventLog.record(.dismissedSuhoor, metadata: ["id": record.id.uuidString])
        }
        recordStore.remove(id: id)
    }

    private func mapState(_ state: Alarm.State) -> AlarmKnownState {
        switch state {
        case .alerting:
            return .alerting
        case .countdown:
            return .countdown
        case .paused:
            return .paused
        case .scheduled:
            return .scheduled
        @unknown default:
            return .unknown
        }
    }
}
