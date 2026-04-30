import Foundation

enum MorningHeroWakeState: String, Equatable {
    case active
    case offWithAnchor
    case noAlarm
    case quietHours
    case unavailable
}

enum MorningHeroWakeWindowIndicatorState: String, Equatable {
    case active
    case offAnchor
    case none
    case unavailable
}

enum MorningHeroFajrWindowVisualMode: String, Equatable {
    case interactiveWithinFajrWindow
    case staticWithinFajrWindow
    case interactiveEarlyWorshipWindow
    case staticEarlyWorshipWindow
    case hiddenOutOfWindow
    case hiddenUnavailable

    var rendersRange: Bool {
        switch self {
        case .interactiveWithinFajrWindow,
             .staticWithinFajrWindow,
             .interactiveEarlyWorshipWindow,
             .staticEarlyWorshipWindow:
            return true
        case .hiddenOutOfWindow, .hiddenUnavailable:
            return false
        }
    }

    var isInteractive: Bool {
        switch self {
        case .interactiveWithinFajrWindow, .interactiveEarlyWorshipWindow:
            return true
        case .staticWithinFajrWindow, .staticEarlyWorshipWindow, .hiddenOutOfWindow, .hiddenUnavailable:
            return false
        }
    }

    var isEarlyWorship: Bool {
        switch self {
        case .interactiveEarlyWorshipWindow, .staticEarlyWorshipWindow:
            return true
        case .interactiveWithinFajrWindow, .staticWithinFajrWindow, .hiddenOutOfWindow, .hiddenUnavailable:
            return false
        }
    }
}

enum MorningHeroBoundaryMarkerStyle: String, Equatable {
    case endpointCircle
    case verticalLine
    case none
}

enum MorningHeroRelationTone: String, Equatable {
    case normal
    case urgentRed
}

struct MorningHomeHeroDisplay: Equatable {
    let locationText: String
    let locationIconName: String?
    let title: String
    let dateLine: String?
    let wakeState: MorningHeroWakeState
    let primaryTime: Date?
    let primaryText: String
    let wakeIconName: String?
    let statusText: String
    let detailText: String
    let relationTone: MorningHeroRelationTone
    let fajrWindowLine: String
    let fajrBeginDisplayText: String?
    let fajrEndDisplayText: String?
    let wakeWindowPositionRatio: Double?
    let wakeWindowIndicatorState: MorningHeroWakeWindowIndicatorState
    let wakeWindowIndicatorIconName: String?
    let leftBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
    let rightBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
    let fajrWindowVisualMode: MorningHeroFajrWindowVisualMode
    let fajrWindowAccessibilityText: String?
    let wakeAdjustmentEnabled: Bool
    let wakeAdjustmentMinTime: Date?
    let wakeAdjustmentMaxTime: Date?
    let wakeAdjustmentFajrEndTime: Date?
    let wakeAdjustmentStepMinutes: Int
    let wakeAdjustmentRelationAnchor: WakeAnchorType?
    let wakeAdjustmentAccessibilityValue: String?
    let chipTitles: [String]
    let accessibilityLabel: String
}

struct MorningcastRowDisplay: Equatable {
    let title: String
    let subtitle: String?
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let accessibilityLabel: String
}

enum NextTenMorningsLoadingState: Equatable {
    case ready
    case empty
}

enum NextTenMorningsQuietModeState: Equatable {
    case inactive
    case active
}

enum NextTenMorningsTagProminence: Equatable {
    case strong
    case opportunity
    case fallback
}

enum NextTenMorningsTagSemantic: Equatable {
    case fajrFallback
    case quietMode
    case ramadan
    case fastingIntent
    case tahajjudIntent
    case qada
    case kaffarah
    case vow
    case observanceOpportunity(FastSecondaryVirtueTag)
    case observanceIntended(FastSecondaryVirtueTag)
}

struct NextTenMorningsTagDisplay: Equatable, Identifiable {
    let id: String
    let title: String
    let semantic: NextTenMorningsTagSemantic
    let prominence: NextTenMorningsTagProminence
    let priority: Int
    let accessibilityText: String
}

struct NextTenMorningsRowDisplay: Equatable, Identifiable {
    let id: String
    let dateKey: String
    let date: Date
    let dateLabel: String
    let tags: [NextTenMorningsTagDisplay]
    let allAccessibilityTags: [NextTenMorningsTagDisplay]
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let accessibilityLabel: String
}

struct NextTenMorningsResolvedRowLanes: Equatable {
    let dateLaneWidth: Double
    let dateToTagGap: Double
    let tagLaneWidth: Double
    let tagToTrailingGap: Double
    let trailingLaneWidth: Double

    var tagLaneCenterX: Double {
        dateLaneWidth + dateToTagGap + (tagLaneWidth / 2)
    }
}

struct NextTenMorningsRowMetrics: Equatable {
    static let minimumDateLaneWidth: Double = 78
    static let minimumDateToTagGap: Double = 6
    static let minimumTagLaneWidth: Double = 44
    static let minimumTagToTimeGap: Double = 6
    static let minimumTrailingLaneWidth: Double = 92

    let dateLaneWidth: Double
    let minimumDateToTagGap: Double
    let minimumTagLaneWidth: Double
    let minimumTagToTimeGap: Double
    let trailingLaneWidth: Double

    static let fallback = NextTenMorningsRowMetrics(
        dateLaneWidth: minimumDateLaneWidth,
        minimumDateToTagGap: minimumDateToTagGap,
        minimumTagLaneWidth: minimumTagLaneWidth,
        minimumTagToTimeGap: minimumTagToTimeGap,
        trailingLaneWidth: minimumTrailingLaneWidth
    )

    func resolvedLanes(for contentWidth: Double) -> NextTenMorningsResolvedRowLanes {
        let fixedWidth = dateLaneWidth + minimumDateToTagGap + minimumTagToTimeGap + trailingLaneWidth
        let tagLaneWidth = max(minimumTagLaneWidth, contentWidth - fixedWidth)
        return NextTenMorningsResolvedRowLanes(
            dateLaneWidth: dateLaneWidth,
            dateToTagGap: minimumDateToTagGap,
            tagLaneWidth: tagLaneWidth,
            tagToTrailingGap: minimumTagToTimeGap,
            trailingLaneWidth: trailingLaneWidth
        )
    }
}

struct NextTenMorningsSnapshot: Equatable {
    static let title = "NEXT 10 MORNINGS"

    let title: String
    let rows: [NextTenMorningsRowDisplay]
    let rowMetrics: NextTenMorningsRowMetrics
    let loadingState: NextTenMorningsLoadingState
    let generatedAt: Date
}

struct ShawwalSixProgressSummary: Equatable {
    let completedIntendedShawwalSixCount: Int
    let remainingCount: Int
    let completedDateKeys: Set<String>
    let isComplete: Bool

    static let incomplete = ShawwalSixProgressSummary(
        completedIntendedShawwalSixCount: 0,
        remainingCount: 6,
        completedDateKeys: [],
        isComplete: false
    )
}

