import Foundation

struct CompletionSurfaceProvider {
    func progressSurfaceSnapshot(
        todayCompletion: DailyCompletionSnapshot,
        recentDateKeys: [String],
        completionState: CompletionStateSnapshot,
        wakeProgress: WakeProgressSnapshot
    ) -> ProgressSurfaceSnapshot {
        CompletionProjectionBuilder.buildProgress(
            todayCompletion: todayCompletion,
            recentDateKeys: recentDateKeys,
            completionState: completionState,
            wakeProgress: wakeProgress
        )
    }

    func fajrHistorySurfaceSnapshot(
        window: CompletionHistoryWindow
    ) -> FajrHistorySurfaceSnapshot {
        CompletionHistoryProjectionBuilder.buildFajr(window: window)
    }

    func fastHistorySurfaceSnapshot(
        window: CompletionHistoryWindow
    ) -> FastHistorySurfaceSnapshot {
        CompletionHistoryProjectionBuilder.buildFast(window: window)
    }
}
