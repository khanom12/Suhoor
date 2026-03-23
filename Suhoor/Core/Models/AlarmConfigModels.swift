import Foundation

enum AlarmActivationMode: String, Codable, CaseIterable, Identifiable, Sendable {
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

enum SuhoorTimeMode: String, Codable, CaseIterable, Identifiable, Sendable {
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

enum ReminderTimeMode: String, Codable, CaseIterable, Identifiable, Sendable {
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

enum IftarAudibleMode: String, Codable, Sendable {
    case none
    case alarm
    case adhan
}

struct IftarDeliverySelection: Codable, Equatable, Sendable {
    var notification: Bool
    var alarm: Bool
    var adhan: Bool

    static let notificationOnly = IftarDeliverySelection(notification: true, alarm: false, adhan: false)
    static let off = IftarDeliverySelection(notification: false, alarm: false, adhan: false)

    var includesNotification: Bool { normalized().notification }
    var isOff: Bool { !notification && !alarm && !adhan }

    var audibleMode: IftarAudibleMode {
        let normalized = normalized()
        if normalized.adhan {
            return .adhan
        }
        if normalized.alarm {
            return .alarm
        }
        return .none
    }

    func normalized() -> IftarDeliverySelection {
        // Keep the user's notification preference, but collapse duplicate audible intent to adhan precedence.
        IftarDeliverySelection(
            notification: notification,
            alarm: alarm && !adhan,
            adhan: adhan
        )
    }

    var summaryText: String {
        let normalized = normalized()
        var parts: [String] = []
        if normalized.notification {
            parts.append("Notification")
        }
        switch normalized.audibleMode {
        case .none:
            break
        case .alarm:
            parts.append("Alarm")
        case .adhan:
            parts.append("Adhan")
        }
        if parts.isEmpty {
            return "Off"
        }
        return parts.joined(separator: " + ")
    }
}

struct DefaultAlarmConfig: Codable, Equatable, Sendable {
    var suhoorEnabledDefault: Bool
    var reminderEnabledDefault: Bool
    var fajrEnabledDefault: Bool
    var iftarEnabledDefault: Bool
    var defaultWakeState: DefaultWakeState
    var defaultWakeAnchorType: WakeAnchorType
    var defaultWakeDeltaMinutes: Int
    var defaultLatestWakeCapMinutesFromMidnight: Int?
    var defaultSuhoorTimeMode: SuhoorTimeMode
    var defaultSuhoorOffsetMinutes: Int
    var defaultReminderTimeMode: ReminderTimeMode
    var defaultReminderMinutesBeforeFajr: Int
    var defaultReminderFixedTimeMinutes: Int
    var defaultIftarDelivery: IftarDeliverySelection
    var defaultIftarSoundChoice: SoundChoice
    var activationMode: AlarmActivationMode
    var activeStartDate: Date?
    var activeEndDate: Date?
    var scheduleWindowDays: Int
    var extraOneOffDates: Set<String>
    var deletedDates: Set<String>

