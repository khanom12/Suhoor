import Foundation

enum ObservanceOpportunityResolver {
    static func resolve(
        date: Date,
        dateKey: String,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        timeZone: TimeZone
    ) -> [ObservanceOpportunity] {
        var opportunities: [String: ObservanceOpportunity] = [:]

        for warning in FastIntentEngine.warnings(for: date, timeZone: timeZone) {
            let kind: ObservanceKind
            switch warning {
            case .eidAlFitr:
                kind = .eidAlFitr
            case .eidAlAdha:
                kind = .eidAlAdha
            case .tashreeq:
                kind = .tashreeq
            }
            upsert(kind: kind, source: .hijriCalendar, dateKey: dateKey, into: &opportunities)
        }

        if FastIntentEngine.isRamadan(date, timeZone: timeZone)
            || provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }) {
            upsert(kind: .ramadan, source: .hijriCalendar, dateKey: dateKey, into: &opportunities)
        }

        let derivedTags = FastIntentEngine.dateDerivedObservanceTags(
            for: date,
            timeZone: timeZone,
            includeShawwalPotential: true
        )
        for tag in derivedTags.union(tagResult.computedSecondaryTags).union(tagResult.suppressedSecondaryTags) {
            let kind = ObservanceKind(tag)
            let source: ObservanceSource = kind == .mondayThursday ? .gregorianWeekday : .hijriCalendar
            upsert(kind: kind, source: source, dateKey: dateKey, into: &opportunities)
        }

        for provenance in provenances {
            for kind in opportunityKinds(for: provenance.sourceOrigin) {
                upsert(
                    kind: kind,
                    source: .scheduledDateSource(provenance.sourceOrigin),
                    dateKey: dateKey,
                    into: &opportunities
                )
            }
        }

        return opportunities.values.sorted {
            if $0.priority == $1.priority {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.priority < $1.priority
        }
    }

    private static func upsert(
        kind: ObservanceKind,
        source: ObservanceSource,
        dateKey: String,
        into opportunities: inout [String: ObservanceOpportunity]
    ) {
        let opportunity = ObservanceOpportunity(
            id: opportunityID(dateKey: dateKey, kind: kind),
            kind: kind,
            eligibility: eligibility(for: kind),
            source: source,
            priority: priority(for: kind),
            isActionable: isActionable(kind),
            title: title(for: kind),
            detail: detail(for: kind)
        )
        if let existing = opportunities[opportunity.id],
           existing.priority <= opportunity.priority {
            return
        }
        opportunities[opportunity.id] = opportunity
    }

    static func opportunityID(dateKey: String, kind: ObservanceKind) -> String {
        "\(dateKey).opportunity.\(kind.rawValue)"
    }

    private static func opportunityKinds(for origin: ScheduledDateSourceOrigin) -> [ObservanceKind] {
        switch origin {
        case .defaultDailyPlan:
            return []
        case .defaultRamadan:
            return [.ramadan]
        case .manualSingleDay, .manualGregorianRange, .migratedLegacyAlways, .migratedLegacyDateRange:
            return [.voluntaryGeneral]
        case .recurringIslamic(let rule):
            switch rule {
            case .whiteDays:
                return [.whiteDays]
            case .mondayThursday:
                return [.mondayThursday]
            case .ramadan:
                return [.ramadan]
            }
        case .islamicQuickAdd(let kind):
            switch kind {
            case .nextAshura:
                return [.ashura]
            case .nextArafah:
                return [.arafah]
            case .nextDhulHijjahFirstNine:
                return [.dhulHijjahFirstNine]
            case .nextEidAlFitr:
                return [.eidAlFitr]
            case .nextEidAlAdha:
                return [.eidAlAdha]
            case .nextWhiteDays:
                return [.whiteDays]
            case .nextRamadanMonth:
                return [.ramadan]
            case .nextMondayThursdayPair:
                return [.mondayThursday]
            }
        }
    }

    private static func eligibility(for kind: ObservanceKind) -> ObservanceEligibility {
        switch kind {
        case .ramadan:
            return .obligatory
        case .mondayThursday, .whiteDays, .arafah, .ashura, .dhulHijjahFirstNine, .shawwalSixPotential:
            return .recommended
        case .eidAlFitr, .eidAlAdha, .tashreeq:
            return .forbidden
        case .qadaAssignable, .voluntaryGeneral, .tahajjudEligible:
            return .permissible
        case .ordinary:
            return .neutral
        }
    }

    private static func isActionable(_ kind: ObservanceKind) -> Bool {
        switch kind {
        case .ordinary, .eidAlFitr, .eidAlAdha, .tashreeq:
            return false
        default:
            return true
        }
    }

    private static func priority(for kind: ObservanceKind) -> Int {
        switch kind {
        case .eidAlFitr, .eidAlAdha, .tashreeq:
            return 0
        case .ramadan:
            return 10
        case .qadaAssignable:
            return 20
        case .arafah:
            return 30
        case .ashura:
            return 31
        case .dhulHijjahFirstNine:
            return 32
        case .shawwalSixPotential:
            return 40
        case .whiteDays:
            return 50
        case .mondayThursday:
            return 60
        case .voluntaryGeneral:
            return 70
        case .tahajjudEligible:
            return 80
        case .ordinary:
            return 100
        }
    }

    private static func title(for kind: ObservanceKind) -> String {
        switch kind {
        case .ordinary:
            return "Ordinary day"
        case .ramadan:
            return "Ramadan"
        case .qadaAssignable:
            return "Qada"
        case .voluntaryGeneral:
            return "Voluntary fast"
        case .mondayThursday:
            return "Monday/Thursday"
        case .whiteDays:
            return "White Days"
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .dhulHijjahFirstNine:
            return "First 9 of Dhul Hijjah"
        case .shawwalSixPotential:
            return "Six of Shawwal"
        case .eidAlFitr:
            return "Eid al-Fitr"
        case .eidAlAdha:
            return "Eid al-Adha"
        case .tashreeq:
            return "Days of Tashreeq"
        case .tahajjudEligible:
            return "Tahajjud"
        }
    }

    private static func detail(for kind: ObservanceKind) -> String? {
        switch kind {
        case .ramadan:
            return "Auto-resolved as an obligatory fasting context."
        case .mondayThursday, .whiteDays, .arafah, .ashura, .dhulHijjahFirstNine, .shawwalSixPotential:
            return "Recommended opportunity; it is not a planned fast unless selected."
        case .eidAlFitr, .eidAlAdha, .tashreeq:
            return "Forbidden fasting day; do not treat as a normal fast plan."
        case .qadaAssignable:
            return "Counts toward qada only when selected and completed as qada."
        case .voluntaryGeneral:
            return "User-sourced fasting opportunity."
        case .tahajjudEligible:
            return "Optional night-wake purpose."
        case .ordinary:
            return nil
        }
    }
}

