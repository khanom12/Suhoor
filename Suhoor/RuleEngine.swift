import Foundation

enum RamadanBadge: String, Identifiable {
    case weekend
    case last10
    case laylatulQadr
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekend: return "Weekend"
        case .last10: return "Last 10"
        case .laylatulQadr: return "Qadr"
        case .custom: return "Custom"
        }
    }
}

enum RamadanLayerKind {
    case weekend
    case last10
    case laylatulQadr

    var displayName: String {
        switch self {
        case .weekend: return "Weekend Boost"
        case .last10: return "Last 10 Nights"
        case .laylatulQadr: return "Laylatul Qadr"
        }
    }
}

struct AppliedLayer {
    let kind: RamadanLayerKind
    let earlierByMinutes: Int
}

struct RuleSummary {
    let baseOffsetMinutes: Int
    let appliedLayer: AppliedLayer?
    let finalOffsetMinutes: Int
    let overrideOffsetMinutes: Int?
    let disabledForDay: Bool
}

struct RuleEngine {
    let settings: AppSettings
    let timeZone: TimeZone

    private let ramadanRange: RamadanRange?
    private let profileEngine = RamadanProfileEngine()

    init(settings: AppSettings, timeZone: TimeZone = .current) {
        self.settings = settings
        self.timeZone = timeZone
        if settings.ramadanModeEnabled {
            ramadanRange = profileEngine.computeRamadanRange(
                forGregorianYear: settings.selectedRamadanProfile.gregorianYear,
                startAdjustmentDays: settings.ramadanStartAdjustmentDays,
                endAdjustmentDays: settings.ramadanEndAdjustmentDays,
                timeZone: timeZone
            )
        } else {
            ramadanRange = nil
        }
    }

    func effectiveWakeOffsetMinutes(for date: Date) -> Int {
        let summary = ruleSummary(for: date)
        return summary.finalOffsetMinutes
    }

    func effectiveReminderEnabled(for date: Date) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = settings.perDayExceptions[key]?.reminderEnabledOverride {
            return override
        }
        return settings.reminderEnabledGlobal
    }

    func effectiveAtFajrEnabled(for date: Date) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = settings.perDayExceptions[key]?.atFajrEnabledOverride {
            return override
        }
        return settings.atFajrEnabledGlobal
    }

    func effectiveAtFajrSoundChoice(for date: Date) -> SoundChoice {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = settings.perDayExceptions[key]?.atFajrSoundOverride {
            return override
        }
        return settings.atFajrSoundSelectionGlobal
    }

    func effectiveReminderMinutes(for date: Date) -> Int {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = settings.perDayExceptions[key]?.reminderMinutesOverride {
            return override
        }
        return settings.reminderMinutesBeforeFajrGlobal
    }

    func ruleSummary(for date: Date) -> RuleSummary {
        let baseOffset = settings.baseWakeOffsetMinutes
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let exception = settings.perDayExceptions[key] {
            if exception.disabledForDay {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    appliedLayer: nil,
                    finalOffsetMinutes: baseOffset,
                    overrideOffsetMinutes: exception.wakeOffsetOverrideMinutes,
                    disabledForDay: true
                )
            }
            if let override = exception.wakeOffsetOverrideMinutes {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    appliedLayer: nil,
                    finalOffsetMinutes: override,
                    overrideOffsetMinutes: override,
                    disabledForDay: false
                )
            }
        }

        let applied = appliedLayerByPrecedence(for: date)
        let finalOffset = baseOffset + (applied?.earlierByMinutes ?? 0)
        return RuleSummary(
            baseOffsetMinutes: baseOffset,
            appliedLayer: applied,
            finalOffsetMinutes: finalOffset,
            overrideOffsetMinutes: nil,
            disabledForDay: false
        )
    }

    func appliedLayerLabel(for date: Date) -> String? {
        guard let applied = appliedLayerByPrecedence(for: date) else { return nil }
        return applied.kind.displayName
    }

    func appliedLayer(for date: Date) -> AppliedLayer? {
        appliedLayerByPrecedence(for: date)
    }

    func applicableBadges(for date: Date) -> [RamadanBadge] {
        var badges: [RamadanBadge] = []
        if let range = ramadanRange, isDate(date, within: range) {
            if isWeekendBoostApplicable(on: date) { badges.append(.weekend) }
            if isLast10Applicable(on: date) { badges.append(.last10) }
            if isLaylatulQadrApplicable(on: date) { badges.append(.laylatulQadr) }
        }

        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let exception = settings.perDayExceptions[key] {
            if exception.disabledForDay {
                return [.custom]
            }
            if exception.wakeOffsetOverrideMinutes != nil
                || exception.reminderEnabledOverride != nil
                || exception.reminderMinutesOverride != nil
                || exception.atFajrEnabledOverride != nil
                || exception.atFajrSoundOverride != nil {
                badges.append(.custom)
            }
        }
        return badges
    }

    func ramadanRangeForDisplay() -> RamadanRange? {
        ramadanRange
    }

    private func appliedLayerByPrecedence(for date: Date) -> AppliedLayer? {
        guard let range = ramadanRange, isDate(date, within: range) else { return nil }

        if settings.lqEnabled, isLaylatulQadrApplicable(on: date) {
            return AppliedLayer(kind: .laylatulQadr, earlierByMinutes: settings.lqBoostMinutes)
        }
        if settings.last10Enabled, isLast10Applicable(on: date) {
            return AppliedLayer(kind: .last10, earlierByMinutes: settings.last10BoostMinutes)
        }
        if settings.weekendBoostEnabled, isWeekendBoostApplicable(on: date) {
            return AppliedLayer(kind: .weekend, earlierByMinutes: settings.weekendBoostMinutes)
        }
        return nil
    }

    private func isDate(_ date: Date, within range: RamadanRange) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let target = calendar.startOfDay(for: date)
        return target >= calendar.startOfDay(for: range.startDate) && target <= calendar.startOfDay(for: range.endDate)
    }

    private func isWeekendBoostApplicable(on date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    private func isLast10Applicable(on date: Date) -> Bool {
        guard let range = ramadanRange else { return false }
        guard let dayNumber = profileEngine.computeRamadanDayNumber(for: date, range: range, timeZone: timeZone) else { return false }
        return dayNumber >= max(1, range.dayCount - 9)
    }

    private func isLaylatulQadrApplicable(on date: Date) -> Bool {
        guard let range = ramadanRange else { return false }
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let specificKey = settings.lqSpecificDateKey {
            return specificKey == key
        }
        guard let dayNumber = profileEngine.computeRamadanDayNumber(for: date, range: range, timeZone: timeZone) else { return false }
        return settings.lqNightNumbers.contains(dayNumber)
    }
}