    init(
        suhoorEnabledDefault: Bool,
        reminderEnabledDefault: Bool,
        fajrEnabledDefault: Bool,
        iftarEnabledDefault: Bool,
        defaultWakeState: DefaultWakeState,
        defaultWakeAnchorType: WakeAnchorType,
        defaultWakeDeltaMinutes: Int,
        defaultLatestWakeCapMinutesFromMidnight: Int?,
        defaultSuhoorTimeMode: SuhoorTimeMode,
        defaultSuhoorOffsetMinutes: Int,
        defaultReminderTimeMode: ReminderTimeMode,
        defaultReminderMinutesBeforeFajr: Int,
        defaultReminderFixedTimeMinutes: Int,
        defaultIftarDelivery: IftarDeliverySelection,
        defaultIftarSoundChoice: SoundChoice,
        activationMode: AlarmActivationMode,
        activeStartDate: Date?,
        activeEndDate: Date?,
        scheduleWindowDays: Int,
        extraOneOffDates: Set<String> = [],
        deletedDates: Set<String> = []
    ) {
        self.suhoorEnabledDefault = suhoorEnabledDefault
        self.reminderEnabledDefault = reminderEnabledDefault
        self.fajrEnabledDefault = fajrEnabledDefault
        self.iftarEnabledDefault = iftarEnabledDefault
        self.defaultWakeState = defaultWakeState
        self.defaultWakeAnchorType = defaultWakeAnchorType
        self.defaultWakeDeltaMinutes = max(0, defaultWakeDeltaMinutes)
        self.defaultLatestWakeCapMinutesFromMidnight = defaultLatestWakeCapMinutesFromMidnight
        self.defaultSuhoorTimeMode = defaultSuhoorTimeMode
        self.defaultSuhoorOffsetMinutes = defaultSuhoorOffsetMinutes
        self.defaultReminderTimeMode = defaultReminderTimeMode
        self.defaultReminderMinutesBeforeFajr = defaultReminderMinutesBeforeFajr
        self.defaultReminderFixedTimeMinutes = defaultReminderFixedTimeMinutes
        self.defaultIftarDelivery = defaultIftarDelivery
        self.defaultIftarSoundChoice = defaultIftarSoundChoice
        self.activationMode = activationMode
        self.activeStartDate = activeStartDate
        self.activeEndDate = activeEndDate
        self.scheduleWindowDays = scheduleWindowDays
        self.extraOneOffDates = extraOneOffDates
        self.deletedDates = deletedDates
    }

    static let `default` = DefaultAlarmConfig(
        suhoorEnabledDefault: true,
        reminderEnabledDefault: true,
        fajrEnabledDefault: true,
        iftarEnabledDefault: true,
        defaultWakeState: .preFajr,
        defaultWakeAnchorType: .fajrStart,
        defaultWakeDeltaMinutes: 30,
        defaultLatestWakeCapMinutesFromMidnight: nil,
        defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
        defaultSuhoorOffsetMinutes: 30,
        defaultReminderTimeMode: .beforeFajr,
        defaultReminderMinutesBeforeFajr: 10,
        defaultReminderFixedTimeMinutes: 0,
        defaultIftarDelivery: .notificationOnly,
        defaultIftarSoundChoice: .adhanSoft,
        activationMode: .alwaysOn,
        activeStartDate: nil,
        activeEndDate: nil,
        scheduleWindowDays: 14,
        extraOneOffDates: [],
        deletedDates: []
    )

