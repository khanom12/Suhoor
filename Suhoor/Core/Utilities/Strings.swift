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
        static let hijriAdjustmentsTitle = "Hijri corrections updated"
        static func hijriAdjustmentsMessage(_ count: Int) -> String {
            "\(count) date\(count == 1 ? "" : "s") adjusted."
        }
        static let hijriAdjustmentsAction = "Review"
        static let hijriAdjustmentsReviewTitle = "Hijri adjustments"
        static let hijriAdjustmentsMarkRead = "Mark as read"
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
        static let emptySubtitle = "Use the + button to add a day, date range, or Islamic-date schedule."
        static let customizedBadge = "Customized"
        static let skippedBadge = "Skipped"
        static let todayLabel = "Today"
        static let tomorrowLabel = "Tomorrow"
        static func ramadanDayLabel(_ day: Int) -> String { "Fasting Day \(day)" }
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
        static let resetDayTitle = "Reset this day to defaults?"
        static let resetDayMessage = "This removes day-specific edits and restores the default alarm settings you saved during onboarding or in Settings."
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
        static let resetDayHelper = "Restores the default alarm settings you saved in onboarding or Settings and removes any edits made just for this date."
        static let sourceGeneratedHelper = "This date is included because of a recurring schedule or saved date range."
        static let sourceManualHelper = "This date was added directly."
        static let sourceDayExclusion = "Exclude this date from the schedule"
        static let sourceDayExclusionHelper = "Keeps the schedule, but leaves this specific date out."
        static let sourceDeleteDay = "Delete this day"
        static let sourceDeleteDayHelper = "Removes this one manually added date."
        static let defaultsSection = "Default Alarms"
        static let suhoorMode = "Suhoor time mode"
        static let activationMode = "Activation mode"
        static let activeStartDate = "Start date"
        static let activeEndDate = "End date"
        static let emptyMonth = "No alarms in this month yet."
        static let emptyFilteredMonth = "No alarms match the selected tags yet."
        static let nextAlarmSectionTitle = "Next alarm"
        static let filterTitle = "Filter Tags"
        static let filterApply = "Apply"
        static let filterClear = "Clear"
        static let filteringLabel = "Filtered by"
        static let filterPurposeSection = "Purpose"
        static let filterAnyPurpose = "Any purpose"
        static let filterObservancesSection = "Observances"
        static let filterMatchAllFooter = "Shows only alarms that match all selected tags."
        static let filterVoluntaryOnlyHelper = "Only available with Voluntary (Sunnah) purpose."
        static func filterIncompatibleTagHelper(_ titles: String) -> String {
            "Can’t combine with \(titles)."
        }
        static func alarmCountAccessibility(_ count: Int) -> String {
            "\(count) alarm\(count == 1 ? "" : "s") in this month"
        }
        static func hijriMonthStarts(_ date: String) -> String { "Starts \(date)" }
        static func hijriMonthStarted(_ date: String) -> String { "Started \(date)" }
    }

    enum AddSchedule {
        static let title = "Add Schedule"
        static let modeHelperSingleDay = "Add one specific date."
        static let modeHelperDateRange = "Add a span of dates."
        static let modeHelperIslamicDates = "Add common fasting dates using your Hijri corrections."
        static let addDay = "Add Day"
        static let addRange = "Add Range"
        static let disabledSingleDay = "This day is already active."
        static let disabledRange = "No new dates in this range."
        static let hijriBanner = "Hijri dates use your corrections. Ramadan is automatic."
        static let manageCorrections = "Manage corrections"
        static let recurringBanner = "Recurring schedules fill the next Hijri year. Suhoor schedules upcoming alarms automatically, and matching dates are merged."
        static let rangeHelper = "Choose a start and end date."
        static let rangePreviewFooter = "Ramadan dates are skipped automatically."
        static let purposeHelper = "Applies to every date in the range."
        static let detailsTitle = "Details"
        static let alreadyActiveThroughRecurring = "Already active through another recurring schedule."
        static let someDatesAlreadyCovered = "Some matching dates are already covered."
        static let someAlreadyActive = "Some already active."
        static let allMatchingDatesActive = "All matching dates are already active."
        static let previewUnavailable = "Needs calendar data for a preview right now."
    }

    enum LocationRationale {
        static let title = "Use your location"
        static let body = "Suhoor uses your location to calculate Fajr times for your area and keep your routine updated."
        static let continueButton = "Continue"
        static let notNowButton = "Not now"
    }

    enum LocationAccess {
        static let title = "Location"
        static let allowLocation = "Allow Location"
        static let openSettings = "Open Settings"
        static let tryAgain = "Try Again"
        static let autoExplanation = "Allow location so Suhoor can calculate Fajr times for your area."
        static let deniedExplanation = "Location is off, so Suhoor can’t calculate local Fajr times automatically."
        static let waitingForLocation = "Getting your location..."
        static let simulatorHint = "In Simulator, also set a location from Xcode's Debug > Location menu."
        static func fixedExplanation(_ name: String) -> String { "Using \(name) for Fajr times." }
        static let fixedExplanationFallback = "Using your chosen city for Fajr times."
        static let manualOverride = "Choose a city instead of automatic location."
        static func currentLocation(_ name: String) -> String { "Current location: \(name)" }
    }

    enum AlarmAccess {
        static let title = "Alarms"
        static let allowAlarms = "Enable Alarms"
        static let explanation = "Enable alarms for the most reliable wake-up before Fajr."
        static let deniedExplanation = "Alarm access is off, so wake-ups will fall back to notifications."
        static let unavailableExplanation = "AlarmKit isn’t available on this device, so wake-ups use notifications."
    }

    enum NotificationAccess {
        static let title = "Notifications"
        static let allowNotifications = "Allow Notifications"
        static let explanation = "Used for reminders before Fajr and backup alerts."
        static let deniedExplanation = "Notifications are off, so reminders and fallback alerts can’t be delivered."
    }

    enum NotificationRationale {
        static let title = "Allow notifications"
        static let body = "Used for your reminder before Fajr and your At Fajr alert."
        static let continueButton = "Continue"
        static let notNowButton = "Not now"
    }

    enum Onboarding {
        static let welcomeTitle = "Wake before Fajr, reliably"
        static let welcomeBody = "Pick your wake-up once. Suhoor updates it each day based on Fajr in your area."
        static let welcomePrimaryAction = "Get started"
        static let welcomeSecondaryAction = "How it works"

        static let locationTitle = "Allow location"
        static let locationBody = "Tap \"Use my location.\" On the next popup, choose \"Allow While Using App.\""
        static let locationPrivacyNote = "Used to calculate times."
        static let locationPrimaryAction = "Use my location"
        static let locationSecondaryAction = "Choose a city"
        static let locationReady = "Location is ready."
        static func locationFixedStatus(_ name: String) -> String { "Using \(name) for Fajr times." }
        static let locationFixedReady = "Using your chosen city for Fajr times."
        static let locationFixedMissing = "Choose a city so Suhoor can calculate Fajr accurately."

        static let alarmKitTitle = "Reliable wake-up"
        static let alarmKitBody = "Enable alarms for the most reliable wake-up before Fajr."
        static let alarmKitFootnote = "Requires iOS 26+ and a compatible device."
        static let alarmKitPrimaryAction = "Enable alarms"
        static let alarmKitFallbackBanner = "If alarms aren’t available, Suhoor can still alert you with notifications (less reliable)."
        static let alarmKitReady = "Alarms are ready."

        static let notificationsTitle = "Allow notifications"
        static let notificationsBody = "On the next popup, tap \"Allow\" for reminders and backup alerts."
        static let notificationsRequirement = "Required to finish setup."
        static let notificationsPrimaryAction = "Enable notifications"
        static let notificationsReady = "Notifications are ready."

        static let offsetTitle = "Choose your wake-up"
        static let offsetBody = "How many minutes before Fajr should we wake you?"
        static let offsetCustomHelper = "You can customize specific days later in Schedule."

        static let confirmationTitle = "You’re set"
        static let confirmationBody = "Suhoor will keep your schedule updated each day."

        static let continueAction = "Continue"
        static let doneAction = "Finish"

        enum HowItWorks {
            static let title = "How Suhoor works"
            static let body = "Suhoor calculates Fajr for your area, then keeps tomorrow’s wake-up up to date."
            static func bulletWakeDefault(_ minutes: Int) -> String { "Choose a default, for example \(minutes) minutes before Fajr." }
            static let bulletReminders = "Get a reminder and an optional Fajr Adhan alert."
            static let bulletCustomize = "Adjust any day later in Schedule."
        }
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
        static let wakeCustomHelper = "Customize any day later in Schedule."
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

    enum Settings {
        static let title = "Settings"
        static let needsAttentionSection = "Needs Attention"
        static let alertsGroup = "Alerts"
        static let calendarTimesGroup = "Calendar & times"
        static let appHealthGroup = "App health"
        static let aboutGroup = "About"
        static let defaultAlarmsScreenTitle = "Default alarms"
        static let prayerTimesTitle = "Prayer times"
        static let prayerTimesHelper = "Choose how Fajr is calculated for your schedule."
        static let permissionsReliabilityTitle = "Permissions & reliability"
        static let alarmReliabilityTitle = "Alarm reliability"
        static let alarmReliabilitySummary = "How wake-ups work, when notifications are used, and what to check if alarms are quiet."
        static let alarmReliabilityLearnMore = "Learn how wake-ups work"
        static let aboutDescription = "Suhoor keeps your routine in sync with local Fajr times so your wake-up, reminder, and Fajr adhan stay easy to review."
        static let badgeLocating = "Locating"
        static let badgeNeedsAttention = "Needs attention"
        static let badgeUsingFallback = "Using fallback"
        static let badgeReady = "Ready"
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
        static let alertsSection = "Alerts"
        static let wakeAlarmLabel = "Wake alarm"
        static let reminderLabel = "Reminder"
        static let fajrAdhanLabel = "Fajr adhan"
        static let defaultAlarmsHelper = "These defaults apply to days that don’t have custom overrides."
        static let wakeAlarmSection = "Wake alarm"
        static let wakeAlarmHelper = "Your main wake-up time for Suhoor."
        static let reminderSection = "Reminder"
        static let reminderScreenHelper = "Use a reminder when you want a heads-up before Fajr."
        static let timeStyleLabel = "Time style"
        static let fixedTime = "Fixed time"
        static let wakeTimeLabel = "Wake time"
        static let wakeOffsetTitle = "Wake time"
        static let reminderOffsetTitle = "Reminder time"
        static let minutesBeforeFajr = "Minutes before Fajr"
        static func offsetValue(_ minutes: Int) -> String { "\(minutes) min" }
        static let previewSection = "Tomorrow preview"
        static let previewUnavailable = "Preview will appear once Suhoor has generated tomorrow’s schedule."
        static let previewHelper = "Preview uses your current defaults and location."
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
        static let locationAutomatic = "Automatic"
        static let locationChooseCity = "Choose city"
        static let currentCityTitle = "Current city"
        static let cityLabel = "City"
        static let locationWaiting = "Waiting for location"
        static let locationAutomaticReady = "Suhoor is using your current location to keep Fajr times up to date."
        static let locationAutomaticWaiting = "Location is allowed, but Suhoor is still waiting for a usable city fix."
        static let locationAutomaticNeedsPermission = "Allow location if you want Suhoor to update Fajr times automatically."
        static let locationAutomaticDenied = "Turn location back on to keep Fajr times accurate automatically."
        static let fixedLocationHelper = "Pick a city when you want Suhoor to stay fixed instead of updating automatically."
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
        static let fajrAdjustment = "Fajr adjustment"
        static let fajrAdjustmentHelper = "Adjust Fajr earlier or later."
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
        static let title = "Alarm reliability"
        static let bullet1 = "AlarmKit provides the most reliable wake-ups when your device supports it."
        static let bullet2 = "If alarms aren’t available, Suhoor falls back to notifications for reminders and wake-ups."
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
        static let locationWaitingMessage = "Suhoor is waiting for a usable city so it can calculate local Fajr times automatically."
        static let locationBlockedTitle = "Location needs attention"
        static let locationBlockedMessage = "Allow location to keep Fajr times accurate automatically."
        static let notificationsBlockedTitle = "Notifications are required"
        static let notificationsBlockedMessage = "Without notifications, reminders and fallback alerts can’t be delivered."
        static let fallbackTitle = "Wake-ups are using notifications"
        static let fallbackMessage = "This device is using notification fallback instead of AlarmKit for wake-ups."
        static let alarmPermissionTitle = "Alarm access would improve reliability"
        static let alarmPermissionMessage = "Allow alarms for the most reliable wake-ups when your device supports them."
    }

    enum SettingsCalculation {
        static let muslimWorldLeague = "Commonly used in many regions and a good general default."
        static let egyptian = "Uses the Egyptian General Authority of Survey calculation."
        static let karachi = "Uses the University of Islamic Sciences, Karachi calculation."
        static let northAmerica = "Often used for schedules in the United States and Canada."
        static let makkah = "Uses the Umm al-Qura calculation associated with Makkah."
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
        static let blockedModeMessage = "Suhoor still needs permission before it can deliver reminders or wake you up reliably."
        static let educationTitle = "Reliability basics"
        static let educationBody = "AlarmKit is preferred when available. If alarms are unavailable or not allowed, Suhoor falls back to notifications. If alerts are too quiet, check your device's Ringtone & Alerts volume."
    }
}
