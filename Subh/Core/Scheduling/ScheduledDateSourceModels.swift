import Foundation

enum RecurringIslamicRule: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case whiteDays
    case mondayThursday
    case ramadan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .whiteDays:
            return "White Days"
        case .mondayThursday:
            return "Monday & Thursday"
        case .ramadan:
            return "Ramadan"
        }
    }

    var detailText: String {
        switch self {
        case .whiteDays:
            return "Adds the 13th, 14th, and 15th of each Hijri month for the next year."
        case .mondayThursday:
            return "Adds upcoming Mondays and Thursdays for the next Hijri year."
        case .ramadan:
            return "Every day of Ramadan."
        }
    }

    static let addFlowVisibleCases: [RecurringIslamicRule] = [
        .whiteDays,
        .mondayThursday
    ]
}

enum IslamicQuickAddKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case nextAshura
    case nextArafah
    case nextDhulHijjahFirstNine
    case nextEidAlFitr
    case nextEidAlAdha
    case nextWhiteDays
    case nextRamadanMonth
    case nextMondayThursdayPair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nextAshura:
            return "Next Ashura"
        case .nextArafah:
            return "Next Arafah"
        case .nextDhulHijjahFirstNine:
            return "First 9 of Dhul Hijjah"
        case .nextEidAlFitr:
            return "Next Eid al-Fitr"
        case .nextEidAlAdha:
            return "Next Eid al-Adha"
        case .nextWhiteDays:
            return "Next White Days"
        case .nextRamadanMonth:
            return "Next Ramadan Month"
        case .nextMondayThursdayPair:
            return "Next Monday + Thursday"
        }
    }

    var detailText: String {
        switch self {
        case .nextAshura:
            return "Recommended Ashura pairing, or add all three dates."
        case .nextArafah:
            return "Next corrected 9 Dhul Hijjah."
        case .nextDhulHijjahFirstNine:
            return "First nine days of Dhul Hijjah."
        case .nextEidAlFitr:
            return "Next corrected 1 Shawwal."
        case .nextEidAlAdha:
            return "Next corrected 10 Dhul Hijjah."
        case .nextWhiteDays:
            return "Next corrected 13, 14, and 15."
        case .nextRamadanMonth:
            return "Next corrected Ramadan run."
        case .nextMondayThursdayPair:
            return "Next Monday and Thursday."
        }
    }

    static let addFlowVisibleCases: [IslamicQuickAddKind] = [
        .nextAshura,
        .nextArafah,
        .nextDhulHijjahFirstNine,
        .nextWhiteDays,
        .nextMondayThursdayPair
    ]

    var isHijriBased: Bool {
        switch self {
        case .nextMondayThursdayPair:
            return false
        default:
            return true
        }
    }
}

struct SingleDaySource: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let date: Date
}

struct GregorianRangeSource: Codable, Equatable, Hashable, Sendable {
    static let maxLengthDays = 60

    let startDate: Date
    let endDate: Date

    init(startDate: Date, endDate: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
        let normalizedEnd = calendar.startOfDay(for: max(startDate, endDate))
        let daySpan = calendar.dateComponents([.day], from: normalizedStart, to: normalizedEnd).day ?? 0
        let cappedSpan = min(daySpan, Self.maxLengthDays - 1)
        self.startDate = normalizedStart
        self.endDate = calendar.date(byAdding: .day, value: cappedSpan, to: normalizedStart) ?? normalizedEnd
    }
}

struct RecurringIslamicSource: Codable, Equatable, Hashable, Sendable {
    let rule: RecurringIslamicRule
    let startDate: Date
}

struct HijriSingleDaySource: Codable, Equatable, Hashable, Sendable {
    let hijriYear: Int
    let month: HijriMonth
    let day: Int
}

enum ScheduledDateSourceKind: Codable, Equatable, Hashable, Sendable {
    case singleDay(SingleDaySource)
    case gregorianRange(GregorianRangeSource)
    case recurringIslamic(RecurringIslamicSource)
    case hijriSingleDay(HijriSingleDaySource)

    private enum CodingKeys: String, CodingKey {
        case type
        case singleDay
        case gregorianRange
        case recurringIslamic
        case hijriSingleDay
    }

