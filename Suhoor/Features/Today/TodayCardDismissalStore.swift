import Foundation
import Combine

final class TodayCardDismissalStore: ObservableObject {
    private struct StorageState: Codable {
        var warnings: [String: String]
        var supportCards: [String: String]
    }

    @Published private(set) var revision: Int = 0

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.TodayCardDismissals"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func dismiss(_ warning: FastWarning, on date: Date, timeZone: TimeZone = .current) {
        var state = storedState()
        state.warnings[warning.rawValue] = dateKey(for: date, timeZone: timeZone)
        persist(state)
    }

    func isDismissed(_ warning: FastWarning, on date: Date, timeZone: TimeZone = .current) -> Bool {
        storedState().warnings[warning.rawValue] == dateKey(for: date, timeZone: timeZone)
    }

    func dismissSupportCard(_ key: String, on date: Date, timeZone: TimeZone = .current) {
        var state = storedState()
        state.supportCards[key] = dateKey(for: date, timeZone: timeZone)
        persist(state)
    }

    func isSupportCardDismissed(_ key: String, on date: Date, timeZone: TimeZone = .current) -> Bool {
        storedState().supportCards[key] == dateKey(for: date, timeZone: timeZone)
    }

    private func storedState() -> StorageState {
        guard let data = defaults.data(forKey: storageKey) else {
            return StorageState(warnings: [:], supportCards: [:])
        }

        if let decoded = try? JSONDecoder().decode(StorageState.self, from: data) {
            return decoded
        }

        if let legacyWarnings = try? JSONDecoder().decode([String: String].self, from: data) {
            return StorageState(warnings: legacyWarnings, supportCards: [:])
        }

        return StorageState(warnings: [:], supportCards: [:])
    }

    private func persist(_ state: StorageState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
        revision += 1
    }

    private func dateKey(for date: Date, timeZone: TimeZone) -> String {
        DateHelpers.dayIdentifier(
            for: DateHelpers.startOfDay(date, in: timeZone),
            timeZone: timeZone
        )
    }
}
