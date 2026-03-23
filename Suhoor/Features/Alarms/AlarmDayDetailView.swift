import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timeZone: TimeZone = .current
    @State private var reminderTimeClamped = false
    @State private var showsResetConfirmation = false
    @State private var expandedAlarm: ExpandedAlarm?
    @State private var selectedAbout: FastTagAbout?
    @State private var cachedEditorContext: DayAlarmEditorContext?

    var body: some View {
        configurationList
            .background(Color(.systemGroupedBackground))
            .navigationTitle(GregorianDateFormatter.shared.cardString(for: schedule.date))
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                Strings.AlarmsTab.resetDayTitle,
                isPresented: $showsResetConfirmation
            ) {
                Button(Strings.AlarmsTab.resetDay, role: .destructive) {
                    alarmConfigStore.removeOverride(for: schedule.date, timeZone: timeZone)
                    scheduleManager.requestRescheduleDay(schedule.date)
                }
                Button(Strings.Settings.cancel, role: .cancel) {}
            } message: {
                Text(Strings.AlarmsTab.resetDayMessage)
            }
            .sheet(item: $selectedAbout) { about in
                AboutTagSheet(about: about)
            }
            .task {
                rebuildViewState()
            }
            .onChange(of: alarmConfigStore.currentRevision) { _, _ in
                rebuildViewState()
            }
            .onChange(of: settingsStore.currentRevision) { _, _ in
                rebuildViewState()
            }
            .onChange(of: scheduleManager.currentRevision) { _, _ in
                rebuildViewState()
            }
            .onChange(of: fastTagStore.currentRevision) { _, _ in
                rebuildViewState()
            }
    }

    private var editorContext: DayAlarmEditorContext {
        cachedEditorContext ?? buildEditorContext()
    }

    private var currentSchedule: DaySchedule {
        scheduleManager.activeDay(for: schedule.date, timeZone: timeZone)?.schedule ?? schedule
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(
            settings: settingsStore.settings,
            defaultConfig: alarmConfigStore.defaults,
            overridesByDay: alarmConfigStore.overridesByDay,
            timeZone: timeZone
        )
    }

    private var ruleSummary: RuleSummary {
        editorContext.ruleSummary
    }

    private var effectiveConfig: EffectiveDailyConfig {
        editorContext.effectiveConfig
    }

    private var isSkippingDay: Bool {
        effectiveConfig.skipDay
    }

    private var dayOverride: DailyAlarmOverride? {
        alarmConfigStore.override(for: schedule.date, timeZone: timeZone)
    }

    private var hasOneDayChanges: Bool {
        dayOverride != nil
    }

    private var intentWarnings: [FastWarning] {
        editorContext.intentWarnings
    }

    private var computedIntentSelection: FastIntentSelection {
        editorContext.computedIntentSelection
    }

    private var wakeRuleSelectionBinding: Binding<DayWakeRuleSelection> {
        Binding(get: {
            if let overrideState = dayOverride?.wakeStateOverride {
                return DayWakeRuleSelection(overrideState)
            }
            if dayOverride?.fixedWakeTimeOverrideMinutesFromMidnight != nil || dayOverride?.suhoorTimeOverrideMinutesFromMidnight != nil {
                return .fixedWake
            }
            return .defaultPlan
        }, set: { newValue in
            updateOverride { override in
                switch newValue {
                case .defaultPlan:
                    override.wakeStateOverride = nil
                    override.wakeAnchorTypeOverride = nil
                    override.wakeDeltaOverrideMinutes = nil
                    override.fixedWakeTimeOverrideMinutesFromMidnight = nil
                    override.suhoorOffsetOverrideMinutes = nil
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                case .preFajr:
                    override.wakeStateOverride = .preFajr
                    override.wakeAnchorTypeOverride = .fajrStart
                    override.wakeDeltaOverrideMinutes = override.wakeDeltaOverrideMinutes ?? effectiveConfig.defaultWakeRule.deltaMinutes
                    override.fixedWakeTimeOverrideMinutesFromMidnight = nil
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                case .inFajr:
                    override.wakeStateOverride = .inFajr
                    override.wakeAnchorTypeOverride = override.wakeAnchorTypeOverride == .fajrEnd ? .fajrEnd : .fajrStart
                    override.wakeDeltaOverrideMinutes = override.wakeDeltaOverrideMinutes ?? effectiveConfig.defaultWakeRule.deltaMinutes
                    override.fixedWakeTimeOverrideMinutesFromMidnight = nil
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                case .postFajr:
                    override.wakeStateOverride = .postFajr
                    override.wakeAnchorTypeOverride = .fajrEnd
                    override.wakeDeltaOverrideMinutes = override.wakeDeltaOverrideMinutes ?? 0
                    override.fixedWakeTimeOverrideMinutesFromMidnight = nil
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                case .fixedWake:
                    override.wakeStateOverride = .fixedWake
                    override.wakeAnchorTypeOverride = .clockTime
                    let existingMinutes = override.fixedWakeTimeOverrideMinutesFromMidnight
                        ?? override.suhoorTimeOverrideMinutesFromMidnight
                        ?? minutesFromMidnight(for: currentSchedule.wakeDate)
                    override.fixedWakeTimeOverrideMinutesFromMidnight = existingMinutes
                    override.suhoorTimeOverrideMinutesFromMidnight = existingMinutes
                }
                override.suhoorEnabled = true
            }
        })
    }

    private var wakeAnchorBinding: Binding<WakeAnchorType> {
        Binding(get: {
            dayOverride?.wakeAnchorTypeOverride == .fajrEnd ? .fajrEnd : .fajrStart
        }, set: { newValue in
            updateOverride { override in
                override.wakeAnchorTypeOverride = newValue == .fajrEnd ? .fajrEnd : .fajrStart
                override.wakeStateOverride = .inFajr
                override.suhoorEnabled = true
            }
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
            dayOverride?.wakeDeltaOverrideMinutes
                ?? dayOverride?.suhoorOffsetOverrideMinutes
                ?? effectiveConfig.resolvedWakeRule.deltaMinutes
        }, set: { newValue in
            updateOverride {
                $0.wakeDeltaOverrideMinutes = newValue
                $0.suhoorOffsetOverrideMinutes = newValue
                $0.suhoorEnabled = true
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var suhoorFixedTimeBinding: Binding<Bool> {
        Binding(get: {
            wakeRuleSelectionBinding.wrappedValue == .fixedWake
        }, set: { newValue in
            wakeRuleSelectionBinding.wrappedValue = newValue ? .fixedWake : .preFajr
            clampReminderOffsetIfNeeded()
        })
    }

    private var usesFixedSuhoorTime: Bool {
        wakeRuleSelectionBinding.wrappedValue == .fixedWake
    }

    private var suhoorTimeBinding: Binding<Date> {
        Binding(get: {
            if let overrideMinutes = dayOverride?.fixedWakeTimeOverrideMinutesFromMidnight ?? dayOverride?.suhoorTimeOverrideMinutesFromMidnight {
                return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
            }
            return suhoorTime
        }, set: { newValue in
            updateOverride { override in
                let minutes = minutesFromMidnight(for: newValue)
                override.wakeStateOverride = .fixedWake
                override.fixedWakeTimeOverrideMinutesFromMidnight = minutes
                override.suhoorTimeOverrideMinutesFromMidnight = minutes
                override.suhoorEnabled = true
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
                override.reminderEnabled = true
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
                override.reminderEnabled = true
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
        let minutesBetween = Int(round(currentSchedule.fajrDate.timeIntervalSince(suhoorTime) / 60))
        return max(1, minutesBetween)
    }

    private var reminderOffsetRange: ClosedRange<Int> {
        let lowerBound = min(5, maxReminderOffsetMinutes)
        return lowerBound...maxReminderOffsetMinutes
    }

    private var suhoorTime: Date {
        if let overrideMinutes = effectiveConfig.resolvedWakeRule.fixedWakeTimeMinutesFromMidnight {
            return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        }
        if effectiveConfig.suhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: schedule.date, minutes: effectiveConfig.suhoorOffsetMinutes)
        }
        return ScheduleEventCalculator.wakeDate(
            for: currentSchedule.fajrDate,
            offsetMinutes: effectiveConfig.suhoorOffsetMinutes,
            calendar: calendar
        )
    }

    private var reminderTime: Date? {
        reminderValidationResult?.reminderTime
    }

    private var dayToggleBinding: Binding<Bool> {
        Binding(get: {
            isDayEnabled
        }, set: { newValue in
            setDayEnabled(newValue)
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
                    fajrText: Strings.AlarmsTab.fajrTime(TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)),
                    isOff: primaryDisplayKind == nil,
                    intentSelection: computedIntentSelection,
                    warnings: intentWarnings,
                    onWarningInfo: { warning in
                        selectedAbout = warning.about
                    }
                )
                .padding(.vertical, DesignTokens.rowVerticalPadding)
                .padding(.horizontal, 16)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.secondarySystemGroupedBackground))

            Section {
                Toggle(Strings.AlarmsTab.dayToggleTitle, isOn: dayToggleBinding)
            } header: {
                Text(Strings.AlarmsTab.dayToggleSectionTitle)
                    .textCase(nil)
            } footer: {
                Text(hasOneDayChanges ? Strings.AlarmsTab.dayToggleOverrideFooter : Strings.AlarmsTab.dayToggleDefaultFooter)
            }
            .animation(Motion.standard(reduceMotion: reduceMotion), value: dayToggleBinding.wrappedValue)

            Section {
                Picker("Wake rule", selection: wakeRuleSelectionBinding) {
                    ForEach(DayWakeRuleSelection.allCases) { selection in
                        Text(selection.title).tag(selection)
                    }
                }

                if wakeRuleSelectionBinding.wrappedValue == .inFajr {
                    Picker("Anchor", selection: wakeAnchorBinding) {
                        Text("From Fajr start").tag(WakeAnchorType.fajrStart)
                        Text("Before Fajr end").tag(WakeAnchorType.fajrEnd)
                    }
                }
            } header: {
                Text("Wake Override")
                    .textCase(nil)
            } footer: {
                Text("This changes only this date. Fixed Wake and Post-Fajr stay exceptional.")
            }
            .disabled(!dayToggleBinding.wrappedValue)
            .opacity(dayToggleBinding.wrappedValue ? 1.0 : 0.5)

            Section {
                VStack(spacing: DesignTokens.spacingM) {
                    AlarmTimingEditor(
                        title: Strings.Settings.wakeAlarmLabel,
                        summary: suhoorSummaryText,
                        isEnabled: suhoorEnabledBinding,
                        mode: suhoorTimeModeBinding,
                        relativeValue: suhoorOffsetBinding,
                        fixedTime: suhoorTimeBinding,
                        relativeLabel: wakeDeltaEditorLabel,
                        relativeDetail: Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)),
                        fixedLabel: Strings.AlarmsTab.suhoorTime,
                        fixedDetail: Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)),
                        relativeRange: 0...240,
                        relativeStep: 1,
                        warningText: nil,
                        isExpanded: expandedAlarm == .suhoor,
                        onToggleExpanded: { toggleExpanded(.suhoor) },
                        isDisabled: isSkippingDay
                    )

                    AlarmTimingEditor(
                        title: Strings.Settings.reminderLabel,
                        summary: reminderSummaryText,
                        isEnabled: reminderEnabledBinding,
                        mode: reminderTimeModeBinding,
                        relativeValue: reminderOffsetBinding,
                        fixedTime: reminderFixedTimeBinding,
                        relativeLabel: Strings.AlarmsTab.minutesBeforeFajr,
                        relativeDetail: reminderFooterText,
                        fixedLabel: Strings.Settings.reminderTime,
                        fixedDetail: reminderFooterText,
                        relativeRange: reminderOffsetRange,
                        relativeStep: 5,
                        warningText: reminderTimeClamped || reminderValidationResult?.wasClampedToSuhoor == true
                            ? Strings.Settings.reminderBeforeSuhoorWarning
                            : nil,
                        isExpanded: expandedAlarm == .reminder,
                        onToggleExpanded: { toggleExpanded(.reminder) },
                        isDisabled: isSkippingDay
                    )

                    SettingsEditorCard(
                        title: "Fajr Adhan",
                        subtitle: fajrSummaryText,
                        trailing: AnyView(
                            Toggle("", isOn: fajrEnabledBinding)
                                .labelsHidden()
                        )
                    ) {
                        EmptyView()
                    }
                }
                .padding(.vertical, DesignTokens.textSpacingTight)
            } header: {
                Text(Strings.AlarmsTab.settingsSectionTitle)
                    .textCase(nil)
            } footer: {
                Text(Strings.AlarmsTab.settingsSectionFooter)
            }
            .animation(Motion.standard(reduceMotion: reduceMotion), value: expandedAlarm)
            .disabled(!dayToggleBinding.wrappedValue)
            .opacity(dayToggleBinding.wrappedValue ? 1.0 : 0.5)

            if hasOneDayChanges {
                Section {
                    Button("Reset to Default", role: .destructive) {
                        showsResetConfirmation = true
                    }
                } header: {
                    Text("Reset to Default")
                        .textCase(nil)
                } footer: {
                    Text(Strings.AlarmsTab.resetDayHelper)
                }
            }
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
        return ProductSurfacePresentation.wakeExplanationText(
            for: scheduleManager.activeDay(for: schedule.date, timeZone: timeZone)
                ?? ActiveAlarmDay(
                    date: schedule.date,
                    dateKey: schedule.id,
                    schedule: currentSchedule,
                    effectiveConfig: effectiveConfig,
                    provenances: [],
                    isImplicitRamadan: false,
                    isExplicitOneOff: false,
                    tagResult: .empty,
                    primaryDisplay: effectiveConfig.primaryDisplay(schedule: currentSchedule),
                    sourceSummaryText: "",
                    resolvedDayContext: .standard
                ),
            hasDayOverride: hasOneDayChanges
        )
    }

    private var reminderSummaryText: String {
        guard effectiveConfig.reminderEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        return reminderFooterText
    }

    private var wakeDeltaEditorLabel: String {
        switch wakeRuleSelectionBinding.wrappedValue {
        case .defaultPlan, .preFajr:
            return "Minutes before Fajr starts"
        case .inFajr:
            return wakeAnchorBinding.wrappedValue == .fajrEnd
                ? "Minutes before Fajr ends"
                : "Minutes after Fajr starts"
        case .postFajr:
            return "Minutes after Fajr ends"
        case .fixedWake:
            return "Fixed wake time"
        }
    }

    private var fajrSummaryText: String {
        guard effectiveConfig.fajrEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        return Strings.AlarmsTab.willPlayAt(TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate))
    }

    private func toggleExpanded(_ alarm: ExpandedAlarm) {
        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
            if expandedAlarm == alarm {
                expandedAlarm = nil
            } else {
                expandedAlarm = alarm
            }
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
                for: currentSchedule.fajrDate,
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
        scheduleManager.requestRescheduleDay(schedule.date)
        rebuildEditorContext()
    }

    private func setDayEnabled(_ isEnabled: Bool) {
        alarmConfigStore.setDayEnabled(isEnabled, for: schedule.date, timeZone: timeZone)
        scheduleManager.requestRescheduleDay(schedule.date)
        rebuildEditorContext()
    }

    private var isDayEnabled: Bool {
        !effectiveConfig.skipDay && effectiveConfig.hasAnyEnabled
    }

    private func clampReminderOffsetIfNeeded() {
        guard let override = alarmConfigStore.override(for: schedule.date, timeZone: timeZone),
              let reminderOverride = override.reminderOffsetOverrideMinutes else { return }
        let clamped = min(reminderOverride, maxReminderOffsetMinutes)
        guard clamped != reminderOverride else { return }
        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone) { draft in
            draft.reminderOffsetOverrideMinutes = clamped
        }
        scheduleManager.requestRescheduleDay(schedule.date)
        rebuildEditorContext()
    }

    private func rebuildEditorContext() {
        let token = PerformanceTrace.begin("alarm.day-detail.snapshot", metadata: schedule.id)
        cachedEditorContext = buildEditorContext()
        PerformanceTrace.end(token)
    }

    private func rebuildViewState() {
        rebuildEditorContext()
    }

    private func buildEditorContext() -> DayAlarmEditorContext {
        let summary = ruleEngine.ruleSummary(for: schedule.date)
        let effectiveConfig = alarmConfigStore.effectiveConfig(
            for: schedule.date,
            ruleSummary: summary,
            settings: settingsStore.settings,
            timeZone: timeZone
        )
        let userIntentSelection = fastTagStore.selection(for: schedule.date, timeZone: timeZone) ?? .default
        let activeDay = scheduleManager.activeDay(for: schedule.date, timeZone: timeZone)
        let computedTagResult = activeDay?.tagResult
            ?? scheduleManager.tagPreviewResult(
                for: schedule.date,
                overrideSelection: userIntentSelection.hasMeaningfulTags ? userIntentSelection : nil,
                timeZone: timeZone
            )

        return DayAlarmEditorContext(
            ruleSummary: summary,
            effectiveConfig: effectiveConfig,
            computedIntentSelection: FastIntentSelection(
                primaryIntent: computedTagResult.computedPrimaryIntent,
                secondaryTags: computedTagResult.computedSecondaryTags
            ),
            intentWarnings: FastIntentEngine.warnings(for: schedule.date, timeZone: timeZone)
        )
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
            return TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)
        case .fajr:
            return TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)
        case .iftar:
            return TimeFormatters.timeFormatter.string(from: currentSchedule.iftarDate ?? currentSchedule.maghribDate)
        }
    }

    private var primaryDisplayTime: Date? {
        guard let primaryDisplayKind else { return nil }
        switch primaryDisplayKind {
        case .suhoor:
            return suhoorTime
        case .reminder:
            return reminderTime ?? currentSchedule.fajrDate
        case .fajr:
            return currentSchedule.fajrDate
        case .iftar:
            return currentSchedule.iftarDate ?? currentSchedule.maghribDate
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
        case .iftar:
            return "Iftar / Maghrib"
        }
    }

    private var heroTitleLabel: String {
        guard let primaryDisplayKind else { return Strings.AlarmsTab.alarmOffLabel }
        switch primaryDisplayKind {
        case .suhoor:
            return Strings.Settings.wakeAlarmLabel
        case .reminder:
            return Strings.Settings.reminderLabel
        case .fajr:
            return Strings.AlarmsTab.fajrAdhanLabel
        case .iftar:
            return "Iftar / Maghrib"
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
        if effectiveConfig.iftarEnabled {
            return .iftar
        }
        return nil
    }

    private var fullGregorianDate: String {
        SummaryHeader.fullDateFormatter.string(from: schedule.date)
    }

    private var suhoorTimeModeBinding: Binding<AlarmTimingEditorMode> {
        Binding(get: {
            usesFixedSuhoorTime ? .fixedTime : .beforeFajr
        }, set: { newValue in
            suhoorFixedTimeBinding.wrappedValue = newValue == .fixedTime
        })
    }

    private var reminderTimeModeBinding: Binding<AlarmTimingEditorMode> {
        Binding(get: {
            usesFixedReminderTime ? .fixedTime : .beforeFajr
        }, set: { newValue in
            switch newValue {
            case .fixedTime:
                let reminderDate = reminderTime
                    ?? dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
                reminderFixedTimeBinding.wrappedValue = reminderDate
            case .beforeFajr:
                reminderOffsetBinding.wrappedValue = effectiveConfig.reminderMinutesBeforeFajr
            }
        })
    }
}

