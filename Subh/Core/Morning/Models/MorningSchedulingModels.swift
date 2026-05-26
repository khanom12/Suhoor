import Foundation

struct DailyPrayerWindow: Codable, Equatable, Hashable, Sendable {
    let date: Date
    let fajrStart: Date
    let fajrEnd: Date?
    let maghrib: Date
    let calculationSource: PrayerCalculationSource
    let methodID: String?
    let methodDisplayName: String?
    let authorityName: String?
    let fajrAngleDegrees: Double?
    let highLatitudeRuleRequested: PrayerHighLatitudeRule
    let highLatitudeRuleApplied: PrayerHighLatitudeRule?
    let highLatitudeFallbackWasUsed: Bool
    let fajrBeginSource: FajrBeginSource
    let fajrEndSource: FajrEndSource
    let maghribSource: MaghribSource
    let adjustmentsApplied: PrayerBoundaryAdjustments
    let diagnostics: PrayerCalculationDiagnostics
    let isValid: Bool

    init(
        date: Date,
        fajrStart: Date,
        fajrEnd: Date?,
        maghrib: Date,
        calculationSource: PrayerCalculationSource = .localCalculated,
        methodID: String? = nil,
        methodDisplayName: String? = nil,
        authorityName: String? = nil,
        fajrAngleDegrees: Double? = nil,
        highLatitudeRuleRequested: PrayerHighLatitudeRule = .automatic,
        highLatitudeRuleApplied: PrayerHighLatitudeRule? = nil,
        highLatitudeFallbackWasUsed: Bool = false,
        fajrBeginSource: FajrBeginSource = .localSolarAngle,
        fajrEndSource: FajrEndSource = .unavailable,
        maghribSource: MaghribSource = .localSolarSunset,
        adjustmentsApplied: PrayerBoundaryAdjustments = .none,
        diagnostics: PrayerCalculationDiagnostics = .unavailable,
        isValid: Bool = true
    ) {
        self.date = date
        self.fajrStart = fajrStart
        self.fajrEnd = fajrEnd
        self.maghrib = maghrib
        self.calculationSource = calculationSource
        self.methodID = methodID
        self.methodDisplayName = methodDisplayName
        self.authorityName = authorityName
        self.fajrAngleDegrees = fajrAngleDegrees
        self.highLatitudeRuleRequested = highLatitudeRuleRequested
        self.highLatitudeRuleApplied = highLatitudeRuleApplied
        self.highLatitudeFallbackWasUsed = highLatitudeFallbackWasUsed
        self.fajrBeginSource = fajrBeginSource
        self.fajrEndSource = fajrEndSource
        self.maghribSource = maghribSource
        self.adjustmentsApplied = adjustmentsApplied
        self.diagnostics = diagnostics
        self.isValid = isValid
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case fajrStart
        case fajrEnd
        case maghrib
        case calculationSource
        case methodID
        case methodDisplayName
        case authorityName
        case fajrAngleDegrees
        case highLatitudeRuleRequested
        case highLatitudeRuleApplied
        case highLatitudeFallbackWasUsed
        case fajrBeginSource
        case fajrEndSource
        case maghribSource
        case adjustmentsApplied
        case diagnostics
        case isValid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fajrEnd = try container.decodeIfPresent(Date.self, forKey: .fajrEnd)
        self.init(
            date: try container.decode(Date.self, forKey: .date),
            fajrStart: try container.decode(Date.self, forKey: .fajrStart),
            fajrEnd: fajrEnd,
            maghrib: try container.decode(Date.self, forKey: .maghrib),
            calculationSource: try container.decodeIfPresent(PrayerCalculationSource.self, forKey: .calculationSource) ?? .localCalculated,
            methodID: try container.decodeIfPresent(String.self, forKey: .methodID),
            methodDisplayName: try container.decodeIfPresent(String.self, forKey: .methodDisplayName),
            authorityName: try container.decodeIfPresent(String.self, forKey: .authorityName),
            fajrAngleDegrees: try container.decodeIfPresent(Double.self, forKey: .fajrAngleDegrees),
            highLatitudeRuleRequested: try container.decodeIfPresent(PrayerHighLatitudeRule.self, forKey: .highLatitudeRuleRequested) ?? .automatic,
            highLatitudeRuleApplied: try container.decodeIfPresent(PrayerHighLatitudeRule.self, forKey: .highLatitudeRuleApplied),
            highLatitudeFallbackWasUsed: try container.decodeIfPresent(Bool.self, forKey: .highLatitudeFallbackWasUsed) ?? false,
            fajrBeginSource: try container.decodeIfPresent(FajrBeginSource.self, forKey: .fajrBeginSource) ?? .localSolarAngle,
            fajrEndSource: try container.decodeIfPresent(FajrEndSource.self, forKey: .fajrEndSource) ?? (fajrEnd == nil ? .unavailable : .solarSunrise),
            maghribSource: try container.decodeIfPresent(MaghribSource.self, forKey: .maghribSource) ?? .localSolarSunset,
            adjustmentsApplied: try container.decodeIfPresent(PrayerBoundaryAdjustments.self, forKey: .adjustmentsApplied) ?? .none,
            diagnostics: try container.decodeIfPresent(PrayerCalculationDiagnostics.self, forKey: .diagnostics) ?? .unavailable,
            isValid: try container.decodeIfPresent(Bool.self, forKey: .isValid) ?? true
        )
    }
}

