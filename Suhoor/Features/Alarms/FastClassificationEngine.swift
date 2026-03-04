import Foundation
import SwiftUI

enum FiqhRuleset: String, CaseIterable, Identifiable, Codable, Sendable {
    case strict
    // Legacy-only compatibility case. The app remains strict-only.
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

enum FastPrimaryIntent: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case ramadanObligatory
    case forbidden
    case qadaMakeup
    case kaffarahExpiation
    case vowNadhr
    case voluntary = "voluntarySunnah"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ramadanObligatory:
            return "Ramadan (Obligatory)"
        case .forbidden:
            return "Forbidden"
        case .qadaMakeup:
            return "Qada (Makeup)"
        case .kaffarahExpiation:
            return "Kaffarah (Expiation)"
        case .vowNadhr:
            return "Vow (Nadhr)"
        case .voluntary:
            return "Voluntary"
        case .other:
            return "Other"
        }
    }

    var shortTitle: String {
        switch self {
        case .ramadanObligatory:
            return "Ramadan"
        case .forbidden:
            return "Forbidden"
        case .qadaMakeup:
            return "Qada"
        case .kaffarahExpiation:
            return "Kaffarah"
        case .vowNadhr:
            return "Vow"
        case .voluntary:
            return "Voluntary"
        case .other:
            return "Other"
        }
    }

    var style: FastTagStyle {
        switch self {
        case .ramadanObligatory:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "moon.stars", color: .green)
        case .forbidden:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "exclamationmark.triangle.fill", color: .red)
        case .qadaMakeup:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "arrow.counterclockwise", color: .indigo)
        case .kaffarahExpiation:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "flame", color: .red)
        case .vowNadhr:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "checkmark.seal", color: .purple)
        case .voluntary:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "sparkles", color: .orange)
        case .other:
            return FastTagStyle(title: title, shortTitle: shortTitle, systemImage: "tag", color: .secondary)
        }
    }

    var isObligatory: Bool {
        switch self {
        case .ramadanObligatory, .qadaMakeup, .kaffarahExpiation, .vowNadhr:
            return true
        case .forbidden, .voluntary, .other:
            return false
        }
    }
}

enum FastSecondaryVirtueTag: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
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

    var category: FastObservanceCategory {
        switch self {
        case .mondayThursday:
            return .recurringWeekly
        case .whiteDays:
            return .recurringMonthly
        case .arafah, .ashura:
            return .singleDay
        case .shawwalSix:
            return .seasonalSeries
        case .dhulHijjahFirstNine:
            return .seasonalWindow
        }
    }

    var isAutoDerivedOnly: Bool { true }

    var suppressedByObligatoryPrimary: Bool { true }

    func allowsCoexistence(with other: FastSecondaryVirtueTag) -> Bool {
        FastIntentEngine.observanceTagsCanCoexist(self, other)
    }
}

enum FastWarning: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
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

enum FastObservanceCategory: String, Codable, Hashable, Sendable {
    case recurringWeekly
    case recurringMonthly
    case singleDay
    case seasonalSeries
    case seasonalWindow
}

enum FastTagSource: String, Codable, Hashable, Sendable {
    case autoDerived
    case userSelected
    case suppressedByPolicy
}

struct TagEvaluationDetail: Codable, Hashable, Sendable {
    let tag: FastSecondaryVirtueTag
    let source: FastTagSource
    let reason: String
}

struct FastIntentSelection: Codable, Hashable, Sendable {
    var primaryIntent: FastPrimaryIntent
    var secondaryTags: Set<FastSecondaryVirtueTag>

    static let `default` = FastIntentSelection(primaryIntent: .other, secondaryTags: [])

    var hasMeaningfulTags: Bool {
        primaryIntent != .other || !secondaryTags.isEmpty
    }
}

struct FastIntentSuggestions: Hashable, Sendable {
    let suggestedPrimary: FastPrimaryIntent?
    let suggestedSecondary: [FastSecondaryVirtueTag]
    let note: String?
}

