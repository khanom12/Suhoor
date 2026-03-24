import SwiftUI

struct DefaultAlarmsSettingsView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(
                title: "Default Morning Plan",
                supportingText: "Choose how mornings normally relate to Fajr."
            ) {
                SettingsRow {
                    SettingsValueRow(title: "Wake timing", value: planSummary.wakeTiming)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Anchor", value: planSummary.anchor)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Wake offset", value: planSummary.wakeOffset)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Reserve before Fajr ends", value: planSummary.reserveBeforeEnd)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Latest wake", value: planSummary.latestWake)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Fasting mornings", value: planSummary.fastingCues)
                }
                AppGroupDivider()
                SettingsRow {
                    SettingsValueRow(title: "Sounds", value: planSummary.sounds)
                }
            }

            SettingsGroup(
                title: "Morning Rules",
                supportingText: "Defaults can be before Fajr or during Fajr."
            ) {
                SettingsRow {
                    Picker("Wake timing", selection: defaultWakeStateBinding) {
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
                            Text("From Fajr end").tag(WakeAnchorType.fajrEnd)
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

                if showsReserveEditor {
                    AppGroupDivider()
                    SettingsRow {
                        Stepper(value: reserveBeforeEndBinding, in: 1...60, step: 1) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reserve before Fajr ends")
                                Text("\(settingsStore.settings.clampedReserveBeforeEndMinutes) min")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    AppGroupDivider()
                    SettingsRow {
                        Text("Keeps enough time before Fajr ends.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                AppGroupDivider()
                SettingsRow {
                    Toggle("Latest wake", isOn: latestWakeCapEnabledBinding)
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
                        Text("Keeps your wake from drifting later through the year.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            SettingsGroup(
                title: "Cues",
                supportingText: "These cues support the same morning plan instead of becoming separate alarm definitions."
            ) {
                SettingsRow {
                    Toggle("Play cue at Fajr start when waking before Fajr", isOn: fajrDefaultBinding)
                }
                AppGroupDivider()
                SettingsRow {
                    Toggle("Use fasting reminder on fasting mornings", isOn: fastingReminderDefaultBinding)
                }

                if alarmConfigStore.defaults.fastingReminderEnabledDefault {
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
                title: "Sounds",
                supportingText: "Sound-role choices and reserve-before-end also live in Settings."
            ) {
                Button {
                    appNavigator.openAlarmBehavior()
                } label: {
                    SettingsRow {
                        SettingsSummaryRow(
                            title: "Alarm Behavior",
                            subtitle: "Edit Pre-Fajr, Fajr-start, during-Fajr, after-Fajr, and fixed-wake sounds.",
                            systemImage: "speaker.wave.3",
                            badgeText: planSummary.sounds,
                            badgeTone: .neutral,
                            showsDisclosureIndicator: true
                        )
                    }
                }
                .buttonStyle(.plain)
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
                if let previewDay {
                    SettingsRow {
                        previewRow(
                            title: "Final wake time",
                            value: TimeFormatters.timeFormatter.string(from: previewDay.decisionLog.resolvedWakeTime)
                        )
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: "Resolved wake type",
                            value: ProductSurfacePresentation.wakeStateLabel(for: previewDay)
                        )
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: "Fajr start time",
                            value: TimeFormatters.timeFormatter.string(from: previewDay.schedule.fajrDate)
                        )
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(
                            title: "Latest wake effect",
                            value: previewCapSummary(for: previewDay)
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

    private var planSummary: DefaultMorningPlanSurfaceSummary {
        ProductSurfaceSnapshots.defaultMorningPlanSummary(
            defaults: alarmConfigStore.defaults,
            settings: settingsStore.settings
        )
    }

    private var previewDay: ActiveAlarmDay? {
        scheduleManager.nextWakeEventSummary?.day
            ?? scheduleManager.activeWindowSnapshot.visibleDays.first(where: {
                !$0.effectiveConfig.skipDay && $0.effectiveConfig.hasAnyEnabled
            })
    }

    private var showsReserveEditor: Bool {
        alarmConfigStore.defaults.defaultWakeState == .inFajr
            && alarmConfigStore.defaults.normalizedDefaultWakeAnchorType == .fajrStart
    }

    private var deltaRowTitle: String {
        switch alarmConfigStore.defaults.defaultWakeState {
        case .preFajr:
            return "Minutes before Fajr"
        case .inFajr:
            return alarmConfigStore.defaults.normalizedDefaultWakeAnchorType == .fajrEnd
                ? "Minutes before Fajr ends"
                : "Minutes after Fajr begins"
        }
    }

    private var deltaSummaryText: String {
        ProductSurfacePresentation.defaultWakeOffsetText(for: alarmConfigStore.defaults)
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
            alarmConfigStore.defaults.fastingReminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var fastingReminderDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.fastingReminderEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.fastingReminderEnabledDefault = newValue
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

    private var reserveBeforeEndBinding: Binding<Int> {
        Binding(get: {
            settingsStore.settings.clampedReserveBeforeEndMinutes
        }, set: { newValue in
            settingsStore.update { draft in
                draft.reserveBeforeEndMinutes = max(1, newValue)
            }
            rescheduleFromDefaults()
        })
    }

    private func defaultWakeStateTitle(_ state: DefaultWakeState) -> String {
        switch state {
        case .preFajr:
            return "Before Fajr"
        case .inFajr:
            return "During Fajr"
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

    private func previewCapSummary(for day: ActiveAlarmDay) -> String {
        if day.decisionLog.latestWakeCapApplied {
            return "Moved earlier by your latest wake"
        }
        return "No cap applied"
    }
}