    enum CodingKeys: String, CodingKey {
        case suhoorEnabledDefault
        case reminderEnabledDefault
        case fajrEnabledDefault
        case iftarEnabledDefault
        case defaultWakeState
        case defaultWakeAnchorType
        case defaultWakeDeltaMinutes
        case defaultLatestWakeCapMinutesFromMidnight
        case defaultSuhoorTimeMode
        case defaultSuhoorOffsetMinutes
        case defaultReminderTimeMode
        case defaultReminderMinutesBeforeFajr
        case defaultReminderFixedTimeMinutes
        case defaultIftarDelivery
        case defaultIftarSoundChoice
        case activationMode
        case activeStartDate
        case activeEndDate
        case scheduleWindowDays
        case extraOneOffDates
        case deletedDates
        case extraActiveDates
        case legacyDefaultReminderOffsetMinutes = "defaultReminderOffsetMinutes"
        case legacyDefaultReminderMinutesAfterSuhoor = "defaultReminderMinutesAfterSuhoor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suhoorEnabledDefault = try container.decode(Bool.self, forKey: .suhoorEnabledDefault)
        reminderEnabledDefault = try container.decode(Bool.self, forKey: .reminderEnabledDefault)
        fajrEnabledDefault = try container.decode(Bool.self, forKey: .fajrEnabledDefault)
        iftarEnabledDefault = try container.decodeIfPresent(Bool.self, forKey: .iftarEnabledDefault) ?? true
        defaultSuhoorTimeMode = try container.decodeIfPresent(SuhoorTimeMode.self, forKey: .defaultSuhoorTimeMode)
            ?? .relativeToFajrMinusMinutes
        defaultSuhoorOffsetMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultSuhoorOffsetMinutes) ?? 30
        if let storedWakeState = try container.decodeIfPresent(DefaultWakeState.self, forKey: .defaultWakeState) {
            defaultWakeState = storedWakeState
        } else if defaultSuhoorTimeMode == .relativeToFajrMinusMinutes {
            defaultWakeState = .preFajr
        } else {
            defaultWakeState = .preFajr
        }
        defaultWakeAnchorType = try container.decodeIfPresent(WakeAnchorType.self, forKey: .defaultWakeAnchorType)
            ?? .fajrStart
        let fallbackWakeDelta = defaultSuhoorTimeMode == .relativeToFajrMinusMinutes
            ? max(0, defaultSuhoorOffsetMinutes)
            : 30
        defaultWakeDeltaMinutes = max(
            0,
            try container.decodeIfPresent(Int.self, forKey: .defaultWakeDeltaMinutes) ?? fallbackWakeDelta
        )
        defaultLatestWakeCapMinutesFromMidnight = try container.decodeIfPresent(
            Int.self,
            forKey: .defaultLatestWakeCapMinutesFromMidnight
        )
        defaultReminderTimeMode = try container.decodeIfPresent(ReminderTimeMode.self, forKey: .defaultReminderTimeMode)
            ?? .beforeFajr
        let legacyMinutes = try container.decodeIfPresent(Int.self, forKey: .legacyDefaultReminderMinutesAfterSuhoor)
            ?? container.decodeIfPresent(Int.self, forKey: .legacyDefaultReminderOffsetMinutes)
        let decodedMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultReminderMinutesBeforeFajr)
            ?? legacyMinutes
            ?? 10
        defaultReminderMinutesBeforeFajr = max(decodedMinutes, 10)
        defaultReminderFixedTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultReminderFixedTimeMinutes) ?? 0
        defaultIftarDelivery = try container.decodeIfPresent(IftarDeliverySelection.self, forKey: .defaultIftarDelivery)
            ?? .notificationOnly
        defaultIftarSoundChoice = try container.decodeIfPresent(SoundChoice.self, forKey: .defaultIftarSoundChoice)
            ?? .adhanSoft
        activationMode = try container.decodeIfPresent(AlarmActivationMode.self, forKey: .activationMode) ?? .alwaysOn
        activeStartDate = try container.decodeIfPresent(Date.self, forKey: .activeStartDate)
        activeEndDate = try container.decodeIfPresent(Date.self, forKey: .activeEndDate)
        scheduleWindowDays = try container.decodeIfPresent(Int.self, forKey: .scheduleWindowDays) ?? 14
        extraOneOffDates = try container.decodeIfPresent(Set<String>.self, forKey: .extraOneOffDates)
            ?? container.decodeIfPresent(Set<String>.self, forKey: .extraActiveDates)
            ?? []
        deletedDates = try container.decodeIfPresent(Set<String>.self, forKey: .deletedDates) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(suhoorEnabledDefault, forKey: .suhoorEnabledDefault)
        try container.encode(reminderEnabledDefault, forKey: .reminderEnabledDefault)
        try container.encode(fajrEnabledDefault, forKey: .fajrEnabledDefault)
        try container.encode(iftarEnabledDefault, forKey: .iftarEnabledDefault)
        try container.encode(defaultWakeState, forKey: .defaultWakeState)
        try container.encode(defaultWakeAnchorType, forKey: .defaultWakeAnchorType)
        try container.encode(defaultWakeDeltaMinutes, forKey: .defaultWakeDeltaMinutes)
        try container.encodeIfPresent(
            defaultLatestWakeCapMinutesFromMidnight,
            forKey: .defaultLatestWakeCapMinutesFromMidnight
        )
        try container.encode(defaultSuhoorTimeMode, forKey: .defaultSuhoorTimeMode)
        try container.encode(defaultSuhoorOffsetMinutes, forKey: .defaultSuhoorOffsetMinutes)
        try container.encode(defaultReminderTimeMode, forKey: .defaultReminderTimeMode)
        try container.encode(defaultReminderMinutesBeforeFajr, forKey: .defaultReminderMinutesBeforeFajr)
        try container.encode(defaultReminderFixedTimeMinutes, forKey: .defaultReminderFixedTimeMinutes)
        try container.encode(defaultIftarDelivery, forKey: .defaultIftarDelivery)
        try container.encode(defaultIftarSoundChoice, forKey: .defaultIftarSoundChoice)
        try container.encode(activationMode, forKey: .activationMode)
        try container.encodeIfPresent(activeStartDate, forKey: .activeStartDate)
        try container.encodeIfPresent(activeEndDate, forKey: .activeEndDate)
        try container.encode(scheduleWindowDays, forKey: .scheduleWindowDays)
        try container.encode(extraOneOffDates, forKey: .extraOneOffDates)
        try container.encode(deletedDates, forKey: .deletedDates)
    }
}

