import Foundation

enum WakeAnchorType: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrStart
    case fajrEnd
    case masjidFajr
    case clockTime

    var id: String { rawValue }
}

enum ResolvedWakeState: String, Codable, CaseIterable, Identifiable, Sendable {
    case preFajr
    case inFajr
    case postFajr

    var id: String { rawValue }
}

enum MorningWakeRuleState: String, Codable, CaseIterable, Identifiable, Sendable {
    case preFajr
    case inFajr
    case postFajr
    case fixedWake

    var id: String { rawValue }
}

enum DefaultWakeState: String, Codable, CaseIterable, Identifiable, Sendable {
    case preFajr
    case inFajr

    var id: String { rawValue }

    var asWakeRuleState: MorningWakeRuleState {
        switch self {
        case .preFajr:
            return .preFajr
        case .inFajr:
            return .inFajr
        }
    }

    init(_ state: MorningWakeRuleState) {
        switch state {
        case .preFajr:
            self = .preFajr
        case .inFajr, .postFajr, .fixedWake:
            self = .inFajr
        }
    }
}

enum QuickWakeMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case suhoor
    case fajr
    case quiet

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .suhoor:
            return "Suhoor"
        case .fajr:
            return "Fajr"
        case .quiet:
            return "Quiet"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "suhoor", "fast", "preFajr", "pre-fajr", "early", "Early", "Fast", "Pre-Fajr":
            self = .suhoor
        case "fajr", "Fajr":
            self = .fajr
        case "quiet", "Quiet", "off", "Off", "noAlarm", "No alarm":
            self = .quiet
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown quick wake mode: \(value)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum EarlyWakePurposeOverride: String, Codable, CaseIterable, Identifiable, Sendable {
    case fast
    case tahajjud
    case fastAndTahajjud

    static let allCases: [EarlyWakePurposeOverride] = [.fast]

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .fast:
            return "Suhoor"
        case .tahajjud:
            return "Suhoor"
        case .fastAndTahajjud:
            return "Suhoor"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "fast", "tahajjud", "fastAndTahajjud", "otherEarlyWorship", "other", "Fasting", "Tahajjud only":
            self = .fast
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown early wake purpose: \(value)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum AlarmDetailFastTypeOverride: String, Codable, Identifiable, Sendable {
    case other
    case voluntary
    case qada
    case vowNadhr
    case kaffarah

    static let allCases: [AlarmDetailFastTypeOverride] = [
        .voluntary,
        .qada,
        .vowNadhr,
        .kaffarah,
        .other
    ]

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .other:
            return "Other fast"
        case .voluntary:
            return "Voluntary fast"
        case .qada:
            return "Qada fast"
        case .vowNadhr:
            return "Vow / Nadhr fast"
        case .kaffarah:
            return "Kaffarah fast"
        }
    }

    var primaryIntent: FastPrimaryIntent {
        switch self {
        case .other:
            return .other
        case .voluntary:
            return .voluntary
        case .qada:
            return .qadaMakeup
        case .vowNadhr:
            return .vowNadhr
        case .kaffarah:
            return .kaffarahExpiation
        }
    }
}

enum AlarmDetailAudioPlan: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrAdhan
    case wakeAlarm
    case wakeAlarmAndFajrAdhan

    var id: String { rawValue }
}

struct WakeAnchor: Codable, Equatable, Hashable, Sendable {
    let type: WakeAnchorType
    let date: Date
    let providerNotes: String?
}

enum WakeDeltaRelation: String, Codable, CaseIterable, Identifiable, Sendable {
    case before
    case after

    var id: String { rawValue }
}

struct WakeDelta: Codable, Equatable, Hashable, Sendable {
    let relation: WakeDeltaRelation
    let minutes: Int

    var signedMinutes: Int {
        switch relation {
        case .before:
            return -minutes
        case .after:
            return minutes
        }
    }
}

struct MorningWakeRule: Codable, Equatable, Hashable, Sendable {
    let state: MorningWakeRuleState
    let anchorType: WakeAnchorType?
    let deltaMinutes: Int
    let fixedWakeTimeMinutesFromMidnight: Int?
    let latestWakeCapMinutesFromMidnight: Int?
    let bypassLatestWakeCap: Bool
    let isLegacyFixedWakeCompatibility: Bool

