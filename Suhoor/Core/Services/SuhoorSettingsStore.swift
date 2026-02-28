import Foundation
import SwiftUI
import Combine

final class SuhoorSettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    private let settingsKey = "Suhoor.AppSettings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    func update(_ updateBlock: (inout AppSettings) -> Void) {
        var draft = settings
        updateBlock(&draft)
        settings = draft
    }

    func set(_ newSettings: AppSettings) {
        settings = newSettings
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    func reset() {
        settings = .default
        defaults.removeObject(forKey: settingsKey)
    }
}
