import Foundation

enum HomeSupportCardKind: Equatable, Sendable {
    case blockingIssue
    case fajrCompletion
    case forbiddenFast
    case fasting
}

enum HomeSupportCardPhase: Equatable, Sendable {
    case blockingIssue
    case fajrCompletionPrompt
    case forbiddenFastNotice
    case fastingStatusPrompt
    case fastingInProgress
    case fastCompletionPrompt
    case fastCompletionLogged
}

struct FajrHomeSupportPresentation: Equatable, Sendable {
    let dateKey: String
    let title: String
    let detail: String
}

struct FastingHomeSupportPresentation: Equatable, Sendable {
    let phase: HomeSupportCardPhase
    let dateKey: String
    let intentSnapshot: FastIntentSnapshot
    let title: String
    let detail: String
    let primaryActionTitle: String?
    let secondaryActionTitle: String?
    let statusTitle: String?
    let showsUndo: Bool
}

enum HomeSupportCardPresentation: Equatable, Sendable {
    case blockingIssue(AppPermissionKind)
    case fajrCompletionPrompt(FajrHomeSupportPresentation)
    case forbiddenFastNotice(FastWarning)
    case fasting(FastingHomeSupportPresentation)

    var kind: HomeSupportCardKind {
        switch self {
        case .blockingIssue:
            return .blockingIssue
        case .fajrCompletionPrompt:
            return .fajrCompletion
        case .forbiddenFastNotice:
            return .forbiddenFast
        case .fasting:
            return .fasting
        }
    }

    var phase: HomeSupportCardPhase {
        switch self {
        case .blockingIssue:
            return .blockingIssue
        case .fajrCompletionPrompt:
            return .fajrCompletionPrompt
        case .forbiddenFastNotice:
            return .forbiddenFastNotice
        case .fasting(let presentation):
            return presentation.phase
        }
    }
}

struct ConfiguredPlanItem: Identifiable, Equatable, Sendable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
}

struct ConfiguredPlansSnapshot: Equatable, Sendable {
    let upcomingSpecialMornings: [ConfiguredPlanItem]
    let additionalSpecialMorningCount: Int
    let qadaSummary: String

    var hasUpcomingSpecialMornings: Bool {
        !upcomingSpecialMornings.isEmpty
    }
}

struct ScheduleRowPresentation: Equatable, Sendable {
    let wakeTime: Date
    let relationText: String
    let primaryContextTitle: String
    let secondaryContextTitles: [String]
    let provenanceText: String?
}

struct WakeProgressSnapshot: Equatable, Sendable {
    let summaryTitle: String?
    let summaryDetail: String?
    let recentActivityLines: [String]
    let emptyStateText: String?

    static let empty = WakeProgressSnapshot(
        summaryTitle: nil,
        summaryDetail: nil,
        recentActivityLines: [],
        emptyStateText: "Wake activity appears after a few mornings."
    )
}

protocol WakeProgressSource {
    func snapshot(limit: Int) -> WakeProgressSnapshot
}

struct DebugEventLogWakeProgressSource: WakeProgressSource {
    let log: DebugEventLog

    init(log: DebugEventLog = .shared) {
        self.log = log
    }

    func snapshot(limit: Int) -> WakeProgressSnapshot {
        ProductSurfacePresentation.wakeProgressSnapshot(from: log.events(limit: limit))
    }
}

enum ProductSurfacePresentation {
    static func primaryContextTitle(_ context: MorningContextType) -> String {
        switch context {
        case .standard:
            return "Daily plan"
        default:
            return context.title
        }
    }

    static func meaningfulSecondaryContextTitles(
        from resolvedDayContext: ResolvedDayContext,
        limit: Int = 2
    ) -> [String] {
        var seen = Set<String>([resolvedDayContext.primaryContext.rawValue])
        var titles: [String] = []

        for context in resolvedDayContext.secondaryContexts {
            guard context != .standard else { continue }
            guard seen.insert(context.rawValue).inserted else { continue }
            titles.append(context.title)
            if titles.count == limit {
                break
            }
        }

        return titles
    }

    static func wakeRelationText(delta: WakeDelta, anchor: WakeAnchorType) -> String {
        let anchorTitle: String
        switch anchor {
        case .fajrStart:
            anchorTitle = "Fajr"
        case .fajrEnd:
            anchorTitle = "Fajr ends"
        case .masjidFajr:
            anchorTitle = "masjid Fajr"
        }

        if delta.minutes == 0 {
            return "At \(anchorTitle)"
        }

        let unit = delta.minutes == 1 ? "minute" : "minutes"
        switch delta.relation {
        case .before:
            return "\(delta.minutes) \(unit) before \(anchorTitle)"
        case .after:
            return "\(delta.minutes) \(unit) after \(anchorTitle)"
        }
    }

    static func configuredPlansSnapshot(
        upcomingDays: [ActiveAlarmDay],
        overrideDateKeys: Set<String>,
        qadaProgress: QadaProgressSnapshot,
        limit: Int = 3
    ) -> ConfiguredPlansSnapshot {
        let specialMornings = upcomingDays.filter { day in
            isConfiguredSpecialMorning(day: day, overrideDateKeys: overrideDateKeys)
        }

        let items = specialMornings.prefix(limit).map { day in
            configuredPlanItem(for: day, hasOverride: overrideDateKeys.contains(day.dateKey))
        }

        let qadaSummary: String
        if qadaProgress.baselineOwed > 0 {
            qadaSummary = "\(qadaProgress.completed) completed · \(qadaProgress.remaining) remaining"
        } else {
            qadaSummary = "No Qada tracked"
        }

        return ConfiguredPlansSnapshot(
            upcomingSpecialMornings: Array(items),
            additionalSpecialMorningCount: max(0, specialMornings.count - items.count),
            qadaSummary: qadaSummary
        )
    }

