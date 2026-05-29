import Foundation

enum MorningWakeResolutionService {
    static func resolve(
        for day: ActiveAlarmDay,
        scheduleStatusOverride: MorningWakeScheduleStatus? = nil,
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy = .active,
        timeZone: TimeZone = .current
    ) -> ResolvedMorningWakeState {
        let selection = WakeStateSelectionResolver.selectedMode(for: day)
        let underlyingMode = WakeStateSelectionResolver.underlyingMode(for: day)
        let wakePurpose = underlyingMode == .earlyWorship ? WakePurpose.suhoor : .fajr
        let dateAlarmOverride = day.effectiveConfig.dateAlarmOverride == .none
            && day.effectiveConfig.quickWakeModeOverride == .quiet
            ? .quiet
            : day.effectiveConfig.dateAlarmOverride
        let dayContext = WakeStateSelectionResolver.dayContextKind(for: day)
        let boundary = resolveBoundary(
            day: day,
            selection: selection,
            dateAlarmOverride: dateAlarmOverride,
            underlyingMode: underlyingMode,
            dayContext: dayContext,
            timeZone: timeZone
        )
        let wakeTime = resolveWakeTime(day: day, boundary: boundary)
        let activation = resolveAlarmActivation(
            day: day,
            selection: selection,
            dateAlarmOverride: dateAlarmOverride,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy,
            wakeTime: wakeTime
        )
        let resolvedAlarmState = resolveAlarmState(
            activation: activation,
            dateAlarmOverride: dateAlarmOverride,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy
        )
        let scheduleStatus = resolveScheduleStatus(
            day: day,
            activation: activation,
            dateAlarmOverride: dateAlarmOverride,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy,
            override: scheduleStatusOverride
        )
        let visualMode = resolveVisualMode(
            activation: activation,
            underlyingMode: underlyingMode,
            boundary: boundary,
            wakeTime: wakeTime
        )
        let boundaryRegime = resolveBoundaryRegime(
            selection: selection,
            dateAlarmOverride: dateAlarmOverride,
            underlyingMode: underlyingMode,
            boundary: boundary,
            visualMode: visualMode
        )
        let copy = resolveCopyState(
            day: day,
            selection: selection,
            dateAlarmOverride: dateAlarmOverride,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy,
            underlyingMode: underlyingMode,
            wakeTime: wakeTime,
            boundary: boundary,
            activation: activation,
            scheduleStatus: scheduleStatus,
            timeZone: timeZone
        )

        return ResolvedMorningWakeState(
            dateKey: day.dateKey,
            morningDate: day.date,
            dayContext: dayContext,
            wakePurpose: wakePurpose,
            quickWakeSelection: selection,
            underlyingWakeMode: underlyingMode,
            dateAlarmOverride: dateAlarmOverride,
            globalWakeAlarmPolicy: globalWakeAlarmPolicy,
            resolvedAlarmState: resolvedAlarmState,
            boundaryRegime: boundaryRegime,
            wakeBoundaryResolution: boundary,
            wakeTimeResolution: wakeTime,
            alarmActivation: activation,
            scheduleStatus: scheduleStatus,
            visualMode: visualMode,
            copyState: copy,
            persistenceState: .clean,
            accessibilitySummary: copy.accessibilityText
        )
    }

    private static func resolveBoundary(
        day: ActiveAlarmDay,
        selection: QuickWakeMode,
        dateAlarmOverride: DateAlarmOverride,
        underlyingMode: MorningWakeUnderlyingMode,
        dayContext: MorningWakeDayContextKind,
        timeZone: TimeZone
    ) -> WakeBoundaryResolution {
        let window = day.decisionLog.prayerWindow
        let fajrBegins = window.fajrStart
        let fajrEnds = window.fajrEnd
        let reason = boundaryReason(
            selection: selection,
            underlyingMode: underlyingMode,
            dayContext: dayContext
        )

        switch underlyingMode {
        case .fajr:
            return WakeBoundaryResolution(
                kind: fajrEnds == nil ? .unavailable : .fajrBegins,
                leftBoundaryTime: fajrEnds == nil ? nil : fajrBegins,
                rightBoundaryTime: fajrEnds,
                finalThirdStart: nil,
                fajrBegins: fajrBegins,
                fajrEnds: fajrEnds,
                reason: dateAlarmOverride == .quiet ? .quietPreserved : .defaultFajrMorning,
                isEstimated: window.fajrEndSource == .unavailable
            )
        case .earlyWorship:
            guard let finalThirdStart = EarlyWorshipBoundaryResolver.finalThirdStart(
                targetFajrStart: fajrBegins,
                maghrib: window.maghrib,
                timeZone: timeZone
            ) else {
                return WakeBoundaryResolution(
                    kind: .unavailable,
                    leftBoundaryTime: nil,
                    rightBoundaryTime: nil,
                    finalThirdStart: nil,
                    fajrBegins: fajrBegins,
                    fajrEnds: fajrEnds,
                    reason: .fallbackMissingNightData,
                    isEstimated: false
                )
            }

            return WakeBoundaryResolution(
                kind: .finalThirdOfNight,
                leftBoundaryTime: finalThirdStart,
                rightBoundaryTime: fajrBegins,
                finalThirdStart: finalThirdStart,
                fajrBegins: fajrBegins,
                fajrEnds: fajrEnds,
                reason: dateAlarmOverride == .quiet ? .quietPreserved : reason,
                isEstimated: false
            )
        }
    }

