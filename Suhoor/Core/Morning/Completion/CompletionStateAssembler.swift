import Foundation

enum CompletionStateAssembler {
    static func assemble(
        completionRecords: [CompletionRecord],
        qadaLedgerSnapshot: QadaLedgerSnapshot
    ) -> CompletionStateSnapshot {
        let grouped = Dictionary(grouping: completionRecords, by: \.dateKey)
            .mapValues { records in
                records.sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.kind.rawValue < rhs.kind.rawValue
                    }
                    return lhs.updatedAt > rhs.updatedAt
                }
            }

        return CompletionStateSnapshot(
            recordsByDateKey: grouped,
            qadaLedgerSnapshot: qadaLedgerSnapshot
        )
    }

    static func assemble(
        stateSnapshot: MorningStateSnapshot
    ) -> CompletionStateSnapshot {
        assemble(
            completionRecords: stateSnapshot.completionRecords,
            qadaLedgerSnapshot: stateSnapshot.qadaLedgerSnapshot
        )
    }
}
