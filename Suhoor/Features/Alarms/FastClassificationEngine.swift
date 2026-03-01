import Foundation
import SwiftUI

enum FiqhRuleset: String, CaseIterable, Identifiable, Codable {
    case strict
    case permissive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strict:
            return "Strict"
        case .permissive:
            return "Permissive"
        }
    }
}

enum FastPrimaryIntent: String, CaseIterable, Codable, Identifiable, Hashable {
    case ramadanObligatory
    case qadaMakeup
    case kaffarahExpiation
    case vowNadhr
    case voluntarySunnah
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ramadanObligatory:
            return "Ramadan (Obligatory)"
        case .qadaMakeup:
            return "Qada (Makeup)"
        case .kaffarahExpiation:
            return "Kaffarah (Expiation)"
        case .vowNadhr:
            return "Vow (Nadhr)"
        case .voluntarySunnah:
            return "Voluntary (Sunnah)"
        case .other:
            return "Other"
        }
    }

    var shortTitle: String {
        switch self {
        case .ramadanObligatory:
            return "Ramadan"
        case .qadaMakeup:
            return "Qada"
        case .kaffarahExpiation:
            return "Kaffarah"
        case .vowNadhr:
            return "Vow"
        case .voluntarySunnah:
            return "Sunnah"
        case .other:
            return "Other"
        }
    }

    var style: FastTagStyle {
        switch self {
        case .ramadanObligatory:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "moon.stars", color: .green)
        case .qadaMakeup:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "arrow.counterclockwise", color: .indigo)
        case .kaffarahExpiation:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "flame", color: .red)
        case .vowNadhr:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "checkmark.seal", color: .purple)
        case .voluntarySunnah:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "sparkles", color: .orange)
        case .other:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "tag", color: .secondary)
        }
    }

    var isObligatory: Bool {
        switch self {
        case .ramadanObligatory, .qadaMakeup, .kaffarahExpiation, .vowNadhr:
            return true
        case .voluntarySunnah, .other:
            return false
        }
    }
}

enum FastSecondaryVirtueTag: String, CaseIterable, Codable, Identifiable, Hashable {
    case shawwalSix
    case arafah
    case ashura
    case whiteDays
    case mondayThursday
    case dhulHijjahFirstNine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shawwalSix:
            return "Six of Shawwal"
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .whiteDays:
            return "White Days (13-15)"
        case .mondayThursday:
            return "Monday/Thursday"
        case .dhulHijjahFirstNine:
            return "First 9 of Dhul Hijjah"
        }
    }

    var shortTitle: String {
        switch self {
        case .shawwalSix:
            return "Shawwal 6"
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .whiteDays:
            return "White Days"
        case .mondayThursday:
            return "Mon/Thu"
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah"
        }
    }

    var style: FastTagStyle {
        switch self {
        case .shawwalSix:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "6.circle", color: .blue)
        case .arafah:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "mountain.2", color: .teal)
        case .ashura:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "sparkles", color: .indigo)
        case .whiteDays:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "circle", color: .mint)
        case .mondayThursday:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "calendar", color: .orange)
        case .dhulHijjahFirstNine:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "sun.max", color: .yellow)
        }
    }
}

enum FastWarning: String, CaseIterable, Codable, Hashable, Identifiable {
    case eidAlFitr
    case eidAlAdha
    case tashreeq

    var id: String { rawValue }

    var title: String {
        switch self {
        case .eidAlFitr:
            return "Eid al-Fitr"
        case .eidAlAdha:
            return "Eid al-Adha"
        case .tashreeq:
            return "Days of Tashreeq"
        }
    }

    var systemImage: String { "exclamationmark.triangle.fill" }
}

struct FastTagStyle {
    let title: String
    let shortTitle: String
    let systemImage: String?
    let color: Color
}

struct FastIntentSelection: Codable, Hashable {
    var primaryIntent: FastPrimaryIntent
    var secondaryTags: Set<FastSecondaryVirtueTag>

    static let `default` = FastIntentSelection(primaryIntent: .other, secondaryTags: [])

    var hasMeaningfulTags: Bool {
        primaryIntent != .other || !secondaryTags.isEmpty
    }
}

struct FastIntentSuggestions: Hashable {
    let suggestedPrimary: FastPrimaryIntent?
    let suggestedSecondary: [FastSecondaryVirtueTag]
    let note: String?
}

enum FastIntentEngine {
    static func hijriMonthTitle(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func hijriMonthKey(for date: Date, timeZone: TimeZone) -> HijriMonthKey? {
        let components = hijriComponents(for: date, timeZone: timeZone)
        guard let year = components.year, let month = components.month else { return nil }
        let title = hijriMonthTitle(for: date, timeZone: timeZone)
        return HijriMonthKey(year: year, month: month, title: title)
    }

    static func warnings(for date: Date, timeZone: TimeZone) -> [FastWarning] {
        let components = hijriComponents(for: date, timeZone: timeZone)
        guard let month = components.month, let day = components.day else { return [] }
        var warnings: [FastWarning] = []
        if month == 10, day == 1 { warnings.append(.eidAlFitr) }
        if month == 12, day == 10 { warnings.append(.eidAlAdha) }
        if month == 12, (11...13).contains(day) { warnings.append(.tashreeq) }
        return warnings
    }

    static func suggestions(for date: Date, timeZone: TimeZone) -> FastIntentSuggestions {
        let components = hijriComponents(for: date, timeZone: timeZone)
        let month = components.month ?? 0
        let day = components.day ?? 0
        var suggestedPrimary: FastPrimaryIntent?
        var suggestedSecondary: [FastSecondaryVirtueTag] = []
        var note: String?

        if month == 9 {
            suggestedPrimary = .ramadanObligatory
            note = "Ramadan takes precedence over other Sunnah patterns."
            return FastIntentSuggestions(
                suggestedPrimary: suggestedPrimary,
                suggestedSecondary: suggestedSecondary,
                note: note
            )
        }

        if month == 12, day == 9 { suggestedSecondary.append(.arafah) }
        if month == 1, [9, 10, 11].contains(day) { suggestedSecondary.append(.ashura) }
        if [13, 14, 15].contains(day) { suggestedSecondary.append(.whiteDays) }
        if isMondayOrThursday(date, timeZone: timeZone) { suggestedSecondary.append(.mondayThursday) }

        if !suggestedSecondary.isEmpty {
            suggestedPrimary = .voluntarySunnah
        }

        return FastIntentSuggestions(
            suggestedPrimary: suggestedPrimary,
            suggestedSecondary: suggestedSecondary,
            note: note
        )
    }

    static func allowsSecondaryTags(primary: FastPrimaryIntent, ruleset: FiqhRuleset) -> Bool {
        switch ruleset {
        case .strict:
            return !primary.isObligatory
        case .permissive:
            return true
        }
    }

    static func normalizedSelection(_ selection: FastIntentSelection, ruleset: FiqhRuleset) -> FastIntentSelection {
        guard ruleset == .strict, selection.primaryIntent.isObligatory, !selection.secondaryTags.isEmpty else {
            return selection
        }
        return FastIntentSelection(primaryIntent: selection.primaryIntent, secondaryTags: [])
    }

    private static func isMondayOrThursday(_ date: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 2 || weekday == 5
    }

    private static func hijriComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        let calendar = hijriCalendar(timeZone: timeZone)
        return calendar.dateComponents([.year, .month, .day], from: date)
    }

    private static func hijriCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        return calendar
    }
}

struct HijriMonthKey: Hashable {
    let year: Int
    let month: Int
    let title: String
}