    private static func boundaryReason(
        selection: QuickWakeMode,
        underlyingMode: MorningWakeUnderlyingMode,
        dayContext: MorningWakeDayContextKind
    ) -> WakeBoundaryReason {
        if selection == .quiet {
            return .quietPreserved
        }
        guard underlyingMode == .earlyWorship else {
            return .defaultFajrMorning
        }
        switch dayContext {
        case .fastingIntended,
             .ramadanFasting,
             .qadaFastIntended,
             .sunnahFastIntended,
             .customFastIntended:
            return .intendedFasting
        default:
            return .intendedFasting
        }
    }

    private static func resolveWakeTime(
        day: ActiveAlarmDay,
        boundary: WakeBoundaryResolution
    ) -> WakeTimeResolution {
        guard boundary.isAvailable else {
            return WakeTimeResolution(
                wakeTime: nil,
                displayText: nil,
                origin: .unavailable,
                offsetMinutes: nil,
                relationBoundary: .unavailable,
                isEndpoint: false,
                isAdjusted: false,
                isClamped: false,
                minutesBeforeFajrEnd: nil,
                minutesBeforeFajrBegin: nil
            )
        }

        let wakeTime = day.schedule.wakeDate
        let origin = wakeTimeOrigin(for: day)
        let minutesBeforeFajrEnd = boundary.fajrEnds.map {
            Int(round($0.timeIntervalSince(wakeTime) / 60))
        }
        let minutesBeforeFajrBegin = boundary.fajrBegins.map {
            Int(round($0.timeIntervalSince(wakeTime) / 60))
        }
        let relationBoundary = relationBoundary(
            wakeTime: wakeTime,
            boundary: boundary
        )
        let endpoint = isEndpoint(wakeTime, boundary.leftBoundaryTime)
            || isEndpoint(wakeTime, boundary.rightBoundaryTime)
        let offset: Int?
        switch relationBoundary {
        case .fajrBegin:
            offset = minutesBeforeFajrBegin
        case .fajrEnd:
            offset = minutesBeforeFajrEnd
        case .finalThirdStart:
            offset = 0
        case .none, .unavailable:
            offset = nil
        }

        return WakeTimeResolution(
            wakeTime: wakeTime,
            displayText: nil,
            origin: origin,
            offsetMinutes: offset.map(abs),
            relationBoundary: relationBoundary,
            isEndpoint: endpoint,
            isAdjusted: isAdjusted(day),
            isClamped: day.decisionLog.latestWakeCapApplied,
            minutesBeforeFajrEnd: minutesBeforeFajrEnd,
            minutesBeforeFajrBegin: minutesBeforeFajrBegin
        )
    }

    private static func wakeTimeOrigin(for day: ActiveAlarmDay) -> WakeTimeOrigin {
        let rule = day.effectiveConfig.resolvedWakeRule
        if day.decisionLog.latestWakeCapApplied {
            return .clampedToBoundary
        }
        if rule.state == .fixedWake || rule.fixedWakeTimeMinutesFromMidnight != nil {
            return .manualDragOverride
        }
        if day.effectiveConfig.quickWakeModeOverride == .fajr
            || day.effectiveConfig.quickWakeModeOverride == .suhoor {
            return .quickSelectorDefault
        }
        if day.effectiveConfig.wakeRuleWasOverridden {
            return .dateSpecificOverride
        }
        if rule.state == .inFajr,
           rule.anchorType == .fajrEnd,
           rule.deltaMinutes == WakeStateSelectionResolver.defaultFajrDeltaMinutes {
            return .globalDefaultFajrOffset
        }
        if rule.state == .preFajr,
           rule.anchorType == .fajrStart,
           rule.deltaMinutes == WakeStateSelectionResolver.defaultSuhoorDeltaMinutes {
            return .globalDefaultSuhoorOffset
        }
        if day.selectedPlanIsGenerated {
            return .planGenerated
        }
        return .restoredPersistedValue
    }

