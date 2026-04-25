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
    private let defaults: UserDefaults
    private let lock = NSLock()
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.event-timeline-log",
        delay: 1.0
    )
    private var cachedEntries: [EventTimelineEntry]

    #if DEBUG
    private let persistenceEnabled = true
    #else
    private let persistenceEnabled = false
    #endif

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cachedEntries = Self.loadEntries(from: defaults, key: storageKey)
    }

    func record(category: String, message: String) {
        let entry = EventTimelineEntry(category: category, message: message)
        lock.lock()
        cachedEntries.append(entry)
        if cachedEntries.count > maxEntries {
            cachedEntries = Array(cachedEntries.suffix(maxEntries))
        }
        let snapshot = cachedEntries
        lock.unlock()
        schedulePersist(snapshot)
        logger.info("[\(category)] \(message)")
    }

    func entries() -> [EventTimelineEntry] {
        lock.lock()
        let snapshot = cachedEntries.reversed()
        lock.unlock()
        return Array(snapshot)
    }

    func clear() {
        persistence.cancelPending()
        lock.lock()
        cachedEntries.removeAll()
        lock.unlock()
        defaults.removeObject(forKey: storageKey)
        logger.info("Event timeline cleared")
    }

    private func schedulePersist(_ entries: [EventTimelineEntry]) {
        guard persistenceEnabled else { return }
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(entries) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadEntries(from defaults: UserDefaults, key: String) -> [EventTimelineEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([EventTimelineEntry].self, from: data)) ?? []
    }
}
