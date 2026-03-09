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

enum MorningScheduleResolver {
    static let resolverVersion = 1

    static func resolve(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator = PrayerTimeCalculator()
    ) -> ResolvedDaySnapshot? {
        let prayerWindow = resolvePrayerWindow(input: input, calculator: calculator)
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
            anchorType: planSelection.selectedPlan.wakeAnchorType
        )
        let wakeTime = resolveWakeTime(
            day: input.date,
            anchor: wakeAnchor,
            effectiveConfig: input.effectiveConfig,
            selectedPlan: planSelection.selectedPlan,
            timeZone: input.stateSnapshot.timeZone
        )
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
            wakeDelta: wakeDelta
        )
        let reminder = resolveReminderTime(
            input: input,
            wakeTime: wakeTime,
            anchor: wakeAnchor,
            timeZone: input.stateSnapshot.timeZone
        )
        let iftarDate = behaviorProfile.iftarReminderEnabled ? prayerWindow.maghrib : nil
        let boundaryDate = behaviorProfile.fajrBoundaryNoticeEnabled ? prayerWindow.fajrStart : nil
        let materializedEvents = materializeEvents(
            input: input,
            prayerWindow: prayerWindow,
            wakeAnchor: wakeAnchor,
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
                    affectsCompletion: $0.affectsCompletion
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
            resolvedWakeTime: wakeTime,
            resolvedSequenceTemplate: sequenceTemplate,
            materializedEvents: materializedEvents,
            compatibilityNotes: compatibilityNotes(
                input: input,
                selectedPlan: planSelection.selectedPlan
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
            completionSummary: completionSummary(from: dailyCompletion)
        )
    }

    private static func resolvePrayerWindow(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator
    ) -> DailyPrayerWindow? {
        guard let fajrStart = calculator.fajrDate(
            for: input.date,
            location: input.stateSnapshot.coordinate,
            timeZone: input.stateSnapshot.timeZone,
            method: input.stateSnapshot.settings.calculationMethod,
            adjustmentMinutes: input.stateSnapshot.settings.fajrAdjustmentMinutes
        ),
        let maghrib = calculator.maghribDate(
            for: input.date,
            location: input.stateSnapshot.coordinate,
            timeZone: input.stateSnapshot.timeZone,
            adjustmentMinutes: input.stateSnapshot.settings.maghribAdjustmentMinutes
        ) else {
            return nil
        }

        let fajrEnd = calculator.sunriseDate(
            for: input.date,
            location: input.stateSnapshot.coordinate,
            timeZone: input.stateSnapshot.timeZone,
            adjustmentMinutes: 0
        )

        return DailyPrayerWindow(
            date: input.date,
            fajrStart: fajrStart,
            fajrEnd: fajrEnd,
            maghrib: maghrib
        )
    }

    private static func resolveWakeAnchor(
        prayerWindow: DailyPrayerWindow,
        anchorType: WakeAnchorType
    ) -> WakeAnchor {
        switch anchorType {
        case .fajrStart:
            return WakeAnchor(type: .fajrStart, date: prayerWindow.fajrStart, providerNotes: nil)
        case .fajrEnd:
            return WakeAnchor(
                type: .fajrEnd,
                date: prayerWindow.fajrEnd ?? prayerWindow.fajrStart,
                providerNotes: prayerWindow.fajrEnd == nil ? "fallback:missing_fajr_end" : "provider:solar_sunrise_proxy"
            )
        case .masjidFajr:
            return WakeAnchor(type: .masjidFajr, date: prayerWindow.fajrStart, providerNotes: "fallback:fajr_start")
        }
    }

    private static func resolveWakeTime(
        day: Date,
        anchor: WakeAnchor,
        effectiveConfig: EffectiveDailyConfig,
        selectedPlan: MorningPlan,
        timeZone: TimeZone
    ) -> Date {
        if let overrideMinutes = effectiveConfig.suhoorTimeOverrideMinutesFromMidnight {
            return dateFromMidnight(for: day, minutes: overrideMinutes, timeZone: timeZone)
        }

        if effectiveConfig.suhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: day, minutes: effectiveConfig.suhoorOffsetMinutes, timeZone: timeZone)
        }

        if let fixedCompatibilityMinutes = selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight {
            return dateFromMidnight(for: day, minutes: fixedCompatibilityMinutes, timeZone: timeZone)
        }

        let resolvedDelta = WakeDelta(
            relation: selectedPlan.wakeDelta.relation,
            minutes: max(0, effectiveConfig.suhoorOffsetMinutes)
        )
        return Calendar.current.date(byAdding: .minute, value: resolvedDelta.signedMinutes, to: anchor.date) ?? anchor.date
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
        wakeDelta: WakeDelta
    ) -> MorningBehaviorProfile {
        let fastingContexts: Set<MorningContextType> = [.fasting, .qadaFast, .sunnahFast]
        let iftarReminderEnabled = selectedPlan.iftarReminderEnabled && fastingContexts.contains(resolvedContext.primaryContext)

        return MorningBehaviorProfile(
            wakeAnchorType: selectedPlan.wakeAnchorType,
            wakeDelta: wakeDelta,
            fixedWakeTimeCompatibilityMinutesFromMidnight: selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
            reminderEnabled: input.effectiveConfig.reminderEnabled,
            wakeAlarmEnabled: input.effectiveConfig.suhoorEnabled,
            wakeFollowUpEnabled: FeatureFlags.enableSnooze && input.stateSnapshot.settings.snoozeEnabled,
            fajrBoundaryNoticeEnabled: input.effectiveConfig.fajrEnabled,
            iftarReminderEnabled: iftarReminderEnabled
        )
    }

    private static func resolveReminderTime(
        input: MorningScheduleResolutionInput,
        wakeTime: Date,
        anchor: WakeAnchor,
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
            to: anchor.date
        ) ?? anchor.date
        return max(candidate, wakeTime)
    }

    private static func materializeEvents(
        input: MorningScheduleResolutionInput,
        prayerWindow: DailyPrayerWindow,
        wakeAnchor: WakeAnchor,
        wakeTime: Date,
        reminder: Date,
        boundaryDate: Date?,
        iftarDate: Date?,
        behaviorProfile: MorningBehaviorProfile
    ) -> [ScheduledEvent] {
        var events: [ScheduledEvent] = []

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
                    deliveryKinds: [.reminder]
                )
            )
        }

        if behaviorProfile.wakeAlarmEnabled {
            let reference: ScheduledEventRelativeReference
            if let overrideMinutes = input.effectiveConfig.suhoorTimeOverrideMinutesFromMidnight {
                reference = .fixedClock(minutesFromMidnight: overrideMinutes)
            } else if input.effectiveConfig.suhoorTimeMode == .fixedTime,
                      input.effectiveConfig.suhoorOffsetMinutes >= 0 {
                reference = .fixedClock(minutesFromMidnight: input.effectiveConfig.suhoorOffsetMinutes)
            } else if let fixedCompatibilityMinutes = behaviorProfile.fixedWakeTimeCompatibilityMinutesFromMidnight {
                reference = .fixedClock(minutesFromMidnight: fixedCompatibilityMinutes)
            } else {
                reference = .wakeAnchor(type: wakeAnchor.type, offsetMinutes: resolveWakeDelta(anchor: wakeAnchor, wakeTime: wakeTime).signedMinutes)
            }
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).wakeAlarm",
                    type: .wakeAlarm,
                    dateKey: input.dateKey,
                    fireDate: wakeTime,
                    relativeTo: reference,
                    isUserVisible: true,
                    affectsCompletion: true,
                    deliveryKinds: [.wake]
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
                    deliveryKinds: []
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
                    deliveryKinds: [.boundary]
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
                    deliveryKinds: iftarDeliveryKinds(for: input.effectiveConfig)
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
        selectedPlan: MorningPlan
    ) -> [String] {
        var notes: [String] = []
        if selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight != nil {
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
