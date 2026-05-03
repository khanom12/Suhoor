import Foundation

enum Strings {
    enum AlarmList {
        static let hijriAdjustmentsReviewTitle = "Hijri adjustments"
        static let hijriAdjustmentsMarkRead = "Mark as read"
    }

    enum AlarmsTab {
        static let todayLabel = "Today"
        static let tomorrowLabel = "Tomorrow"
        static func fajrTime(_ time: String) -> String { "Fajr \(time)" }
    }

    enum AddSchedule {
        static let allMatchingDatesActive = "All matching dates are already active."
        static let previewUnavailable = "Needs calendar data for a preview right now."
    }

    enum LocationAccess {
        static let title = "Location"
        static let allowLocation = "Allow Location"
        static let openSettings = "Open Settings"
        static let tryAgain = "Try Again"
        static let autoExplanation = "Allow location so Subh can calculate Fajr times for your area."
        static let deniedExplanation = "Location is off, so Subh can’t calculate local Fajr times automatically."
        static let waitingForLocation = "Getting your location..."
        static let simulatorHint = "In Simulator, also set a location from Xcode's Debug > Location menu."
        static func fixedExplanation(_ name: String) -> String { "Using \(name) for Fajr times." }
        static let fixedExplanationFallback = "Using your chosen city for Fajr times."
        static let manualOverride = "Choose a city instead of automatic location."
        static func currentLocation(_ name: String) -> String { "Current location: \(name)" }
    }

    enum AlarmAccess {
        static let title = "Alarms"
        static let allowAlarms = "Enable alarm"
        static let explanation = "Alarm access is required before Subh can prepare your first wake."
        static let deniedExplanation = "Alarm access is off. Enable it in Settings to continue."
        static let unavailableExplanation = "Alarm access is unavailable on this device. Subh cannot complete wake setup here."
    }

    enum NotificationAccess {
        static let title = "Notifications"
        static let allowNotifications = "Allow notifications"
        static let explanation = "Subh can send reminders and schedule updates for your mornings."
        static let deniedExplanation = "Notifications are off. You can enable them later in Settings."
    }

    enum Onboarding {
        static let previewFajrLabel = "Fajr"
        static let previewTag = "Preview"
        static let previewLabelActual = "Next wake"
        static let previewLabelExample = "Example"
        static let previewExampleLocation = "Example morning"
        static let previewLocalLocation = "Local Fajr time"
        static let previewWakeLabel = "Wake"
        static let previewRelationshipText = "30 min before Fajr ends"
        static let previewFajrPlaceholder = "— —"
        static let previewWakePlaceholder = "— —"
        static let previewNeedsLocation = "Enable location to calculate tomorrow’s Fajr time."
        static let previewUnavailable = "Preview will appear once your next wake is ready."

        static let valueTitle = "Wake for Fajr, automatically."
        static let valueBody = "Subh calculates your local Fajr time and prepares your next wake by default. Your main wake is set 30 minutes before Fajr ends."
        static let valueSupport = "Fasting and Tahajjud mornings can be adjusted later when you need them."
        static let valuePrimaryAction = "Set up Subh"

        static let locationTitle = "Find your Fajr time"
        static let locationBody = "Subh uses your location to calculate Fajr times for where you are. You can choose a city instead."
        static let locationPrimaryAction = "Use my location"
        static let locationSecondaryAction = "Choose a city instead"
        static let locationReady = "Location is ready."
        static func locationFixedStatus(_ name: String) -> String { "Using \(name) for Fajr times." }
        static let locationFixedReady = "Using your chosen city for Fajr times."
        static let locationFixedMissing = "Choose a city so Subh can calculate Fajr accurately."
        static let locationWaiting = "Getting your location… You can choose a city if this takes too long."
        static let locationDenied = "Location is off, so Subh can’t calculate Fajr automatically."
        static let locationRestricted = "Location is restricted on this device. Choose a city to continue."
        static let locationUnavailable = "Automatic location is unavailable. Choose a city to continue."
        static let locationTrustBullets = [
            "Used to calculate local prayer times",
            "You can choose a city instead",
            "You can change this later in Settings"
        ]

