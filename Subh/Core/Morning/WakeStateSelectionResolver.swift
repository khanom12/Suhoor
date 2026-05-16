import Foundation

enum WakeStateSelectionResolver {
    static let defaultFajrDeltaMinutes = 30
    static let defaultSuhoorDeltaMinutes = 30

    static func selectedMode(for day: ActiveAlarmDay) -> QuickWakeMode {
        if let explicitMode = day.effectiveConfig.quickWakeModeOverride {
            return explicitMode
        }

        if isIntendedEarlyWorship(day)
            || (day.effectiveConfig.wakeRuleWasOverridden && day.effectiveConfig.resolvedWakeRule.state == .preFajr) {
            return .suhoor
        }

        return .fajr
    }

    static func isQuiet(_ day: ActiveAlarmDay) -> Bool {
        selectedMode(for: day) == .quiet
    }

    static func isSelectedFast(_ day: ActiveAlarmDay) -> Bool {
        selectedMode(for: day) == .suhoor
    }

    static func isEarlyWorshipMorning(_ day: ActiveAlarmDay) -> Bool {
        isSelectedFast(day) || isIntendedEarlyWorship(day)
    }

    static func underlyingMode(for day: ActiveAlarmDay) -> MorningWakeUnderlyingMode {
        switch selectedMode(for: day) {
        case .suhoor:
            return .earlyWorship
        case .fajr:
            return .fajr
        case .quiet:
            if let preservedMode = day.effectiveConfig.underlyingWakeModeBeforeQuiet {
                return preservedMode == .suhoor ? .earlyWorship : .fajr
            }
            if day.effectiveConfig.resolvedWakeRule.state == .preFajr || isIntendedEarlyWorship(day) {
                return .earlyWorship
            }
            return .fajr
        }
    }

