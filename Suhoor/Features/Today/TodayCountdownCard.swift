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
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: headerSpacing) {
                    Text(title(for: target.kind))
                        .font(DesignTokens.cardTitleFont)
                    Text(subtitle(for: target.kind))
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: headerSpacing) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(TimeFormatters.timeFormatter.string(from: target.targetDate))
                        .font(DesignTokens.cardMetaFont)
                        .foregroundStyle(.secondary)
                    if let dayContext = dayContext(for: target.day.schedule.date) {
                        Text(dayContext)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                let remaining = max(0, target.targetDate.timeIntervalSince(now))
                Text(Self.formattedCountdown(remaining: remaining))
                    .timeTextStyle()
                    .foregroundStyle(.primary)
                    .accessibilityLabel(accessibilityLabel(for: remaining, kind: target.kind))

                Text(contextLine(for: target.kind))
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
            }

            alarmToggleRow(for: target, now: now)
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
    private func alarmToggleRow(for target: TodayCountdownEngine.Target, now: Date) -> some View {
        let controlKind = controlKind(for: target, now: now)
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: 4) {
                Text(controlTitle(for: controlKind))
                    .font(DesignTokens.cardMetaFont)
                Text(controlSubtitle(for: controlKind, isOn: isControlEnabled(controlKind, for: target.day)))
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: controlBinding(for: controlKind, day: target.day))
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
        case .suhoor:
            return "Time to Suhoor"
        case .fajr:
            return "Time to Fajr"
        case .iftar:
            return "Time to Iftar"
        }
    }

    private func subtitle(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .suhoor:
            return "Wake up for Suhoor"
        case .fajr:
            return "Fasting begins"
        case .iftar:
            return "Maghrib / Iftar"
        }
    }

    private func contextLine(for kind: TodayCountdownEngine.Target.Kind) -> String {
        switch kind {
        case .suhoor:
            return "Suhoor ends at Fajr."
        case .fajr:
            return "Your next fasting boundary is Fajr."
        case .iftar:
            return "Your next fasting boundary is Iftar."
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

    private func controlKind(for target: TodayCountdownEngine.Target, now: Date) -> CountdownAlarmControlKind {
        switch target.kind {
        case .suhoor:
            return .suhoor
        case .fajr:
            return now < target.day.schedule.wakeDate ? .suhoor : .fajr
        case .iftar:
            return .iftar
        }
    }

    private func controlTitle(for kind: CountdownAlarmControlKind) -> String {
        switch kind {
        case .suhoor:
            return "Suhoor Alarm"
        case .fajr:
            return "Fajr Adhan"
        case .iftar:
            return "Iftar Alert"
        }
    }

    private func controlSubtitle(for kind: CountdownAlarmControlKind, isOn: Bool) -> String {
        switch kind {
        case .suhoor:
            return isOn ? "On for this day. Turn off to count down to Fajr instead." : "Off for this day. Turn on for an earlier wake-up."
        case .fajr:
            return isOn ? "On for this day." : "Off for this day."
        case .iftar:
            return isOn ? "On for this day." : "Off for this day."
        }
    }

    private func isControlEnabled(_ kind: CountdownAlarmControlKind, for day: ActiveAlarmDay) -> Bool {
        let override = alarmConfigStore.override(for: day.schedule.date, timeZone: .current)
        switch kind {
        case .suhoor:
            return override?.suhoorEnabled ?? day.effectiveConfig.suhoorEnabled
        case .fajr:
            return override?.fajrEnabled ?? day.effectiveConfig.fajrEnabled
        case .iftar:
            return override?.iftarEnabled ?? day.effectiveConfig.iftarEnabled
        }
    }

    private func controlBinding(for kind: CountdownAlarmControlKind, day: ActiveAlarmDay) -> Binding<Bool> {
        Binding(
            get: { isControlEnabled(kind, for: day) },
            set: { newValue in
                alarmConfigStore.updateOverride(for: day.schedule.date, timeZone: .current) { override in
                    switch kind {
                    case .suhoor:
                        override.suhoorEnabled = newValue
                    case .fajr:
                        override.fajrEnabled = newValue
                    case .iftar:
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
}

private enum CountdownAlarmControlKind {
    case suhoor
    case fajr
    case iftar
}
