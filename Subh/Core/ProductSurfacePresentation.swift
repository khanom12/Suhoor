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

enum SharedDayTagSurface: Equatable, Sendable {
    case nextSevenDaysCompactRow
    case primaryMorningContextCompact
    case primaryMorningContextExpanded
    case alarmDetailContext
    case weeklyFajrcastFooterContext
    case accessibilityOnly
}

enum SharedDayTagFamily: String, Sendable {
    case wakeMode
    case opportunity
    case fastingPurpose
    case calendarContext
    case statusModifier
}

enum SharedDayTagStatusKind: String, Sendable {
    case quiet
    case locked
    case unavailable
    case override
    case completed
}

enum SharedDayTagSemanticKind: Equatable, Sendable {
    case wakeMode(QuickWakeMode)
    case opportunity(ObservanceKind)
    case fastingPurpose(FastPrimaryIntent)
    case calendarContext(ObservanceKind)
    case statusModifier(SharedDayTagStatusKind)

    var stableID: String {
        switch self {
        case .wakeMode(let mode):
            return "wake-\(mode.rawValue)"
        case .opportunity(let kind):
            return "opportunity-\(kind.rawValue)"
        case .fastingPurpose(let intent):
            return "purpose-\(intent.rawValue)"
        case .calendarContext(let kind):
            return "calendar-\(kind.rawValue)"
        case .statusModifier(let status):
            return "status-\(status.rawValue)"
        }
    }
}

enum SharedDayTagProminence: String, Sendable {
    case primary
    case secondary
    case quiet
    case subdued
}

struct SharedDayTagPresentation: Equatable, Identifiable, Sendable {
    let id: String
    let family: SharedDayTagFamily
    let semanticKind: SharedDayTagSemanticKind
    let label: String
    let shortLabel: String?
    let prominence: SharedDayTagProminence
    let sourceOpportunityIDs: [String]
    let sourceIntentionIDs: [String]
    let isUserSelected: Bool
    let isOpportunityOnly: Bool
    let accessibilityLabel: String
}

enum SharedDayTagSuppressionReason: String, Sendable {
    case compactDensity
    case ramadanSupersedesOpportunity
    case quietCompact
}

struct SuppressedSharedDayTag: Equatable, Sendable {
    let tag: SharedDayTagPresentation
    let reason: SharedDayTagSuppressionReason
}

struct SharedDayTagPresentationSnapshot: Equatable, Sendable {
    let dateKey: String
    let surface: SharedDayTagSurface
    let visibleTags: [SharedDayTagPresentation]
    let hiddenTags: [SharedDayTagPresentation]
    let suppressedTags: [SuppressedSharedDayTag]
    let accessibilitySummary: String
}

enum PrimaryMorningContextDensity: Equatable, Sendable {
    case compact
    case expanded
}

enum PrimaryMorningContextDisplayModeAvailability: Equatable, Sendable {
    case visible
    case hiddenBecauseOrdinaryDefault
    case hiddenBecauseHostSurfaceUnavailable
}

enum PrimaryMorningContextKind: Equatable, Sendable {
    case unavailable
    case forbiddenFastingDay
    case ramadan
    case selectedFastingPurpose
    case selectedSunnahOpportunity
    case selectedVoluntaryFast
    case selectedQadaOrObligatoryMakeup
    case opportunityOnly
    case quietMeaningfulDay
    case quietOrdinaryDay
    case ordinaryFajr
}

struct PrimaryMorningContextPresentation: Equatable, Sendable {
    let dateKey: String
    let displayModeAvailability: PrimaryMorningContextDisplayModeAvailability
    let primaryKind: PrimaryMorningContextKind
    let title: String
    let body: String?
    let supportingLine: String?
    let compactChips: [SharedDayTagPresentation]
    let expandedChips: [SharedDayTagPresentation]
    let quietOverlayText: String?
    let overrideText: String?
    let unavailableReasonText: String?
    let actionHint: String?
    let accessibilityLabel: String
    let accessibilityValue: String?
}