struct DailyAlarmOverride: Codable, Equatable, Identifiable, Sendable {
    let dateKey: String
    let date: Date
    var skipDay: Bool
    var suhoorEnabled: Bool?
    var reminderEnabled: Bool?
    var fajrEnabled: Bool?
    var iftarEnabled: Bool?
    var wakeStateOverride: MorningWakeRuleState?
    var wakeAnchorTypeOverride: WakeAnchorType?
    var wakeDeltaOverrideMinutes: Int?
    var fixedWakeTimeOverrideMinutesFromMidnight: Int?
    var bypassLatestWakeCap: Bool?
    var tahajjudRefinement: Bool?
    var suhoorOffsetOverrideMinutes: Int?
    var reminderOffsetOverrideMinutes: Int?
    var suhoorTimeOverrideMinutesFromMidnight: Int?
    var reminderTimeOverrideMinutesFromMidnight: Int?
    var fajrSoundOverride: SoundChoice?
    var iftarDeliveryOverride: IftarDeliverySelection?
    var iftarSoundOverride: SoundChoice?
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
        self.iftarEnabled = nil
        self.wakeStateOverride = nil
        self.wakeAnchorTypeOverride = nil
        self.wakeDeltaOverrideMinutes = nil
        self.fixedWakeTimeOverrideMinutesFromMidnight = nil
        self.bypassLatestWakeCap = nil
        self.tahajjudRefinement = nil
        self.suhoorOffsetOverrideMinutes = nil
        self.reminderOffsetOverrideMinutes = nil
        self.suhoorTimeOverrideMinutesFromMidnight = nil
        self.reminderTimeOverrideMinutesFromMidnight = nil
        self.fajrSoundOverride = nil
        self.iftarDeliveryOverride = nil
        self.iftarSoundOverride = nil
        self.notes = nil
    }

    var hasOverrides: Bool {
        if skipDay { return true }
        if suhoorEnabled != nil { return true }
        if reminderEnabled != nil { return true }
        if fajrEnabled != nil { return true }
        if iftarEnabled != nil { return true }
        if wakeStateOverride != nil { return true }
        if wakeAnchorTypeOverride != nil { return true }
        if wakeDeltaOverrideMinutes != nil { return true }
        if fixedWakeTimeOverrideMinutesFromMidnight != nil { return true }
        if bypassLatestWakeCap != nil { return true }
        if tahajjudRefinement == true { return true }
        if suhoorOffsetOverrideMinutes != nil { return true }
        if reminderOffsetOverrideMinutes != nil { return true }
        if suhoorTimeOverrideMinutesFromMidnight != nil { return true }
        if reminderTimeOverrideMinutesFromMidnight != nil { return true }
        if fajrSoundOverride != nil { return true }
        if iftarDeliveryOverride != nil { return true }
        if iftarSoundOverride != nil { return true }
        if let notes, !notes.isEmpty { return true }
        return false
    }

    var hasSuhoorCustomization: Bool {
        wakeStateOverride != nil
            || wakeAnchorTypeOverride != nil
            || wakeDeltaOverrideMinutes != nil
            || fixedWakeTimeOverrideMinutesFromMidnight != nil
            || suhoorOffsetOverrideMinutes != nil
            || suhoorTimeOverrideMinutesFromMidnight != nil
    }

    var hasReminderCustomization: Bool {
        reminderOffsetOverrideMinutes != nil || reminderTimeOverrideMinutesFromMidnight != nil
    }

    var hasFajrCustomization: Bool {
        fajrSoundOverride != nil
    }

    var hasIftarCustomization: Bool {
        if let delivery = iftarDeliveryOverride?.normalized(), !delivery.isOff {
            return true
        }
        return iftarSoundOverride != nil
    }
}

