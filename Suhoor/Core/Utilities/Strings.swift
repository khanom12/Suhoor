import Foundation

enum Strings {
    enum AlarmList {
        static let title = "Alarms"
        static let routineTitle = "Suhoor"
        static let notSetUp = "Not set up"
        static let turnOnFooter = "Turn on to schedule."
        static let wakeTitle = "Wake"
        static let reminderTitle = "Reminder"
        static let fajrTitle = "Fajr Adhan"
        static let reminderMinutesLabel = "Minutes before"
        static let fajrSoundLabel = "Sound"
        static let placeholderTime = "— —"
        static let offLabel = "Off"
        static let todayLabel = "Today"
        static let tomorrowLabel = "Tomorrow"
        static func wakeSubtitle(_ minutes: Int) -> String {
            "Wake me \(minutes) min before Fajr"
        }
        static func reminderSubtitle(_ minutes: Int) -> String {
            "Remind me \(minutes) min before Fajr"
        }
        static let fajrSubtitle = "Fajr Adhan"
        static func nextAlarmTitleLine(prefix: String) -> String {
            "Next Alarm - \(prefix)"
        }
        static func subtitle(dateText: String, wakeMinutes: Int, reminderOn: Bool, fajrOn: Bool) -> String {
            let reminder = reminderOn ? "On" : "Off"
            let fajr = fajrOn ? "On" : "Off"
            return "\(dateText) • Wake \(wakeMinutes)m before Fajr • Reminder \(reminder) • Fajr \(fajr)"
        }
        static let locationRequired = "Enable location to calculate Fajr times."
        static let notificationsRequired = "Enable notifications for reminders and Adhan."
        static let openSettings = "Open Settings"
        static let alarmKitUnavailableTitle = "Using Notifications"
        static let alarmKitUnavailableBody = "AlarmKit isn’t available on this device. Suhoor still works, but reminders may be less reliable."
        static let learnMore = "Learn more"
        static let alarmDenied = "Using notifications. Allow alarms for reliability."
        static let notificationsFallback = "Using notifications (less reliable)."
        static let scheduleUnable = "Schedule couldn’t load. Tap to retry."
    }

    enum AlarmsTab {
        static let scheduleWindow = "Days shown"
        static func nextDays(_ count: Int) -> String { "Next \(count) days" }
        static func todayHeader(gregorian: String, hijri: String) -> String {
            "Today: \(gregorian) • \(hijri)"
        }
        static let listRangeTitle = "Alarms list range"
        static let listRangeHelper = "Controls how many days are shown in the Alarms tab list."
        static let emptyTitle = "No schedule yet"
        static let emptySubtitle = "Enable defaults or create a day override to schedule alarms."
        static let customizedBadge = "Customized"
        static let skippedBadge = "Skipped"
        static let todayLabel = "Today"
        static let tomorrowLabel = "Tomorrow"
        static let suhoorLabel = "Suhoor"
        static let reminderLabel = "Reminder"
        static let fajrLabel = "Fajr"
        static let onLabel = "On"
        static let offLabel = "Off"
        static let enabledLabel = "Enabled"
        static let useFixedTime = "Use fixed time"
        static let timeModeLabel = "Time mode"
        static let beforeFajrLabel = "Before Fajr"
        static let fixedTimeLabel = "Fixed"
        static let minutesBeforeFajr = "Minutes before Fajr"
        static let alarmOffLabel = "Off"
        static let fajrAdhanLabel = "Fajr (Adhan)"
        static let suhoorAlarmLabel = "Suhoor Alarm"
        static let reminderAlarmLabel = "Reminder Alarm"
        static let dayDisabledHelper = "If off, no alarms will run on this date."
        static let dayEnableToConfigureHelper = "Turn on \"Enable this day\" to configure alarms."
        static let suhoorTime = "Suhoor time"
        static func suhoorComputed(_ time: String) -> String { "Computed: \(time)" }
        static func reminderOffsetLabel(_ minutes: Int) -> String { "Minutes before Fajr: \(minutes)m" }
        static func reminderComputed(_ time: String) -> String { "Computed: \(time)" }
        static let reminderOff = "Reminder is off for this day."
        static func fajrComputed(_ time: String) -> String { "Fajr: \(time)" }
        static func fajrTime(_ time: String) -> String { "Fajr \(time)" }
        static func willRingAt(_ time: String) -> String { "Will ring at \(time)" }
        static func willPlayAt(_ time: String) -> String { "Will play at \(time)" }
        static func computedAt(_ time: String) -> String { "Computed: \(time)" }
        static let fajrHelper = "Matches your calculated Fajr time."
        static let resetDay = "Reset this day to defaults"
        static let defaultsSection = "Default Alarms"
        static let suhoorMode = "Suhoor time mode"
        static let activationMode = "Activation mode"
        static let activeStartDate = "Start date"
        static let activeEndDate = "End date"
    }

