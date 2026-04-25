import SwiftUI

struct DefaultAlarmsSettingsView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @State private var draftDefaults = DefaultAlarmConfig.default
    @State private var draftSettings = AppSettings.default
    @State private var hasPendingCommit = false
    @State private var commitTask: Task<Void, Never>?

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(
                title: "Summary",
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
                supportingText: "Set the usual relationship between your wake and Fajr."
            ) {
                SettingsRow {
                    Picker("Wake timing", selection: defaultWakeStateBinding) {
                        ForEach(DefaultWakeState.allCases) { state in
                            Text(defaultWakeStateTitle(state)).tag(state)
                        }
                    }
                }

                if draftDefaults.defaultWakeState == .inFajr {
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
                                Text("\(normalizedDraftSettings.clampedReserveBeforeEndMinutes) min")
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

                if draftDefaults.defaultLatestWakeCapMinutesFromMidnight != nil {
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
                supportingText: "These cues support the same morning instead of becoming separate wake setups."
            ) {
                SettingsRow {
                    Toggle("Play cue at Fajr start when waking before Fajr", isOn: fajrDefaultBinding)
                }
                AppGroupDivider()
                SettingsRow {
                    Toggle("Use fasting reminder on fasting mornings", isOn: fastingReminderDefaultBinding)
                }

                if draftDefaults.fastingReminderEnabledDefault {
                    AppGroupDivider()
                    SettingsRow {
                        Stepper(value: reminderDefaultOffsetBinding, in: 1...180, step: 1) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder lead")
                                Text("\(draftDefaults.defaultReminderMinutesBeforeFajr) min before Fajr")
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

                if draftSettings.snoozeEnabled {
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
                supportingText: "Wake sounds and reserve-before-end live in Settings."
            ) {
                Button {
                    appNavigator.openAlarmBehavior()
                } label: {
                    SettingsRow {
                        SettingsSummaryRow(
                            title: "Wake Sounds & Reserve",
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
        .task {
            loadDraftFromStores()
        }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in
            guard !hasPendingCommit else { return }
            loadDraftFromStores()
        }
        .onChange(of: settingsStore.currentRevision) { _, _ in
            guard !hasPendingCommit else { return }
            loadDraftFromStores()
        }
        .onDisappear {
            applyDraftIfNeeded()
        }
    }

    private var validationResult: DefaultWakeRuleValidationResult? {
        scheduleManager.defaultWakeValidation()
    }

    private var planSummary: DefaultMorningPlanSurfaceSummary {
        ProductSurfaceSnapshots.defaultMorningPlanSummary(
            defaults: normalizedDraftDefaults,
            settings: normalizedDraftSettings
        )
    }

    private var previewDay: ActiveAlarmDay? {
        scheduleManager.nextWakeEventSummary?.day
            ?? scheduleManager.activeWindowSnapshot.visibleDays.first(where: {
                !$0.effectiveConfig.skipDay && $0.effectiveConfig.hasAnyEnabled
            })
    }

    private var showsReserveEditor: Bool {
        draftDefaults.defaultWakeState == .inFajr
            && draftDefaults.normalizedDefaultWakeAnchorType == .fajrStart
    }

    private var deltaRowTitle: String {
        switch draftDefaults.defaultWakeState {
        case .preFajr:
            return "Minutes before Fajr"
        case .inFajr:
            return draftDefaults.normalizedDefaultWakeAnchorType == .fajrEnd
                ? "Minutes before Fajr ends"
                : "Minutes after Fajr begins"
        }
    }

    private var deltaSummaryText: String {
        ProductSurfacePresentation.defaultWakeOffsetText(for: normalizedDraftDefaults)
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
            draftDefaults.defaultWakeState
        }, set: { newValue in
            draftDefaults.defaultWakeState = newValue
            if newValue == .preFajr {
                draftDefaults.defaultWakeAnchorType = .fajrStart
            }
            commitWakeRuleEdit()
        })
    }

    private var defaultWakeAnchorBinding: Binding<WakeAnchorType> {
        Binding(get: {
            draftDefaults.normalizedDefaultWakeAnchorType
        }, set: { newValue in
            draftDefaults.defaultWakeAnchorType = newValue == .fajrEnd ? .fajrEnd : .fajrStart
            commitWakeRuleEdit()
        })
    }

    private var wakeDeltaBinding: Binding<Int> {
        Binding(get: {
            draftDefaults.defaultWakeDeltaMinutes
        }, set: { newValue in
            draftDefaults.defaultWakeDeltaMinutes = max(0, newValue)
            commitWakeRuleEdit()
        })
    }

    private var latestWakeCapEnabledBinding: Binding<Bool> {
        Binding(get: {
            draftDefaults.defaultLatestWakeCapMinutesFromMidnight != nil
        }, set: { newValue in
            if newValue {
                draftDefaults.defaultLatestWakeCapMinutesFromMidnight
                    = draftDefaults.defaultLatestWakeCapMinutesFromMidnight
                    ?? DateHelpers.minutesFromMidnight(for: Date(), timeZone: .current)
            } else {
                draftDefaults.defaultLatestWakeCapMinutesFromMidnight = nil
            }
            rescheduleFromDefaults()
        })
    }

    private var latestWakeCapBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(
                for: Date(),
                minutes: draftDefaults.defaultLatestWakeCapMinutesFromMidnight
                    ?? DateHelpers.minutesFromMidnight(for: Date(), timeZone: .current)
            )
        }, set: { newValue in
            draftDefaults.defaultLatestWakeCapMinutesFromMidnight = minutesFromMidnight(for: newValue)
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
            draftDefaults.reminderEnabledDefault
        }, set: { newValue in
            draftDefaults.reminderEnabledDefault = newValue
            draftDefaults.fastingReminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var fastingReminderDefaultBinding: Binding<Bool> {
        Binding(get: {
            draftDefaults.fastingReminderEnabledDefault
        }, set: { newValue in
            draftDefaults.fastingReminderEnabledDefault = newValue
            draftDefaults.reminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultOffsetBinding: Binding<Int> {
        Binding(get: {
            draftDefaults.defaultReminderMinutesBeforeFajr
        }, set: { newValue in
            draftDefaults.defaultReminderMinutesBeforeFajr = max(1, newValue)
            rescheduleFromDefaults()
        })
    }

    private var fajrDefaultBinding: Binding<Bool> {
        Binding(get: {
            draftDefaults.fajrEnabledDefault
        }, set: { newValue in
            draftDefaults.fajrEnabledDefault = newValue
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
            draftSettings.snoozeEnabled
        }, set: { newValue in
            draftSettings.snoozeEnabled = newValue
            rescheduleFromDefaults()
        })
    }

    private var wakeFollowUpMinutesBinding: Binding<Int> {
        Binding(get: {
            draftSettings.snoozeMinutes
        }, set: { newValue in
            draftSettings.snoozeMinutes = newValue
            rescheduleFromDefaults()
        })
    }

    private var reserveBeforeEndBinding: Binding<Int> {
        Binding(get: {
            normalizedDraftSettings.clampedReserveBeforeEndMinutes
        }, set: { newValue in
            draftSettings.reserveBeforeEndMinutes = max(1, newValue)
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
        draftDefaults.defaultSuhoorTimeMode = .relativeToFajrMinusMinutes
        draftDefaults.defaultSuhoorOffsetMinutes = draftDefaults.defaultWakeDeltaMinutes
        rescheduleFromDefaults()
    }

    private func rescheduleFromDefaults() {
        scheduleDraftCommit()
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

    private var normalizedDraftDefaults: DefaultAlarmConfig {
        var defaults = draftDefaults
        defaults.defaultSuhoorTimeMode = .relativeToFajrMinusMinutes
        defaults.defaultSuhoorOffsetMinutes = defaults.defaultWakeDeltaMinutes
        if defaults.defaultWakeState == .preFajr {
            defaults.defaultWakeAnchorType = .fajrStart
        }
        defaults.fastingReminderEnabledDefault = defaults.reminderEnabledDefault
        return defaults
    }

    private var normalizedDraftSettings: AppSettings {
        var settings = draftSettings
        settings.reserveBeforeEndMinutes = max(1, settings.reserveBeforeEndMinutes)
        return settings
    }

    private func loadDraftFromStores() {
        draftDefaults = alarmConfigStore.defaults
        draftSettings = settingsStore.settings
    }

    private func scheduleDraftCommit() {
        hasPendingCommit = true
        commitTask?.cancel()
        commitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            applyDraftIfNeeded()
        }
    }

    private func applyDraftIfNeeded() {
        commitTask?.cancel()
        commitTask = nil

        let nextDefaults = normalizedDraftDefaults
        let nextSettings = normalizedDraftSettings
        let defaultsChanged = alarmConfigStore.defaults != nextDefaults
        let settingsChanged = settingsStore.settings != nextSettings

        if defaultsChanged {
            alarmConfigStore.defaults = nextDefaults
        }
        if settingsChanged {
            settingsStore.set(nextSettings)
        }

        hasPendingCommit = false
        if defaultsChanged || settingsChanged {
            scheduleManager.requestRefresh(reason: .settingsChanged)
        }
    }
}
