import Foundation

struct WakeSurfaceProvider {
    func wakeSurfaceSnapshot(
        activeWindowSnapshot: ActiveAlarmWindowSnapshot,
        nextWakeEventSummary: NextWakeEventSummary?,
        overrideDateKeys: Set<String>
    ) -> WakeSurfaceSnapshot {
        WakeSurfaceSnapshot(
            visibleDays: activeWindowSnapshot.visibleDays,
            nextWakeEventSummary: nextWakeEventSummary,
            overrideDateKeys: overrideDateKeys
        )
    }
}
