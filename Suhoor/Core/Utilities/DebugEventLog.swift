import Foundation
import os

enum DebugEventType: String, Codable, CaseIterable {
    case scheduledSuhoor = "scheduled_suhoor"
    case firedSuhoor = "fired_suhoor"
    case dismissedSuhoor = "dismissed_suhoor"
    case snoozedSuhoor = "snoozed_suhoor"
    case scheduledSuhoorSnooze = "scheduled_suhoor_snooze"
    case scheduledFajrReminder = "scheduled_fajr_reminder"
    case firedFajrReminder = "fired_fajr_reminder"
    case countdownStarted = "countdown_started"
    case countdownStoppedByUser = "countdown_stopped_by_user"
    case countdownEnded = "countdown_ended"
    case scheduledFajrAdhan = "scheduled_fajr_adhan"
    case firedFajrAdhan = "fired_fajr_adhan"
    case canceledTestAlarms = "canceled_test_alarms"
    case cleanupLiveActivities = "cleanup_live_activities"
}

struct DebugEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let type: DebugEventType
    let metadata: [String: String]

    init(timestamp: Date = Date(), type: DebugEventType, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = timestamp
        self.type = type
        self.metadata = metadata
    }
}

final class DebugEventLog {
    static let shared = DebugEventLog()

    private let storageKey = "suhoor.debugEventLog"
    private let maxEntries = 200
    private let logger = Logging.diagnostics

    private init() {}

    func record(_ type: DebugEventType, metadata: [String: String] = [:]) {
        var entries = loadEntries()
        entries.append(DebugEvent(type: type, metadata: metadata))
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }
        store(entries: entries)
        if metadata.isEmpty {
            logger.info("[DebugEvent] \(type.rawValue)")
        } else {
            logger.info("[DebugEvent] \(type.rawValue) metadata=\(metadata)")
        }
    }

    func events(limit: Int) -> [DebugEvent] {
        Array(loadEntries().suffix(limit).reversed())
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        logger.info("Debug event log cleared")
    }

    private func loadEntries() -> [DebugEvent] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([DebugEvent].self, from: data)) ?? []
    }

    private func store(entries: [DebugEvent]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