    enum LocationRationale {
        static let title = "Use your location"
        static let body = "Suhoor uses your location to calculate Fajr times for your area and keep your routine updated."
        static let continueButton = "Continue"
        static let notNowButton = "Not now"
    }

    enum NotificationRationale {
        static let title = "Allow notifications"
        static let body = "Used for your reminder before Fajr and your At Fajr alert."
        static let continueButton = "Continue"
        static let notNowButton = "Not now"
    }

    enum AlarmDetail {
        static let title = "Suhoor"
        static let nextSection = "Next"
        static let wakeRow = "Wake"
        static let fajrRow = "Fajr"
        static let updatesFooter = "Updates daily based on location."
        static let wakeSection = "Wake"
        static let wakeMe = "Wake me"
        static let wakeHelper = "Your main wake alarm."
        static let reminderSection = "Reminder"
        static let reminderToggle = "Reminder before Fajr"
        static let reminderTime = "Time"
        static let reminderHelper = "Heads-up to wrap up suhoor."
        static let atFajrSection = "At Fajr"
        static let atFajrToggle = "Fajr Adhan"
        static let atFajrHelper = "Signals the start of Fajr."
        static let alertDefaultsSection = "Daily Alerts"
        static let editAlertDefaults = "Edit defaults in Settings"
        static let alertDefaultsHelper = "Applies to all days."
        static let snoozeSection = "Snooze"
        static let snoozeToggle = "Snooze"
        static let snoozeDuration = "Duration"
        static let snoozeHelper = "Only for Wake."
        static let labelSection = "Label"
        static let viewSchedule = "View schedule"
    }

    enum Schedule {
        static let title = "Schedule"
        static func nextDays(_ count: Int) -> String { "Next \(count) days" }
        static let reminderOff = "Reminder Off"
        static let defaultBadge = "Default"
        static let customBadge = "Custom"
        static let offBadge = "Off"
    }

    enum DayDetail {
        static let timesSection = "Times"
        static let ruleSection = "Rule"
        static let exceptionSection = "Exception"
        static let skipDay = "Skip this day"
        static let createException = "Create exception"
        static let editException = "Edit exception"
        static let resetDefault = "Reset to default"
    }

    enum ExceptionEditor {
        static let title = "Exception"
        static let dateSection = "Date"
        static let exceptionSection = "Exception"
        static let save = "Save"
        static let cancel = "Cancel"
    }

