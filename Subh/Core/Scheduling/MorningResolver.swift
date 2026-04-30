import CoreLocation
import Foundation

struct MorningScheduleResolutionInput: Sendable {
    let date: Date
    let dateKey: String
    let provenances: [ResolvedScheduledDateProvenance]
    let effectiveConfig: EffectiveDailyConfig
    let tagResult: TagComputationResult
    let stateSnapshot: MorningStateSnapshot
}

struct WakeResolutionResult: Sendable {
    let candidateWakeTime: Date
    let finalWakeTime: Date
    let resolvedWakeState: ResolvedWakeState
    let latestWakeCapMinutesFromMidnight: Int?
    let latestWakeCapApplied: Bool
    let latestWakeCapShiftedState: Bool
}

enum MorningScheduleResolver {
    static let resolverVersion = 1

    static func resolve(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator = PrayerTimeCalculator()
    ) -> ResolvedDaySnapshot? {
        let prayerWindow = resolvePrayerWindow(
            date: input.date,
            coordinate: input.stateSnapshot.coordinate,
            timeZone: input.stateSnapshot.timeZone,
            settings: input.stateSnapshot.settings,
            calculator: calculator
        )
        guard let prayerWindow else { return nil }

        let planSelection = MorningPlanResolver.resolve(
            dateKey: input.dateKey,
            provenances: input.provenances,
            effectiveConfig: input.effectiveConfig,
            tagResult: input.tagResult,
            morningPlanState: input.stateSnapshot.morningPlanState
        )
        let wakeAnchor = resolveWakeAnchor(
            prayerWindow: prayerWindow,
            day: input.date,
            wakeRule: planSelection.selectedPlan.wakeRule,
            timeZone: input.stateSnapshot.timeZone
        )
        let wakeResolution = resolveWakeTime(
            day: input.date,
            prayerWindow: prayerWindow,
            anchor: wakeAnchor,
            selectedPlan: planSelection.selectedPlan,
            timeZone: input.stateSnapshot.timeZone
        )
        let wakeTime = wakeResolution.finalWakeTime
        let wakeDelta = resolveWakeDelta(anchor: wakeAnchor, wakeTime: wakeTime)
        let resolvedContext = ResolvedDayContextResolver.resolve(
            date: input.date,
            provenances: input.provenances,
            tagResult: input.tagResult,
            defaultConfig: input.stateSnapshot.defaultConfig,
            effectiveConfig: input.effectiveConfig,
            timeZone: input.stateSnapshot.timeZone,
            wakeTime: wakeTime
        )
        let behaviorProfile = resolveBehaviorProfile(
            input: input,
            selectedPlan: planSelection.selectedPlan,
            resolvedContext: resolvedContext,
            wakeDelta: wakeDelta,
            wakeResolution: wakeResolution
        )
        let reminder = resolveReminderTime(
            input: input,
            prayerWindow: prayerWindow,
            wakeTime: wakeTime,
            timeZone: input.stateSnapshot.timeZone
        )
        let iftarDate = behaviorProfile.iftarReminderEnabled ? prayerWindow.maghrib : nil
        let boundaryDate = wakeResolution.resolvedWakeState == .preFajr ? prayerWindow.fajrStart : nil
        let materializedEvents = materializeEvents(
            input: input,
            prayerWindow: prayerWindow,
            wakeAnchor: wakeAnchor,
            wakeResolution: wakeResolution,
            wakeTime: wakeTime,
            reminder: reminder,
            boundaryDate: boundaryDate,
            iftarDate: iftarDate,
            behaviorProfile: behaviorProfile
        )
        let sequenceTemplate = WakeSequenceTemplate(
            id: "\(planSelection.selectedPlan.id).sequence",
            name: "\(planSelection.selectedPlan.title) sequence",
            steps: materializedEvents.map {
                WakeSequenceStep(
                    eventType: $0.type,
                    relativeTo: $0.relativeTo,
                    isUserVisible: $0.isUserVisible,
                    affectsCompletion: $0.affectsCompletion,
                    soundRole: $0.soundRole,
                    wakeSessionRole: $0.wakeSessionRole,
                    fajrStartBehavior: $0.fajrStartBehavior
                )
            }
        )
        let decisionLog = RuleDecisionLog(
            dateKey: input.dateKey,
            resolverVersion: resolverVersion,
            decisionHash: decisionHash(
                dateKey: input.dateKey,
                planID: planSelection.selectedPlan.id,
                wakeTime: wakeTime,
                events: materializedEvents
            ),
            prayerWindow: prayerWindow,
            candidateContexts: ResolvedDayContextResolver.candidateContexts(
                tagResult: input.tagResult,
                provenances: input.provenances
            ),
            resolvedDayContext: resolvedContext,
            candidatePlans: planSelection.candidates,
            selectedPlanID: planSelection.selectedPlan.id,
            precedenceReason: planSelection.precedenceReason,
            resolvedBehaviorProfile: behaviorProfile,
            resolvedAnchor: wakeAnchor,
            resolvedDelta: wakeDelta,
            candidateWakeTime: wakeResolution.candidateWakeTime,
            resolvedWakeTime: wakeTime,
            resolvedWakeState: wakeResolution.resolvedWakeState,
            plannedWakeState: planSelection.selectedPlan.wakeRule.state,
            latestWakeCapMinutesFromMidnight: wakeResolution.latestWakeCapMinutesFromMidnight,
            latestWakeCapApplied: wakeResolution.latestWakeCapApplied,
            latestWakeCapShiftedState: wakeResolution.latestWakeCapShiftedState,
            suppressDefaultPrayerPrompt: behaviorProfile.suppressDefaultPrayerPrompt,
            resolvedSequenceTemplate: sequenceTemplate,
            materializedEvents: materializedEvents,
            compatibilityNotes: compatibilityNotes(
                input: input,
                selectedPlan: planSelection.selectedPlan,
                wakeResolution: wakeResolution
            )
        )
        let completionState = CompletionStateAssembler.assemble(
            completionRecords: input.stateSnapshot.completionRecords,
            qadaLedgerSnapshot: input.stateSnapshot.qadaLedgerSnapshot
        )
        let completionRecords = CompletionSnapshotResolver.resolve(
            for: input.dateKey,
            completionRecords: input.stateSnapshot.completionRecords
        )
        let dailyCompletion = DailyCompletionResolver.resolve(
            dateKey: input.dateKey,
            resolvedDayContext: resolvedContext,
            completionState: completionState
        )
        let resolvedDayPurpose = DayPurposeResolver.resolve(
            date: input.date,
            dateKey: input.dateKey,
            provenances: input.provenances,
            tagResult: input.tagResult,
            effectiveConfig: input.effectiveConfig,
            stateSnapshot: input.stateSnapshot,
            selectedPlan: planSelection.selectedPlan,
            wakeAnchor: wakeAnchor,
            wakeResolution: wakeResolution,
            completionRecords: completionRecords,
            dailyCompletion: dailyCompletion
        )

        return ResolvedDaySnapshot(
            date: input.date,
            dateKey: input.dateKey,
            prayerWindow: prayerWindow,
            resolvedDayContext: resolvedContext,
            selectedPlan: planSelection.selectedPlan,
            resolvedBehaviorProfile: behaviorProfile,
            materializedEvents: materializedEvents,
            decisionLog: decisionLog,
            completionRecords: completionRecords,
            dailyCompletion: dailyCompletion,
            completionSummary: completionSummary(from: dailyCompletion),
            resolvedDayPurpose: resolvedDayPurpose
        )
    }

