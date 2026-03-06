import SwiftUI

struct QadaCompanionView: View {
    @Environment(\.dismiss) private var dismiss

    let state: QadaExperienceState
    let onViewCurrentBatch: () -> Void
    let onPlanNextBatch: () -> Void
    let onAdjustTotal: () -> Void
    let onRecoverMissedDay: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                headerCard

                recoveryCard

                batchCard

                actionCard
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .navigationTitle("Qada")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var headerCard: some View {
        GlassCard(style: .header, tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(headerTitle)
                    .font(.title3.weight(.semibold))
                Text(headerSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var recoveryCard: some View {
        if case .needsRecovery(let snapshot) = state {
            GlassCard(tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.08) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("You missed a planned Qada fast.")
                        .font(.headline.weight(.semibold))
                    if let missedDate = snapshot.missedDate {
                        Text("Missed date: \(mediumDate(missedDate)). Move it to the next available date when you're ready.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Move it to the next available date when you're ready.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button("Recover missed day") {
                        onRecoverMissedDay()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DawnColor.accent)
                }
            }
        }
    }

    private var batchCard: some View {
        let snapshot = currentSnapshot

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                if let nextDate = snapshot?.nextPlannedDate {
                    summaryRow(title: "Next Qada", value: mediumDate(nextDate))
                } else {
                    summaryRow(title: "Next Qada", value: snapshot?.remainingBacklog == 0 ? "You’re caught up" : "Plan the next batch")
                }

                if let snapshot {
                    summaryRow(title: "This batch", value: snapshot.completedProgressText)
                    summaryRow(title: "Overall", value: snapshot.remainingText)
                } else {
                    Text("Plan the next small batch when you’re ready.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Button(primaryActionTitle) {
                    primaryAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(DawnColor.accent)

                if showsViewCurrentBatchSecondaryAction {
                    Button("View current batch") {
                        onViewCurrentBatch()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Adjust total") {
                    onAdjustTotal()
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
    }

    private var currentSnapshot: QadaBatchSnapshot? {
        switch state {
        case .needsSetup:
            return nil
        case .activeBatch(let snapshot), .batchCompleteNeedsNext(let snapshot), .needsRecovery(let snapshot):
            return snapshot
        }
    }

    private var headerTitle: String {
        switch state {
        case .needsSetup:
            return "Plan your Qada"
        case .activeBatch:
            return "Your Qada"
        case .batchCompleteNeedsNext(let snapshot):
            return snapshot.remainingBacklog == 0 ? "You’re all caught up" : "This batch is complete"
        case .needsRecovery:
            return "Your Qada"
        }
    }

    private var headerSubtitle: String {
        switch state {
        case .needsSetup:
            return "Build a small, realistic batch and keep going from there."
        case .activeBatch:
            return "Stay with this batch one day at a time."
        case .batchCompleteNeedsNext(let snapshot):
            if snapshot.remainingBacklog == 0 {
                return "Your Qada plan is complete for now."
            }
            return "Plan the next few fasts to keep your momentum going."
        case .needsRecovery:
            return "A small reset is enough. You do not need to start over."
        }
    }

    private var primaryActionTitle: String {
        switch state {
        case .needsSetup:
            return "Plan your Qada"
        case .activeBatch:
            return "View current batch"
        case .batchCompleteNeedsNext(let snapshot):
            return snapshot.remainingBacklog == 0 ? "View last batch" : "Plan next batch"
        case .needsRecovery:
            return "Recover missed day"
        }
    }

    private func primaryAction() {
        switch state {
        case .needsSetup:
            onPlanNextBatch()
        case .activeBatch:
            onViewCurrentBatch()
        case .batchCompleteNeedsNext(let snapshot):
            if snapshot.remainingBacklog == 0 {
                onViewCurrentBatch()
            } else {
                onPlanNextBatch()
            }
        case .needsRecovery:
            onRecoverMissedDay()
        }
    }

    private var showsViewCurrentBatchSecondaryAction: Bool {
        switch state {
        case .needsRecovery, .batchCompleteNeedsNext:
            return true
        case .needsSetup, .activeBatch:
            return false
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.footnote)
                .multilineTextAlignment(.trailing)
        }
    }

    private func mediumDate(_ date: Date) -> String {
        GregorianDateFormatter.shared.headerString(for: date)
    }
}
