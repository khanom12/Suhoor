import Foundation

struct DeliveryRepairResult: Equatable, Sendable {
    let cancelledUnexpected: Int
    let rescheduledMissing: Int
    let rescheduledMismatched: Int
    let leftUnchanged: Int
    let verificationUnavailable: Int
    let failed: Int

    static let empty = DeliveryRepairResult(
        cancelledUnexpected: 0,
        rescheduledMissing: 0,
        rescheduledMismatched: 0,
        leftUnchanged: 0,
        verificationUnavailable: 0,
        failed: 0
    )

    var repairedCount: Int {
        cancelledUnexpected + rescheduledMissing + rescheduledMismatched
    }

    var hasWork: Bool {
        repairedCount > 0 || verificationUnavailable > 0 || failed > 0
    }

    var summaryText: String {
        guard hasWork else { return "No repair needed" }
        var parts: [String] = []
        if cancelledUnexpected > 0 {
            parts.append("Cancelled stale \(cancelledUnexpected)")
        }
        if rescheduledMissing > 0 {
            parts.append("Rescheduled missing \(rescheduledMissing)")
        }
        if rescheduledMismatched > 0 {
            parts.append("Replaced mismatched \(rescheduledMismatched)")
        }
        if verificationUnavailable > 0 {
            parts.append("Verification limited \(verificationUnavailable)")
        }
        if failed > 0 {
            parts.append("Failed \(failed)")
        }
        return parts.joined(separator: " · ")
    }

    var diagnosticsText: String {
        [
            "Delivery repair: \(summaryText)",
            "Cancelled stale: \(cancelledUnexpected)",
            "Rescheduled missing: \(rescheduledMissing)",
            "Replaced mismatched: \(rescheduledMismatched)",
            "Left unchanged: \(leftUnchanged)",
            "Verification limited: \(verificationUnavailable)",
            "Failed: \(failed)",
        ].joined(separator: "\n")
    }
}

enum DeliveryRepairCoordinator {
    static func expectedRecords(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date
    ) -> [ExpectedDeliveryRecord] {
        let plan = DeliveryReconciliation.plan(
            snapshot: snapshot,
            settings: settings,
            mode: mode,
            now: now
        )
        return plan.expectedDeliveries.map { delivery in
            ExpectedDeliveryRecord(
                delivery: delivery,
                wakeSessionID: wakeSessionID(for: delivery, in: snapshot),
                generatedAt: now
            )
        }
    }

    static func wakeSessionID(
        for delivery: ExpectedAlarmDelivery,
        in snapshot: ActiveAlarmWindowSnapshot
    ) -> String? {
        snapshot.byDateKey[delivery.dateKey]?
            .scheduledEvents
            .first { $0.id == delivery.eventID }?
            .wakeSessionID
    }

    static func verificationUnavailableCount(in report: DeliveryReconciliationReport) -> Int {
        report.issues.filter { $0.category == .verificationUnavailable }.count
    }
}