struct NextTenMorningsTagResolverInput: Equatable {
    let date: Date
    let dateKey: String
    let resolvedContext: ResolvedDayContext
    let tagResult: TagComputationResult
    let compatibleOpportunityTags: [FastSecondaryVirtueTag]
    let quietModeState: NextTenMorningsQuietModeState
    let shawwalSixProgress: ShawwalSixProgressSummary?
    let hasDayOverride: Bool
    let tahajjudIntended: Bool
}

struct NextTenMorningsTagResolution: Equatable {
    let visibleTags: [NextTenMorningsTagDisplay]
    let accessibilityTags: [NextTenMorningsTagDisplay]
}

enum NextTenMorningsTagResolver {
    static let maximumVisibleTags = 3

    static func resolve(_ input: NextTenMorningsTagResolverInput) -> NextTenMorningsTagResolution {
        let tags: [NextTenMorningsTagDisplay]

        if input.quietModeState == .active {
            tags = [tag(.quietMode, priority: 0)]
        } else if isRamadan(input) {
            tags = [tag(.ramadan, priority: 10)]
        } else if hasFastingIntent(input) {
            tags = fastingTags(input)
        } else if input.tahajjudIntended {
            tags = tahajjudTags(input)
        } else {
            let opportunityTags = opportunityTags(input)
            tags = opportunityTags.isEmpty
                ? [tag(.fajrFallback, priority: 100)]
                : [tag(.fajrFallback, priority: 65)] + opportunityTags
        }

        let ordered = orderedUnique(tags)
        return NextTenMorningsTagResolution(
            visibleTags: Array(ordered.prefix(maximumVisibleTags)),
            accessibilityTags: ordered
        )
    }

    private static func isRamadan(_ input: NextTenMorningsTagResolverInput) -> Bool {
        input.tagResult.computedPrimaryIntent == .ramadanObligatory
            || input.resolvedContext.supportingTags.contains(.ramadan)
    }

    private static func hasFastingIntent(_ input: NextTenMorningsTagResolverInput) -> Bool {
        switch input.tagResult.computedPrimaryIntent {
        case .voluntary, .qadaMakeup, .kaffarahExpiation, .vowNadhr:
            return true
        case .ramadanObligatory, .forbidden, .other:
            break
        }

        let tags = Set(input.resolvedContext.supportingTags)
        if tags.contains(.voluntary) || tags.contains(.qada) || tags.contains(.kaffarah) || tags.contains(.vow) {
            return true
        }

        switch input.resolvedContext.primaryContext {
        case .fasting, .suhoor, .sunnahFast, .qadaFast:
            return true
        case .standard, .tahajjud, .jamaah, .specialDay:
            return false
        }
    }

    private static func fastingTags(_ input: NextTenMorningsTagResolverInput) -> [NextTenMorningsTagDisplay] {
        var tags = [tag(.fastingIntent, priority: 20)]

        switch input.tagResult.computedPrimaryIntent {
        case .qadaMakeup:
            tags.append(tag(.qada, priority: 30))
        case .kaffarahExpiation:
            tags.append(tag(.kaffarah, priority: 31))
        case .vowNadhr:
            tags.append(tag(.vow, priority: 32))
        case .voluntary, .ramadanObligatory, .forbidden, .other:
            break
        }

        guard input.tagResult.computedPrimaryIntent == .voluntary else {
            return tags
        }

        let intended = Set(input.tagResult.computedSecondaryTags).union(secondaryTags(from: input.resolvedContext))
        for secondaryTag in sortedVisibleSecondaryTags(intended, shawwalSixProgress: input.shawwalSixProgress) {
            tags.append(tag(.observanceIntended(secondaryTag), priority: intendedPriority(for: secondaryTag)))
        }

        return tags
    }

    private static func tahajjudTags(_ input: NextTenMorningsTagResolverInput) -> [NextTenMorningsTagDisplay] {
        var tags = [tag(.tahajjudIntent, priority: 60)]
        for secondaryTag in sortedVisibleOpportunityTags(input.compatibleOpportunityTags, shawwalSixProgress: input.shawwalSixProgress) {
            tags.append(tag(.observanceOpportunity(secondaryTag), priority: opportunityPriority(for: secondaryTag)))
        }
        return tags
    }

    private static func opportunityTags(_ input: NextTenMorningsTagResolverInput) -> [NextTenMorningsTagDisplay] {
        let opportunities = Set(input.compatibleOpportunityTags).union(secondaryTags(from: input.resolvedContext))
        return sortedVisibleOpportunityTags(
            Array(opportunities),
            shawwalSixProgress: input.shawwalSixProgress
        ).map {
            tag(.observanceOpportunity($0), priority: opportunityPriority(for: $0))
        }
    }

    private static func sortedVisibleOpportunityTags(
        _ tags: [FastSecondaryVirtueTag],
        shawwalSixProgress: ShawwalSixProgressSummary?
    ) -> [FastSecondaryVirtueTag] {
        let filtered = tags.filter { secondaryTag in
            guard secondaryTag != .mondayThursday else { return false }
            guard secondaryTag != .shawwalSix || shawwalSixProgress?.isComplete != true else { return false }
            return true
        }
        return FastIntentEngine.displaySecondaryTags(Set(filtered))
    }

    private static func sortedVisibleSecondaryTags(
        _ tags: Set<FastSecondaryVirtueTag>,
        shawwalSixProgress: ShawwalSixProgressSummary?
    ) -> [FastSecondaryVirtueTag] {
        let filtered = tags.filter { secondaryTag in
            guard secondaryTag != .shawwalSix || shawwalSixProgress?.isComplete != true else { return false }
            return true
        }
        return FastIntentEngine.displaySecondaryTags(Set(filtered))
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

    private static func orderedUnique(_ tags: [NextTenMorningsTagDisplay]) -> [NextTenMorningsTagDisplay] {
        var seen = Set<String>()
        return tags.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.title < rhs.title
            }
            return lhs.priority < rhs.priority
        }.filter { tag in
            seen.insert(tag.id).inserted
        }
    }

    private static func intendedPriority(for tag: FastSecondaryVirtueTag) -> Int {
        40 + secondaryPriority(for: tag)
    }

    private static func opportunityPriority(for tag: FastSecondaryVirtueTag) -> Int {
        70 + secondaryPriority(for: tag)
    }

    private static func secondaryPriority(for tag: FastSecondaryVirtueTag) -> Int {
        switch tag {
        case .arafah:
            return 0
        case .ashura:
            return 1
        case .dhulHijjahFirstNine:
            return 2
        case .whiteDays:
            return 3
        case .shawwalSix:
            return 4
        case .mondayThursday:
            return 5
        }
    }

    private static func tag(
        _ semantic: NextTenMorningsTagSemantic,
        priority: Int
    ) -> NextTenMorningsTagDisplay {
        NextTenMorningsTagDisplay(
            id: tagID(for: semantic),
            title: title(for: semantic),
            semantic: semantic,
            prominence: prominence(for: semantic),
            priority: priority,
            accessibilityText: accessibilityText(for: semantic)
        )
    }

    private static func tagID(for semantic: NextTenMorningsTagSemantic) -> String {
        switch semantic {
        case .fajrFallback:
            return "fajr"
        case .quietMode:
            return "quiet-mode"
        case .ramadan:
            return "ramadan"
        case .fastingIntent:
            return "fasting"
        case .tahajjudIntent:
            return "tahajjud"
        case .qada:
            return "qada"
        case .kaffarah:
            return "kaffarah"
        case .vow:
            return "vow"
        case .observanceOpportunity(let tag):
            return "opportunity-\(tag.rawValue)"
        case .observanceIntended(let tag):
            return "intended-\(tag.rawValue)"
        }
    }

    private static func title(for semantic: NextTenMorningsTagSemantic) -> String {
        switch semantic {
        case .fajrFallback:
            return "Fajr"
        case .quietMode:
            return "Quiet mode"
        case .ramadan:
            return "Ramadan"
        case .fastingIntent:
            return "Fasting"
        case .tahajjudIntent:
            return "Tahajjud"
        case .qada:
            return "Qada"
        case .kaffarah:
            return "Kaffarah"
        case .vow:
            return "Vow"
        case .observanceOpportunity(let tag), .observanceIntended(let tag):
            return tag.shortTitle
        }
    }

    private static func prominence(for semantic: NextTenMorningsTagSemantic) -> NextTenMorningsTagProminence {
        switch semantic {
        case .quietMode, .ramadan, .fastingIntent, .tahajjudIntent, .qada, .kaffarah, .vow:
            return .strong
        case .observanceOpportunity, .observanceIntended:
            return .opportunity
        case .fajrFallback:
            return .fallback
        }
    }

    private static func accessibilityText(for semantic: NextTenMorningsTagSemantic) -> String {
        switch semantic {
        case .fajrFallback:
            return "Fajr morning"
        case .quietMode:
            return "Quiet mode"
        case .ramadan:
            return "Ramadan morning"
        case .fastingIntent:
            return "Fasting intended"
        case .tahajjudIntent:
            return "Tahajjud intended"
        case .qada:
            return "Qada"
        case .kaffarah:
            return "Kaffarah"
        case .vow:
            return "Vow"
        case .observanceOpportunity(let tag):
            return "\(tag.shortTitle) fasting opportunity"
        case .observanceIntended(let tag):
            return tag.shortTitle
        }
    }
}

