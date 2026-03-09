import CoreLocation
import Foundation

struct MorningStateSnapshot: Sendable {
    let settings: AppSettings
    let defaultConfig: DefaultAlarmConfig
    let morningPlanState: MorningPlanState
    let dateAssignments: [PlanDateAssignment]
    let completionRecords: [CompletionRecord]
    let qadaLedgerSnapshot: QadaLedgerSnapshot
    let coordinate: CLLocationCoordinate2D
    let timeZone: TimeZone
    let locationDescription: String
    let fastTagSelections: [String: FastIntentSelection]
    let overridesByDateKey: [String: DailyAlarmOverride]
}