enum DayIntentionResolver {
    static func resolve(
        date: Date,
        dateKey: String,
        opportunities: [ObservanceOpportunity],
        tagResult: TagComputationResult,
        effectiveConfig: EffectiveDailyConfig,
        selectedPlan: MorningPlan,
        fastTagSelections: [String: FastIntentSelection],
        dateAssignments: [PlanDateAssignment],
        timeZone: TimeZone,
        overrides: DayIntentionOverrides = .empty
    ) -> ResolvedDayIntention {
        if effectiveConfig.skipDay || overrides.quietDateKeys.contains(dateKey) {
            return ResolvedDayIntention(
                kind: .quiet,
                source: effectiveConfig.skipDay ? .userDateOverride : .quietOverlay,
                selectedOpportunityIDs: [],
                fastIntent: nil,
                suppressesPrompts: true,
                explanation: "Quiet overlay suppresses prompts without deleting the day's meaning."
            )
        }

        if dateAssignments.contains(where: { $0.dateKey == dateKey && $0.planID == "qada-\(dateKey)" })
            || selectedPlan.kind == .qadaAssignment {
            let selection = FastIntentSelection(primaryIntent: .qadaMakeup, secondaryTags: [])
            return ResolvedDayIntention(
                kind: .fast,
                source: .userSelected,
                selectedOpportunityIDs: selectedOpportunityIDs(
                    for: selection,
                    opportunities: opportunities,
                    tagResult: tagResult
                ),
                fastIntent: selection,
                suppressesPrompts: false,
                explanation: "Qada is the primary intention for this morning."
            )
        }

        if let storedSelection = fastTagSelections[dateKey] {
            let normalized = FastIntentEngine.normalizedSelection(
                storedSelection,
                for: date,
                ruleset: .strict,
                timeZone: timeZone
            )
            if isFastIntention(normalized.primaryIntent) {
                return ResolvedDayIntention(
                    kind: .fast,
                    source: .migratedFastTagSelection,
                    selectedOpportunityIDs: selectedOpportunityIDs(
                        for: normalized,
                        opportunities: opportunities,
                        tagResult: tagResult
                    ),
                    fastIntent: normalized,
                    suppressesPrompts: false,
                    explanation: "Existing fast-tag selection is treated as the MVP day intention."
                )
            }
        }

        if hasOpportunity(.ramadan, in: opportunities), !hasForbiddenOpportunity(in: opportunities) {
            let selection = FastIntentSelection(primaryIntent: .ramadanObligatory, secondaryTags: [])
            return ResolvedDayIntention(
                kind: .fast,
                source: .autoRamadan,
                selectedOpportunityIDs: selectedOpportunityIDs(
                    for: selection,
                    opportunities: opportunities,
                    tagResult: tagResult
                ),
                fastIntent: selection,
                suppressesPrompts: false,
                explanation: "Ramadan resolves as an auto-obligatory fast context."
            )
        }

        if let overrideIntention = overrideIntention(
            dateKey: dateKey,
            opportunities: opportunities,
            tagResult: tagResult,
            effectiveConfig: effectiveConfig
        ) {
            return overrideIntention
        }

        if overrides.tahajjudDateKeys.contains(dateKey) {
            return ResolvedDayIntention(
                kind: .tahajjud,
                source: .userSelected,
                selectedOpportunityIDs: [],
                fastIntent: nil,
                suppressesPrompts: false,
                explanation: "Tahajjud is selected without adding fast completion pressure."
            )
        }

        return ResolvedDayIntention(
            kind: .defaultFajr,
            source: .defaultDailyPlan,
            selectedOpportunityIDs: [],
            fastIntent: nil,
            suppressesPrompts: false,
            explanation: "No active day intention is selected; the default Fajr plan applies."
        )
    }