enum MorningSoundRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case preFajrWake
    case fajrStart
    case inFajrWake
    case postFajrWake
    case fixedWake
    case reminder
    case iftar

    var id: String { rawValue }
}

enum WakeSessionEventRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case primaryWake
    case wakeCheck
    case checkpoint
    case companion

    var id: String { rawValue }
}

enum FajrStartBehavior: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case cueOnly
    case takeoverIfUnresolvedOtherwiseCue

    var id: String { rawValue }
}

enum ScheduledEventType: String, Codable, CaseIterable, Identifiable, Sendable {
    case wakeReminder
    case wakeAlarm
    case wakeFollowUp
    case fajrBoundaryNotice
    case iftarReminder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wakeReminder:
            return "Wake Reminder"
        case .wakeAlarm:
            return "Wake Alarm"
        case .wakeFollowUp:
            return "Wake Check"
        case .fajrBoundaryNotice:
            return "Fajr Notice"
        case .iftarReminder:
            return "Iftar Reminder"
        }
    }
}

enum PrayerBoundaryReference: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrStart
    case fajrEnd
    case maghrib

    var id: String { rawValue }
}

enum ScheduledEventRelativeReference: Codable, Equatable, Hashable, Sendable {
    case wakeAnchor(type: WakeAnchorType, offsetMinutes: Int)
    case wakeAlarm(offsetMinutes: Int)
    case prayerBoundary(boundary: PrayerBoundaryReference, offsetMinutes: Int)
    case fixedClock(minutesFromMidnight: Int)
    case absolute

    private enum CodingKeys: String, CodingKey {
        case type
        case wakeAnchorType
        case offsetMinutes
        case boundary
        case minutesFromMidnight
    }

