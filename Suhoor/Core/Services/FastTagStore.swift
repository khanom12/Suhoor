import Foundation
import Combine

final class FastTagStore: ObservableObject {
    @Published private(set) var selections: [String: FastIntentSelection]

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.FastIntentSelections"
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
        if normalized.hasMeaningfulTags {
            selections[key] = normalized
        } else {
            selections[key] = nil
        }
        persist()
    }

    func removeSelection(for date: Date, timeZone: TimeZone) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        selections[key] = nil
        persist()
    }

    private func persist() {
        let snapshot = selections
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
