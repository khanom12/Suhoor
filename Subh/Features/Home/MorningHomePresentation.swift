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

enum MorningHeroActionSlotAction: Equatable {
    case none
    case confirmAwake(WakeSessionMode)
    case confirmFastingToday
    case confirmFajrPrayer
    case setFajrWakeAlarm
    case ringOnceDespitePause
}

enum MorningHeroActionSlotStyle: String, Equatable {
    case empty
    case compact
    case primary
    case confirmation
    case quiet
}

struct MorningHeroActionSlotDisplay: Equatable {
    let style: MorningHeroActionSlotStyle
    let primaryTitle: String?
    let secondaryText: String?
    let action: MorningHeroActionSlotAction
    let accessibilityLabel: String

    static let empty = MorningHeroActionSlotDisplay(
        style: .empty,
        primaryTitle: nil,
        secondaryText: nil,
        action: .none,
        accessibilityLabel: ""
    )
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
    let selectedQuickWakeMode: QuickWakeMode?
    let quickWakeModeOptions: [MorningHeroQuickWakeModeOption]
    let actionSlot: MorningHeroActionSlotDisplay
    let chipTitles: [String]
    let accessibilityLabel: String
}

struct MorningHeroQuickWakeModeOption: Equatable, Identifiable {
    let mode: QuickWakeMode
    let title: String
    let isSelected: Bool
    let accessibilityLabel: String
    let accessibilityHint: String

    var id: QuickWakeMode { mode }
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
    case eid
    case fastingUnavailable
    case fastingIntent
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
    let purposeText: String
    let tags: [NextTenMorningsTagDisplay]
    let allAccessibilityTags: [NextTenMorningsTagDisplay]
    let leadingTime: Date?
    let leadingStatusText: String?
    let trailingTime: Date?
    let trailingStatusText: String?
    let alarmToggleIsOn: Bool
    let alarmToggleIsEnabled: Bool
    let selectedQuickWakeMode: QuickWakeMode?
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
    static let title = MorningHomeSnapshot.forecastTitle
    static let subtitle = "View and plan your next seven mornings"

    let title: String
    let subtitle: String
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
    var resolvedDayPurpose: ResolvedDayPurpose? = nil
    let resolvedContext: ResolvedDayContext
    let tagResult: TagComputationResult
    let compatibleOpportunityTags: [FastSecondaryVirtueTag]
    let quietModeState: NextTenMorningsQuietModeState
    let selectedQuickWakeMode: QuickWakeMode?
    let shawwalSixProgress: ShawwalSixProgressSummary?
    let hasDayOverride: Bool
}

struct NextTenMorningsTagResolution: Equatable {
    let visibleTags: [NextTenMorningsTagDisplay]
    let accessibilityTags: [NextTenMorningsTagDisplay]
}

enum NextTenMorningsTagResolver {
    static let maximumVisibleTags = 3

    static func resolve(_ input: NextTenMorningsTagResolverInput) -> NextTenMorningsTagResolution {
        let selectedMode = resolvedSelectedMode(for: input)
        let shared = ProductSurfacePresentation.sharedDayTags(
            dateKey: input.dateKey,
            resolvedDayPurpose: input.resolvedDayPurpose,
            selectedMode: selectedMode,
            resolvedContext: input.resolvedContext,
            tagResult: input.tagResult,
            compatibleOpportunityTags: input.compatibleOpportunityTags,
            surface: .nextSevenDaysCompactRow,
            shawwalSixComplete: input.shawwalSixProgress?.isComplete == true
        )
        let sourceTags = shared.visibleTags + shared.hiddenTags
        let ordered = orderedUnique(sourceTags.compactMap(nextTenVisibleTagDisplay(from:)))
        let accessible = sourceTags.map(nextTenTagDisplay(from:))
        return NextTenMorningsTagResolution(
            visibleTags: Array(dominantVisibleTags(from: ordered).prefix(maximumVisibleTags)),
            accessibilityTags: orderedUnique(accessible)
        )
    }

    private static func resolvedSelectedMode(for input: NextTenMorningsTagResolverInput) -> QuickWakeMode {
        if let selectedQuickWakeMode = input.selectedQuickWakeMode {
            return selectedQuickWakeMode
        }
        if hasFastingIntent(input) || isRamadan(input) {
            return .suhoor
        }
        return .fajr
    }

    private static func nextTenTagDisplay(
        from tag: SharedDayTagPresentation
    ) -> NextTenMorningsTagDisplay {
        let semantic = nextTenSemantic(from: tag)
        return NextTenMorningsTagDisplay(
            id: tag.id,
            title: tag.label,
            semantic: semantic,
            prominence: nextTenProminence(from: tag.prominence, family: tag.family),
            priority: nextTenPriority(for: tag),
            accessibilityText: accessibilityText(for: semantic)
        )
    }

    private static func nextTenVisibleTagDisplay(
        from tag: SharedDayTagPresentation
    ) -> NextTenMorningsTagDisplay? {
        let display = nextTenTagDisplay(from: tag)
        switch display.semantic {
        case .ramadan, .eid, .fastingUnavailable, .observanceOpportunity, .observanceIntended:
            break
        case .fajrFallback, .quietMode, .fastingIntent, .qada, .kaffarah, .vow:
            return nil
        }

        return display
    }

