import Foundation

enum CompletionMutationSource: String, Codable, CaseIterable, Sendable {
    case homeCard
    case historyEdit
    case notificationAction
    case launchNormalization
    case migration
    case sync
}

struct CompletionRepositorySnapshot: Sendable {
    let records: [CompletionRecord]
    let qadaLedgerSnapshot: QadaLedgerSnapshot
}

struct CompletionMutationResult: Sendable {
    let dateKey: String
    let prayerState: PrayerCompletionState
    let fastState: FastCompletionState
    let qadaEffect: QadaEffect?
    let updatedAt: Date
    let source: CompletionMutationSource
}

@MainActor
protocol CompletionRepository {
    @discardableResult
    func perform(
        _ intent: CompletionEditIntent,
        source: CompletionMutationSource,
        now: Date
    ) -> CompletionMutationResult

    func snapshot() -> CompletionRepositorySnapshot

    func normalizeStaleInProgress(todayKey: String, now: Date)
}

@MainActor
final class LegacyCompletionRepository: CompletionRepository {
    private let fajrLogStore: FajrLogStore
    private let fastLogStore: FastLogStore
    private let qadaBacklogStore: QadaBacklogStore

    init(
        fajrLogStore: FajrLogStore,
        fastLogStore: FastLogStore,
        qadaBacklogStore: QadaBacklogStore
    ) {
        self.fajrLogStore = fajrLogStore
        self.fastLogStore = fastLogStore
        self.qadaBacklogStore = qadaBacklogStore
    }

    @discardableResult
    func perform(
        _ intent: CompletionEditIntent,
        source: CompletionMutationSource,
        now: Date = Date()
    ) -> CompletionMutationResult {
        switch intent {
        case let .setPrayerStatus(dateKey, status):
            fajrLogStore.setStatus(fajrStatus(from: status), for: dateKey, now: now, source: source.rawValue)
            return CompletionMutationResult(
                dateKey: dateKey,
                prayerState: PrayerCompletionState(
                    status: status,
                    updatedAt: now,
                    source: source.rawValue
                ),
                fastState: fastCompletionState(for: dateKey),
                qadaEffect: nil,
                updatedAt: now,
                source: source
            )
        case let .clearPrayerStatus(dateKey):
            fajrLogStore.clear(for: dateKey)
            return CompletionMutationResult(
                dateKey: dateKey,
                prayerState: .empty,
                fastState: fastCompletionState(for: dateKey),
                qadaEffect: nil,
                updatedAt: now,
                source: source
            )
        case let .setFastStatus(dateKey, status, intentSnapshot):
            let result = persistFastStatus(
                dateKey: dateKey,
                status: fastLogStatus(from: status),
                intentSnapshot: intentSnapshot,
                source: source,
                now: now
            )
            return CompletionMutationResult(
                dateKey: dateKey,
                prayerState: prayerCompletionState(for: dateKey),
                fastState: result.fastState,
                qadaEffect: result.qadaEffect,
                updatedAt: now,
                source: source
            )
        case let .clearFastStatus(dateKey):
            fastLogStore.clear(for: dateKey)
            return CompletionMutationResult(
                dateKey: dateKey,
                prayerState: prayerCompletionState(for: dateKey),
                fastState: FastCompletionState(
                    status: .unknown,
                    intentSnapshot: nil,
                    updatedAt: nil,
                    source: nil
                ),
                qadaEffect: nil,
                updatedAt: now,
                source: source
            )
        }
    }

    func snapshot() -> CompletionRepositorySnapshot {
        CompletionRepositorySnapshot(
            records: completionRecords(),
            qadaLedgerSnapshot: qadaLedgerSnapshot()
        )
    }

    func normalizeStaleInProgress(todayKey: String, now: Date = Date()) {
        let staleKeys = fastLogStore.entriesByDateKey.keys.filter { key in
            guard let entry = fastLogStore.entriesByDateKey[key] else { return false }
            return entry.status == .inProgress && key < todayKey
        }

        guard !staleKeys.isEmpty else { return }

        for key in staleKeys.sorted() {
            let intentSnapshot = fastLogStore.entry(for: key)?.intentSnapshot
            _ = persistFastStatus(
                dateKey: key,
                status: .completed,
                intentSnapshot: intentSnapshot,
                source: .launchNormalization,
                now: now
            )
        }
    }

    private func persistFastStatus(
        dateKey: String,
        status: FastLogStatus,
        intentSnapshot: FastIntentSnapshot?,
        source: CompletionMutationSource,
        now: Date
    ) -> (fastState: FastCompletionState, qadaEffect: QadaEffect?) {
        guard status != .unknown else {
            fastLogStore.clear(for: dateKey)
            return (
                FastCompletionState(status: .unknown, intentSnapshot: nil, updatedAt: nil, source: nil),
                nil
            )
        }

        let existingIntent = fastLogStore.entry(for: dateKey)?.intentSnapshot
        let resolvedIntent = intentSnapshot ?? existingIntent
        let persistedEffect = persistedQadaEffect(
            for: dateKey,
            status: status,
            intentSnapshot: resolvedIntent
        )
        fastLogStore.setStatus(
            status,
            for: dateKey,
            intentSnapshot: resolvedIntent,
            now: now,
            qadaEffect: persistedEffect,
            source: source.rawValue
        )

        return (
            FastCompletionState(
                status: fastCompletionStatus(from: status),
                intentSnapshot: resolvedIntent,
                updatedAt: now,
                source: source.rawValue
            ),
            persistedEffect?.asQadaEffect
        )
    }

