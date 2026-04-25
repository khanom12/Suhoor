import Foundation

protocol QadaPlanMaintenanceService: Sendable {
    nonisolated func suggestReschedule(forMissedDateKey dateKey: String) -> Date?
}

struct NoOpQadaPlanMaintenanceService: QadaPlanMaintenanceService {
    nonisolated func suggestReschedule(forMissedDateKey dateKey: String) -> Date? {
        nil
    }
}