    private enum SourceType: String, Codable {
        case singleDay
        case gregorianRange
        case recurringIslamic
        case hijriSingleDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(SourceType.self, forKey: .type) {
        case .singleDay:
            self = .singleDay(try container.decode(SingleDaySource.self, forKey: .singleDay))
        case .gregorianRange:
            self = .gregorianRange(try container.decode(GregorianRangeSource.self, forKey: .gregorianRange))
        case .recurringIslamic:
            self = .recurringIslamic(try container.decode(RecurringIslamicSource.self, forKey: .recurringIslamic))
        case .hijriSingleDay:
            self = .hijriSingleDay(try container.decode(HijriSingleDaySource.self, forKey: .hijriSingleDay))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .singleDay(let source):
            try container.encode(SourceType.singleDay, forKey: .type)
            try container.encode(source, forKey: .singleDay)
        case .gregorianRange(let source):
            try container.encode(SourceType.gregorianRange, forKey: .type)
            try container.encode(source, forKey: .gregorianRange)
        case .recurringIslamic(let source):
            try container.encode(SourceType.recurringIslamic, forKey: .type)
            try container.encode(source, forKey: .recurringIslamic)
        case .hijriSingleDay(let source):
            try container.encode(SourceType.hijriSingleDay, forKey: .type)
            try container.encode(source, forKey: .hijriSingleDay)
        }
    }
}

enum ScheduledDateSourceOrigin: Codable, Equatable, Hashable, Sendable {
    case defaultDailyPlan
    case defaultRamadan
    case manualSingleDay
    case manualGregorianRange
    case islamicQuickAdd(IslamicQuickAddKind)
    case recurringIslamic(RecurringIslamicRule)
    case migratedLegacyAlways
    case migratedLegacyDateRange

    private enum CodingKeys: String, CodingKey {
        case type
        case islamicQuickAdd
        case recurringIslamic
    }

    private enum OriginType: String, Codable {
        case defaultDailyPlan
        case defaultRamadan
        case manualSingleDay
        case manualGregorianRange
        case islamicQuickAdd
        case recurringIslamic
        case migratedLegacyAlways
        case migratedLegacyDateRange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(OriginType.self, forKey: .type) {
        case .defaultDailyPlan:
            self = .defaultDailyPlan
        case .defaultRamadan:
            self = .defaultRamadan
        case .manualSingleDay:
            self = .manualSingleDay
        case .manualGregorianRange:
            self = .manualGregorianRange
        case .islamicQuickAdd:
            self = .islamicQuickAdd(try container.decode(IslamicQuickAddKind.self, forKey: .islamicQuickAdd))
        case .recurringIslamic:
            self = .recurringIslamic(try container.decode(RecurringIslamicRule.self, forKey: .recurringIslamic))
        case .migratedLegacyAlways:
            self = .migratedLegacyAlways
        case .migratedLegacyDateRange:
            self = .migratedLegacyDateRange
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .defaultDailyPlan:
            try container.encode(OriginType.defaultDailyPlan, forKey: .type)
        case .defaultRamadan:
            try container.encode(OriginType.defaultRamadan, forKey: .type)
        case .manualSingleDay:
            try container.encode(OriginType.manualSingleDay, forKey: .type)
        case .manualGregorianRange:
            try container.encode(OriginType.manualGregorianRange, forKey: .type)
        case .islamicQuickAdd(let kind):
            try container.encode(OriginType.islamicQuickAdd, forKey: .type)
            try container.encode(kind, forKey: .islamicQuickAdd)
        case .recurringIslamic(let rule):
            try container.encode(OriginType.recurringIslamic, forKey: .type)
            try container.encode(rule, forKey: .recurringIslamic)
        case .migratedLegacyAlways:
            try container.encode(OriginType.migratedLegacyAlways, forKey: .type)
        case .migratedLegacyDateRange:
            try container.encode(OriginType.migratedLegacyDateRange, forKey: .type)
        }
    }

    var label: String {
        switch self {
        case .defaultDailyPlan:
            return "Provided by your daily morning plan"
        case .defaultRamadan:
            return "Part of the Ramadan schedule"
        case .manualSingleDay:
            return "Added manually"
        case .manualGregorianRange:
            return "Part of a saved date range"
        case .islamicQuickAdd(let kind):
            return "Added from \(kind.sourceDisplayTitle)"
        case .recurringIslamic(let rule):
            return "Generated by the \(rule.title) recurring schedule"
        case .migratedLegacyAlways:
            return "Part of a migrated 60-day date range"
        case .migratedLegacyDateRange:
            return "Part of a migrated date range"
        }
    }

