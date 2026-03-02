import Foundation
import SwiftUI
import Combine

final class SuhoorSettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            guard !isPersistenceSuspended else { return }
            saveSettings()
        }
    }

    private let settingsKey = "Suhoor.AppSettings"
    private let migrationKey = "Suhoor.AppSettingsMigrationVersion"
    private let defaults: UserDefaults
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.settings-store",
        delay: 0.2
    )
    private var isPersistenceSuspended = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
        performMigrationIfNeeded()
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
        let snapshot = settings
        persistence.schedule { [defaults, settingsKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: settingsKey)
        }
    }

    private func performMigrationIfNeeded() {
        let currentVersion = defaults.integer(forKey: migrationKey)
        guard currentVersion < 1 else { return }

        var migrated = settings
        migrated.isEnabled = true
        migrated.reminderEnabledGlobal = true
        migrated.atFajrEnabledGlobal = true

        isPersistenceSuspended = true
        settings = migrated
        isPersistenceSuspended = false
        saveSettings()
        defaults.set(1, forKey: migrationKey)
    }

    func reset() {
        isPersistenceSuspended = true
        settings = .default
        isPersistenceSuspended = false
        persistence.cancelPending()
        defaults.removeObject(forKey: settingsKey)
        defaults.removeObject(forKey: migrationKey)
    }
}
