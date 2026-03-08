import CoreLocation
import Foundation

struct MorningScheduleResolutionInput: Sendable {
    let date: Date
    let dateKey: String
    let provenances: [ResolvedScheduledDateProvenance]
    let settings: AppSettings
    let defaultConfig: DefaultAlarmConfig
    let effectiveConfig: EffectiveDailyConfig
    let tagResult: TagComputationResult
    let coordinate: CLLocationCoordinate2D
    let timeZone: TimeZone
    let locationDescription: String
    let morningPlanState: MorningPlanState
}

struct MorningScheduleResolution: Sendable {
    let schedule: DaySchedule
    let effectiveConfig: EffectiveDailyConfig
    let resolvedDayContext: ResolvedDayContext
    let materializedEvents: [ScheduledEvent]
    let decisionLog: RuleDecisionLog
    let primaryDisplay: PrimaryDisplay?
}

enum MorningScheduleResolver {
    static let resolverVersion = 1

    static func resolve(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator = PrayerTimeCalculator()
    ) -> MorningScheduleResolution? {
        let prayerWindow = resolvePrayerWindow(input: input, calculator: calculator)
        guard let prayerWindow else { return nil }

        let planSelection = selectPlan(input: input)
        let wakeAnchor = resolveWakeAnchor(
            prayerWindow: prayerWindow,
            anchorType: planSelection.selectedPlan.wakeAnchorType
        )
        let wakeTime = resolveWakeTime(
            day: input.date,
            anchor: wakeAnchor,
            effectiveConfig: input.effectiveConfig,
            selectedPlan: planSelection.selectedPlan,
            timeZone: input.timeZone
        )
        let wakeDelta = resolveWakeDelta(anchor: wakeAnchor, wakeTime: wakeTime)
        let resolvedContext = resolveContext(
            input: input,
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
            timeZone: input.timeZone
        )
        let iftarDate = behaviorProfile.iftarReminderEnabled ? prayerWindow.maghrib : nil
        let boundaryDate = behaviorProfile.fajrBoundaryNoticeEnabled ? prayerWindow.fajrStart : nil

        let schedule = DaySchedule(
            date: input.date,
            fajrDate: prayerWindow.fajrStart,
            maghribDate: prayerWindow.maghrib,
            wakeDate: wakeTime,
            reminderDate: behaviorProfile.reminderEnabled ? reminder : nil,
            boundaryDate: boundaryDate,
            iftarDate: iftarDate,
            fajrSoundChoice: input.effectiveConfig.fajrSoundChoice,
            iftarSoundChoice: input.effectiveConfig.iftarSoundChoice,
            locationDescription: input.locationDescription,
            offsetMinutes: max(0, Int(round(prayerWindow.fajrStart.timeIntervalSince(wakeTime) / 60))),
            calculationMethodName: input.settings.calculationMethod.displayName,
            timeZone: input.timeZone
        )

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
        let primaryDisplay = resolvePrimaryDisplay(from: materializedEvents)
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
            candidateContexts: candidateContexts(for: input.tagResult, provenances: input.provenances),
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

        return MorningScheduleResolution(
            schedule: schedule,
            effectiveConfig: input.effectiveConfig,
            resolvedDayContext: resolvedContext,
            materializedEvents: materializedEvents,
            decisionLog: decisionLog,
            primaryDisplay: primaryDisplay
        )
    }

    private static func resolvePrayerWindow(
        input: MorningScheduleResolutionInput,
        calculator: PrayerTimeCalculator
    ) -> DailyPrayerWindow? {
        guard let fajrStart = calculator.fajrDate(
            for: input.date,
            location: input.coordinate,
            timeZone: input.timeZone,
            method: input.settings.calculationMethod,
            adjustmentMinutes: input.settings.fajrAdjustmentMinutes
        ),
        let maghrib = calculator.maghribDate(
            for: input.date,
            location: input.coordinate,
            timeZone: input.timeZone,
            adjustmentMinutes: input.settings.maghribAdjustmentMinutes
        ) else {
            return nil
        }

        let fajrEnd = calculator.sunriseDate(
            for: input.date,
            location: input.coordinate,
            timeZone: input.timeZone,
            adjustmentMinutes: 0
        )

        return DailyPrayerWindow(
            date: input.date,
            fajrStart: fajrStart,
            fajrEnd: fajrEnd,
            maghrib: maghrib
        )
    }

