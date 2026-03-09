import Foundation

struct HomeSurfaceSnapshot: Equatable, Sendable {
    let gregorianText: String
    let hijriText: String
    let dayLabel: String?
    let primaryContextTitle: String?
    let secondaryContextTitles: [String]
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
    let wakeRelation: String
    let reminder: String
    let followUp: String
    let fajrNotice: String
    let fastingDaySupport: String
    let compatibilityNote: String?
}

struct PlansSurfaceSnapshot: Equatable, Sendable {
    let defaultMorningPlanSummary: DefaultMorningPlanSurfaceSummary
    let configuredPlansSnapshot: ConfiguredPlansSnapshot
    let qadaProgress: QadaProgressSnapshot
}

struct ProgressSurfaceSnapshot: Equatable, Sendable {
    let fajrTodaySummary: String
    let fajrSummary: String
    let fastTodaySummary: String
    let fastSummary: String
    let qadaProgress: QadaProgressSnapshot
    let wakeProgress: WakeProgressSnapshot
}

enum ProductSurfaceSnapshots {
    static func defaultMorningPlanSummary(
        defaults: DefaultAlarmConfig,
        settings: AppSettings
    ) -> DefaultMorningPlanSurfaceSummary {
        let wakeRelation: String
        switch defaults.defaultSuhoorTimeMode {
        case .relativeToFajrMinusMinutes:
            wakeRelation = "\(defaults.defaultSuhoorOffsetMinutes) min before Fajr"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultSuhoorOffsetMinutes)
            wakeRelation = "\(timeText) fixed wake (compatibility)"
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
                ? "Reminder \(timeText) fixed"
                : "Reminder off"
        }

        let followUpSummary = settings.snoozeEnabled
            ? "\(settings.snoozeMinutes) min after wake"
            : "Off"

        return DefaultMorningPlanSurfaceSummary(
            wakeRelation: wakeRelation,
            reminder: reminderSummary,
            followUp: followUpSummary,
            fajrNotice: defaults.fajrEnabledDefault ? "On" : "Off",
            fastingDaySupport: defaults.iftarEnabledDefault ? "Iftar support on" : "Wake-only support",
            compatibilityNote: defaults.defaultSuhoorTimeMode == .fixedTime ? "Using fixed-time compatibility." : nil
        )
    }

}