enum MorningHomePresentation {
    static func nextTenMorningsSnapshot(
        from entries: [WakeRowEntry],
        currentDate: Date = Date(),
        timeZone: TimeZone = .current,
        generatedAt: Date = Date(),
        shawwalSixProgress: ShawwalSixProgressSummary? = nil
    ) -> NextTenMorningsSnapshot {
        let rows = entries.prefix(MorningHomeSnapshot.maximumMorningcastCount).enumerated().map { index, entry in
            nextTenMorningsRowDisplay(
                for: entry,
                index: index,
                currentDate: currentDate,
                timeZone: timeZone,
                shawwalSixProgress: shawwalSixProgress
            )
        }

        return NextTenMorningsSnapshot(
            title: NextTenMorningsSnapshot.title,
            rows: rows,
            rowMetrics: nextTenMorningsRowMetrics(for: rows, timeZone: timeZone),
            loadingState: rows.isEmpty ? .empty : .ready,
            generatedAt: generatedAt
        )
    }

    static func nextTenMorningsRowMetrics(
        for rows: [NextTenMorningsRowDisplay],
        timeZone: TimeZone = .current
    ) -> NextTenMorningsRowMetrics {
        guard !rows.isEmpty else { return .fallback }

        let dateWidth = rows
            .map { estimatedDateLaneWidth(for: $0.dateLabel) }
            .max() ?? NextTenMorningsRowMetrics.minimumDateLaneWidth
        let trailingWidth = rows
            .map { estimatedTrailingLaneWidth(for: $0, timeZone: timeZone) }
            .max() ?? NextTenMorningsRowMetrics.minimumTrailingLaneWidth

        return NextTenMorningsRowMetrics(
            dateLaneWidth: max(NextTenMorningsRowMetrics.minimumDateLaneWidth, dateWidth),
            minimumDateToTagGap: NextTenMorningsRowMetrics.minimumDateToTagGap,
            minimumTagLaneWidth: NextTenMorningsRowMetrics.minimumTagLaneWidth,
            minimumTagToTimeGap: NextTenMorningsRowMetrics.minimumTagToTimeGap,
            trailingLaneWidth: max(NextTenMorningsRowMetrics.minimumTrailingLaneWidth, trailingWidth)
        )
    }