    init(
        state: MorningWakeRuleState,
        anchorType: WakeAnchorType?,
        deltaMinutes: Int,
        fixedWakeTimeMinutesFromMidnight: Int? = nil,
        latestWakeCapMinutesFromMidnight: Int? = nil,
        bypassLatestWakeCap: Bool = false,
        isLegacyFixedWakeCompatibility: Bool = false
    ) {
        self.state = state
        self.anchorType = state == .fixedWake ? .clockTime : anchorType
        self.deltaMinutes = max(0, deltaMinutes)
        self.fixedWakeTimeMinutesFromMidnight = fixedWakeTimeMinutesFromMidnight
        self.latestWakeCapMinutesFromMidnight = latestWakeCapMinutesFromMidnight
        self.bypassLatestWakeCap = bypassLatestWakeCap
        self.isLegacyFixedWakeCompatibility = isLegacyFixedWakeCompatibility
    }

    var compatibilityWakeAnchorType: WakeAnchorType {
        anchorType ?? .fajrStart
    }

    var compatibilityWakeDelta: WakeDelta {
        switch state {
        case .preFajr:
            return WakeDelta(relation: .before, minutes: deltaMinutes)
        case .inFajr:
            let relation: WakeDeltaRelation = compatibilityWakeAnchorType == .fajrEnd ? .before : .after
            return WakeDelta(relation: relation, minutes: deltaMinutes)
        case .postFajr:
            return WakeDelta(relation: .after, minutes: deltaMinutes)
        case .fixedWake:
            return WakeDelta(relation: .after, minutes: 0)
        }
    }

    var usesLatestWakeCap: Bool {
        latestWakeCapMinutesFromMidnight != nil && !bypassLatestWakeCap && state != .fixedWake
    }
}

struct MorningBehaviorProfile: Codable, Equatable, Hashable, Sendable {
    let wakeAnchorType: WakeAnchorType
    let wakeDelta: WakeDelta
    let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?
    let reminderEnabled: Bool
    let wakeAlarmEnabled: Bool
    let wakeFollowUpEnabled: Bool
    let fajrBoundaryNoticeEnabled: Bool
    let iftarReminderEnabled: Bool
    let resolvedWakeState: ResolvedWakeState
    let plannedWakeState: MorningWakeRuleState
    let latestWakeCapMinutesFromMidnight: Int?
    let latestWakeCapApplied: Bool
    let latestWakeCapShiftedState: Bool
    let primaryWakeSoundRole: MorningSoundRole?
    let takesOverAtFajrStart: Bool
    let suppressDefaultPrayerPrompt: Bool

    private enum CodingKeys: String, CodingKey {
        case wakeAnchorType
        case wakeDelta
        case fixedWakeTimeCompatibilityMinutesFromMidnight
        case reminderEnabled
        case wakeAlarmEnabled
        case wakeFollowUpEnabled
        case fajrBoundaryNoticeEnabled
        case iftarReminderEnabled
        case resolvedWakeState
        case plannedWakeState
        case latestWakeCapMinutesFromMidnight
        case latestWakeCapApplied
        case latestWakeCapShiftedState
        case primaryWakeSoundRole
        case takesOverAtFajrStart
        case suppressDefaultPrayerPrompt
    }

