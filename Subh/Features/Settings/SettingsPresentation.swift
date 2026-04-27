import Foundation

struct SettingsSummaryFormatter {
    private static let expectedPermissionCount = AppPermissionKind.allCases.count

    static func defaultAlarmsSummary(config: DefaultAlarmConfig) -> String {
        let wakeSummary = ProductSurfacePresentation.defaultWakeTimingText(for: config)
        let cueSummary = config.fastingReminderEnabledDefault
            ? "Fasting reminder on"
            : "Fasting reminder off"

        var parts = [wakeSummary, cueSummary]
        if let latestCap = config.defaultLatestWakeCapMinutesFromMidnight {
            parts.append("Latest wake \(timeText(minutesFromMidnight: latestCap))")
        }
        return parts.joined(separator: " · ")
    }

    static func locationSummary(settings: AppSettings, locationService: LocationService) -> String {
        switch settings.locationMode {
        case .auto:
            let city = effectiveLocationName(settings: settings, locationService: locationService)
                ?? Strings.SettingsSummary.locationWaiting
            return [Strings.SettingsSummary.locationAutomatic, city].joined(separator: " · ")
        case .fixed:
            let city = effectiveLocationName(settings: settings, locationService: locationService)
                ?? Strings.SettingsSummary.locationChooseCity
            return [Strings.SettingsSummary.locationCity, city].joined(separator: " · ")
        }
    }

    static func prayerTimesSummary(settings: AppSettings) -> String {
        let method = "Calculation method: \(settings.calculationMethod.displayName)"
        let offsets = [
            Strings.SettingsSummary.fajrAdjustment(adjustmentText(settings.fajrAdjustmentMinutes)),
            "Maghrib \(adjustmentText(settings.maghribAdjustmentMinutes))"
        ].joined(separator: " · ")
        return "\(method)\nPrayer offsets: \(offsets)"
    }

    static func hijriCorrectionsSummary(scheduleManager: ScheduleManager) -> String {
        let changed = HijriMonth.allCases.filter { scheduleManager.hijriAdjustment(for: $0) != 0 }.count
        if changed == 0 {
            return Strings.Settings.hijriNoChanges
        }
        return Strings.Settings.hijriAdjustedMonths(changed)
    }

    static func permissionsSummary(
        settings: AppSettings,
        schedulingMode: SchedulingMode,
        presentations: [AppPermissionKind: PermissionPresentation]
    ) -> String {
        guard hasLoadedPermissions(presentations) else {
            return Strings.SettingsSummary.permissionsChecking
        }

        let locationNeedsAttention = settings.locationMode == .auto
            && presentations[.location]?.state != .authorized
        let notificationsState = presentations[.notifications]?.state
        let alarmState = presentations[.alarmKit]?.state

        if locationNeedsAttention
            || notificationsState == .denied
            || notificationsState == .restricted
            || notificationsState == .notDetermined
            || alarmState == .denied
            || alarmState == .restricted
            || alarmState == .notDetermined {
            return Strings.SettingsSummary.permissionsNeedsAttention
        }

        if schedulingMode == .notifications || alarmState == .unavailable {
            return Strings.SettingsSummary.permissionsUsingNotifications
        }

        return Strings.SettingsSummary.permissionsAllReady
    }

    static func aboutSummary(version: String) -> String {
        Strings.SettingsSummary.about(version)
    }

    static func effectiveLocationName(settings: AppSettings, locationService: LocationService) -> String? {
        switch settings.locationMode {
        case .auto:
            guard !locationService.locationName.isEmpty else { return nil }
            return locationService.locationName
        case .fixed:
            guard let fixed = settings.fixedLocation else { return nil }
            if let city = City.all.first(where: {
                abs($0.latitude - fixed.latitude) < 0.001 && abs($0.longitude - fixed.longitude) < 0.001
            }) {
                return city.name
            }
            if !locationService.locationName.isEmpty {
                return locationService.locationName
            }
            return Strings.Settings.locationCustom
        }
    }