    static func resolvePrayerWindow(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator
    ) -> DailyPrayerWindow? {
        resolvePrayerWindow(
            date: input.date,
            coordinate: input.stateSnapshot.coordinate,
            timeZone: input.stateSnapshot.timeZone,
            settings: input.stateSnapshot.settings,
            calculator: calculator
        )
    }

    static func resolvePrayerWindow(
        date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        settings: AppSettings,
        calculator: PrayerTimeCalculator
    ) -> DailyPrayerWindow? {
        calculator.localPrayerWindow(
            for: date,
            location: coordinate,
            timeZone: timeZone,
            method: settings.calculationMethod,
            fajrBeginAdjustmentMinutes: settings.fajrAdjustmentMinutes,
            fajrEndAdjustmentMinutes: settings.fajrEndAdjustmentMinutes,
            maghribAdjustmentMinutes: settings.maghribAdjustmentMinutes,
            highLatitudeRule: settings.highLatitudeRule,
            roundingPolicy: settings.roundingPolicy
        )
    }

    static func resolveWakeAnchor(
        prayerWindow: DailyPrayerWindow,
        day: Date,
        wakeRule: MorningWakeRule,
        timeZone: TimeZone
    ) -> WakeAnchor {
        if let fixedWakeTime = wakeRule.fixedWakeTimeMinutesFromMidnight,
           wakeRule.state == .fixedWake || wakeRule.isLegacyFixedWakeCompatibility {
            return WakeAnchor(
                type: .clockTime,
                date: dateFromMidnight(for: day, minutes: fixedWakeTime, timeZone: timeZone),
                providerNotes: wakeRule.isLegacyFixedWakeCompatibility ? "legacy_fixed_wake_compatibility" : "fixed_clock_time"
            )
        }

        switch wakeRule.anchorType ?? .fajrStart {
        case .fajrStart:
            return WakeAnchor(type: .fajrStart, date: prayerWindow.fajrStart, providerNotes: nil)
        case .fajrEnd:
            return WakeAnchor(
                type: .fajrEnd,
                date: prayerWindow.fajrEnd ?? prayerWindow.fajrStart,
                providerNotes: prayerWindow.fajrEnd == nil ? "fallback:missing_fajr_end" : prayerWindow.fajrEndSource.providerNote
            )
        case .masjidFajr:
            return WakeAnchor(type: .masjidFajr, date: prayerWindow.fajrStart, providerNotes: "fallback:fajr_start")
        case .clockTime:
            return WakeAnchor(type: .clockTime, date: prayerWindow.fajrStart, providerNotes: "fallback:clock_time_missing")
        }
    }

