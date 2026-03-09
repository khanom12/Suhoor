import SwiftUI

struct FajrHistoryView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let days = 30

    var body: some View {
        let snapshot = scheduleManager.fajrHistorySurfaceSnapshot(days: days)

        List {
            Section {
                if snapshot.rows.isEmpty {
                    Text(snapshot.emptyText)
                        .font(.footnote)
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
        .navigationTitle("Fajr History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct HistoryRow: View {
        let row: FajrHistoryRowSnapshot
        let onIntent: (CompletionEditIntent) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(row.gregorianText)
                            .font(DesignTokens.cardTitleFont)
                        Text(row.hijriText)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                        if let fajrTimeText = row.fajrTimeText {
                            Text("Fajr \(fajrTimeText)")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(row.statusText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                HStack(spacing: DesignTokens.spacingXS) {
                    statusButton(
                        title: "Fajr completed",
                        isSelected: row.status == .completed,
                        tint: .green
                    ) {
                        onIntent(.setPrayerStatus(dateKey: row.dateKey, status: .completed))
                    }

                    statusButton(
                        title: "Not prayed",
                        isSelected: row.status == .missed,
                        tint: .red
                    ) {
                        onIntent(.setPrayerStatus(dateKey: row.dateKey, status: .missed))
                    }

                    if row.canClear {
                        Button("Clear") {
                            onIntent(.clearPrayerStatus(dateKey: row.dateKey))
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
            case .missed:
                return .red
            case .unknown:
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