    var stopSeriesLabel: String? {
        switch self {
        case .defaultDailyPlan:
            return nil
        case .defaultRamadan:
            return nil
        case .manualSingleDay:
            return nil
        case .manualGregorianRange:
            return "Remove date range"
        case .islamicQuickAdd(let kind):
            return "Remove \(kind.sourceDisplayTitle) schedule"
        case .recurringIslamic(let rule):
            return "Stop \(rule.title) schedule"
        case .migratedLegacyAlways:
            return "Remove migrated 60-day date range"
        case .migratedLegacyDateRange:
            return "Remove migrated date range"
        }
    }

    var isExplicitOneOff: Bool {
        switch self {
        case .manualSingleDay:
            return true
        case .defaultDailyPlan, .defaultRamadan, .manualGregorianRange, .islamicQuickAdd, .recurringIslamic, .migratedLegacyAlways, .migratedLegacyDateRange:
            return false
        }
    }

    var planningRuleID: String {
        switch self {
        case .defaultDailyPlan:
            return "default-daily-plan"
        case .defaultRamadan:
            return "default-ramadan"
        case .manualSingleDay:
            return "manual-single-day"
        case .manualGregorianRange:
            return "manual-gregorian-range"
        case .islamicQuickAdd(let kind):
            return "islamic-quick-add-\(kind.rawValue)"
        case .recurringIslamic(let rule):
            return "recurring-islamic-\(rule.rawValue)"
        case .migratedLegacyAlways:
            return "migrated-legacy-always"
        case .migratedLegacyDateRange:
            return "migrated-legacy-date-range"
        }
    }
}

enum MorningIntentAnchorKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case gregorianDate
    case hijriDate
    case observance
    case weekdayPattern
    case hijriMonthWindow
    case gregorianRange
    case immediateAlarm
    case defaultSetting
    case completionHistory

    var id: String { rawValue }
}

struct MorningIntentAnchor: Codable, Equatable, Hashable, Sendable {
    let kind: MorningIntentAnchorKind
    let gregorianDateKey: String?
    let startDateKey: String?
    let endDateKey: String?
    let hijriYear: Int?
    let hijriMonth: HijriMonth?
    let hijriDay: Int?
    let observanceID: String?
    let occurrenceID: String?
    let weekdays: [Int]
    let ruleID: String?
    let activeAlarmID: String?
    let historyID: String?

    init(
        kind: MorningIntentAnchorKind,
        gregorianDateKey: String? = nil,
        startDateKey: String? = nil,
        endDateKey: String? = nil,
        hijriYear: Int? = nil,
        hijriMonth: HijriMonth? = nil,
        hijriDay: Int? = nil,
        observanceID: String? = nil,
        occurrenceID: String? = nil,
        weekdays: [Int] = [],
        ruleID: String? = nil,
        activeAlarmID: String? = nil,
        historyID: String? = nil
    ) {
        self.kind = kind
        self.gregorianDateKey = gregorianDateKey
        self.startDateKey = startDateKey
        self.endDateKey = endDateKey
        self.hijriYear = hijriYear
        self.hijriMonth = hijriMonth
        self.hijriDay = hijriDay
        self.observanceID = observanceID
        self.occurrenceID = occurrenceID
        self.weekdays = Array(Set(weekdays)).sorted()
        self.ruleID = ruleID
        self.activeAlarmID = activeAlarmID
        self.historyID = historyID
    }