        static let permissionsTitle = "Make your wake reliable"
        static let permissionsBody = "Subh uses alarm access for your Fajr wake. Notifications can support reminders and future schedule updates."
        static let permissionsRequiredNote = "Alarm access is required before Subh can prepare your first wake."
        static let permissionsContinueBlockedNote = "Enable alarm access to continue."
        static let permissionsAlarmTitle = "Wake alarm"
        static let permissionsNotificationsTitle = "Notifications"
        static let permissionsAlarmAction = "Enable alarm"
        static let permissionsNotificationsAction = "Allow notifications"
        static let permissionsNotificationsSkipAction = "Not now"
        static let permissionsAlarmHelper = "Required for Subh to wake you reliably."
        static let permissionsAlarmReady = "Alarm access is ready."
        static let permissionsAlarmDenied = "Alarm access is off. Enable it in Settings to continue."
        static let permissionsAlarmRestricted = "Alarm access is restricted on this device."
        static let permissionsAlarmUnavailable = "Alarm access is unavailable on this device. Subh cannot complete wake setup here."
        static let permissionsAlarmChecking = "Checking alarm access…"
        static let permissionsNotificationsReady = "Notifications are ready."
        static let permissionsNotificationsRecommended = "Recommended for reminders and future schedule updates."
        static let permissionsNotificationsDenied = "Notifications are off. You can enable them later in Settings."
        static let permissionsNotificationsRestricted = "Notifications are restricted on this device."
        static let permissionsNotificationsUnavailable = "Notifications are unavailable on this device."
        static let permissionsNotificationsChecking = "Checking notifications…"

        static let successReadyTitle = "Your first wake is ready"
        static let successReadyBody = "Subh has prepared your next Fajr wake using your location and default timing. You can adjust fasting and Tahajjud mornings later."
        static let successReadyAction = "View my morning"
        static let successLoadingText = "Preparing your wake…"
        static let successAlarmReadyBadge = "Alarm ready"
        static let successNotificationOnBadge = "Notifications on"
        static let successNotificationOffBadge = "Notifications off"
        static let successBlockedTitle = "Your wake needs one more step"
        static let successBlockedBody = "Subh needs location and alarm access before it can prepare your first wake."
        static let successBlockedAction = "Finish setup"

        static let todayLabel = "Today"
        static let tomorrowLabel = "Tomorrow"

        static let continueAction = "Continue"
    }

