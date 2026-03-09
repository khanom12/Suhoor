import Foundation

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
