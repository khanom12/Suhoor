import Foundation
import Combine

@MainActor
final class AlarmConfigStore: ObservableObject {
    @Published var defaults: DefaultAlarmConfig {
        didSet { persistDefaults() }
    }

    @Published var overridesByDay: [String: DailyAlarmOverride] {
        didSet { persistOverrides() }
    }

    private let defaultsKey = "Suhoor.DefaultAlarmConfig"
    private let overridesKey = "Suhoor.DailyAlarmOverrides"
    private let migrationKey = "Suhoor.AlarmConfigMigrationVersion"
    private let defaultsStore: UserDefaults

    init(defaultsStore: UserDefaults = .standard, legacySettings: AppSettings? = nil) {
        self.defaultsStore = defaultsStore

        if let data = defaultsStore.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(DefaultAlarmConfig.self, from: data) {
            self.defaults = decoded
        } else {
            self.defaults = .default
        }

        if let data = defaultsStore.data(forKey: overridesKey),
           let decoded = try? JSONDecoder().decode([String: DailyAlarmOverride].self, from: data) {
            self.overridesByDay = decoded
        } else {
            self.overridesByDay = [:]
        }

        performMigrationIfNeeded(legacySettings: legacySettings)
    }

    func override(for date: Date, timeZone: TimeZone = .current) -> DailyAlarmOverride? {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return overridesByDay[key]
    }

