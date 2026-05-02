import Foundation

struct SchedulingReconciliationResult: Sendable {
    let schedulingMode: SchedulingMode
    let statusText: String
}

enum SchedulingReconciler {
    static func reconcile(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        requestedMode: SchedulingMode,
        alarmScheduler: AlarmScheduler,
        cancelAll: @escaping @Sendable () async -> Void,
        blockedMessage: @escaping @Sendable () async -> String
    ) async -> SchedulingReconciliationResult {
        let hasAnyEnabled = snapshot.visibleDays.contains { day in
            let config = day.effectiveConfig
            return !config.skipDay && config.hasAnyEnabled
        }

        guard hasAnyEnabled else {
            await cancelAll()
            return SchedulingReconciliationResult(
                schedulingMode: .none,
                statusText: "Off"
            )
        }

        guard requestedMode != .none else {
            await cancelAll()
            return SchedulingReconciliationResult(
                schedulingMode: .none,
                statusText: await blockedMessage()
            )
        }

        let scheduled = await alarmScheduler.scheduleAll(
            days: snapshot.scheduledDays,
            settings: settings,
            mode: requestedMode,
            cancelWindowDays: snapshot.scheduledHorizonDays
        )
        return SchedulingReconciliationResult(
            schedulingMode: requestedMode,
            statusText: scheduled ? "Scheduled" : "Unable to schedule"
        )
    }
}