    enum Settings {
        static let title = "Settings"
        static let needsAttentionSection = "Needs Attention"
        static let alertsGroup = "Alerts"
        static let calendarTimesGroup = "Prayer & timing"
        static let appHealthGroup = "Reliability"
        static let aboutGroup = "About"
        static let defaultAlarmsScreenTitle = "Default Morning Plan"
        static let prayerTimesTitle = "Prayer times"
        static let prayerTimesHelper = "Choose how Fajr is calculated for your morning plan."
        static let permissionsReliabilityTitle = "Permissions & reliability"
        static let alarmReliabilityTitle = "Wake reliability"
        static let alarmReliabilitySummary = "How wake-ups work, when notifications are used, and what to check if they are quiet."
        static let alarmReliabilityLearnMore = "Learn how wake-ups work"
        static let aboutDescription = "Subh is a Fajr-centered morning system that keeps your next wake, reminders, and supporting observances aligned with local prayer times."
        static let badgeLocating = "Locating"
        static let badgeNeedsAttention = "Needs attention"
        static let badgeUsingFallback = "Using fallback"
        static let badgeReady = "Ready"
        static let defaultsEnabledSection = "Default wake support"
        static let defaultsEnabledHelper = "These defaults apply to your morning plan unless a date has its own override."
        static let defaultWakeToggle = "Main alarm enabled by default"
        static let defaultReminderToggle = "Reminder enabled by default"
        static let defaultFajrToggle = "Fajr notice enabled by default"
        static let suhoorTimingSection = "Alarm timing"
        static let suhoorTimingHelper = "Applies to the main alarm only."
        static let suhoorTimeBasedOn = "Alarm time is based on"
        static let suhoorMinutesBeforeFajr = "Minutes before Fajr"
        static let reminderTimingSection = "Reminder timing"
        static let reminderTimingHelper = "Applies to the Reminder alarm only."
        static let reminderTimeBasedOn = "Reminder time is based on"
        static let reminderMinutesBeforeFajr = "Minutes before Fajr"
        static let reminderTime = "Reminder time"
        static let reminderBeforeWakeWarning = "Reminder can’t be earlier than your main wake."
        static let activePeriodSection = "Active period"
        static let activePeriodHelper = "Limits scheduling and default behavior to a time range. You can still manually enable alarms on specific days."
        static let defaultsActive = "Defaults active"
        static let activeAlways = "Always"
        static let activeDateRange = "Date range"
        static let alarmsListRangeSection = "Wake list range"
        static let alarmsListRangeHelper = "Controls how many days are shown in the Wake tab list."
        static let alarmsListRangeLabel = "Show next"
        static let alertsSection = "Morning cues"
        static let wakeAlarmLabel = "Wake"
        static let reminderLabel = "Reminder"
        static let fajrAdhanLabel = "Fajr adhan"
        static let defaultAlarmsHelper = "These defaults apply to your daily morning plan unless a specific date overrides them."
        static let wakeAlarmSection = "Wake"
        static let wakeAlarmHelper = "Your main wake around Fajr."
        static let reminderSection = "Reminder"
        static let reminderScreenHelper = "Use a reminder when you want a heads-up before Fajr."
        static let timeStyleLabel = "Time style"
        static let fixedTime = "Fixed wake"
        static let wakeTimeLabel = "Wake time"
        static let wakeOffsetTitle = "Wake relation to Fajr"
        static let reminderOffsetTitle = "Reminder time"
        static let minutesBeforeFajr = "Minutes before Fajr"
        static func offsetValue(_ minutes: Int) -> String { "\(minutes) min" }
        static let previewSection = "Preview"
        static let previewUnavailable = "Preview will appear once your next wake is ready."
        static let previewHelper = "Preview uses your current morning plan and location."
        static let routineDefaultsSection = "Alarm timing"
        static let reminderToggle = "Reminder before Fajr"
        static let reminderHelper = "Applies to all days."
        static let reminderMinutes = "Minutes before Fajr"
        static let atFajrToggle = "At Fajr (stop time)"
        static let atFajrHelper = "Plays an alert at the start of Fajr."
        static let atFajrSound = "Sound"
        static let locationSection = "Location"
        static let locationMode = "Location mode"
        static let locationAutomatic = "Automatic"
        static let locationChooseCity = "Choose city"
        static let currentCityTitle = "Current city"
        static let cityLabel = "City"
        static let locationWaiting = "Waiting for location"
        static let locationAutomaticReady = "Subh is using your current location to keep Fajr times up to date."
        static let locationAutomaticWaiting = "Location is allowed, but Subh is still waiting for a usable city fix."
        static let locationAutomaticNeedsPermission = "Allow location if you want Subh to update Fajr times automatically."
        static let locationAutomaticDenied = "Turn location back on to keep Fajr times accurate automatically."
        static let fixedLocationHelper = "Pick a city when you want Subh to stay fixed instead of updating automatically."
        static let locationHelper = "Auto updates when you travel."
        static let useCurrentLocation = "Use current location"
        static let locationSettings = "Location settings"
        static let locationAuto = "Auto"
        static let locationCity = "City"
        static let locationCustom = "Custom location"
        static let locationSearchOnline = "Search online"
        static let locationSearchTitle = "Search City"
        static let locationSearchPlaceholder = "City name"
        static let locationSearchLocalSection = "Saved cities"
        static let locationSearchOnlineSection = "Search more cities"
        static let locationSearchPrompt = "Type a city name, then tap Search to look beyond the saved list."
        static let locationSearchRequiresInternet = "Requires internet."
        static let locationSearchNoResults = "No results found."
        static let locationSearchFailed = "Search failed. Try again."
        static let locationSearchUnknown = "Unknown place"
        static let cancel = "Cancel"
        static func locationSelected(_ city: String) -> String { "Selected: \(city)" }
        static let openAppSettings = "Open App Settings"
        static let calculationSection = "Calculation"
        static let prayerTimeCalculationSection = "Prayer time calculation"
        static let calculationMethodTitle = "Calculation method"
        static let method = "Method"
        static let fajrAdjustment = "Fajr begin adjustment"
        static let fajrAdjustmentHelper = "Adjust the Fajr begin boundary earlier or later."
        static let fajrEndAdjustment = "Fajr end adjustment"
        static let fajrEndAdjustmentHelper = "Adjust the sunrise/Fajr-end boundary earlier or later."
        static let prayerBoundaryAdjustmentHelper = "Use adjustments only when your local authority or mosque publishes slightly different times."
        static let hijriCalendarTitle = "Hijri calendar corrections"
        static let hijriMonthCorrectionsTitle = "Month corrections"
        static let hijriCalendarHelper = "Adjust month starts if your local mosque begins a Hijri month one day earlier or later."
        static let hijriCalendarBannerTitle = "Affects Hijri-based schedules"
        static let hijriCalendarBannerBody = "These corrections affect Hijri fast presets, corrected Islamic dates, and calendar-based schedule generation."
        static let hijriNoChanges = "No changes"
        static func hijriAdjustedMonths(_ count: Int) -> String { "\(count) adjusted" }
        static let hijriMinusOneDay = "-1 day"
        static let hijriNoChange = "No change"
        static let hijriPlusOneDay = "+1 day"
        static let hijriAdjustedMinusOneDay = "Adjusted -1 day"
        static let hijriAdjustedPlusOneDay = "Adjusted +1 day"
        static let hijriPreviewUnavailable = "Preview will appear when calendar data for this month is available."
        static let hijriBuiltInStart = "Built-in start"
        static let hijriCorrectedStart = "Corrected start"
        static let schedulingSection = "Scheduling"
        static let permissionsSection = "Permissions"
        static let locationStatus = "Location"
        static let notificationsStatus = "Notifications"
        static let aboutSection = "About"
        static let aboutAlarms = "Alarm reliability"
        static let version = "Version"
        static let presetsSection = "Presets"
        static let customSection = "Custom"
        static func offsetOptionMinutes(_ minutes: Int) -> String { "\(minutes) min" }
    }