    static func resolveWakeTime(
        day: Date,
        prayerWindow: DailyPrayerWindow,
        anchor: WakeAnchor,
        selectedPlan: MorningPlan,
        timeZone: TimeZone
    ) -> WakeResolutionResult {
        resolveWakeTime(
            day: day,
            prayerWindow: prayerWindow,
            anchor: anchor,
            wakeRule: selectedPlan.wakeRule,
            timeZone: timeZone
        )
    }

    static func resolveWakeTime(
        day: Date,
        prayerWindow: DailyPrayerWindow,
        anchor: WakeAnchor,
        wakeRule: MorningWakeRule,
        timeZone: TimeZone
    ) -> WakeResolutionResult {
        let deltaMinutes = max(0, wakeRule.deltaMinutes)
        let candidateWakeTime: Date

        switch wakeRule.state {
        case .preFajr:
            candidateWakeTime = Calendar.current.date(byAdding: .minute, value: -deltaMinutes, to: anchor.date) ?? anchor.date
        case .inFajr:
            let offset = (anchor.type == .fajrEnd) ? -deltaMinutes : deltaMinutes
            candidateWakeTime = Calendar.current.date(byAdding: .minute, value: offset, to: anchor.date) ?? anchor.date
        case .postFajr:
            candidateWakeTime = Calendar.current.date(byAdding: .minute, value: deltaMinutes, to: anchor.date) ?? anchor.date
        case .fixedWake:
            candidateWakeTime = wakeRule.fixedWakeTimeMinutesFromMidnight
                .map { dateFromMidnight(for: day, minutes: $0, timeZone: timeZone) }
                ?? anchor.date
        }

        let candidateState = classifyWakeState(candidateWakeTime, prayerWindow: prayerWindow)
        let latestWakeCapDate = wakeRule.latestWakeCapMinutesFromMidnight
            .map { dateFromMidnight(for: day, minutes: $0, timeZone: timeZone) }
        let finalWakeTime: Date
        let latestWakeCapApplied: Bool
        if wakeRule.usesLatestWakeCap,
           let latestWakeCapDate,
           latestWakeCapDate < candidateWakeTime {
            finalWakeTime = latestWakeCapDate
            latestWakeCapApplied = true
        } else {
            finalWakeTime = candidateWakeTime
            latestWakeCapApplied = false
        }

        let resolvedWakeState = classifyWakeState(finalWakeTime, prayerWindow: prayerWindow)
        return WakeResolutionResult(
            candidateWakeTime: candidateWakeTime,
            finalWakeTime: finalWakeTime,
            resolvedWakeState: resolvedWakeState,
            latestWakeCapMinutesFromMidnight: wakeRule.latestWakeCapMinutesFromMidnight,
            latestWakeCapApplied: latestWakeCapApplied,
            latestWakeCapShiftedState: candidateState != resolvedWakeState
        )
    }

