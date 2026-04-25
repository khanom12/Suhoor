import Foundation

struct AlarmKitTestSnapshot {
    let now: Date
    let testRun: AlarmKitTestRunState?
    let alarmStates: [AlarmStateEntry]
    let countdownSession: CountdownSession?
    let events: [DebugEvent]
}