    private enum Kind: String, Codable {
        case wakeAnchor
        case wakeAlarm
        case prayerBoundary
        case fixedClock
        case absolute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        switch kind {
        case .wakeAnchor:
            self = .wakeAnchor(
                type: try container.decode(WakeAnchorType.self, forKey: .wakeAnchorType),
                offsetMinutes: try container.decode(Int.self, forKey: .offsetMinutes)
            )
        case .wakeAlarm:
            self = .wakeAlarm(offsetMinutes: try container.decode(Int.self, forKey: .offsetMinutes))
        case .prayerBoundary:
            self = .prayerBoundary(
                boundary: try container.decode(PrayerBoundaryReference.self, forKey: .boundary),
                offsetMinutes: try container.decode(Int.self, forKey: .offsetMinutes)
            )
        case .fixedClock:
            self = .fixedClock(minutesFromMidnight: try container.decode(Int.self, forKey: .minutesFromMidnight))
        case .absolute:
            self = .absolute
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .wakeAnchor(let type, let offsetMinutes):
            try container.encode(Kind.wakeAnchor, forKey: .type)
            try container.encode(type, forKey: .wakeAnchorType)
            try container.encode(offsetMinutes, forKey: .offsetMinutes)
        case .wakeAlarm(let offsetMinutes):
            try container.encode(Kind.wakeAlarm, forKey: .type)
            try container.encode(offsetMinutes, forKey: .offsetMinutes)
        case .prayerBoundary(let boundary, let offsetMinutes):
            try container.encode(Kind.prayerBoundary, forKey: .type)
            try container.encode(boundary, forKey: .boundary)
            try container.encode(offsetMinutes, forKey: .offsetMinutes)
        case .fixedClock(let minutesFromMidnight):
            try container.encode(Kind.fixedClock, forKey: .type)
            try container.encode(minutesFromMidnight, forKey: .minutesFromMidnight)
        case .absolute:
            try container.encode(Kind.absolute, forKey: .type)
        }
    }
}

struct ScheduledEvent: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let type: ScheduledEventType
    let dateKey: String
    let fireDate: Date
    let relativeTo: ScheduledEventRelativeReference
    let isUserVisible: Bool
    let affectsCompletion: Bool
    let deliveryKinds: [ScheduleEventKind]
    let soundRole: MorningSoundRole?
    let wakeSessionID: String?
    let wakeSessionRole: WakeSessionEventRole?
    let fajrStartBehavior: FajrStartBehavior

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case dateKey
        case fireDate
        case relativeTo
        case isUserVisible
        case affectsCompletion
        case deliveryKinds
        case soundRole
        case wakeSessionID
        case wakeSessionRole
        case fajrStartBehavior
    }

    init(
        id: String,
        type: ScheduledEventType,
        dateKey: String,
        fireDate: Date,
        relativeTo: ScheduledEventRelativeReference,
        isUserVisible: Bool,
        affectsCompletion: Bool,
        deliveryKinds: [ScheduleEventKind],
        soundRole: MorningSoundRole? = nil,
        wakeSessionID: String? = nil,
        wakeSessionRole: WakeSessionEventRole? = nil,
        fajrStartBehavior: FajrStartBehavior = .none
    ) {
        self.id = id
        self.type = type
        self.dateKey = dateKey
        self.fireDate = fireDate
        self.relativeTo = relativeTo
        self.isUserVisible = isUserVisible
        self.affectsCompletion = affectsCompletion
        self.deliveryKinds = deliveryKinds
        self.soundRole = soundRole
        self.wakeSessionID = wakeSessionID
        self.wakeSessionRole = wakeSessionRole
        self.fajrStartBehavior = fajrStartBehavior
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            type: try container.decode(ScheduledEventType.self, forKey: .type),
            dateKey: try container.decode(String.self, forKey: .dateKey),
            fireDate: try container.decode(Date.self, forKey: .fireDate),
            relativeTo: try container.decode(ScheduledEventRelativeReference.self, forKey: .relativeTo),
            isUserVisible: try container.decode(Bool.self, forKey: .isUserVisible),
            affectsCompletion: try container.decode(Bool.self, forKey: .affectsCompletion),
            deliveryKinds: try container.decode([ScheduleEventKind].self, forKey: .deliveryKinds),
            soundRole: try container.decodeIfPresent(MorningSoundRole.self, forKey: .soundRole),
            wakeSessionID: try container.decodeIfPresent(String.self, forKey: .wakeSessionID),
            wakeSessionRole: try container.decodeIfPresent(WakeSessionEventRole.self, forKey: .wakeSessionRole),
            fajrStartBehavior: try container.decodeIfPresent(FajrStartBehavior.self, forKey: .fajrStartBehavior) ?? .none
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(dateKey, forKey: .dateKey)
        try container.encode(fireDate, forKey: .fireDate)
        try container.encode(relativeTo, forKey: .relativeTo)
        try container.encode(isUserVisible, forKey: .isUserVisible)
        try container.encode(affectsCompletion, forKey: .affectsCompletion)
        try container.encode(deliveryKinds, forKey: .deliveryKinds)
        try container.encodeIfPresent(soundRole, forKey: .soundRole)
        try container.encodeIfPresent(wakeSessionID, forKey: .wakeSessionID)
        try container.encodeIfPresent(wakeSessionRole, forKey: .wakeSessionRole)
        try container.encode(fajrStartBehavior, forKey: .fajrStartBehavior)
    }
}

