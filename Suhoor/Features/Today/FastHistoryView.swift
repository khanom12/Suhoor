import SwiftUI

struct FastHistoryView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let days = 30

    var body: some View {
        let snapshot = scheduleManager.fastHistorySurfaceSnapshot(days: days)

        List {
            Section {
                if snapshot.rows.isEmpty {
                    Text(snapshot.emptyText)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.rows) { row in
                        HistoryRow(row: row) { intent in
                            scheduleManager.performCompletionEdit(intent)
                        }
                    }
                }
            } header: {
                Text(snapshot.summaryText)
            } footer: {
                Text(snapshot.footerText)
            }
        }
        .navigationTitle("Fast History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct HistoryRow: View {
        let row: FastHistoryRowSnapshot
        let onIntent: (CompletionEditIntent) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(row.gregorianText)
                            .font(AppTypography.cardTitle)
                        Text(row.hijriText)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                        Text(row.meaningText)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                        if let qadaEffectText = row.qadaEffectText {
                            Text(qadaEffectText)
                                .font(AppTypography.cardBody)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(row.statusText)
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(statusColor)
                }

                HStack(spacing: DesignTokens.spacingXS) {
                    statusButton(
                        title: "Completed",
                        isSelected: row.status == .completed,
                        tint: .green
                    ) {
                        onIntent(.setFastStatus(
                            dateKey: row.dateKey,
                            status: .completed,
                            intentSnapshot: row.intentSnapshot
                        ))
                    }

                    statusButton(
                        title: "Not completed",
                        isSelected: row.status == .notCompleted,
                        tint: .red
                    ) {
                        onIntent(.setFastStatus(
                            dateKey: row.dateKey,
                            status: .notCompleted,
                            intentSnapshot: row.intentSnapshot
                        ))
                    }

                    if row.canClear {
                        Button("Clear") {
                            onIntent(.clearFastStatus(dateKey: row.dateKey))
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
            }
            .padding(.vertical, DesignTokens.spacingXS)
        }

        private var statusColor: Color {
            switch row.status {
            case .completed:
                return .green
            case .notCompleted:
                return .red
            case .unknown, .inProgress, .notRequired:
                return .secondary
            }
        }

        @ViewBuilder
        private func statusButton(
            title: String,
            isSelected: Bool,
            tint: Color,
            action: @escaping () -> Void
        ) -> some View {
            if isSelected {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            } else {
                Button(title, action: action)
                    .buttonStyle(.bordered)
                    .tint(tint)
            }
        }
    }
}