    enum AboutAlarms {
        static let title = "Wake reliability"
        static let bullet1 = "AlarmKit provides the most reliable wake-ups when your device supports it."
        static let bullet2 = "If alarms aren’t available, Subh falls back to notifications for reminders and wake-ups."
        static let bullet3 = "If alarms are too quiet, check your device’s Ringtone & Alerts volume."
        static let openSettings = "Open Settings"
    }

    enum SettingsSummary {
        static let wakeOff = "Wake off"
        static func wakeBeforeFajr(_ minutes: Int) -> String { "Wake \(minutes) min before Fajr" }
        static func wakeFixed(_ time: String) -> String { "Wake at \(time)" }
        static let reminderOff = "Reminder off"
        static func reminderBeforeFajr(_ minutes: Int) -> String { "Reminder \(minutes) min before Fajr" }
        static func reminderFixed(_ time: String) -> String { "Reminder at \(time)" }
        static let fajrOn = "Fajr adhan on"
        static let fajrOff = "Fajr adhan off"
        static let locationAutomatic = "Automatic"
        static let locationWaiting = "Waiting for city"
        static let locationCity = "City"
        static let locationChooseCity = "Choose city"
        static func fajrAdjustment(_ value: String) -> String { "Fajr \(value)" }
        static func hijriCorrections(_ value: String) -> String { "Corrections \(value)" }
        static let permissionsNeedsAttention = "Needs attention"
        static let permissionsChecking = "Checking status"
        static let permissionsUsingNotifications = "Using notifications"
        static let permissionsAllReady = "All permissions ready"
        static func about(_ version: String) -> String { "Version \(version)" }
    }

    enum SettingsIssues {
        static let locationWaitingTitle = "Location is still updating"
        static let locationWaitingMessage = "Subh is waiting for a usable city so it can calculate local Fajr times automatically."
        static let locationBlockedTitle = "Location needs attention"
        static let locationBlockedMessage = "Allow location to keep Fajr times accurate automatically."
        static let notificationsBlockedTitle = "Notifications are required"
        static let notificationsBlockedMessage = "Without notifications, reminders and fallback alerts can’t be delivered."
        static let fallbackTitle = "Wake delivery is limited"
        static let fallbackMessage = "This device is using notifications instead of AlarmKit."
        static let alarmPermissionTitle = "Alarm access would improve reliability"
        static let alarmPermissionMessage = "Allow alarms for the most reliable wake-ups when your device supports them."
    }

    enum SettingsCalculation {
        static let muslimWorldLeague = "Commonly used in many regions and a good general default."
        static let egyptian = "Uses the Egyptian General Authority of Survey calculation."
        static let karachi = "Uses the University of Islamic Sciences, Karachi calculation."
        static let northAmerica = "Islamic Society of North America • common in the United States and Canada."
        static let makkah = "Umm al-Qura, Makkah • Saudi Arabia setting."
    }

    enum SettingsHijri {
        static func genericEffect(_ month: String) -> String { "Affects \(month) dates." }
        static let muharram = "Affects Muharram dates and Ashura."
        static let ramadan = "Affects Ramadan dates and related schedules."
        static let shawwal = "Affects Eid al-Fitr and Shawwal dates."
        static let dhulHijjah = "Affects Arafah, Eid al-Adha, and Dhul Hijjah dates."
    }

    enum SettingsReliability {
        static let alarmKitModeTitle = "AlarmKit active"
        static let alarmKitModeMessage = "Wake-ups are using the most reliable alarm channel available on this device."
        static let notificationsModeTitle = "Using notifications"
        static let notificationsModeMessage = "Wake-ups or reminders are currently relying on notifications instead of AlarmKit."
        static let blockedModeTitle = "Wake-ups blocked"
        static let blockedModeMessage = "Subh still needs permission before it can deliver reminders or wake you up reliably."
        static let educationTitle = "Reliability basics"
        static let educationBody = "AlarmKit is preferred when available. If alarms are unavailable or not allowed, Subh falls back to notifications. If alerts are too quiet, check your device's Ringtone & Alerts volume."
    }

    enum QuietPeriod {
        static let title = "Quiet period"
        static let body = "Reduce prayer and fasting prompts for now. You can turn them back on whenever you want."
        static let masterToggle = "Quiet period"
        static let prayerToggle = "Reduce prayer check-ins"
        static let fastingToggle = "Reduce fasting prompts"
        static let footer = "Quiet period softens prayer and fasting prompts. It does not change wake delivery unless you adjust that separately."
        static let summaryOff = "Off"
        static let summaryOn = "Prayer and fasting prompts are softer."
        static let summaryPartial = "Some prompts are softer."
    }
}
