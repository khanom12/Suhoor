import Foundation

enum MorningPlanResolver {
    static func resolve(
        dateKey: String,
        provenances: [ResolvedScheduledDateProvenance],
        effectiveConfig: EffectiveDailyConfig,
        tagResult: TagComputationResult,
        morningPlanState: MorningPlanState
    ) -> MorningPlanResolution {
        let defaultPlan = morningPlanState.defaultDailyPlan
        let meaningfulProvenances = provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        var candidates = [
            RulePlanCandidate(id: defaultPlan.id, title: defaultPlan.title, kind: defaultPlan.kind)
        ]

        if effectiveConfig.hasOverrides {
            let overrideWakeRule = effectiveConfig.resolvedWakeRule
            let overridePlan = MorningPlan(
                id: "override-\(dateKey)",
                title: "Date override",
                kind: .explicitDateOverride,
                wakeRule: overrideWakeRule,
                wakeAnchorType: overrideWakeRule.compatibilityWakeAnchorType,
                wakeDelta: overrideWakeRule.compatibilityWakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: overrideWakeRule.fixedWakeTimeMinutesFromMidnight,
                reminderEnabled: effectiveConfig.reminderEnabled,
                wakeAlarmEnabled: effectiveConfig.suhoorEnabled,
                fajrBoundaryNoticeEnabled: effectiveConfig.fajrEnabled,
                iftarReminderEnabled: effectiveConfig.iftarEnabled
            )
            candidates.insert(.init(id: overridePlan.id, title: overridePlan.title, kind: overridePlan.kind), at: 0)
            return MorningPlanResolution(
                selectedPlan: overridePlan,
                candidates: candidates,
                precedenceReason: "Explicit single-date override takes precedence."
            )
        }

        if tagResult.computedPrimaryIntent == .qadaMakeup {
            let qadaPlan = MorningPlan(
                id: "qada-\(dateKey)",
                title: "Qada day",
                kind: .qadaAssignment,
                wakeRule: defaultPlan.wakeRule,
                wakeAnchorType: defaultPlan.wakeAnchorType,
                wakeDelta: defaultPlan.wakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: defaultPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
                reminderEnabled: defaultPlan.reminderEnabled,
                wakeAlarmEnabled: defaultPlan.wakeAlarmEnabled,
                fajrBoundaryNoticeEnabled: defaultPlan.fajrBoundaryNoticeEnabled,
                iftarReminderEnabled: true
            )
            candidates.insert(.init(id: qadaPlan.id, title: qadaPlan.title, kind: qadaPlan.kind), at: 0)
            return MorningPlanResolution(
                selectedPlan: qadaPlan,
                candidates: candidates,
                precedenceReason: "Qada context overrides the default daily plan."
            )
        }

        if !meaningfulProvenances.isEmpty {
            let overlayPlan = MorningPlan(
                id: "overlay-\(dateKey)",
                title: "Context overlay",
                kind: .generatedObservance,
                wakeRule: defaultPlan.wakeRule,
                wakeAnchorType: defaultPlan.wakeAnchorType,
                wakeDelta: defaultPlan.wakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: defaultPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
                reminderEnabled: defaultPlan.reminderEnabled,
                wakeAlarmEnabled: defaultPlan.wakeAlarmEnabled,
                fajrBoundaryNoticeEnabled: defaultPlan.fajrBoundaryNoticeEnabled,
                iftarReminderEnabled: defaultPlan.iftarReminderEnabled
            )
            candidates.insert(.init(id: overlayPlan.id, title: overlayPlan.title, kind: overlayPlan.kind), at: 0)
            return MorningPlanResolution(
                selectedPlan: overlayPlan,
                candidates: candidates,
                precedenceReason: "An observance or source overlay applies to this date."
            )
        }

        return MorningPlanResolution(
            selectedPlan: defaultPlan,
            candidates: candidates,
            precedenceReason: "The default daily plan applies."
        )
    }
}
