import SwiftUI

struct TodayCountdownCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        GlassCard(style: .header) {
            let now = Date()
            if let target = TodayCountdownEngine.target(now: now, snapshot: scheduleManager.activeWindowSnapshot, timeZone: .current) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(for: target.kind))
                                .font(.headline.weight(.semibold))
                            Text(subtitle(for: target.kind))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(TimeFormatters.timeFormatter.string(from: target.targetDate))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    TimelineView(.periodic(from: now, by: 1.0)) { context in
                        let remaining = max(0, target.targetDate.timeIntervalSince(context.date))
                        Text(Self.formattedCountdown(remaining: remaining))
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .accessibilityLabel(accessibilityLabel(for: remaining, kind: target.kind))
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

    private func accessibilityLabel(for remaining: TimeInterval, kind: TodayCountdownEngine.Target.Kind) -> String {
        let totalSeconds = Int(remaining.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return "\(title(for: kind)). \(hours) hours, \(minutes) minutes, \(seconds) seconds remaining."
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

    private func title(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .fajr:
            return "Time to Fajr"
        case .iftar:
            return "Time to Iftar"
        }
    }

    private func subtitle(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .fajr:
            return "Next prayer time"
        case .iftar:
            return "Maghrib / Iftar"
        }
    }
}