    private static func resolveWakeDelta(anchor: WakeAnchor, wakeTime: Date) -> WakeDelta {
        let minutes = Int(round(abs(anchor.date.timeIntervalSince(wakeTime)) / 60))
        return WakeDelta(
            relation: wakeTime <= anchor.date ? .before : .after,
            minutes: minutes
        )
    }

    private static func resolveBehaviorProfile(
        input: MorningScheduleResolutionInput,
        selectedPlan: MorningPlan,
        resolvedContext: ResolvedDayContext,
        wakeDelta: WakeDelta,
        wakeResolution: WakeResolutionResult
    ) -> MorningBehaviorProfile {
        let fastingContexts: Set<MorningContextType> = [.fasting, .qadaFast, .sunnahFast]
        let iftarReminderEnabled = selectedPlan.iftarReminderEnabled && fastingContexts.contains(resolvedContext.primaryContext)
        let primaryWakeSoundRole = primaryWakeSoundRole(
            plannedWakeState: selectedPlan.wakeRule.state,
            resolvedWakeState: wakeResolution.resolvedWakeState
        )
        let suppressDefaultPrayerPrompt = selectedPlan.kind == .explicitDateOverride
            && selectedPlan.wakeRule.state == .postFajr

        return MorningBehaviorProfile(
            wakeAnchorType: selectedPlan.wakeRule.compatibilityWakeAnchorType,
            wakeDelta: wakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
            reminderEnabled: input.effectiveConfig.reminderEnabled,
            wakeAlarmEnabled: input.effectiveConfig.suhoorEnabled,
            wakeFollowUpEnabled: FeatureFlags.enableSnooze && input.stateSnapshot.settings.snoozeEnabled,
            fajrBoundaryNoticeEnabled: input.effectiveConfig.fajrEnabled,
            iftarReminderEnabled: iftarReminderEnabled,
            resolvedWakeState: wakeResolution.resolvedWakeState,
            plannedWakeState: selectedPlan.wakeRule.state,
            latestWakeCapMinutesFromMidnight: wakeResolution.latestWakeCapMinutesFromMidnight,
            latestWakeCapApplied: wakeResolution.latestWakeCapApplied,
            latestWakeCapShiftedState: wakeResolution.latestWakeCapShiftedState,
            primaryWakeSoundRole: primaryWakeSoundRole,
            takesOverAtFajrStart: wakeResolution.resolvedWakeState == .preFajr,
            suppressDefaultPrayerPrompt: suppressDefaultPrayerPrompt
        )
    }

    private static func resolveReminderTime(
        input: MorningScheduleResolutionInput,
        prayerWindow: DailyPrayerWindow,
        wakeTime: Date,
        timeZone: TimeZone
    ) -> Date {
        if let overrideMinutes = input.effectiveConfig.reminderTimeOverrideMinutesFromMidnight {
            return dateFromMidnight(for: input.date, minutes: overrideMinutes, timeZone: timeZone)
        }

        if input.effectiveConfig.reminderTimeMode == .fixedTime {
            return dateFromMidnight(
                for: input.date,
                minutes: input.effectiveConfig.reminderFixedTimeMinutes,
                timeZone: timeZone
            )
        }

        let candidate = Calendar.current.date(
            byAdding: .minute,
            value: -input.effectiveConfig.reminderMinutesBeforeFajr,
            to: prayerWindow.fajrStart
        ) ?? prayerWindow.fajrStart
        return max(candidate, wakeTime)
    }

