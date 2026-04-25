import Foundation

enum ScheduleEventKind: String, CaseIterable, Codable, Sendable {
    case wake
    case reminder
    case boundary
    case iftarNotification
    case iftarAlarm
    case iftarAdhan

    var title: String {
        switch self {
        case .wake: return "Wake"
        case .reminder: return "Fajr reminder"
        case .boundary: return "Fajr"
        case .iftarNotification, .iftarAlarm, .iftarAdhan: return "Iftar"
        }
    }

    var body: String {
        switch self {
        case .wake: return "Time to wake up before Fajr."
        case .reminder: return "Fajr is coming soon."
        case .boundary: return "Fajr has started."
        case .iftarNotification, .iftarAlarm, .iftarAdhan: return "Maghrib has begun."
        }
    }
}