    static func scheduleRowPresentation(
        for day: ActiveAlarmDay,
        hasDayOverride: Bool
    ) -> ScheduleRowPresentation {
        let secondaryContextTitles = meaningfulSecondaryContextTitles(from: day.resolvedDayContext)
        let nonDefaultProvenances = day.provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        let provenanceText: String?
        if hasDayOverride && nonDefaultProvenances.isEmpty {
            provenanceText = "Adjusted"
        } else if nonDefaultProvenances.isEmpty {
            provenanceText = nil
        } else {
            let labels = Array(NSOrderedSet(array: nonDefaultProvenances.map(\.label))).compactMap { $0 as? String }
            provenanceText = labels.joined(separator: " • ")
        }

        return ScheduleRowPresentation(
            wakeTime: day.schedule.wakeDate,
            relationText: wakeRelationText(
                delta: day.decisionLog.resolvedDelta,
                anchor: day.decisionLog.resolvedAnchor.type
            ),
            primaryContextTitle: primaryContextTitle(day.resolvedDayContext.primaryContext),
            secondaryContextTitles: secondaryContextTitles,
            provenanceText: provenanceText
        )
    }

    static func wakeProgressSnapshot(from events: [DebugEvent]) -> WakeProgressSnapshot {
        let wakeEvents = events.filter {
            switch $0.type {
            case .scheduledSuhoor, .firedSuhoor, .dismissedSuhoor, .snoozedSuhoor, .scheduledSuhoorSnooze:
                return true
            default:
                return false
            }
        }

        guard !wakeEvents.isEmpty else {
            return .empty
        }

        let firedCount = wakeEvents.filter { $0.type == .firedSuhoor }.count
        let dismissedCount = wakeEvents.filter { $0.type == .dismissedSuhoor }.count
        let snoozedCount = wakeEvents.filter { $0.type == .snoozedSuhoor || $0.type == .scheduledSuhoorSnooze }.count

        let summaryTitle = firedCount > 0
            ? "\(firedCount) recent wake event\(firedCount == 1 ? "" : "s")"
            : "Wake activity"

        var detailParts: [String] = []
        if dismissedCount > 0 {
            detailParts.append("\(dismissedCount) dismissed")
        }
        if snoozedCount > 0 {
            detailParts.append("\(snoozedCount) follow-ups or snoozes")
        }

        return WakeProgressSnapshot(
            summaryTitle: summaryTitle,
            summaryDetail: detailParts.isEmpty ? "From recent wake events." : detailParts.joined(separator: " · "),
            recentActivityLines: Array(wakeEvents.prefix(4)).map(formatWakeEventLine),
            emptyStateText: nil
        )
    }

    private static func isConfiguredSpecialMorning(
        day: ActiveAlarmDay,
        overrideDateKeys: Set<String>
    ) -> Bool {
        if overrideDateKeys.contains(day.dateKey) {
            return true
        }

        if day.resolvedDayContext.primaryContext != .standard {
            return true
        }

        if meaningfulSecondaryContextTitles(from: day.resolvedDayContext).isEmpty == false {
            return true
        }

        if day.provenances.contains(where: { $0.sourceOrigin != .defaultDailyPlan }) {
            return true
        }

        return day.resolvedDayContext.supportingTags.contains {
            $0 != .dailyPlan && $0 != .locationBased
        }
    }

    private static func configuredPlanItem(
        for day: ActiveAlarmDay,
        hasOverride: Bool
    ) -> ConfiguredPlanItem {
        let nonDefaultProvenances = day.provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        let provenanceLabels = Array(NSOrderedSet(array: nonDefaultProvenances.map(\.label))).compactMap { $0 as? String }
        let primaryTitle = primaryContextTitle(day.resolvedDayContext.primaryContext)

        let title: String
        if hasOverride && nonDefaultProvenances.isEmpty && day.resolvedDayContext.primaryContext == .standard {
            title = "Adjusted morning"
        } else if day.resolvedDayContext.primaryContext != .standard {
            title = primaryTitle
        } else if let firstProvenance = provenanceLabels.first {
            title = firstProvenance
        } else if let firstTag = day.resolvedDayContext.supportingTags.first(where: { $0 != .dailyPlan && $0 != .locationBased }) {
            title = firstTag.title
        } else {
            title = "Planned morning"
        }

        var subtitleParts = [
            AlarmRowPresentation.dateLabel(for: day.date),
            wakeRelationText(delta: day.decisionLog.resolvedDelta, anchor: day.decisionLog.resolvedAnchor.type)
        ]

        if hasOverride && nonDefaultProvenances.isEmpty {
            subtitleParts.append("Adjusted")
        } else if let firstProvenance = provenanceLabels.first {
            subtitleParts.append(firstProvenance)
        }

        return ConfiguredPlanItem(
            id: day.dateKey,
            date: day.date,
            title: title,
            subtitle: subtitleParts.joined(separator: " • ")
        )
    }

    private static func formatWakeEventLine(_ event: DebugEvent) -> String {
        let formatter = TimeFormatters.shortDateTime
        let prefix: String
        switch event.type {
        case .scheduledSuhoor:
            prefix = "Scheduled"
        case .firedSuhoor:
            prefix = "Wake fired"
        case .dismissedSuhoor:
            prefix = "Wake dismissed"
        case .snoozedSuhoor:
            prefix = "Wake snoozed"
        case .scheduledSuhoorSnooze:
            prefix = "Follow-up scheduled"
        default:
            prefix = "Wake activity"
        }
        return "\(prefix) · \(formatter.string(from: event.timestamp))"
    }
}
