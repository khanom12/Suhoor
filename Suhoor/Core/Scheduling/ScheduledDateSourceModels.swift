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
            return "13th, 14th, and 15th of each Hijri month."
        case .mondayThursday:
            return "Upcoming Mondays and Thursdays."
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
            return "Choose a recommended Ashura pairing or add all three dates."
        case .nextArafah:
            return "Next corrected 9 Dhul Hijjah."
        case .nextEidAlFitr:
            return "Next corrected 1 Shawwal."
        case .nextEidAlAdha:
            return "Next corrected 10 Dhul Hijjah."
        case .nextWhiteDays:
            return "Next corrected 13, 14, and 15."
        case .nextRamadanMonth:
            return "Next corrected Ramadan run."
        case .nextMondayThursdayPair:
            return "Next upcoming Monday and Thursday."
        }
    }

    static let addFlowVisibleCases: [IslamicQuickAddKind] = [
        .nextAshura,
        .nextArafah,
        .nextWhiteDays,
        .nextMondayThursdayPair
    ]
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

enum ScheduledDateSourceKind: Codable, Equatable, Hashable, Sendable {
    case singleDay(SingleDaySource)
    case gregorianRange(GregorianRangeSource)
    case recurringIslamic(RecurringIslamicSource)

    private enum CodingKeys: String, CodingKey {
        case type
        case singleDay
        case gregorianRange
        case recurringIslamic
    }

    private enum SourceType: String, Codable {
        case singleDay
        case gregorianRange
        case recurringIslamic
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
        }
    }
}

enum ScheduledDateSourceOrigin: Codable, Equatable, Hashable, Sendable {
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
        case .defaultRamadan:
            return "Upcoming Ramadan"
        case .manualSingleDay:
            return "Added manually"
        case .manualGregorianRange:
            return "From date range"
        case .islamicQuickAdd(let kind):
            return "From \(kind.title)"
        case .recurringIslamic(let rule):
            return "From recurring \(rule.title)"
        case .migratedLegacyAlways:
            return "From migrated 60-day range"
        case .migratedLegacyDateRange:
            return "From migrated date range"
        }
    }

    var stopSeriesLabel: String? {
        switch self {
        case .defaultRamadan:
            return nil
        case .manualSingleDay:
            return nil
        case .manualGregorianRange:
            return "Stop date range"
        case .islamicQuickAdd(let kind):
            return "Remove \(kind.title)"
        case .recurringIslamic(let rule):
            return "Stop recurring \(rule.title)"
        case .migratedLegacyAlways:
            return "Remove migrated 60-day range"
        case .migratedLegacyDateRange:
            return "Remove migrated date range"
        }
    }

    var isExplicitOneOff: Bool {
        switch self {
        case .manualSingleDay:
            return true
        default:
            return false
        }
    }
}

struct ScheduledDateSource: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let kind: ScheduledDateSourceKind
    let createdAt: Date
    var isEnabled: Bool
    let origin: ScheduledDateSourceOrigin
    let groupID: UUID?
}

struct ResolvedScheduledDateProvenance: Codable, Hashable, Identifiable, Sendable {
    let sourceID: UUID
    let groupID: UUID?
    let label: String
    let stopSeriesLabel: String?
    let isExplicitOneOff: Bool
    let sourceOrigin: ScheduledDateSourceOrigin

    var id: String {
        "\(sourceID.uuidString)-\(groupID?.uuidString ?? "none")"
    }

    var canStopSeries: Bool {
        stopSeriesLabel != nil
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
