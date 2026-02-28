import Foundation

struct AppSettings: Codable, Equatable {
    var isConfigured: Bool
    var isEnabled: Bool
    var baseWakeOffsetMinutes: Int
    var reminderEnabledGlobal: Bool
    var reminderMinutesBeforeFajrGlobal: Int
    var atFajrEnabledGlobal: Bool
    var atFajrSoundSelectionGlobal: SoundChoice
    var snoozeEnabled: Bool
    var snoozeMinutes: Int
    var label: String
    var calculationMethod: CalculationMethod
    var fajrAdjustmentMinutes: Int
    var schedulePreviewDays: Int
    var locationMode: LocationMode
    var fixedLocation: FixedLocation?
    var lastScheduledDate: Date?
    var lastSchedulingMode: SchedulingMode

    var ramadanModeEnabled: Bool
    var selectedRamadanProfile: RamadanProfile
    var ramadanStartAdjustmentDays: Int
    var ramadanEndAdjustmentDays: Int
    var weekendBoostEnabled: Bool
    var weekendBoostMinutes: Int
    var last10Enabled: Bool
    var last10BoostMinutes: Int
    var lqEnabled: Bool
    var lqBoostMinutes: Int
    var lqNightNumbers: Set<Int>
    var lqSpecificDateKey: String?
    var perDayExceptions: [String: DayException]
    var perDayOverrideOffsets: [String: Int]

    static let `default` = AppSettings(
        isConfigured: false,
        isEnabled: false,
        baseWakeOffsetMinutes: 30,
        reminderEnabledGlobal: false,
        reminderMinutesBeforeFajrGlobal: 10,
        atFajrEnabledGlobal: false,
        atFajrSoundSelectionGlobal: .adhanSoft,
        snoozeEnabled: true,
        snoozeMinutes: 5,
        label: "Suhoor",
        calculationMethod: CalculationMethod.defaultForTimeZone(TimeZone.current),
        fajrAdjustmentMinutes: 0,
        schedulePreviewDays: 14,
        locationMode: .auto,
        fixedLocation: nil,
        lastScheduledDate: nil,
        lastSchedulingMode: .none,
        ramadanModeEnabled: false,
        selectedRamadanProfile: .ramadan2026,
        ramadanStartAdjustmentDays: 0,
        ramadanEndAdjustmentDays: 0,
        weekendBoostEnabled: false,
        weekendBoostMinutes: 15,
        last10Enabled: false,
        last10BoostMinutes: 30,
        lqEnabled: false,
        lqBoostMinutes: 60,
        lqNightNumbers: [27],
        lqSpecificDateKey: nil,
        perDayExceptions: [:],
        perDayOverrideOffsets: [:]
    )
}

extension AppSettings {
    enum CodingKeys: String, CodingKey {
        case isConfigured
        case isEnabled
        case baseWakeOffsetMinutes
        case reminderEnabledGlobal
        case reminderMinutesBeforeFajrGlobal
        case atFajrEnabledGlobal
        case atFajrSoundSelectionGlobal
        case reminderEnabled
        case reminderMinutes
        case boundaryEnabled
        case soundChoice
        case label
        case calculationMethod
        case fajrAdjustmentMinutes
        case schedulePreviewDays
        case locationMode
        case fixedLocation
        case lastScheduledDate
        case lastSchedulingMode
        case snoozeEnabled
        case snoozeMinutes
        case ramadanModeEnabled
        case selectedRamadanProfile
        case ramadanStartAdjustmentDays
        case ramadanEndAdjustmentDays
        case weekendBoostEnabled
        case weekendBoostMinutes
        case last10Enabled
        case last10BoostMinutes
        case lqEnabled
        case lqBoostMinutes
        case lqNightNumbers
        case lqSpecificDateKey
        case perDayExceptions
        case perDayOverrideOffsets

        case hasCompletedOnboarding
        case alarmEnabled
        case offsetPreset
        case customOffsetMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isConfigured = try container.decodeIfPresent(Bool.self, forKey: .isConfigured)
            ?? container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
            ?? false
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
            ?? container.decodeIfPresent(Bool.self, forKey: .alarmEnabled)
            ?? false

        if let storedBase = try container.decodeIfPresent(Int.self, forKey: .baseWakeOffsetMinutes) {
            baseWakeOffsetMinutes = storedBase
        } else if let legacyPreset = try container.decodeIfPresent(OffsetPreset.self, forKey: .offsetPreset) {
            if legacyPreset == .custom {
                baseWakeOffsetMinutes = try container.decodeIfPresent(Int.self, forKey: .customOffsetMinutes) ?? legacyPreset.minutes
            } else {
                baseWakeOffsetMinutes = legacyPreset.minutes
            }
        } else {
            baseWakeOffsetMinutes = 30
        }