struct WakeSequenceStep: Codable, Equatable, Hashable, Sendable {
    let eventType: ScheduledEventType
    let relativeTo: ScheduledEventRelativeReference
    let isUserVisible: Bool
    let affectsCompletion: Bool
    let soundRole: MorningSoundRole?
    let wakeSessionRole: WakeSessionEventRole?
    let fajrStartBehavior: FajrStartBehavior

    private enum CodingKeys: String, CodingKey {
        case eventType
        case relativeTo
        case isUserVisible
        case affectsCompletion
        case soundRole
        case wakeSessionRole
        case fajrStartBehavior
    }

    init(
        eventType: ScheduledEventType,
        relativeTo: ScheduledEventRelativeReference,
        isUserVisible: Bool,
        affectsCompletion: Bool,
        soundRole: MorningSoundRole? = nil,
        wakeSessionRole: WakeSessionEventRole? = nil,
        fajrStartBehavior: FajrStartBehavior = .none
    ) {
        self.eventType = eventType
        self.relativeTo = relativeTo
        self.isUserVisible = isUserVisible
        self.affectsCompletion = affectsCompletion
        self.soundRole = soundRole
        self.wakeSessionRole = wakeSessionRole
        self.fajrStartBehavior = fajrStartBehavior
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            eventType: try container.decode(ScheduledEventType.self, forKey: .eventType),
            relativeTo: try container.decode(ScheduledEventRelativeReference.self, forKey: .relativeTo),
            isUserVisible: try container.decode(Bool.self, forKey: .isUserVisible),
            affectsCompletion: try container.decode(Bool.self, forKey: .affectsCompletion),
            soundRole: try container.decodeIfPresent(MorningSoundRole.self, forKey: .soundRole),
            wakeSessionRole: try container.decodeIfPresent(WakeSessionEventRole.self, forKey: .wakeSessionRole),
            fajrStartBehavior: try container.decodeIfPresent(FajrStartBehavior.self, forKey: .fajrStartBehavior) ?? .none
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(relativeTo, forKey: .relativeTo)
        try container.encode(isUserVisible, forKey: .isUserVisible)
        try container.encode(affectsCompletion, forKey: .affectsCompletion)
        try container.encodeIfPresent(soundRole, forKey: .soundRole)
        try container.encodeIfPresent(wakeSessionRole, forKey: .wakeSessionRole)
        try container.encode(fajrStartBehavior, forKey: .fajrStartBehavior)
    }
}

struct WakeSequenceTemplate: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let steps: [WakeSequenceStep]
}

