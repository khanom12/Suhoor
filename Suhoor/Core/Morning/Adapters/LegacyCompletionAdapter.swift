import Foundation

struct LegacyCompletionSnapshot: Sendable {
    let records: [CompletionRecord]
    let qadaLedgerSnapshot: QadaLedgerSnapshot
}

enum LegacyCompletionAdapter {
    static func records(
        fajrEntries: [String: FajrLogEntry],
        fastEntries: [String: FastLogEntry],
        qadaBacklogState: QadaBacklogState
    ) -> LegacyCompletionSnapshot {
        let fajrRecords = fajrEntries.values.map { entry in
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

        let fastRecords = fastEntries.values.map { entry in
            CompletionRecord(
                id: "fast-\(entry.dateKey)",
                dateKey: entry.dateKey,
                kind: .fast,
                status: completionStatus(from: entry.status),
                updatedAt: entry.updatedAt,
                source: entry.source ?? "fastLog",
                metadata: metadata(for: entry)
            )
        }

        let qadaProgress = QadaProgressEngine.snapshot(
            state: qadaBacklogState,
            logEntries: fastEntries
        )

        return LegacyCompletionSnapshot(
            records: (fajrRecords + fastRecords).sorted { lhs, rhs in
                if lhs.dateKey == rhs.dateKey {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.dateKey < rhs.dateKey
            },
            qadaLedgerSnapshot: QadaLedgerSnapshot(
                trackingStartDateKey: qadaBacklogState.trackingStartDateKey,
                baselineOwed: qadaProgress.baselineOwed,
                completed: qadaProgress.completed,
                remaining: qadaProgress.remaining
            )
        )
    }

    private static func completionStatus(from status: FajrCompletionStatus) -> CompletionStatus {
        switch status {
        case .completed:
            return .completed
        case .missed:
            return .missed
        case .unknown:
            return .unknown
        }
    }

    private static func completionStatus(from status: FastLogStatus) -> CompletionStatus {
        switch status {
        case .completed:
            return .completed
        case .missed:
            return .missed
        case .inProgress, .unknown:
            return .unknown
        }
    }

    private static func metadata(for entry: FastLogEntry) -> [String: String] {
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
}
