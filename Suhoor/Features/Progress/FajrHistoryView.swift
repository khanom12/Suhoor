import SwiftUI

struct FajrHistoryView: View {
    @EnvironmentObject private var fajrLogStore: FajrLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let days = 30

    var body: some View {
        let timeZone = TimeZone.current
        let calendar = historyCalendar(timeZone: timeZone)
        let today = calendar.startOfDay(for: Date())

        List {
            Section {
                ForEach(historyKeys(from: today, calendar: calendar, timeZone: timeZone), id: \.self) { dateKey in
                    let date = date(for: dateKey, timeZone: timeZone)
                    let schedule = date.flatMap { scheduleManager.schedule(for: $0) }
                    let status = fajrLogStore.status(for: dateKey)

                    HistoryRow(
                        dateKey: dateKey,
                        date: date,
                        schedule: schedule,
                        status: status
                    ) { newStatus in
                        fajrLogStore.setStatus(newStatus, for: dateKey)
                    } onClear: {
                        fajrLogStore.clear(for: dateKey)
                    }
                }
            } header: {
                Text("Last \(days) mornings")
            } footer: {
                Text("Tap a mark to log. Tap again to clear.")
            }
        }
        .navigationTitle("Fajr Completion")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyKeys(from today: Date, calendar: Calendar, timeZone: TimeZone) -> [String] {
        (0..<days).compactMap { offset in
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

    private func historyCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private struct HistoryRow: View {
        let dateKey: String
        let date: Date?
        let schedule: DaySchedule?
        let status: FajrCompletionStatus
        let onSetStatus: (FajrCompletionStatus) -> Void
        let onClear: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(gregorianLabel)
                        .font(DesignTokens.cardTitleFont)
                    Text(hijriLabel)
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                    if let schedule {
                        Text("Fajr \(TimeFormatters.timeFormatter.string(from: schedule.fajrDate))")
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: DesignTokens.spacingXS) {
                    statusButton(targetStatus: .completed)
                    statusButton(targetStatus: .missed)
                }
            }
            .contentShape(Rectangle())
        }

        @ViewBuilder
        private func statusButton(targetStatus: FajrCompletionStatus) -> some View {
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
                .accessibilityLabel("Clear \(targetStatus.title) for \(gregorianLabel)")
            } else {
                Button {
                    onSetStatus(targetStatus)
                } label: {
                    Image(systemName: iconName(for: targetStatus))
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(color(for: targetStatus))
                .accessibilityLabel("Mark \(targetStatus.title) for \(gregorianLabel)")
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

        private func color(for status: FajrCompletionStatus) -> Color {
            switch status {
            case .unknown:
                return .secondary
            case .completed:
                return .green
            case .missed:
                return .red
            }
        }

        private func iconName(for status: FajrCompletionStatus) -> String {
            switch status {
            case .completed:
                return "checkmark.circle"
            case .missed:
                return "xmark.circle"
            case .unknown:
                return "circle"
            }
        }

        private func filledIconName(for status: FajrCompletionStatus) -> String {
            switch status {
            case .completed:
                return "checkmark.circle.fill"
            case .missed:
                return "xmark.circle.fill"
            case .unknown:
                return "circle.fill"
            }
        }
    }
}
