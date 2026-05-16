import Foundation

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

enum ProductSurfacePresentation {
    static func primaryContextTitle(_ context: MorningContextType) -> String {
        switch context {
        case .standard:
            return ordinaryDaySummaryText
        default:
            return context.title
        }
    }

    static let ordinaryDaySummaryText = "Regular Fajr morning"

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

    static func dayMeaningText(for day: ActiveAlarmDay) -> String {
        let resolved = day.resolvedDayContext
        let tags = Set(resolved.supportingTags)

        if resolved.primaryContext == .qadaFast || tags.contains(.qada) {
            return "Qada planned"
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
            return "Suhoor planned"
        case .suhoor, .fasting:
            return "Fasting tomorrow"
        case .sunnahFast:
            return "Sunnah fast"
        case .jamaah:
            return "Jama'ah morning"
        case .specialDay:
            return "A meaningful day is coming up"
        case .qadaFast:
            return "Qada planned"
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
            return "Set for this date"
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
                statusDetail: "No wake or extra morning cues are set for this date."
            )
        }

        if hasCustomChange {
            return WakeAvailabilityPresentation(
                state: .activeOverride,
                availabilityLabel: "Changed for this date",
                statusSummary: "Changed for this date",
                statusDetail: "This morning has its own wake."
            )
        }

        return WakeAvailabilityPresentation(
            state: .activeDefault,
            availabilityLabel: "Usual plan",
            statusSummary: "Follows your usual plan",
            statusDetail: "Your usual morning plan is still in effect."
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
            meaningText: dayMeaningText(for: day),
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
            return "Moved earlier by latest wake"
        }
        if availability.state == .skipped {
            return nil
        }
        if day.decisionLog.plannedWakeState == .fixedWake && hasDayOverride {
            return "For this date only"
        }
        if day.decisionLog.plannedWakeState == .postFajr && hasDayOverride {
            return "Available for this date only"
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
            return "\(stateText) · no later than \(SettingsSummaryFormatter.timeText(minutesFromMidnight: cap))"
        }

        if hasDayOverride && decision.plannedWakeState == .fixedWake {
            return "Fixed wake for this date"
        }
        if hasDayOverride && decision.plannedWakeState == .postFajr {
            return "\(stateText) · available for this date only"
        }
        if hasDayOverride {
            return "\(stateText) · changed for this date"
        }

        return stateText
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

}
