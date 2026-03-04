import SwiftUI

struct TodayCountdownCard: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    private let contentSpacing = DesignTokens.dashboardCardInternalSpacing

    var body: some View {
        GlassCard(style: .header) {
            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                if let target = TodayCountdownEngine.target(
                    now: context.date,
                    snapshot: scheduleManager.activeWindowSnapshot,
                    timeZone: .current
                ) {
                    countdownContent(target: target, now: context.date)
                } else {
                    emptyStateContent
                }
            }
        }
    }

    @ViewBuilder
    private func countdownContent(target: TodayCountdownEngine.Target, now: Date) -> some View {
        let remaining = max(0, target.targetDate.timeIntervalSince(now))
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                Text(title(for: target.kind))
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                Text(Self.formattedCountdown(remaining: remaining))
                    .timeTextStyle()
                    .foregroundStyle(.primary)
                    .accessibilityLabel(accessibilityLabel(for: remaining, kind: target.kind))

                eventRow(for: target)
            }
        }
    }

    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text("Next Countdown")
                .font(DesignTokens.cardTitleFont)

            if needsLocationPermission {
                Text("Allow location access to calculate fasting times and countdowns.")
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                }
                .font(DesignTokens.cardMetaFont)
            } else if scheduleManager.activeWindowSnapshot.visibleDays.isEmpty {
                Text("No upcoming fast days are scheduled yet.")
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
                Button("Add Days") {
                    NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
                }
                .font(DesignTokens.cardMetaFont)
            } else {
                Text("Your schedule is still updating.")
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                }
                .font(DesignTokens.cardMetaFont)
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
            return "Time Until Fajr"
        case .maghrib:
            return "Time Until Maghrib"
        }
    }

    @ViewBuilder
    private func eventRow(for target: TodayCountdownEngine.Target) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Button {
                toggleAdhan(for: target)
            } label: {
                Image(systemName: adhanEnabled(for: target) ? "bell.fill" : "bell")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(adhanEnabled(for: target) ? iconTint(for: target.kind) : .secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(adhanControlTitle(for: target.kind))
            .accessibilityValue(adhanEnabled(for: target) ? "On" : "Off")

            Text("\(eventName(for: target.kind)) at \(TimeFormatters.timeFormatter.string(from: target.targetDate))")
                .font(DesignTokens.cardSubtitleFont)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
    }

    private var needsLocationPermission: Bool {
        guard let locationPermission = scheduleManager.permissionSnapshot.presentations[.location] else {
            return false
        }
        return locationPermission.state != .authorized
    }

    private func adhanControlTitle(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .fajr:
            return "Fajr Adhan"
        case .maghrib:
            return "Maghrib Adhan"
        }
    }

    private func adhanEnabled(for target: TodayCountdownEngine.Target) -> Bool {
        let day = target.day
        let override = alarmConfigStore.override(for: day.schedule.date, timeZone: .current)
        switch target.kind {
        case .fajr:
            return (override?.fajrSoundOverride ?? day.effectiveConfig.fajrSoundChoice) == .adhanSoft
        case .maghrib:
            return (override?.iftarDeliveryOverride ?? day.effectiveConfig.iftarDelivery).normalized().adhan
        }
    }

    private func toggleAdhan(for target: TodayCountdownEngine.Target) {
        let newValue = !adhanEnabled(for: target)
        let day = target.day
        alarmConfigStore.updateOverride(for: day.schedule.date, timeZone: .current) { override in
            switch target.kind {
            case .fajr:
                override.fajrSoundOverride = newValue ? .adhanSoft : .systemDefault
            case .maghrib:
                var delivery = (override.iftarDeliveryOverride ?? day.effectiveConfig.iftarDelivery).normalized()
                delivery.adhan = newValue
                delivery.alarm = false
                override.iftarDeliveryOverride = delivery.normalized()
            }
        }
        scheduleManager.requestRescheduleDay(day.schedule.date)
    }

    private func iconTint(for kind: TodayCountdownEngine.Target.Kind) -> Color {
        switch kind {
        case .fajr:
            return .orange
        case .maghrib:
            return .green
        }
    }

    private func eventName(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .fajr:
            return "Fajr"
        case .maghrib:
            return "Maghrib"
        }
    }
}
