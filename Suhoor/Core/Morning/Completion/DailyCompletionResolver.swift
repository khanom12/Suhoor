import Foundation

enum DailyCompletionResolver {
    static func resolve(
        dateKey: String,
        resolvedDayContext: ResolvedDayContext,
        completionState: CompletionStateSnapshot
    ) -> DailyCompletionSnapshot {
        let records = completionState.records(for: dateKey)
        let prayerState = resolvePrayerState(from: records)
        let fastState = resolveFastState(
            from: records,
            resolvedDayContext: resolvedDayContext
        )
        let qadaEffect = resolveQadaEffect(
            from: records,
            resolvedDayContext: resolvedDayContext,
            fastState: fastState,
            qadaLedgerSnapshot: completionState.qadaLedgerSnapshot
        )
        let outstandingAction = resolveOutstandingAction(
            prayerState: prayerState,
            fastState: fastState
        )

        return DailyCompletionSnapshot(
            dateKey: dateKey,
            prayer: prayerState,
            fast: fastState,
            qadaEffect: qadaEffect,
            wakeSupport: .none,
            outstandingAction: outstandingAction,
            isMeaningfullyResolved: outstandingAction == nil
        )
    }

    static func fastIntentSnapshot(
        for resolvedDayContext: ResolvedDayContext
    ) -> FastIntentSnapshot? {
        let primaryIntent: FastPrimaryIntent
        switch resolvedDayContext.primaryContext {
        case .qadaFast:
            primaryIntent = .qadaMakeup
        case .fasting:
            if resolvedDayContext.supportingTags.contains(.ramadan) {
                primaryIntent = .ramadanObligatory
            } else if resolvedDayContext.supportingTags.contains(.kaffarah) {
                primaryIntent = .kaffarahExpiation
            } else if resolvedDayContext.supportingTags.contains(.vow) {
                primaryIntent = .vowNadhr
            } else {
                primaryIntent = .voluntary
            }
        case .sunnahFast, .suhoor:
            primaryIntent = .voluntary
        default:
            if resolvedDayContext.supportingTags.contains(.qada) {
                primaryIntent = .qadaMakeup
            } else if resolvedDayContext.supportingTags.contains(.ramadan) {
                primaryIntent = .ramadanObligatory
            } else if isFastingRelevant(resolvedDayContext: resolvedDayContext) {
                primaryIntent = .voluntary
            } else {
                primaryIntent = .other
            }
        }

        guard primaryIntent != .other else { return nil }

        return FastIntentSnapshot(
            primaryIntent: primaryIntent,
            secondaryTags: secondaryVirtueTags(from: resolvedDayContext.supportingTags)
        )
    }

    static func isFastingRelevant(
        resolvedDayContext: ResolvedDayContext
    ) -> Bool {
        if [.fasting, .qadaFast, .sunnahFast, .suhoor].contains(resolvedDayContext.primaryContext) {
            return true
        }

        let tags = Set(resolvedDayContext.supportingTags)
        return tags.intersection([
            .ramadan,
            .qada,
            .kaffarah,
            .vow,
            .voluntary,
            .shawwalSix,
            .arafah,
            .ashura,
            .whiteDays,
            .mondayThursday,
            .dhulHijjahFirstNine,
        ]).isEmpty == false
    }

    private static func resolvePrayerState(
        from records: [CompletionRecord]
    ) -> PrayerCompletionState {
        guard let record = records.first(where: { $0.kind == .fajr }) else {
            return .empty
        }

        let status: PrayerCompletionStatus
        switch record.status {
        case .completed:
            status = .completed
        case .missed:
            status = .missed
        case .unknown:
            status = .unknown
        }

        return PrayerCompletionState(
            status: status,
            updatedAt: record.updatedAt,
            source: record.source
        )
    }

