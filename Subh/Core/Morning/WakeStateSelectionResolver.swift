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

    static func underlyingMode(for day: ActiveAlarmDay) -> MorningWakeUnderlyingMode {
        switch selectedMode(for: day) {
        case .fast:
            return .earlyWorship
        case .fajr:
            return .fajr
        case .quiet:
            if day.effectiveConfig.resolvedWakeRule.state == .preFajr || isIntendedEarlyWorship(day) {
                return .earlyWorship
            }
            return .fajr
        }
    }

    static func dayContextKind(for day: ActiveAlarmDay) -> MorningWakeDayContextKind {
        let context = day.resolvedDayContext
        let tags = Set(context.supportingTags)
        let hasTahajjud = context.primaryContext == .tahajjud
            || context.secondaryContexts.contains(.tahajjud)
            || day.effectiveConfig.tahajjudRefinement
        let hasIntendedFast = isFastingMorning(context)
        let hasFastingOpportunity = tags.contains(.mondayThursday)
            || tags.contains(.whiteDays)
            || tags.contains(.arafah)
            || tags.contains(.ashura)
            || tags.contains(.dhulHijjahFirstNine)
            || tags.contains(.shawwalSix)

        if hasTahajjud && hasIntendedFast {
            return .fastingAndTahajjudIntended
        }
        if hasTahajjud {
            return .tahajjudIntended
        }
        if tags.contains(.ramadan) || day.isImplicitRamadan {
            return .ramadanFasting
        }
        if context.primaryContext == .qadaFast || tags.contains(.qada) {
            return .qadaFastIntended
        }
        if context.primaryContext == .sunnahFast {
            return .sunnahFastIntended
        }
        if hasIntendedFast {
            return .fastingIntended
        }
        if selectedMode(for: day) == .fast {
            return .fastingIntended
        }
        if hasFastingOpportunity {
            return .fastingOpportunity
        }
        if context.primaryContext == .specialDay || tags.contains(.eid) || tags.contains(.tashreeq) {
            return .observanceOnly
        }
        if day.effectiveConfig.wakeRuleWasOverridden {
            return .adjusted
        }
        return .ordinary
    }

    static func apply(_ mode: QuickWakeMode, to override: inout DailyAlarmOverride) {
        switch mode {
        case .fast:
            override.skipDay = false
            override.quickWakeModeOverride = .fast
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
            override.alarmDetailAudioPlanOverride = .wakeAlarmAndFajrAdhan
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
            override.earlyWakePurposeOverride = nil
            override.alarmDetailFastTypeOverride = nil
            override.suhoorEnabled = false
            override.reminderEnabled = false
            override.fajrEnabled = true
            override.alarmDetailAudioPlanOverride = .fajrAdhan
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
            override.earlyWakePurposeOverride = nil
            override.alarmDetailFastTypeOverride = nil
            override.alarmDetailAudioPlanOverride = nil
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
