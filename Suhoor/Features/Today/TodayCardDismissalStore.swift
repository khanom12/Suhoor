import Foundation
import Combine

final class TodayCardDismissalStore: ObservableObject {
    @Published private(set) var revision: Int = 0

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.TodayCardDismissals"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func dismiss(_ warning: FastWarning, on date: Date, timeZone: TimeZone = .current) {
        var dismissals = storedDismissals()
        dismissals[warning.rawValue] = DateHelpers.dayIdentifier(
            for: DateHelpers.startOfDay(date, in: timeZone),
            timeZone: timeZone
        )
        persist(dismissals)
    }

    func isDismissed(_ warning: FastWarning, on date: Date, timeZone: TimeZone = .current) -> Bool {
        storedDismissals()[warning.rawValue] == DateHelpers.dayIdentifier(
            for: DateHelpers.startOfDay(date, in: timeZone),
            timeZone: timeZone
        )
    }

    private func storedDismissals() -> [String: String] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func persist(_ dismissals: [String: String]) {
        guard let data = try? JSONEncoder().encode(dismissals) else { return }
        defaults.set(data, forKey: storageKey)
        revision += 1
    }
}
