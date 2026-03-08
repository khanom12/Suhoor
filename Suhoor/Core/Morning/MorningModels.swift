import Foundation

enum MorningContextType: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case tahajjud
    case suhoor
    case fasting
    case qadaFast
    case sunnahFast
    case jamaah
    case specialDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .tahajjud:
            return "Tahajjud"
        case .suhoor:
            return "Suhoor"
        case .fasting:
            return "Fasting"
        case .qadaFast:
            return "Qada"
        case .sunnahFast:
            return "Sunnah"
        case .jamaah:
            return "Jama'ah"
        case .specialDay:
            return "Special day"
        }
    }
}

enum DayTag: String, Codable, CaseIterable, Identifiable, Sendable {
    case dailyPlan
    case manualDay
    case manualRange
    case ramadan
    case qada
    case kaffarah
    case vow
    case voluntary
    case shawwalSix
    case arafah
    case ashura
    case whiteDays
    case mondayThursday
    case dhulHijjahFirstNine
    case eid
    case tashreeq
    case locationBased
    case fixedTimeCompatibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyPlan:
            return "Daily plan"
        case .manualDay:
            return "Manual day"
        case .manualRange:
            return "Manual range"
        case .ramadan:
            return "Ramadan"
        case .qada:
            return "Qada"
        case .kaffarah:
            return "Kaffarah"
        case .vow:
            return "Vow"
        case .voluntary:
            return "Voluntary"
        case .shawwalSix:
            return "Shawwal 6"
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .whiteDays:
            return "White Days"
        case .mondayThursday:
            return "Monday & Thursday"
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah"
        case .eid:
            return "Eid"
        case .tashreeq:
            return "Tashreeq"
        case .locationBased:
            return "Location-based"
        case .fixedTimeCompatibility:
            return "Fixed wake compatibility"
        }
    }
}

struct ContextExplanation: Codable, Equatable, Hashable, Sendable {
    let summary: String
    let details: [String]

    static let empty = ContextExplanation(summary: "", details: [])
}

struct ResolvedDayContext: Codable, Equatable, Hashable, Sendable {
    let primaryContext: MorningContextType
    let secondaryContexts: [MorningContextType]
    let supportingTags: [DayTag]
    let explanation: ContextExplanation

    static let standard = ResolvedDayContext(
        primaryContext: .standard,
        secondaryContexts: [],
        supportingTags: [],
        explanation: ContextExplanation(
            summary: "Using the default morning plan.",
            details: []
        )
    )
}

enum WakeAnchorType: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrStart
    case fajrEnd
    case masjidFajr

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

struct DailyPrayerWindow: Codable, Equatable, Hashable, Sendable {
    let date: Date
    let fajrStart: Date
    let fajrEnd: Date?
    let maghrib: Date
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
            return "Wake Follow-Up"
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
}

struct WakeSequenceStep: Codable, Equatable, Hashable, Sendable {
    let eventType: ScheduledEventType
    let relativeTo: ScheduledEventRelativeReference
    let isUserVisible: Bool
    let affectsCompletion: Bool
}

struct WakeSequenceTemplate: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let steps: [WakeSequenceStep]
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
    let wakeAnchorType: WakeAnchorType
    let wakeDelta: WakeDelta
    let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?
    let reminderEnabled: Bool
    let wakeAlarmEnabled: Bool
    let fajrBoundaryNoticeEnabled: Bool
    let iftarReminderEnabled: Bool
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
    let resolvedWakeTime: Date
    let resolvedSequenceTemplate: WakeSequenceTemplate
    let materializedEvents: [ScheduledEvent]
    let compatibilityNotes: [String]
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
                    affectsCompletion: $0.affectsCompletion
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
            resolvedWakeTime: schedule.wakeDate,
            resolvedSequenceTemplate: sequence,
            materializedEvents: events,
            compatibilityNotes: ["cache_compatibility_fallback"]
        )
    }

    private static func scheduleTimeZone(_ schedule: DaySchedule) -> TimeZone {
        TimeZone.current
    }
}