    static func nextTenMorningsRowDisplay(
        for entry: WakeRowEntry,
        index: Int,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current,
        shawwalSixProgress: ShawwalSixProgressSummary? = nil,
        quietModeState: NextTenMorningsQuietModeState = .inactive
    ) -> NextTenMorningsRowDisplay {
        let dateLabel = nextTenMorningsDateLabel(
            for: entry.schedule.date,
            index: index,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let compatibleOpportunityTags = FastIntentEngine.displaySecondaryTags(
            FastIntentEngine.dateDerivedObservanceTags(
                for: entry.schedule.date,
                timeZone: timeZone,
                includeShawwalPotential: true
            )
        )
        let tagResolution = NextTenMorningsTagResolver.resolve(
            NextTenMorningsTagResolverInput(
                date: entry.schedule.date,
                dateKey: entry.id,
                resolvedContext: entry.activeDay.resolvedDayContext,
                tagResult: entry.activeDay.tagResult,
                compatibleOpportunityTags: compatibleOpportunityTags,
                quietModeState: quietModeState,
                shawwalSixProgress: shawwalSixProgress,
                hasDayOverride: entry.hasDayOverride,
                tahajjudIntended: entry.activeDay.resolvedDayContext.primaryContext == .tahajjud
                    || entry.activeDay.effectiveConfig.tahajjudRefinement
            )
        )
        let trailingTime = entry.isEnabled ? entry.schedule.wakeDate : nil
        let trailingStatusText = entry.isEnabled ? nil : WakePagePresentation.noWakeTrailingText
        let accessibilityLabel = nextTenMorningsAccessibilityLabel(
            entry: entry,
            date: entry.schedule.date,
            tags: tagResolution.accessibilityTags,
            trailingTime: trailingTime,
            trailingStatusText: trailingStatusText,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return NextTenMorningsRowDisplay(
            id: entry.id,
            dateKey: entry.id,
            date: entry.schedule.date,
            dateLabel: dateLabel,
            tags: tagResolution.visibleTags,
            allAccessibilityTags: tagResolution.accessibilityTags,
            trailingTime: trailingTime,
            trailingStatusText: trailingStatusText,
            isInactive: !entry.isEnabled,
            accessibilityLabel: accessibilityLabel
        )
    }

    static func heroDisplay(
        entry: WakeRowEntry?,
        permissionSummary: String,
        locationDisplayText: String? = nil,
        locationIconName: String? = nil,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil,
        accessibleHijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil
    ) -> MorningHomeHeroDisplay {
        let fallbackLocation = locationDisplayText.flatMap(Self.nonEmptyLocationText) ?? "Location unavailable"
        guard let entry else {
            let detail = permissionSummary.isEmpty
                ? "Subh will show tomorrow once schedule data is available."
                : permissionSummary
            return MorningHomeHeroDisplay(
                locationText: fallbackLocation,
                locationIconName: locationIconName,
                title: "Tomorrow",
                dateLine: nil,
                wakeState: .unavailable,
                primaryTime: nil,
                primaryText: "Wake time unavailable",
                wakeIconName: nil,
                statusText: "Wake time unavailable",
                detailText: detail,
                relationTone: .normal,
                fajrWindowLine: "Fajr times are not available yet",
                fajrBeginDisplayText: nil,
                fajrEndDisplayText: nil,
                wakeWindowPositionRatio: nil,
                wakeWindowIndicatorState: .unavailable,
                wakeWindowIndicatorIconName: nil,
                leftBoundaryMarkerStyle: .none,
                rightBoundaryMarkerStyle: .none,
                fajrWindowVisualMode: .hiddenUnavailable,
                fajrWindowAccessibilityText: nil,
                wakeAdjustmentEnabled: false,
                wakeAdjustmentMinTime: nil,
                wakeAdjustmentMaxTime: nil,
                wakeAdjustmentFajrEndTime: nil,
                wakeAdjustmentStepMinutes: 1,
                wakeAdjustmentRelationAnchor: nil,
                wakeAdjustmentAccessibilityValue: nil,
                chipTitles: [],
                accessibilityLabel: "\(fallbackLocation). Tomorrow. Wake time unavailable. \(detail). Fajr times are not available yet."
            )
        }

        let locationText = locationDisplayText.flatMap(Self.nonEmptyLocationText)
            ?? nonEmptyLocationText(entry.schedule.locationDescription)
            ?? "Location unavailable"
        let title = relativeDayLabel(
            targetDate: entry.schedule.date,
            wakeDate: entry.schedule.wakeDate,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let dateLine = heroDateLine(
            for: entry.schedule.date,
            timeZone: timeZone,
            hijriDateTextProvider: hijriDateTextProvider
        )
        let wakeState = heroWakeState(for: entry)
        let statusText = heroStatusText(for: entry)
        let relation = conciseWakeRelation(for: entry, timeZone: timeZone)
        let chipTitles = actionableChipTitles(for: entry)
        let fajrWindow = fajrWindowDisplay(for: entry, currentDate: currentDate, timeZone: timeZone)
        let primaryTime = wakeState == .active ? entry.schedule.wakeDate : nil
        let primaryText = primaryDisplayText(for: entry, wakeState: wakeState, timeZone: timeZone)
        let accessibilityLabel = heroAccessibilityLabel(
            locationText: locationText,
            title: title,
            entry: entry,
            dateLine: dateLine,
            wakeState: wakeState,
            primaryText: primaryText,
            detailText: relation.text,
            fajrWindowAccessibilityText: fajrWindow.accessibilityText ?? fajrWindow.fallbackText,
            timeZone: timeZone,
            accessibleHijriDateTextProvider: accessibleHijriDateTextProvider
        )

        return MorningHomeHeroDisplay(
            locationText: locationText,
            locationIconName: locationIconName,
            title: title,
            dateLine: dateLine,
            wakeState: wakeState,
            primaryTime: primaryTime,
            primaryText: primaryText,
            wakeIconName: wakeIconName(for: wakeState),
            statusText: statusText,
            detailText: relation.text,
            relationTone: relation.tone,
            fajrWindowLine: fajrWindow.fallbackText,
            fajrBeginDisplayText: fajrWindow.beginText,
            fajrEndDisplayText: fajrWindow.endText,
            wakeWindowPositionRatio: fajrWindow.wakePositionRatio,
            wakeWindowIndicatorState: fajrWindow.indicatorState,
            wakeWindowIndicatorIconName: wakeWindowIndicatorIconName(for: fajrWindow.indicatorState),
            leftBoundaryMarkerStyle: fajrWindow.leftBoundaryMarkerStyle,
            rightBoundaryMarkerStyle: fajrWindow.rightBoundaryMarkerStyle,
            fajrWindowVisualMode: fajrWindow.visualMode,
            fajrWindowAccessibilityText: fajrWindow.accessibilityText,
            wakeAdjustmentEnabled: fajrWindow.visualMode.isInteractive,
            wakeAdjustmentMinTime: fajrWindow.adjustmentMinTime,
            wakeAdjustmentMaxTime: fajrWindow.adjustmentMaxTime,
            wakeAdjustmentFajrEndTime: fajrWindow.adjustmentFajrEndTime,
            wakeAdjustmentStepMinutes: fajrWindow.adjustmentStepMinutes,
            wakeAdjustmentRelationAnchor: fajrWindow.adjustmentRelationAnchor,
            wakeAdjustmentAccessibilityValue: fajrWindow.adjustmentAccessibilityValue,
            chipTitles: chipTitles,
            accessibilityLabel: accessibilityLabel
        )
    }

    static func heroDisplay(
        adjusting display: MorningHomeHeroDisplay,
        tentativeWakeTime: Date,
        timeZone: TimeZone = .current
    ) -> MorningHomeHeroDisplay {
        guard
            let minTime = display.wakeAdjustmentMinTime,
            let maxTime = display.wakeAdjustmentMaxTime
        else {
            return display
        }

        let clampedWake = clamped(tentativeWakeTime, min: minTime, max: maxTime)
        let fajrEndForUrgency = display.wakeAdjustmentFajrEndTime ?? maxTime
        let relation = adjustedWakeRelation(
            wakeTime: clampedWake,
            minTime: minTime,
            maxTime: maxTime,
            fajrEnd: fajrEndForUrgency,
            visualMode: display.fajrWindowVisualMode
        )
        let detailText = relation.text
        let ratio = wakeWindowPositionRatio(
            wakeDate: clampedWake,
            fajrStart: minTime,
            fajrEnd: maxTime
        )
        let primaryText = timeFormatter(timeZone: timeZone).string(from: clampedWake)
        let accessibilityValue = wakeAdjustmentAccessibilityValue(
            wakeTime: clampedWake,
            relationText: detailText,
            minTime: minTime,
            maxTime: maxTime,
            fajrEnd: fajrEndForUrgency,
            visualMode: display.fajrWindowVisualMode,
            timeZone: timeZone
        )

        return MorningHomeHeroDisplay(
            locationText: display.locationText,
            locationIconName: display.locationIconName,
            title: display.title,
            dateLine: display.dateLine,
            wakeState: display.wakeState,
            primaryTime: clampedWake,
            primaryText: primaryText,
            wakeIconName: display.wakeIconName,
            statusText: display.statusText,
            detailText: detailText,
            relationTone: relation.tone,
            fajrWindowLine: display.fajrWindowLine,
            fajrBeginDisplayText: display.fajrBeginDisplayText,
            fajrEndDisplayText: display.fajrEndDisplayText,
            wakeWindowPositionRatio: ratio,
            wakeWindowIndicatorState: display.wakeWindowIndicatorState,
            wakeWindowIndicatorIconName: display.wakeWindowIndicatorIconName,
            leftBoundaryMarkerStyle: display.leftBoundaryMarkerStyle,
            rightBoundaryMarkerStyle: display.rightBoundaryMarkerStyle,
            fajrWindowVisualMode: display.fajrWindowVisualMode,
            fajrWindowAccessibilityText: display.fajrWindowAccessibilityText,
            wakeAdjustmentEnabled: display.wakeAdjustmentEnabled,
            wakeAdjustmentMinTime: display.wakeAdjustmentMinTime,
            wakeAdjustmentMaxTime: display.wakeAdjustmentMaxTime,
            wakeAdjustmentFajrEndTime: display.wakeAdjustmentFajrEndTime,
            wakeAdjustmentStepMinutes: display.wakeAdjustmentStepMinutes,
            wakeAdjustmentRelationAnchor: display.wakeAdjustmentRelationAnchor,
            wakeAdjustmentAccessibilityValue: accessibilityValue,
            chipTitles: display.chipTitles,
            accessibilityLabel: adjustedAccessibilityLabel(
                base: display.accessibilityLabel,
                wakeTimeText: primaryText,
                relationText: detailText,
                fajrWindowAccessibilityText: display.fajrWindowAccessibilityText
            )
        )
    }

    static func morningcastEntries(
        from entries: [WakeRowEntry],
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [WakeRowEntry] {
        MorningHomeSnapshot.morningcastEntries(
            from: entries,
            currentDate: currentDate,
            timeZone: timeZone
        )
    }

    static func shouldShowInMorningcast(
        _ entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        MorningHomeSnapshot.shouldShowInMorningcast(entry, currentDate: currentDate, timeZone: timeZone)
    }

    static func morningcastRowDisplay(
        for entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> MorningcastRowDisplay {
        let fullDisplay = WakePagePresentation.row(
            for: entry,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return MorningcastRowDisplay(
            title: fullDisplay.title,
            subtitle: compactMorningcastSubtitle(for: entry),
            trailingTime: fullDisplay.trailingTime,
            trailingStatusText: fullDisplay.trailingStatusText,
            isInactive: fullDisplay.isInactive,
            accessibilityLabel: fullDisplay.accessibilityLabel
        )
    }

    private static func nextTenMorningsDateLabel(
        for date: Date,
        index: Int,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        if index == 0, isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.tomorrowLabel
        }
        if index == 0, isToday(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.todayLabel
        }
        return nextTenMorningsDateFormatter(timeZone: timeZone).string(from: date)
    }

    private static func nextTenMorningsAccessibilityLabel(
        entry: WakeRowEntry,
        date: Date,
        tags: [NextTenMorningsTagDisplay],
        trailingTime: Date?,
        trailingStatusText: String?,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        var parts: [String] = [
            nextTenMorningsAccessibilityDateLabel(
                for: date,
                currentDate: currentDate,
                timeZone: timeZone
            ),
            nextTenMorningsAccessibilityTagSummary(tags)
        ]

        if let trailingTime {
            parts.append("Wake at \(timeFormatter(timeZone: timeZone).string(from: trailingTime))")
        } else if let trailingStatusText {
            parts.append(trailingStatusText)
        }

        if entry.hasDayOverride {
            parts.append("Adjusted for this date")
        }
        if entry.activeDay.decisionLog.latestWakeCapApplied {
            parts.append("Latest wake cap applied")
        }
        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            parts.append("Fixed wake")
        }

        parts.append("Double tap for details")
        return parts.filter { !$0.isEmpty }.joined(separator: ". ") + "."
    }

    private static func nextTenMorningsAccessibilityTagSummary(_ tags: [NextTenMorningsTagDisplay]) -> String {
        guard !tags.isEmpty else { return "Fajr morning" }
        if tags.count == 1 {
            return tags[0].accessibilityText
        }
        if tags.first?.semantic == .fajrFallback {
            let details = tags.dropFirst().map(\.accessibilityText)
            if details.isEmpty {
                return "Fajr morning"
            }
            return "Fajr morning; \(details.joined(separator: ", "))"
        }
        if tags.first?.semantic == .fastingIntent {
            let details = tags.dropFirst().map(\.accessibilityText)
            if details.isEmpty {
                return "Fasting intended"
            }
            return "Fasting intended for \(details.joined(separator: ", "))"
        }
        if tags.first?.semantic == .tahajjudIntent {
            let details = tags.dropFirst().map(\.accessibilityText)
            if details.isEmpty {
                return "Tahajjud intended"
            }
            return "Tahajjud intended; \(details.joined(separator: ", "))"
        }
        return tags.map(\.accessibilityText).joined(separator: ", ")
    }

    private static func estimatedDateLaneWidth(for text: String) -> Double {
        let measured = Double(text.count) * 7.6 + 8
        return ceil(measured)
    }

    private static func estimatedTrailingLaneWidth(
        for row: NextTenMorningsRowDisplay,
        timeZone: TimeZone
    ) -> Double {
        if let trailingTime = row.trailingTime {
            let displayText = timeFormatter(timeZone: timeZone).string(from: trailingTime)
            let mainCharacterCount = displayText.filter { $0.isNumber || $0 == ":" }.count
            let suffixCharacterCount = displayText.filter(\.isLetter).count
            let mainWidth = Double(mainCharacterCount) * 12.4
            let suffixWidth = Double(suffixCharacterCount) * 6.8
            return ceil(mainWidth + suffixWidth + 12)
        }

        if let trailingStatusText = row.trailingStatusText {
            return ceil(Double(trailingStatusText.count) * 7.4 + 8)
        }

        return NextTenMorningsRowMetrics.minimumTrailingLaneWidth
    }

    private static func nextTenMorningsAccessibilityDateLabel(
        for date: Date,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        let dateText = nextTenMorningsAccessibilityDateFormatter(timeZone: timeZone).string(from: date)
        if isToday(date, currentDate: currentDate, timeZone: timeZone) {
            return "\(Strings.AlarmsTab.todayLabel), \(dateText)"
        }
        if isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(dateText)"
        }
        return dateText
    }

    private static func isToday(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(date, inSameDayAs: calendar.startOfDay(for: currentDate))
    }

    private static func isTomorrow(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: currentDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return calendar.isDate(date, inSameDayAs: tomorrow)
    }

    private static func heroStatusText(for entry: WakeRowEntry) -> String {
        if !entry.isEnabled {
            return entry.activeDay.effectiveConfig.skipDay ? "Alarm off" : "No alarm set"
        }
        if entry.rowPresentation.availability.state == .activeOverride {
            return "Changed wake"
        }

        let context = entry.activeDay.resolvedDayContext
        let tags = Set(context.supportingTags)
        if context.primaryContext == .qadaFast || tags.contains(.qada) {
            return "Qada planned"
        }
        if context.primaryContext == .tahajjud || entry.activeDay.effectiveConfig.tahajjudRefinement {
            return "Tahajjud planned"
        }
        if context.primaryContext == .fasting
            || context.primaryContext == .suhoor
            || context.primaryContext == .sunnahFast
            || tags.contains(.ramadan)
            || tags.contains(.voluntary) {
            return "Fasting morning"
        }

        return "Wake alarm"
    }

    private struct RelationDisplay {
        let text: String
        let tone: MorningHeroRelationTone
    }

    private static func conciseWakeRelation(for entry: WakeRowEntry, timeZone: TimeZone) -> RelationDisplay {
        if !entry.isEnabled {
            if entry.activeDay.effectiveConfig.skipDay,
               let fajrEnd = entry.activeDay.decisionLog.prayerWindow.fajrEnd {
                return RelationDisplay(
                    text: "Planned wake was \(fajrEndOffsetText(wakeTime: entry.schedule.wakeDate, fajrEnd: fajrEnd))",
                    tone: .normal
                )
            }
            let text = entry.activeDay.effectiveConfig.skipDay
                ? "Alarm is off for this date"
                : "No wake alarm is set for this date"
            return RelationDisplay(text: text, tone: .normal)
        }

        let prayerWindow = entry.activeDay.decisionLog.prayerWindow
        guard let fajrEnd = prayerWindow.fajrEnd else {
            return RelationDisplay(text: "Fajr times are not available yet", tone: .normal)
        }
        if isEarlyWorshipMorning(entry),
           let finalThirdStart = finalThirdStart(for: prayerWindow, timeZone: timeZone),
           entry.schedule.wakeDate >= finalThirdStart,
           entry.schedule.wakeDate <= prayerWindow.fajrStart {
            return activeEarlyWorshipWakeRelation(
                wakeTime: entry.schedule.wakeDate,
                finalThirdStart: finalThirdStart,
                fajrStart: prayerWindow.fajrStart,
                fajrEnd: fajrEnd
            )
        }
        return activeHeroWakeRelation(
            wakeTime: entry.schedule.wakeDate,
            fajrStart: prayerWindow.fajrStart,
            fajrEnd: fajrEnd
        )
    }

    private static func actionableChipTitles(for entry: WakeRowEntry) -> [String] {
        let redundantTitles: Set<String> = [
            "Fasting",
            "Qada",
            "Tahajjud",
            "Changed",
            "Skipped",
            "Fixed wake",
            "Daily plan",
            "Location-based"
        ]

        return entry.rowPresentation.chipTitles
            .filter { title in
                !redundantTitles.contains(title)
            }
            .prefix(2)
            .map { $0 }
    }

    private static func compactMorningcastSubtitle(for entry: WakeRowEntry) -> String? {
        if !entry.isEnabled {
            return "No wake for this date"
        }
        if entry.rowPresentation.availability.state == .activeOverride {
            return "Changed wake"
        }
        if entry.activeDay.decisionLog.latestWakeCapApplied {
            return "Moved earlier"
        }
        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            return "Fixed wake"
        }

        let status = heroStatusText(for: entry)
        return status == "Wake alarm" ? nil : status
    }

    private static func compactDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func nextTenMorningsDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func nextTenMorningsAccessibilityDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func heroDateLine(
        for date: Date,
        timeZone: TimeZone,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)?
    ) -> String {
        let gregorian = compactGregorianDateText(for: date, timeZone: timeZone)
        let hijri: String?
        if let hijriDateTextProvider {
            hijri = hijriDateTextProvider(date, timeZone)
        } else {
            hijri = compactHijriDateText(for: date, timeZone: timeZone)
        }
        guard let hijri else {
            return gregorian
        }
        return "\(gregorian) • \(hijri)"
    }

    private static func compactHijriDateText(for date: Date, timeZone: TimeZone) -> String? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }
        return "\(heroHijriMonthDisplayName(for: components.month)) \(components.day)"
    }

    private static func accessibleHijriDateText(for date: Date, timeZone: TimeZone) -> String? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }
        return "\(heroHijriMonthDisplayName(for: components.month)) \(components.day)"
    }

    private static func heroWakeState(for entry: WakeRowEntry) -> MorningHeroWakeState {
        guard entry.isEnabled else {
            return entry.activeDay.effectiveConfig.skipDay ? .offWithAnchor : .noAlarm
        }
        return .active
    }

    private static func primaryDisplayText(
        for entry: WakeRowEntry,
        wakeState: MorningHeroWakeState,
        timeZone: TimeZone
    ) -> String {
        switch wakeState {
        case .active:
            return timeFormatter(timeZone: timeZone).string(from: entry.schedule.wakeDate)
        case .offWithAnchor:
            return "Alarm off"
        case .noAlarm:
            return "No alarm set"
        case .quietHours:
            return "Quiet morning"
        case .unavailable:
            return "Wake time unavailable"
        }
    }

    private static func wakeIconName(for wakeState: MorningHeroWakeState) -> String? {
        switch wakeState {
        case .active:
            return "alarm.fill"
        case .offWithAnchor:
            return "bell.slash.fill"
        case .quietHours:
            return "moon.fill"
        case .noAlarm, .unavailable:
            return nil
        }
    }

    private static func fajrEndOffsetText(wakeTime: Date, fajrEnd: Date) -> String {
        let minutes = Int(round(fajrEnd.timeIntervalSince(wakeTime) / 60))
        return "\(minutes) min before Fajr ends"
    }

    private static func activeHeroWakeRelation(wakeTime: Date, fajrStart: Date, fajrEnd: Date) -> RelationDisplay {
        let tone = urgentRelationTone(wakeTime: wakeTime, fajrEnd: fajrEnd)
        if isEndpoint(wakeTime, fajrStart) {
            return RelationDisplay(text: "Wake up as Fajr begins", tone: tone)
        }
        if isEndpoint(wakeTime, fajrEnd) {
            return RelationDisplay(text: "Wake up as Fajr ends", tone: tone)
        }
        return RelationDisplay(
            text: "Wake up \(fajrEndOffsetText(wakeTime: wakeTime, fajrEnd: fajrEnd))",
            tone: tone
        )
    }

    private static func activeEarlyWorshipWakeRelation(
        wakeTime: Date,
        finalThirdStart: Date,
        fajrStart: Date,
        fajrEnd: Date
    ) -> RelationDisplay {
        let tone = urgentRelationTone(wakeTime: wakeTime, fajrEnd: fajrEnd)
        if isEndpoint(wakeTime, finalThirdStart) {
            return RelationDisplay(text: "Wake up for the last third of the night", tone: tone)
        }
        if isEndpoint(wakeTime, fajrStart) {
            return RelationDisplay(text: "Wake up as Fajr begins", tone: tone)
        }

        let minutes = Int(round(fajrStart.timeIntervalSince(wakeTime) / 60))
        return RelationDisplay(text: "Wake up \(minutes) min before Fajr begins", tone: tone)
    }

    private static func isEndpoint(_ lhs: Date, _ rhs: Date) -> Bool {
        abs(lhs.timeIntervalSince(rhs)) < 60
    }

    private static func urgentRelationTone(wakeTime: Date, fajrEnd: Date) -> MorningHeroRelationTone {
        let minutesBeforeFajrEnd = Int(round(fajrEnd.timeIntervalSince(wakeTime) / 60))
        return minutesBeforeFajrEnd <= 14 ? .urgentRed : .normal
    }

    private struct FajrWindowDisplay {
        let beginText: String?
        let endText: String?
        let fallbackText: String
        let accessibilityText: String?
        let wakePositionRatio: Double?
        let indicatorState: MorningHeroWakeWindowIndicatorState
        let leftBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
        let rightBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
        let visualMode: MorningHeroFajrWindowVisualMode
        let adjustmentMinTime: Date?
        let adjustmentMaxTime: Date?
        let adjustmentFajrEndTime: Date?
        let adjustmentStepMinutes: Int
        let adjustmentRelationAnchor: WakeAnchorType?
        let adjustmentAccessibilityValue: String?
    }

    private static func fajrWindowDisplay(
        for entry: WakeRowEntry,
        currentDate: Date,
        timeZone: TimeZone
    ) -> FajrWindowDisplay {
        let window = entry.activeDay.decisionLog.prayerWindow
        guard let fajrEnd = window.fajrEnd else {
            return FajrWindowDisplay(
                beginText: nil,
                endText: nil,
                fallbackText: "Fajr times are not available yet",
                accessibilityText: nil,
                wakePositionRatio: nil,
                indicatorState: .unavailable,
                leftBoundaryMarkerStyle: .none,
                rightBoundaryMarkerStyle: .none,
                visualMode: .hiddenUnavailable,
                adjustmentMinTime: nil,
                adjustmentMaxTime: nil,
                adjustmentFajrEndTime: nil,
                adjustmentStepMinutes: 1,
                adjustmentRelationAnchor: nil,
                adjustmentAccessibilityValue: nil
            )
        }

        let beginVerb: String
        let endVerb: String
        if entry.schedule.date <= currentDate, currentDate >= fajrEnd {
            beginVerb = "began"
            endVerb = "ended"
        } else if currentDate >= window.fajrStart, currentDate < fajrEnd {
            beginVerb = "began"
            endVerb = "ends"
        } else {
            beginVerb = "begins"
            endVerb = "ends"
        }

        let formatter = timeFormatter(timeZone: timeZone)
        let indicatorState = wakeWindowIndicatorState(for: entry)
        let markerDate = wakeWindowMarkerDate(for: entry, indicatorState: indicatorState)

        if isEarlyWorshipMorning(entry) {
            guard let finalThirdStart = finalThirdStart(for: window, timeZone: timeZone) else {
                return FajrWindowDisplay(
                    beginText: nil,
                    endText: nil,
                    fallbackText: "Fajr times are not available yet",
                    accessibilityText: nil,
                    wakePositionRatio: nil,
                    indicatorState: .unavailable,
                    leftBoundaryMarkerStyle: .none,
                    rightBoundaryMarkerStyle: .none,
                    visualMode: .hiddenUnavailable,
                    adjustmentMinTime: nil,
                    adjustmentMaxTime: nil,
                    adjustmentFajrEndTime: nil,
                    adjustmentStepMinutes: 1,
                    adjustmentRelationAnchor: nil,
                    adjustmentAccessibilityValue: nil
                )
            }

            let beginText = formatter.string(from: finalThirdStart)
            let endText = formatter.string(from: window.fajrStart)
            let accessibilityText = "Final third of the night begins at \(beginText). Fajr begins at \(endText)"
            let ratio = markerDate.flatMap {
                wakeWindowPositionRatio(wakeDate: $0, fajrStart: finalThirdStart, fajrEnd: window.fajrStart)
            }
            let visualMode = earlyWorshipVisualMode(for: entry, ratio: ratio)
            let adjustmentEnabled = visualMode.isInteractive
            let adjustmentAccessibilityValue: String?
            if adjustmentEnabled {
                adjustmentAccessibilityValue = wakeAdjustmentAccessibilityValue(
                    wakeTime: entry.schedule.wakeDate,
                    relationText: conciseWakeRelation(for: entry, timeZone: timeZone).text,
                    minTime: finalThirdStart,
                    maxTime: window.fajrStart,
                    fajrEnd: fajrEnd,
                    visualMode: visualMode,
                    timeZone: timeZone
                )
            } else {
                adjustmentAccessibilityValue = nil
            }

            return FajrWindowDisplay(
                beginText: beginText,
                endText: endText,
                fallbackText: "Final third begins: \(beginText) • Fajr begins: \(endText)",
                accessibilityText: accessibilityText,
                wakePositionRatio: ratio,
                indicatorState: ratio == nil ? .none : indicatorState,
                leftBoundaryMarkerStyle: .verticalLine,
                rightBoundaryMarkerStyle: .endpointCircle,
                visualMode: visualMode,
                adjustmentMinTime: adjustmentEnabled ? finalThirdStart : nil,
                adjustmentMaxTime: adjustmentEnabled ? window.fajrStart : nil,
                adjustmentFajrEndTime: adjustmentEnabled ? fajrEnd : nil,
                adjustmentStepMinutes: 1,
                adjustmentRelationAnchor: adjustmentEnabled ? .fajrStart : nil,
                adjustmentAccessibilityValue: adjustmentAccessibilityValue
            )
        }

        let beginText = formatter.string(from: window.fajrStart)
        let endText = formatter.string(from: fajrEnd)
        let relationVerbText = "Fajr \(beginVerb): \(beginText). Fajr \(endVerb): \(endText)"
        let ratio = markerDate.flatMap {
            wakeWindowPositionRatio(wakeDate: $0, fajrStart: window.fajrStart, fajrEnd: fajrEnd)
        }
        let visualMode = fajrWindowVisualMode(for: entry, ratio: ratio)
        let adjustmentEnabled = visualMode.isInteractive
        let relationAnchor = adjustmentEnabled ? adjustmentRelationAnchor(for: entry) : nil
        let adjustmentAccessibilityValue: String?
        if adjustmentEnabled {
            adjustmentAccessibilityValue = wakeAdjustmentAccessibilityValue(
                wakeTime: entry.schedule.wakeDate,
                relationText: conciseWakeRelation(for: entry, timeZone: timeZone).text,
                minTime: window.fajrStart,
                maxTime: fajrEnd,
                fajrEnd: fajrEnd,
                visualMode: visualMode,
                timeZone: timeZone
            )
        } else {
            adjustmentAccessibilityValue = nil
        }

        return FajrWindowDisplay(
            beginText: beginText,
            endText: endText,
            fallbackText: "Fajr \(beginVerb): \(beginText) • Fajr \(endVerb): \(endText)",
            accessibilityText: relationVerbText,
            wakePositionRatio: ratio,
            indicatorState: ratio == nil ? .none : indicatorState,
            leftBoundaryMarkerStyle: .endpointCircle,
            rightBoundaryMarkerStyle: .endpointCircle,
            visualMode: visualMode,
            adjustmentMinTime: adjustmentEnabled ? window.fajrStart : nil,
            adjustmentMaxTime: adjustmentEnabled ? fajrEnd : nil,
            adjustmentFajrEndTime: adjustmentEnabled ? fajrEnd : nil,
            adjustmentStepMinutes: 1,
            adjustmentRelationAnchor: relationAnchor,
            adjustmentAccessibilityValue: adjustmentAccessibilityValue
        )
    }

    private static func heroAccessibilityLabel(
        locationText: String,
        title: String,
        entry: WakeRowEntry,
        dateLine _: String?,
        wakeState: MorningHeroWakeState,
        primaryText: String,
        detailText: String,
        fajrWindowAccessibilityText: String,
        timeZone: TimeZone,
        accessibleHijriDateTextProvider _: ((Date, TimeZone) -> String?)?
    ) -> String {
        let wakeText: String
        if wakeState == .active {
            wakeText = "Wake alarm at \(timeFormatter(timeZone: timeZone).string(from: entry.schedule.wakeDate))"
        } else {
            wakeText = primaryText
        }

        return [
            locationText,
            title,
            wakeText,
            detailText,
            fajrWindowAccessibilityText.replacingOccurrences(of: " • ", with: ". ")
        ]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    private static func nonEmptyLocationText(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func relativeDayLabel(
        targetDate: Date,
        wakeDate: Date,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let targetStart = calendar.startOfDay(for: targetDate)
        let today = calendar.startOfDay(for: currentDate)

        if targetStart == today, wakeDate >= currentDate {
            return "Today"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           targetStart == tomorrow {
            return "Tomorrow"
        }

        return weekdayFormatter(timeZone: timeZone).string(from: targetDate)
    }

    private static func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func weekdayFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func compactGregorianDateText(for date: Date, timeZone: TimeZone) -> String {
        let locale = Locale.current
        let formatter = compactDateFormatter(timeZone: timeZone)
        let base = formatter.string(from: date)
        guard locale.language.languageCode?.identifier == "en" else {
            return base
        }

        return base
    }

    private static func heroHijriMonthDisplayName(for month: HijriMonth) -> String {
        switch month {
        case .dhulQadah:
            return "Dhul Qadah"
        default:
            return month.displayName
        }
    }

    private static func wakeWindowIndicatorState(for entry: WakeRowEntry) -> MorningHeroWakeWindowIndicatorState {
        switch heroWakeState(for: entry) {
        case .active:
            return .active
        case .offWithAnchor:
            return .offAnchor
        case .noAlarm:
            return .none
        case .quietHours, .unavailable:
            return .unavailable
        }
    }

    private static func wakeWindowIndicatorIconName(for state: MorningHeroWakeWindowIndicatorState) -> String? {
        switch state {
        case .active:
            return "alarm.fill"
        case .offAnchor:
            return "bell.slash.fill"
        case .none, .unavailable:
            return nil
        }
    }

    private static func fajrWindowVisualMode(
        for entry: WakeRowEntry,
        ratio: Double?
    ) -> MorningHeroFajrWindowVisualMode {
        let window = entry.activeDay.decisionLog.prayerWindow
        guard window.fajrEnd != nil else {
            return .hiddenUnavailable
        }

        guard let ratio else {
            return .staticWithinFajrWindow
        }

        guard ratio >= 0, ratio <= 1 else {
            return .hiddenOutOfWindow
        }

        return heroWakeState(for: entry) == .active
            ? .interactiveWithinFajrWindow
            : .staticWithinFajrWindow
    }

    private static func earlyWorshipVisualMode(
        for entry: WakeRowEntry,
        ratio: Double?
    ) -> MorningHeroFajrWindowVisualMode {
        guard entry.activeDay.decisionLog.prayerWindow.fajrEnd != nil else {
            return .hiddenUnavailable
        }

        guard let ratio else {
            return .staticEarlyWorshipWindow
        }

        guard ratio >= 0, ratio <= 1 else {
            return .hiddenOutOfWindow
        }

        return heroWakeState(for: entry) == .active
            ? .interactiveEarlyWorshipWindow
            : .staticEarlyWorshipWindow
    }

    private static func isEarlyWorshipMorning(_ entry: WakeRowEntry) -> Bool {
        isFastingMorning(entry.activeDay.resolvedDayContext)
            || entry.activeDay.resolvedDayContext.primaryContext == .tahajjud
            || entry.activeDay.resolvedDayContext.secondaryContexts.contains(.tahajjud)
            || entry.activeDay.effectiveConfig.tahajjudRefinement
    }

    private static func isFastingMorning(_ context: ResolvedDayContext) -> Bool {
        let fastingContexts: Set<MorningContextType> = [.fasting, .qadaFast, .sunnahFast]
        if fastingContexts.contains(context.primaryContext) {
            return true
        }
        if context.secondaryContexts.contains(where: { fastingContexts.contains($0) }) {
            return true
        }

        let fastingTags: Set<DayTag> = [.ramadan, .qada, .kaffarah, .vow, .voluntary]
        return context.supportingTags.contains(where: { fastingTags.contains($0) })
    }

    private static func finalThirdStart(for window: DailyPrayerWindow, timeZone: TimeZone) -> Date? {
        EarlyWorshipBoundaryResolver.finalThirdStart(
            targetFajrStart: window.fajrStart,
            maghrib: window.maghrib,
            timeZone: timeZone
        )
    }

    private static func adjustmentRelationAnchor(for entry: WakeRowEntry) -> WakeAnchorType {
        let anchor = entry.activeDay.decisionLog.resolvedAnchor.type
        switch anchor {
        case .fajrStart, .fajrEnd:
            return anchor
        case .masjidFajr, .clockTime:
            return .fajrEnd
        }
    }

    private static func wakeWindowMarkerDate(
        for entry: WakeRowEntry,
        indicatorState: MorningHeroWakeWindowIndicatorState
    ) -> Date? {
        switch indicatorState {
        case .active, .offAnchor:
            return entry.schedule.wakeDate
        case .none, .unavailable:
            return nil
        }
    }

    private static func wakeWindowPositionRatio(wakeDate: Date, fajrStart: Date, fajrEnd: Date) -> Double? {
        let duration = fajrEnd.timeIntervalSince(fajrStart)
        guard duration > 0 else { return nil }
        return wakeDate.timeIntervalSince(fajrStart) / duration
    }

    private static func clamped(_ date: Date, min minTime: Date, max maxTime: Date) -> Date {
        if date < minTime { return minTime }
        if date > maxTime { return maxTime }
        return date
    }

    private static func adjustedWakeRelation(
        wakeTime: Date,
        minTime: Date,
        maxTime: Date,
        fajrEnd: Date,
        visualMode: MorningHeroFajrWindowVisualMode
    ) -> RelationDisplay {
        if visualMode.isEarlyWorship {
            return activeEarlyWorshipWakeRelation(
                wakeTime: wakeTime,
                finalThirdStart: minTime,
                fajrStart: maxTime,
                fajrEnd: fajrEnd
            )
        }

        return activeHeroWakeRelation(wakeTime: wakeTime, fajrStart: minTime, fajrEnd: maxTime)
    }

    private static func wakeAdjustmentAccessibilityValue(
        wakeTime: Date,
        relationText: String,
        minTime: Date,
        maxTime: Date,
        fajrEnd: Date,
        visualMode: MorningHeroFajrWindowVisualMode,
        timeZone: TimeZone
    ) -> String {
        let formatter = timeFormatter(timeZone: timeZone)
        if visualMode.isEarlyWorship {
            return "Wake alarm at \(formatter.string(from: wakeTime)), \(relationText). Adjustable between the final third of the night at \(formatter.string(from: minTime)) and Fajr begin at \(formatter.string(from: maxTime))."
        }

        return "Wake alarm at \(formatter.string(from: wakeTime)), \(relationText). Adjustable between Fajr begin at \(formatter.string(from: minTime)) and Fajr end at \(formatter.string(from: fajrEnd))."
    }

    private static func adjustedAccessibilityLabel(
        base: String,
        wakeTimeText: String,
        relationText: String,
        fajrWindowAccessibilityText: String?
    ) -> String {
        let fajrText = fajrWindowAccessibilityText?.replacingOccurrences(of: " • ", with: ". ")
        return [
            base.components(separatedBy: ". Wake alarm at").first,
            "Wake alarm at \(wakeTimeText)",
            relationText,
            fajrText
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
    }

}
