import CoreLocation
import Foundation

enum MorningStateAssembler {
    static func assemble(
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig,
        morningPlanStore: MorningPlanStore,
        fastTagSelections: [String: FastIntentSelection],
        fastLogEntries: [String: FastLogEntry],
        fajrLogEntries: [String: FajrLogEntry],
        qadaBacklogState: QadaBacklogState,
        qadaBatchState: QadaBatchState,
        overridesByDateKey: [String: DailyAlarmOverride],
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        locationDescription: String,
        provenancesByDateKey: [String: [ResolvedScheduledDateProvenance]]
    ) -> MorningStateSnapshot {
        let completionSnapshot = LegacyCompletionAdapter.records(
            fajrEntries: fajrLogEntries,
            fastEntries: fastLogEntries,
            qadaBacklogState: qadaBacklogState
        )
        let dateAssignments = LegacyDateAssignmentAdapter.assignments(
            overridesByDay: overridesByDateKey,
            provenancesByDateKey: provenancesByDateKey,
            fastTagSelections: fastTagSelections,
            qadaBatchState: qadaBatchState
        )

        return MorningStateSnapshot(
            settings: settings,
            defaultConfig: defaultConfig,
            morningPlanState: LegacyMorningPlanAdapter.loadState(from: morningPlanStore),
            dateAssignments: dateAssignments.assignments,
            completionRecords: completionSnapshot.records,
            qadaLedgerSnapshot: completionSnapshot.qadaLedgerSnapshot,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: locationDescription,
            fastTagSelections: fastTagSelections,
            overridesByDateKey: overridesByDateKey
        )
    }
}
