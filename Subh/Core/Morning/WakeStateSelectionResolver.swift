import Foundation

enum WakeStateSelectionResolver {
    static let defaultFajrDeltaMinutes = 30
    static let defaultFastDeltaMinutes = 30

    static func selectedMode(for day: ActiveAlarmDay) -> QuickWakeMode {
        if let explicitMode = day.effectiveConfig.quickWakeModeOverride {
            return explicitMode
        }

        if isIntendedEarlyWorship(day)
            || (day.effectiveConfig.wakeRuleWasOverridden && day.effectiveConfig.resolvedWakeRule.state == .preFajr) {
            return .fast
        }

        return .fajr
    }

    static func isQuiet(_ day: ActiveAlarmDay) -> Bool {
        selectedMode(for: day) == .quiet
    }

    static func isSelectedFast(_ day: ActiveAlarmDay) -> Bool {
        selectedMode(for: day) == .fast
    }

    static func isEarlyWorshipMorning(_ day: ActiveAlarmDay) -> Bool {
        isSelectedFast(day) || isIntendedEarlyWorship(day)
    }

    static func apply(_ mode: QuickWakeMode, to override: inout DailyAlarmOverride) {
        switch mode {
        case .fast:
            override.skipDay = false
            override.quickWakeModeOverride = .fast
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
            override.iftarEnabled = nil
            override.wakeStateOverride = .preFajr
            override.wakeAnchorTypeOverride = .fajrStart
            override.wakeDeltaOverrideMinutes = defaultFastDeltaMinutes
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.bypassLatestWakeCap = true
            override.tahajjudRefinement = nil
        case .fajr:
            override.skipDay = false
            override.quickWakeModeOverride = .fajr
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
            override.iftarEnabled = nil
            override.wakeStateOverride = .inFajr
            override.wakeAnchorTypeOverride = .fajrEnd
            override.wakeDeltaOverrideMinutes = defaultFajrDeltaMinutes
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.bypassLatestWakeCap = true
            override.tahajjudRefinement = nil
        case .quiet:
            override.skipDay = true
            override.quickWakeModeOverride = .quiet
            override.suhoorEnabled = false
            override.reminderEnabled = false
            override.fajrEnabled = false
            override.iftarEnabled = false
        }
    }

    private static func isIntendedEarlyWorship(_ day: ActiveAlarmDay) -> Bool {
        isFastingMorning(day.resolvedDayContext)
            || day.resolvedDayContext.primaryContext == .tahajjud
            || day.resolvedDayContext.secondaryContexts.contains(.tahajjud)
            || day.effectiveConfig.tahajjudRefinement
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
}