struct RuleDecisionLog: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let resolverVersion: Int
    let decisionHash: String
    let prayerWindow: DailyPrayerWindow
    let candidateContexts: [MorningContextType]
    let resolvedDayContext: ResolvedDayContext
    let candidatePlans: [RulePlanCandidate]
    let selectedPlanID: String
    let precedenceReason: String
    let resolvedBehaviorProfile: MorningBehaviorProfile
    let resolvedAnchor: WakeAnchor
    let resolvedDelta: WakeDelta
    let candidateWakeTime: Date
    let resolvedWakeTime: Date
    let resolvedWakeState: ResolvedWakeState
    let plannedWakeState: MorningWakeRuleState
    let latestWakeCapMinutesFromMidnight: Int?
    let latestWakeCapApplied: Bool
    let latestWakeCapShiftedState: Bool
    let suppressDefaultPrayerPrompt: Bool
    let resolvedSequenceTemplate: WakeSequenceTemplate
    let materializedEvents: [ScheduledEvent]
    let compatibilityNotes: [String]

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case resolverVersion
        case decisionHash
        case prayerWindow
        case candidateContexts
        case resolvedDayContext
        case candidatePlans
        case selectedPlanID
        case precedenceReason
        case resolvedBehaviorProfile
        case resolvedAnchor
        case resolvedDelta
        case candidateWakeTime
        case resolvedWakeTime
        case resolvedWakeState
        case plannedWakeState
        case latestWakeCapMinutesFromMidnight
        case latestWakeCapApplied
        case latestWakeCapShiftedState
        case suppressDefaultPrayerPrompt
        case resolvedSequenceTemplate
        case materializedEvents
        case compatibilityNotes
    }

    init(
        dateKey: String,
        resolverVersion: Int,
        decisionHash: String,
        prayerWindow: DailyPrayerWindow,
        candidateContexts: [MorningContextType],
        resolvedDayContext: ResolvedDayContext,
        candidatePlans: [RulePlanCandidate],
        selectedPlanID: String,
        precedenceReason: String,
        resolvedBehaviorProfile: MorningBehaviorProfile,
        resolvedAnchor: WakeAnchor,
        resolvedDelta: WakeDelta,
        candidateWakeTime: Date,
        resolvedWakeTime: Date,
        resolvedWakeState: ResolvedWakeState,
        plannedWakeState: MorningWakeRuleState,
        latestWakeCapMinutesFromMidnight: Int? = nil,
        latestWakeCapApplied: Bool = false,
        latestWakeCapShiftedState: Bool = false,
        suppressDefaultPrayerPrompt: Bool = false,
        resolvedSequenceTemplate: WakeSequenceTemplate,
        materializedEvents: [ScheduledEvent],
        compatibilityNotes: [String]
    ) {
        self.dateKey = dateKey
        self.resolverVersion = resolverVersion
        self.decisionHash = decisionHash
        self.prayerWindow = prayerWindow
        self.candidateContexts = candidateContexts
        self.resolvedDayContext = resolvedDayContext
        self.candidatePlans = candidatePlans
        self.selectedPlanID = selectedPlanID
        self.precedenceReason = precedenceReason
        self.resolvedBehaviorProfile = resolvedBehaviorProfile
        self.resolvedAnchor = resolvedAnchor
        self.resolvedDelta = resolvedDelta
        self.candidateWakeTime = candidateWakeTime
        self.resolvedWakeTime = resolvedWakeTime
        self.resolvedWakeState = resolvedWakeState
        self.plannedWakeState = plannedWakeState
        self.latestWakeCapMinutesFromMidnight = latestWakeCapMinutesFromMidnight
        self.latestWakeCapApplied = latestWakeCapApplied
        self.latestWakeCapShiftedState = latestWakeCapShiftedState
        self.suppressDefaultPrayerPrompt = suppressDefaultPrayerPrompt
        self.resolvedSequenceTemplate = resolvedSequenceTemplate
        self.materializedEvents = materializedEvents
        self.compatibilityNotes = compatibilityNotes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateKey = try container.decode(String.self, forKey: .dateKey)
        let prayerWindow = try container.decode(DailyPrayerWindow.self, forKey: .prayerWindow)
        let materializedEvents = try container.decodeIfPresent([ScheduledEvent].self, forKey: .materializedEvents) ?? []
        let resolvedWakeTime = try container.decode(Date.self, forKey: .resolvedWakeTime)
        let resolvedWakeState = try container.decodeIfPresent(ResolvedWakeState.self, forKey: .resolvedWakeState)
            ?? Self.classifyWakeState(resolvedWakeTime, prayerWindow: prayerWindow)
        let plannedWakeState = try container.decodeIfPresent(MorningWakeRuleState.self, forKey: .plannedWakeState)
            ?? Self.fallbackPlannedWakeState(for: resolvedWakeState)
        let fallbackSequence = WakeSequenceTemplate(
            id: "\(dateKey).decoded-sequence",
            name: "Decoded sequence",
            steps: materializedEvents.map {
                WakeSequenceStep(
                    eventType: $0.type,
                    relativeTo: $0.relativeTo,
                    isUserVisible: $0.isUserVisible,
                    affectsCompletion: $0.affectsCompletion,
                    soundRole: $0.soundRole,
                    wakeSessionRole: $0.wakeSessionRole,
                    fajrStartBehavior: $0.fajrStartBehavior
                )
            }
        )

        self.init(
            dateKey: dateKey,
            resolverVersion: try container.decode(Int.self, forKey: .resolverVersion),
            decisionHash: try container.decode(String.self, forKey: .decisionHash),
            prayerWindow: prayerWindow,
            candidateContexts: try container.decode([MorningContextType].self, forKey: .candidateContexts),
            resolvedDayContext: try container.decode(ResolvedDayContext.self, forKey: .resolvedDayContext),
            candidatePlans: try container.decode([RulePlanCandidate].self, forKey: .candidatePlans),
            selectedPlanID: try container.decode(String.self, forKey: .selectedPlanID),
            precedenceReason: try container.decode(String.self, forKey: .precedenceReason),
            resolvedBehaviorProfile: try container.decode(MorningBehaviorProfile.self, forKey: .resolvedBehaviorProfile),
            resolvedAnchor: try container.decode(WakeAnchor.self, forKey: .resolvedAnchor),
            resolvedDelta: try container.decode(WakeDelta.self, forKey: .resolvedDelta),
            candidateWakeTime: try container.decodeIfPresent(Date.self, forKey: .candidateWakeTime) ?? resolvedWakeTime,
            resolvedWakeTime: resolvedWakeTime,
            resolvedWakeState: resolvedWakeState,
            plannedWakeState: plannedWakeState,
            latestWakeCapMinutesFromMidnight: try container.decodeIfPresent(Int.self, forKey: .latestWakeCapMinutesFromMidnight),
            latestWakeCapApplied: try container.decodeIfPresent(Bool.self, forKey: .latestWakeCapApplied) ?? false,
            latestWakeCapShiftedState: try container.decodeIfPresent(Bool.self, forKey: .latestWakeCapShiftedState) ?? false,
            suppressDefaultPrayerPrompt: try container.decodeIfPresent(Bool.self, forKey: .suppressDefaultPrayerPrompt) ?? false,
            resolvedSequenceTemplate: try container.decodeIfPresent(WakeSequenceTemplate.self, forKey: .resolvedSequenceTemplate) ?? fallbackSequence,
            materializedEvents: materializedEvents,
            compatibilityNotes: try container.decodeIfPresent([String].self, forKey: .compatibilityNotes) ?? []
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateKey, forKey: .dateKey)
        try container.encode(resolverVersion, forKey: .resolverVersion)
        try container.encode(decisionHash, forKey: .decisionHash)
        try container.encode(prayerWindow, forKey: .prayerWindow)
        try container.encode(candidateContexts, forKey: .candidateContexts)
        try container.encode(resolvedDayContext, forKey: .resolvedDayContext)
        try container.encode(candidatePlans, forKey: .candidatePlans)
        try container.encode(selectedPlanID, forKey: .selectedPlanID)
        try container.encode(precedenceReason, forKey: .precedenceReason)
        try container.encode(resolvedBehaviorProfile, forKey: .resolvedBehaviorProfile)
        try container.encode(resolvedAnchor, forKey: .resolvedAnchor)
        try container.encode(resolvedDelta, forKey: .resolvedDelta)
        try container.encode(candidateWakeTime, forKey: .candidateWakeTime)
        try container.encode(resolvedWakeTime, forKey: .resolvedWakeTime)
        try container.encode(resolvedWakeState, forKey: .resolvedWakeState)
        try container.encode(plannedWakeState, forKey: .plannedWakeState)
        try container.encodeIfPresent(latestWakeCapMinutesFromMidnight, forKey: .latestWakeCapMinutesFromMidnight)
        try container.encode(latestWakeCapApplied, forKey: .latestWakeCapApplied)
        try container.encode(latestWakeCapShiftedState, forKey: .latestWakeCapShiftedState)
        try container.encode(suppressDefaultPrayerPrompt, forKey: .suppressDefaultPrayerPrompt)
        try container.encode(resolvedSequenceTemplate, forKey: .resolvedSequenceTemplate)
        try container.encode(materializedEvents, forKey: .materializedEvents)
        try container.encode(compatibilityNotes, forKey: .compatibilityNotes)
    }

    private static func classifyWakeState(
        _ wakeTime: Date,
        prayerWindow: DailyPrayerWindow
    ) -> ResolvedWakeState {
        if wakeTime < prayerWindow.fajrStart {
            return .preFajr
        }
        if let fajrEnd = prayerWindow.fajrEnd, wakeTime >= fajrEnd {
            return .postFajr
        }
        return .inFajr
    }

    private static func fallbackPlannedWakeState(for resolvedWakeState: ResolvedWakeState) -> MorningWakeRuleState {
        switch resolvedWakeState {
        case .preFajr:
            return .preFajr
        case .inFajr:
            return .inFajr
        case .postFajr:
            return .postFajr
        }
    }
}

