import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    private let timeZone: TimeZone = .current
    @State private var reminderTimeClamped = false
    @State private var showsResetConfirmation = false
    @State private var expandedAlarm: ExpandedAlarm?
    @State private var dayEnabledSnapshot: DayEnabledSnapshot?
    @State private var showsTagPicker = false
    @State private var selectedAbout: FastTagAbout?

    var body: some View {
        configurationList
            .background(Color(.systemGroupedBackground))
        .navigationTitle(GregorianDateFormatter.shared.cardString(for: schedule.date))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reset this day to defaults?",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.AlarmsTab.resetDay, role: .destructive) {
                alarmConfigStore.removeOverride(for: schedule.date, timeZone: timeZone)
                Task { await scheduleManager.rescheduleDay(schedule.date) }
            }
            Button(Strings.Settings.cancel, role: .cancel) {}
        }
        .sheet(isPresented: $showsTagPicker) {
            NavigationStack {
                FastTagPickerSheet(
                    date: schedule.date,
                    initialSelection: userIntentSelection,
                    schedules: scheduleManager.schedules,
                    selections: fastTagStore.selections,
                    onSave: { selection in
                        fastTagStore.setSelection(selection, for: schedule.date, timeZone: timeZone)
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedAbout) { about in
            AboutTagSheet(about: about)
        }
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settingsStore.settings, configStore: alarmConfigStore, timeZone: timeZone)
    }

    private var effectiveConfig: EffectiveDailyConfig {
        alarmConfigStore.effectiveConfig(
            for: schedule.date,
            ruleSummary: ruleEngine.ruleSummary(for: schedule.date),
            settings: settingsStore.settings,
            timeZone: timeZone
        )
    }

    private var isSkippingDay: Bool {
        effectiveConfig.skipDay
    }

    private var skipBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.skipDay ?? false
        }, set: { newValue in
            updateOverride { $0.skipDay = newValue }
        })
    }

    private var userIntentSelection: FastIntentSelection {
        fastTagStore.selection(for: schedule.date, timeZone: timeZone) ?? .default
    }

    private var intentWarnings: [FastWarning] {
        FastIntentEngine.warnings(for: schedule.date, timeZone: timeZone)
    }

    private var computedTagResult: TagComputationResult {
        let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
        let results = TagComputationEngine.results(
            schedules: scheduleManager.schedules,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: timeZone
        )
        if let result = results[key] {
            return result
        }
        return TagComputationEngine.result(
            for: schedule.date,
            schedules: scheduleManager.schedules,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: userIntentSelection.hasMeaningfulTags ? userIntentSelection : nil
        )
    }

    private var computedIntentSelection: FastIntentSelection {
        FastIntentSelection(
            primaryIntent: computedTagResult.computedPrimaryIntent,
            secondaryTags: computedTagResult.computedSecondaryTags
        )
    }

    private var intentSummaryText: String {
        var parts: [String] = [computedIntentSelection.primaryIntent.shortTitle]
        let secondary = computedIntentSelection.secondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map { $0.shortTitle }.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            !skipBinding.wrappedValue
        }, set: { newValue in
            updateOverride { $0.skipDay = !newValue }
        })
    }

    private var suhoorEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.suhoorEnabled
        }, set: { newValue in
            updateOverride { $0.suhoorEnabled = newValue }
        })
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.reminderEnabled
        }, set: { newValue in
            updateOverride { $0.reminderEnabled = newValue }
        })
    }

    private var fajrEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.fajrEnabled
        }, set: { newValue in
            updateOverride { $0.fajrEnabled = newValue }
        })
    }

    private var suhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorOffsetOverrideMinutes
                ?? ruleEngine.ruleSummary(for: schedule.date).finalOffsetMinutes
        }, set: { newValue in
            updateOverride { $0.suhoorOffsetOverrideMinutes = newValue }
            clampReminderOffsetIfNeeded()
        })
    }

    private var suhoorFixedTimeBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight != nil
        }, set: { newValue in
            updateOverride { override in
                if newValue {
                    override.suhoorTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: schedule.wakeDate)
                } else {
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                }
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var usesFixedSuhoorTime: Bool {
        alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight != nil
    }

    private var suhoorTimeBinding: Binding<Date> {
        Binding(get: {
            if let overrideMinutes = alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight {
                return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
            }
            return suhoorTime
        }, set: { newValue in
            updateOverride { override in
                override.suhoorTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: newValue)
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var reminderOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderOffsetOverrideMinutes
                ?? effectiveConfig.reminderMinutesBeforeFajr
        }, set: { newValue in
            let clamped = min(newValue, maxReminderOffsetMinutes)
            updateOverride { override in
                override.reminderOffsetOverrideMinutes = clamped
                override.reminderTimeOverrideMinutesFromMidnight = nil
            }
            reminderTimeClamped = clamped != newValue
        })
    }

    private var reminderFixedTimeBinding: Binding<Date> {
        Binding(get: {
            if let overrideMinutes = alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderTimeOverrideMinutesFromMidnight {
                return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
            }
            return dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
        }, set: { newValue in
            let validation = TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: newValue)
            updateOverride { override in
                override.reminderTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: validation.reminderTime)
                override.reminderOffsetOverrideMinutes = nil
            }
            reminderTimeClamped = validation.wasClampedToSuhoor
        })
    }

    private var reminderFooterText: String {
        if !effectiveConfig.reminderEnabled {
            return Strings.AlarmsTab.reminderOff
        }
        if let reminderDate = reminderTime {
            return Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: reminderDate))
        }
        return Strings.AlarmsTab.reminderOff
    }

    private var maxReminderOffsetMinutes: Int {
        let minutesBetween = Int(round(schedule.fajrDate.timeIntervalSince(suhoorTime) / 60))
        return max(1, minutesBetween)
    }

    private var reminderOffsetRange: ClosedRange<Int> {
        let lowerBound = min(5, maxReminderOffsetMinutes)
        return lowerBound...maxReminderOffsetMinutes
    }

    private var suhoorTime: Date {
        if let overrideMinutes = effectiveConfig.suhoorTimeOverrideMinutesFromMidnight {
            return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        }
        if effectiveConfig.suhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: schedule.date, minutes: effectiveConfig.suhoorOffsetMinutes)
        }
        return ScheduleEventCalculator.wakeDate(
            for: schedule.fajrDate,
            offsetMinutes: effectiveConfig.suhoorOffsetMinutes,
            calendar: calendar
        )
    }

    private var reminderTime: Date? {
        reminderValidationResult?.reminderTime
    }

    private var dayToggleBinding: Binding<Bool> {
        Binding(get: {
            dayActiveBinding.wrappedValue
        }, set: { newValue in
            if newValue {
                restoreDayEnabledStates()
            } else {
                dayEnabledSnapshot = DayEnabledSnapshot(
                    suhoorEnabled: effectiveConfig.suhoorEnabled,
                    reminderEnabled: effectiveConfig.reminderEnabled,
                    fajrEnabled: effectiveConfig.fajrEnabled
                )
                updateOverride { $0.skipDay = true }
            }
        })
    }

    private var configurationList: some View {
        List {
            Section {
                SummaryHeader(
                    gregorianText: fullGregorianDate,
                    hijriText: HijriDateFormatter.shared.string(from: schedule.date),
                    primaryText: primaryDisplayText,
                    primaryTime: primaryDisplayTime,
                    titleLabel: heroTitleLabel,
                    fajrText: Strings.AlarmsTab.fajrTime(TimeFormatters.timeFormatter.string(from: schedule.fajrDate)),
                    isOff: primaryDisplayKind == nil,
                    intentSelection: computedIntentSelection,
                    warnings: intentWarnings,
                    onWarningInfo: { warning in
                        selectedAbout = warning.about
                    }
                )
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.secondarySystemGroupedBackground))

            Section {
                Button {
                    showsTagPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Tags")
                                .foregroundStyle(.primary)
                            Text(intentSummaryText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Intent")
                    .textCase(nil)
            }

            Section {
                Toggle("Enable this day", isOn: dayToggleBinding)
            } header: {
                Text("Day")
                    .textCase(nil)
            } footer: {
                Text(Strings.AlarmsTab.dayDisabledHelper)
            }
            .animation(.easeInOut(duration: 0.2), value: dayToggleBinding.wrappedValue)

            Section {
                expandableAlarmRow(
                    title: "Suhoor Alarm",
                    subtitle: suhoorSummaryText,
                    isExpanded: expandedAlarm == .suhoor,
                    onToggleExpanded: { toggleExpanded(.suhoor) },
                    toggle: Toggle(isOn: suhoorEnabledBinding) { EmptyView() }
                )

                if effectiveConfig.suhoorEnabled && expandedAlarm == .suhoor {
                    Picker(Strings.AlarmsTab.timeModeLabel, selection: suhoorTimeModeBinding) {
                        ForEach(DayTimeMode.allCases) { mode in
                            Text(mode.displayLabel).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                    .disabled(isSkippingDay)

                    if usesFixedSuhoorTime {
                        DatePicker(
                            selection: suhoorTimeBinding,
                            displayedComponents: [.hourAndMinute]
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.AlarmsTab.suhoorTime)
                                Text(Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isSkippingDay)
                    } else {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.AlarmsTab.minutesBeforeFajr)
                                Text(Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    stepValue(suhoorOffsetBinding, delta: -5, range: 5...240)
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .controlSize(.mini)
                                Text("\(suhoorOffsetBinding.wrappedValue)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Button {
                                    stepValue(suhoorOffsetBinding, delta: 5, range: 5...240)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .controlSize(.mini)
                            }
                            .disabled(isSkippingDay)
                        }
                    }
                }

                expandableAlarmRow(
                    title: "Reminder Alarm",
                    subtitle: reminderSummaryText,
                    isExpanded: expandedAlarm == .reminder,
                    onToggleExpanded: { toggleExpanded(.reminder) },
                    toggle: Toggle(isOn: reminderEnabledBinding) { EmptyView() }
                )

                if effectiveConfig.reminderEnabled && expandedAlarm == .reminder {
                    Picker(Strings.AlarmsTab.timeModeLabel, selection: reminderTimeModeBinding) {
                        ForEach(DayTimeMode.allCases) { mode in
                            Text(mode.displayLabel).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                    .disabled(isSkippingDay)

                    if usesFixedReminderTime {
                        DatePicker(
                            selection: reminderFixedTimeBinding,
                            displayedComponents: [.hourAndMinute]
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Settings.reminderTime)
                                if let reminderTime {
                                    Text(Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: reminderTime)))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(isSkippingDay)
                    } else {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.AlarmsTab.minutesBeforeFajr)
                                Text(reminderFooterText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    stepValue(reminderOffsetBinding, delta: -5, range: reminderOffsetRange)
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .controlSize(.mini)
                                Text("\(reminderOffsetBinding.wrappedValue)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Button {
                                    stepValue(reminderOffsetBinding, delta: 5, range: reminderOffsetRange)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .controlSize(.mini)
                            }
                            .disabled(isSkippingDay)
                        }
                    }

                    if reminderTimeClamped || reminderValidationResult?.wasClampedToSuhoor == true {
                        Text(Strings.Settings.reminderBeforeSuhoorWarning)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                staticAlarmRow(
                    title: "Fajr Adhan",
                    subtitle: fajrSummaryText,
                    toggle: Toggle(isOn: fajrEnabledBinding) { EmptyView() }
                )
            } header: {
                Text("Alarms")
                    .textCase(nil)
            }
            .animation(.easeInOut(duration: 0.2), value: expandedAlarm)
            .disabled(!dayToggleBinding.wrappedValue)
            .opacity(dayToggleBinding.wrappedValue ? 1.0 : 0.5)

            Section {
                Button(Strings.AlarmsTab.resetDay, role: .destructive) {
                    showsResetConfirmation = true
                }
            } header: {
                Text("Reset")
                    .textCase(nil)
            }
            .disabled(!dayToggleBinding.wrappedValue)
            .opacity(dayToggleBinding.wrappedValue ? 1.0 : 0.5)
        }
        .listStyle(.insetGrouped)
        .onChange(of: dayToggleBinding.wrappedValue) { _, newValue in
            if !newValue {
                expandedAlarm = nil
            }
        }
    }

    private var suhoorSummaryText: String {
        guard effectiveConfig.suhoorEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        return Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime))
    }

    private var reminderSummaryText: String {
        guard effectiveConfig.reminderEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        return reminderFooterText
    }

    private var fajrSummaryText: String {
        guard effectiveConfig.fajrEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        return Strings.AlarmsTab.willPlayAt(TimeFormatters.timeFormatter.string(from: schedule.fajrDate))
    }

    private func toggleExpanded(_ alarm: ExpandedAlarm) {
        if expandedAlarm == alarm {
            expandedAlarm = nil
        } else {
            expandedAlarm = alarm
        }
    }

    private func stepValue(_ binding: Binding<Int>, delta: Int, range: ClosedRange<Int>) {
        let newValue = min(max(binding.wrappedValue + delta, range.lowerBound), range.upperBound)
        binding.wrappedValue = newValue
    }

    private func restoreDayEnabledStates() {
        if let snapshot = dayEnabledSnapshot {
            updateOverride { override in
                override.skipDay = false
                override.suhoorEnabled = snapshot.suhoorEnabled
                override.reminderEnabled = snapshot.reminderEnabled
                override.fajrEnabled = snapshot.fajrEnabled
            }
        } else {
            updateOverride { $0.skipDay = false }
        }
    }

    private var usesFixedReminderTime: Bool {
        if alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderTimeOverrideMinutesFromMidnight != nil {
            return true
        }
        return effectiveConfig.reminderTimeMode == .fixedTime
    }

    private var reminderValidationResult: TimeValidationResult? {
        guard effectiveConfig.reminderEnabled else { return nil }
        let reminderDate: Date
        if let overrideMinutes = effectiveConfig.reminderTimeOverrideMinutesFromMidnight {
            reminderDate = dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        } else if effectiveConfig.reminderTimeMode == .fixedTime {
            reminderDate = dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
        } else {
            reminderDate = ScheduleEventCalculator.reminderDate(
                for: schedule.fajrDate,
                reminderMinutes: effectiveConfig.reminderMinutesBeforeFajr,
                calendar: calendar
            )
        }
        return TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: reminderDate)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func updateOverride(_ update: (inout DailyAlarmOverride) -> Void) {
        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone, update: update)
        Task { await scheduleManager.rescheduleDay(schedule.date) }
    }

    private func clampReminderOffsetIfNeeded() {
        guard let override = alarmConfigStore.override(for: schedule.date, timeZone: timeZone),
              let reminderOverride = override.reminderOffsetOverrideMinutes else { return }
        let clamped = min(reminderOverride, maxReminderOffsetMinutes)
        guard clamped != reminderOverride else { return }
        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone) { draft in
            draft.reminderOffsetOverrideMinutes = clamped
        }
        Task { await scheduleManager.rescheduleDay(schedule.date) }
    }

    private func minutesFromMidnight(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return max(0, Int(round(date.timeIntervalSince(start) / 60)))
    }

    private func dateFromMidnight(for day: Date, minutes: Int) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    private var primaryDisplayText: String {
        guard let primaryDisplayKind else { return Strings.AlarmList.offLabel }
        switch primaryDisplayKind {
        case .suhoor:
            return TimeFormatters.timeFormatter.string(from: suhoorTime)
        case .reminder:
            if let reminderTime {
                return TimeFormatters.timeFormatter.string(from: reminderTime)
            }
            return TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
        case .fajr:
            return TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
        }
    }

    private var primaryDisplayTime: Date? {
        guard let primaryDisplayKind else { return nil }
        switch primaryDisplayKind {
        case .suhoor:
            return suhoorTime
        case .reminder:
            return reminderTime ?? schedule.fajrDate
        case .fajr:
            return schedule.fajrDate
        }
    }

    private var primaryDisplayLabel: String {
        guard let primaryDisplayKind else { return Strings.AlarmsTab.alarmOffLabel }
        switch primaryDisplayKind {
        case .suhoor:
            return Strings.AlarmsTab.suhoorLabel
        case .reminder:
            return Strings.AlarmsTab.reminderLabel
        case .fajr:
            return Strings.AlarmsTab.fajrAdhanLabel
        }
    }

    private var heroTitleLabel: String {
        guard let primaryDisplayKind else { return Strings.AlarmsTab.alarmOffLabel }
        switch primaryDisplayKind {
        case .suhoor:
            return "Suhoor Alarm"
        case .reminder:
            return "Reminder Alarm"
        case .fajr:
            return Strings.AlarmsTab.fajrAdhanLabel
        }
    }

    private var primaryDisplayKind: PrimaryDisplayKind? {
        if effectiveConfig.suhoorEnabled {
            return .suhoor
        }
        if effectiveConfig.reminderEnabled {
            return .reminder
        }
        if effectiveConfig.fajrEnabled {
            return .fajr
        }
        return nil
    }

    private var fullGregorianDate: String {
        SummaryHeader.fullDateFormatter.string(from: schedule.date)
    }

    private var suhoorTimeModeBinding: Binding<DayTimeMode> {
        Binding(get: {
            usesFixedSuhoorTime ? .fixed : .beforeFajr
        }, set: { newValue in
            suhoorFixedTimeBinding.wrappedValue = newValue == .fixed
        })
    }

    private var reminderTimeModeBinding: Binding<DayTimeMode> {
        Binding(get: {
            usesFixedReminderTime ? .fixed : .beforeFajr
        }, set: { newValue in
            switch newValue {
            case .fixed:
                let reminderDate = reminderTime
                    ?? dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
                reminderFixedTimeBinding.wrappedValue = reminderDate
            case .beforeFajr:
                reminderOffsetBinding.wrappedValue = effectiveConfig.reminderMinutesBeforeFajr
            }
        })
    }
}