    static func gregorianDate(_ dateKey: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .gregorianDate, gregorianDateKey: dateKey)
    }

    static func gregorianRange(startDateKey: String, endDateKey: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .gregorianRange, startDateKey: startDateKey, endDateKey: endDateKey)
    }

    static func hijriDate(year: Int, month: HijriMonth, day: Int) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .hijriDate, hijriYear: year, hijriMonth: month, hijriDay: day)
    }

    static func observance(_ id: String, occurrenceID: String? = nil) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .observance, observanceID: id, occurrenceID: occurrenceID)
    }

    static func weekdayPattern(_ weekdays: [Int], ruleID: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .weekdayPattern, weekdays: weekdays, ruleID: ruleID)
    }

    static func hijriMonthWindow(month: HijriMonth, year: Int?, ruleID: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .hijriMonthWindow, hijriYear: year, hijriMonth: month, ruleID: ruleID)
    }

    static func defaultSetting(ruleID: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .defaultSetting, ruleID: ruleID)
    }

    static func immediateAlarm(activeAlarmID: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .immediateAlarm, activeAlarmID: activeAlarmID)
    }

    static func completionHistory(historyID: String, dateKey: String) -> MorningIntentAnchor {
        MorningIntentAnchor(kind: .completionHistory, gregorianDateKey: dateKey, historyID: historyID)
    }

    var isCalendarMovable: Bool {
        switch kind {
        case .hijriDate, .observance, .hijriMonthWindow:
            return true
        case .gregorianDate, .weekdayPattern, .gregorianRange, .immediateAlarm, .defaultSetting, .completionHistory:
            return false
        }
    }

    var summaryText: String {
        switch kind {
        case .gregorianDate:
            return gregorianDateKey.map { "Stays on \($0)" } ?? "Stays on this date"
        case .gregorianRange:
            if let startDateKey, let endDateKey {
                return "Stays from \(startDateKey) to \(endDateKey)"
            }
            return "Stays on this date range"
        case .hijriDate:
            if let hijriDay, let hijriMonth, let hijriYear {
                return "Moves with \(hijriDay) \(hijriMonth.displayName) \(hijriYear)"
            }
            return "Moves with this Hijri date"
        case .observance:
            return observanceID.map { "Moves with \($0)" } ?? "Moves with this observance"
        case .weekdayPattern:
            return "Repeats by weekday"
        case .hijriMonthWindow:
            return hijriMonth.map { "Moves with \($0.displayName)" } ?? "Moves with this Hijri month"
        case .immediateAlarm:
            return "Applies to the next active alarm"
        case .defaultSetting:
            return "Follows the default setting"
        case .completionHistory:
            return gregorianDateKey.map { "History fixed on \($0)" } ?? "History stays fixed"
        }
    }
}

struct CalendarVersionSnapshot: Codable, Equatable, Hashable, Sendable {
    let createdDateKey: String?
    let timeZoneIdentifier: String?
    let hijriAdjustmentFingerprint: String?

    init(
        createdDateKey: String? = nil,
        timeZoneIdentifier: String? = nil,
        hijriAdjustmentFingerprint: String? = nil
    ) {
        self.createdDateKey = createdDateKey
        self.timeZoneIdentifier = timeZoneIdentifier
        self.hijriAdjustmentFingerprint = hijriAdjustmentFingerprint
    }
}

enum PlanningReviewStateKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case movedByHijriAdjustment
    case stayedAfterHijriAdjustment
    case needsReview
    case expiredImmediateAlarm

    var id: String { rawValue }
}

struct PlanningReviewState: Codable, Equatable, Hashable, Sendable {
    let kind: PlanningReviewStateKind
    let oldDateKey: String?
    let newDateKey: String?
    let message: String
    let createdAt: Date

    init(
        kind: PlanningReviewStateKind,
        oldDateKey: String? = nil,
        newDateKey: String? = nil,
        message: String,
        createdAt: Date = Date()
    ) {
        self.kind = kind
        self.oldDateKey = oldDateKey
        self.newDateKey = newDateKey
        self.message = message
        self.createdAt = createdAt
    }
}