        let legacyReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled)
        let legacyReminderMinutes = try container.decodeIfPresent(Int.self, forKey: .reminderMinutes)
        let legacyBoundaryEnabled = try container.decodeIfPresent(Bool.self, forKey: .boundaryEnabled)
        let legacySoundChoice = try container.decodeIfPresent(SoundChoice.self, forKey: .soundChoice)

        reminderEnabledGlobal = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabledGlobal)
            ?? legacyReminderEnabled
            ?? false
        reminderMinutesBeforeFajrGlobal = try container.decodeIfPresent(Int.self, forKey: .reminderMinutesBeforeFajrGlobal)
            ?? legacyReminderMinutes
            ?? 10
        atFajrEnabledGlobal = try container.decodeIfPresent(Bool.self, forKey: .atFajrEnabledGlobal)
            ?? legacyBoundaryEnabled
            ?? false
        atFajrSoundSelectionGlobal = try container.decodeIfPresent(SoundChoice.self, forKey: .atFajrSoundSelectionGlobal)
            ?? legacySoundChoice
            ?? .adhanSoft
        snoozeEnabled = try container.decodeIfPresent(Bool.self, forKey: .snoozeEnabled) ?? true
        snoozeMinutes = try container.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 5
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? "Suhoor"
        calculationMethod = try container.decodeIfPresent(CalculationMethod.self, forKey: .calculationMethod)
            ?? CalculationMethod.defaultForTimeZone(TimeZone.current)
        fajrAdjustmentMinutes = try container.decodeIfPresent(Int.self, forKey: .fajrAdjustmentMinutes) ?? 0
        schedulePreviewDays = try container.decodeIfPresent(Int.self, forKey: .schedulePreviewDays) ?? 14
        locationMode = try container.decodeIfPresent(LocationMode.self, forKey: .locationMode) ?? .auto
        fixedLocation = try container.decodeIfPresent(FixedLocation.self, forKey: .fixedLocation)
        lastScheduledDate = try container.decodeIfPresent(Date.self, forKey: .lastScheduledDate)
        lastSchedulingMode = try container.decodeIfPresent(SchedulingMode.self, forKey: .lastSchedulingMode) ?? .none

        ramadanModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .ramadanModeEnabled) ?? false
        selectedRamadanProfile = try container.decodeIfPresent(RamadanProfile.self, forKey: .selectedRamadanProfile) ?? .ramadan2026
        ramadanStartAdjustmentDays = try container.decodeIfPresent(Int.self, forKey: .ramadanStartAdjustmentDays) ?? 0
        ramadanEndAdjustmentDays = try container.decodeIfPresent(Int.self, forKey: .ramadanEndAdjustmentDays) ?? 0
        weekendBoostEnabled = try container.decodeIfPresent(Bool.self, forKey: .weekendBoostEnabled) ?? false
        weekendBoostMinutes = try container.decodeIfPresent(Int.self, forKey: .weekendBoostMinutes) ?? 15
        last10Enabled = try container.decodeIfPresent(Bool.self, forKey: .last10Enabled) ?? false
        last10BoostMinutes = try container.decodeIfPresent(Int.self, forKey: .last10BoostMinutes) ?? 30
        lqEnabled = try container.decodeIfPresent(Bool.self, forKey: .lqEnabled) ?? false
        lqBoostMinutes = try container.decodeIfPresent(Int.self, forKey: .lqBoostMinutes) ?? 60
        lqNightNumbers = try container.decodeIfPresent(Set<Int>.self, forKey: .lqNightNumbers) ?? [27]
        lqSpecificDateKey = try container.decodeIfPresent(String.self, forKey: .lqSpecificDateKey)
        perDayExceptions = try container.decodeIfPresent([String: DayException].self, forKey: .perDayExceptions) ?? [:]
        perDayOverrideOffsets = try container.decodeIfPresent([String: Int].self, forKey: .perDayOverrideOffsets) ?? [:]
        if perDayExceptions.isEmpty, !perDayOverrideOffsets.isEmpty {
            perDayExceptions = perDayOverrideOffsets.mapValues {
                DayException(
                    disabledForDay: false,
                    wakeOffsetOverrideMinutes: $0,
                    reminderEnabledOverride: nil,
                    atFajrEnabledOverride: nil,
                    reminderMinutesOverride: nil,
                    atFajrSoundOverride: nil
                )
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isConfigured, forKey: .isConfigured)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(baseWakeOffsetMinutes, forKey: .baseWakeOffsetMinutes)
        try container.encode(reminderEnabledGlobal, forKey: .reminderEnabledGlobal)
        try container.encode(reminderMinutesBeforeFajrGlobal, forKey: .reminderMinutesBeforeFajrGlobal)
        try container.encode(atFajrEnabledGlobal, forKey: .atFajrEnabledGlobal)
        try container.encode(atFajrSoundSelectionGlobal, forKey: .atFajrSoundSelectionGlobal)
        try container.encode(snoozeEnabled, forKey: .snoozeEnabled)
        try container.encode(snoozeMinutes, forKey: .snoozeMinutes)
        try container.encode(label, forKey: .label)
        try container.encode(calculationMethod, forKey: .calculationMethod)
        try container.encode(fajrAdjustmentMinutes, forKey: .fajrAdjustmentMinutes)
        try container.encode(schedulePreviewDays, forKey: .schedulePreviewDays)
        try container.encode(locationMode, forKey: .locationMode)
        try container.encodeIfPresent(fixedLocation, forKey: .fixedLocation)
        try container.encodeIfPresent(lastScheduledDate, forKey: .lastScheduledDate)
        try container.encode(lastSchedulingMode, forKey: .lastSchedulingMode)
        try container.encode(ramadanModeEnabled, forKey: .ramadanModeEnabled)
        try container.encode(selectedRamadanProfile, forKey: .selectedRamadanProfile)
        try container.encode(ramadanStartAdjustmentDays, forKey: .ramadanStartAdjustmentDays)
        try container.encode(ramadanEndAdjustmentDays, forKey: .ramadanEndAdjustmentDays)
        try container.encode(weekendBoostEnabled, forKey: .weekendBoostEnabled)
        try container.encode(weekendBoostMinutes, forKey: .weekendBoostMinutes)
        try container.encode(last10Enabled, forKey: .last10Enabled)
        try container.encode(last10BoostMinutes, forKey: .last10BoostMinutes)
        try container.encode(lqEnabled, forKey: .lqEnabled)
        try container.encode(lqBoostMinutes, forKey: .lqBoostMinutes)
        try container.encode(lqNightNumbers, forKey: .lqNightNumbers)
        try container.encodeIfPresent(lqSpecificDateKey, forKey: .lqSpecificDateKey)
        try container.encode(perDayExceptions, forKey: .perDayExceptions)
        try container.encode(perDayOverrideOffsets, forKey: .perDayOverrideOffsets)
    }
}