extension ScheduledEventType {
    var defaultVisibility: Bool {
        switch self {
        case .wakeReminder, .wakeAlarm, .wakeFollowUp, .fajrBoundaryNotice, .iftarReminder:
            return true
        }
    }

    var defaultCompletionBehavior: Bool {
        switch self {
        case .wakeAlarm:
            return true
        case .wakeReminder, .wakeFollowUp, .fajrBoundaryNotice, .iftarReminder:
            return false
        }
    }
}

extension RuleDecisionLog {
    static func compatibilityFallback(
        dateKey: String,
        schedule: DaySchedule,
        resolvedDayContext: ResolvedDayContext,
        primaryDisplay: PrimaryDisplay?
    ) -> RuleDecisionLog {
        let anchor = WakeAnchor(type: .fajrStart, date: schedule.fajrDate, providerNotes: "compatibility_fallback")
        let delta = WakeDelta(
            relation: schedule.wakeDate <= schedule.fajrDate ? .before : .after,
            minutes: Int(round(abs(schedule.fajrDate.timeIntervalSince(schedule.wakeDate)) / 60))
        )

        var events: [ScheduledEvent] = [
            ScheduledEvent(
                id: "\(dateKey).wakeAlarm",
                type: .wakeAlarm,
                dateKey: dateKey,
                fireDate: schedule.wakeDate,
                relativeTo: .wakeAnchor(type: .fajrStart, offsetMinutes: delta.signedMinutes),
                isUserVisible: true,
                affectsCompletion: true,
                deliveryKinds: [.wake]
            )
        ]

        if let reminderDate = schedule.reminderDate {
            let offset = Int(round(reminderDate.timeIntervalSince(schedule.fajrDate) / 60))
            events.append(
                ScheduledEvent(
                    id: "\(dateKey).wakeReminder",
                    type: .wakeReminder,
                    dateKey: dateKey,
                    fireDate: reminderDate,
                    relativeTo: .prayerBoundary(boundary: .fajrStart, offsetMinutes: offset),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.reminder]
                )
            )
        }