struct EffectiveDailyConfig: Codable, Equatable, Sendable {
    let date: Date
    let defaultsActive: Bool
    let skipDay: Bool
    let suhoorEnabled: Bool
    let reminderEnabled: Bool
    let fajrEnabled: Bool
    let iftarEnabled: Bool
    let defaultWakeRule: MorningWakeRule
    let resolvedWakeRule: MorningWakeRule
    let wakeRuleWasOverridden: Bool
    let tahajjudRefinement: Bool
    let suhoorTimeMode: SuhoorTimeMode
    let suhoorOffsetMinutes: Int
    let reminderTimeMode: ReminderTimeMode
    let reminderMinutesBeforeFajr: Int
    let reminderFixedTimeMinutes: Int
    let suhoorTimeOverrideMinutesFromMidnight: Int?
    let reminderTimeOverrideMinutesFromMidnight: Int?
    let fajrSoundChoice: SoundChoice
    let iftarDelivery: IftarDeliverySelection
    let iftarSoundChoice: SoundChoice
    let hasOverrides: Bool

    var hasAnyEnabled: Bool {
        suhoorEnabled || reminderEnabled || fajrEnabled || iftarEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case defaultsActive
        case skipDay
        case suhoorEnabled
        case reminderEnabled
        case fajrEnabled
        case iftarEnabled
        case defaultWakeRule
        case resolvedWakeRule
        case wakeRuleWasOverridden
        case tahajjudRefinement
        case suhoorTimeMode
        case suhoorOffsetMinutes
        case reminderTimeMode
        case reminderMinutesBeforeFajr
        case reminderFixedTimeMinutes
        case suhoorTimeOverrideMinutesFromMidnight
        case reminderTimeOverrideMinutesFromMidnight
        case fajrSoundChoice
        case iftarDelivery
        case iftarSoundChoice
        case hasOverrides
    }

