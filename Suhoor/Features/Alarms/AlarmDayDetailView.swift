import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timeZone: TimeZone = .current
    @State private var reminderTimeClamped = false
    @State private var showsResetConfirmation = false
    @State private var showsExclusionDialog = false
    @State private var expandedAlarm: ExpandedAlarm?
    @State private var showsTagPicker = false
    @State private var selectedAbout: FastTagAbout?
    @State private var cachedEditorContext: DayAlarmEditorContext?
    @State private var cachedTagPickerSeeds: [ActiveTagComputationSeed] = []

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
            .confirmationDialog(
                "Exclude this date from which schedule?",
                isPresented: $showsExclusionDialog,
                titleVisibility: .visible
            ) {
                ForEach(stoppableProvenances, id: \.id) { provenance in
                    Button("Exclude from \(provenance.label)") {
                        Task {
                            await scheduleManager.skipScheduledDate(
                                schedule.date,
                                scope: suppressionScope(for: provenance)
                            )
                            dismiss()
                        }
                    }
                }
                Button(Strings.Settings.cancel, role: .cancel) {}
            }
            .sheet(isPresented: $showsTagPicker) {
                NavigationStack {
                    FastTagPickerSheet(
                        date: schedule.date,
                        initialSelection: userIntentSelection,
                        seeds: cachedTagPickerSeeds,
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

    private var hasOneDayChanges: Bool {
        alarmConfigStore.override(for: schedule.date, timeZone: timeZone) != nil
    }

    private var userIntentSelection: FastIntentSelection {
        editorContext.userIntentSelection
    }

    private var intentWarnings: [FastWarning] {
        editorContext.intentWarnings
    }

    private var computedIntentSelection: FastIntentSelection {
        editorContext.computedIntentSelection
    }

    private var sourceProvenances: [ResolvedScheduledDateProvenance] {
        editorContext.sourceProvenances
    }

    private var explicitSourceProvenances: [ResolvedScheduledDateProvenance] {
        sourceProvenances.filter(\.isExplicitOneOff)
    }

    private var stoppableProvenances: [ResolvedScheduledDateProvenance] {
        var seen = Set<String>()
        return sourceProvenances.filter { provenance in
            guard provenance.canStopSeries else { return false }
            let key = "\(provenance.groupID?.uuidString ?? provenance.sourceID.uuidString)-\(provenance.stopSeriesLabel ?? "")"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    private var intentSummaryText: String {
        var parts: [String] = [computedIntentSelection.primaryIntent.shortTitle]
        let secondary = computedIntentSelection.secondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map { $0.shortTitle }.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private var sourcePresentations: [ScheduleSourcePresentation] {
        sourceProvenances.map(ScheduleSourcePresentation.init)
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            isDayEnabled
        }, set: { newValue in
            setDayEnabled(newValue)
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

    private var iftarEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.iftarEnabled
        }, set: { newValue in
            updateOverride { $0.iftarEnabled = newValue }
        })
    }

    private var iftarNotificationBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.iftarDelivery.notification
        }, set: { newValue in
            updateOverride { override in
                let base = override.iftarDeliveryOverride ?? effectiveConfig.iftarDelivery
                override.iftarDeliveryOverride = IftarDeliverySelection(
                    notification: newValue,
                    alarm: base.alarm,
                    adhan: base.adhan
                ).normalized()
            }
        })
    }

    private var iftarAlarmBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.iftarDelivery.normalized().alarm
        }, set: { newValue in
            updateOverride { override in
                let base = override.iftarDeliveryOverride ?? effectiveConfig.iftarDelivery
                override.iftarDeliveryOverride = IftarDeliverySelection(
                    notification: base.notification,
                    alarm: newValue,
                    adhan: base.adhan
                ).normalized()
            }
        })
    }

    private var iftarAdhanBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.iftarDelivery.normalized().adhan
        }, set: { newValue in
            updateOverride { override in
                let base = override.iftarDeliveryOverride ?? effectiveConfig.iftarDelivery
                override.iftarDeliveryOverride = IftarDeliverySelection(
                    notification: base.notification,
                    alarm: base.alarm,
                    adhan: newValue
                ).normalized()
            }
        })
    }

    private var suhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorOffsetOverrideMinutes
                ?? ruleSummary.finalOffsetMinutes
        }, set: { newValue in
            updateOverride {
                $0.suhoorOffsetOverrideMinutes = newValue
                $0.suhoorEnabled = true
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var suhoorFixedTimeBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight != nil
        }, set: { newValue in
            updateOverride { override in
                if newValue {
                    override.suhoorTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: currentSchedule.wakeDate)
                    override.suhoorEnabled = true
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
        if let overrideMinutes = effectiveConfig.suhoorTimeOverrideMinutesFromMidnight {
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
                            Text("Shape this morning's meaning")
                                .foregroundStyle(.primary)
                            Text(intentSummaryText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                if canQuickMarkFastingDay {
                    Button("Mark as Fasting Day") {
                        fastTagStore.setSelection(
                            FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
                            for: schedule.date,
                            timeZone: timeZone
                        )
                        rebuildViewState()
                    }
                }
            } header: {
                Text("Morning meaning")
                    .textCase(nil)
            } footer: {
                Text("Use this to make the date a fasting morning, Qada morning, or another meaningful morning.")
            }

            Section {
                Toggle("Keep this morning active", isOn: dayToggleBinding)
            } header: {
                Text("This morning only")
                    .textCase(nil)
            } footer: {
                Text(hasOneDayChanges ? "This morning is using date-specific changes." : "This morning is using your default morning plan.")
            }
            .animation(Motion.standard(reduceMotion: reduceMotion), value: dayToggleBinding.wrappedValue)

            Section {
                VStack(spacing: DesignTokens.spacingM) {
                    AlarmTimingEditor(
                        title: Strings.Settings.wakeAlarmLabel,
                        summary: suhoorSummaryText,
                        isEnabled: suhoorEnabledBinding,
                        mode: suhoorTimeModeBinding,
                        relativeValue: suhoorOffsetBinding,
                        fixedTime: suhoorTimeBinding,
                        relativeLabel: Strings.AlarmsTab.minutesBeforeFajr,
                        relativeDetail: Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)),
                        fixedLabel: Strings.AlarmsTab.suhoorTime,
                        fixedDetail: Strings.AlarmsTab.willRingAt(TimeFormatters.timeFormatter.string(from: suhoorTime)),
                        relativeRange: 5...240,
                        relativeStep: 5,
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

                    SettingsEditorCard(
                        title: "Iftar / Maghrib",
                        subtitle: iftarSummaryText,
                        trailing: AnyView(
                            Toggle("", isOn: iftarEnabledBinding)
                                .labelsHidden()
                        ),
                        isExpanded: expandedAlarm == .iftar,
                        onToggleExpanded: { toggleExpanded(.iftar) }
                    ) {
                        if effectiveConfig.iftarEnabled {
                            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                                Text("Calculated from sunset. Adjust globally from Prayer times.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Toggle("Notification", isOn: iftarNotificationBinding)
                                    .disabled(isSkippingDay || !effectiveConfig.iftarEnabled)
                                Toggle("Alarm", isOn: iftarAlarmBinding)
                                    .disabled(isSkippingDay || !effectiveConfig.iftarEnabled)
                                Toggle("Adhan", isOn: iftarAdhanBinding)
                                    .disabled(isSkippingDay || !effectiveConfig.iftarEnabled)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Wake sequence")
                    .textCase(nil)
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

            if !sourcePresentations.isEmpty {
                Section {
                    ForEach(sourcePresentations) { presentation in
                        ScheduleSourceCard(presentation: presentation)
                    }
                } header: {
                    Text("Why This Morning")
                        .textCase(nil)
                }
            }

            if !explicitSourceProvenances.isEmpty || !stoppableProvenances.isEmpty {
                Section {
                    if !explicitSourceProvenances.isEmpty {
                        DetailActionButton(
                            title: Strings.AlarmsTab.sourceDeleteDay,
                            subtitle: Strings.AlarmsTab.sourceDeleteDayHelper,
                            role: .destructive
                        ) {
                            Task {
                                await scheduleManager.deleteExplicitScheduledDate(schedule.date)
                                dismiss()
                            }
                        }
                    }

                    if !stoppableProvenances.isEmpty {
                        DetailActionButton(
                            title: Strings.AlarmsTab.sourceDayExclusion,
                            subtitle: Strings.AlarmsTab.sourceDayExclusionHelper,
                            tint: DawnColor.accent
                        ) {
                            if stoppableProvenances.count == 1, let provenance = stoppableProvenances.first {
                                Task {
                                    await scheduleManager.skipScheduledDate(
                                        schedule.date,
                                        scope: suppressionScope(for: provenance)
                                    )
                                    dismiss()
                                }
                            } else {
                                showsExclusionDialog = true
                            }
                        }

                        ForEach(stoppableProvenances, id: \.id) { provenance in
                            let actionPresentation = SourceManagementActionPresentation(provenance: provenance)
                            DetailActionButton(
                                title: actionPresentation.title,
                                subtitle: actionPresentation.subtitle,
                                role: .destructive
                            ) {
                                Task {
                                    await scheduleManager.stopSeries(for: provenance)
                                    dismiss()
                                }
                            }
                        }
                    }
                } header: {
                    Text("Adjust Planned Source")
                        .textCase(nil)
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
        return Strings.AlarmsTab.willPlayAt(TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate))
    }

    private var iftarSummaryText: String {
        guard effectiveConfig.iftarEnabled, dayToggleBinding.wrappedValue else {
            return Strings.AlarmList.offLabel
        }
        let timeText = TimeFormatters.timeFormatter.string(from: currentSchedule.iftarDate ?? currentSchedule.maghribDate)
        return "\(effectiveConfig.iftarDelivery.summaryText) · \(timeText)"
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
        cachedTagPickerSeeds = scheduleManager.activeWindowSnapshot.visibleDays.map(\.tagSeed)
        rebuildEditorContext()
    }

    private var canQuickMarkFastingDay: Bool {
        intentWarnings.isEmpty && computedIntentSelection.primaryIntent == .other
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
            userIntentSelection: userIntentSelection,
            computedIntentSelection: FastIntentSelection(
                primaryIntent: computedTagResult.computedPrimaryIntent,
                secondaryTags: computedTagResult.computedSecondaryTags
            ),
            intentWarnings: FastIntentEngine.warnings(for: schedule.date, timeZone: timeZone),
            sourceProvenances: activeDay?.provenances ?? scheduleManager.provenance(for: schedule.date, timeZone: timeZone)
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
    case iftar
}

private struct DayAlarmEditorContext {
    let ruleSummary: RuleSummary
    let effectiveConfig: EffectiveDailyConfig
    let userIntentSelection: FastIntentSelection
    let computedIntentSelection: FastIntentSelection
    let intentWarnings: [FastWarning]
    let sourceProvenances: [ResolvedScheduledDateProvenance]
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

            if !tagElements.isEmpty {
                Spacer()
                    .frame(height: 10)

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
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            if !useIconOnly {
                Text(displayText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.title)
                .foregroundStyle(.primary)
            Text(presentation.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(foregroundStyle)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
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