    private static func isFastIntention(_ intent: FastPrimaryIntent) -> Bool {
        switch intent {
        case .ramadanObligatory, .qadaMakeup, .kaffarahExpiation, .vowNadhr, .voluntary:
            return true
        case .forbidden, .other:
            return false
        }
    }

    private static func overrideIntention(
        dateKey: String,
        opportunities: [ObservanceOpportunity],
        tagResult: TagComputationResult,
        effectiveConfig: EffectiveDailyConfig
    ) -> ResolvedDayIntention? {
        if effectiveConfig.earlyWakePurposeOverride == .tahajjud || effectiveConfig.tahajjudRefinement {
            return ResolvedDayIntention(
                kind: .tahajjud,
                source: .userDateOverride,
                selectedOpportunityIDs: [],
                fastIntent: nil,
                suppressesPrompts: false,
                explanation: "Tahajjud is selected for this morning without adding fast completion pressure."
            )
        }

        guard effectiveConfig.quickWakeModeOverride == .fast
            || effectiveConfig.earlyWakePurposeOverride == .fast
            || effectiveConfig.earlyWakePurposeOverride == .fastAndTahajjud
            || effectiveConfig.alarmDetailFastTypeOverride != nil
        else {
            return nil
        }

        let primaryIntent = effectiveConfig.alarmDetailFastTypeOverride?.primaryIntent ?? FastPrimaryIntent.voluntary
        let selection = FastIntentSelection(primaryIntent: primaryIntent, secondaryTags: [])
        return ResolvedDayIntention(
            kind: .fast,
            source: .userDateOverride,
            selectedOpportunityIDs: selectedOpportunityIDs(
                for: selection,
                opportunities: opportunities,
                tagResult: tagResult
            ),
            fastIntent: selection,
            suppressesPrompts: false,
            explanation: "A date-specific fast wake purpose is selected for this morning."
        )
    }

    private static func hasOpportunity(_ kind: ObservanceKind, in opportunities: [ObservanceOpportunity]) -> Bool {
        opportunities.contains { $0.kind == kind }
    }

