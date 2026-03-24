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

    var dismissalKey: String? {
        switch self {
        case .blockingIssue, .forbiddenFastNotice:
            return nil
        case .fajrCompletionPrompt(let presentation):
            return "fajr-\(presentation.dateKey)"
        case .fasting(let presentation):
            return "fast-\(presentation.dateKey)-\(presentation.phase)"
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
    let meaningText: String
    let availability: WakeAvailabilityPresentation
    let stateLabel: String
    let secondaryExplanation: String?
    let detailText: String
    let chipTitles: [String]
    let provenanceText: String?
}

enum WakeAvailabilityState: Equatable, Sendable {
    case activeDefault
    case activeOverride
    case skipped
}

struct WakeAvailabilityPresentation: Equatable, Sendable {
    let state: WakeAvailabilityState
    let availabilityLabel: String
    let statusSummary: String
    let statusDetail: String
}

struct WakeReasonRow: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
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
        emptyStateText: "Wake follow-through appears after a few mornings."
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
            return ordinaryDaySummaryText
        default:
            return context.title
        }
    }

    static let ordinaryDaySummaryText = "Ordinary Fajr day"

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

    static func homeContextSummaryText(
        for day: ActiveAlarmDay,
        dayLabel: String?
    ) -> String {
        let meaning = dayMeaningText(for: day, style: .homeContext)
        if let dayLabel, !dayLabel.isEmpty {
            return "\(dayLabel) • \(meaning)"
        }
        return meaning
    }

    static func homeHeroMeaningText(for day: ActiveAlarmDay) -> String? {
        let resolved = day.resolvedDayContext
        let tags = Set(resolved.supportingTags)

        if resolved.primaryContext == .standard && meaningfulSecondaryContextTitles(from: resolved).isEmpty {
            return nil
        }

        if resolved.primaryContext == .qadaFast || tags.contains(.qada) {
            return "Qada planned"
        }
        if resolved.primaryContext == .tahajjud {
            return "Tahajjud planned"
        }
        if let observance = observanceTitle(from: resolved) {
            return observance
        }
        if tags.contains(.ramadan) {
            return "Ramadan fast"
        }
        if resolved.primaryContext == .sunnahFast {
            return "Sunnah fast"
        }
        if resolved.primaryContext == .fasting || resolved.primaryContext == .suhoor {
            return "Fasting tomorrow"
        }

        return dayMeaningText(for: day, style: .homeContext)
    }

    static func homeHeroLabel(for day: ActiveAlarmDay) -> String {
        "Tomorrow's wake"
    }

    static func homeHeroPresentation(for day: ActiveAlarmDay) -> HomeHeroPresentation {
        HomeHeroPresentation(
            label: homeHeroLabel(for: day),
            meaningText: homeHeroMeaningText(for: day),
            stateText: wakeStateLabel(for: day),
            timingText: homeHeroTimingText(for: day),
            secondaryText: homeHeroSecondaryText(for: day)
        )
    }

    static func homeHeroSubline(for day: ActiveAlarmDay) -> String {
        var parts: [String] = []
        if let meaning = homeHeroMeaningText(for: day) {
            parts.append(meaning)
        }
        parts.append(wakeStateLabel(for: day))
        parts.append(homeHeroTimingText(for: day))
        if let secondary = homeHeroSecondaryText(for: day) {
            parts.append(secondary)
        }
        return parts.joined(separator: " • ")
    }

    static func scheduleChipTitles(
        for day: ActiveAlarmDay,
        hasDayOverride: Bool,
        limit: Int = 3
    ) -> [String] {
        var titles: [String] = []
        let resolved = day.resolvedDayContext
        let tags = Set(resolved.supportingTags)

        if resolved.primaryContext == .qadaFast || tags.contains(.qada) {
            titles.append("Qada")
        } else if tags.contains(.ramadan)
            || resolved.primaryContext == .fasting
            || resolved.primaryContext == .suhoor
            || resolved.primaryContext == .sunnahFast {
            titles.append("Fasting")
        }

        if resolved.primaryContext == .tahajjud || day.effectiveConfig.tahajjudRefinement {
            titles.append("Tahajjud")
        }

        if day.decisionLog.latestWakeCapApplied {
            titles.append("Cap applied")
        }

        if day.effectiveConfig.skipDay {
            titles.append("Skipped")
        } else if day.decisionLog.plannedWakeState == .fixedWake {
            titles.append("Fixed wake")
        } else if day.decisionLog.plannedWakeState == .postFajr {
            titles.append("After Fajr")
        } else if hasDayOverride {
            titles.append("Changed")
        }

        return Array(NSOrderedSet(array: titles).array.prefix(limit)).compactMap { $0 as? String }
    }

    static func dayMeaningText(
        for day: ActiveAlarmDay,
        style: DayMeaningStyle
    ) -> String {
        let resolved = day.resolvedDayContext
        let tags = Set(resolved.supportingTags)

        if resolved.primaryContext == .qadaFast || tags.contains(.qada) {
            return style == .wakeRow ? "Qada planned" : "Qada fast"
        }
        if tags.contains(.ramadan) {
            return "Ramadan fast"
        }
        if let observance = observanceTitle(from: resolved) {
            return observance
        }
        switch resolved.primaryContext {
        case .standard:
            return ordinaryDaySummaryText
        case .tahajjud:
            return "Tahajjud planned"
        case .suhoor, .fasting:
            return style == .history ? "Fasting day" : "Fasting tomorrow"
        case .sunnahFast:
            return "Sunnah fast"
        case .jamaah:
            return "Jama'ah morning"
        case .specialDay:
            return "A meaningful day is coming up"
        case .qadaFast:
            return style == .wakeRow ? "Qada planned" : "Qada fast"
        }
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
        case .clockTime:
            return "Fixed wake"
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

    static func wakeListTimingText(for day: ActiveAlarmDay) -> String {
        if day.effectiveConfig.skipDay {
            return "No wake for this date"
        }
        if day.decisionLog.plannedWakeState == .fixedWake {
            return "Ignores latest wake"
        }
        if day.decisionLog.plannedWakeState == .postFajr {
            return "One-day exception"
        }
        return wakeOffsetText(for: day)
    }

    static func wakeAvailabilityPresentation(
        for day: ActiveAlarmDay,
        hasCustomChange: Bool
    ) -> WakeAvailabilityPresentation {
        if day.effectiveConfig.skipDay {
            return WakeAvailabilityPresentation(
                state: .skipped,
                availabilityLabel: "Skipped",
                statusSummary: "Morning off for this date",
                statusDetail: "This date won't wake or play supporting morning cues."
            )
        }

        if hasCustomChange {
            return WakeAvailabilityPresentation(
                state: .activeOverride,
                availabilityLabel: "Changed for this date",
                statusSummary: "Uses a one-day wake change",
                statusDetail: "This date has its own wake change."
            )
        }

        return WakeAvailabilityPresentation(
            state: .activeDefault,
            availabilityLabel: "Default morning",
            statusSummary: "Uses your default morning plan",
            statusDetail: "This date uses your usual morning plan."
        )
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
        let availability = wakeAvailabilityPresentation(for: day, hasCustomChange: hasDayOverride)
        let nonDefaultProvenances = day.provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        let provenanceText: String?
        if nonDefaultProvenances.isEmpty || day.resolvedDayContext.primaryContext != .standard {
            provenanceText = nil
        } else {
            let labels = Array(NSOrderedSet(array: nonDefaultProvenances.map(\.label))).compactMap { $0 as? String }
            provenanceText = labels.joined(separator: " • ")
        }

        return ScheduleRowPresentation(
            wakeTime: day.schedule.wakeDate,
            meaningText: dayMeaningText(for: day, style: .wakeRow),
            availability: availability,
            stateLabel: availability.state == .skipped ? availability.availabilityLabel : wakeStateLabel(for: day),
            secondaryExplanation: scheduleSecondaryExplanation(for: day, hasDayOverride: hasDayOverride),
            detailText: wakeListTimingText(for: day),
            chipTitles: scheduleChipTitles(for: day, hasDayOverride: hasDayOverride),
            provenanceText: provenanceText
        )
    }

    static func defaultWakeTimingText(for defaults: DefaultAlarmConfig) -> String {
        switch defaults.defaultWakeState {
        case .preFajr:
            return "Before Fajr"
        case .inFajr:
            return "During Fajr"
        }
    }

    static func defaultWakeAnchorText(for defaults: DefaultAlarmConfig) -> String {
        switch defaults.defaultWakeState {
        case .preFajr:
            return "From Fajr start"
        case .inFajr:
            return defaults.normalizedDefaultWakeAnchorType == .fajrEnd
                ? "From Fajr end"
                : "From Fajr start"
        }
    }

    static func defaultWakeOffsetText(for defaults: DefaultAlarmConfig) -> String {
        wakeOffsetText(
            state: defaults.defaultWakeState == .preFajr ? .preFajr : .inFajr,
            anchor: defaults.normalizedDefaultWakeAnchorType,
            deltaMinutes: defaults.defaultWakeDeltaMinutes,
            fixedTimeMinutes: nil
        )
    }

    static func defaultReserveSummaryText(
        defaults: DefaultAlarmConfig,
        settings: AppSettings
    ) -> String {
        guard defaults.defaultWakeState == .inFajr,
              defaults.normalizedDefaultWakeAnchorType == .fajrStart else {
            return "Not needed"
        }
        return "\(settings.clampedReserveBeforeEndMinutes) min"
    }

    static func latestWakeSummaryText(minutesFromMidnight: Int?) -> String {
        guard let minutesFromMidnight else { return "Off" }
        return "Never after \(SettingsSummaryFormatter.timeText(minutesFromMidnight: minutesFromMidnight))"
    }

    static func defaultFastingCueSummaryText(
        defaults: DefaultAlarmConfig,
        settings _: AppSettings
    ) -> String {
        var parts: [String] = []
        if defaults.fastingReminderEnabledDefault && defaults.reminderEnabledDefault {
            parts.append("Reminder")
        }
        if defaults.defaultWakeState == .preFajr && defaults.fajrEnabledDefault {
            parts.append("Fajr cue")
        }
        return parts.isEmpty ? "No extra cues" : parts.joined(separator: " + ")
    }

    static func soundSummaryText(settings: AppSettings) -> String {
        let defaultSettings = AppSettings.default
        let isCustom = settings.preFajrWakeSoundSelectionGlobal != defaultSettings.preFajrWakeSoundSelectionGlobal
            || settings.fajrStartSoundSelectionGlobal != defaultSettings.fajrStartSoundSelectionGlobal
            || settings.inFajrWakeSoundSelectionGlobal != defaultSettings.inFajrWakeSoundSelectionGlobal
            || settings.postFajrWakeSoundSelectionGlobal != defaultSettings.postFajrWakeSoundSelectionGlobal
            || settings.fixedWakeSoundSelectionGlobal != defaultSettings.fixedWakeSoundSelectionGlobal
        return isCustom ? "Custom" : "Default"
    }

    static func wakeStateLabel(for day: ActiveAlarmDay) -> String {
        if day.effectiveConfig.skipDay {
            return "Skipped"
        }
        if day.decisionLog.plannedWakeState == .fixedWake {
            return "Fixed wake"
        }
        switch day.decisionLog.resolvedWakeState {
        case .preFajr:
            return "Before Fajr"
        case .inFajr:
            return "During Fajr"
        case .postFajr:
            return "After Fajr"
        }
    }

    static func wakeOffsetText(
        state: MorningWakeRuleState,
        anchor: WakeAnchorType,
        deltaMinutes: Int,
        fixedTimeMinutes: Int?
    ) -> String {
        switch state {
        case .preFajr:
            return deltaMinutes == 1 ? "1 min before Fajr" : "\(deltaMinutes) min before Fajr"
        case .inFajr:
            if anchor == .fajrEnd {
                return deltaMinutes == 1 ? "1 min before Fajr ends" : "\(deltaMinutes) min before Fajr ends"
            }
            return deltaMinutes == 1 ? "1 min after Fajr begins" : "\(deltaMinutes) min after Fajr begins"
        case .postFajr:
            return deltaMinutes == 1 ? "1 min after Fajr ends" : "\(deltaMinutes) min after Fajr ends"
        case .fixedWake:
            guard let fixedTimeMinutes else { return "Fixed wake" }
            return SettingsSummaryFormatter.timeText(minutesFromMidnight: fixedTimeMinutes)
        }
    }

    static func homeHeroTimingText(for day: ActiveAlarmDay) -> String {
        if day.decisionLog.plannedWakeState == .fixedWake {
            return "Set for \(TimeFormatters.timeFormatter.string(from: day.decisionLog.resolvedWakeTime))"
        }
        return wakeOffsetText(for: day)
    }

    static func homeHeroSecondaryText(for day: ActiveAlarmDay) -> String? {
        let availability = wakeAvailabilityPresentation(
            for: day,
            hasCustomChange: day.effectiveConfig.hasOverrides
        )
        if day.decisionLog.latestWakeCapApplied {
            return "Moved earlier by your latest wake"
        }
        if day.decisionLog.plannedWakeState == .fixedWake {
            return "Fixed wake for this date"
        }
        if day.decisionLog.plannedWakeState == .postFajr {
            return "After-Fajr exception for this date"
        }
        if availability.state == .activeOverride {
            return availability.availabilityLabel
        }
        return nil
    }

    static func wakeOffsetText(for day: ActiveAlarmDay) -> String {
        let decision = day.decisionLog
        return wakeOffsetText(
            state: decision.plannedWakeState,
            anchor: decision.resolvedAnchor.type,
            deltaMinutes: decision.resolvedDelta.minutes,
            fixedTimeMinutes: decision.plannedWakeState == .fixedWake
                ? DateHelpers.minutesFromMidnight(for: decision.resolvedWakeTime, timeZone: .current)
                : nil
        )
    }

    static func scheduleSecondaryExplanation(
        for day: ActiveAlarmDay,
        hasDayOverride: Bool
    ) -> String? {
        let availability = wakeAvailabilityPresentation(for: day, hasCustomChange: hasDayOverride)
        if day.decisionLog.latestWakeCapApplied {
            return "Limited by your latest wake"
        }
        if availability.state == .skipped {
            return nil
        }
        if day.decisionLog.plannedWakeState == .fixedWake && hasDayOverride {
            return "Fixed wake for this date"
        }
        if day.decisionLog.plannedWakeState == .postFajr && hasDayOverride {
            return "After-Fajr exception"
        }
        if availability.state == .activeOverride {
            return availability.availabilityLabel
        }
        return nil
    }

    static func wakeExplanationText(
        for day: ActiveAlarmDay,
        hasDayOverride: Bool
    ) -> String {
        let availability = wakeAvailabilityPresentation(for: day, hasCustomChange: hasDayOverride)
        let decision = day.decisionLog
        let stateText = wakeOffsetText(for: day)

        if availability.state == .skipped {
            return availability.statusSummary
        }

        if decision.latestWakeCapApplied,
           let cap = decision.latestWakeCapMinutesFromMidnight {
            return "\(stateText) · latest wake \(SettingsSummaryFormatter.timeText(minutesFromMidnight: cap))"
        }

        if hasDayOverride && decision.plannedWakeState == .fixedWake {
            return "Fixed wake override"
        }
        if hasDayOverride && decision.plannedWakeState == .postFajr {
            return "Post-Fajr override"
        }
        if hasDayOverride {
            return "\(stateText) · \(availability.availabilityLabel)"
        }

        return stateText
    }

    static func wakeReasonRows(
        for day: ActiveAlarmDay,
        hasDayOverride: Bool
    ) -> [WakeReasonRow] {
        let availability = wakeAvailabilityPresentation(for: day, hasCustomChange: hasDayOverride)
        var rows: [WakeReasonRow] = []

        if availability.state != .activeDefault {
            rows.append(
                WakeReasonRow(
                    id: "availability",
                    title: "This morning",
                    detail: availability.statusSummary
                )
            )
        }

        rows.append(
            WakeReasonRow(
                id: "default-plan",
                title: "Default plan",
                detail: "\(defaultPlanTitle(for: day)), \(defaultPlanWakeText(for: day))"
            )
        )

        if let latestWakeCap = day.decisionLog.latestWakeCapMinutesFromMidnight {
            rows.append(
                WakeReasonRow(
                    id: "latest-wake",
                    title: "Latest wake limit",
                    detail: "Never after \(SettingsSummaryFormatter.timeText(minutesFromMidnight: latestWakeCap))"
                )
            )
        }

        if day.decisionLog.latestWakeCapApplied {
            rows.append(
                WakeReasonRow(
                    id: "cap-applied",
                    title: "Cap applied",
                    detail: "Today's Fajr-based wake would have landed later, so it moved earlier."
                )
            )
        }

        let resolved = day.resolvedDayContext
        let tags = Set(resolved.supportingTags)
        if tags.contains(.qada) || resolved.primaryContext == .qadaFast {
            rows.append(WakeReasonRow(id: "qada", title: "Qada", detail: "Counts toward what remains."))
        } else if tags.contains(.ramadan)
            || resolved.primaryContext == .fasting
            || resolved.primaryContext == .suhoor
            || resolved.primaryContext == .sunnahFast {
            rows.append(WakeReasonRow(id: "fasting", title: "Fasting", detail: "This date is planned as a fast."))
        }

        if resolved.primaryContext == .tahajjud || day.effectiveConfig.tahajjudRefinement {
            rows.append(WakeReasonRow(id: "tahajjud", title: "Tahajjud", detail: "This date includes Tahajjud refinement."))
        }

        if hasDayOverride && day.decisionLog.plannedWakeState == .postFajr {
            rows.append(
                WakeReasonRow(
                    id: "after-fajr",
                    title: "Wake change",
                    detail: "This date was changed to after Fajr."
                )
            )
        }

        if hasDayOverride && day.decisionLog.plannedWakeState == .fixedWake {
            rows.append(
                WakeReasonRow(
                    id: "fixed",
                    title: "Fixed wake",
                    detail: "This date uses \(TimeFormatters.timeFormatter.string(from: day.decisionLog.resolvedWakeTime))."
                )
            )
        }

        return rows
    }

    static func wakeSourceSummaryText(for day: ActiveAlarmDay) -> String {
        if day.sourceSummaryText.isEmpty == false {
            return day.sourceSummaryText
        }
        return "This date comes from your default morning plan."
    }

    static func wakeSourceHelperText(for day: ActiveAlarmDay, hasDayOverride: Bool) -> String {
        if hasDayOverride {
            return "Use Plans to change your usual morning plan."
        }
        if day.provenances.contains(where: { $0.sourceOrigin != .defaultDailyPlan }) {
            return "Use Plans if you want to change every matching date."
        }
        return "Use Plans to change your usual morning plan."
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
            summaryDetail: detailParts.isEmpty ? "From recent mornings." : detailParts.joined(separator: " · "),
            recentActivityLines: Array(wakeEvents.prefix(4)).map(formatWakeEventLine),
            emptyStateText: nil
        )
    }

    private static func defaultPlanTitle(for day: ActiveAlarmDay) -> String {
        switch day.effectiveConfig.defaultWakeRule.state {
        case .preFajr:
            return "Before Fajr"
        case .inFajr:
            return "During Fajr"
        case .postFajr:
            return "After Fajr"
        case .fixedWake:
            return "Fixed wake"
        }
    }

    private static func defaultPlanWakeText(for day: ActiveAlarmDay) -> String {
        let rule = day.effectiveConfig.defaultWakeRule
        return wakeOffsetText(
            state: rule.state,
            anchor: rule.anchorType ?? .fajrStart,
            deltaMinutes: rule.deltaMinutes,
            fixedTimeMinutes: rule.fixedWakeTimeMinutesFromMidnight
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
        let primaryTitle = dayMeaningText(for: day, style: .history)

        let title: String
        if hasOverride && day.decisionLog.plannedWakeState == .fixedWake {
            title = "Fixed wake"
        } else if hasOverride && day.decisionLog.plannedWakeState == .postFajr {
            title = "After Fajr"
        } else if hasOverride && nonDefaultProvenances.isEmpty && day.resolvedDayContext.primaryContext == .standard {
            title = "Changed"
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
            WakeRowPresentation.dateLabel(for: day.date),
            wakeExplanationText(for: day, hasDayOverride: hasOverride)
        ]

        if hasOverride && nonDefaultProvenances.isEmpty {
            subtitleParts.append("Changed")
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

    private static func observanceTitle(
        from resolvedDayContext: ResolvedDayContext
    ) -> String? {
        let tags = Set(resolvedDayContext.supportingTags)
        if tags.contains(.arafah) {
            return "Arafah fast"
        }
        if tags.contains(.ashura) {
            return "Ashura fast"
        }
        if tags.contains(.whiteDays) {
            return "White Days fast"
        }
        if tags.contains(.shawwalSix) {
            return "Shawwal fast"
        }
        if tags.contains(.dhulHijjahFirstNine) {
            return "Dhul Hijjah fast"
        }
        if tags.contains(.mondayThursday) {
            return "Monday or Thursday fast"
        }
        return nil
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

enum DayMeaningStyle {
    case homeContext
    case wakeRow
    case history
}
