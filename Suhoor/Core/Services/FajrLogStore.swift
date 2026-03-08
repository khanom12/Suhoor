import Foundation
import Combine

enum FajrCompletionStatus: String, Codable, CaseIterable, Sendable {
    case unknown
    case completed
    case missed

    var title: String {
        switch self {
        case .unknown:
            return "Not logged"
        case .completed:
            return "Made Fajr"
        case .missed:
            return "Missed Fajr"
        }
    }
}

struct FajrLogEntry: Codable, Equatable, Sendable {
    let dateKey: String
    var status: FajrCompletionStatus
    var updatedAt: Date
}

final class FajrLogStore: ObservableObject {
    @Published private(set) var entriesByDateKey: [String: FajrLogEntry]
    @Published private(set) var currentRevision: Int

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.FajrLogEntries"
    private let revisionKey = "Suhoor.FajrLogEntriesRevision"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.fajr-log-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: FajrLogEntry].self, from: data) {
            self.entriesByDateKey = decoded
        } else {
            self.entriesByDateKey = [:]
        }
        self.currentRevision = defaults.integer(forKey: revisionKey)
    }

    func entry(for dateKey: String) -> FajrLogEntry? {
        entriesByDateKey[dateKey]
    }

    func status(for dateKey: String) -> FajrCompletionStatus {
        entriesByDateKey[dateKey]?.status ?? .unknown
    }

    func setStatus(
        _ status: FajrCompletionStatus,
        for dateKey: String,
        now: Date = Date()
    ) {
        if status == .unknown {
            updateEntry(nil, for: dateKey)
            return
        }

        var entry = entriesByDateKey[dateKey] ?? FajrLogEntry(
            dateKey: dateKey,
            status: status,
            updatedAt: now
        )
        entry.status = status
        entry.updatedAt = now
        updateEntry(entry, for: dateKey)
    }

    func clear(for dateKey: String) {
        updateEntry(nil, for: dateKey)
    }

    func reset() {
        persistence.cancelPending()
        entriesByDateKey = [:]
        currentRevision = 0
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: revisionKey)
    }

    private func updateEntry(_ entry: FajrLogEntry?, for dateKey: String) {
        let existing = entriesByDateKey[dateKey]
        guard existing != entry else { return }
        entriesByDateKey[dateKey] = entry
        bumpRevision()
    }

    private func bumpRevision() {
        currentRevision += 1
        persist()
    }

    private func persist() {
        let snapshot = entriesByDateKey
        let revision = currentRevision
        persistence.schedule { [defaults, storageKey, revisionKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
            defaults.set(revision, forKey: revisionKey)
        }
    }

#if DEBUG
    func flushPersistenceForTesting() {
        persistence.flush()
    }
#endif
}
