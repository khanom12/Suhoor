import Foundation
import os

struct EventTimelineEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let category: String
    let message: String

    init(timestamp: Date = Date(), category: String, message: String) {
        self.id = UUID()
        self.timestamp = timestamp
        self.category = category
        self.message = message
    }
}

final class EventTimelineLog {
    static let shared = EventTimelineLog()

    private let storageKey = "suhoor.eventTimelineLog"
    private let maxEntries = 200
    private let logger = Logging.diagnostics

    private init() {}

    func record(category: String, message: String) {
        var entries = loadEntries()
        entries.append(EventTimelineEntry(category: category, message: message))
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }
        store(entries: entries)
        logger.info("[\(category)] \(message)")
    }

    func entries() -> [EventTimelineEntry] {
        loadEntries().reversed()
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        logger.info("Event timeline cleared")
    }

    private func loadEntries() -> [EventTimelineEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([EventTimelineEntry].self, from: data)) ?? []
    }

    private func store(entries: [EventTimelineEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