    init(
        date: Date,
        defaultsActive: Bool,
        skipDay: Bool,
        suhoorEnabled: Bool,
        reminderEnabled: Bool,
        fajrEnabled: Bool,
        iftarEnabled: Bool,
        defaultWakeRule: MorningWakeRule = DefaultAlarmConfig.default.defaultWakeRule,
        resolvedWakeRule: MorningWakeRule = DefaultAlarmConfig.default.defaultWakeRule,
        wakeRuleWasOverridden: Bool = false,
        tahajjudRefinement: Bool = false,
        suhoorTimeMode: SuhoorTimeMode,
        suhoorOffsetMinutes: Int,
        reminderTimeMode: ReminderTimeMode,
        reminderMinutesBeforeFajr: Int,
        reminderFixedTimeMinutes: Int,
        suhoorTimeOverrideMinutesFromMidnight: Int?,
        reminderTimeOverrideMinutesFromMidnight: Int?,
        fajrSoundChoice: SoundChoice,
        iftarDelivery: IftarDeliverySelection,
        iftarSoundChoice: SoundChoice,
        hasOverrides: Bool
    ) {
        self.date = date
        self.defaultsActive = defaultsActive
        self.skipDay = skipDay
        self.suhoorEnabled = suhoorEnabled
        self.reminderEnabled = reminderEnabled
        self.fajrEnabled = fajrEnabled
        self.iftarEnabled = iftarEnabled
        self.defaultWakeRule = defaultWakeRule
        self.resolvedWakeRule = resolvedWakeRule
        self.wakeRuleWasOverridden = wakeRuleWasOverridden
        self.tahajjudRefinement = tahajjudRefinement
        self.suhoorTimeMode = suhoorTimeMode
        self.suhoorOffsetMinutes = suhoorOffsetMinutes
        self.reminderTimeMode = reminderTimeMode
        self.reminderMinutesBeforeFajr = reminderMinutesBeforeFajr
        self.reminderFixedTimeMinutes = reminderFixedTimeMinutes
        self.suhoorTimeOverrideMinutesFromMidnight = suhoorTimeOverrideMinutesFromMidnight
        self.reminderTimeOverrideMinutesFromMidnight = reminderTimeOverrideMinutesFromMidnight
        self.fajrSoundChoice = fajrSoundChoice
        self.iftarDelivery = iftarDelivery
        self.iftarSoundChoice = iftarSoundChoice
        self.hasOverrides = hasOverrides
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackWakeRule = DefaultAlarmConfig.default.defaultWakeRule
        let decodedDefaultWakeRule = try container.decodeIfPresent(MorningWakeRule.self, forKey: .defaultWakeRule)
        let decodedResolvedWakeRule = try container.decodeIfPresent(MorningWakeRule.self, forKey: .resolvedWakeRule)

        self.init(
            date: try container.decode(Date.self, forKey: .date),
            defaultsActive: try container.decode(Bool.self, forKey: .defaultsActive),
            skipDay: try container.decode(Bool.self, forKey: .skipDay),
            suhoorEnabled: try container.decode(Bool.self, forKey: .suhoorEnabled),
            reminderEnabled: try container.decode(Bool.self, forKey: .reminderEnabled),
            fajrEnabled: try container.decode(Bool.self, forKey: .fajrEnabled),
            iftarEnabled: try container.decode(Bool.self, forKey: .iftarEnabled),
            defaultWakeRule: decodedDefaultWakeRule ?? fallbackWakeRule,
            resolvedWakeRule: decodedResolvedWakeRule ?? decodedDefaultWakeRule ?? fallbackWakeRule,
            wakeRuleWasOverridden: try container.decodeIfPresent(Bool.self, forKey: .wakeRuleWasOverridden)
                ?? false,
            tahajjudRefinement: try container.decodeIfPresent(Bool.self, forKey: .tahajjudRefinement)
                ?? false,
            suhoorTimeMode: try container.decode(SuhoorTimeMode.self, forKey: .suhoorTimeMode),
            suhoorOffsetMinutes: try container.decode(Int.self, forKey: .suhoorOffsetMinutes),
            reminderTimeMode: try container.decode(ReminderTimeMode.self, forKey: .reminderTimeMode),
            reminderMinutesBeforeFajr: try container.decode(Int.self, forKey: .reminderMinutesBeforeFajr),
            reminderFixedTimeMinutes: try container.decode(Int.self, forKey: .reminderFixedTimeMinutes),
            suhoorTimeOverrideMinutesFromMidnight: try container.decodeIfPresent(Int.self, forKey: .suhoorTimeOverrideMinutesFromMidnight),
            reminderTimeOverrideMinutesFromMidnight: try container.decodeIfPresent(Int.self, forKey: .reminderTimeOverrideMinutesFromMidnight),
            fajrSoundChoice: try container.decode(SoundChoice.self, forKey: .fajrSoundChoice),
            iftarDelivery: try container.decode(IftarDeliverySelection.self, forKey: .iftarDelivery),
            iftarSoundChoice: try container.decode(SoundChoice.self, forKey: .iftarSoundChoice),
            hasOverrides: try container.decode(Bool.self, forKey: .hasOverrides)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(defaultsActive, forKey: .defaultsActive)
        try container.encode(skipDay, forKey: .skipDay)
        try container.encode(suhoorEnabled, forKey: .suhoorEnabled)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(fajrEnabled, forKey: .fajrEnabled)
        try container.encode(iftarEnabled, forKey: .iftarEnabled)
        try container.encode(defaultWakeRule, forKey: .defaultWakeRule)
        try container.encode(resolvedWakeRule, forKey: .resolvedWakeRule)
        try container.encode(wakeRuleWasOverridden, forKey: .wakeRuleWasOverridden)
        try container.encode(tahajjudRefinement, forKey: .tahajjudRefinement)
        try container.encode(suhoorTimeMode, forKey: .suhoorTimeMode)
        try container.encode(suhoorOffsetMinutes, forKey: .suhoorOffsetMinutes)
        try container.encode(reminderTimeMode, forKey: .reminderTimeMode)
        try container.encode(reminderMinutesBeforeFajr, forKey: .reminderMinutesBeforeFajr)
        try container.encode(reminderFixedTimeMinutes, forKey: .reminderFixedTimeMinutes)
        try container.encodeIfPresent(suhoorTimeOverrideMinutesFromMidnight, forKey: .suhoorTimeOverrideMinutesFromMidnight)
        try container.encodeIfPresent(reminderTimeOverrideMinutesFromMidnight, forKey: .reminderTimeOverrideMinutesFromMidnight)
        try container.encode(fajrSoundChoice, forKey: .fajrSoundChoice)
        try container.encode(iftarDelivery, forKey: .iftarDelivery)
        try container.encode(iftarSoundChoice, forKey: .iftarSoundChoice)
        try container.encode(hasOverrides, forKey: .hasOverrides)
    }
}

extension DefaultAlarmConfig {
    var normalizedDefaultWakeAnchorType: WakeAnchorType {
        switch defaultWakeState {
        case .preFajr:
            return .fajrStart
        case .inFajr:
            return defaultWakeAnchorType == .fajrEnd ? .fajrEnd : .fajrStart
        }
    }

