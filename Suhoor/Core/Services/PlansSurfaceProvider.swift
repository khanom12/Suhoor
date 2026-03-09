import Foundation

struct PlansSurfaceProvider {
    func plansSurfaceSnapshot(
        defaults: DefaultAlarmConfig,
        settings: AppSettings,
        upcomingDays: [ActiveAlarmDay],
        overrideDateKeys: Set<String>,
        qadaBacklogState: QadaBacklogState,
        fastLogEntries: [String: FastLogEntry]
    ) -> PlansSurfaceSnapshot {
        let qadaProgress = QadaProgressEngine.snapshot(
            state: qadaBacklogState,
            logEntries: fastLogEntries
        )

        return PlansSurfaceSnapshot(
            defaultMorningPlanSummary: ProductSurfaceSnapshots.defaultMorningPlanSummary(
                defaults: defaults,
                settings: settings
            ),
            configuredPlansSnapshot: ProductSurfacePresentation.configuredPlansSnapshot(
                upcomingDays: upcomingDays,
                overrideDateKeys: overrideDateKeys,
                qadaProgress: qadaProgress
            ),
            qadaProgress: qadaProgress
        )
    }
}