enum OffsetPreset: String, Codable, CaseIterable, Identifiable {
    case minutes15
    case minutes30
    case minutes45
    case minutes60
    case minutes90
    case custom

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .minutes15: return 15
        case .minutes30: return 30
        case .minutes45: return 45
        case .minutes60: return 60
        case .minutes90: return 90
        case .custom: return 30
        }
    }

    var label: String {
        switch self {
        case .minutes15: return "15"
        case .minutes30: return "30"
        case .minutes45: return "45"
        case .minutes60: return "60"
        case .minutes90: return "90"
        case .custom: return "Custom"
        }
    }
}

enum SoundChoice: String, Codable, CaseIterable, Identifiable {
    case systemDefault
    case adhanSoft

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .systemDefault: return "Default"
        case .adhanSoft: return "Adhan"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "systemDefault"
        if rawValue == "defaultSound" {
            self = .systemDefault
        } else {
            self = SoundChoice(rawValue: rawValue) ?? .systemDefault
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum SchedulingMode: String, Codable {
    case alarmKit
    case notifications
    case none
}

enum LocationMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case fixed

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct FixedLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct DayException: Codable, Equatable {
    var disabledForDay: Bool
    var wakeOffsetOverrideMinutes: Int?
    var reminderEnabledOverride: Bool?
    var atFajrEnabledOverride: Bool?
    var reminderMinutesOverride: Int?
    var atFajrSoundOverride: SoundChoice?
}

extension AppSettings {
    var hasAnyReminderEnabled: Bool {
        if reminderEnabledGlobal { return true }
        return perDayExceptions.values.contains { $0.reminderEnabledOverride == true }
    }

    var hasAnyAtFajrEnabled: Bool {
        if atFajrEnabledGlobal { return true }
        return perDayExceptions.values.contains { $0.atFajrEnabledOverride == true }
    }

    var hasAnyAtFajrNonDefaultSound: Bool {
        if atFajrEnabledGlobal, atFajrSoundSelectionGlobal != .systemDefault { return true }
        return perDayExceptions.values.contains { exception in
            if let override = exception.atFajrSoundOverride {
                return override != .systemDefault
            }
            return false
        }
    }

    func requiresReschedule(comparedTo other: AppSettings) -> Bool {
        normalizedForSchedulingComparison() != other.normalizedForSchedulingComparison()
    }

    private func normalizedForSchedulingComparison() -> AppSettings {
        var copy = self
        copy.lastScheduledDate = nil
        copy.lastSchedulingMode = .none
        return copy
    }
}
