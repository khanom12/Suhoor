import Foundation

struct AlarmKitTestRunState: Codable, Equatable {
    let testRunId: UUID
    let baseNow: Date
    let suhoorDate: Date
    let reminderDate: Date
    let adhanDate: Date
}

final class AlarmKitTestRunStore {
    private let storageKey = "suhoor.alarmKitTestRun"

    func load() -> AlarmKitTestRunState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AlarmKitTestRunState.self, from: data)
    }

    func save(_ state: AlarmKitTestRunState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