struct ScheduledDateSource: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let kind: ScheduledDateSourceKind
    let createdAt: Date
    var isEnabled: Bool
    let origin: ScheduledDateSourceOrigin
    let groupID: UUID?
    let intentAnchor: MorningIntentAnchor
    let calendarSnapshotAtCreation: CalendarVersionSnapshot?
    var reviewState: PlanningReviewState?

    init(
        id: UUID,
        kind: ScheduledDateSourceKind,
        createdAt: Date,
        isEnabled: Bool,
        origin: ScheduledDateSourceOrigin,
        groupID: UUID?,
        intentAnchor: MorningIntentAnchor? = nil,
        calendarSnapshotAtCreation: CalendarVersionSnapshot? = nil,
        reviewState: PlanningReviewState? = nil
    ) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.isEnabled = isEnabled
        self.origin = origin
        self.groupID = groupID
        let resolvedAnchor = intentAnchor ?? Self.defaultIntentAnchor(kind: kind, origin: origin)
        self.intentAnchor = resolvedAnchor
        self.calendarSnapshotAtCreation = calendarSnapshotAtCreation ?? Self.defaultCalendarSnapshot(
            kind: kind,
            intentAnchor: resolvedAnchor
        )
        self.reviewState = reviewState
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case createdAt
        case isEnabled
        case origin
        case groupID
        case intentAnchor
        case calendarSnapshotAtCreation
        case reviewState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let kind = try container.decode(ScheduledDateSourceKind.self, forKey: .kind)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        let origin = try container.decode(ScheduledDateSourceOrigin.self, forKey: .origin)
        let groupID = try container.decodeIfPresent(UUID.self, forKey: .groupID)
        let anchor = try container.decodeIfPresent(MorningIntentAnchor.self, forKey: .intentAnchor)
            ?? Self.defaultIntentAnchor(kind: kind, origin: origin)

        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.isEnabled = isEnabled
        self.origin = origin
        self.groupID = groupID
        self.intentAnchor = anchor
        self.calendarSnapshotAtCreation = try container.decodeIfPresent(
            CalendarVersionSnapshot.self,
            forKey: .calendarSnapshotAtCreation
        ) ?? Self.defaultCalendarSnapshot(kind: kind, intentAnchor: anchor)
        self.reviewState = try container.decodeIfPresent(PlanningReviewState.self, forKey: .reviewState)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(origin, forKey: .origin)
        try container.encodeIfPresent(groupID, forKey: .groupID)
        try container.encode(intentAnchor, forKey: .intentAnchor)
        try container.encodeIfPresent(calendarSnapshotAtCreation, forKey: .calendarSnapshotAtCreation)
        try container.encodeIfPresent(reviewState, forKey: .reviewState)
    }

    static func defaultIntentAnchor(
        kind: ScheduledDateSourceKind,
        origin: ScheduledDateSourceOrigin
    ) -> MorningIntentAnchor {
        switch origin {
        case .defaultDailyPlan:
            return .defaultSetting(ruleID: origin.planningRuleID)
        case .defaultRamadan:
            return .hijriMonthWindow(month: .ramadan, year: nil, ruleID: origin.planningRuleID)
        case .islamicQuickAdd(let quickAdd):
            if quickAdd == .nextMondayThursdayPair {
                return .weekdayPattern([2, 5], ruleID: origin.planningRuleID)
            }
            return .observance(quickAdd.rawValue)
        case .recurringIslamic(let rule):
            switch rule {
            case .mondayThursday:
                return .weekdayPattern([2, 5], ruleID: origin.planningRuleID)
            case .ramadan:
                return .hijriMonthWindow(month: .ramadan, year: nil, ruleID: origin.planningRuleID)
            case .whiteDays:
                return .observance(rule.rawValue)
            }
        case .manualSingleDay, .manualGregorianRange, .migratedLegacyAlways, .migratedLegacyDateRange:
            break
        }

        switch kind {
        case .singleDay(let singleDay):
            return .gregorianDate(singleDay.dateKey)
        case .gregorianRange(let range):
            return .gregorianRange(
                startDateKey: DateHelpers.dayIdentifier(for: range.startDate, timeZone: .current),
                endDateKey: DateHelpers.dayIdentifier(for: range.endDate, timeZone: .current)
            )
        case .recurringIslamic(let recurring):
            switch recurring.rule {
            case .mondayThursday:
                return .weekdayPattern([2, 5], ruleID: recurring.rule.rawValue)
            case .ramadan:
                return .hijriMonthWindow(month: .ramadan, year: nil, ruleID: recurring.rule.rawValue)
            case .whiteDays:
                return .observance(recurring.rule.rawValue)
            }
        case .hijriSingleDay(let hijri):
            return .hijriDate(year: hijri.hijriYear, month: hijri.month, day: hijri.day)
        }
    }

    private static func defaultCalendarSnapshot(
        kind: ScheduledDateSourceKind,
        intentAnchor: MorningIntentAnchor
    ) -> CalendarVersionSnapshot {
        let createdDateKey: String?
        switch kind {
        case .singleDay(let singleDay):
            createdDateKey = singleDay.dateKey
        case .gregorianRange(let range):
            createdDateKey = DateHelpers.dayIdentifier(for: range.startDate, timeZone: .current)
        case .recurringIslamic, .hijriSingleDay:
            createdDateKey = intentAnchor.gregorianDateKey
        }
        return CalendarVersionSnapshot(
            createdDateKey: createdDateKey,
            timeZoneIdentifier: TimeZone.current.identifier,
            hijriAdjustmentFingerprint: nil
        )
    }
}

struct ResolvedScheduledDateProvenance: Codable, Hashable, Identifiable, Sendable {
    let sourceID: UUID
    let groupID: UUID?
    let label: String
    let stopSeriesLabel: String?
    let isExplicitOneOff: Bool
    let sourceOrigin: ScheduledDateSourceOrigin
    let intentAnchor: MorningIntentAnchor
    let calendarSnapshotAtCreation: CalendarVersionSnapshot?
    let reviewState: PlanningReviewState?

