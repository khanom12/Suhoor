import Foundation

enum ScheduleEventKind: String, CaseIterable, Codable {
    case wake
    case reminder
    case boundary

    var title: String {
        switch self {
        case .wake: return "Suhoor"
        case .reminder: return "Fajr reminder"
        case .boundary: return "Fajr"
        }
    }

    var body: String {
        switch self {
        case .wake: return "Time to wake up before Fajr."
        case .reminder: return "Fajr is coming soon."
        case .boundary: return "Fajr has started."
        }
    }
}