    private static func relationBoundary(
        wakeTime: Date,
        boundary: WakeBoundaryResolution
    ) -> WakeTimeRelationBoundary {
        if isEndpoint(wakeTime, boundary.finalThirdStart) {
            return .finalThirdStart
        }
        if let fajrBegins = boundary.fajrBegins,
           wakeTime <= fajrBegins,
           boundary.kind == .finalThirdOfNight {
            return .fajrBegin
        }
        if isEndpoint(wakeTime, boundary.fajrBegins) {
            return .fajrBegin
        }
        if boundary.kind == .fajrBegins {
            return .fajrEnd
        }
        return .none
    }

    private static func resolveAlarmActivation(
        day: ActiveAlarmDay,
        selection: QuickWakeMode,
        dateAlarmOverride: DateAlarmOverride,
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy,
        wakeTime: WakeTimeResolution
    ) -> AlarmActivation {
        if wakeTime.wakeTime == nil {
            return .unavailable
        }
        if dateAlarmOverride == .quiet || selection == .quiet {
            return .quietSuppressed
        }
        if globalWakeAlarmPolicy == .pausedIndefinitely,
           dateAlarmOverride != .ringDespitePause {
            return .pausedSuppressed
        }
        if day.effectiveConfig.skipDay {
            return .offWithAnchor
        }
        if !day.effectiveConfig.suhoorEnabled {
            return .offWithAnchor
        }
        return .active
    }

    private static func resolveAlarmState(
        activation: AlarmActivation,
        dateAlarmOverride: DateAlarmOverride,
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy
    ) -> ResolvedAlarmState {
        switch activation {
        case .active:
            if globalWakeAlarmPolicy == .pausedIndefinitely,
               dateAlarmOverride == .ringDespitePause {
                return .ringsOnceDespitePause
            }
            return .active
        case .quietSuppressed:
            return .quiet
        case .pausedSuppressed:
            return .pausedInherited
        case .offWithAnchor, .noAnchor:
            return .blocked
        case .unavailable:
            return .unavailable
        }
    }

    private static func resolveScheduleStatus(
        day: ActiveAlarmDay,
        activation: AlarmActivation,
        dateAlarmOverride: DateAlarmOverride,
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy,
        override: MorningWakeScheduleStatus?
    ) -> MorningWakeScheduleStatus {
        if let override {
            return override
        }

        switch activation {
        case .active:
            if globalWakeAlarmPolicy == .pausedIndefinitely,
               dateAlarmOverride == .ringDespitePause,
               day.scheduledEvents.contains(where: { $0.type == .wakeAlarm }) {
                return .scheduledDespitePause
            }
            return day.scheduledEvents.contains(where: { $0.type == .wakeAlarm })
                ? .scheduled
                : .pending
        case .quietSuppressed:
            return .notScheduledBecauseQuiet
        case .pausedSuppressed:
            return .notScheduledBecausePaused
        case .offWithAnchor:
            return .notScheduledBecauseQuiet
        case .noAnchor:
            return .notScheduledBecauseNoAnchor
        case .unavailable:
            return .notScheduledBecauseUnavailable
        }
    }

    private static func resolveVisualMode(
        activation: AlarmActivation,
        underlyingMode: MorningWakeUnderlyingMode,
        boundary: WakeBoundaryResolution,
        wakeTime: WakeTimeResolution
    ) -> MorningWakeVisualMode {
        guard boundary.isAvailable else {
            return .hiddenUnavailable
        }

        if let wake = wakeTime.wakeTime,
           let left = boundary.leftBoundaryTime,
           let right = boundary.rightBoundaryTime,
           (wake < left || wake > right) {
            return .hiddenOutOfRange
        }

        switch (activation, underlyingMode) {
        case (.active, .fajr):
            return .interactiveDefaultFajr
        case (.active, .earlyWorship):
            return .interactiveEarlyWorship
        case (.quietSuppressed, .fajr):
            return .staticDefaultFajrQuiet
        case (.quietSuppressed, .earlyWorship):
            return .staticEarlyWorshipQuiet
        case (.pausedSuppressed, _):
            return .staticNoAlarmWithBoundaries
        case (.offWithAnchor, _), (.noAnchor, _):
            return .staticNoAlarmWithBoundaries
        case (.unavailable, _):
            return .hiddenUnavailable
        }
    }