    static func issues(
        settings: AppSettings,
        schedulingMode: SchedulingMode,
        presentations: [AppPermissionKind: PermissionPresentation]
    ) -> [SettingsIssue] {
        guard hasLoadedPermissions(presentations) else { return [] }

        var items: [SettingsIssue] = []

        if let notifications = presentations[.notifications] {
            switch notifications.state {
            case .authorized, .needsFollowUp, .unavailable:
                break
            case .notDetermined, .denied, .restricted:
                items.append(
                    SettingsIssue(
                        id: "notifications-blocked",
                        title: Strings.SettingsIssues.notificationsBlockedTitle,
                        message: Strings.SettingsIssues.notificationsBlockedMessage,
                        statusText: Strings.Settings.badgeNeedsAttention,
                        destination: .permissionsReliability,
                        systemImage: "bell.slash",
                        tone: .critical
                    )
                )
            }
        }

        if settings.locationMode == .auto, let location = presentations[.location] {
            switch location.state {
            case .authorized:
                break
            case .needsFollowUp:
                items.append(
                    SettingsIssue(
                        id: "location-waiting",
                        title: Strings.SettingsIssues.locationWaitingTitle,
                        message: Strings.SettingsIssues.locationWaitingMessage,
                        statusText: Strings.Settings.badgeLocating,
                        destination: .location,
                        systemImage: "location.slash",
                        tone: .warning
                    )
                )
            case .notDetermined, .denied, .restricted:
                items.append(
                    SettingsIssue(
                        id: "location-blocked",
                        title: Strings.SettingsIssues.locationBlockedTitle,
                        message: Strings.SettingsIssues.locationBlockedMessage,
                        statusText: Strings.Settings.badgeNeedsAttention,
                        destination: .location,
                        systemImage: "location.slash",
                        tone: .critical
                    )
                )
            case .unavailable:
                break
            }
        }

        if let alarms = presentations[.alarmKit] {
            switch alarms.state {
            case .authorized:
                break
            case .unavailable:
                if schedulingMode == .notifications {
                    items.append(
                        SettingsIssue(
                            id: "alarm-fallback",
                            title: Strings.SettingsIssues.fallbackTitle,
                            message: Strings.SettingsIssues.fallbackMessage,
                            statusText: Strings.Settings.badgeUsingFallback,
                            destination: .permissionsReliability,
                            systemImage: "alarm",
                            tone: .warning
                        )
                    )
                }
            case .denied, .restricted, .notDetermined:
                items.append(
                    SettingsIssue(
                        id: "alarm-permission",
                        title: Strings.SettingsIssues.alarmPermissionTitle,
                        message: Strings.SettingsIssues.alarmPermissionMessage,
                        statusText: Strings.Settings.badgeUsingFallback,
                        destination: .permissionsReliability,
                        systemImage: "alarm",
                        tone: .warning
                    )
                )
            case .needsFollowUp:
                break
            }
        }

        return items
    }

    static func adjustmentText(_ minutes: Int) -> String {
        let sign = minutes >= 0 ? "+" : "-"
        return "\(sign)\(abs(minutes)) min"
    }

    static func hasLoadedPermissions(_ presentations: [AppPermissionKind: PermissionPresentation]) -> Bool {
        presentations.count == expectedPermissionCount
    }

    static func timeText(minutesFromMidnight: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .minute, value: minutesFromMidnight, to: start) ?? start
        return TimeFormatters.timeFormatter.string(from: date)
    }
}

enum SettingsDestination: String, CaseIterable, Identifiable {
    case location
    case prayerTimes
    case hijriCalendarCorrections
    case alarmBehavior
    case permissionsReliability
    case quietPeriod
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            return Strings.Settings.locationSection
        case .prayerTimes:
            return Strings.Settings.prayerTimesTitle
        case .hijriCalendarCorrections:
            return Strings.Settings.hijriCalendarTitle
        case .alarmBehavior:
            return "Wake Sounds & Reserve"
        case .permissionsReliability:
            return "Wake delivery & reliability"
        case .quietPeriod:
            return Strings.QuietPeriod.title
        case .about:
            return Strings.Settings.aboutSection
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            return "location.circle"
        case .prayerTimes:
            return "moon.stars"
        case .hijriCalendarCorrections:
            return "calendar.badge.clock"
        case .alarmBehavior:
            return "speaker.wave.3"
        case .permissionsReliability:
            return "checkmark.shield"
        case .quietPeriod:
            return "moon.circle"
        case .about:
            return "info.circle"
        }
    }
}

enum SettingsDestinationGroup: CaseIterable, Identifiable {
    case calendarTimes
    case morningRules
    case appHealth
    case about

    var id: String {
        switch self {
        case .calendarTimes:
            return "calendar-times"
        case .morningRules:
            return "morning-rules"
        case .appHealth:
            return "app-health"
        case .about:
            return "about"
        }
    }

    var title: String {
        switch self {
        case .calendarTimes:
            return Strings.Settings.calendarTimesGroup
        case .morningRules:
            return "Morning Rules"
        case .appHealth:
            return Strings.Settings.appHealthGroup
        case .about:
            return Strings.Settings.aboutGroup
        }
    }

    var destinations: [SettingsDestination] {
        switch self {
        case .calendarTimes:
            return [.location, .prayerTimes, .hijriCalendarCorrections]
        case .morningRules:
            return [.alarmBehavior]
        case .appHealth:
            return [.permissionsReliability, .quietPeriod]
        case .about:
            return [.about]
        }
    }
}

struct SettingsIssue: Identifiable, Equatable {
    enum Tone {
        case warning
        case critical
    }

    let id: String
    let title: String
    let message: String
    let statusText: String
    let destination: SettingsDestination
    let systemImage: String
    let tone: Tone
}
