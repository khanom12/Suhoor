import Foundation

enum AlarmKnownState: String, Codable {
    case scheduled
    case alerting
    case countdown
    case paused
    case dismissed
    case unknown

    var isScheduled: Bool {
        switch self {
        case .scheduled, .alerting, .countdown, .paused:
            return true
        case .dismissed, .unknown:
            return false
        }
    }
}

struct AlarmStateEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var state: AlarmKnownState
    var lastUpdated: Date
}

final class AlarmStateStore {
    private let storageKey = "suhoor.alarmStateStore"

    func update(id: UUID, state: AlarmKnownState, timestamp: Date = Date()) {
        var entries = loadEntries()
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].state = state
            entries[index].lastUpdated = timestamp
        } else {
            entries.append(AlarmStateEntry(id: id, state: state, lastUpdated: timestamp))
        }
        store(entries: entries)
    }

    func entry(for id: UUID) -> AlarmStateEntry? {
        loadEntries().first(where: { $0.id == id })
    }

    func entries() -> [AlarmStateEntry] {
        loadEntries()
    }

    func remove(id: UUID) {
        var entries = loadEntries()
        entries.removeAll { $0.id == id }
        store(entries: entries)
    }

    func isUnresolved(id: UUID) -> Bool {
        entry(for: id)?.state.isScheduled ?? false
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func loadEntries() -> [AlarmStateEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([AlarmStateEntry].self, from: data)) ?? []
    }

    private func store(entries: [AlarmStateEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