    private static func resolveBoundaryRegime(
        selection: QuickWakeMode,
        dateAlarmOverride: DateAlarmOverride,
        underlyingMode: MorningWakeUnderlyingMode,
        boundary: WakeBoundaryResolution,
        visualMode: MorningWakeVisualMode
    ) -> WakeBoundaryRegime {
        guard boundary.isAvailable else {
            return .unavailable
        }
        if visualMode == .hiddenOutOfRange {
            return .customOutOfRange
        }
        if dateAlarmOverride == .quiet || selection == .quiet {
            return underlyingMode == .earlyWorship ? .quietEarlyWorshipWindow : .quietDefaultFajrWindow
        }
        return underlyingMode == .earlyWorship ? .earlyWorshipWindow : .defaultFajrWindow
    }

    private static func resolveCopyState(
        day: ActiveAlarmDay,
        selection: QuickWakeMode,
        dateAlarmOverride: DateAlarmOverride,
        globalWakeAlarmPolicy: GlobalWakeAlarmPolicy,
        underlyingMode: MorningWakeUnderlyingMode,
        wakeTime: WakeTimeResolution,
        boundary: WakeBoundaryResolution,
        activation: AlarmActivation,
        scheduleStatus: MorningWakeScheduleStatus,
        timeZone: TimeZone
    ) -> WakeCopyState {
        let scheduleWarning = scheduleWarningText(for: scheduleStatus)
        if dateAlarmOverride == .quiet || selection == .quiet {
            let savedRelation = wakeTime.wakeTime.map {
                "Alarm saved for \(timeFormatter(timeZone: timeZone).string(from: $0))"
            } ?? "Alarm saved"
            let accessibility = "Quiet. No alarm will ring for this morning. \(boundaryAccessibilityText(boundary, timeZone: timeZone))"
            return WakeCopyState(
                primaryHeroText: "Quiet",
                finalRelationText: savedRelation,
                relationTone: .stateText,
                detailExplanation: "Quiet keeps this morning's plan saved without ringing an alarm.",
                scheduleWarningText: scheduleWarning,
                accessibilityText: accessibility
            )
        }

        if activation == .pausedSuppressed,
           let wake = wakeTime.wakeTime {
            let savedRelation = "Alarm saved for \(timeFormatter(timeZone: timeZone).string(from: wake))"
            return WakeCopyState(
                primaryHeroText: "Alarms paused",
                finalRelationText: savedRelation,
                relationTone: .stateText,
                detailExplanation: "Wake alarms are paused until resumed.",
                scheduleWarningText: scheduleWarning,
                accessibilityText: "Alarms paused. \(savedRelation)."
            )
        }

        if activation == .offWithAnchor,
           let wake = wakeTime.wakeTime {
            let relation = relationText(
                wakeTime: wake,
                underlyingMode: underlyingMode,
                boundary: boundary
            )
            let plannedRelation = "Alarm saved for \(timeFormatter(timeZone: timeZone).string(from: wake)). \(relation)"
            return WakeCopyState(
                primaryHeroText: "Alarm off",
                finalRelationText: plannedRelation,
                relationTone: .stateText,
                detailExplanation: "The wake anchor is preserved, but the alarm is off for this date.",
                scheduleWarningText: scheduleWarning,
                accessibilityText: "Alarm off. \(plannedRelation)."
            )
        }

        guard activation != .unavailable,
              let wake = wakeTime.wakeTime else {
            return WakeCopyState(
                primaryHeroText: "Set location",
                finalRelationText: "Fajr times are not available yet",
                relationTone: .warning,
                detailExplanation: "Required timing data is missing for this morning.",
                scheduleWarningText: scheduleWarning,
                accessibilityText: "Wake time unavailable. Required timing data is missing."
            )
        }

        let formatter = timeFormatter(timeZone: timeZone)
        let relation = relationText(
            wakeTime: wake,
            underlyingMode: underlyingMode,
            boundary: boundary
        )
        let tone = relationTone(
            wakeTime: wake,
            underlyingMode: underlyingMode,
            activation: activation,
            boundary: boundary
        )
        let accessibility = [
            "\(selection.displayTitle) selected",
            "Alarm at \(formatter.string(from: wake))",
            relation
        ].joined(separator: ". ")

        return WakeCopyState(
            primaryHeroText: formatter.string(from: wake),
            finalRelationText: globalWakeAlarmPolicy == .pausedIndefinitely && dateAlarmOverride == .ringDespitePause
                ? "Rings tomorrow only"
                : relation,
            relationTone: tone,
            detailExplanation: nil,
            scheduleWarningText: scheduleWarning,
            accessibilityText: accessibility
        )
    }

