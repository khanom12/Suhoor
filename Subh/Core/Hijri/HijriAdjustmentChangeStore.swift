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
    let intentAnchor: MorningIntentAnchor?
    let reviewState: PlanningReviewState?

    init(
        id: UUID,
        hijriYear: Int,
        month: HijriMonth,
        day: Int,
        oldDateKey: String,
        newDateKey: String,
        sourceLabel: String,
        timestamp: Date,
        intentAnchor: MorningIntentAnchor? = nil,
        reviewState: PlanningReviewState? = nil
    ) {
        self.id = id
        self.hijriYear = hijriYear
        self.month = month
        self.day = day
        self.oldDateKey = oldDateKey
        self.newDateKey = newDateKey
        self.sourceLabel = sourceLabel
        self.timestamp = timestamp
        self.intentAnchor = intentAnchor
        self.reviewState = reviewState
    }
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
