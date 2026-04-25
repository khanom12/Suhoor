import Foundation

struct AlarmKitTestRunState: Codable, Equatable {
    let testRunId: UUID
    let baseNow: Date
    let suhoorDate: Date
    let reminderDate: Date
    let adhanDate: Date
}

final class AlarmKitTestRunStore {
    private let defaults: UserDefaults
    private let storageKey = "suhoor.alarmKitTestRun"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AlarmKitTestRunState? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(AlarmKitTestRunState.self, from: data)
        } catch {
            defaults.removeObject(forKey: storageKey)
            return nil
        }
    }

    func save(_ state: AlarmKitTestRunState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