    private static func relationText(
        wakeTime: Date,
        underlyingMode: MorningWakeUnderlyingMode,
        boundary: WakeBoundaryResolution
    ) -> String {
        switch underlyingMode {
        case .earlyWorship:
            if isEndpoint(wakeTime, boundary.finalThirdStart) {
                return "At the last third of the night"
            }
            if isEndpoint(wakeTime, boundary.fajrBegins) {
                return "As Fajr begins"
            }
            if let fajrBegins = boundary.fajrBegins {
                let minutes = Int(round(fajrBegins.timeIntervalSince(wakeTime) / 60))
                return "\(minutes) min before Fajr begins"
            }
        case .fajr:
            if isEndpoint(wakeTime, boundary.fajrBegins) {
                return "As Fajr begins"
            }
            if isEndpoint(wakeTime, boundary.fajrEnds) {
                return "As Fajr ends"
            }
            if let fajrEnds = boundary.fajrEnds {
                let minutes = Int(round(fajrEnds.timeIntervalSince(wakeTime) / 60))
                return "\(minutes) min before Fajr ends"
            }
        }
        return "Alarm saved"
    }

    private static func relationTone(
        wakeTime: Date,
        underlyingMode: MorningWakeUnderlyingMode,
        activation: AlarmActivation,
        boundary: WakeBoundaryResolution
    ) -> WakeCopyTone {
        guard underlyingMode == .fajr, activation == .active else {
            return .normal
        }
        guard let fajrEnds = boundary.fajrEnds else {
            return .normal
        }
        let minutesBeforeFajrEnd = Int(round(fajrEnds.timeIntervalSince(wakeTime) / 60))
        return minutesBeforeFajrEnd <= 14 ? .urgentRed : .normal
    }

    private static func scheduleWarningText(for status: MorningWakeScheduleStatus) -> String? {
        switch status {
        case .permissionBlocked:
            return "Alarm permission needed"
        case .failed:
            return "Alarm could not be scheduled"
        case .pending:
            return "Next alarm soon"
        case .notScheduledBecausePaused, .scheduledDespitePause:
            return nil
        case .scheduled,
             .notScheduledBecauseQuiet,
             .notScheduledBecauseNoAnchor,
             .notScheduledBecauseUnavailable,
             .unavailable:
            return nil
        }
    }

    private static func boundaryAccessibilityText(
        _ boundary: WakeBoundaryResolution,
        timeZone: TimeZone
    ) -> String {
        let formatter = timeFormatter(timeZone: timeZone)
        switch boundary.kind {
        case .fajrBegins:
            guard let begin = boundary.fajrBegins, let end = boundary.fajrEnds else {
                return "Fajr times are not available yet."
            }
            return "Fajr begins at \(formatter.string(from: begin)) and Fajr ends at \(formatter.string(from: end))."
        case .finalThirdOfNight:
            guard let finalThird = boundary.finalThirdStart, let begin = boundary.fajrBegins else {
                return "Suhoor boundary times are not available yet."
            }
            return "Final third begins at \(formatter.string(from: finalThird)) and Fajr begins at \(formatter.string(from: begin))."
        case .unavailable:
            return "Fajr times are not available yet."
        }
    }

    private static func isAdjusted(_ day: ActiveAlarmDay) -> Bool {
        day.effectiveConfig.resolvedWakeRule.state == .fixedWake
            || day.effectiveConfig.resolvedWakeRule.fixedWakeTimeMinutesFromMidnight != nil
            || (day.effectiveConfig.wakeRuleWasOverridden && day.effectiveConfig.quickWakeModeOverride == nil)
    }

    private static func isEndpoint(_ lhs: Date, _ rhs: Date?) -> Bool {
        guard let rhs else { return false }
        return abs(lhs.timeIntervalSince(rhs)) < 60
    }

    private static func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }
}

private extension ActiveAlarmDay {
    var selectedPlanIsGenerated: Bool {
        switch decisionLog.selectedPlanID {
        case let id where id.contains("ramadan")
            || id.contains("qada")
            || id.contains("sunnah"):
            return true
        default:
            return false
        }
    }
}
