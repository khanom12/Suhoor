import SwiftUI

struct FastHistoryView: View {
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let days = 30

    var body: some View {
        let _ = scheduleManager.hijriAdjustmentChanges.count
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
                    let date = date(for: dateKey, timeZone: timeZone)
                    HistoryRow(
                        dateKey: dateKey,
                        date: date,
                        status: status,
                        intent: entry?.intentSnapshot
                    ) { newStatus in
                        fastLogStore.setStatus(newStatus, for: dateKey, intentSnapshot: entry?.intentSnapshot)
                    } onClear: {
                        fastLogStore.clear(for: dateKey)
                    }
                }
            } header: {
                Text("Past \(days) days")
            } footer: {
                Text("Tap an icon to log. Tap again to clear.")
            }
        }
        .navigationTitle("Fast History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyKeys(from today: Date, calendar: Calendar, timeZone: TimeZone) -> [String] {
        (1...days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        }
    }

    private func date(for dateKey: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateKey)
    }

    private struct HistoryRow: View {
        let dateKey: String
        let date: Date?
        let status: FastLogStatus
        let intent: FastIntentSnapshot?
        let onSetStatus: (FastLogStatus) -> Void
        let onClear: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(gregorianLabel)
                        .font(DesignTokens.cardTitleFont)
                    Text(hijriLabel)
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                    if let tagSummary {
                        Text(tagSummary)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: DesignTokens.spacingXS) {
                    historyStatusButton(targetStatus: .completed)
                    historyStatusButton(targetStatus: .missed)
                }
            }
            .contentShape(Rectangle())
        }

        @ViewBuilder
        private func historyStatusButton(targetStatus: FastLogStatus) -> some View {
            let isSelected = status == targetStatus
            if isSelected {
                Button {
                    onClear()
                } label: {
                    Image(systemName: filledIconName(for: targetStatus))
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(color(for: targetStatus))
                .accessibilityLabel("Clear \(title(for: targetStatus)) for \(gregorianLabel)")
            } else {
                Button {
                    onSetStatus(targetStatus)
                } label: {
                    Image(systemName: iconName(for: targetStatus))
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(color(for: targetStatus))
                .accessibilityLabel("Mark \(title(for: targetStatus)) for \(gregorianLabel)")
            }
        }

        private var gregorianLabel: String {
            guard let date else { return dateKey }
            return GregorianDateFormatter.shared.cardString(for: date)
        }

        private var hijriLabel: String {
            guard let date else { return "Hijri date unavailable" }
            return HijriDateFormatter.shared.shortString(from: date)
        }

        private var tagSummary: String? {
            guard let intent else { return nil }
            if intent.primaryIntent != .other {
                return intent.primaryIntent.shortTitle
            }
            return FastIntentEngine.displaySecondaryTags(intent.secondaryTags).first?.shortTitle
        }

        private func color(for status: FastLogStatus) -> Color {
            switch status {
            case .unknown:
                return .secondary
            case .inProgress:
                return .orange
            case .completed:
                return .green
            case .missed:
                return .red
            }
        }

        private func iconName(for status: FastLogStatus) -> String {
            switch status {
            case .completed:
                return "checkmark.circle"
            case .missed:
                return "xmark.circle"
            case .unknown, .inProgress:
                return "circle"
            }
        }

        private func filledIconName(for status: FastLogStatus) -> String {
            switch status {
            case .completed:
                return "checkmark.circle.fill"
            case .missed:
                return "xmark.circle.fill"
            case .unknown, .inProgress:
                return "circle.fill"
            }
        }

        private func title(for status: FastLogStatus) -> String {
            switch status {
            case .completed:
                return "Completed"
            case .missed:
                return "Missed"
            case .unknown:
                return "Not logged"
            case .inProgress:
                return "In progress"
            }
        }
    }
}
