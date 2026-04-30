import Foundation

enum MorningWakeResolutionService {
    static func resolve(
        for day: ActiveAlarmDay,
        scheduleStatusOverride: MorningWakeScheduleStatus? = nil,
        timeZone: TimeZone = .current
    ) -> ResolvedMorningWakeState {
        let selection = WakeStateSelectionResolver.selectedMode(for: day)
        let underlyingMode = WakeStateSelectionResolver.underlyingMode(for: day)
        let dayContext = WakeStateSelectionResolver.dayContextKind(for: day)
        let boundary = resolveBoundary(
            day: day,
            selection: selection,
            underlyingMode: underlyingMode,
            dayContext: dayContext,
            timeZone: timeZone
        )
        let wakeTime = resolveWakeTime(day: day, boundary: boundary)
        let activation = resolveAlarmActivation(
            day: day,
            selection: selection,
            wakeTime: wakeTime
        )
        let scheduleStatus = resolveScheduleStatus(
            day: day,
            activation: activation,
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
            underlyingMode: underlyingMode,
            boundary: boundary,
            visualMode: visualMode
        )
        let copy = resolveCopyState(
            day: day,
            selection: selection,
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
            quickWakeSelection: selection,
            underlyingWakeMode: underlyingMode,
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
                reason: selection == .quiet ? .quietPreserved : .defaultFajrMorning,
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
                reason: selection == .quiet ? .quietPreserved : reason,
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
        case .tahajjudIntended:
            return .intendedTahajjud
        case .fastingAndTahajjudIntended:
            return .intendedFastingAndTahajjud
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
            || day.effectiveConfig.quickWakeModeOverride == .fast {
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
           rule.deltaMinutes == WakeStateSelectionResolver.defaultFastDeltaMinutes {
            return .globalDefaultFastOffset
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
        wakeTime: WakeTimeResolution
    ) -> AlarmActivation {
        if wakeTime.wakeTime == nil {
            return .unavailable
        }
        if selection == .quiet {
            return .quietSuppressed
        }
        if day.effectiveConfig.skipDay {
            return .offWithAnchor
        }
        if !day.effectiveConfig.suhoorEnabled {
            return .offWithAnchor
        }
        return .active
    }

    private static func resolveScheduleStatus(
        day: ActiveAlarmDay,
        activation: AlarmActivation,
        override: MorningWakeScheduleStatus?
    ) -> MorningWakeScheduleStatus {
        if let override {
            return override
        }

        switch activation {
        case .active:
            return day.scheduledEvents.contains(where: { $0.type == .wakeAlarm })
                ? .scheduled
                : .pending
        case .quietSuppressed, .offWithAnchor:
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
        case (.offWithAnchor, _), (.noAnchor, _):
            return .staticNoAlarmWithBoundaries
        case (.unavailable, _):
            return .hiddenUnavailable
        }
    }

    private static func resolveBoundaryRegime(
        selection: QuickWakeMode,
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
        if selection == .quiet {
            return underlyingMode == .earlyWorship ? .quietEarlyWorshipWindow : .quietDefaultFajrWindow
        }
        return underlyingMode == .earlyWorship ? .earlyWorshipWindow : .defaultFajrWindow
    }

    private static func resolveCopyState(
        day: ActiveAlarmDay,
        selection: QuickWakeMode,
        underlyingMode: MorningWakeUnderlyingMode,
        wakeTime: WakeTimeResolution,
        boundary: WakeBoundaryResolution,
        activation: AlarmActivation,
        scheduleStatus: MorningWakeScheduleStatus,
        timeZone: TimeZone
    ) -> WakeCopyState {
        let scheduleWarning = scheduleWarningText(for: scheduleStatus)
        if selection == .quiet {
            let accessibility = "Quiet mode on. No wake alarm will ring. \(boundaryAccessibilityText(boundary, timeZone: timeZone))"
            return WakeCopyState(
                primaryHeroText: "Quiet mode on",
                finalRelationText: "No wake alarm for tomorrow",
                relationTone: .stateText,
                detailExplanation: "Quiet suppresses the wake alarm without deleting this morning's underlying plan.",
                scheduleWarningText: scheduleWarning,
                accessibilityText: accessibility
            )
        }

        if activation == .offWithAnchor,
           let wake = wakeTime.wakeTime {
            let relation = relationText(
                wakeTime: wake,
                underlyingMode: underlyingMode,
                boundary: boundary
            )
            let plannedRelation = relation.replacingOccurrences(of: "Wake up", with: "Planned wake was")
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
                primaryHeroText: "Wake time unavailable",
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
        let tone = relationTone(wakeTime: wake, boundary: boundary)
        let accessibility = [
            "\(selection.displayTitle) wake selected",
            "Alarm at \(formatter.string(from: wake))",
            relation
        ].joined(separator: ". ")

        return WakeCopyState(
            primaryHeroText: formatter.string(from: wake),
            finalRelationText: relation,
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
                return "Wake up for the last third of the night"
            }
            if isEndpoint(wakeTime, boundary.fajrBegins) {
                return "Wake up as Fajr begins"
            }
            if let fajrBegins = boundary.fajrBegins {
                let minutes = Int(round(fajrBegins.timeIntervalSince(wakeTime) / 60))
                return "Wake up \(minutes) min before Fajr begins"
            }
        case .fajr:
            if isEndpoint(wakeTime, boundary.fajrBegins) {
                return "Wake up as Fajr begins"
            }
            if isEndpoint(wakeTime, boundary.fajrEnds) {
                return "Wake up as Fajr ends"
            }
            if let fajrEnds = boundary.fajrEnds {
                let minutes = Int(round(fajrEnds.timeIntervalSince(wakeTime) / 60))
                return "Wake up \(minutes) min before Fajr ends"
            }
        }
        return "Wake time selected"
    }

    private static func relationTone(
        wakeTime: Date,
        boundary: WakeBoundaryResolution
    ) -> WakeCopyTone {
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
            return "Wake time selected, but alarm is not scheduled yet"
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
                return "Early-worship times are not available yet."
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
            || id.contains("sunnah")
            || id.contains("tahajjud"):
            return true
        default:
            return false
        }
    }
}