enum FastIntentEngine {
    static var adjustedHijriCalendar = AdjustedHijriCalendar.shared

    static func hijriMonthTitle(for date: Date, timeZone: TimeZone) -> String {
        adjustedHijriCalendar.monthTitle(for: date, timeZone: timeZone) ?? "Hijri"
    }

    static func hijriMonthKey(for date: Date, timeZone: TimeZone) -> HijriMonthKey? {
        adjustedHijriCalendar.adjustedMonthKey(for: date, timeZone: timeZone)
    }

    static func warnings(for date: Date, timeZone: TimeZone) -> [FastWarning] {
        guard let components = adjustedComponents(for: date, timeZone: timeZone) else { return [] }
        var warnings: [FastWarning] = []
        if components.month == .shawwal, components.day == 1 { warnings.append(.eidAlFitr) }
        if components.month == .dhulHijjah, components.day == 10 { warnings.append(.eidAlAdha) }
        if components.month == .dhulHijjah, (11...13).contains(components.day) { warnings.append(.tashreeq) }
        return warnings
    }

    static func isForbiddenToFast(_ date: Date, timeZone: TimeZone) -> Bool {
        !warnings(for: date, timeZone: timeZone).isEmpty
    }

    static func suggestions(for date: Date, timeZone: TimeZone) -> FastIntentSuggestions {
        var suggestedPrimary: FastPrimaryIntent?
        var suggestedSecondary: [FastSecondaryVirtueTag] = []
        var note: String?

        if isForbiddenToFast(date, timeZone: timeZone) {
            return FastIntentSuggestions(
                suggestedPrimary: .forbidden,
                suggestedSecondary: [],
                note: "Fasting is forbidden on this date."
            )
        }

        if isRamadan(date, timeZone: timeZone) {
            suggestedPrimary = .ramadanObligatory
            note = "Ramadan takes precedence over other voluntary patterns."
            return FastIntentSuggestions(
                suggestedPrimary: suggestedPrimary,
                suggestedSecondary: suggestedSecondary,
                note: note
            )
        }

        suggestedSecondary = Array(dateDerivedObservanceTags(for: date, timeZone: timeZone, includeShawwalPotential: true))
            .sorted { $0.title < $1.title }

        if !suggestedSecondary.isEmpty {
            suggestedPrimary = .voluntary
        }

        return FastIntentSuggestions(
            suggestedPrimary: suggestedPrimary,
            suggestedSecondary: suggestedSecondary,
            note: note
        )
    }