private enum DayTimeMode: String, CaseIterable, Identifiable {
    case beforeFajr
    case fixed

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .beforeFajr:
            return Strings.AlarmsTab.beforeFajrLabel
        case .fixed:
            return Strings.AlarmsTab.fixedTimeLabel
        }
    }
}

private extension AlarmDayDetailView {
    @ViewBuilder
    func expandableAlarmRow(
        title: String,
        subtitle: String,
        isExpanded: Bool,
        onToggleExpanded: @escaping () -> Void,
        toggle: Toggle<EmptyView>
    ) -> some View {
        HStack(spacing: 12) {
            Button(action: onToggleExpanded) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            toggle
                .labelsHidden()
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func staticAlarmRow(
        title: String,
        subtitle: String,
        toggle: Toggle<EmptyView>
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            toggle
                .labelsHidden()
        }
    }
}

private enum ExpandedAlarm {
    case suhoor
    case reminder
}

private struct DayEnabledSnapshot {
    let suhoorEnabled: Bool
    let reminderEnabled: Bool
    let fajrEnabled: Bool
}

private struct SummaryHeader: View {
    let gregorianText: String
    let hijriText: String
    let primaryText: String
    let primaryTime: Date?
    let titleLabel: String
    let fajrText: String
    let isOff: Bool
    let intentSelection: FastIntentSelection
    let warnings: [FastWarning]
    let onWarningInfo: (FastWarning) -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 42