    init(
        wakeAnchorType: WakeAnchorType,
        wakeDelta: WakeDelta,
        fixedWakeTimeCompatibilityMinutesFromMidnight: Int?,
        reminderEnabled: Bool,
        wakeAlarmEnabled: Bool,
        wakeFollowUpEnabled: Bool,
        fajrBoundaryNoticeEnabled: Bool,
        iftarReminderEnabled: Bool,
        resolvedWakeState: ResolvedWakeState = .preFajr,
        plannedWakeState: MorningWakeRuleState = .preFajr,
        latestWakeCapMinutesFromMidnight: Int? = nil,
        latestWakeCapApplied: Bool = false,
        latestWakeCapShiftedState: Bool = false,
        primaryWakeSoundRole: MorningSoundRole? = nil,
        takesOverAtFajrStart: Bool = false,
        suppressDefaultPrayerPrompt: Bool = false
    ) {
        self.wakeAnchorType = wakeAnchorType
        self.wakeDelta = wakeDelta
        self.fixedWakeTimeCompatibilityMinutesFromMidnight = fixedWakeTimeCompatibilityMinutesFromMidnight
        self.reminderEnabled = reminderEnabled
        self.wakeAlarmEnabled = wakeAlarmEnabled
        self.wakeFollowUpEnabled = wakeFollowUpEnabled
        self.fajrBoundaryNoticeEnabled = fajrBoundaryNoticeEnabled
        self.iftarReminderEnabled = iftarReminderEnabled
        self.resolvedWakeState = resolvedWakeState
        self.plannedWakeState = plannedWakeState
        self.latestWakeCapMinutesFromMidnight = latestWakeCapMinutesFromMidnight
        self.latestWakeCapApplied = latestWakeCapApplied
        self.latestWakeCapShiftedState = latestWakeCapShiftedState
        self.primaryWakeSoundRole = primaryWakeSoundRole
        self.takesOverAtFajrStart = takesOverAtFajrStart
        self.suppressDefaultPrayerPrompt = suppressDefaultPrayerPrompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            wakeAnchorType: try container.decode(WakeAnchorType.self, forKey: .wakeAnchorType),
            wakeDelta: try container.decode(WakeDelta.self, forKey: .wakeDelta),
            fixedWakeTimeCompatibilityMinutesFromMidnight: try container.decodeIfPresent(Int.self, forKey: .fixedWakeTimeCompatibilityMinutesFromMidnight),
            reminderEnabled: try container.decode(Bool.self, forKey: .reminderEnabled),
            wakeAlarmEnabled: try container.decode(Bool.self, forKey: .wakeAlarmEnabled),
            wakeFollowUpEnabled: try container.decode(Bool.self, forKey: .wakeFollowUpEnabled),
            fajrBoundaryNoticeEnabled: try container.decode(Bool.self, forKey: .fajrBoundaryNoticeEnabled),
            iftarReminderEnabled: try container.decode(Bool.self, forKey: .iftarReminderEnabled),
            resolvedWakeState: try container.decodeIfPresent(ResolvedWakeState.self, forKey: .resolvedWakeState) ?? .preFajr,
            plannedWakeState: try container.decodeIfPresent(MorningWakeRuleState.self, forKey: .plannedWakeState) ?? .preFajr,
            latestWakeCapMinutesFromMidnight: try container.decodeIfPresent(Int.self, forKey: .latestWakeCapMinutesFromMidnight),
            latestWakeCapApplied: try container.decodeIfPresent(Bool.self, forKey: .latestWakeCapApplied) ?? false,
            latestWakeCapShiftedState: try container.decodeIfPresent(Bool.self, forKey: .latestWakeCapShiftedState) ?? false,
            primaryWakeSoundRole: try container.decodeIfPresent(MorningSoundRole.self, forKey: .primaryWakeSoundRole),
            takesOverAtFajrStart: try container.decodeIfPresent(Bool.self, forKey: .takesOverAtFajrStart) ?? false,
            suppressDefaultPrayerPrompt: try container.decodeIfPresent(Bool.self, forKey: .suppressDefaultPrayerPrompt) ?? false
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wakeAnchorType, forKey: .wakeAnchorType)
        try container.encode(wakeDelta, forKey: .wakeDelta)
        try container.encodeIfPresent(fixedWakeTimeCompatibilityMinutesFromMidnight, forKey: .fixedWakeTimeCompatibilityMinutesFromMidnight)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(wakeAlarmEnabled, forKey: .wakeAlarmEnabled)
        try container.encode(wakeFollowUpEnabled, forKey: .wakeFollowUpEnabled)
        try container.encode(fajrBoundaryNoticeEnabled, forKey: .fajrBoundaryNoticeEnabled)
        try container.encode(iftarReminderEnabled, forKey: .iftarReminderEnabled)
        try container.encode(resolvedWakeState, forKey: .resolvedWakeState)
        try container.encode(plannedWakeState, forKey: .plannedWakeState)
        try container.encodeIfPresent(latestWakeCapMinutesFromMidnight, forKey: .latestWakeCapMinutesFromMidnight)
        try container.encode(latestWakeCapApplied, forKey: .latestWakeCapApplied)
        try container.encode(latestWakeCapShiftedState, forKey: .latestWakeCapShiftedState)
        try container.encodeIfPresent(primaryWakeSoundRole, forKey: .primaryWakeSoundRole)
        try container.encode(takesOverAtFajrStart, forKey: .takesOverAtFajrStart)
        try container.encode(suppressDefaultPrayerPrompt, forKey: .suppressDefaultPrayerPrompt)
    }
}

enum MorningPlanKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultDaily
    case explicitDateOverride
    case observanceOverlay
    case qadaAssignment
    case generatedObservance

    var id: String { rawValue }
}