        if let boundaryDate = schedule.boundaryDate {
            events.append(
                ScheduledEvent(
                    id: "\(dateKey).fajrBoundaryNotice",
                    type: .fajrBoundaryNotice,
                    dateKey: dateKey,
                    fireDate: boundaryDate,
                    relativeTo: .prayerBoundary(boundary: .fajrStart, offsetMinutes: 0),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.boundary]
                )
            )
        }

        if let iftarDate = schedule.iftarDate {
            events.append(
                ScheduledEvent(
                    id: "\(dateKey).iftarReminder",
                    type: .iftarReminder,
                    dateKey: dateKey,
                    fireDate: iftarDate,
                    relativeTo: .prayerBoundary(boundary: .maghrib, offsetMinutes: 0),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.iftarNotification]
                )
            )
        }

        events.sort { $0.fireDate < $1.fireDate }
        let sequence = WakeSequenceTemplate(
            id: "\(dateKey).compatibility-sequence",
            name: "Compatibility sequence",
            steps: events.map {
                WakeSequenceStep(
                    eventType: $0.type,
                    relativeTo: $0.relativeTo,
                    isUserVisible: $0.isUserVisible,
                    affectsCompletion: $0.affectsCompletion,
                    soundRole: $0.soundRole,
                    wakeSessionRole: $0.wakeSessionRole,
                    fajrStartBehavior: $0.fajrStartBehavior
                )
            }
        )

        return RuleDecisionLog(
            dateKey: dateKey,
            resolverVersion: 0,
            decisionHash: "\(dateKey)|compatibility_fallback|\(schedule.wakeDate.timeIntervalSince1970)",
            prayerWindow: DailyPrayerWindow(
                date: schedule.date,
                fajrStart: schedule.fajrDate,
                fajrEnd: nil,
                maghrib: schedule.maghribDate
            ),
            candidateContexts: [resolvedDayContext.primaryContext],
            resolvedDayContext: resolvedDayContext,
            candidatePlans: [
                RulePlanCandidate(
                    id: "compatibility-fallback",
                    title: "Compatibility fallback",
                    kind: .defaultDaily
                )
            ],
            selectedPlanID: "compatibility-fallback",
            precedenceReason: "Recovered from a cached compatibility snapshot.",
            resolvedBehaviorProfile: MorningBehaviorProfile(
                wakeAnchorType: .fajrStart,
                wakeDelta: delta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: primaryDisplay?.kind == .suhoor ? DateHelpers.minutesFromMidnight(for: schedule.wakeDate, timeZone: scheduleTimeZone(schedule)) : nil,
                reminderEnabled: schedule.reminderDate != nil,
                wakeAlarmEnabled: true,
                wakeFollowUpEnabled: false,
                fajrBoundaryNoticeEnabled: schedule.boundaryDate != nil,
                iftarReminderEnabled: schedule.iftarDate != nil
            ),
            resolvedAnchor: anchor,
            resolvedDelta: delta,
            candidateWakeTime: schedule.wakeDate,
            resolvedWakeTime: schedule.wakeDate,
            resolvedWakeState: schedule.wakeDate < schedule.fajrDate ? .preFajr : .inFajr,
            plannedWakeState: .preFajr,
            latestWakeCapMinutesFromMidnight: nil,
            latestWakeCapApplied: false,
            latestWakeCapShiftedState: false,
            suppressDefaultPrayerPrompt: false,
            resolvedSequenceTemplate: sequence,
            materializedEvents: events,
            compatibilityNotes: ["cache_compatibility_fallback"]
        )
    }

    private static func scheduleTimeZone(_ schedule: DaySchedule) -> TimeZone {
        TimeZone.current
    }
}