    private static let timeMainFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let timeSuffixFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(gregorianText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(hijriText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(titleLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 6) {
                FastPrimaryIntentCapsule(intent: intentSelection.primaryIntent)
                ForEach(intentSelection.secondaryTags.sorted { $0.title < $1.title }, id: \.self) { tag in
                    FastSecondaryTagCapsule(tag: tag)
                }
                ForEach(warnings, id: \.self) { warning in
                    WarningChipWithInfo(
                        warning: warning,
                        onInfo: { onWarningInfo(warning) }
                    )
                }
            }
            .padding(.top, 8)

            Spacer()
                .frame(height: 12)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(primaryTimeMain)
                    .font(.system(size: timeFontSize, weight: .light))
                    .foregroundStyle(isOff ? .secondary : .primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)

                if let primaryTimeSuffix {
                    Text(primaryTimeSuffix)
                        .font(.system(size: timeFontSize * 0.6, weight: .medium))
                        .foregroundStyle(isOff ? .secondary : .primary)
                        .opacity(isOff ? 1 : 0.84)
                        .baselineOffset(1)
                }
            }

            Spacer()
                .frame(height: 7)

            Text(fajrText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var primaryTimeMain: String {
        if let primaryTime {
            return SummaryHeader.timeMainFormatter.string(from: primaryTime)
        }
        return primaryText
    }

    private var primaryTimeSuffix: String? {
        guard let primaryTime else { return nil }
        return SummaryHeader.timeSuffixFormatter.string(from: primaryTime)
    }

    private var accessibilitySummary: String {
        "\(titleLabel), \(primaryText). \(fajrText)."
    }
}
private struct FastPrimaryIntentCapsule: View {
    let intent: FastPrimaryIntent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let style = intent.style
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        CapsuleLabelView(
            title: style.title,
            shortTitle: style.shortTitle,
            systemImage: style.systemImage,
            color: style.color,
            prominence: .strong,
            useIconOnly: isAccessibility
        )
    }
}

private struct FastSecondaryTagCapsule: View {
    let tag: FastSecondaryVirtueTag
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let style = tag.style
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        CapsuleLabelView(
            title: style.title,
            shortTitle: style.shortTitle,
            systemImage: style.systemImage,
            color: style.color,
            prominence: .subtle,
            useIconOnly: isAccessibility
        )
    }
}

private struct WarningChipWithInfo: View {
    let warning: FastWarning
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            FastWarningCapsule(warning: warning)
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(warning.title)")
        }
    }
}

