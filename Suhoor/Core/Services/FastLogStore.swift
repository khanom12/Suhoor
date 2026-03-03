import Foundation
import Combine

final class FastLogStore: ObservableObject {
    @Published private(set) var entriesByDateKey: [String: FastLogEntry]
    @Published private(set) var currentRevision: Int

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.FastLogEntries"
    private let revisionKey = "Suhoor.FastLogEntriesRevision"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.fast-log-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: FastLogEntry].self, from: data) {
            self.entriesByDateKey = decoded
        } else {
            self.entriesByDateKey = [:]
        }
        self.currentRevision = defaults.integer(forKey: revisionKey)
    }

    func entry(for dateKey: String) -> FastLogEntry? {
        entriesByDateKey[dateKey]
    }

    func status(for dateKey: String) -> FastLogStatus {
        entriesByDateKey[dateKey]?.status ?? .unknown
    }

    func setStatus(
        _ status: FastLogStatus,
        for dateKey: String,
        intentSnapshot: FastIntentSnapshot? = nil,
        now: Date = Date()
    ) {
        if status == .unknown {
            updateEntry(nil, for: dateKey)
            return
        }

        var entry = entriesByDateKey[dateKey] ?? FastLogEntry(
            dateKey: dateKey,
            status: status,
            updatedAt: now,
            intentSnapshot: intentSnapshot
        )
        entry.status = status
        entry.updatedAt = now
        if entry.intentSnapshot == nil {
            entry.intentSnapshot = intentSnapshot
        }
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

    private func updateEntry(_ entry: FastLogEntry?, for dateKey: String) {
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
