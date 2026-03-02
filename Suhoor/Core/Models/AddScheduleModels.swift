import Foundation

struct AddScheduledDatesResult: Hashable, Sendable {
    let addedDates: [Date]
    let skippedActiveDates: [Date]

    static let empty = AddScheduledDatesResult(addedDates: [], skippedActiveDates: [])

    var isEmpty: Bool {
        addedDates.isEmpty && skippedActiveDates.isEmpty
    }

    var addedCount: Int {
        addedDates.count
    }

    var skippedCount: Int {
        skippedActiveDates.count
    }

    var totalSelectedCount: Int {
        addedDates.count + skippedActiveDates.count
    }
}

enum RangePurposeSelection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case auto
    case voluntary
    case qada
    case kaffarah
    case vow
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            return "Auto"
        case .voluntary:
            return "Voluntary"
        case .qada:
            return "Qada"
        case .kaffarah:
            return "Kaffarah"
        case .vow:
            return "Vow"
        case .other:
            return "Other"
        }
    }

    var detailText: String {
        switch self {
        case .auto:
            return "Adds Voluntary automatically only on dates that already match a Sunnah observance."
        case .voluntary:
            return "Marks every added day as Voluntary and derives matching observances per date."
        case .qada:
            return "Marks every added day as Qada and suppresses derived observance tags."
        case .kaffarah:
            return "Marks every added day as Kaffarah and suppresses derived observance tags."
        case .vow:
            return "Marks every added day as Vow and suppresses derived observance tags."
        case .other:
            return "Adds the dates without a stored purpose."
        }
    }
}

struct CalendarDayState: Identifiable, Hashable, Sendable {
    let date: Date
    let dayNumberText: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isDisabled: Bool
    let isAlreadyActive: Bool
    let activeSourceSummary: String?
    let hijriText: String

    var id: String {
        DateHelpers.dayIdentifier(for: date, timeZone: .current)
    }
}

struct CalendarMonthContext: Hashable, Sendable {
    let monthStart: Date
    let monthTitle: String
    let weekdaySymbols: [String]
    let dayStates: [CalendarDayState]
}

enum IslamicQuickAddAvailabilityState: Hashable, Sendable {
    case available
    case partial
    case disabled
}

enum AshuraQuickAddPattern: String, CaseIterable, Identifiable, Hashable, Sendable {
    case nineTen
    case tenEleven
    case allThree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nineTen:
            return "9 + 10 Muharram"
        case .tenEleven:
            return "10 + 11 Muharram"
        case .allThree:
            return "9 + 10 + 11 Muharram"
        }
    }

    var detailText: String {
        switch self {
        case .nineTen:
            return "The primary recommended pair when both days are still upcoming."
        case .tenEleven:
            return "The alternate pair when 9 Muharram has passed or you prefer the later pairing."
        case .allThree:
            return "Adds all three Ashura-adjacent dates together."
        }
    }
}

struct AshuraQuickAddPreview: Hashable, Sendable {
    let pattern: AshuraQuickAddPattern
    let dates: [Date]
    let previewText: String
    let availabilityText: String
}

struct AshuraQuickAddAvailability: Hashable, Sendable {
    let pattern: AshuraQuickAddPattern
    let preview: AshuraQuickAddPreview?
    let addResult: AddScheduledDatesResult
    let reasonText: String?
    let isRecommended: Bool

    var state: IslamicQuickAddAvailabilityState {
        if addResult.addedDates.isEmpty {
            return .disabled
        }
        if addResult.skippedActiveDates.isEmpty {
            return .available
        }
        return .partial
    }
}

struct IslamicQuickAddAvailability: Hashable, Sendable {
    let kind: IslamicQuickAddKind
    let preview: IslamicQuickAddPreview?
    let addResult: AddScheduledDatesResult
    let reasonText: String?

    var state: IslamicQuickAddAvailabilityState {
        if addResult.addedDates.isEmpty {
            return .disabled
        }
        if addResult.skippedActiveDates.isEmpty {
            return .available
        }
        return .partial
    }
}

struct RecurringRuleStatus: Hashable, Sendable {
    let rule: RecurringIslamicRule
    let isAdded: Bool
    let detailText: String?
}

struct CalendarDayDetail: Hashable, Sendable {
    let date: Date
    let gregorianText: String
    let hijriText: String
    let isAlreadyActive: Bool
    let activeSourceSummary: String?
    let tagSummary: String
}