    private static func hasForbiddenOpportunity(in opportunities: [ObservanceOpportunity]) -> Bool {
        opportunities.contains { $0.eligibility == .forbidden }
    }

    private static func selectedOpportunityIDs(
        for selection: FastIntentSelection,
        opportunities: [ObservanceOpportunity],
        tagResult: TagComputationResult
    ) -> Set<String> {
        switch selection.primaryIntent {
        case .ramadanObligatory:
            return Set(opportunities.filter { $0.kind == .ramadan }.map(\.id))
        case .qadaMakeup:
            return Set(opportunities.filter { $0.kind == .qadaAssignable }.map(\.id))
        case .voluntary:
            let selectedKinds = Set(selection.secondaryTags.map(ObservanceKind.init))
            let computedKinds = Set(tagResult.computedSecondaryTags.map(ObservanceKind.init))
            let compatibleKinds = selectedKinds.isEmpty ? computedKinds : selectedKinds
            let explicitIDs = opportunities
                .filter { compatibleKinds.contains($0.kind) || $0.kind == .voluntaryGeneral }
                .map(\.id)
            if !explicitIDs.isEmpty {
                return Set(explicitIDs)
            }

            let recommended = opportunities.filter { $0.eligibility == .recommended }
            if recommended.count == 1, let only = recommended.first {
                return [only.id]
            }
            return []
        case .kaffarahExpiation, .vowNadhr:
            return []
        case .forbidden, .other:
            return []
        }
    }
}

enum DayWakeClassificationResolver {
    static func resolve(
        intention: ResolvedDayIntention,
        selectedPlan: MorningPlan,
        wakeAnchor: WakeAnchor,
        wakeResolution: WakeResolutionResult
    ) -> DayWakeClassification {
        let kind: DayWakeClassificationKind
        let explanation: String

        if intention.kind == .quiet || !selectedPlan.wakeAlarmEnabled {
            kind = .disabled
            explanation = "Wake delivery is disabled for the resolved day purpose."
        } else if selectedPlan.wakeRule.state == .fixedWake || wakeAnchor.type == .clockTime {
            kind = .fixedClock
            explanation = "Wake is resolved from a fixed clock-time rule."
        } else if selectedPlan.kind == .explicitDateOverride {
            kind = .overridden
            explanation = "A date-specific override is shaping the wake rule."
        } else {
            switch wakeResolution.resolvedWakeState {
            case .preFajr:
                kind = .earlyPreFajr
                explanation = "Wake resolves before Fajr begins."
            case .inFajr:
                kind = .defaultInFajr
                explanation = "Wake resolves inside the supported Fajr window."
            case .postFajr:
                kind = .overridden
                explanation = "Wake resolves after the supported Fajr window begins."
            }
        }

        return DayWakeClassification(
            kind: kind,
            plannedWakeState: selectedPlan.wakeRule.state,
            resolvedWakeState: wakeResolution.resolvedWakeState,
            anchorType: wakeAnchor.type,
            explanation: explanation
        )
    }
}

enum DayRequiredActionResolver {
    static func resolve(
        intention: ResolvedDayIntention
    ) -> [DayRequiredAction] {
        switch intention.kind {
        case .quiet:
            return []
        case .defaultFajr:
            return [.fajrCheckIn]
        case .tahajjud:
            return [.fajrCheckIn, .tahajjudCheckIn]
        case .fast:
            var actions: [DayRequiredAction] = [.fajrCheckIn, .fastStatus, .fastCompletion]
            if intention.fastIntent?.primaryIntent == .qadaMakeup {
                actions.append(.qadaCompletionCredit)
            }
            return actions
        }
    }
}

