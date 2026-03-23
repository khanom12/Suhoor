import Foundation

struct HomeSurfaceSnapshot: Equatable, Sendable {
    let gregorianText: String
    let hijriText: String
    let heroLabel: String?
    let heroSubline: String?
    let nextWakeEventSummary: NextWakeEventSummary?
    let supportDecision: HomeSupportDecision?

    var supportCard: HomeSupportCardPresentation? {
        supportDecision?.presentation
    }
}

struct WakeSurfaceSnapshot: Equatable, Sendable {
    let visibleDays: [ActiveAlarmDay]
    let nextWakeEventSummary: NextWakeEventSummary?
    let overrideDateKeys: Set<String>
}

struct DefaultMorningPlanSurfaceSummary: Equatable, Sendable {
    let wakeLead: String
    let extraWakeBuffer: String
    let reminders: String
    let prayerTimes: String
    let tahajjudBehavior: String?
}

struct PlansSurfaceSnapshot: Equatable, Sendable {
    let defaultMorningPlanSummary: DefaultMorningPlanSurfaceSummary
    let configuredPlansSnapshot: ConfiguredPlansSnapshot
    let qadaProgress: QadaProgressSnapshot
}

struct ProgressSurfaceSnapshot: Equatable, Sendable {
    let headlineText: String?
    let fastSectionTitle: String
    let fajrTodaySummary: String
    let fajrSummary: String
    let fastTodaySummary: String
    let fastSummary: String
    let qadaProgress: QadaProgressSnapshot
    let wakeProgress: WakeProgressSnapshot

    static let empty = ProgressSurfaceSnapshot(
        headlineText: nil,
        fastSectionTitle: "Fasts",
        fajrTodaySummary: "Not logged",
        fajrSummary: "No logged mornings yet",
        fastTodaySummary: "Not logged",
        fastSummary: "No logged fasts yet",
        qadaProgress: QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0),
        wakeProgress: .empty
    )
}

enum ProductSurfaceSnapshots {
    static func defaultMorningPlanSummary(
        defaults: DefaultAlarmConfig,
        settings: AppSettings
    ) -> DefaultMorningPlanSurfaceSummary {
        let wakeLead: String
        switch defaults.defaultWakeState {
        case .preFajr:
            wakeLead = "\(defaults.defaultWakeDeltaMinutes) min before Fajr"
        case .inFajr:
            if defaults.normalizedDefaultWakeAnchorType == .fajrEnd {
                wakeLead = "\(defaults.defaultWakeDeltaMinutes) min before Fajr ends"
            } else {
                wakeLead = "\(defaults.defaultWakeDeltaMinutes) min after Fajr starts"
            }
        }

        let extraWakeBuffer: String
        if let latestWakeCap = defaults.defaultLatestWakeCapMinutesFromMidnight {
            extraWakeBuffer = "Cap at \(SettingsSummaryFormatter.timeText(minutesFromMidnight: latestWakeCap))"
        } else if settings.snoozeEnabled {
            extraWakeBuffer = "\(settings.snoozeMinutes) min follow-up"
        } else {
            extraWakeBuffer = "Off"
        }

        let reminderSummary: String
        switch defaults.defaultReminderTimeMode {
        case .beforeFajr:
            reminderSummary = defaults.reminderEnabledDefault
                ? "Reminder \(defaults.defaultReminderMinutesBeforeFajr) min before Fajr"
                : "Reminder off"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultReminderFixedTimeMinutes)
            reminderSummary = defaults.reminderEnabledDefault
                ? "Reminder at \(timeText)"
                : "Reminder off"
        }

        let prayerTimes = defaults.fajrEnabledDefault
            ? "Fajr adhan on"
            : "Fajr adhan off"

        return DefaultMorningPlanSurfaceSummary(
            wakeLead: wakeLead,
            extraWakeBuffer: extraWakeBuffer,
            reminders: reminderSummary,
            prayerTimes: prayerTimes,
            tahajjudBehavior: "Reserve \(settings.clampedReserveBeforeEndMinutes) min before Fajr ends"
        )
    }

}