    private func persistedQadaEffect(
        for dateKey: String,
        status: FastLogStatus,
        intentSnapshot: FastIntentSnapshot?
    ) -> PersistedQadaEffect? {
        guard status == .completed,
              intentSnapshot?.primaryIntent == .qadaMakeup else {
            return nil
        }

        let qadaSnapshot = qadaProgressSnapshot(assumingAdditionalCompletedDateKey: dateKey)
        return PersistedQadaEffect(
            countsTowardQada: true,
            completedDelta: 1,
            remainingAfterEffect: qadaSnapshot.remaining,
            explanation: "Completed Qada fasts reduce what remains."
        )
    }

    private func prayerCompletionState(for dateKey: String) -> PrayerCompletionState {
        guard let entry = fajrLogStore.entry(for: dateKey) else {
            return .empty
        }

        return PrayerCompletionState(
            status: prayerCompletionStatus(from: entry.status),
            updatedAt: entry.updatedAt,
            source: entry.source
        )
    }

    private func fastCompletionState(for dateKey: String) -> FastCompletionState {
        guard let entry = fastLogStore.entry(for: dateKey) else {
            return FastCompletionState(
                status: .unknown,
                intentSnapshot: nil,
                updatedAt: nil,
                source: nil
            )
        }

        return FastCompletionState(
            status: fastCompletionStatus(from: entry.status),
            intentSnapshot: entry.intentSnapshot,
            updatedAt: entry.updatedAt,
            source: entry.source
        )
    }

    private func completionRecords() -> [CompletionRecord] {
        let fajrRecords = fajrLogStore.entriesByDateKey.values.map { entry in
            CompletionRecord(
                id: "fajr-\(entry.dateKey)",
                dateKey: entry.dateKey,
                kind: .fajr,
                status: completionStatus(from: entry.status),
                updatedAt: entry.updatedAt,
                source: entry.source ?? "fajrLog",
                metadata: [:]
            )
        }

        let fastRecords = fastLogStore.entriesByDateKey.values.map { entry in
            CompletionRecord(
                id: "fast-\(entry.dateKey)",
                dateKey: entry.dateKey,
                kind: .fast,
                status: completionStatus(from: entry.status),
                updatedAt: entry.updatedAt,
                source: entry.source ?? "fastLog",
                metadata: fastMetadata(for: entry)
            )
        }

        return (fajrRecords + fastRecords).sorted { lhs, rhs in
            if lhs.dateKey == rhs.dateKey {
                return lhs.kind.rawValue < rhs.kind.rawValue
            }
            return lhs.dateKey < rhs.dateKey
        }
    }

    private func fastMetadata(for entry: FastLogEntry) -> [String: String] {
        var metadata: [String: String] = [
            "primaryIntent": entry.intentSnapshot?.primaryIntent.rawValue ?? FastPrimaryIntent.other.rawValue,
            "legacyStatus": entry.status.rawValue,
        ]

        if let qadaEffect = entry.qadaEffect {
            metadata["qadaCountsToward"] = qadaEffect.countsTowardQada ? "true" : "false"
            metadata["qadaCompletedDelta"] = String(qadaEffect.completedDelta)
            if let remaining = qadaEffect.remainingAfterEffect {
                metadata["qadaRemainingAfterEffect"] = String(remaining)
            }
            if let explanation = qadaEffect.explanation {
                metadata["qadaExplanation"] = explanation
            }
        }

        return metadata
    }

    private func qadaLedgerSnapshot() -> QadaLedgerSnapshot {
        let progress = qadaProgressSnapshot()
        return QadaLedgerSnapshot(
            trackingStartDateKey: qadaBacklogStore.state.trackingStartDateKey,
            baselineOwed: progress.baselineOwed,
            completed: progress.completed,
            remaining: progress.remaining
        )
    }

    private func qadaProgressSnapshot(
        assumingAdditionalCompletedDateKey dateKey: String? = nil
    ) -> QadaProgressSnapshot {
        var entries = fastLogStore.entriesByDateKey

        if let dateKey {
            if var entry = entries[dateKey] {
                if entry.intentSnapshot?.primaryIntent == .qadaMakeup {
                    entry.status = .completed
                    entry.qadaEffect = nil
                    entries[dateKey] = entry
                }
            } else {
                entries[dateKey] = FastLogEntry(
                    dateKey: dateKey,
                    status: .completed,
                    updatedAt: Date(),
                    intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
                )
            }
        }

        return QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: entries
        )
    }

    private func completionStatus(from status: FajrCompletionStatus) -> CompletionStatus {
        switch status {
        case .completed:
            return .completed
        case .missed:
            return .missed
        case .unknown:
            return .unknown
        }
    }

    private func completionStatus(from status: FastLogStatus) -> CompletionStatus {
        switch status {
        case .completed:
            return .completed
        case .missed:
            return .missed
        case .inProgress, .unknown:
            return .unknown
        }
    }

    private func fajrStatus(from status: PrayerCompletionStatus) -> FajrCompletionStatus {
        switch status {
        case .unknown:
            return .unknown
        case .completed:
            return .completed
        case .missed:
            return .missed
        }
    }

    private func prayerCompletionStatus(from status: FajrCompletionStatus) -> PrayerCompletionStatus {
        switch status {
        case .unknown:
            return .unknown
        case .completed:
            return .completed
        case .missed:
            return .missed
        }
    }

    private func fastLogStatus(from status: FastCompletionStatus) -> FastLogStatus {
        switch status {
        case .notRequired, .unknown:
            return .unknown
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .notCompleted:
            return .missed
        }
    }

    private func fastCompletionStatus(from status: FastLogStatus) -> FastCompletionStatus {
        switch status {
        case .unknown:
            return .unknown
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .missed:
            return .notCompleted
        }
    }
}