    private static func dominantVisibleTags(
        from tags: [NextTenMorningsTagDisplay]
    ) -> [NextTenMorningsTagDisplay] {
        if tags.contains(where: { $0.semantic == .fastingUnavailable }) {
            return tags.filter { $0.semantic == .fastingUnavailable }
        }
        if tags.contains(where: { $0.semantic == .eid }) {
            return tags.filter { $0.semantic == .eid }
        }
        if tags.contains(where: { $0.semantic == .ramadan }) {
            return tags.filter { $0.semantic == .ramadan }
        }
        return tags
    }

    private static func nextTenSemantic(
        from tag: SharedDayTagPresentation
    ) -> NextTenMorningsTagSemantic {
        switch tag.semanticKind {
        case .wakeMode(let mode):
            switch mode {
            case .suhoor:
                return .fastingIntent
            case .fajr:
                return .fajrFallback
            case .quiet:
                return .quietMode
            }
        case .calendarContext(let kind):
            switch kind {
            case .ramadan:
                return .ramadan
            case .eidAlFitr, .eidAlAdha:
                return .eid
            case .tashreeq:
                return .fastingUnavailable
            default:
                return .fajrFallback
            }
        case .fastingPurpose(let intent):
            switch intent {
            case .qadaMakeup:
                return .qada
            case .kaffarahExpiation:
                return .kaffarah
            case .vowNadhr:
                return .vow
            case .ramadanObligatory:
                return .ramadan
            case .voluntary, .other, .forbidden:
                return .fastingIntent
            }
        case .opportunity(let kind):
            if let secondaryTag = FastSecondaryVirtueTag(kind) {
                return tag.isUserSelected ? .observanceIntended(secondaryTag) : .observanceOpportunity(secondaryTag)
            }
            return .fajrFallback
        case .statusModifier(let status):
            return status == .quiet ? .quietMode : .fajrFallback
        }
    }

    private static func nextTenProminence(
        from prominence: SharedDayTagProminence,
        family: SharedDayTagFamily
    ) -> NextTenMorningsTagProminence {
        switch prominence {
        case .primary, .quiet:
            return .strong
        case .secondary:
            return family == .opportunity ? .opportunity : .fallback
        case .subdued:
            return .fallback
        }
    }

    private static func nextTenPriority(for tag: SharedDayTagPresentation) -> Int {
        switch tag.semanticKind {
        case .wakeMode(.quiet):
            return 0
        case .calendarContext(.tashreeq):
            return 0
        case .calendarContext(.eidAlFitr), .calendarContext(.eidAlAdha):
            return 5
        case .calendarContext(.ramadan):
            return 10
        case .calendarContext:
            return 15
        case .wakeMode(.suhoor):
            return 20
        case .fastingPurpose(.qadaMakeup):
            return 30
        case .fastingPurpose(.kaffarahExpiation):
            return 31
        case .fastingPurpose(.vowNadhr):
            return 32
        case .opportunity(let kind):
            guard let secondaryTag = FastSecondaryVirtueTag(kind) else { return 55 }
            return 40 + secondaryPriority(for: secondaryTag)
        case .fastingPurpose:
            return 55
        case .wakeMode(.fajr):
            return 0
        case .statusModifier:
            return 90
        }
    }

    private static func isRamadan(_ input: NextTenMorningsTagResolverInput) -> Bool {
        input.tagResult.computedPrimaryIntent == .ramadanObligatory
            || input.resolvedContext.supportingTags.contains(.ramadan)
    }