    var defaultWakeRule: MorningWakeRule {
        MorningWakeRule(
            state: defaultWakeState.asWakeRuleState,
            anchorType: normalizedDefaultWakeAnchorType,
            deltaMinutes: max(0, defaultWakeDeltaMinutes),
            fixedWakeTimeMinutesFromMidnight: defaultSuhoorTimeMode == .fixedTime ? defaultSuhoorOffsetMinutes : nil,
            latestWakeCapMinutesFromMidnight: defaultLatestWakeCapMinutesFromMidnight,
            bypassLatestWakeCap: false,
            isLegacyFixedWakeCompatibility: defaultSuhoorTimeMode == .fixedTime
        )
    }
}

extension DailyAlarmOverride {
    func resolvedWakeRule(defaults: DefaultAlarmConfig) -> MorningWakeRule? {
        let fixedMinutes = fixedWakeTimeOverrideMinutesFromMidnight ?? suhoorTimeOverrideMinutesFromMidnight
        if let wakeStateOverride {
            let delta = max(0, wakeDeltaOverrideMinutes ?? suhoorOffsetOverrideMinutes ?? defaults.defaultWakeDeltaMinutes)
            switch wakeStateOverride {
            case .preFajr:
                return MorningWakeRule(
                    state: .preFajr,
                    anchorType: .fajrStart,
                    deltaMinutes: delta,
                    latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                    bypassLatestWakeCap: bypassLatestWakeCap ?? true
                )
            case .inFajr:
                return MorningWakeRule(
                    state: .inFajr,
                    anchorType: wakeAnchorTypeOverride == .fajrEnd ? .fajrEnd : .fajrStart,
                    deltaMinutes: delta,
                    latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                    bypassLatestWakeCap: bypassLatestWakeCap ?? true
                )
            case .postFajr:
                return MorningWakeRule(
                    state: .postFajr,
                    anchorType: .fajrEnd,
                    deltaMinutes: delta,
                    latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                    bypassLatestWakeCap: bypassLatestWakeCap ?? true
                )
            case .fixedWake:
                return MorningWakeRule(
                    state: .fixedWake,
                    anchorType: .clockTime,
                    deltaMinutes: 0,
                    fixedWakeTimeMinutesFromMidnight: fixedMinutes,
                    latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                    bypassLatestWakeCap: bypassLatestWakeCap ?? true
                )
            }
        }

        if let fixedMinutes {
            return MorningWakeRule(
                state: .fixedWake,
                anchorType: .clockTime,
                deltaMinutes: 0,
                fixedWakeTimeMinutesFromMidnight: fixedMinutes,
                latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                bypassLatestWakeCap: true
            )
        }

        if let offset = suhoorOffsetOverrideMinutes {
            return MorningWakeRule(
                state: defaults.defaultWakeState.asWakeRuleState,
                anchorType: defaults.normalizedDefaultWakeAnchorType,
                deltaMinutes: max(0, offset),
                latestWakeCapMinutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight,
                bypassLatestWakeCap: bypassLatestWakeCap ?? true
            )
        }

        return nil
    }
}

enum PrimaryDisplayKind: Codable, Equatable, Sendable {
    case suhoor
    case reminder
    case fajr
    case iftar
}

struct PrimaryDisplay: Codable, Equatable, Sendable {
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
        if iftarEnabled, let iftarDate = schedule.iftarDate {
            return PrimaryDisplay(time: iftarDate, kind: .iftar)
        }
        return nil
    }
}
