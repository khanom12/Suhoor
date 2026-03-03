import Foundation
import Combine

final class FastTagStore: ObservableObject {
    @Published private(set) var selections: [String: FastIntentSelection]
    @Published private(set) var currentRevision: Int

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.FastIntentSelections"
    private let revisionKey = "Suhoor.FastIntentSelectionsRevision"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.fast-tag-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: FastIntentSelection].self, from: data) {
            self.selections = decoded
        } else {
            self.selections = [:]
        }
        self.currentRevision = defaults.integer(forKey: revisionKey)
    }

    func selection(for date: Date, timeZone: TimeZone) -> FastIntentSelection? {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return selections[key]
    }

    func setSelection(_ selection: FastIntentSelection, for date: Date, timeZone: TimeZone) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let normalized = FastIntentEngine.normalizedSelection(
            selection,
            for: date,
            ruleset: .strict,
            timeZone: timeZone
        )
        let newSelection: FastIntentSelection? = normalized.hasMeaningfulTags ? normalized : nil
        updateSelection(newSelection, for: key)
    }

    func removeSelection(for date: Date, timeZone: TimeZone) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        updateSelection(nil, for: key)
    }

    private func updateSelection(_ selection: FastIntentSelection?, for key: String) {
        let existing = selections[key]
        guard existing != selection else { return }
        selections[key] = selection
        bumpRevision()
    }

    private func bumpRevision() {
        currentRevision += 1
        persist()
    }

    private func persist() {
        let snapshot = selections
        let revision = currentRevision
        persistence.schedule { [defaults, storageKey, revisionKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
            defaults.set(revision, forKey: revisionKey)
        }
    }
}
