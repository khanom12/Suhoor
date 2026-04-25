import Foundation

struct HijriAdjustmentChange: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let hijriYear: Int
    let month: HijriMonth
    let day: Int
    let oldDateKey: String
    let newDateKey: String
    let sourceLabel: String
    let timestamp: Date
}

final class HijriAdjustmentChangeStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.HijriAdjustmentChanges"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func pendingChanges() -> [HijriAdjustmentChange] {
        load()
    }

    func record(_ changes: [HijriAdjustmentChange]) {
        guard !changes.isEmpty else { return }
        var existing = load()
        existing.append(contentsOf: changes)
        save(existing)
    }

    func acknowledgeAll() {
        save([])
    }

    private func load() -> [HijriAdjustmentChange] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HijriAdjustmentChange].self, from: data) else {
            return []
        }
        return decoded
    }

    private func save(_ entries: [HijriAdjustmentChange]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
