import Foundation

struct AppSettings: Codable, Equatable, Sendable {
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
    var maghribAdjustmentMinutes: Int
    var locationMode: LocationMode
    var fixedLocation: FixedLocation?
    var lastScheduledDate: Date?
    var lastSchedulingMode: SchedulingMode
    var hijriSpecialDaySettings: HijriSpecialDaySettings

    static let `default` = AppSettings(
        isConfigured: false,
        isEnabled: true,
        baseWakeOffsetMinutes: 30,
        reminderEnabledGlobal: true,
        reminderMinutesBeforeFajrGlobal: 10,
        atFajrEnabledGlobal: true,
        atFajrSoundSelectionGlobal: .adhanSoft,
        snoozeEnabled: true,
        snoozeMinutes: 5,
        label: "Suhoor",
        calculationMethod: CalculationMethod.defaultForTimeZone(TimeZone.current),
        fajrAdjustmentMinutes: 0,
        maghribAdjustmentMinutes: 0,
        locationMode: .auto,
        fixedLocation: nil,
        lastScheduledDate: nil,
        lastSchedulingMode: .none,
        hijriSpecialDaySettings: .default
    )
}

struct HijriSpecialDaySettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var ramadanDailyEnabled: Bool
    var whiteDaysEnabled: Bool
    var ashuraEnabled: Bool
    var arafahEnabled: Bool
    var eidAlFitrEnabled: Bool
    var eidAlAdhaEnabled: Bool

    static let `default` = HijriSpecialDaySettings(
        isEnabled: false,
        ramadanDailyEnabled: false,
        whiteDaysEnabled: false,
        ashuraEnabled: false,
        arafahEnabled: false,
        eidAlFitrEnabled: false,
        eidAlAdhaEnabled: false
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
        case maghribAdjustmentMinutes
        case locationMode
        case fixedLocation
        case lastScheduledDate
        case lastSchedulingMode
        case hijriSpecialDaySettings
        case snoozeEnabled
        case snoozeMinutes

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
        maghribAdjustmentMinutes = try container.decodeIfPresent(Int.self, forKey: .maghribAdjustmentMinutes) ?? 0
        locationMode = try container.decodeIfPresent(LocationMode.self, forKey: .locationMode) ?? .auto
        fixedLocation = try container.decodeIfPresent(FixedLocation.self, forKey: .fixedLocation)
        lastScheduledDate = try container.decodeIfPresent(Date.self, forKey: .lastScheduledDate)
        lastSchedulingMode = try container.decodeIfPresent(SchedulingMode.self, forKey: .lastSchedulingMode) ?? .none
        hijriSpecialDaySettings = try container.decodeIfPresent(HijriSpecialDaySettings.self, forKey: .hijriSpecialDaySettings) ?? .default
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
        try container.encode(maghribAdjustmentMinutes, forKey: .maghribAdjustmentMinutes)
        try container.encode(locationMode, forKey: .locationMode)
        try container.encodeIfPresent(fixedLocation, forKey: .fixedLocation)
        try container.encodeIfPresent(lastScheduledDate, forKey: .lastScheduledDate)
        try container.encode(lastSchedulingMode, forKey: .lastSchedulingMode)
        try container.encode(hijriSpecialDaySettings, forKey: .hijriSpecialDaySettings)
    }
}

enum OffsetPreset: String, Codable, CaseIterable, Identifiable, Sendable {
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

enum SoundChoice: String, Codable, CaseIterable, Identifiable, Sendable {
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

enum SchedulingMode: String, Codable, Sendable {
    case alarmKit
    case notifications
    case none
}

enum LocationMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto
    case fixed

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct FixedLocation: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

extension AppSettings {
    var hasAnyReminderEnabled: Bool {
        reminderEnabledGlobal
    }

    var hasAnyAtFajrEnabled: Bool {
        atFajrEnabledGlobal
    }

    var hasAnyIftarEnabled: Bool {
        false
    }

    var hasAnyAtFajrNonDefaultSound: Bool {
        atFajrEnabledGlobal && atFajrSoundSelectionGlobal != .systemDefault
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

    func withSuhoorEnabled(_ isEnabled: Bool) -> AppSettings {
        var copy = self
        copy.isEnabled = isEnabled
        return copy
    }
}
