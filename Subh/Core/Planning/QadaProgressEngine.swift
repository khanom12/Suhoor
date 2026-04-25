import Foundation

struct QadaProgressSnapshot: Equatable, Sendable {
    let remaining: Int
    let completed: Int
    let baselineOwed: Int
}

enum QadaProgressEngine {
    static func snapshot(
        state: QadaBacklogState,
        logEntries: [String: FastLogEntry]
    ) -> QadaProgressSnapshot {
        let startKey = state.trackingStartDateKey
        let baseline = max(0, state.baselineOwed)
        var completed = 0

        for (dateKey, entry) in logEntries {
            guard dateKey >= startKey,
                  entry.status == .completed,
                  entry.intentSnapshot?.primaryIntent == .qadaMakeup else {
                continue
            }
            completed += 1
        }

        let remaining = max(0, baseline - completed)
        return QadaProgressSnapshot(
            remaining: remaining,
            completed: completed,
            baselineOwed: baseline
        )
    }
}
