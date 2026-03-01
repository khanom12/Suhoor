import Foundation
import Combine

final class FastTagStore: ObservableObject {
    @Published private(set) var selections: [String: FastIntentSelection]

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.FastIntentSelections"

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
        if selection.hasMeaningfulTags {
            selections[key] = selection
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
        guard let data = try? JSONEncoder().encode(selections) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