    private static func candidateContexts(
        for tagResult: TagComputationResult,
        provenances: [ResolvedScheduledDateProvenance]
    ) -> [MorningContextType] {
        var contexts: [MorningContextType] = [.standard]
        let meaningfulProvenances = provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        switch tagResult.computedPrimaryIntent {
        case .ramadanObligatory, .kaffarahExpiation, .vowNadhr:
            contexts.append(.fasting)
        case .qadaMakeup:
            contexts.append(.qadaFast)
        case .voluntary:
            contexts.append(.sunnahFast)
        case .forbidden, .other:
            break
        }

        if meaningfulProvenances.contains(where: { $0.sourceOrigin == .defaultRamadan }) {
            contexts.append(.fasting)
        }
        if !tagResult.computedSecondaryTags.isEmpty {
            contexts.append(.specialDay)
        }
        return Array(NSOrderedSet(array: contexts).compactMap { $0 as? MorningContextType })
    }

    private static func resolveContext(
        input: MorningScheduleResolutionInput,
        wakeTime: Date
    ) -> ResolvedDayContext {
        let supportingTags = resolvedTags(input: input)
        let warnings = FastIntentEngine.warnings(for: input.date, timeZone: input.timeZone)
        let primaryContext: MorningContextType
        switch input.tagResult.computedPrimaryIntent {
        case .qadaMakeup:
            primaryContext = .qadaFast
        case .ramadanObligatory, .kaffarahExpiation, .vowNadhr:
            primaryContext = .fasting
        case .voluntary:
            primaryContext = input.tagResult.computedSecondaryTags.isEmpty ? .fasting : .sunnahFast
        case .forbidden, .other:
            primaryContext = .standard
        }

        var secondaryContexts: [MorningContextType] = []
        if wakeTime < input.date.addingTimeInterval(24 * 60 * 60),
           wakeTime < input.date.addingTimeInterval(6 * 60 * 60) {
            secondaryContexts.append(.suhoor)
        }
        if primaryContext == .standard,
           input.provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }) == false,
           !warnings.isEmpty {
            secondaryContexts.append(.specialDay)
        }
        if !input.tagResult.computedSecondaryTags.isEmpty || !warnings.isEmpty {
            secondaryContexts.append(.specialDay)
        }

        let summary = contextSummary(primaryContext: primaryContext, supportingTags: supportingTags)
        let details = contextDetails(input: input, supportingTags: supportingTags)

        return ResolvedDayContext(
            primaryContext: primaryContext,
            secondaryContexts: Array(NSOrderedSet(array: secondaryContexts).compactMap { $0 as? MorningContextType }),
            supportingTags: supportingTags,
            explanation: ContextExplanation(summary: summary, details: details)
        )
    }

    private static func contextSummary(
        primaryContext: MorningContextType,
        supportingTags: [DayTag]
    ) -> String {
        switch primaryContext {
        case .standard:
            return "Using the default morning plan."
        case .fasting:
            if supportingTags.contains(.ramadan) {
                return "Ramadan context is shaping today's wake."
            }
            return "A fasting context is shaping today's wake."
        case .qadaFast:
            return "A Qada plan is shaping today's wake."
        case .sunnahFast:
            return "A Sunnah observance is shaping today's wake."
        case .tahajjud:
            return "Tahajjud context is shaping today's wake."
        case .suhoor:
            return "Suhoor context is shaping today's wake."
        case .jamaah:
            return "A jama'ah context is shaping today's wake."
        case .specialDay:
            return "A special-day context is shaping today's wake."
        }
    }

    private static func contextDetails(
        input: MorningScheduleResolutionInput,
        supportingTags: [DayTag]
    ) -> [String] {
        var details: [String] = []
        if input.provenances.contains(where: { $0.sourceOrigin == .defaultDailyPlan }) {
            details.append("The daily morning plan applies to this date.")
        }
        if input.effectiveConfig.hasOverrides {
            details.append("A date-specific override is active.")
        }
        for tag in supportingTags where tag != .dailyPlan && tag != .locationBased {
            details.append("\(tag.title) contributes labels and progress metadata.")
        }
        if input.defaultConfig.defaultSuhoorTimeMode == .fixedTime || input.effectiveConfig.suhoorTimeMode == .fixedTime {
            details.append("Fixed wake compatibility is being used for this date.")
        }
        return details
    }

    private static func resolvedTags(input: MorningScheduleResolutionInput) -> [DayTag] {
        var tags: [DayTag] = [.locationBased]

        if input.provenances.contains(where: { $0.sourceOrigin == .defaultDailyPlan }) {
            tags.append(.dailyPlan)
        }

        for provenance in input.provenances {
            switch provenance.sourceOrigin {
            case .defaultRamadan:
                tags.append(.ramadan)
            case .manualSingleDay:
                tags.append(.manualDay)
            case .manualGregorianRange:
                tags.append(.manualRange)
            case .islamicQuickAdd, .recurringIslamic:
                break
            case .migratedLegacyAlways, .migratedLegacyDateRange:
                break
            case .defaultDailyPlan:
                tags.append(.dailyPlan)
            }
        }

        switch input.tagResult.computedPrimaryIntent {
        case .ramadanObligatory:
            tags.append(.ramadan)
        case .qadaMakeup:
            tags.append(.qada)
        case .kaffarahExpiation:
            tags.append(.kaffarah)
        case .vowNadhr:
            tags.append(.vow)
        case .voluntary:
            tags.append(.voluntary)
        case .forbidden, .other:
            break
        }

        for tag in input.tagResult.computedSecondaryTags {
            switch tag {
            case .shawwalSix:
                tags.append(.shawwalSix)
            case .arafah:
                tags.append(.arafah)
            case .ashura:
                tags.append(.ashura)
            case .whiteDays:
                tags.append(.whiteDays)
            case .mondayThursday:
                tags.append(.mondayThursday)
            case .dhulHijjahFirstNine:
                tags.append(.dhulHijjahFirstNine)
            }
        }

        if input.tagResult.computedPrimaryIntent == .forbidden {
            let warnings = FastIntentEngine.warnings(for: input.date, timeZone: input.timeZone)
            if warnings.contains(.eidAlFitr) || warnings.contains(.eidAlAdha) {
                tags.append(.eid)
            }
            if warnings.contains(.tashreeq) {
                tags.append(.tashreeq)
            }
        }

        if input.defaultConfig.defaultSuhoorTimeMode == .fixedTime || input.effectiveConfig.suhoorTimeMode == .fixedTime {
            tags.append(.fixedTimeCompatibility)
        }

        return Array(NSOrderedSet(array: tags).compactMap { $0 as? DayTag })
    }

    private static func selectPlan(
        input: MorningScheduleResolutionInput
    ) -> (selectedPlan: MorningPlan, candidates: [RulePlanCandidate], precedenceReason: String) {
        let defaultPlan = input.morningPlanState.defaultDailyPlan
        let meaningfulProvenances = input.provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        var candidates = [
            RulePlanCandidate(id: defaultPlan.id, title: defaultPlan.title, kind: defaultPlan.kind)
        ]

        if input.effectiveConfig.hasOverrides {
            let overridePlan = MorningPlan(
                id: "override-\(input.dateKey)",
                title: "Date override",
                kind: .explicitDateOverride,
                wakeAnchorType: defaultPlan.wakeAnchorType,
                wakeDelta: defaultPlan.wakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: defaultPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
                reminderEnabled: input.effectiveConfig.reminderEnabled,
                wakeAlarmEnabled: input.effectiveConfig.suhoorEnabled,
                fajrBoundaryNoticeEnabled: input.effectiveConfig.fajrEnabled,
                iftarReminderEnabled: input.effectiveConfig.iftarEnabled
            )
            candidates.insert(
                RulePlanCandidate(id: overridePlan.id, title: overridePlan.title, kind: overridePlan.kind),
                at: 0
            )
            return (overridePlan, candidates, "Explicit single-date override takes precedence.")
        }

        if input.tagResult.computedPrimaryIntent == .qadaMakeup {
            let qadaPlan = MorningPlan(
                id: "qada-\(input.dateKey)",
                title: "Qada day",
                kind: .qadaAssignment,
                wakeAnchorType: defaultPlan.wakeAnchorType,
                wakeDelta: defaultPlan.wakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: defaultPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
                reminderEnabled: defaultPlan.reminderEnabled,
                wakeAlarmEnabled: defaultPlan.wakeAlarmEnabled,
                fajrBoundaryNoticeEnabled: defaultPlan.fajrBoundaryNoticeEnabled,
                iftarReminderEnabled: true
            )
            candidates.insert(
                RulePlanCandidate(id: qadaPlan.id, title: qadaPlan.title, kind: qadaPlan.kind),
                at: 0
            )
            return (qadaPlan, candidates, "Qada context overrides the default daily plan.")
        }

        if meaningfulProvenances.isEmpty == false {
            let overlayPlan = MorningPlan(
                id: "overlay-\(input.dateKey)",
                title: "Context overlay",
                kind: .generatedObservance,
                wakeAnchorType: defaultPlan.wakeAnchorType,
                wakeDelta: defaultPlan.wakeDelta,
                fixedWakeTimeCompatibilityMinutesFromMidnight: defaultPlan.fixedWakeTimeCompatibilityMinutesFromMidnight,
                reminderEnabled: defaultPlan.reminderEnabled,
                wakeAlarmEnabled: defaultPlan.wakeAlarmEnabled,
                fajrBoundaryNoticeEnabled: defaultPlan.fajrBoundaryNoticeEnabled,
                iftarReminderEnabled: defaultPlan.iftarReminderEnabled
            )
            candidates.insert(
                RulePlanCandidate(id: overlayPlan.id, title: overlayPlan.title, kind: overlayPlan.kind),
                at: 0
            )
            return (overlayPlan, candidates, "An observance or source overlay applies to this date.")
        }

        return (defaultPlan, candidates, "The default daily plan applies.")
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
        let signedMinutes = resolvedDelta.signedMinutes
        return Calendar.current.date(byAdding: .minute, value: signedMinutes, to: anchor.date) ?? anchor.date
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
            wakeFollowUpEnabled: FeatureFlags.enableSnooze && input.settings.snoozeEnabled,
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
            let followUpDate = wakeTime.addingTimeInterval(TimeInterval(input.settings.snoozeMinutes * 60))
            events.append(
                ScheduledEvent(
                    id: "\(input.dateKey).wakeFollowUp",
                    type: .wakeFollowUp,
                    dateKey: input.dateKey,
                    fireDate: followUpDate,
                    relativeTo: .wakeAlarm(offsetMinutes: input.settings.snoozeMinutes),
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

    private static func resolvePrimaryDisplay(from events: [ScheduledEvent]) -> PrimaryDisplay? {
        for type in [ScheduledEventType.wakeAlarm, .wakeReminder, .fajrBoundaryNotice, .iftarReminder] {
            guard let event = events.first(where: { $0.type == type }) else { continue }
            switch event.type {
            case .wakeAlarm:
                return PrimaryDisplay(time: event.fireDate, kind: .suhoor)
            case .wakeReminder:
                return PrimaryDisplay(time: event.fireDate, kind: .reminder)
            case .fajrBoundaryNotice:
                return PrimaryDisplay(time: event.fireDate, kind: .fajr)
            case .iftarReminder:
                return PrimaryDisplay(time: event.fireDate, kind: .iftar)
            case .wakeFollowUp:
                break
            }
        }
        return nil
    }

    private static func compatibilityNotes(
        input: MorningScheduleResolutionInput,
        selectedPlan: MorningPlan
    ) -> [String] {
        var notes: [String] = []
        if selectedPlan.fixedWakeTimeCompatibilityMinutesFromMidnight != nil {
            notes.append("fixed_time_wake_compatibility")
        }
        if input.morningPlanState.activationMode == .legacyCompat {
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
