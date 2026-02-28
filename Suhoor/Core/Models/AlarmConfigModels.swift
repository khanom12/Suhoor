import Foundation

enum AlarmActivationMode: String, Codable, CaseIterable, Identifiable {
    case alwaysOn
    case dateRange

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alwaysOn: return "Always On"
        case .dateRange: return "Date Range"
        }
    }
}

enum SuhoorTimeMode: String, Codable, CaseIterable, Identifiable {
    case relativeToFajrMinusMinutes
    case fixedTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relativeToFajrMinusMinutes: return "Before Fajr"
        case .fixedTime: return "Fixed time"
        }
    }
}

struct DefaultAlarmConfig: Codable, Equatable {
    var suhoorEnabledDefault: Bool
    var reminderEnabledDefault: Bool
    var fajrEnabledDefault: Bool
    var defaultSuhoorTimeMode: SuhoorTimeMode
    var defaultSuhoorOffsetMinutes: Int
    var defaultReminderOffsetMinutes: Int
    var activationMode: AlarmActivationMode
    var activeStartDate: Date?
    var activeEndDate: Date?
    var scheduleWindowDays: Int

    static let `default` = DefaultAlarmConfig(
        suhoorEnabledDefault: false,
        reminderEnabledDefault: false,
        fajrEnabledDefault: false,
        defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
        defaultSuhoorOffsetMinutes: 30,
        defaultReminderOffsetMinutes: 10,
        activationMode: .alwaysOn,
        activeStartDate: nil,
        activeEndDate: nil,
        scheduleWindowDays: 14
    )
}

struct DailyAlarmOverride: Codable, Equatable, Identifiable {
    let dateKey: String
    let date: Date
    var skipDay: Bool
    var suhoorEnabled: Bool?
    var reminderEnabled: Bool?
    var fajrEnabled: Bool?
    var suhoorOffsetOverrideMinutes: Int?
    var reminderOffsetOverrideMinutes: Int?
    var suhoorTimeOverrideMinutesFromMidnight: Int?
    var reminderTimeOverrideMinutesFromMidnight: Int?
    var fajrSoundOverride: SoundChoice?
    var notes: String?

    var id: String { dateKey }

    init(date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalized = calendar.startOfDay(for: date)
        self.date = normalized
        self.dateKey = DateHelpers.dayIdentifier(for: normalized, timeZone: timeZone)
        self.skipDay = false
        self.suhoorEnabled = nil
        self.reminderEnabled = nil
        self.fajrEnabled = nil
        self.suhoorOffsetOverrideMinutes = nil
        self.reminderOffsetOverrideMinutes = nil
        self.suhoorTimeOverrideMinutesFromMidnight = nil
        self.reminderTimeOverrideMinutesFromMidnight = nil
        self.fajrSoundOverride = nil
        self.notes = nil
    }

    var hasOverrides: Bool {
        if skipDay { return true }
        if suhoorEnabled != nil { return true }
        if reminderEnabled != nil { return true }
        if fajrEnabled != nil { return true }
        if suhoorOffsetOverrideMinutes != nil { return true }
        if reminderOffsetOverrideMinutes != nil { return true }
        if suhoorTimeOverrideMinutesFromMidnight != nil { return true }
        if reminderTimeOverrideMinutesFromMidnight != nil { return true }
        if fajrSoundOverride != nil { return true }
        if let notes, !notes.isEmpty { return true }
        return false
    }
}

struct EffectiveDailyConfig: Equatable {
    let date: Date
    let defaultsActive: Bool
    let skipDay: Bool
    let suhoorEnabled: Bool
    let reminderEnabled: Bool
    let fajrEnabled: Bool
    let suhoorTimeMode: SuhoorTimeMode
    let suhoorOffsetMinutes: Int
    let reminderOffsetMinutes: Int
    let suhoorTimeOverrideMinutesFromMidnight: Int?
    let reminderTimeOverrideMinutesFromMidnight: Int?
    let fajrSoundChoice: SoundChoice
    let hasOverrides: Bool

    var hasAnyEnabled: Bool {
        suhoorEnabled || reminderEnabled || fajrEnabled
    }
}
