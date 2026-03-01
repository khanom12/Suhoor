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

enum ReminderTimeMode: String, Codable, CaseIterable, Identifiable {
    case beforeFajr
    case fixedTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beforeFajr: return "Before Fajr"
        case .fixedTime: return "Fixed time"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if rawValue == "afterSuhoorPlusMinutes" {
            self = .beforeFajr
        } else {
            self = ReminderTimeMode(rawValue: rawValue) ?? .beforeFajr
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct DefaultAlarmConfig: Codable, Equatable {
    var suhoorEnabledDefault: Bool
    var reminderEnabledDefault: Bool
    var fajrEnabledDefault: Bool
    var defaultSuhoorTimeMode: SuhoorTimeMode
    var defaultSuhoorOffsetMinutes: Int
    var defaultReminderTimeMode: ReminderTimeMode
    var defaultReminderMinutesBeforeFajr: Int
    var defaultReminderFixedTimeMinutes: Int
    var activationMode: AlarmActivationMode
    var activeStartDate: Date?
    var activeEndDate: Date?
    var scheduleWindowDays: Int
    var extraOneOffDates: Set<String>

    init(
        suhoorEnabledDefault: Bool,
        reminderEnabledDefault: Bool,
        fajrEnabledDefault: Bool,
        defaultSuhoorTimeMode: SuhoorTimeMode,
        defaultSuhoorOffsetMinutes: Int,
        defaultReminderTimeMode: ReminderTimeMode,
        defaultReminderMinutesBeforeFajr: Int,
        defaultReminderFixedTimeMinutes: Int,
        activationMode: AlarmActivationMode,
        activeStartDate: Date?,
        activeEndDate: Date?,
        scheduleWindowDays: Int,
        extraOneOffDates: Set<String> = []
    ) {
        self.suhoorEnabledDefault = suhoorEnabledDefault
        self.reminderEnabledDefault = reminderEnabledDefault
        self.fajrEnabledDefault = fajrEnabledDefault
        self.defaultSuhoorTimeMode = defaultSuhoorTimeMode
        self.defaultSuhoorOffsetMinutes = defaultSuhoorOffsetMinutes
        self.defaultReminderTimeMode = defaultReminderTimeMode
        self.defaultReminderMinutesBeforeFajr = defaultReminderMinutesBeforeFajr
        self.defaultReminderFixedTimeMinutes = defaultReminderFixedTimeMinutes
        self.activationMode = activationMode
        self.activeStartDate = activeStartDate
        self.activeEndDate = activeEndDate
        self.scheduleWindowDays = scheduleWindowDays
        self.extraOneOffDates = extraOneOffDates
    }

    static let `default` = DefaultAlarmConfig(
        suhoorEnabledDefault: false,
        reminderEnabledDefault: false,
        fajrEnabledDefault: false,
        defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
        defaultSuhoorOffsetMinutes: 30,
        defaultReminderTimeMode: .beforeFajr,
        defaultReminderMinutesBeforeFajr: 10,
        defaultReminderFixedTimeMinutes: 0,
        activationMode: .alwaysOn,
        activeStartDate: nil,
        activeEndDate: nil,
        scheduleWindowDays: 14,
        extraOneOffDates: []
    )

    enum CodingKeys: String, CodingKey {
        case suhoorEnabledDefault
        case reminderEnabledDefault
        case fajrEnabledDefault
        case defaultSuhoorTimeMode
        case defaultSuhoorOffsetMinutes
        case defaultReminderTimeMode
        case defaultReminderMinutesBeforeFajr
        case defaultReminderFixedTimeMinutes
        case activationMode
        case activeStartDate
        case activeEndDate
        case scheduleWindowDays
        case extraOneOffDates
        case extraActiveDates
        case legacyDefaultReminderOffsetMinutes = "defaultReminderOffsetMinutes"
        case legacyDefaultReminderMinutesAfterSuhoor = "defaultReminderMinutesAfterSuhoor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suhoorEnabledDefault = try container.decode(Bool.self, forKey: .suhoorEnabledDefault)
        reminderEnabledDefault = try container.decode(Bool.self, forKey: .reminderEnabledDefault)
        fajrEnabledDefault = try container.decode(Bool.self, forKey: .fajrEnabledDefault)
        defaultSuhoorTimeMode = try container.decodeIfPresent(SuhoorTimeMode.self, forKey: .defaultSuhoorTimeMode)
            ?? .relativeToFajrMinusMinutes
        defaultSuhoorOffsetMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultSuhoorOffsetMinutes) ?? 30
        defaultReminderTimeMode = try container.decodeIfPresent(ReminderTimeMode.self, forKey: .defaultReminderTimeMode)
            ?? .beforeFajr
        let legacyMinutes = try container.decodeIfPresent(Int.self, forKey: .legacyDefaultReminderMinutesAfterSuhoor)
            ?? container.decodeIfPresent(Int.self, forKey: .legacyDefaultReminderOffsetMinutes)
        let decodedMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultReminderMinutesBeforeFajr)
            ?? legacyMinutes
            ?? 10
        defaultReminderMinutesBeforeFajr = max(decodedMinutes, 10)
        defaultReminderFixedTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultReminderFixedTimeMinutes) ?? 0
        activationMode = try container.decodeIfPresent(AlarmActivationMode.self, forKey: .activationMode) ?? .alwaysOn
        activeStartDate = try container.decodeIfPresent(Date.self, forKey: .activeStartDate)
        activeEndDate = try container.decodeIfPresent(Date.self, forKey: .activeEndDate)
        scheduleWindowDays = try container.decodeIfPresent(Int.self, forKey: .scheduleWindowDays) ?? 14
        extraOneOffDates = try container.decodeIfPresent(Set<String>.self, forKey: .extraOneOffDates)
            ?? container.decodeIfPresent(Set<String>.self, forKey: .extraActiveDates)
            ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(suhoorEnabledDefault, forKey: .suhoorEnabledDefault)
        try container.encode(reminderEnabledDefault, forKey: .reminderEnabledDefault)
        try container.encode(fajrEnabledDefault, forKey: .fajrEnabledDefault)
        try container.encode(defaultSuhoorTimeMode, forKey: .defaultSuhoorTimeMode)
        try container.encode(defaultSuhoorOffsetMinutes, forKey: .defaultSuhoorOffsetMinutes)
        try container.encode(defaultReminderTimeMode, forKey: .defaultReminderTimeMode)
        try container.encode(defaultReminderMinutesBeforeFajr, forKey: .defaultReminderMinutesBeforeFajr)
        try container.encode(defaultReminderFixedTimeMinutes, forKey: .defaultReminderFixedTimeMinutes)
        try container.encode(activationMode, forKey: .activationMode)
        try container.encodeIfPresent(activeStartDate, forKey: .activeStartDate)
        try container.encodeIfPresent(activeEndDate, forKey: .activeEndDate)
        try container.encode(scheduleWindowDays, forKey: .scheduleWindowDays)
        try container.encode(extraOneOffDates, forKey: .extraOneOffDates)
    }
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
    let reminderTimeMode: ReminderTimeMode
    let reminderMinutesBeforeFajr: Int
    let reminderFixedTimeMinutes: Int
    let suhoorTimeOverrideMinutesFromMidnight: Int?
    let reminderTimeOverrideMinutesFromMidnight: Int?
    let fajrSoundChoice: SoundChoice
    let hasOverrides: Bool

    var hasAnyEnabled: Bool {
        suhoorEnabled || reminderEnabled || fajrEnabled
    }
}

enum PrimaryDisplayKind {
    case suhoor
    case reminder
    case fajr
}

struct PrimaryDisplay {
    let time: Date
    let kind: PrimaryDisplayKind
}

extension EffectiveDailyConfig {
    func primaryDisplay(schedule: DaySchedule) -> PrimaryDisplay? {
        if suhoorEnabled {
            return PrimaryDisplay(time: schedule.wakeDate, kind: .suhoor)
        }
        if reminderEnabled, let reminderDate = schedule.reminderDate {
            return PrimaryDisplay(time: reminderDate, kind: .reminder)
        }
        if fajrEnabled {
            return PrimaryDisplay(time: schedule.fajrDate, kind: .fajr)
        }
        return nil
    }
}
