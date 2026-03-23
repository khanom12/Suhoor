import SwiftUI

struct DefaultAlarmsSettingsView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(
                title: "Default Morning Plan",
                supportingText: "Set your normal Fajr-centered wake rhythm. Post-Fajr and fixed wakes stay as date-specific exceptions."
            ) {
                SettingsRow {
                    SettingsValueRow(title: "Wake timing", value: wakeSummaryText)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Routine cap", value: latestWakeCapSummaryText)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Support cues", value: supportCueSummaryText)
                }

                if usesLegacyFixedTimeCompatibility {
                    AppGroupDivider()
                    SettingsRow {
                        Text("A legacy fixed-time default is still preserved for compatibility. Updating this plan converts it back to the Fajr-centered rule set.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            SettingsGroup(
                title: "Wake Rule",
                supportingText: "Defaults may be Pre-Fajr or In-Fajr only."
            ) {
                SettingsRow {
                    Picker("Default wake state", selection: defaultWakeStateBinding) {
                        ForEach(DefaultWakeState.allCases) { state in
                            Text(defaultWakeStateTitle(state)).tag(state)
                        }
                    }
                }

                if alarmConfigStore.defaults.defaultWakeState == .inFajr {
                    AppGroupDivider()
                    SettingsRow {
                        Picker("Anchor", selection: defaultWakeAnchorBinding) {
                            Text("From Fajr start").tag(WakeAnchorType.fajrStart)
                            Text("Before Fajr end").tag(WakeAnchorType.fajrEnd)
                        }
                    }
                }

                AppGroupDivider()
                SettingsRow {
                    Stepper(value: wakeDeltaBinding, in: 0...240, step: 1) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deltaRowTitle)
                            Text(deltaSummaryText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                AppGroupDivider()
                SettingsRow {
                    Toggle("Latest wake cap", isOn: latestWakeCapEnabledBinding)
                }

                if alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight != nil {
                    AppGroupDivider()
                    SettingsRow {
                        DatePicker(
                            "Never wake later than",
                            selection: latestWakeCapBinding,
                            displayedComponents: [.hourAndMinute]
                        )
                    }

                    AppGroupDivider()
                    SettingsRow {
                        Text("The cap only pulls earlier. It can move an in-Fajr default earlier, including into Pre-Fajr, when you want routine stability.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            SettingsGroup(
                title: "Support Around Wake",
                supportingText: "Keep the wake plan in Plans, and leave sound behavior in Settings."
            ) {
                SettingsRow {
                    Toggle(Strings.Settings.wakeAlarmLabel, isOn: suhoorDefaultBinding)
                }
                AppGroupDivider()
                SettingsRow {
                    Toggle(Strings.Settings.reminderLabel, isOn: reminderDefaultBinding)
                }

                if alarmConfigStore.defaults.reminderEnabledDefault {
                    AppGroupDivider()
                    SettingsRow {
                        Stepper(value: reminderDefaultOffsetBinding, in: 1...180, step: 1) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder lead")
                                Text("\(alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr) min before Fajr")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                AppGroupDivider()
                SettingsRow {
                    Toggle("At Fajr start cue", isOn: fajrDefaultBinding)
                }
                AppGroupDivider()
                SettingsRow {
                    Toggle("Iftar / Maghrib", isOn: iftarDefaultBinding)
                }
                AppGroupDivider()
                SettingsRow {
                    Toggle("Wake follow-up", isOn: wakeFollowUpEnabledBinding)
                }

                if settingsStore.settings.snoozeEnabled {
                    AppGroupDivider()
                    SettingsRow {
                        Picker("Follow-up delay", selection: wakeFollowUpMinutesBinding) {
                            ForEach([5, 9, 10, 15], id: \.self) { value in
                                Text("\(value) minutes").tag(value)
                            }
                        }
                    }
                }
            }

            SettingsGroup(
                title: "Validation",
                supportingText: "Defaults validate against the next rolling 365 days for your current location and prayer calculation."
            ) {
                SettingsRow {
                    validationRow
                }
            }

            SettingsGroup(
                title: Strings.Settings.previewSection,
                supportingText: "Tomorrow reflects the same resolver used on Home and Wake."
            ) {
                if let preview = scheduleManager.schedules.first {
                    SettingsRow {
                        previewRow(title: Strings.Settings.wakeAlarmLabel, value: TimeFormatters.timeFormatter.string(from: preview.wakeDate))
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: Strings.Settings.reminderLabel,
                            value: preview.reminderDate.map { TimeFormatters.timeFormatter.string(from: $0) } ?? Strings.AlarmList.offLabel
                        )
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: "At Fajr start",
                            value: TimeFormatters.timeFormatter.string(from: preview.fajrDate)
                        )
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: "Iftar / Maghrib",
                            value: TimeFormatters.timeFormatter.string(from: preview.iftarDate ?? preview.maghribDate)
                        )
                    }
                } else {
                    SettingsRow {
                        Text(Strings.Settings.previewUnavailable)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.defaultAlarmsScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var validationResult: DefaultWakeRuleValidationResult? {
        scheduleManager.defaultWakeValidation()
    }

    private var usesLegacyFixedTimeCompatibility: Bool {
        alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime
    }

    private var wakeSummaryText: String {
        guard alarmConfigStore.defaults.suhoorEnabledDefault else {
            return Strings.AlarmsTab.alarmOffLabel
        }
        return deltaSummaryText
    }

    private var latestWakeCapSummaryText: String {
        guard let latestWakeCap = alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight else {
            return "Off"
        }
        return SettingsSummaryFormatter.timeText(minutesFromMidnight: latestWakeCap)
    }

    private var supportCueSummaryText: String {
        var parts: [String] = []
        parts.append(alarmConfigStore.defaults.reminderEnabledDefault ? "Reminder on" : "Reminder off")
        parts.append(alarmConfigStore.defaults.fajrEnabledDefault ? "Fajr cue on" : "Fajr cue off")
        parts.append(settingsStore.settings.snoozeEnabled ? "Follow-up \(settingsStore.settings.snoozeMinutes) min" : "Follow-up off")
        return parts.joined(separator: " · ")
    }

    private var deltaRowTitle: String {
        switch alarmConfigStore.defaults.defaultWakeState {
        case .preFajr:
            return "Minutes before Fajr starts"
        case .inFajr:
            return alarmConfigStore.defaults.normalizedDefaultWakeAnchorType == .fajrEnd
                ? "Minutes before Fajr ends"
                : "Minutes after Fajr starts"
        }
    }

    private var deltaSummaryText: String {
        let delta = alarmConfigStore.defaults.defaultWakeDeltaMinutes
        switch alarmConfigStore.defaults.defaultWakeState {
        case .preFajr:
            return "\(delta) min before Fajr"
        case .inFajr:
            if alarmConfigStore.defaults.normalizedDefaultWakeAnchorType == .fajrEnd {
                return "\(delta) min before Fajr ends"
            }
            return "\(delta) min after Fajr starts"
        }
    }

    @ViewBuilder
    private var validationRow: some View {
        if let validationResult {
            if validationResult.isValid {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Valid across 365 days")
                    if validationResult.capPulledIntoPreFajrCount > 0 {
                        Text("The latest wake cap pulls \(validationResult.capPulledIntoPreFajrCount) in-Fajr morning(s) earlier into Pre-Fajr.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Needs adjustment")
                    if let message = validationResult.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let firstInvalidDateKey = validationResult.firstInvalidDateKey {
                        Text(firstInvalidDateKey)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Text("Validation needs a usable location first.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func previewRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var defaultWakeStateBinding: Binding<DefaultWakeState> {
        Binding(get: {
            alarmConfigStore.defaults.defaultWakeState
        }, set: { newValue in
            alarmConfigStore.defaults.defaultWakeState = newValue
            if newValue == .preFajr {
                alarmConfigStore.defaults.defaultWakeAnchorType = .fajrStart
            }
            commitWakeRuleEdit()
        })
    }

    private var defaultWakeAnchorBinding: Binding<WakeAnchorType> {
        Binding(get: {
            alarmConfigStore.defaults.normalizedDefaultWakeAnchorType
        }, set: { newValue in
            alarmConfigStore.defaults.defaultWakeAnchorType = newValue == .fajrEnd ? .fajrEnd : .fajrStart
            commitWakeRuleEdit()
        })
    }

    private var wakeDeltaBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultWakeDeltaMinutes
        }, set: { newValue in
            alarmConfigStore.defaults.defaultWakeDeltaMinutes = max(0, newValue)
            commitWakeRuleEdit()
        })
    }

    private var latestWakeCapEnabledBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight != nil
        }, set: { newValue in
            if newValue {
                alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight
                    = alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight
                    ?? DateHelpers.minutesFromMidnight(for: Date(), timeZone: .current)
            } else {
                alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight = nil
            }
            rescheduleFromDefaults()
        })
    }

    private var latestWakeCapBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(
                for: Date(),
                minutes: alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight
                    ?? DateHelpers.minutesFromMidnight(for: Date(), timeZone: .current)
            )
        }, set: { newValue in
            alarmConfigStore.defaults.defaultLatestWakeCapMinutesFromMidnight = minutesFromMidnight(for: newValue)
            rescheduleFromDefaults()
        })
    }

    private var suhoorDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.suhoorEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.suhoorEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.reminderEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.reminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr = max(1, newValue)
            rescheduleFromDefaults()
        })
    }

    private var fajrDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.fajrEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.fajrEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var iftarDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.iftarEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.iftarEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var wakeFollowUpEnabledBinding: Binding<Bool> {
        Binding(get: {
            settingsStore.settings.snoozeEnabled
        }, set: { newValue in
            settingsStore.update { draft in
                draft.snoozeEnabled = newValue
            }
            rescheduleFromDefaults()
        })
    }

    private var wakeFollowUpMinutesBinding: Binding<Int> {
        Binding(get: {
            settingsStore.settings.snoozeMinutes
        }, set: { newValue in
            settingsStore.update { draft in
                draft.snoozeMinutes = newValue
            }
            rescheduleFromDefaults()
        })
    }

    private func defaultWakeStateTitle(_ state: DefaultWakeState) -> String {
        switch state {
        case .preFajr:
            return "Pre-Fajr"
        case .inFajr:
            return "In-Fajr"
        }
    }

    private func commitWakeRuleEdit() {
        alarmConfigStore.defaults.defaultSuhoorTimeMode = .relativeToFajrMinusMinutes
        alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = alarmConfigStore.defaults.defaultWakeDeltaMinutes
        rescheduleFromDefaults()
    }

    private func rescheduleFromDefaults() {
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    private func minutesFromMidnight(for date: Date) -> Int {
        DateHelpers.minutesFromMidnight(for: date, timeZone: .current)
    }

    private func dateFromMidnight(for day: Date, minutes: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}
