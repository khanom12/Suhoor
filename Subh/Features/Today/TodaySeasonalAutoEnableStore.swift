import Foundation

final class TodaySeasonalAutoEnableStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.TodaySeasonalAutoEnabledKeys"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasAutoEnabled(_ card: TodayCardKind, for hijriDateKey: String) -> Bool {
        storedKeys.contains(storageValue(card: card, hijriDateKey: hijriDateKey))
    }

    func markAutoEnabled(_ card: TodayCardKind, for hijriDateKey: String) {
        var updated = storedKeys
        updated.insert(storageValue(card: card, hijriDateKey: hijriDateKey))
        defaults.set(Array(updated), forKey: storageKey)
    }

    private var storedKeys: Set<String> {
        Set(defaults.stringArray(forKey: storageKey) ?? [])
    }

    private func storageValue(card: TodayCardKind, hijriDateKey: String) -> String {
        "\(card.rawValue)|\(hijriDateKey)"
    }
}