    private static func materializeEvents(
        input: MorningScheduleResolutionInput,
        prayerWindow: DailyPrayerWindow,
        wakeAnchor: WakeAnchor,
        wakeResolution: WakeResolutionResult,
        wakeTime: Date,
        reminder: Date,
        boundaryDate: Date?,
        iftarDate: Date?,
        behaviorProfile: MorningBehaviorProfile
    ) -> [ScheduledEvent] {
        var events: [ScheduledEvent] = []
        let wakeSessionID = "\(input.dateKey).wake-session"

        if behaviorProfile.reminderEnabled {
            let reference: ScheduledEventRelativeReference
            if let overrideMinutes = input.effectiveConfig.reminderTimeOverrideMinutesFromMidnight {
                reference = .fixedClock(minutesFromMidnight: overrideMinutes)
            } else if input.effectiveConfig.reminderTimeMode == .fixedTime {
                reference = .fixedClock(minutesFromMidnight: input.effectiveConfig.reminderFixedTimeMinutes)
            } else {
                reference = .wakeAnchor(type: .fajrStart, offsetMinutes: -input.effectiveConfig.reminderMinutesBeforeFajr)
            }
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).wakeReminder",
                    type: .wakeReminder,
                    dateKey: input.dateKey,
                    fireDate: reminder,
                    relativeTo: reference,
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.reminder],
                    soundRole: .reminder,
                    wakeSessionID: wakeSessionID,
                    wakeSessionRole: .companion
                )
            )
        }

        if behaviorProfile.wakeAlarmEnabled {
            let reference = wakeRelativeReference(
                wakeAnchor: wakeAnchor,
                wakeTime: wakeTime,
                wakeResolution: wakeResolution,
                behaviorProfile: behaviorProfile
            )
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).wakeAlarm",
                    type: .wakeAlarm,
                    dateKey: input.dateKey,
                    fireDate: wakeTime,
                    relativeTo: reference,
                    isUserVisible: true,
                    affectsCompletion: true,
                    deliveryKinds: [.wake],
                    soundRole: behaviorProfile.primaryWakeSoundRole,
                    wakeSessionID: wakeSessionID,
                    wakeSessionRole: .primaryWake
                )
            )
        }

        if behaviorProfile.wakeFollowUpEnabled {
            let followUpDate = wakeTime.addingTimeInterval(TimeInterval(input.stateSnapshot.settings.snoozeMinutes * 60))
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).wakeFollowUp",
                    type: .wakeFollowUp,
                    dateKey: input.dateKey,
                    fireDate: followUpDate,
                    relativeTo: .wakeAlarm(offsetMinutes: input.stateSnapshot.settings.snoozeMinutes),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [],
                    soundRole: behaviorProfile.primaryWakeSoundRole,
                    wakeSessionID: wakeSessionID,
                    wakeSessionRole: .companion
                )
            )
        }

        if let boundaryDate {
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).fajrBoundaryNotice",
                    type: .fajrBoundaryNotice,
                    dateKey: input.dateKey,
                    fireDate: boundaryDate,
                    relativeTo: .prayerBoundary(boundary: .fajrStart, offsetMinutes: 0),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: behaviorProfile.fajrBoundaryNoticeEnabled ? [.boundary] : [],
                    soundRole: .fajrStart,
                    wakeSessionID: wakeSessionID,
                    wakeSessionRole: .checkpoint,
                    fajrStartBehavior: behaviorProfile.takesOverAtFajrStart
                        ? .takeoverIfUnresolvedOtherwiseCue
                        : .cueOnly
                )
            )
        }

        if let iftarDate {
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).iftarReminder",
                    type: .iftarReminder,
                    dateKey: input.dateKey,
                    fireDate: iftarDate,
                    relativeTo: .prayerBoundary(boundary: .maghrib, offsetMinutes: 0),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: iftarDeliveryKinds(for: input.effectiveConfig),
                    soundRole: .iftar,
                    wakeSessionRole: .companion
                )
            )
        }

        return events.sorted { $0.fireDate < $1.fireDate }
    }

    private static func iftarDeliveryKinds(for config: EffectiveDailyConfig) -> [ScheduleEventKind] {
        var kinds: [ScheduleEventKind] = []
        let delivery = config.iftarDelivery.normalized()
        if delivery.includesNotification {
            kinds.append(.iftarNotification)
        }
        switch delivery.audibleMode {
        case .none:
            break
        case .alarm:
            kinds.append(.iftarAlarm)
        case .adhan:
            kinds.append(.iftarAdhan)
        }
        return kinds
    }

    private static func compatibilityNotes(
        input: MorningScheduleResolutionInput,
        selectedPlan: MorningPlan,
        wakeResolution: WakeResolutionResult
    ) -> [String] {
        var notes: [String] = []
        if selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight != nil || selectedPlan.wakeRule.isLegacyFixedWakeCompatibility {
            notes.append("fixed_time_wake_compatibility")
        }
        if input.stateSnapshot.morningPlanState.activationMode == .legacyCompat {
            notes.append("legacy_compat_schedule_window")
        }
        if input.effectiveConfig.hasOverrides {
            notes.append("date_override")
        }
        if selectedPlan.wakeAnchorType == .fajrEnd {
            notes.append("abstract_fajr_end_anchor")
        }
        if wakeResolution.latestWakeCapApplied {
            notes.append("latest_wake_cap_applied")
        } else if wakeResolution.latestWakeCapMinutesFromMidnight != nil {
            notes.append("latest_wake_cap_available")
        }
        if wakeResolution.latestWakeCapShiftedState {
            notes.append("latest_wake_cap_shifted_state")
        }
        return notes
    }

    private static func completionSummary(
        from snapshot: DailyCompletionSnapshot
    ) -> String? {
        switch snapshot.outstandingAction {
        case .prayerCheckIn:
            return "Fajr not logged yet."
        case .fastingStatus:
            return "Fasting status not logged yet."
        case .fastCompletion:
            return "Fast completion is still unresolved."
        case nil:
            if snapshot.qadaEffect.countsTowardQada {
                return snapshot.qadaEffect.explanation
            }
            return nil
        }
    }

    private static func decisionHash(
        dateKey: String,
        planID: String,
        wakeTime: Date,
        events: [ScheduledEvent]
    ) -> String {
        let eventFragment = events.map { "\($0.type.rawValue)@\($0.fireDate.timeIntervalSince1970)" }
            .joined(separator: "|")
        return "\(dateKey)|\(planID)|\(wakeTime.timeIntervalSince1970)|\(eventFragment)"
    }

    private static func classifyWakeState(
        _ wakeTime: Date,
        prayerWindow: DailyPrayerWindow
    ) -> ResolvedWakeState {
        let fajrEnd = prayerWindow.fajrEnd ?? prayerWindow.fajrStart
        if wakeTime < prayerWindow.fajrStart {
            return .preFajr
        }
        if wakeTime < fajrEnd {
            return .inFajr
        }
        return .postFajr
    }

    private static func primaryWakeSoundRole(
        plannedWakeState: MorningWakeRuleState,
        resolvedWakeState: ResolvedWakeState
    ) -> MorningSoundRole {
        switch plannedWakeState {
        case .fixedWake:
            return .fixedWake
        case .postFajr:
            return .postFajrWake
        case .preFajr, .inFajr:
            switch resolvedWakeState {
            case .preFajr:
                return .preFajrWake
            case .inFajr:
                return .inFajrWake
            case .postFajr:
                return .postFajrWake
            }
        }
    }

    private static func wakeRelativeReference(
        wakeAnchor: WakeAnchor,
        wakeTime: Date,
        wakeResolution: WakeResolutionResult,
        behaviorProfile: MorningBehaviorProfile
    ) -> ScheduledEventRelativeReference {
        if wakeResolution.latestWakeCapApplied,
           let minutes = wakeResolution.latestWakeCapMinutesFromMidnight {
            return .fixedClock(minutesFromMidnight: minutes)
        }

        if let fixedCompatibilityMinutes = behaviorProfile.fixedWakeTimeCompatibilityMinutesFromMidnight,
           wakeAnchor.type == .clockTime {
            return .fixedClock(minutesFromMidnight: fixedCompatibilityMinutes)
        }

        if wakeAnchor.type == .clockTime {
            let minutes = DateHelpers.minutesFromMidnight(for: wakeTime, timeZone: .current)
            return .fixedClock(minutesFromMidnight: minutes)
        }

        return .wakeAnchor(
            type: wakeAnchor.type,
            offsetMinutes: resolveWakeDelta(anchor: wakeAnchor, wakeTime: wakeTime).signedMinutes
        )
    }

    private static func dateFromMidnight(
        for day: Date,
        minutes: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}