enum ProductSurfacePresentation {
    static func sharedDayTags(
        for day: ActiveAlarmDay,
        surface: SharedDayTagSurface,
        timeZone: TimeZone = .current,
        shawwalSixComplete: Bool = false
    ) -> SharedDayTagPresentationSnapshot {
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: day)
        return sharedDayTags(
            dateKey: day.dateKey,
            resolvedDayPurpose: day.resolvedDayPurpose,
            selectedMode: selectedMode,
            resolvedContext: day.resolvedDayContext,
            tagResult: day.tagResult,
            compatibleOpportunityTags: FastIntentEngine.displaySecondaryTags(
                FastIntentEngine.dateDerivedObservanceTags(
                    for: day.date,
                    timeZone: timeZone,
                    includeShawwalPotential: true
                )
            ),
            surface: surface,
            shawwalSixComplete: shawwalSixComplete
        )
    }

    static func sharedDayTags(
        dateKey: String,
        resolvedDayPurpose: ResolvedDayPurpose?,
        selectedMode: QuickWakeMode,
        resolvedContext: ResolvedDayContext? = nil,
        tagResult: TagComputationResult? = nil,
        compatibleOpportunityTags: [FastSecondaryVirtueTag] = [],
        surface: SharedDayTagSurface,
        shawwalSixComplete: Bool = false
    ) -> SharedDayTagPresentationSnapshot {
        guard let resolvedDayPurpose else {
            return fallbackSharedDayTags(
                dateKey: dateKey,
                selectedMode: selectedMode,
                resolvedContext: resolvedContext ?? .standard,
                tagResult: tagResult ?? .empty,
                compatibleOpportunityTags: compatibleOpportunityTags,
                surface: surface,
                shawwalSixComplete: shawwalSixComplete
            )
        }

        let isQuiet = selectedMode == .quiet || resolvedDayPurpose.intention.kind == .quiet
        let isRamadan = hasOpportunity(.ramadan, in: resolvedDayPurpose)
            || resolvedDayPurpose.intention.fastIntent?.primaryIntent == .ramadanObligatory
        let forbiddenOpportunity = resolvedDayPurpose.opportunities.first { $0.eligibility == .forbidden }
        let selectedPurposeTags = selectedFastingPurposeTags(from: resolvedDayPurpose)
        let opportunityTags = opportunityTags(
            from: resolvedDayPurpose,
            includeMondayThursday: includeMondayThursdayOpportunity(on: surface),
            shawwalSixComplete: shawwalSixComplete
        )
        let selectedOpportunityTags = opportunityTags.filter(\.isUserSelected)
        let forbiddenTags = forbiddenOpportunity.map { [calendarTag(for: $0)] } ?? []
        let ramadanTags = isRamadan
            ? [calendarTag(kind: .ramadan, label: "Ramadan", prominence: .primary)]
            : []
        let fullMeaningTags = orderedUniqueSharedTags(
            selectedPurposeTags
                + selectedOpportunityTags
                + opportunityTags
                + forbiddenTags
                + ramadanTags
        )

        let visibleTags: [SharedDayTagPresentation]
        let suppressedTags: [SuppressedSharedDayTag]

        switch surface {
        case .nextSevenDaysCompactRow:
            if isQuiet {
                visibleTags = [wakeModeTag(.quiet)]
                suppressedTags = fullMeaningTags.map {
                    SuppressedSharedDayTag(tag: $0, reason: .quietCompact)
                }
            } else if isRamadan {
                visibleTags = [calendarTag(kind: .ramadan, label: "Ramadan", prominence: .primary)]
                suppressedTags = opportunityTags.map {
                    SuppressedSharedDayTag(tag: $0, reason: .ramadanSupersedesOpportunity)
                }
            } else if let forbiddenOpportunity {
                visibleTags = [calendarTag(for: forbiddenOpportunity)]
                suppressedTags = opportunityTags.map {
                    SuppressedSharedDayTag(tag: $0, reason: .compactDensity)
                }
            } else if isSelectedFast(resolvedDayPurpose) || selectedMode == .suhoor {
                let secondary = selectedPurposeTags.isEmpty && selectedOpportunityTags.isEmpty
                    ? [fastingPurposeTag(.voluntary, isUserSelected: true, sourceOpportunityIDs: [])]
                    : selectedPurposeTags + selectedOpportunityTags
                visibleTags = limitedSharedTags([wakeModeTag(.suhoor)] + secondary, limit: 3)
                suppressedTags = suppressedHiddenTags(
                    all: [wakeModeTag(.suhoor)] + secondary + opportunityTags,
                    visible: visibleTags,
                    reason: .compactDensity
                )
            } else {
                visibleTags = limitedSharedTags([wakeModeTag(.fajr)] + opportunityTags, limit: 3)
                suppressedTags = suppressedHiddenTags(
                    all: [wakeModeTag(.fajr)] + opportunityTags,
                    visible: visibleTags,
                    reason: .compactDensity
                )
            }

        case .primaryMorningContextCompact:
            if isQuiet {
                visibleTags = limitedSharedTags(fullMeaningTags + [statusTag(.quiet)], limit: 3)
            } else {
                visibleTags = limitedSharedTags(fullMeaningTags, limit: 3)
            }
            suppressedTags = suppressedHiddenTags(
                all: fullMeaningTags + (isQuiet ? [statusTag(.quiet)] : []),
                visible: visibleTags,
                reason: .compactDensity
            )

        case .primaryMorningContextExpanded, .alarmDetailContext, .accessibilityOnly:
            let expandedTags = fullMeaningTags + (isQuiet ? [statusTag(.quiet)] : [])
            visibleTags = orderedUniqueSharedTags(expandedTags)
            suppressedTags = []

        case .weeklyFajrcastFooterContext:
            visibleTags = limitedSharedTags(fullMeaningTags, limit: 2)
            suppressedTags = suppressedHiddenTags(
                all: fullMeaningTags,
                visible: visibleTags,
                reason: .compactDensity
            )
        }

        let visible = orderedUniqueSharedTags(visibleTags)
        let hidden = hiddenTags(all: fullMeaningTags + (isQuiet ? [statusTag(.quiet)] : []), visible: visible)
        return SharedDayTagPresentationSnapshot(
            dateKey: dateKey,
            surface: surface,
            visibleTags: visible,
            hiddenTags: hidden,
            suppressedTags: suppressedTags,
            accessibilitySummary: sharedTagAccessibilitySummary(visible: visible, hidden: hidden)
        )
    }

    static func primaryMorningContext(
        for day: ActiveAlarmDay,
        density: PrimaryMorningContextDensity,
        timeZone: TimeZone = .current
    ) -> PrimaryMorningContextPresentation {
        let surface: SharedDayTagSurface = density == .compact
            ? .primaryMorningContextCompact
            : .alarmDetailContext
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: day)
        let sharedTags = sharedDayTags(for: day, surface: surface, timeZone: timeZone)
        return primaryMorningContext(
            dateKey: day.dateKey,
            resolvedDayPurpose: day.resolvedDayPurpose,
            selectedMode: selectedMode,
            sharedTags: sharedTags,
            density: density,
            hasOverride: day.effectiveConfig.hasOverrides
        )
    }

    static func primaryMorningContext(
        dateKey: String,
        resolvedDayPurpose: ResolvedDayPurpose?,
        selectedMode: QuickWakeMode,
        sharedTags: SharedDayTagPresentationSnapshot,
        density: PrimaryMorningContextDensity,
        hasOverride: Bool = false
    ) -> PrimaryMorningContextPresentation {
        guard let resolvedDayPurpose else {
            let title = "Day context unavailable"
            let body = "Subh cannot confirm fasting opportunities for this morning yet."
            return PrimaryMorningContextPresentation(
                dateKey: dateKey,
                displayModeAvailability: .visible,
                primaryKind: .unavailable,
                title: title,
                body: body,
                supportingLine: nil,
                compactChips: sharedTags.visibleTags,
                expandedChips: sharedTags.visibleTags,
                quietOverlayText: nil,
                overrideText: hasOverride ? "Changed for this date." : nil,
                unavailableReasonText: body,
                actionHint: nil,
                accessibilityLabel: [title, body].joined(separator: ". "),
                accessibilityValue: sharedTags.accessibilitySummary
            )
        }

        let isQuiet = selectedMode == .quiet || resolvedDayPurpose.intention.kind == .quiet
        let meaningfulOpportunities = meaningfulOpportunities(in: resolvedDayPurpose)
        let isOrdinaryDefault = !isQuiet
            && resolvedDayPurpose.intention.kind == .defaultFajr
            && meaningfulOpportunities.isEmpty
            && selectedMode == .fajr
        let availability: PrimaryMorningContextDisplayModeAvailability =
            density == .compact && isOrdinaryDefault ? .hiddenBecauseOrdinaryDefault : .visible
        let copy = primaryMorningContextCopy(
            purpose: resolvedDayPurpose,
            selectedMode: selectedMode,
            density: density
        )
        let quietOverlayText = isQuiet ? copy.quietOverlayText : nil
        let bodyCandidates: [String?] = [copy.body, quietOverlayText]
        let bodyParts: [String] = bodyCandidates.compactMap { (value: String?) -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        let body = bodyParts.isEmpty ? nil : bodyParts.joined(separator: " ")
        let accessibilityLabel = [copy.title, body].compactMap { $0 }.joined(separator: ". ")

        return PrimaryMorningContextPresentation(
            dateKey: dateKey,
            displayModeAvailability: availability,
            primaryKind: copy.kind,
            title: copy.title,
            body: body,
            supportingLine: nil,
            compactChips: sharedTags.visibleTags,
            expandedChips: sharedTags.visibleTags + sharedTags.hiddenTags,
            quietOverlayText: quietOverlayText,
            overrideText: hasOverride ? "Changed for this date." : nil,
            unavailableReasonText: nil,
            actionHint: nil,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: sharedTags.accessibilitySummary
        )
    }

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

    static func defaultWakeTimesSummary(for defaults: DefaultAlarmConfig) -> String {
        [
            defaults.defaultFajrWakeRule.conciseSummary,
            defaults.defaultSuhoorWakeRule.conciseSummary
        ].joined(separator: " · ")
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

    private static func fallbackSharedDayTags(
        dateKey: String,
        selectedMode: QuickWakeMode,
        resolvedContext: ResolvedDayContext,
        tagResult: TagComputationResult,
        compatibleOpportunityTags: [FastSecondaryVirtueTag],
        surface: SharedDayTagSurface,
        shawwalSixComplete: Bool
    ) -> SharedDayTagPresentationSnapshot {
        let contextTags = Set(resolvedContext.supportingTags)
        let selectedOpportunityKinds = Set(tagResult.computedSecondaryTags.map(ObservanceKind.init))
        let opportunityKinds = Set(compatibleOpportunityTags.map(ObservanceKind.init))
            .union(Set(secondaryTags(from: resolvedContext).map(ObservanceKind.init)))
        let allowedOpportunityKinds = opportunityKinds.filter {
            guard $0 != .mondayThursday
                || includeMondayThursdayOpportunity(on: surface)
                || selectedOpportunityKinds.contains(.mondayThursday) else { return false }
            guard $0 != .shawwalSixPotential || !shawwalSixComplete else { return false }
            return true
        }
        let opportunities = FastIntentEngine.displaySecondaryTags(Set(allowedOpportunityKinds.compactMap(FastSecondaryVirtueTag.init)))
            .map { opportunityTag(for: ObservanceKind($0), sourceOpportunityIDs: [], isUserSelected: false) }

        let visible: [SharedDayTagPresentation]
        if selectedMode == .quiet {
            visible = [wakeModeTag(.quiet)]
        } else if tagResult.computedPrimaryIntent == .ramadanObligatory || contextTags.contains(.ramadan) {
            visible = [calendarTag(kind: .ramadan, label: "Ramadan", prominence: .primary)]
        } else if selectedMode == .suhoor || isLegacyFastingIntent(tagResult, context: resolvedContext) {
            var tags = [wakeModeTag(.suhoor)]
            tags += legacyPurposeTags(from: tagResult)
            if tags.count == 1 {
                tags += opportunities.filter { tag in
                    guard let kind = opportunityKind(from: tag) else { return false }
                    return selectedOpportunityKinds.contains(kind)
                }
            }
            visible = limitedSharedTags(tags, limit: 3)
        } else if tagResult.computedPrimaryIntent == .forbidden || contextTags.contains(.eid) || contextTags.contains(.tashreeq) {
            visible = [calendarTag(kind: contextTags.contains(.tashreeq) ? .tashreeq : .eidAlFitr, label: contextTags.contains(.tashreeq) ? "Fasting unavailable" : "Eid", prominence: .primary)]
        } else {
            visible = limitedSharedTags([wakeModeTag(.fajr)] + opportunities, limit: 3)
        }

        let all = orderedUniqueSharedTags(visible + opportunities)
        let hidden = hiddenTags(all: all, visible: visible)
        return SharedDayTagPresentationSnapshot(
            dateKey: dateKey,
            surface: surface,
            visibleTags: orderedUniqueSharedTags(visible),
            hiddenTags: hidden,
            suppressedTags: suppressedHiddenTags(all: all, visible: visible, reason: .compactDensity),
            accessibilitySummary: sharedTagAccessibilitySummary(visible: visible, hidden: hidden)
        )
    }

    private static func selectedFastingPurposeTags(
        from purpose: ResolvedDayPurpose
    ) -> [SharedDayTagPresentation] {
        guard let intent = purpose.intention.fastIntent?.primaryIntent else { return [] }
        switch intent {
        case .ramadanObligatory:
            return []
        case .qadaMakeup, .kaffarahExpiation, .vowNadhr, .voluntary, .other:
            return [fastingPurposeTag(
                intent,
                isUserSelected: purpose.intention.source != .defaultDailyPlan,
                sourceOpportunityIDs: Array(purpose.intention.selectedOpportunityIDs).sorted()
            )]
        case .forbidden:
            return []
        }
    }

    private static func opportunityTags(
        from purpose: ResolvedDayPurpose,
        includeMondayThursday: Bool,
        shawwalSixComplete: Bool
    ) -> [SharedDayTagPresentation] {
        purpose.opportunities
            .filter { opportunity in
                guard opportunity.eligibility == .recommended || opportunity.kind == .voluntaryGeneral else { return false }
                let isSelected = purpose.intention.selectedOpportunityIDs.contains(opportunity.id)
                guard opportunity.kind != .mondayThursday || includeMondayThursday || isSelected else { return false }
                guard opportunity.kind != .shawwalSixPotential || !shawwalSixComplete else { return false }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.priority < rhs.priority
            }
            .map { opportunity in
                opportunityTag(
                    for: opportunity.kind,
                    sourceOpportunityIDs: [opportunity.id],
                    isUserSelected: purpose.intention.selectedOpportunityIDs.contains(opportunity.id)
                )
            }
    }

    private static func wakeModeTag(_ mode: QuickWakeMode) -> SharedDayTagPresentation {
        let label = mode.displayTitle
        return SharedDayTagPresentation(
            id: SharedDayTagSemanticKind.wakeMode(mode).stableID,
            family: .wakeMode,
            semanticKind: .wakeMode(mode),
            label: label,
            shortLabel: label,
            prominence: mode == .quiet ? .quiet : .primary,
            sourceOpportunityIDs: [],
            sourceIntentionIDs: [mode.rawValue],
            isUserSelected: mode != .fajr,
            isOpportunityOnly: false,
            accessibilityLabel: "\(label) wake mode"
        )
    }

    private static func fastingPurposeTag(
        _ intent: FastPrimaryIntent,
        isUserSelected: Bool,
        sourceOpportunityIDs: [String]
    ) -> SharedDayTagPresentation {
        let label = intent == .other ? "Other fast" : intent.shortTitle
        return SharedDayTagPresentation(
            id: SharedDayTagSemanticKind.fastingPurpose(intent).stableID,
            family: .fastingPurpose,
            semanticKind: .fastingPurpose(intent),
            label: label,
            shortLabel: label,
            prominence: .primary,
            sourceOpportunityIDs: sourceOpportunityIDs,
            sourceIntentionIDs: [intent.rawValue],
            isUserSelected: isUserSelected,
            isOpportunityOnly: false,
            accessibilityLabel: "\(label) selected"
        )
    }

    private static func opportunityTag(
        for kind: ObservanceKind,
        sourceOpportunityIDs: [String],
        isUserSelected: Bool
    ) -> SharedDayTagPresentation {
        let label = opportunityTagLabel(for: kind)
        return SharedDayTagPresentation(
            id: SharedDayTagSemanticKind.opportunity(kind).stableID,
            family: .opportunity,
            semanticKind: .opportunity(kind),
            label: label,
            shortLabel: label,
            prominence: isUserSelected ? .primary : .secondary,
            sourceOpportunityIDs: sourceOpportunityIDs,
            sourceIntentionIDs: [],
            isUserSelected: isUserSelected,
            isOpportunityOnly: !isUserSelected,
            accessibilityLabel: isUserSelected ? "\(label) selected" : "\(label) opportunity"
        )
    }

    private static func calendarTag(for opportunity: ObservanceOpportunity) -> SharedDayTagPresentation {
        if opportunity.kind == .eidAlFitr || opportunity.kind == .eidAlAdha {
            return calendarTag(kind: opportunity.kind, label: "Eid", prominence: .primary)
        }
        if opportunity.kind == .tashreeq {
            return calendarTag(kind: .tashreeq, label: "Fasting unavailable", prominence: .primary)
        }
        return calendarTag(kind: opportunity.kind, label: opportunity.title, prominence: .primary)
    }

    private static func calendarTag(
        kind: ObservanceKind,
        label: String,
        prominence: SharedDayTagProminence
    ) -> SharedDayTagPresentation {
        SharedDayTagPresentation(
            id: SharedDayTagSemanticKind.calendarContext(kind).stableID,
            family: .calendarContext,
            semanticKind: .calendarContext(kind),
            label: label,
            shortLabel: label,
            prominence: prominence,
            sourceOpportunityIDs: [],
            sourceIntentionIDs: [],
            isUserSelected: false,
            isOpportunityOnly: false,
            accessibilityLabel: label
        )
    }

    private static func statusTag(_ status: SharedDayTagStatusKind) -> SharedDayTagPresentation {
        let label: String
        switch status {
        case .quiet:
            label = "Quiet"
        case .locked:
            label = "Locked"
        case .unavailable:
            label = "Unavailable"
        case .override:
            label = "Override"
        case .completed:
            label = "Completed"
        }
        return SharedDayTagPresentation(
            id: SharedDayTagSemanticKind.statusModifier(status).stableID,
            family: .statusModifier,
            semanticKind: .statusModifier(status),
            label: label,
            shortLabel: label,
            prominence: status == .quiet ? .quiet : .subdued,
            sourceOpportunityIDs: [],
            sourceIntentionIDs: [status.rawValue],
            isUserSelected: status == .quiet,
            isOpportunityOnly: false,
            accessibilityLabel: label
        )
    }

    private static func primaryMorningContextCopy(
        purpose: ResolvedDayPurpose,
        selectedMode: QuickWakeMode,
        density: PrimaryMorningContextDensity
    ) -> (
        kind: PrimaryMorningContextKind,
        title: String,
        body: String?,
        quietOverlayText: String?
    ) {
        let isQuiet = selectedMode == .quiet || purpose.intention.kind == .quiet
        let opportunities = meaningfulOpportunities(in: purpose)
        let recommended = opportunities.first { $0.eligibility == .recommended }
        let forbidden = opportunities.first { $0.eligibility == .forbidden }

        if let forbidden {
            let title = forbidden.kind == .eidAlFitr || forbidden.kind == .eidAlAdha
                ? "Eid morning"
                : "Fasting unavailable"
            return (.forbiddenFastingDay, title, "Fasting is not offered for this day.", nil)
        }

        if hasOpportunity(.ramadan, in: purpose)
            || purpose.intention.fastIntent?.primaryIntent == .ramadanObligatory {
            return (
                .ramadan,
                "Ramadan day",
                "The fasting purpose is Ramadan and is locked.",
                isQuiet ? "This morning is kept quiet, but the Ramadan context remains locked." : nil
            )
        }

        if isQuiet {
            if let first = recommended {
                return (
                    .quietMeaningfulDay,
                    opportunityContextTitle(for: first),
                    nil,
                    "This morning is kept quiet, but the opportunity is still recognized."
                )
            }
            return (.quietOrdinaryDay, "Quiet morning", nil, "This morning is kept quiet.")
        }

        if purpose.intention.kind == .fast || selectedMode == .suhoor {
            if let intent = purpose.intention.fastIntent?.primaryIntent {
                switch intent {
                case .qadaMakeup:
                    return (
                        .selectedQadaOrObligatoryMakeup,
                        "Qada fast planned",
                        opportunityAlsoLine(recommended),
                        nil
                    )
                case .kaffarahExpiation:
                    return (
                        .selectedQadaOrObligatoryMakeup,
                        "Kaffarah fast planned",
                        opportunityAlsoLine(recommended) ?? "This morning is marked for Suhoor.",
                        nil
                    )
                case .vowNadhr:
                    return (
                        .selectedQadaOrObligatoryMakeup,
                        "Vow fast planned",
                        opportunityAlsoLine(recommended) ?? "This morning is marked for Suhoor.",
                        nil
                    )
                case .voluntary:
                    if let selectedOpportunity = opportunities.first(where: { purpose.intention.selectedOpportunityIDs.contains($0.id) }) ?? recommended {
                        return (
                            .selectedSunnahOpportunity,
                            "\(opportunityPlannedTitle(for: selectedOpportunity)) fast planned",
                            selectedOpportunity.kind == .shawwalSixPotential
                                ? "This can count toward your Shawwal fasts."
                                : "This morning is marked for Suhoor.",
                            nil
                        )
                    }
                    return (.selectedVoluntaryFast, "Voluntary fast planned", "This morning is marked for Suhoor.", nil)
                case .other:
                    return (
                        .selectedFastingPurpose,
                        "Other fast planned",
                        opportunityAlsoLine(recommended) ?? "This morning is marked for Suhoor.",
                        nil
                    )
                case .ramadanObligatory, .forbidden:
                    break
                }
            }
            if let first = recommended {
                return (
                    .selectedSunnahOpportunity,
                    "\(opportunityPlannedTitle(for: first)) fast planned",
                    "This morning is marked for Suhoor.",
                    nil
                )
            }
            return (.selectedVoluntaryFast, "Voluntary fast planned", "This morning is marked for Suhoor.", nil)
        }

        if let first = recommended {
            return (
                .opportunityOnly,
                opportunityContextTitle(for: first),
                first.kind == .whiteDays ? "This is one of the middle days of the Hijri month." : "You have not planned Suhoor for this morning.",
                nil
            )
        }

        let body = density == .expanded
            ? "No special fasting opportunity is recognized for this day."
            : nil
        return (.ordinaryFajr, ordinaryDaySummaryText, body, nil)
    }

    private static func isSelectedFast(_ purpose: ResolvedDayPurpose) -> Bool {
        purpose.intention.kind == .fast
            || purpose.intention.fastIntent != nil
            || !purpose.intention.selectedOpportunityIDs.isEmpty
    }

    private static func isLegacyFastingIntent(
        _ tagResult: TagComputationResult,
        context: ResolvedDayContext
    ) -> Bool {
        switch tagResult.computedPrimaryIntent {
        case .voluntary, .qadaMakeup, .kaffarahExpiation, .vowNadhr:
            return true
        case .ramadanObligatory, .forbidden, .other:
            break
        }

        let tags = Set(context.supportingTags)
        return context.primaryContext == .fasting
            || context.primaryContext == .suhoor
            || context.primaryContext == .sunnahFast
            || context.primaryContext == .qadaFast
            || tags.contains(.voluntary)
            || tags.contains(.qada)
            || tags.contains(.kaffarah)
            || tags.contains(.vow)
    }

    private static func legacyPurposeTags(from tagResult: TagComputationResult) -> [SharedDayTagPresentation] {
        switch tagResult.computedPrimaryIntent {
        case .qadaMakeup:
            return [fastingPurposeTag(.qadaMakeup, isUserSelected: true, sourceOpportunityIDs: [])]
        case .kaffarahExpiation:
            return [fastingPurposeTag(.kaffarahExpiation, isUserSelected: true, sourceOpportunityIDs: [])]
        case .vowNadhr:
            return [fastingPurposeTag(.vowNadhr, isUserSelected: true, sourceOpportunityIDs: [])]
        case .voluntary:
            return tagResult.computedSecondaryTags.isEmpty
                ? [fastingPurposeTag(.voluntary, isUserSelected: true, sourceOpportunityIDs: [])]
                : []
        case .ramadanObligatory, .forbidden, .other:
            return []
        }
    }

    private static func meaningfulOpportunities(
        in purpose: ResolvedDayPurpose
    ) -> [ObservanceOpportunity] {
        purpose.opportunities.filter { $0.kind != .ordinary && $0.eligibility != .neutral }
            .sorted {
                if $0.priority == $1.priority {
                    return $0.kind.rawValue < $1.kind.rawValue
                }
                return $0.priority < $1.priority
            }
    }

    private static func hasOpportunity(
        _ kind: ObservanceKind,
        in purpose: ResolvedDayPurpose
    ) -> Bool {
        purpose.opportunities.contains { $0.kind == kind }
    }

    private static func includeMondayThursdayOpportunity(on surface: SharedDayTagSurface) -> Bool {
        switch surface {
        case .nextSevenDaysCompactRow:
            return true
        case .primaryMorningContextCompact,
             .primaryMorningContextExpanded,
             .alarmDetailContext,
             .weeklyFajrcastFooterContext,
             .accessibilityOnly:
            return true
        }
    }

    private static func opportunityContextTitle(for opportunity: ObservanceOpportunity) -> String {
        switch opportunity.kind {
        case .arafah:
            return "Arafah recognized"
        case .ashura:
            return "Ashura recognized"
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah opportunity"
        case .whiteDays:
            return "White Days opportunity"
        case .shawwalSixPotential:
            return "Shawwal 6 opportunity"
        case .mondayThursday:
            return "Monday/Thursday opportunity"
        default:
            return "\(opportunity.title) opportunity"
        }
    }

    private static func opportunityPlannedTitle(for opportunity: ObservanceOpportunity) -> String {
        switch opportunity.kind {
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah"
        case .shawwalSixPotential:
            return "Shawwal"
        case .mondayThursday:
            return "Monday/Thursday"
        default:
            return opportunityTagLabel(for: opportunity.kind)
        }
    }

    private static func opportunityAlsoLine(_ opportunity: ObservanceOpportunity?) -> String? {
        guard let opportunity else { return nil }
        return "This day also has a \(opportunityTagLabel(for: opportunity.kind)) opportunity."
    }

    private static func opportunityTagLabel(for kind: ObservanceKind) -> String {
        switch kind {
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah"
        case .whiteDays:
            return "White Days"
        case .shawwalSixPotential:
            return "Shawwal 6"
        case .mondayThursday:
            return "Mon/Thu"
        case .voluntaryGeneral:
            return "Voluntary"
        default:
            return kind.rawValue
        }
    }

    private static func secondaryTags(from context: ResolvedDayContext) -> Set<FastSecondaryVirtueTag> {
        Set(context.supportingTags.compactMap { dayTag in
            switch dayTag {
            case .shawwalSix:
                return .shawwalSix
            case .arafah:
                return .arafah
            case .ashura:
                return .ashura
            case .whiteDays:
                return .whiteDays
            case .mondayThursday:
                return .mondayThursday
            case .dhulHijjahFirstNine:
                return .dhulHijjahFirstNine
            case .dailyPlan, .manualDay, .manualRange, .ramadan, .qada, .kaffarah, .vow, .voluntary, .eid, .tashreeq, .locationBased, .fixedTimeCompatibility:
                return nil
            }
        })
    }

    private static func opportunityKind(from tag: SharedDayTagPresentation) -> ObservanceKind? {
        guard case .opportunity(let kind) = tag.semanticKind else { return nil }
        return kind
    }

    private static func orderedUniqueSharedTags(_ tags: [SharedDayTagPresentation]) -> [SharedDayTagPresentation] {
        var seen = Set<String>()
        return tags.filter { tag in
            seen.insert(tag.id).inserted
        }
    }

    private static func limitedSharedTags(
        _ tags: [SharedDayTagPresentation],
        limit: Int
    ) -> [SharedDayTagPresentation] {
        Array(orderedUniqueSharedTags(tags).prefix(limit))
    }

    private static func hiddenTags(
        all: [SharedDayTagPresentation],
        visible: [SharedDayTagPresentation]
    ) -> [SharedDayTagPresentation] {
        let visibleIDs = Set(visible.map(\.id))
        return orderedUniqueSharedTags(all).filter { !visibleIDs.contains($0.id) }
    }

    private static func suppressedHiddenTags(
        all: [SharedDayTagPresentation],
        visible: [SharedDayTagPresentation],
        reason: SharedDayTagSuppressionReason
    ) -> [SuppressedSharedDayTag] {
        hiddenTags(all: all, visible: visible).map {
            SuppressedSharedDayTag(tag: $0, reason: reason)
        }
    }

    private static func sharedTagAccessibilitySummary(
        visible: [SharedDayTagPresentation],
        hidden: [SharedDayTagPresentation]
    ) -> String {
        let labels = orderedUniqueSharedTags(visible + hidden).map(\.accessibilityLabel)
        guard !labels.isEmpty else { return "Fajr morning" }
        return labels.joined(separator: ", ")
    }
}

extension FastSecondaryVirtueTag {
    nonisolated init?(_ kind: ObservanceKind) {
        switch kind {
        case .shawwalSixPotential:
            self = .shawwalSix
        case .arafah:
            self = .arafah
        case .ashura:
            self = .ashura
        case .whiteDays:
            self = .whiteDays
        case .mondayThursday:
            self = .mondayThursday
        case .dhulHijjahFirstNine:
            self = .dhulHijjahFirstNine
        default:
            return nil
        }
    }
}

private extension ObservanceKind {
    nonisolated init(_ tag: FastSecondaryVirtueTag) {
        switch tag {
        case .shawwalSix:
            self = .shawwalSixPotential
        case .arafah:
            self = .arafah
        case .ashura:
            self = .ashura
        case .whiteDays:
            self = .whiteDays
        case .mondayThursday:
            self = .mondayThursday
        case .dhulHijjahFirstNine:
            self = .dhulHijjahFirstNine
        }
    }
}