private struct FastWarningCapsule: View {
    let warning: FastWarning
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CapsuleLabelView(
            title: warning.title,
            shortTitle: warning.title,
            systemImage: warning.systemImage,
            color: .red,
            prominence: .outline,
            useIconOnly: dynamicTypeSize.isAccessibilitySize
        )
        .accessibilityLabel(warning.title)
    }
}

private struct CapsuleLabelView: View {
    enum Prominence {
        case strong
        case subtle
        case outline
    }

    let title: String
    let shortTitle: String
    let systemImage: String?
    let color: Color
    let prominence: Prominence
    let useIconOnly: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            labelView(text: title, allowText: true)
            labelView(text: shortTitle, allowText: true)
            labelView(text: "", allowText: false)
        }
        .font(font)
        .foregroundStyle(foregroundColor)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(background)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .accessibilityLabel(title)
    }

    private var font: Font {
        switch prominence {
        case .strong:
            return .caption.weight(.semibold)
        case .subtle, .outline:
            return .caption2.weight(.semibold)
        }
    }

    private var foregroundColor: Color {
        switch prominence {
        case .outline:
            return .red
        case .strong, .subtle:
            return color
        }
    }

    private var background: some View {
        Group {
            switch prominence {
            case .strong:
                color.opacity(0.22)
            case .subtle:
                color.opacity(0.14)
            case .outline:
                Color.clear
            }
        }
    }

    private var borderColor: Color {
        switch prominence {
        case .strong:
            return color.opacity(0.4)
        case .subtle:
            return color.opacity(0.25)
        case .outline:
            return Color.red.opacity(0.6)
        }
    }

    private var borderWidth: CGFloat {
        switch prominence {
        case .outline:
            return 0.8
        case .strong, .subtle:
            return 0.6
        }
    }

    @ViewBuilder
    private func labelView(text: String, allowText: Bool) -> some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            if allowText, !text.isEmpty, !useIconOnly {
                Text(text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }
}