struct DefaultWakeRuleValidationResult: Equatable, Sendable {
    let isValid: Bool
    let firstInvalidDateKey: String?
    let message: String?
    let capPulledIntoPreFajrCount: Int

    static let valid = DefaultWakeRuleValidationResult(
        isValid: true,
        firstInvalidDateKey: nil,
        message: nil,
        capPulledIntoPreFajrCount: 0
    )
}

enum DefaultWakeRuleValidator {
    static func validate(
        startDate: Date,
        timeZone: TimeZone,
        coordinate: CLLocationCoordinate2D,
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig,
        calculator: PrayerTimeCalculator = PrayerTimeCalculator(),
        horizonDays: Int = 365
    ) -> DefaultWakeRuleValidationResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: startDate)
        var capPulledIntoPreFajrCount = 0
        let defaultWakeRule = defaultConfig.defaultWakeRule
        let validationPlan = MorningPlan(
            id: "validator",
            title: "Validator plan",
            kind: .defaultDaily,
            wakeRule: defaultWakeRule,
            wakeAnchorType: defaultWakeRule.compatibilityWakeAnchorType,
            wakeDelta: defaultWakeRule.compatibilityWakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: defaultWakeRule.fixedWakeTimeMinutesFromMidnight,
            reminderEnabled: defaultConfig.reminderEnabledDefault,
            wakeAlarmEnabled: defaultConfig.suhoorEnabledDefault,
            fajrBoundaryNoticeEnabled: defaultConfig.fajrEnabledDefault,
            iftarReminderEnabled: defaultConfig.iftarEnabledDefault
        )

        for dayOffset in 0..<max(1, horizonDays) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: normalizedStart) else {
                continue
            }
            guard let prayerWindow = MorningScheduleResolver.resolvePrayerWindow(
                    date: day,
                    coordinate: coordinate,
                    timeZone: timeZone,
                    settings: settings,
                    calculator: calculator
                  ) else {
                let key = DateHelpers.dayIdentifier(for: day, timeZone: timeZone)
                return DefaultWakeRuleValidationResult(
                    isValid: false,
                    firstInvalidDateKey: key,
                    message: "Prayer times were unavailable for \(key).",
                    capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
                )
            }

            let wakeAnchor = MorningScheduleResolver.resolveWakeAnchor(
                prayerWindow: prayerWindow,
                day: day,
                wakeRule: defaultWakeRule,
                timeZone: timeZone
            )
            let wakeResolution = MorningScheduleResolver.resolveWakeTime(
                day: day,
                prayerWindow: prayerWindow,
                anchor: wakeAnchor,
                selectedPlan: validationPlan,
                timeZone: timeZone
            )

            if wakeResolution.latestWakeCapApplied,
               wakeResolution.resolvedWakeState == .preFajr,
               defaultConfig.defaultWakeState == .inFajr {
                capPulledIntoPreFajrCount += 1
            }

            let key = DateHelpers.dayIdentifier(for: day, timeZone: timeZone)
            let fajrEnd = prayerWindow.fajrEnd ?? prayerWindow.fajrStart

            switch defaultWakeRule.state {
            case .preFajr:
                if wakeResolution.candidateWakeTime >= prayerWindow.fajrStart {
                    return DefaultWakeRuleValidationResult(
                        isValid: false,
                        firstInvalidDateKey: key,
                        message: "Pre-Fajr defaults must resolve before Fajr starts.",
                        capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
                    )
                }
            case .inFajr:
                if defaultWakeRule.anchorType == .fajrEnd {
                    if wakeResolution.candidateWakeTime < prayerWindow.fajrStart {
                        return DefaultWakeRuleValidationResult(
                            isValid: false,
                            firstInvalidDateKey: key,
                            message: "End-anchored in-Fajr wakes must stay inside the raw Fajr window.",
                            capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
                        )
                    }
                } else {
                    let reserveCutoff = fajrEnd.addingTimeInterval(TimeInterval(-settings.clampedReserveBeforeEndMinutes * 60))
                    if wakeResolution.candidateWakeTime > reserveCutoff {
                        return DefaultWakeRuleValidationResult(
                            isValid: false,
                            firstInvalidDateKey: key,
                            message: "Start-anchored in-Fajr wakes must preserve the reserve before Fajr ends.",
                            capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
                        )
                    }
                }
            case .postFajr, .fixedWake:
                return DefaultWakeRuleValidationResult(
                    isValid: false,
                    firstInvalidDateKey: key,
                    message: "Defaults may only use Pre-Fajr or In-Fajr wake states.",
                    capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
                )
            }
        }

        return DefaultWakeRuleValidationResult(
            isValid: true,
            firstInvalidDateKey: nil,
            message: nil,
            capPulledIntoPreFajrCount: capPulledIntoPreFajrCount
        )
    }
}