struct MorningPlan: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let kind: MorningPlanKind
    let wakeRule: MorningWakeRule
    let wakeAnchorType: WakeAnchorType
    let wakeDelta: WakeDelta
    let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?
    let reminderEnabled: Bool
    let wakeAlarmEnabled: Bool
    let fajrBoundaryNoticeEnabled: Bool
    let iftarReminderEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case kind
        case wakeRule
        case wakeAnchorType
        case wakeDelta
        case fixedWakeTimeCompatibilityMinutesFromMidnight
        case reminderEnabled
        case wakeAlarmEnabled
        case fajrBoundaryNoticeEnabled
        case iftarReminderEnabled
    }

    init(
        id: String,
        title: String,
        kind: MorningPlanKind,
        wakeRule: MorningWakeRule,
        wakeAnchorType: WakeAnchorType,
        wakeDelta: WakeDelta,
        fixedWakeTimeCompatibilityMinutesFromMidnight: Int?,
        reminderEnabled: Bool,
        wakeAlarmEnabled: Bool,
        fajrBoundaryNoticeEnabled: Bool,
        iftarReminderEnabled: Bool
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.wakeRule = wakeRule
        self.wakeAnchorType = wakeAnchorType
        self.wakeDelta = wakeDelta
        self.fixedWakeTimeCompatibilityMinutesFromMidnight = fixedWakeTimeCompatibilityMinutesFromMidnight
        self.reminderEnabled = reminderEnabled
        self.wakeAlarmEnabled = wakeAlarmEnabled
        self.fajrBoundaryNoticeEnabled = fajrBoundaryNoticeEnabled
        self.iftarReminderEnabled = iftarReminderEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decode(MorningPlanKind.self, forKey: .kind)
        wakeAnchorType = try container.decodeIfPresent(WakeAnchorType.self, forKey: .wakeAnchorType) ?? .fajrStart
        wakeDelta = try container.decodeIfPresent(WakeDelta.self, forKey: .wakeDelta)
            ?? WakeDelta(relation: .before, minutes: 30)
        fixedWakeTimeCompatibilityMinutesFromMidnight = try container.decodeIfPresent(
            Int.self,
            forKey: .fixedWakeTimeCompatibilityMinutesFromMidnight
        )
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? true
        wakeAlarmEnabled = try container.decodeIfPresent(Bool.self, forKey: .wakeAlarmEnabled) ?? true
        fajrBoundaryNoticeEnabled = try container.decodeIfPresent(Bool.self, forKey: .fajrBoundaryNoticeEnabled) ?? true
        iftarReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .iftarReminderEnabled) ?? true

        if let decodedRule = try container.decodeIfPresent(MorningWakeRule.self, forKey: .wakeRule) {
            wakeRule = decodedRule
        } else {
            let synthesizedState: MorningWakeRuleState
            if fixedWakeTimeCompatibilityMinutesFromMidnight != nil {
                synthesizedState = .preFajr
            } else if wakeAnchorType == .fajrEnd && wakeDelta.relation == .after {
                synthesizedState = .postFajr
            } else if wakeDelta.relation == .before {
                synthesizedState = .preFajr
            } else {
                synthesizedState = .inFajr
            }

            wakeRule = MorningWakeRule(
                state: synthesizedState,
                anchorType: fixedWakeTimeCompatibilityMinutesFromMidnight == nil ? wakeAnchorType : .fajrStart,
                deltaMinutes: wakeDelta.minutes,
                fixedWakeTimeMinutesFromMidnight: fixedWakeTimeCompatibilityMinutesFromMidnight,
                latestWakeCapMinutesFromMidnight: nil,
                bypassLatestWakeCap: false,
                isLegacyFixedWakeCompatibility: fixedWakeTimeCompatibilityMinutesFromMidnight != nil
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(kind, forKey: .kind)
        try container.encode(wakeRule, forKey: .wakeRule)
        try container.encode(wakeAnchorType, forKey: .wakeAnchorType)
        try container.encode(wakeDelta, forKey: .wakeDelta)
        try container.encodeIfPresent(
            fixedWakeTimeCompatibilityMinutesFromMidnight,
            forKey: .fixedWakeTimeCompatibilityMinutesFromMidnight
        )
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(wakeAlarmEnabled, forKey: .wakeAlarmEnabled)
        try container.encode(fajrBoundaryNoticeEnabled, forKey: .fajrBoundaryNoticeEnabled)
        try container.encode(iftarReminderEnabled, forKey: .iftarReminderEnabled)
    }
}

struct PlanDateAssignment: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let planID: String
}

enum MorningPlanActivationMode: String, Codable, Sendable {
    case dailyActive
    case legacyCompat
}

struct MorningPlanState: Codable, Equatable, Sendable {
    let schemaVersion: Int
    var activationMode: MorningPlanActivationMode
    var defaultDailyPlan: MorningPlan
    var lastMigrationAt: Date?
}

struct RulePlanCandidate: Codable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let kind: MorningPlanKind
}

struct MorningPlanResolution: Sendable {
    let selectedPlan: MorningPlan
    let candidates: [RulePlanCandidate]
    let precedenceReason: String
}
