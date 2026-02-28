import Foundation
import Combine

struct AlarmKitTestSettings: Codable, Equatable {
    var isEnabled: Bool
    var suhoorOffsetSeconds: Int
    var reminderOffsetSeconds: Int
    var adhanOffsetSeconds: Int
    var testRunId: UUID?

    static let `default` = AlarmKitTestSettings(
        isEnabled: false,
        suhoorOffsetSeconds: 60,
        reminderOffsetSeconds: 120,
        adhanOffsetSeconds: 180,
        testRunId: nil
    )
}

final class AlarmKitTestSettingsStore: ObservableObject {
    @Published var settings: AlarmKitTestSettings {
        didSet { save(settings) }
    }

    private let storageKey = "suhoor.alarmKitTestSettings"

    init() {
        settings = Self.load(storageKey: storageKey) ?? .default
    }

    func reset() {
        settings = .default
    }

    private static func load(storageKey: String) -> AlarmKitTestSettings? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AlarmKitTestSettings.self, from: data)
    }

    private func save(_ settings: AlarmKitTestSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