    static func dayContextKind(for day: ActiveAlarmDay) -> MorningWakeDayContextKind {
        let context = day.resolvedDayContext
        let tags = Set(context.supportingTags)
        let selectedMode = selectedMode(for: day)
        let hasExplicitSuhoorSelection = selectedMode == .suhoor
            || day.effectiveConfig.alarmDetailFastTypeOverride != nil
        let hasResolvedFastingIntent = isFastingMorning(context)
        let hasIntendedFast = hasResolvedFastingIntent || hasExplicitSuhoorSelection
        let hasFastingOpportunity = tags.contains(.mondayThursday)
            || tags.contains(.whiteDays)
            || tags.contains(.arafah)
            || tags.contains(.ashura)
            || tags.contains(.dhulHijjahFirstNine)
            || tags.contains(.shawwalSix)

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
        case .suhoor:
            override.skipDay = false
            override.quickWakeModeOverride = .suhoor
            override.earlyWakePurposeOverride = .fast
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
            override.alarmDetailAudioPlanOverride = .wakeAlarmAndFajrAdhan
            override.iftarEnabled = nil
            override.wakeStateOverride = .preFajr
            override.wakeAnchorTypeOverride = .fajrStart
            override.wakeDeltaOverrideMinutes = defaultSuhoorDeltaMinutes
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.bypassLatestWakeCap = true
            override.tahajjudRefinement = false
        case .fajr:
            override.skipDay = false
            override.quickWakeModeOverride = .fajr
            override.earlyWakePurposeOverride = nil
            override.alarmDetailFastTypeOverride = nil
            override.suhoorEnabled = true
            override.reminderEnabled = false
            override.fajrEnabled = false
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
            override.suhoorEnabled = false
            override.reminderEnabled = false
            override.fajrEnabled = false
            override.iftarEnabled = false
            override.quietOverlay = true
        }
    }

    private static func isIntendedEarlyWorship(_ day: ActiveAlarmDay) -> Bool {
        isFastingMorning(day.resolvedDayContext)
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

enum MorningDateIntentReducer {
    static func selectWakeMode(
        _ mode: QuickWakeMode,
        for day: ActiveAlarmDay,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        let previousMode = WakeStateSelectionResolver.selectedMode(for: day)
        let wasQuiet = previousMode == .quiet || override.quickWakeModeOverride == .quiet
        let preservedMode = override.underlyingWakeModeBeforeQuiet

        switch mode {
        case .suhoor:
            if wasQuiet, preservedMode == .suhoor, override.resolvedWakeRule(defaults: .default) != nil {
                restoreFromQuiet(mode: .suhoor, override: &override)
                override.earlyWakePurposeOverride = override.earlyWakePurposeOverride
                    ?? preservedSuhoorPurpose()
                override.tahajjudRefinement = false
                applyAlarmDetailAudioPlan(override.alarmDetailAudioPlanOverride ?? .wakeAlarmAndFajrAdhan, to: &override)
            } else {
                WakeStateSelectionResolver.apply(.suhoor, to: &override)
                override.earlyWakePurposeOverride = preservedSuhoorPurpose()
                override.tahajjudRefinement = false
            }

        case .fajr:
            WakeStateSelectionResolver.apply(.fajr, to: &override)

        case .quiet:
            if previousMode != .quiet {
                override.underlyingWakeModeBeforeQuiet = previousMode
            } else if override.underlyingWakeModeBeforeQuiet == nil {
                override.underlyingWakeModeBeforeQuiet = day.effectiveConfig.underlyingWakeModeBeforeQuiet
                    ?? (WakeStateSelectionResolver.underlyingMode(for: day) == .earlyWorship ? .suhoor : .fajr)
            }
            WakeStateSelectionResolver.apply(.quiet, to: &override)
        }

        stamp(&override, source: .heroQuickMode, now: now)
    }

    static func commitWakeAdjustment(
        minutesFromMidnight: Int,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        override.skipDay = false
        override.suhoorEnabled = true
        override.wakeStateOverride = .fixedWake
        override.wakeAnchorTypeOverride = nil
        override.wakeDeltaOverrideMinutes = nil
        override.fixedWakeTimeOverrideMinutesFromMidnight = minutesFromMidnight
        override.wakeTimeOriginOverride = .manualDragOverride
        override.suhoorOffsetOverrideMinutes = nil
        override.suhoorTimeOverrideMinutesFromMidnight = nil
        override.bypassLatestWakeCap = true
        override.quietOverlay = false
        if override.quickWakeModeOverride == .quiet {
            override.quickWakeModeOverride = override.underlyingWakeModeBeforeQuiet ?? .fajr
        }
        stamp(&override, source: .heroWakeAdjustment, now: now)
    }

    static func selectEarlyPurpose(
        _ purpose: EarlyWakePurposeOverride,
        isRamadan: Bool,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        WakeStateSelectionResolver.apply(.suhoor, to: &override)
        override.earlyWakePurposeOverride = .fast
        override.tahajjudRefinement = false
        applyAlarmDetailAudioPlan(.wakeAlarmAndFajrAdhan, to: &override, locksFajrAdhan: isRamadan)
        stamp(&override, source: .alarmDetail, now: now)
    }

    static func selectFastPurpose(
        _ fastType: AlarmDetailFastTypeOverride?,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        WakeStateSelectionResolver.apply(.suhoor, to: &override)
        override.earlyWakePurposeOverride = .fast
        override.alarmDetailFastTypeOverride = fastType
        override.tahajjudRefinement = false
        applyAlarmDetailAudioPlan(override.alarmDetailAudioPlanOverride ?? .wakeAlarmAndFajrAdhan, to: &override)
        stamp(&override, source: .alarmDetail, now: now)
    }

    static func selectAudioPlan(
        _ audioPlan: AlarmDetailAudioPlan,
        isRamadan: Bool,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        let resolvedPlan = isRamadan && audioPlan == .wakeAlarm ? .wakeAlarmAndFajrAdhan : audioPlan
        applyAlarmDetailAudioPlan(resolvedPlan, to: &override, locksFajrAdhan: isRamadan)
        stamp(&override, source: .alarmDetail, now: now)
    }

    static func toggleFajrAdhanAtFajrBegins(
        enabled: Bool,
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        WakeStateSelectionResolver.apply(.suhoor, to: &override)
        override.earlyWakePurposeOverride = .fast
        override.tahajjudRefinement = false
        override.fajrAdhanAtFajrBeginsOverride = enabled
        applyAlarmDetailAudioPlan(enabled ? .wakeAlarmAndFajrAdhan : .wakeAlarm, to: &override)
        stamp(&override, source: .alarmDetail, now: now)
    }

    static func restoreDefaultWake(
        override: inout DailyAlarmOverride,
        now: Date
    ) {
        override.skipDay = false
        override.suhoorEnabled = nil
        override.reminderEnabled = nil
        override.fajrEnabled = nil
        override.iftarEnabled = nil
        override.wakeStateOverride = nil
        override.wakeAnchorTypeOverride = nil
        override.wakeDeltaOverrideMinutes = nil
        override.quickWakeModeOverride = nil
        override.underlyingWakeModeBeforeQuiet = nil
        override.earlyWakePurposeOverride = nil
        override.alarmDetailFastTypeOverride = nil
        override.alarmDetailAudioPlanOverride = nil
        override.fixedWakeTimeOverrideMinutesFromMidnight = nil
        override.wakeTimeOriginOverride = nil
        override.bypassLatestWakeCap = nil
        override.tahajjudRefinement = nil
        override.selectedOpportunityIDs = nil
        override.fajrAdhanAtFajrBeginsOverride = nil
        override.quietOverlay = nil
        override.suhoorOffsetOverrideMinutes = nil
        override.suhoorTimeOverrideMinutesFromMidnight = nil
        stamp(&override, source: .restoreDefault, now: now)
    }

    static func applyAlarmDetailAudioPlan(
        _ plan: AlarmDetailAudioPlan,
        to override: inout DailyAlarmOverride,
        locksFajrAdhan: Bool = false
    ) {
        let resolvedPlan = locksFajrAdhan && plan == .wakeAlarm ? .wakeAlarmAndFajrAdhan : plan
        override.alarmDetailAudioPlanOverride = resolvedPlan

        switch resolvedPlan {
        case .fajrAdhan:
            override.suhoorEnabled = true
            override.reminderEnabled = false
            override.fajrEnabled = locksFajrAdhan
            override.fajrAdhanAtFajrBeginsOverride = locksFajrAdhan ? true : nil
        case .wakeAlarm:
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = locksFajrAdhan
            override.fajrAdhanAtFajrBeginsOverride = false
        case .wakeAlarmAndFajrAdhan:
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
            override.fajrAdhanAtFajrBeginsOverride = true
        }
    }

    private static func restoreFromQuiet(mode: QuickWakeMode, override: inout DailyAlarmOverride) {
        override.skipDay = false
        override.quickWakeModeOverride = mode
        override.underlyingWakeModeBeforeQuiet = nil
        override.quietOverlay = false
        override.iftarEnabled = nil
    }

    private static func preservedSuhoorPurpose() -> EarlyWakePurposeOverride {
        .fast
    }

    private static func isRamadanDay(_ day: ActiveAlarmDay) -> Bool {
        day.isImplicitRamadan || day.resolvedDayContext.supportingTags.contains(.ramadan)
    }

    private static func stamp(
        _ override: inout DailyAlarmOverride,
        source: DailyAlarmOverrideSource,
        now: Date
    ) {
        if override.createdAt == nil {
            override.createdAt = now
        }
        override.updatedAt = now
        override.overrideSource = source
    }
}