    static func defaultAddFlowSelection(for date: Date, timeZone: TimeZone) -> FastIntentSelection {
        if isForbiddenToFast(date, timeZone: timeZone) {
            return FastIntentSelection(primaryIntent: .forbidden, secondaryTags: [])
        }

        if isRamadan(date, timeZone: timeZone) {
            return FastIntentSelection(primaryIntent: .ramadanObligatory, secondaryTags: [])
        }

        return FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])
    }

    static func allowsSecondaryTags(primary: FastPrimaryIntent, ruleset: FiqhRuleset) -> Bool {
        switch ruleset {
        case .strict:
            return primary == .voluntary
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

    static func normalizedSelection(
        _ selection: FastIntentSelection,
        for date: Date,
        ruleset: FiqhRuleset,
        timeZone: TimeZone
    ) -> FastIntentSelection {
        if isForbiddenToFast(date, timeZone: timeZone) {
            return FastIntentSelection(primaryIntent: .forbidden, secondaryTags: [])
        }

        if isRamadan(date, timeZone: timeZone) {
            return FastIntentSelection(primaryIntent: .ramadanObligatory, secondaryTags: [])
        }

        guard ruleset == .strict else {
            return normalizedSelection(selection, ruleset: ruleset)
        }

        let normalizedPrimary = normalizedPrimaryIntent(selection.primaryIntent, on: date, timeZone: timeZone)

        guard normalizedPrimary == .voluntary else {
            return FastIntentSelection(primaryIntent: normalizedPrimary, secondaryTags: [])
        }

        let applicable = selection.secondaryTags.filter { isCalendarApplicable(tag: $0, on: date, timeZone: timeZone) }
        let compatible = compatibleObservanceTags(from: Set(applicable))
        return FastIntentSelection(primaryIntent: .voluntary, secondaryTags: compatible)
    }

    static func normalizedPrimaryIntent(_ primary: FastPrimaryIntent, on date: Date, timeZone: TimeZone) -> FastPrimaryIntent {
        if isForbiddenToFast(date, timeZone: timeZone) {
            return .forbidden
        }

        if isRamadan(date, timeZone: timeZone) {
            return .ramadanObligatory
        }

        if primary == .ramadanObligatory || primary == .forbidden {
            return .other
        }

        return primary
    }

    static func isPrimarySelectable(_ primary: FastPrimaryIntent, on date: Date, timeZone: TimeZone) -> Bool {
        if primary == .forbidden {
            return isForbiddenToFast(date, timeZone: timeZone)
        }
        if primary == .ramadanObligatory {
            return isRamadan(date, timeZone: timeZone)
        }
        return true
    }

    static func primaryStatusText(
        for primary: FastPrimaryIntent,
        on date: Date,
        timeZone: TimeZone,
        isSuggested: Bool
    ) -> String? {
        if primary == .forbidden, !isForbiddenToFast(date, timeZone: timeZone) {
            return "Only available on dates when fasting is forbidden"
        }
        if primary == .ramadanObligatory, !isRamadan(date, timeZone: timeZone) {
            return "Only available during Ramadan"
        }
        if isSuggested {
            return "Suggested for this date"
        }
        return nil
    }

    static func dateDerivedObservanceTags(
        for date: Date,
        timeZone: TimeZone,
        includeShawwalPotential: Bool
    ) -> Set<FastSecondaryVirtueTag> {
        guard warnings(for: date, timeZone: timeZone).isEmpty else { return [] }

        guard let components = adjustedComponents(for: date, timeZone: timeZone) else { return [] }
        var tags: Set<FastSecondaryVirtueTag> = []

        if isMondayOrThursday(date, timeZone: timeZone) {
            tags.insert(.mondayThursday)
        }
        if [13, 14, 15].contains(components.day) {
            tags.insert(.whiteDays)
        }
        if components.month == .dhulHijjah, components.day == 9 {
            tags.insert(.arafah)
        }
        if components.month == .muharram, [9, 10, 11].contains(components.day) {
            tags.insert(.ashura)
        }
        if components.month == .dhulHijjah, (1...9).contains(components.day) {
            tags.insert(.dhulHijjahFirstNine)
        }
        if includeShawwalPotential, components.month == .shawwal, components.day != 1 {
            tags.insert(.shawwalSix)
        }

        return compatibleObservanceTags(from: tags)
    }

    static func isCalendarApplicable(tag: FastSecondaryVirtueTag, on date: Date, timeZone: TimeZone) -> Bool {
        dateDerivedObservanceTags(for: date, timeZone: timeZone, includeShawwalPotential: true).contains(tag)
    }

    static func observanceTagsCanCoexist(_ lhs: FastSecondaryVirtueTag, _ rhs: FastSecondaryVirtueTag) -> Bool {
        if lhs == rhs { return true }

        switch (lhs, rhs) {
        case (.mondayThursday, _), (_, .mondayThursday):
            return true
        case (.whiteDays, .shawwalSix), (.shawwalSix, .whiteDays):
            return true
        case (.arafah, .dhulHijjahFirstNine), (.dhulHijjahFirstNine, .arafah):
            return true
        case (.whiteDays, .whiteDays),
             (.shawwalSix, .shawwalSix),
             (.arafah, .arafah),
             (.ashura, .ashura),
             (.dhulHijjahFirstNine, .dhulHijjahFirstNine):
            return true
        default:
            return false
        }
    }

    static func compatibleObservanceTags(from tags: Set<FastSecondaryVirtueTag>) -> Set<FastSecondaryVirtueTag> {
        let ordered = tags.sorted {
            observancePriority(for: $0) < observancePriority(for: $1)
        }

        var accepted: [FastSecondaryVirtueTag] = []
        for tag in ordered {
            guard accepted.allSatisfy({ observanceTagsCanCoexist($0, tag) }) else { continue }
            accepted.append(tag)
        }
        return Set(accepted)
    }

    static func displaySecondaryTags(_ tags: Set<FastSecondaryVirtueTag>) -> [FastSecondaryVirtueTag] {
        tags.sorted { observancePriority(for: $0) < observancePriority(for: $1) }
    }

    static func observanceReason(for tag: FastSecondaryVirtueTag, on date: Date, timeZone: TimeZone) -> String {
        let day = adjustedComponents(for: date, timeZone: timeZone)?.day ?? 0

        switch tag {
        case .mondayThursday:
            return "Applies automatically when the date falls on a Monday or Thursday."
        case .whiteDays:
            return "Applies automatically on the 13th, 14th, or 15th of the Hijri month."
        case .arafah:
            return "Applies automatically on 9 Dhul Hijjah."
        case .ashura:
            return "Applies automatically on the 9th, 10th, or 11th of Muharram."
        case .shawwalSix:
            return "Counts only when this Shawwal day is one of the first six eligible voluntary fasts."
        case .dhulHijjahFirstNine:
            if day == 9 {
                return "Applies automatically during the first nine days of Dhul Hijjah, including alongside Arafah on day 9."
            }
            return "Applies automatically during the first nine days of Dhul Hijjah."
        }
    }

    static func suppressionReason(
        for tag: FastSecondaryVirtueTag,
        primary: FastPrimaryIntent
    ) -> String {
        if primary == .forbidden {
            return "Hidden on dates when fasting is forbidden."
        }
        if primary.isObligatory {
            return "Suppressed by obligatory intent."
        }
        if primary == .other {
            return "Hidden until you choose Voluntary as the purpose."
        }
        return "Suppressed by strict compatibility rules."
    }

    private static func isMondayOrThursday(_ date: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 2 || weekday == 5
    }

    static func isRamadan(_ date: Date, timeZone: TimeZone) -> Bool {
        adjustedHijriCalendar.isRamadan(date: date, timeZone: timeZone)
    }

    static func adjustedComponents(for date: Date, timeZone: TimeZone) -> AdjustedHijriDateComponents? {
        adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone)
    }

    private static func observancePriority(for tag: FastSecondaryVirtueTag) -> Int {
        switch tag {
        case .arafah:
            return 0
        case .ashura:
            return 1
        case .dhulHijjahFirstNine:
            return 2
        case .shawwalSix:
            return 3
        case .whiteDays:
            return 4
        case .mondayThursday:
            return 5
        }
    }
}

extension RangePurposeSelection {
    func selection(for date: Date, timeZone: TimeZone) -> FastIntentSelection? {
        switch self {
        case .auto:
            let selection = FastIntentEngine.defaultAddFlowSelection(for: date, timeZone: timeZone)
            return selection.hasMeaningfulTags ? selection : nil
        case .voluntary:
            return FastIntentSelection(primaryIntent: .voluntary, secondaryTags: [])
        case .qada:
            return FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
        case .kaffarah:
            return FastIntentSelection(primaryIntent: .kaffarahExpiation, secondaryTags: [])
        case .vow:
            return FastIntentSelection(primaryIntent: .vowNadhr, secondaryTags: [])
        case .other:
            return nil
        }
    }
}

struct HijriMonthKey: Hashable {
    let year: Int
    let month: Int
    let title: String
}