    init(
        sourceID: UUID,
        groupID: UUID?,
        label: String,
        stopSeriesLabel: String?,
        isExplicitOneOff: Bool,
        sourceOrigin: ScheduledDateSourceOrigin,
        intentAnchor: MorningIntentAnchor? = nil,
        calendarSnapshotAtCreation: CalendarVersionSnapshot? = nil,
        reviewState: PlanningReviewState? = nil
    ) {
        self.sourceID = sourceID
        self.groupID = groupID
        self.label = label
        self.stopSeriesLabel = stopSeriesLabel
        self.isExplicitOneOff = isExplicitOneOff
        self.sourceOrigin = sourceOrigin
        self.intentAnchor = intentAnchor ?? .defaultSetting(ruleID: sourceOrigin.planningRuleID)
        self.calendarSnapshotAtCreation = calendarSnapshotAtCreation
        self.reviewState = reviewState
    }

    private enum CodingKeys: String, CodingKey {
        case sourceID
        case groupID
        case label
        case stopSeriesLabel
        case isExplicitOneOff
        case sourceOrigin
        case intentAnchor
        case calendarSnapshotAtCreation
        case reviewState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceOrigin = try container.decode(ScheduledDateSourceOrigin.self, forKey: .sourceOrigin)
        self.sourceID = try container.decode(UUID.self, forKey: .sourceID)
        self.groupID = try container.decodeIfPresent(UUID.self, forKey: .groupID)
        self.label = try container.decode(String.self, forKey: .label)
        self.stopSeriesLabel = try container.decodeIfPresent(String.self, forKey: .stopSeriesLabel)
        self.isExplicitOneOff = try container.decode(Bool.self, forKey: .isExplicitOneOff)
        self.sourceOrigin = sourceOrigin
        self.intentAnchor = try container.decodeIfPresent(MorningIntentAnchor.self, forKey: .intentAnchor)
            ?? .defaultSetting(ruleID: sourceOrigin.planningRuleID)
        self.calendarSnapshotAtCreation = try container.decodeIfPresent(
            CalendarVersionSnapshot.self,
            forKey: .calendarSnapshotAtCreation
        )
        self.reviewState = try container.decodeIfPresent(PlanningReviewState.self, forKey: .reviewState)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sourceID, forKey: .sourceID)
        try container.encodeIfPresent(groupID, forKey: .groupID)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(stopSeriesLabel, forKey: .stopSeriesLabel)
        try container.encode(isExplicitOneOff, forKey: .isExplicitOneOff)
        try container.encode(sourceOrigin, forKey: .sourceOrigin)
        try container.encode(intentAnchor, forKey: .intentAnchor)
        try container.encodeIfPresent(calendarSnapshotAtCreation, forKey: .calendarSnapshotAtCreation)
        try container.encodeIfPresent(reviewState, forKey: .reviewState)
    }

    var id: String {
        "\(sourceID.uuidString)-\(groupID?.uuidString ?? "none")"
    }

    var canStopSeries: Bool {
        stopSeriesLabel != nil
    }

    var anchorSummaryText: String {
        intentAnchor.summaryText
    }
}

struct ResolvedScheduledDateEntry: Codable, Hashable, Sendable {
    let date: Date
    let dateKey: String
    let provenances: [ResolvedScheduledDateProvenance]

    var isExplicitOneOff: Bool {
        !provenances.isEmpty && provenances.allSatisfy(\.isExplicitOneOff)
    }
}

struct IslamicQuickAddPreview: Identifiable, Hashable, Sendable {
    let kind: IslamicQuickAddKind
    let dates: [Date]
    let previewText: String
    let availabilityText: String

    var id: IslamicQuickAddKind { kind }
}

private extension IslamicQuickAddKind {
    var sourceDisplayTitle: String {
        switch self {
        case .nextAshura:
            return "Ashura"
        case .nextArafah:
            return "Arafah"
        case .nextDhulHijjahFirstNine:
            return "Dhul Hijjah"
        case .nextEidAlFitr:
            return "Eid al-Fitr"
        case .nextEidAlAdha:
            return "Eid al-Adha"
        case .nextWhiteDays:
            return "White Days"
        case .nextRamadanMonth:
            return "Ramadan"
        case .nextMondayThursdayPair:
            return "Monday & Thursday"
        }
    }
}