enum ObservanceCreditResolver {
    static func resolve(
        dateKey: String,
        opportunities: [ObservanceOpportunity],
        intention: ResolvedDayIntention,
        completionRecords: [CompletionRecord],
        dailyCompletion: DailyCompletionSnapshot
    ) -> [ObservanceCredit] {
        var credits: [String: ObservanceCredit] = [:]
        let selectedIDs = intention.selectedOpportunityIDs
        let completedFast = dailyCompletion.fast.status == .completed
        let notCompletedFast = dailyCompletion.fast.status == .notCompleted
        let invalidForbiddenFast = hasForbiddenOpportunity(opportunities)
            && [.completed, .inProgress].contains(dailyCompletion.fast.status)

        for opportunity in opportunities where opportunity.kind != .ordinary {
            add(
                dateKey: dateKey,
                opportunityID: opportunity.id,
                kind: opportunity.kind,
                creditType: .opportunityAvailable,
                source: .opportunityResolver,
                explanation: opportunity.detail,
                to: &credits
            )

            if intention.kind == .quiet {
                add(
                    dateKey: dateKey,
                    opportunityID: opportunity.id,
                    kind: opportunity.kind,
                    creditType: .suppressedByQuiet,
                    source: .quietOverlay,
                    explanation: "Quiet overlay preserved the meaning while suppressing action pressure.",
                    to: &credits
                )
                continue
            }

            if intention.kind == .defaultFajr,
               opportunity.eligibility == .recommended,
               !completionRecords.contains(where: { $0.kind == .fast }) {
                add(
                    dateKey: dateKey,
                    opportunityID: opportunity.id,
                    kind: opportunity.kind,
                    creditType: .keptDefault,
                    source: .intentionResolver,
                    explanation: "The opportunity was available, but the user kept the default Fajr plan.",
                    to: &credits
                )
            }

            let isPlanned = selectedIDs.contains(opportunity.id)
                || (intention.fastIntent?.primaryIntent == .ramadanObligatory && opportunity.kind == .ramadan)
            guard isPlanned else { continue }

            add(
                dateKey: dateKey,
                opportunityID: opportunity.id,
                kind: opportunity.kind,
                creditType: .planned,
                source: .intentionResolver,
                explanation: intention.explanation,
                to: &credits
            )

            if completedFast, !invalidForbiddenFast {
                add(
                    dateKey: dateKey,
                    opportunityID: opportunity.id,
                    kind: opportunity.kind,
                    creditType: .completed,
                    source: .completionRecord,
                    explanation: "Completion matched the resolved planned observance.",
                    to: &credits
                )
            } else if notCompletedFast {
                add(
                    dateKey: dateKey,
                    opportunityID: opportunity.id,
                    kind: opportunity.kind,
                    creditType: .missedAfterPlanning,
                    source: .completionRecord,
                    explanation: "The fast was planned and then logged as not completed.",
                    to: &credits
                )
            }
        }

        if intention.fastIntent?.primaryIntent == .qadaMakeup {
            add(
                dateKey: dateKey,
                opportunityID: nil,
                kind: .qadaAssignable,
                creditType: .planned,
                source: .intentionResolver,
                explanation: "Qada is the primary fast intention.",
                to: &credits
            )
            if completedFast || dailyCompletion.qadaEffect.countsTowardQada {
                add(
                    dateKey: dateKey,
                    opportunityID: nil,
                    kind: .qadaAssignable,
                    creditType: .completed,
                    source: .qadaLedger,
                    explanation: dailyCompletion.qadaEffect.explanation,
                    to: &credits
                )
            } else if notCompletedFast {
                add(
                    dateKey: dateKey,
                    opportunityID: nil,
                    kind: .qadaAssignable,
                    creditType: .missedAfterPlanning,
                    source: .completionRecord,
                    explanation: "The qada fast was planned and then logged as not completed.",
                    to: &credits
                )
            }
        }

        if invalidForbiddenFast {
            for opportunity in opportunities where opportunity.eligibility == .forbidden {
                add(
                    dateKey: dateKey,
                    opportunityID: opportunity.id,
                    kind: opportunity.kind,
                    creditType: .invalidForbiddenFast,
                    source: .forbiddenPolicy,
                    explanation: "A fast was logged on a forbidden fasting date.",
                    to: &credits
                )
            }
        }

        return credits.values.sorted {
            if $0.dateKey == $1.dateKey {
                return $0.id < $1.id
            }
            return $0.dateKey < $1.dateKey
        }
    }

    private static func hasForbiddenOpportunity(_ opportunities: [ObservanceOpportunity]) -> Bool {
        opportunities.contains { $0.eligibility == .forbidden }
    }

