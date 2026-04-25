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

    private let defaults: UserDefaults
    private let storageKey = "suhoor.alarmKitTestSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = Self.load(storageKey: storageKey, defaults: defaults) ?? .default
    }

    func reset() {
        settings = .default
    }

    private static func load(storageKey: String, defaults: UserDefaults) -> AlarmKitTestSettings? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(AlarmKitTestSettings.self, from: data)
        } catch {
            if let defaultData = try? JSONEncoder().encode(AlarmKitTestSettings.default) {
                defaults.set(defaultData, forKey: storageKey)
            } else {
                defaults.removeObject(forKey: storageKey)
            }
            return .default
        }
    }

    private func save(_ settings: AlarmKitTestSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
