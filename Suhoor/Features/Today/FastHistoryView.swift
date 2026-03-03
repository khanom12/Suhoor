import SwiftUI

struct FastHistoryView: View {
    @EnvironmentObject private var fastLogStore: FastLogStore

    private let days = 30

    var body: some View {
        let timeZone = TimeZone.current
        let calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            return calendar
        }()
        let today = calendar.startOfDay(for: Date())

        List {
            Section {
                ForEach(historyKeys(from: today, calendar: calendar, timeZone: timeZone), id: \.self) { dateKey in
                    let status = fastLogStore.status(for: dateKey)
                    let entry = fastLogStore.entry(for: dateKey)
                    HistoryRow(
                        dateKey: dateKey,
                        status: status,
                        intent: entry?.intentSnapshot
                    ) { newStatus in
                        fastLogStore.setStatus(newStatus, for: dateKey, intentSnapshot: entry?.intentSnapshot)
                    } onClear: {
                        fastLogStore.clear(for: dateKey)
                    }
                }
            } header: {
                Text("Last \(days) days")
            } footer: {
                Text("Logging is optional. If you don’t log a day, it stays as “Not logged”.")
            }
        }
        .navigationTitle("Fast History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyKeys(from today: Date, calendar: Calendar, timeZone: TimeZone) -> [String] {
        (0..<days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        }
    }

    private struct HistoryRow: View {
        let dateKey: String
        let status: FastLogStatus
        let intent: FastIntentSnapshot?
        let onSetStatus: (FastLogStatus) -> Void
        let onClear: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateKey)
                        .font(DesignTokens.cardTitleFont)
                    if let intent {
                        Text(intent.primaryIntent.shortTitle)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("—")
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(status.title)
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(color(for: status))

                Menu {
                    Button("Mark Completed") { onSetStatus(.completed) }
                    Button("Mark Missed") { onSetStatus(.missed) }
                    Button("Clear Log") { onClear() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Edit \(dateKey)")
            }
            .contentShape(Rectangle())
        }

        private func color(for status: FastLogStatus) -> Color {
            switch status {
            case .unknown:
                return .secondary
            case .completed:
                return .green
            case .missed:
                return .red
            }
        }
    }
}