    private static func add(
        dateKey: String,
        opportunityID: String?,
        kind: ObservanceKind,
        creditType: ObservanceCreditType,
        source: ObservanceCreditSource,
        explanation: String?,
        to credits: inout [String: ObservanceCredit]
    ) {
        let credit = ObservanceCredit(
            id: creditID(dateKey: dateKey, kind: kind, creditType: creditType),
            dateKey: dateKey,
            opportunityID: opportunityID,
            kind: kind,
            creditType: creditType,
            source: source,
            explanation: explanation
        )
        credits[credit.id] = credit
    }

    static func creditID(
        dateKey: String,
        kind: ObservanceKind,
        creditType: ObservanceCreditType
    ) -> String {
        "\(dateKey).credit.\(kind.rawValue).\(creditType.rawValue)"
    }
}

enum DayPurposeResolver {
    static func resolve(
        date: Date,
        dateKey: String,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        effectiveConfig: EffectiveDailyConfig,
        stateSnapshot: MorningStateSnapshot,
        selectedPlan: MorningPlan,
        wakeAnchor: WakeAnchor,
        wakeResolution: WakeResolutionResult,
        completionRecords: [CompletionRecord],
        dailyCompletion: DailyCompletionSnapshot
    ) -> ResolvedDayPurpose {
        let opportunities = ObservanceOpportunityResolver.resolve(
            date: date,
            dateKey: dateKey,
            provenances: provenances,
            tagResult: tagResult,
            timeZone: stateSnapshot.timeZone
        )
        let intention = DayIntentionResolver.resolve(
            date: date,
            dateKey: dateKey,
            opportunities: opportunities,
            tagResult: tagResult,
            effectiveConfig: effectiveConfig,
            selectedPlan: selectedPlan,
            fastTagSelections: stateSnapshot.fastTagSelections,
            dateAssignments: stateSnapshot.dateAssignments,
            timeZone: stateSnapshot.timeZone
        )
        let wakeClassification = DayWakeClassificationResolver.resolve(
            intention: intention,
            selectedPlan: selectedPlan,
            wakeAnchor: wakeAnchor,
            wakeResolution: wakeResolution
        )
        let requiredActions = DayRequiredActionResolver.resolve(intention: intention)
        let analyticsCredits = ObservanceCreditResolver.resolve(
            dateKey: dateKey,
            opportunities: opportunities,
            intention: intention,
            completionRecords: completionRecords,
            dailyCompletion: dailyCompletion
        )

        return ResolvedDayPurpose(
            dateKey: dateKey,
            opportunities: opportunities,
            intention: intention,
            wakeClassification: wakeClassification,
            requiredActions: requiredActions,
            analyticsCredits: analyticsCredits,
            explanation: DayPurposeExplanation(
                summary: explanationSummary(intention: intention, opportunities: opportunities),
                details: explanationDetails(
                    intention: intention,
                    opportunities: opportunities,
                    wakeClassification: wakeClassification
                )
            )
        )
    }

    private static func explanationSummary(
        intention: ResolvedDayIntention,
        opportunities: [ObservanceOpportunity]
    ) -> String {
        switch intention.kind {
        case .defaultFajr:
            if let first = opportunities.first(where: { $0.eligibility == .recommended }) {
                return "Usual Fajr wake with \(first.title) available."
            }
            return "Usual Fajr wake."
        case .fast:
            return intention.fastIntent?.primaryIntent.shortTitle ?? "Fast planned."
        case .tahajjud:
            return "Tahajjud wake planned."
        case .quiet:
            return "Quiet day."
        }
    }

    private static func explanationDetails(
        intention: ResolvedDayIntention,
        opportunities: [ObservanceOpportunity],
        wakeClassification: DayWakeClassification
    ) -> [String] {
        var details = [intention.explanation, wakeClassification.explanation]
        if !opportunities.isEmpty {
            details.append(
                "Opportunities: \(opportunities.map(\.title).joined(separator: ", "))."
            )
        }
        return details
    }
}

private extension ObservanceKind {
    init(_ tag: FastSecondaryVirtueTag) {
        switch tag {
        case .shawwalSix:
            self = .shawwalSixPotential
        case .arafah:
            self = .arafah
        case .ashura:
            self = .ashura
        case .whiteDays:
            self = .whiteDays
        case .mondayThursday:
            self = .mondayThursday
        case .dhulHijjahFirstNine:
            self = .dhulHijjahFirstNine
        }
    }
}