    private static func hasFastingIntent(_ input: NextTenMorningsTagResolverInput) -> Bool {
        if input.selectedQuickWakeMode == .suhoor {
            return true
        }

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
            return "quiet"
        case .ramadan:
            return "ramadan"
        case .eid:
            return "eid"
        case .fastingUnavailable:
            return "fasting-unavailable"
        case .fastingIntent:
            return "suhoor"
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
            return "Quiet"
        case .ramadan:
            return "Ramadan"
        case .eid:
            return "Eid"
        case .fastingUnavailable:
            return "Fasting unavailable"
        case .fastingIntent:
            return "Suhoor"
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
        case .quietMode, .ramadan, .eid, .fastingUnavailable, .fastingIntent, .qada, .kaffarah, .vow:
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
            return "Quiet"
        case .ramadan:
            return "Ramadan morning"
        case .eid:
            return "Eid morning"
        case .fastingUnavailable:
            return "Fasting unavailable"
        case .fastingIntent:
            return "Suhoor selected"
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
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy = .active,
        shawwalSixProgress: ShawwalSixProgressSummary? = nil
    ) -> NextTenMorningsSnapshot {
        let rows = entries.prefix(MorningHomeSnapshot.maximumMorningcastCount).enumerated().map { index, entry in
            return nextTenMorningsRowDisplay(
                for: entry,
                index: index,
                currentDate: currentDate,
                timeZone: timeZone,
                shawwalSixProgress: shawwalSixProgress,
                globalWakeAlarmPolicy: globalWakeAlarmPolicy,
                quietModeState: entry.activeDay.effectiveConfig.dateAlarmOverride == .quiet ? .active : .inactive
            )
        }

        return NextTenMorningsSnapshot(
            title: NextTenMorningsSnapshot.title,
            subtitle: NextTenMorningsSnapshot.subtitle,
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
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy = .active,
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
        let selectedMode = selectedQuickWakeMode(for: entry)
        let resolvedQuietModeState = entry.activeDay.effectiveConfig.dateAlarmOverride == .quiet ? .active : quietModeState
        let tagResolution = NextTenMorningsTagResolver.resolve(
            NextTenMorningsTagResolverInput(
                date: entry.schedule.date,
                dateKey: entry.id,
                resolvedDayPurpose: entry.activeDay.resolvedDayPurpose,
                resolvedContext: entry.activeDay.resolvedDayContext,
                tagResult: entry.activeDay.tagResult,
                compatibleOpportunityTags: compatibleOpportunityTags,
                quietModeState: resolvedQuietModeState,
                selectedQuickWakeMode: selectedMode,
                shawwalSixProgress: shawwalSixProgress,
                hasDayOverride: entry.hasDayOverride
            )
        )
        let isQuiet = resolvedQuietModeState == .active
        let isPaused = globalWakeAlarmPolicy == .pausedIndefinitely
            && entry.activeDay.effectiveConfig.dateAlarmOverride != .ringDespitePause
            && !isQuiet
        let leadingTime = (isQuiet || isPaused) ? nil : (entry.isEnabled ? entry.schedule.wakeDate : nil)
        let leadingStatusText: String?
        let trailingStatusText: String?
        if isQuiet {
            leadingStatusText = "Quiet"
            trailingStatusText = nil
        } else if isPaused {
            leadingStatusText = "Paused"
            trailingStatusText = "Paused"
        } else {
            leadingStatusText = entry.isEnabled ? nil : "No alarm"
            trailingStatusText = entry.isEnabled ? nil : "No alarm"
        }
        let purposeText = selectedMode == .suhoor ? "Awake for Suhoor" : "Awake for Fajr"
        let accessibilityLabel = nextTenMorningsAccessibilityLabel(
            entry: entry,
            date: entry.schedule.date,
            tags: tagResolution.accessibilityTags,
            trailingTime: leadingTime,
            trailingStatusText: leadingStatusText,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return NextTenMorningsRowDisplay(
            id: entry.id,
            dateKey: entry.id,
            date: entry.schedule.date,
            dateLabel: dateLabel,
            purposeText: purposeText,
            tags: tagResolution.visibleTags,
            allAccessibilityTags: tagResolution.accessibilityTags,
            leadingTime: leadingTime,
            leadingStatusText: leadingStatusText,
            trailingTime: nil,
            trailingStatusText: trailingStatusText,
            alarmToggleIsOn: !isQuiet && !isPaused && entry.isEnabled,
            alarmToggleIsEnabled: !isPaused && entry.isEnabled,
            selectedQuickWakeMode: selectedMode,
            isInactive: !entry.isEnabled || isQuiet || isPaused,
            accessibilityLabel: accessibilityLabel
        )
    }

    static func heroDisplay(
        entry: WakeRowEntry?,
        wakeSession: WakeSession? = nil,
        morningLog: MorningLogEntry? = nil,
        permissionSummary: String,
        locationDisplayText: String? = nil,
        locationIconName: String? = nil,
        currentDate: Date = Date(),
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy = .active,
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
                title: "Tomorrow Morning",
                dateLine: nil,
                wakeState: .unavailable,
                primaryTime: nil,
                primaryText: "Set location",
                wakeIconName: nil,
                statusText: "Set location",
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
                selectedQuickWakeMode: nil,
                quickWakeModeOptions: [],
                actionSlot: .empty,
                chipTitles: [],
                accessibilityLabel: "\(fallbackLocation). Tomorrow Morning. Set location. \(detail). Fajr times are not available yet."
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
        let resolvedWakeState = MorningWakeResolutionService.resolve(
            for: entry.activeDay,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy,
            timeZone: timeZone
        )
        let wakeState = heroWakeState(for: resolvedWakeState)
        let statusText = heroStatusText(for: entry, resolvedWakeState: resolvedWakeState)
        let selectedQuickWakeMode = resolvedWakeState.quickWakeSelection
        let relation = RelationDisplay(
            text: resolvedWakeState.copyState.finalRelationText ?? resolvedWakeState.copyState.primaryHeroText,
            tone: heroRelationTone(from: resolvedWakeState.copyState.relationTone)
        )
        let chipTitles = actionableChipTitles(for: entry)
        let fajrWindow = fajrWindowDisplay(
            for: entry,
            resolvedWakeState: resolvedWakeState,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let awaitingAwakeConfirmation = isAwaitingAwakeConfirmation(
            wakeSession: wakeSession,
            currentDate: currentDate
        )
        let pendingAttemptTime = nextPendingWakeAttemptTime(
            for: entry,
            wakeSession: wakeSession,
            currentDate: currentDate
        )
        let primaryTime = wakeState == .active
            ? (pendingAttemptTime ?? (awaitingAwakeConfirmation ? nil : resolvedWakeState.wakeTimeResolution.wakeTime))
            : nil
        let primaryText = awaitingAwakeConfirmation
            ? "Time to wake"
            : primaryDisplayText(
                for: entry,
                wakeState: wakeState,
                resolvedWakeState: resolvedWakeState,
                timeZone: timeZone
            )
        let actionSlot = heroActionSlot(
            for: entry,
            wakeSession: wakeSession,
            morningLog: morningLog,
            selectedQuickWakeMode: selectedQuickWakeMode,
            resolvedWakeState: resolvedWakeState,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let options = actionSlot.style == .empty
            ? quickWakeModeOptions(selected: selectedQuickWakeMode, relativeDayLabel: title)
            : []
        let accessibilityLabel = heroAccessibilityLabel(
            locationText: locationText,
            title: title,
            entry: entry,
            dateLine: dateLine,
            selectedQuickWakeMode: selectedQuickWakeMode,
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
            selectedQuickWakeMode: selectedQuickWakeMode,
            quickWakeModeOptions: options,
            actionSlot: actionSlot,
            chipTitles: chipTitles,
            accessibilityLabel: accessibilityLabel
        )
    }

    private static func heroActionSlot(
        for entry: WakeRowEntry,
        wakeSession: WakeSession?,
        morningLog: MorningLogEntry?,
        selectedQuickWakeMode: QuickWakeMode?,
        resolvedWakeState: ResolvedMorningWakeState,
        currentDate: Date,
        timeZone: TimeZone
    ) -> MorningHeroActionSlotDisplay {
        if resolvedWakeState.resolvedAlarmState == .pausedInherited {
            return MorningHeroActionSlotDisplay(
                style: .primary,
                primaryTitle: "Ring tomorrow only",
                secondaryText: nil,
                action: .ringOnceDespitePause,
                accessibilityLabel: "Ring tomorrow only."
            )
        }

        if resolvedWakeState.dateAlarmOverride == .quiet {
            return .empty
        }

        if wakeSession?.status == .quietMorning {
            return MorningHeroActionSlotDisplay(
                style: .quiet,
                primaryTitle: nil,
                secondaryText: "Quiet morning",
                action: .none,
                accessibilityLabel: "Quiet morning. Remaining alarms are stopped for this morning."
            )
        }

        guard let wakeSession else {
            return .empty
        }

        let prayerWindow = entry.activeDay.decisionLog.prayerWindow
        let prayerConfirmed = morningLog?.fajrPrayerOutcome == .fajrPrayerConfirmed
        let fastingIntentConfirmed = morningLog?.fastingIntentOutcome == .fastingIntentConfirmed
        let fajrWakeConfirmed = morningLog?.fajrWakeOutcome.isFajrAwakeConfirmed == true
            || (wakeSession.status == .confirmedAwake && wakeSession.confirmedWakeMode == .fajr)
        let suhoorWakeConfirmed = morningLog?.suhoorWakeOutcome.isSuhoorAwakeConfirmed == true
            || (wakeSession.status == .confirmedAwake && wakeSession.confirmedWakeMode == .suhoor)
        let postAwakeActionReady = wakeSession.confirmedAt.map {
            currentDate >= $0.addingTimeInterval(1.5)
        } ?? false
        let primaryHasFired = currentDate >= wakeSession.plannedWakeTime
            || wakeSession.status == .primaryAlarmFired
            || wakeSession.status == .unconfirmed
            || wakeSession.status == .wakeChecksPending

        if prayerConfirmed {
            return .empty
        }

        if wakeSession.mode == .suhoor, currentDate >= prayerWindow.fajrStart {
            if suhoorWakeConfirmed {
                return confirmedAwakeSlot(session: wakeSession, timeZone: timeZone)
            }
            if fajrWakeConfirmed {
                return confirmedAwakeSlot(session: wakeSession, timeZone: timeZone)
            }
            return awaitingConfirmationSlot(session: wakeSession)
        }

        if wakeSession.mode == .fajr, fajrWakeConfirmed {
            _ = postAwakeActionReady
            return confirmedAwakeSlot(session: wakeSession, timeZone: timeZone)
        }

        if wakeSession.mode == .suhoor, suhoorWakeConfirmed {
            _ = fastingIntentConfirmed
            _ = postAwakeActionReady
            return confirmedAwakeSlot(session: wakeSession, timeZone: timeZone)
        }

        if primaryHasFired {
            return awaitingConfirmationSlot(session: wakeSession)
        }

        if isActiveBeforePrimary(wakeSession: wakeSession, currentDate: currentDate) {
            return MorningHeroActionSlotDisplay(
                style: .compact,
                primaryTitle: activeWakeConfirmationTitle(for: wakeSession.mode),
                secondaryText: nil,
                action: .confirmAwake(wakeSession.mode),
                accessibilityLabel: "Confirm awake for \(wakeSession.mode.confirmationTitle)."
            )
        }

        return .empty
    }

    private static func isActiveBeforePrimary(
        wakeSession: WakeSession,
        currentDate: Date
    ) -> Bool {
        let activeStart: Date
        switch wakeSession.mode {
        case .suhoor:
            activeStart = wakeSession.finalThirdStart ?? wakeSession.plannedWakeTime.addingTimeInterval(-30 * 60)
        case .fajr:
            activeStart = wakeSession.fajrBegins
        }
        return currentDate >= activeStart && currentDate < wakeSession.plannedWakeTime
    }

    private static func isAwaitingAwakeConfirmation(
        wakeSession: WakeSession?,
        currentDate: Date
    ) -> Bool {
        guard let wakeSession, !wakeSession.status.isTerminal else { return false }
        return currentDate >= wakeSession.plannedWakeTime
            || wakeSession.status == .primaryAlarmFired
            || wakeSession.status == .unconfirmed
            || wakeSession.status == .wakeChecksPending
    }

    private static func awaitingConfirmationSlot(session: WakeSession) -> MorningHeroActionSlotDisplay {
        let secondaryText = session.wakeCheckScheduledEventIDs.isEmpty
            ? "Final alarm this morning"
            : "Tap when you’re awake."
        return MorningHeroActionSlotDisplay(
            style: .primary,
            primaryTitle: activeWakeConfirmationTitle(for: session.mode),
            secondaryText: secondaryText,
            action: .confirmAwake(session.mode),
            accessibilityLabel: "Confirm awake. \(secondaryText)"
        )
    }

    private static func confirmedAwakeSlot(
        session: WakeSession,
        timeZone: TimeZone
    ) -> MorningHeroActionSlotDisplay {
        let confirmedText = "Awake for \(session.confirmedWakeMode?.confirmationTitle ?? session.mode.confirmationTitle)"
        return MorningHeroActionSlotDisplay(
            style: .confirmation,
            primaryTitle: confirmedText,
            secondaryText: session.confirmedAt.map { "Confirmed at \(timeFormatter(timeZone: timeZone).string(from: $0))" },
            action: .none,
            accessibilityLabel: "\(confirmedText)."
        )
    }

    private static func fajrPrayerActionSlot() -> MorningHeroActionSlotDisplay {
        MorningHeroActionSlotDisplay(
            style: .primary,
            primaryTitle: "I Prayed Fajr",
            secondaryText: nil,
            action: .confirmFajrPrayer,
            accessibilityLabel: "Confirm Fajr prayer for this morning."
        )
    }

    static func fajrPrayerContextActionSlot() -> MorningHeroActionSlotDisplay {
        fajrPrayerActionSlot()
    }

    static func shouldShowFajrPrayerContextAction(
        for entry: WakeRowEntry,
        wakeSession: WakeSession?,
        morningLog: MorningLogEntry?,
        currentDate: Date
    ) -> Bool {
        guard let wakeSession else { return false }
        guard morningLog?.fajrPrayerOutcome == .unconfirmed || morningLog?.fajrPrayerOutcome == nil else { return false }
        guard morningLog?.fajrWakeOutcome.isFajrAwakeConfirmed == true
                || (wakeSession.status == .confirmedAwake && wakeSession.confirmedWakeMode == .fajr)
                || morningLog?.fajrWakeOutcome == .confirmedEarlyAwakeForFajr else {
            return false
        }
        let prayerWindow = entry.activeDay.decisionLog.prayerWindow
        guard currentDate >= prayerWindow.fajrStart else { return false }
        if let fajrEnd = prayerWindow.fajrEnd, currentDate >= fajrEnd {
            return false
        }
        guard let confirmedAt = wakeSession.confirmedAt else { return true }
        return currentDate >= confirmedAt.addingTimeInterval(1.5)
    }

    static func eligibleEarlyAwakeMode(
        for entry: WakeRowEntry,
        morningLog: MorningLogEntry?,
        currentDate: Date,
        timeZone: TimeZone = .current
    ) -> WakeSessionMode? {
        guard currentDate >= DateHelpers.startOfToday(in: timeZone, now: currentDate) else {
            return nil
        }
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
        if selectedMode == .suhoor,
           morningLog?.suhoorWakeOutcome.isSuhoorAwakeConfirmed != true,
           let finalThirdStart = EarlyWorshipBoundaryResolver.finalThirdStart(
            targetFajrStart: entry.activeDay.decisionLog.prayerWindow.fajrStart,
            maghrib: entry.activeDay.decisionLog.prayerWindow.maghrib,
            timeZone: timeZone
           ),
           currentDate < finalThirdStart {
            return .suhoor
        }
        if selectedMode == .fajr,
           morningLog?.fajrWakeOutcome.isFajrAwakeConfirmed != true,
           currentDate < entry.activeDay.decisionLog.prayerWindow.fajrStart {
            return .fajr
        }
        return nil
    }

    private static func activeWakeConfirmationTitle(for mode: WakeSessionMode) -> String {
        switch mode {
        case .fajr:
            return "I’m Awake for Fajr"
        case .suhoor:
            return "I’m Awake for Suhoor"
        }
    }

    private static func nextPendingWakeAttemptTime(
        for entry: WakeRowEntry,
        wakeSession: WakeSession?,
        currentDate: Date
    ) -> Date? {
        guard let wakeSession, !wakeSession.status.isTerminal else {
            return nil
        }

        return entry.activeDay.scheduledEvents
            .filter { event in
                guard event.deliveryKinds.contains(.wake) else { return false }
                guard event.wakeSessionRole == .primaryWake || event.wakeSessionRole == .wakeCheck else { return false }
                if let eventWakeSessionID = event.wakeSessionID {
                    guard eventWakeSessionID == wakeSession.wakeSessionID else { return false }
                }
                guard event.fireDate > currentDate else { return false }
                guard wakeSession.firedScheduledEventIDs.contains(event.id) == false else { return false }
                guard wakeSession.stoppedScheduledEventIDs.contains(event.id) == false else { return false }
                return true
            }
            .sorted { $0.fireDate < $1.fireDate }
            .first?
            .fireDate
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
        let upperBoundaryTime = display.wakeAdjustmentFajrEndTime ?? maxTime
        let relation = adjustedWakeRelation(
            wakeTime: clampedWake,
            minTime: minTime,
            upperBoundaryTime: upperBoundaryTime,
            visualMode: display.fajrWindowVisualMode
        )
        let detailText = relation.text
        let ratio = wakeWindowPositionRatio(
            wakeDate: clampedWake,
            fajrStart: minTime,
            fajrEnd: upperBoundaryTime
        )
        let primaryText = timeFormatter(timeZone: timeZone).string(from: clampedWake)
        let accessibilityValue = wakeAdjustmentAccessibilityValue(
            wakeTime: clampedWake,
            relationText: detailText,
            minTime: minTime,
            maxTime: maxTime,
            fajrEnd: upperBoundaryTime,
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
            selectedQuickWakeMode: display.selectedQuickWakeMode,
            quickWakeModeOptions: display.quickWakeModeOptions,
            actionSlot: display.actionSlot,
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
                return "Suhoor selected"
            }
            return "Suhoor selected; \(details.joined(separator: ", "))"
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
        if row.alarmToggleIsEnabled || row.leadingStatusText == "Quiet" {
            return 54
        }

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

    private static func heroStatusText(
        for entry: WakeRowEntry,
        resolvedWakeState: ResolvedMorningWakeState? = nil
    ) -> String {
        let resolvedWakeState = resolvedWakeState
            ?? MorningWakeResolutionService.resolve(for: entry.activeDay)

        if resolvedWakeState.dateAlarmOverride == .quiet {
            return "Quiet"
        }
        if resolvedWakeState.resolvedAlarmState == .pausedInherited {
            return "Alarms paused"
        }
        if resolvedWakeState.resolvedAlarmState == .ringsOnceDespitePause {
            return "Rings tomorrow only"
        }
        if resolvedWakeState.alarmActivation == .unavailable {
            return "Set location"
        }

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
            return "Suhoor planned"
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

    private static func conciseWakeRelation(
        for entry: WakeRowEntry,
        relativeDayLabel: String? = nil,
        timeZone: TimeZone
    ) -> RelationDisplay {
        let resolvedWakeState = MorningWakeResolutionService.resolve(for: entry.activeDay, timeZone: timeZone)
        if resolvedWakeState.dateAlarmOverride == .quiet {
            let day = relativeDayLabel.map(quickWakeModeRelativeDayReference) ?? "this date"
            let text = "Quiet for \(day)"
            return RelationDisplay(text: text, tone: .normal)
        }

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
        if resolvedWakeState.underlyingWakeMode == .earlyWorship,
           let finalThirdStart = resolvedWakeState.wakeBoundaryResolution.finalThirdStart,
           entry.schedule.wakeDate >= finalThirdStart,
           entry.schedule.wakeDate <= prayerWindow.fajrStart {
            return activeEarlyWorshipWakeRelation(
                wakeTime: entry.schedule.wakeDate,
                finalThirdStart: finalThirdStart,
                fajrStart: prayerWindow.fajrStart
            )
        }
        return activeHeroWakeRelation(
            wakeTime: entry.schedule.wakeDate,
            fajrStart: prayerWindow.fajrStart,
            fajrEnd: fajrEnd
        )
    }

    private static func selectedQuickWakeMode(for entry: WakeRowEntry) -> QuickWakeMode {
        WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
    }

    static func requiresSuhoorToFajrSwitchConfirmation(
        entry: WakeRowEntry?,
        wakeSession: WakeSession?,
        display: MorningHomeHeroDisplay,
        currentDate: Date,
        timeZone: TimeZone
    ) -> Bool {
        guard display.title == "Today Morning",
              display.selectedQuickWakeMode == .suhoor,
              let entry,
              let wakeSession,
              wakeSession.mode == .suhoor,
              !wakeSession.status.isTerminal else {
            return false
        }

        let prayerWindow = entry.activeDay.decisionLog.prayerWindow
        guard let finalThirdStart = EarlyWorshipBoundaryResolver.finalThirdStart(
            targetFajrStart: prayerWindow.fajrStart,
            maghrib: prayerWindow.maghrib,
            timeZone: timeZone
        ) else {
            return false
        }

        return currentDate >= finalThirdStart && currentDate < prayerWindow.fajrStart
    }

    private static func quickWakeModeOptions(
        selected: QuickWakeMode,
        relativeDayLabel: String
    ) -> [MorningHeroQuickWakeModeOption] {
        [QuickWakeMode.suhoor, .fajr].map { mode in
            MorningHeroQuickWakeModeOption(
                mode: mode,
                title: mode.displayTitle,
                isSelected: mode == selected,
                accessibilityLabel: "\(mode.displayTitle)\(mode == selected ? ", selected" : "")",
                accessibilityHint: quickWakeModeAccessibilityHint(mode: mode, relativeDayLabel: relativeDayLabel)
            )
    }
}

    private static func quickWakeModeAccessibilityHint(mode: QuickWakeMode, relativeDayLabel: String) -> String {
        let day = quickWakeModeRelativeDayReference(relativeDayLabel)
        switch mode {
        case .suhoor:
            return "Wakes 30 min before Fajr begins for suhoor on \(day)."
        case .fajr:
            return "Wakes 30 min before Fajr ends for \(day)."
        case .quiet:
            return "No alarm will ring for \(day)."
        }
    }

    private static func quickWakeModeRelativeDayReference(_ label: String) -> String {
        switch label {
        case "Today", "Tomorrow":
            return label.lowercased()
        case "Today Morning":
            return "today morning"
        case "Tomorrow Morning":
            return "tomorrow morning"
        default:
            return label
        }
    }

    private static func actionableChipTitles(for entry: WakeRowEntry) -> [String] {
        let redundantTitles: Set<String> = [
            "Fasting",
            "Qada",
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

    private static func heroWakeState(for resolvedWakeState: ResolvedMorningWakeState) -> MorningHeroWakeState {
        switch resolvedWakeState.alarmActivation {
        case .active:
            return .active
        case .quietSuppressed:
            return .quietHours
        case .pausedSuppressed:
            return .offWithAnchor
        case .offWithAnchor:
            return .offWithAnchor
        case .noAnchor:
            return .noAlarm
        case .unavailable:
            return .unavailable
        }
    }

    private static func heroWakeState(for entry: WakeRowEntry) -> MorningHeroWakeState {
        let resolvedWakeState = MorningWakeResolutionService.resolve(for: entry.activeDay)
        if resolvedWakeState.alarmActivation != .active {
            return heroWakeState(for: resolvedWakeState)
        }
        guard entry.isEnabled else {
            return entry.activeDay.effectiveConfig.skipDay ? .offWithAnchor : .noAlarm
        }
        return .active
    }

    private static func primaryDisplayText(
        for entry: WakeRowEntry,
        wakeState: MorningHeroWakeState,
        resolvedWakeState: ResolvedMorningWakeState? = nil,
        timeZone: TimeZone
    ) -> String {
        let resolvedWakeState = resolvedWakeState
            ?? MorningWakeResolutionService.resolve(for: entry.activeDay, timeZone: timeZone)
        switch wakeState {
        case .active:
            return resolvedWakeState.copyState.primaryHeroText
        case .offWithAnchor:
            if resolvedWakeState.resolvedAlarmState == .pausedInherited {
                return resolvedWakeState.copyState.primaryHeroText
            }
            return "Alarm off"
        case .noAlarm:
            return "No alarm set"
        case .quietHours:
            return resolvedWakeState.copyState.primaryHeroText
        case .unavailable:
            return "Set location"
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
            return RelationDisplay(text: "As Fajr begins", tone: tone)
        }
        if isEndpoint(wakeTime, fajrEnd) {
            return RelationDisplay(text: "As Fajr ends", tone: tone)
        }
        return RelationDisplay(
            text: fajrEndOffsetText(wakeTime: wakeTime, fajrEnd: fajrEnd),
            tone: tone
        )
    }

    private static func activeEarlyWorshipWakeRelation(
        wakeTime: Date,
        finalThirdStart: Date,
        fajrStart: Date
    ) -> RelationDisplay {
        if isEndpoint(wakeTime, finalThirdStart) {
            return RelationDisplay(text: "At the last third of the night", tone: .normal)
        }
        if isEndpoint(wakeTime, fajrStart) {
            return RelationDisplay(text: "As Fajr begins", tone: .normal)
        }

        let minutes = Int(round(fajrStart.timeIntervalSince(wakeTime) / 60))
        return RelationDisplay(text: "\(minutes) min before Fajr begins", tone: .normal)
    }

    private static func isEndpoint(_ lhs: Date, _ rhs: Date) -> Bool {
        abs(lhs.timeIntervalSince(rhs)) < 60
    }

    private static func urgentRelationTone(wakeTime: Date, fajrEnd: Date) -> MorningHeroRelationTone {
        let minutesBeforeFajrEnd = Int(round(fajrEnd.timeIntervalSince(wakeTime) / 60))
        return minutesBeforeFajrEnd <= 14 ? .urgentRed : .normal
    }

    private static func heroRelationTone(from tone: WakeCopyTone) -> MorningHeroRelationTone {
        switch tone {
        case .urgentRed:
            return .urgentRed
        case .normal, .warning, .stateText:
            return .normal
        }
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
        resolvedWakeState: ResolvedMorningWakeState,
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
        let indicatorState = wakeWindowIndicatorState(for: resolvedWakeState)
        let markerDate = wakeWindowMarkerDate(for: entry, indicatorState: indicatorState)

        if resolvedWakeState.dateAlarmOverride == .quiet,
           resolvedWakeState.underlyingWakeMode == .fajr {
            let beginText = formatter.string(from: window.fajrStart)
            let endText = formatter.string(from: fajrEnd)
            let relationVerbText = "Fajr \(beginVerb): \(beginText). Fajr \(endVerb): \(endText)"
            return FajrWindowDisplay(
                beginText: beginText,
                endText: endText,
                fallbackText: "Fajr \(beginVerb): \(beginText) • Fajr \(endVerb): \(endText)",
                accessibilityText: relationVerbText,
                wakePositionRatio: nil,
                indicatorState: .none,
                leftBoundaryMarkerStyle: .endpointCircle,
                rightBoundaryMarkerStyle: .endpointCircle,
                visualMode: heroVisualMode(from: resolvedWakeState.visualMode),
                adjustmentMinTime: nil,
                adjustmentMaxTime: nil,
                adjustmentFajrEndTime: nil,
                adjustmentStepMinutes: 1,
                adjustmentRelationAnchor: nil,
                adjustmentAccessibilityValue: nil
            )
        }

        if resolvedWakeState.underlyingWakeMode == .earlyWorship {
            guard let finalThirdStart = resolvedWakeState.wakeBoundaryResolution.finalThirdStart else {
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
            let latestWakeTime = window.fajrStart.addingTimeInterval(-5 * 60)
            let accessibilityText = "Final third of the night begins at \(beginText). Fajr begins at \(endText)"
            let ratio = markerDate.flatMap {
                wakeWindowPositionRatio(wakeDate: $0, fajrStart: finalThirdStart, fajrEnd: window.fajrStart)
            }
            let visualMode = heroVisualMode(from: resolvedWakeState.visualMode)
            let adjustmentEnabled = visualMode.isInteractive
            let adjustmentAccessibilityValue: String?
            if adjustmentEnabled {
                adjustmentAccessibilityValue = wakeAdjustmentAccessibilityValue(
                    wakeTime: entry.schedule.wakeDate,
                    relationText: conciseWakeRelation(for: entry, timeZone: timeZone).text,
                    minTime: finalThirdStart,
                    maxTime: latestWakeTime,
                    fajrEnd: window.fajrStart,
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
                adjustmentMaxTime: adjustmentEnabled ? latestWakeTime : nil,
                adjustmentFajrEndTime: adjustmentEnabled ? window.fajrStart : nil,
                adjustmentStepMinutes: 1,
                adjustmentRelationAnchor: adjustmentEnabled ? .fajrStart : nil,
                adjustmentAccessibilityValue: adjustmentAccessibilityValue
            )
        }

        let beginText = formatter.string(from: window.fajrStart)
        let endText = formatter.string(from: fajrEnd)
        let latestWakeTime = fajrEnd.addingTimeInterval(-5 * 60)
        let relationVerbText = "Fajr \(beginVerb): \(beginText). Fajr \(endVerb): \(endText)"
        let ratio = markerDate.flatMap {
            wakeWindowPositionRatio(wakeDate: $0, fajrStart: window.fajrStart, fajrEnd: fajrEnd)
        }
        let visualMode = heroVisualMode(from: resolvedWakeState.visualMode)
        let adjustmentEnabled = visualMode.isInteractive
        let relationAnchor = adjustmentEnabled ? adjustmentRelationAnchor(for: entry) : nil
        let adjustmentAccessibilityValue: String?
        if adjustmentEnabled {
            adjustmentAccessibilityValue = wakeAdjustmentAccessibilityValue(
                wakeTime: entry.schedule.wakeDate,
                relationText: conciseWakeRelation(for: entry, timeZone: timeZone).text,
                minTime: window.fajrStart,
                maxTime: latestWakeTime,
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
            adjustmentMaxTime: adjustmentEnabled ? latestWakeTime : nil,
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
        selectedQuickWakeMode: QuickWakeMode?,
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
        let selectedModeText = selectedQuickWakeMode.map { "\($0.displayTitle) selected" }

        return [
            locationText,
            title,
            selectedModeText,
            wakeText,
            detailText,
            fajrWindowAccessibilityText.replacingOccurrences(of: " • ", with: ". ")
        ]
            .compactMap { $0 }
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
            return "Today Morning"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           targetStart == tomorrow {
            return "Tomorrow Morning"
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
        case .noAlarm, .quietHours:
            return .none
        case .unavailable:
            return .unavailable
        }
    }

    private static func wakeWindowIndicatorState(
        for resolvedWakeState: ResolvedMorningWakeState
    ) -> MorningHeroWakeWindowIndicatorState {
        switch heroWakeState(for: resolvedWakeState) {
        case .active:
            return .active
        case .offWithAnchor:
            return .offAnchor
        case .noAlarm, .quietHours:
            return .none
        case .unavailable:
            return .unavailable
        }
    }

    private static func heroVisualMode(from mode: MorningWakeVisualMode) -> MorningHeroFajrWindowVisualMode {
        switch mode {
        case .interactiveDefaultFajr:
            return .interactiveWithinFajrWindow
        case .staticDefaultFajrQuiet, .staticNoAlarmWithBoundaries:
            return .staticWithinFajrWindow
        case .interactiveEarlyWorship:
            return .interactiveEarlyWorshipWindow
        case .staticEarlyWorshipQuiet:
            return .staticEarlyWorshipWindow
        case .hiddenUnavailable:
            return .hiddenUnavailable
        case .hiddenOutOfRange:
            return .hiddenOutOfWindow
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
        WakeStateSelectionResolver.isEarlyWorshipMorning(entry.activeDay)
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
        upperBoundaryTime: Date,
        visualMode: MorningHeroFajrWindowVisualMode
    ) -> RelationDisplay {
        if visualMode.isEarlyWorship {
            return activeEarlyWorshipWakeRelation(
                wakeTime: wakeTime,
                finalThirdStart: minTime,
                fajrStart: upperBoundaryTime
            )
        }

        return activeHeroWakeRelation(wakeTime: wakeTime, fajrStart: minTime, fajrEnd: upperBoundaryTime)
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
            return "Wake alarm at \(formatter.string(from: wakeTime)), \(relationText). Adjustable between the final third of the night at \(formatter.string(from: minTime)) and the latest wake time at \(formatter.string(from: maxTime)), before Fajr begins at \(formatter.string(from: fajrEnd))."
        }

        return "Wake alarm at \(formatter.string(from: wakeTime)), \(relationText). Adjustable between Fajr begin at \(formatter.string(from: minTime)) and the latest wake time at \(formatter.string(from: maxTime)), before Fajr ends at \(formatter.string(from: fajrEnd))."
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