    private static func resolveFastState(
        from records: [CompletionRecord],
        resolvedDayContext: ResolvedDayContext
    ) -> FastCompletionState {
        let fallbackIntent = fastIntentSnapshot(for: resolvedDayContext)
        guard let record = records.first(where: { $0.kind == .fast }) else {
            guard isFastingRelevant(resolvedDayContext: resolvedDayContext) else {
                return .notRequired
            }

            return FastCompletionState(
                status: .unknown,
                intentSnapshot: fallbackIntent,
                updatedAt: nil,
                source: nil
            )
        }

        let legacyStatus = record.metadata["legacyStatus"].flatMap(FastLogStatus.init(rawValue:))
        let status: FastCompletionStatus
        switch legacyStatus {
        case .inProgress:
            status = .inProgress
        case .completed:
            status = .completed
        case .missed:
            status = .notCompleted
        case .unknown, nil:
            switch record.status {
            case .completed:
                status = .completed
            case .missed:
                status = .notCompleted
            case .unknown:
                status = .unknown
            }
        }

        let intentSnapshot = recordIntentSnapshot(from: record) ?? fallbackIntent

        return FastCompletionState(
            status: status,
            intentSnapshot: intentSnapshot,
            updatedAt: record.updatedAt,
            source: record.source
        )
    }

    private static func resolveQadaEffect(
        from records: [CompletionRecord],
        resolvedDayContext: ResolvedDayContext,
        fastState: FastCompletionState,
        qadaLedgerSnapshot: QadaLedgerSnapshot
    ) -> QadaEffect {
        if let persisted = records.first(where: { $0.kind == .fast }).flatMap(recordQadaEffect(from:)) {
            return persisted
        }

        let isQada = fastState.intentSnapshot?.primaryIntent == .qadaMakeup
            || resolvedDayContext.primaryContext == .qadaFast
            || resolvedDayContext.supportingTags.contains(.qada)

        guard isQada, fastState.status == .completed else {
            return .none
        }

        return QadaEffect(
            countsTowardQada: true,
            completedDelta: 1,
            remainingAfterEffect: qadaLedgerSnapshot.remaining,
            explanation: "Completed Qada fasts reduce what remains."
        )
    }

    private nonisolated static func recordQadaEffect(
        from record: CompletionRecord
    ) -> QadaEffect? {
        guard let countsTowardRaw = record.metadata["qadaCountsToward"],
              let countsTowardQada = Bool(countsTowardRaw),
              let completedDeltaRaw = record.metadata["qadaCompletedDelta"],
              let completedDelta = Int(completedDeltaRaw) else {
            return nil
        }

        return QadaEffect(
            countsTowardQada: countsTowardQada,
            completedDelta: completedDelta,
            remainingAfterEffect: record.metadata["qadaRemainingAfterEffect"].flatMap(Int.init),
            explanation: record.metadata["qadaExplanation"]
        )
    }

    private static func resolveOutstandingAction(
        prayerState: PrayerCompletionState,
        fastState: FastCompletionState
    ) -> OutstandingCompletionAction? {
        if prayerState.status == .unknown {
            return .prayerCheckIn
        }

        switch fastState.status {
        case .unknown:
            return .fastingStatus
        case .inProgress:
            return .fastCompletion
        case .notRequired, .completed, .notCompleted:
            return nil
        }
    }

    private static func recordIntentSnapshot(
        from record: CompletionRecord
    ) -> FastIntentSnapshot? {
        guard let primaryRaw = record.metadata["primaryIntent"],
              let primaryIntent = FastPrimaryIntent(rawValue: primaryRaw) else {
            return nil
        }

        return FastIntentSnapshot(primaryIntent: primaryIntent, secondaryTags: [])
    }

    private static func secondaryVirtueTags(
        from tags: [DayTag]
    ) -> Set<FastSecondaryVirtueTag> {
        Set(tags.compactMap { tag in
            switch tag {
            case .shawwalSix:
                return .shawwalSix
            case .arafah:
                return .arafah
            case .ashura:
                return .ashura
            case .whiteDays:
                return .whiteDays
            case .mondayThursday:
                return .mondayThursday
            case .dhulHijjahFirstNine:
                return .dhulHijjahFirstNine
            default:
                return nil
            }
        })
    }
}