private enum ExpandedAlarm {
    case suhoor
    case reminder
}

private enum DayWakeRuleSelection: String, CaseIterable, Identifiable {
    case defaultPlan
    case preFajr
    case inFajr
    case postFajr
    case fixedWake

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultPlan:
            return "Use default plan"
        case .preFajr:
            return "Pre-Fajr"
        case .inFajr:
            return "In-Fajr"
        case .postFajr:
            return "Post-Fajr"
        case .fixedWake:
            return "Fixed Wake"
        }
    }

    init(_ state: MorningWakeRuleState) {
        switch state {
        case .preFajr:
            self = .preFajr
        case .inFajr:
            self = .inFajr
        case .postFajr:
            self = .postFajr
        case .fixedWake:
            self = .fixedWake
        }
    }
}

private struct DayAlarmEditorContext {
    let ruleSummary: RuleSummary
    let effectiveConfig: EffectiveDailyConfig
    let computedIntentSelection: FastIntentSelection
    let intentWarnings: [FastWarning]
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
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                Text(gregorianText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(hijriText)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)

                Text(titleLabel)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: DesignTokens.rowVerticalPadding)

            AppTimeDisplay(
                main: primaryTimeMain,
                suffix: primaryTimeSuffix,
                style: .detail,
                mainWeight: .light,
                suffixWeight: .medium,
                mainColor: isOff ? .secondary : .primary,
                suffixColor: isOff ? .secondary : nil
            )

            Spacer()
                .frame(height: DesignTokens.textSpacingRegular)

            Text(fajrText)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if !tagElements.isEmpty {
                Spacer()
                    .frame(height: DesignTokens.textSpacingMedium)

                FlowLayout(spacing: DesignTokens.textSpacingCompact) {
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
            }
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
        var parts = ["\(titleLabel), \(primaryText).", "\(fajrText)."]
        if !tagElements.isEmpty {
            parts.append("Tags: \(tagElements.joined(separator: ", ")).")
        }
        return parts.joined(separator: " ")
    }

    private var tagElements: [String] {
        var tags: [String] = []
        if intentSelection.primaryIntent != .other || !intentSelection.secondaryTags.isEmpty {
            tags.append(intentSelection.primaryIntent.style.title)
        }
        tags.append(contentsOf: intentSelection.secondaryTags.sorted { $0.title < $1.title }.map(\.title))
        tags.append(contentsOf: warnings.map(\.title))
        return tags
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
        HStack(spacing: DesignTokens.textSpacingTight) {
            FastWarningCapsule(warning: warning)
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(AppTypography.rowMeta)
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
        HStack(spacing: DesignTokens.textSpacingTight) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(font)
            }
            if !useIconOnly {
                Text(displayText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .font(font)
        .foregroundStyle(foregroundColor)
        .padding(.vertical, DesignTokens.badgeVerticalPadding)
        .padding(.horizontal, DesignTokens.badgeHorizontalPadding)
        .background(background)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .accessibilityLabel(title)
    }

    private var displayText: String {
        shortTitle.isEmpty ? title : shortTitle
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

}

private struct ScheduleSourcePresentation: Identifiable {
    let provenance: ResolvedScheduledDateProvenance
    let title: String
    let subtitle: String

    var id: String { provenance.id }

    nonisolated init(provenance: ResolvedScheduledDateProvenance) {
        self.provenance = provenance
        self.title = provenance.label
        self.subtitle = Self.subtitle(for: provenance)
    }

    private static func subtitle(for provenance: ResolvedScheduledDateProvenance) -> String {
        switch provenance.sourceOrigin {
        case .defaultDailyPlan:
            return "This date is included by your default daily morning plan."
        case .manualSingleDay:
            return Strings.AlarmsTab.sourceManualHelper
        case .defaultRamadan:
            return "This date is included automatically during Ramadan."
        case .manualGregorianRange:
            return "This date is included because it falls inside a saved date range."
        case .recurringIslamic(let rule):
            return "This date is included because it matches your \(rule.title) recurring schedule."
        case .islamicQuickAdd(let kind):
            return "This date comes from the saved \(kind.title.lowercased()) schedule."
        case .migratedLegacyAlways:
            return "This date is included because it falls inside a migrated 60-day date range."
        case .migratedLegacyDateRange:
            return "This date is included because it falls inside a migrated date range."
        }
    }
}

private struct SourceManagementActionPresentation {
    let title: String
    let subtitle: String

    nonisolated init(provenance: ResolvedScheduledDateProvenance) {
        self.title = provenance.stopSeriesLabel ?? "Stop this schedule"
        self.subtitle = Self.subtitle(for: provenance)
    }

    private static func subtitle(for provenance: ResolvedScheduledDateProvenance) -> String {
        switch provenance.sourceOrigin {
        case .defaultDailyPlan:
            return "Adjust the default daily morning plan from Plans."
        case .manualGregorianRange:
            return "Removes every date that came from this saved date range."
        case .recurringIslamic(let rule):
            return "Stops adding future dates from your \(rule.title) recurring schedule."
        case .islamicQuickAdd(let kind):
            return "Removes the saved \(kind.title.lowercased()) schedule that created this date."
        case .migratedLegacyAlways:
            return "Removes the migrated 60-day date range that created this date."
        case .migratedLegacyDateRange:
            return "Removes the migrated date range that created this date."
        case .defaultRamadan:
            return "Removes the schedule that created this date."
        case .manualSingleDay:
            return "Removes the schedule that created this date."
        }
    }
}

private struct ScheduleSourceCard: View {
    let presentation: ScheduleSourcePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
            Text(presentation.title)
                .font(AppTypography.rowTitle)
                .foregroundStyle(.primary)
            Text(presentation.subtitle)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DesignTokens.accessoryInset)
    }
}

private struct DetailActionButton: View {
    let title: String
    let subtitle: String
    var tint: Color? = nil
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                Text(title)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(foregroundStyle)
                Text(subtitle)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.accessoryInset)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var foregroundStyle: Color {
        if role == .destructive {
            return .red
        }
        return tint ?? .primary
    }
}

private func suppressionScope(for provenance: ResolvedScheduledDateProvenance) -> SuppressionScope {
    if let groupID = provenance.groupID {
        return .groupID(groupID)
    }
    return .sourceID(provenance.sourceID)
}