    func updateOverride(for date: Date, timeZone: TimeZone = .current, update: (inout DailyAlarmOverride) -> Void) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        var current = overridesByDay[key] ?? DailyAlarmOverride(date: date, timeZone: timeZone)
        update(&current)
        overridesByDay[key] = current
    }

    func removeOverride(for date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        overridesByDay.removeValue(forKey: key)
    }

    func isDefaultsActive(on date: Date, timeZone: TimeZone = .current) -> Bool {
        if isDeletedDate(on: date, timeZone: timeZone) { return false }
        switch defaults.activationMode {
        case .alwaysOn:
            return true
        case .dateRange:
            return isDateInActiveRange(on: date, timeZone: timeZone)
                || isExtraOneOffDate(on: date, timeZone: timeZone)
        }
    }

    func isWithinActiveRange(on date: Date, timeZone: TimeZone = .current) -> Bool {
        switch defaults.activationMode {
        case .alwaysOn:
            return true
        case .dateRange:
            guard let start = defaults.activeStartDate, let end = defaults.activeEndDate else {
                return false
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let target = calendar.startOfDay(for: date)
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            return target >= startDay && target <= endDay
        }
    }

    func isDateInActiveRange(on date: Date, timeZone: TimeZone = .current) -> Bool {
        guard defaults.activationMode == .dateRange else { return false }
        guard let start = defaults.activeStartDate, let end = defaults.activeEndDate else {
            return false
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let target = calendar.startOfDay(for: date)
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return target >= startDay && target <= endDay
    }

    func isExtraOneOffDate(on date: Date, timeZone: TimeZone = .current) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return defaults.extraOneOffDates.contains(key)
    }

    func addExtraOneOffDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        defaults.extraOneOffDates.insert(key)
        defaults.deletedDates.remove(key)
    }

    func removeExtraOneOffDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        defaults.extraOneOffDates.remove(key)
    }

    func isDeletedDate(on date: Date, timeZone: TimeZone = .current) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return defaults.deletedDates.contains(key)
    }

    func addDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        defaults.deletedDates.insert(key)
        defaults.extraOneOffDates.remove(key)
    }

    func removeDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        defaults.deletedDates.remove(key)
    }

    func effectiveConfig(for date: Date, ruleSummary: RuleSummary, settings: AppSettings, timeZone: TimeZone = .current) -> EffectiveDailyConfig {
        let defaultsActive = isDefaultsActive(on: date, timeZone: timeZone)
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let override = overridesByDay[key]
        let skipDay = override?.skipDay ?? false

        let baseSuhoorEnabled = defaultsActive ? defaults.suhoorEnabledDefault : false
        let baseReminderEnabled = defaultsActive ? defaults.reminderEnabledDefault : false
        let baseFajrEnabled = defaultsActive ? defaults.fajrEnabledDefault : false

        var suhoorEnabled = override?.suhoorEnabled ?? baseSuhoorEnabled
        var reminderEnabled = override?.reminderEnabled ?? baseReminderEnabled
        var fajrEnabled = override?.fajrEnabled ?? baseFajrEnabled

        let reminderOffset = override?.reminderOffsetOverrideMinutes ?? defaults.defaultReminderMinutesBeforeFajr
        let reminderTimeMode: ReminderTimeMode
        if override?.reminderTimeOverrideMinutesFromMidnight != nil {
            reminderTimeMode = .fixedTime
        } else if override?.reminderOffsetOverrideMinutes != nil {
            reminderTimeMode = .beforeFajr
        } else {
            reminderTimeMode = defaults.defaultReminderTimeMode
        }
        let suhoorOffset = ruleSummary.finalOffsetMinutes
        let suhoorTimeOverride = override?.suhoorTimeOverrideMinutesFromMidnight
        let reminderTimeOverride = override?.reminderTimeOverrideMinutesFromMidnight

        if skipDay || ruleSummary.disabledForDay {
            suhoorEnabled = false
            reminderEnabled = false
            fajrEnabled = false
        }

        let fajrSoundChoice = override?.fajrSoundOverride ?? settings.atFajrSoundSelectionGlobal
        let hasOverrides = override?.hasOverrides ?? false

        return EffectiveDailyConfig(
            date: date,
            defaultsActive: defaultsActive,
            skipDay: skipDay,
            suhoorEnabled: suhoorEnabled,
            reminderEnabled: reminderEnabled,
            fajrEnabled: fajrEnabled,
            suhoorTimeMode: defaults.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: suhoorOffset,
            reminderTimeMode: reminderTimeMode,
            reminderMinutesBeforeFajr: reminderOffset,
            reminderFixedTimeMinutes: defaults.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: suhoorTimeOverride,
            reminderTimeOverrideMinutesFromMidnight: reminderTimeOverride,
            fajrSoundChoice: fajrSoundChoice,
            hasOverrides: hasOverrides
        )
    }

    var hasAnyEnabledDefaults: Bool {
        defaults.suhoorEnabledDefault || defaults.reminderEnabledDefault || defaults.fajrEnabledDefault
    }

    func hasAnyEnabledOverride() -> Bool {
        overridesByDay.values.contains { override in
            if override.skipDay { return false }
            return override.suhoorEnabled == true
                || override.reminderEnabled == true
                || override.fajrEnabled == true
        }
    }

    private func performMigrationIfNeeded(legacySettings: AppSettings?) {
        let currentVersion = defaultsStore.integer(forKey: migrationKey)
        guard currentVersion < 1 else { return }
        guard let legacySettings else {
            defaultsStore.set(1, forKey: migrationKey)
            return
        }

        let hasStoredDefaults = defaultsStore.data(forKey: defaultsKey) != nil
        let hasStoredOverrides = defaultsStore.data(forKey: overridesKey) != nil
        guard !hasStoredDefaults && !hasStoredOverrides else {
            defaultsStore.set(1, forKey: migrationKey)
            return
        }

        defaults = DefaultAlarmConfig(
            suhoorEnabledDefault: legacySettings.isEnabled,
            reminderEnabledDefault: legacySettings.reminderEnabledGlobal,
            fajrEnabledDefault: legacySettings.atFajrEnabledGlobal,
            defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
            defaultSuhoorOffsetMinutes: legacySettings.baseWakeOffsetMinutes,
            defaultReminderTimeMode: .beforeFajr,
            defaultReminderMinutesBeforeFajr: max(legacySettings.reminderMinutesBeforeFajrGlobal, 10),
            defaultReminderFixedTimeMinutes: 0,
            activationMode: .alwaysOn,
            activeStartDate: nil,
            activeEndDate: nil,
            scheduleWindowDays: legacySettings.schedulePreviewDays
        )

        if !legacySettings.perDayExceptions.isEmpty {
            var migrated: [String: DailyAlarmOverride] = [:]
            for (key, exception) in legacySettings.perDayExceptions {
                guard let date = dateFromKey(key) else { continue }
                var override = DailyAlarmOverride(date: date)
                override.skipDay = exception.disabledForDay
                override.suhoorOffsetOverrideMinutes = exception.wakeOffsetOverrideMinutes
                override.reminderEnabled = exception.reminderEnabledOverride
                override.reminderOffsetOverrideMinutes = exception.reminderMinutesOverride
                override.fajrEnabled = exception.atFajrEnabledOverride
                override.fajrSoundOverride = exception.atFajrSoundOverride
                migrated[key] = override
            }
            overridesByDay = migrated
        }

        defaultsStore.set(1, forKey: migrationKey)
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func persistDefaults() {
        if let data = try? JSONEncoder().encode(defaults) {
            defaultsStore.set(data, forKey: defaultsKey)
        }
    }

    private func persistOverrides() {
        if let data = try? JSONEncoder().encode(overridesByDay) {
            defaultsStore.set(data, forKey: overridesKey)
        }
    }
}