    enum Settings {
        static let title = "Settings"
        static let defaultsEnabledSection = "Default enabled alarms"
        static let defaultsEnabledHelper = "These defaults apply when a day has no custom overrides."
        static let defaultSuhoorToggle = "Suhoor alarm enabled by default"
        static let defaultReminderToggle = "Reminder alarm enabled by default"
        static let defaultFajrToggle = "Fajr event enabled by default"
        static let suhoorTimingSection = "Suhoor timing"
        static let suhoorTimingHelper = "Applies to the Suhoor alarm only."
        static let suhoorTimeBasedOn = "Suhoor time is based on"
        static let suhoorMinutesBeforeFajr = "Minutes before Fajr"
        static let reminderTimingSection = "Reminder timing"
        static let reminderTimingHelper = "Applies to the Reminder alarm only."
        static let reminderTimeBasedOn = "Reminder time is based on"
        static let reminderMinutesBeforeFajr = "Minutes before Fajr"
        static let reminderTime = "Reminder time"
        static let reminderBeforeSuhoorWarning = "Reminder can’t be earlier than Suhoor."
        static let activePeriodSection = "Active period"
        static let activePeriodHelper = "Limits scheduling and default behavior to a time range. You can still manually enable alarms on specific days."
        static let defaultsActive = "Defaults active"
        static let activeAlways = "Always"
        static let activeDateRange = "Date range"
        static let alarmsListRangeSection = "Alarms list range"
        static let alarmsListRangeHelper = "Controls how many days are shown in the Alarms tab list."
        static let alarmsListRangeLabel = "Show next"
        static let routineDefaultsSection = "Routine Defaults"
        static let reminderToggle = "Reminder before Fajr"
        static let reminderHelper = "Applies to all days."
        static let reminderMinutes = "Minutes before Fajr"
        static let atFajrToggle = "At Fajr (stop time)"
        static let atFajrHelper = "Plays an alert at the start of Fajr."
        static let atFajrSound = "Sound"
        static let soundCheckSection = "Sound Check"
        static let soundCheckTitle = "Sound Check"
        static let soundCheckHelper = "AlarmKit uses system alarm volume. Tests play in 5 seconds."
        static let playAdhanNow = "Play Adhan now"
        static let adhanPlaying = "Playing Adhan preview."
        static let adhanMissing = "Adhan sound file not found in the app bundle."
        static let stopAdhan = "Stop Adhan"
        static let testFajrAdhanAlarm = "Test Fajr alarm (Adhan, 1 min)"
        static let cancelSoundTests = "Cancel sound tests"
        static let testAlarmKit = "Schedule test alarm (1 min)"
        static let cancelAlarmKitTest = "Cancel test alarm"
        static let testNotificationScheduled = "Test notification scheduled in 5 seconds."
        static let testNotificationFailed = "Couldn’t schedule test notification. Check permissions."
        static let fajrAlarmScheduled = "Test Fajr alarm scheduled for 1 minute from now."
        static let fajrAlarmScheduleFailed = "Couldn’t schedule Fajr test alarm. Check permissions."
        static let alarmScheduled = "Test alarm scheduled for 1 minute from now."
        static let alarmScheduleFailed = "Couldn’t schedule test alarm. Check permissions."
        static let testsCancelled = "Test schedules canceled."
        static let locationSection = "Location"
        static let locationMode = "Location mode"
        static let locationHelper = "Auto updates when you travel."
        static let useCurrentLocation = "Use current location"
        static let locationSettings = "Location settings"
        static let locationAuto = "Auto"
        static let locationCity = "City"
        static let locationCustom = "Custom location"
        static let locationSearchOnline = "Search online"
        static let locationSearchTitle = "Search City"
        static let locationSearchPlaceholder = "City name"
        static let locationSearchRequiresInternet = "Requires internet."
        static let locationSearchNoResults = "No results found."
        static let locationSearchFailed = "Search failed. Try again."
        static let locationSearchUnknown = "Unknown place"
        static let cancel = "Cancel"
        static func locationSelected(_ city: String) -> String { "Selected: \(city)" }
        static let openAppSettings = "Open App Settings"
        static let calculationSection = "Calculation"
        static let method = "Method"
        static let fajrAdjustment = "Fajr adjustment"
        static let fajrAdjustmentHelper = "Adjust Fajr earlier or later."
        static let schedulingSection = "Scheduling"
        static let schedulePreview = "Schedule preview"
        static let schedulePreviewHelper = "Changes Schedule only."
        static let permissionsSection = "Permissions"
        static let locationStatus = "Location"
        static let notificationsStatus = "Notifications"
        static let aboutSection = "About"
        static let aboutAlarms = "About alarms"
        static let version = "Version"
    }

    enum AboutAlarms {
        static let title = "Alarms & reliability"
        static let bullet1 = "AlarmKit alarms are the most reliable for wake-ups."
        static let bullet2 = "If AlarmKit isn’t available, Suhoor uses notifications."
        static let bullet3 = "Check Ringtone & Alerts volume if alarms are quiet."
        static let openSettings = "Open Settings"
    }
}
