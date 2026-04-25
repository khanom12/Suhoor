import Foundation

enum CompletionSnapshotResolver {
    static func resolve(
        for dateKey: String,
        completionRecords: [CompletionRecord]
    ) -> [CompletionRecord] {
        completionRecords
            .filter { $0.dateKey == dateKey }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
