import SwiftUI

struct TodayCountdownCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        GlassCard(style: .header) {
            let now = Date()
            if let target = countdownTarget(now: now) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.title)
                                .font(.headline.weight(.semibold))
                            Text(target.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(target.targetTimeText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    TimelineView(.periodic(from: now, by: 1.0)) { context in
                        let remaining = max(0, target.targetDate.timeIntervalSince(context.date))
                        Text(Self.formattedCountdown(remaining: remaining))
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .accessibilityLabel(accessibilityLabel(for: remaining, target: target))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Countdown")
                        .font(.headline.weight(.semibold))
                    Text("Enable location and permissions to calculate accurate prayer times.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Settings") {
                        NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                    }
                    .font(.footnote.weight(.semibold))
                    .tint(DawnColor.accent)
                }
            }
        }
    }

    private func countdownTarget(now: Date) -> CountdownTarget? {
        let snapshot = scheduleManager.activeWindowSnapshot
        guard snapshot.visibleDays.isEmpty == false else { return nil }

        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: now)
        let todayKey = DateHelpers.dayIdentifier(for: startOfToday, timeZone: timeZone)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let tomorrowKey = DateHelpers.dayIdentifier(for: tomorrow, timeZone: timeZone)

        guard let today = snapshot.byDateKey[todayKey]?.schedule else { return nil }

        let iftarOrMaghrib = today.iftarDate ?? today.maghribDate
        if now < today.fajrDate {
            return CountdownTarget(kind: .fajr, targetDate: today.fajrDate)
        }
        if now < iftarOrMaghrib {
            return CountdownTarget(kind: .iftar, targetDate: iftarOrMaghrib)
        }

        guard let tomorrowSchedule = snapshot.byDateKey[tomorrowKey]?.schedule else { return nil }
        return CountdownTarget(kind: .fajr, targetDate: tomorrowSchedule.fajrDate)
    }

    private func accessibilityLabel(for remaining: TimeInterval, target: CountdownTarget) -> String {
        let totalSeconds = Int(remaining.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return "\(target.title). \(hours) hours, \(minutes) minutes, \(seconds) seconds remaining."
    }

    private static func formattedCountdown(remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remaining.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private struct CountdownTarget: Equatable {
        enum Kind: String, Equatable {
            case fajr
            case iftar
        }

        let kind: Kind
        let targetDate: Date

        var title: String {
            switch kind {
            case .fajr:
                return "Time to Fajr"
            case .iftar:
                return "Time to Iftar"
            }
        }

        var subtitle: String {
            switch kind {
            case .fajr:
                return "Next prayer time"
            case .iftar:
                return "Maghrib / Iftar"
            }
        }

        var targetTimeText: String {
            TimeFormatters.timeFormatter.string(from: targetDate)
        }
    }
}

