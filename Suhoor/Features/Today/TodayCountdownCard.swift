import SwiftUI

struct TodayCountdownCard: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    private let headerSpacing = DesignTokens.dashboardCardHeaderSpacing
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
        VStack(alignment: .leading, spacing: contentSpacing) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(title(for: target.kind))
                        .font(DesignTokens.cardTitleFont)
                    if let dayContext = dayContext(for: target.day.schedule.date) {
                        Text(dayContext)
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, DesignTokens.spacingS)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                }
                Text(Self.formattedCountdown(remaining: remaining))
                    .timeTextStyle()
                    .foregroundStyle(.primary)
                    .accessibilityLabel(accessibilityLabel(for: remaining, kind: target.kind))

                Label(TimeFormatters.timeFormatter.string(from: target.targetDate), systemImage: "clock")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                ProgressView(value: countdownProgress(for: target, now: now))
                    .tint(progressTint(for: target.kind))
                    .progressViewStyle(.linear)
            }

            alarmToggleRow(for: target)
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

    @ViewBuilder
    private func alarmToggleRow(for target: TodayCountdownEngine.Target) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            Text(controlTitle(for: target.kind))
                .font(DesignTokens.cardMetaFont)

            Spacer()

            Toggle("", isOn: controlBinding(for: target))
                .labelsHidden()
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.spacingS)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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

    private func dayContext(for date: Date) -> String? {
        let label = scheduleManager.dayLabel(for: date)
        return label == "Today" ? nil : label
    }

    private var needsLocationPermission: Bool {
        guard let locationPermission = scheduleManager.permissionSnapshot.presentations[.location] else {
            return false
        }
        return locationPermission.state != .authorized
    }

    private func controlTitle(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .fajr:
            return "Fajr Adhan"
        case .maghrib:
            return "Maghrib Adhan"
        }
    }

    private func isControlEnabled(for target: TodayCountdownEngine.Target) -> Bool {
        let day = target.day
        let override = alarmConfigStore.override(for: day.schedule.date, timeZone: .current)
        switch target.kind {
        case .fajr:
            return override?.fajrEnabled ?? day.effectiveConfig.fajrEnabled
        case .maghrib:
            return override?.iftarEnabled ?? day.effectiveConfig.iftarEnabled
        }
    }

    private func controlBinding(for target: TodayCountdownEngine.Target) -> Binding<Bool> {
        Binding(
            get: { isControlEnabled(for: target) },
            set: { newValue in
                let day = target.day
                alarmConfigStore.updateOverride(for: day.schedule.date, timeZone: .current) { override in
                    switch target.kind {
                    case .fajr:
                        override.fajrEnabled = newValue
                    case .maghrib:
                        override.iftarEnabled = newValue
                    }
                    if newValue {
                        override.skipDay = false
                    }
                }
                scheduleManager.requestRescheduleDay(day.schedule.date)
            }
        )
    }

    private func countdownProgress(for target: TodayCountdownEngine.Target, now: Date) -> Double {
        let intervalStart: Date
        switch target.kind {
        case .fajr:
            intervalStart = target.targetDate.addingTimeInterval(-24 * 60 * 60)
        case .maghrib:
            intervalStart = target.day.schedule.fajrDate
        }
        let total = target.targetDate.timeIntervalSince(intervalStart)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(intervalStart)
        return min(max(elapsed / total, 0), 1)
    }

    private func progressTint(for kind: TodayCountdownEngine.Target.Kind) -> Color {
        switch kind {
        case .fajr:
            return .orange
        case .maghrib:
            return .green
        }
    }
}
