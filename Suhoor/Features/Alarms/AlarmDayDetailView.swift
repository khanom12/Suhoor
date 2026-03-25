import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    private let timeZone: TimeZone = .current
    @State private var showsResetConfirmation = false
    @State private var showsTagPicker = false
    @State private var showsAdvancedDetails = false
    @State private var showsCueDetails = false
    @State private var selectedAbout: FastTagAbout?
    @State private var cachedEditorContext: DayAlarmEditorContext?
    @State private var wakeSelectionDraft: DayWakeRuleSelection = .defaultPlan
    @State private var wakeAnchorDraft: WakeAnchorType = .fajrStart
    @State private var wakeDeltaDraft = 0
    @State private var fixedWakeMinutesDraft = 0
    @State private var hasPendingEditorCommit = false
    @State private var editorCommitTask: Task<Void, Never>?

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
                    resetDateToDefault()
                }
                Button(Strings.Settings.cancel, role: .cancel) {}
            } message: {
                Text(Strings.AlarmsTab.resetDayMessage)
            }
            .sheet(isPresented: $showsTagPicker) {
                NavigationStack {
                    FastTagPickerSheet(
                        date: schedule.date,
                        initialSelection: storedIntentSelection,
                        seeds: scheduleManager.activeWindowSnapshot.visibleDays.map(\.tagSeed),
                        selections: fastTagStore.selections,
                        onSave: { selection in
                            fastTagStore.setSelection(selection, for: schedule.date, timeZone: timeZone)
                            scheduleManager.requestRescheduleDay(schedule.date)
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
                loadEditorDraft()
            }
            .onChange(of: alarmConfigStore.currentRevision) { _, _ in
                rebuildViewState()
                guard !hasPendingEditorCommit else { return }
                loadEditorDraft()
            }
            .onChange(of: settingsStore.currentRevision) { _, _ in
                rebuildViewState()
                guard !hasPendingEditorCommit else { return }
                loadEditorDraft()
            }
            .onChange(of: scheduleManager.currentRevision) { _, _ in
                rebuildViewState()
                guard !hasPendingEditorCommit else { return }
                loadEditorDraft()
            }
            .onChange(of: fastTagStore.currentRevision) { _, _ in
                rebuildViewState()
            }
            .onDisappear {
                applyEditorDraftIfNeeded()
            }
    }

    private var editorContext: DayAlarmEditorContext {
        cachedEditorContext ?? buildEditorContext()
    }

    private var currentSchedule: DaySchedule {
        editorContext.presentationDay.schedule
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

    private var hasWakeRuleOverride: Bool {
        currentWakeSelection != .defaultPlan
    }

    private var detailAvailabilityPresentation: WakeAvailabilityPresentation {
        ProductSurfacePresentation.wakeAvailabilityPresentation(
            for: presentationDay,
            hasCustomChange: hasWakeRuleOverride
        )
    }

    private var shouldShowWakeControls: Bool {
        !isSkippingDay
    }

    private var shouldShowResetSection: Bool {
        hasWakeRuleOverride
    }

    private var shouldShowCueDisclosure: Bool {
        guard shouldShowWakeControls else { return false }
        guard !derivedCueRows.isEmpty else { return false }

        switch presentationDay.decisionLog.plannedWakeState {
        case .preFajr:
            return true
        case .inFajr:
            return effectiveConfig.reminderEnabled || effectiveConfig.iftarEnabled
        case .postFajr, .fixedWake:
            return effectiveConfig.iftarEnabled
        }
    }

    private var intentWarnings: [FastWarning] {
        editorContext.intentWarnings
    }

    private var computedIntentSelection: FastIntentSelection {
        editorContext.computedIntentSelection
    }

    private var storedIntentSelection: FastIntentSelection {
        fastTagStore.selection(for: schedule.date, timeZone: timeZone) ?? .default
    }

    private var presentationDay: ActiveAlarmDay {
        editorContext.presentationDay
    }

    private var wakeReasonRows: [WakeReasonRow] {
        ProductSurfacePresentation.wakeReasonRows(
            for: presentationDay,
            hasDayOverride: hasOneDayChanges
        )
    }

    private var wakeRuleSelectionBinding: Binding<DayWakeRuleSelection> {
        Binding(get: {
            wakeSelectionDraft
        }, set: { newValue in
            let previousSelection = wakeSelectionDraft
            wakeSelectionDraft = newValue
            switch newValue {
            case .defaultPlan:
                break
            case .preFajr:
                wakeAnchorDraft = .fajrStart
                if previousSelection != .preFajr {
                    wakeDeltaDraft = currentWakeDelta
                }
            case .inFajr:
                if wakeAnchorDraft == .clockTime {
                    wakeAnchorDraft = effectiveConfig.defaultWakeRule.anchorType ?? .fajrStart
                }
                wakeAnchorDraft = wakeAnchorDraft == .fajrEnd ? .fajrEnd : .fajrStart
                if previousSelection != .inFajr {
                    wakeDeltaDraft = currentWakeDelta
                }
            case .postFajr:
                wakeAnchorDraft = .fajrEnd
            case .fixedWake:
                if previousSelection != .fixedWake {
                    fixedWakeMinutesDraft = currentFixedWakeMinutes
                }
            }
            scheduleEditorCommit()
        })
    }

    private var wakeAnchorBinding: Binding<WakeAnchorType> {
        Binding(get: {
            wakeAnchorDraft == .fajrEnd ? .fajrEnd : .fajrStart
        }, set: { newValue in
            wakeAnchorDraft = newValue == .fajrEnd ? .fajrEnd : .fajrStart
            wakeSelectionDraft = .inFajr
            scheduleEditorCommit()
        })
    }

    private var suhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            wakeDeltaDraft
        }, set: { newValue in
            wakeDeltaDraft = newValue
            scheduleEditorCommit()
        })
    }

    private var suhoorTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: schedule.date, minutes: fixedWakeMinutesDraft)
        }, set: { newValue in
            fixedWakeMinutesDraft = minutesFromMidnight(for: newValue)
            wakeSelectionDraft = .fixedWake
            scheduleEditorCommit()
        })
    }

    private var maxReminderOffsetMinutes: Int {
        let minutesBetween = Int(round(currentSchedule.fajrDate.timeIntervalSince(suhoorTime) / 60))
        return max(1, minutesBetween)
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

    private var configurationList: some View {
        List {
            Section {
                SummaryHeader(
                    gregorianText: fullGregorianDate,
                    hijriText: HijriDateFormatter.shared.string(from: schedule.date),
                    meaningSummaryText: dayMeaningSummaryText,
                    primaryText: primaryDisplayText,
                    primaryTime: primaryDisplayTime,
                    fajrText: Strings.AlarmsTab.fajrTime(TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)),
                    isOff: isSkippingDay,
                    summaryText: heroSummaryText,
                    summaryDetailText: heroSummaryDetailText,
                    intentSelection: computedIntentSelection,
                    warnings: intentWarnings,
                    onWarningInfo: { warning in
                        selectedAbout = warning.about
                    }
                )
                .padding(.vertical, DesignTokens.spacingS)
                .padding(.horizontal, 12)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.secondarySystemGroupedBackground))

            if isSkippingDay {
                Section {
                    HStack(alignment: .center) {
                        Button("Restore this date") {
                            restoreSkippedDate()
                        }
                        .font(AppTypography.metricLabel)
                        .appControlStyle(.quiet)

                        Spacer(minLength: 0)
                    }
                }
            }

            Section {
                Button {
                    showsTagPicker = true
                } label: {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                            Text(dayMeaningSummaryText)
                                .font(AppTypography.rowTitle)
                                .foregroundStyle(.primary)

                            Text("Edit day meaning")
                                .font(AppTypography.metricLabel)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: DesignTokens.spacingS)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Day meaning")
                    .textCase(nil)
            }

            if shouldShowWakeControls {
                Section {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(wakeEditorStatusText)
                            .font(AppTypography.metricLabel)
                            .foregroundStyle(.secondary)

                        WakeModeSelector(selection: wakeRuleSelectionBinding)

                        switch wakeRuleSelectionBinding.wrappedValue {
                        case .defaultPlan:
                            if let wakeEditorNoteText {
                                dayDetailInfoRow(
                                    title: "Latest wake",
                                    detail: wakeEditorNoteText
                                )
                            }
                        case .preFajr:
                            Stepper(value: suhoorOffsetBinding, in: 0...240, step: 1) {
                                VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                                    Text("Minutes before Fajr")
                                    Text(wakeDraftSummaryText)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        case .inFajr:
                            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                                WakeAnchorSelector(selection: wakeAnchorBinding)

                                Stepper(value: suhoorOffsetBinding, in: 0...240, step: 1) {
                                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                                        Text(wakeDeltaEditorLabel)
                                        Text(wakeDraftSummaryText)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if let wakeEditorNoteText {
                                    Text(wakeEditorNoteText)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        case .postFajr:
                            Stepper(value: suhoorOffsetBinding, in: 0...240, step: 1) {
                                VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                                    Text("Minutes after Fajr ends")
                                    Text(wakeDraftSummaryText)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let wakeEditorNoteText {
                                Text(wakeEditorNoteText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        case .fixedWake:
                            DatePicker(
                                "Fixed wake time",
                                selection: suhoorTimeBinding,
                                displayedComponents: [.hourAndMinute]
                            )

                            if let wakeEditorNoteText {
                                Text(wakeEditorNoteText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Wake for this date")
                        .textCase(nil)
                }
            }

            Section {
                ForEach(wakeReasonRows) { row in
                    dayDetailInfoRow(title: row.title, detail: row.detail)
                }
            } header: {
                Text("Why this morning")
                    .textCase(nil)
            }

            Section {
                DisclosureGroup("Advanced", isExpanded: $showsAdvancedDetails) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        if shouldShowCueDisclosure {
                            DisclosureGroup("Extra cues", isExpanded: $showsCueDetails) {
                                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                                    ForEach(derivedCueRows) { row in
                                        dayDetailInfoRow(title: row.title, detail: row.detail)
                                    }
                                }
                                .padding(.top, DesignTokens.textSpacingCompact)
                            }
                        }

                        dayDetailInfoRow(
                            title: "Source",
                            detail: changePlannedSourceText
                        )

                        if shouldShowResetSection {
                            Button("Remove wake change", role: .destructive) {
                                showsResetConfirmation = true
                            }
                        }

                        if !isSkippingDay {
                            Button("Skip this date", role: .destructive) {
                                skipDate()
                            }
                        }
                    }
                    .padding(.top, DesignTokens.textSpacingCompact)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var dayMeaningSummaryText: String {
        let primary = computedIntentSelection.primaryIntent
        let secondary = computedIntentSelection.secondaryTags.sorted { $0.title < $1.title }

        var parts: [String] = []
        if primary != .other {
            parts.append(primary.about.title)
        } else {
            parts.append(ProductSurfacePresentation.ordinaryDaySummaryText)
        }
        if !secondary.isEmpty {
            parts.append(secondary.map(\.title).joined(separator: " • "))
        }
        if effectiveConfig.tahajjudRefinement {
            parts.append("Tahajjud")
        }
        return parts.joined(separator: " • ")
    }

    private var wakeEditorStatusText: String {
        switch wakeRuleSelectionBinding.wrappedValue {
        case .defaultPlan:
            return "Follows your usual plan"
        case .postFajr:
            return "After Fajr for this date"
        case .fixedWake:
            return "Fixed wake for this date"
        case .preFajr, .inFajr:
            return hasWakeRuleOverride ? "Changed for this date" : "Follows your usual plan"
        }
    }

    private var wakeEditorNoteText: String? {
        switch wakeRuleSelectionBinding.wrappedValue {
        case .defaultPlan:
            guard presentationDay.decisionLog.latestWakeCapApplied else { return nil }
            return "Moved earlier by your latest wake."
        case .inFajr:
            guard wakeAnchorBinding.wrappedValue == .fajrStart else { return nil }
            return "Leaves time before Fajr ends."
        case .postFajr:
            return "Available for this date only."
        case .fixedWake:
            return "This fixed time ignores your latest wake."
        case .preFajr:
            return nil
        }
    }

    private var derivedCueRows: [WakeReasonRow] {
        let wakeTimeText = TimeFormatters.timeFormatter.string(from: presentationDay.decisionLog.resolvedWakeTime)
        var rows: [WakeReasonRow] = []

        switch presentationDay.decisionLog.plannedWakeState {
        case .preFajr:
            rows.append(
                WakeReasonRow(
                    id: "primary-wake",
                    title: "Wake",
                    detail: "Set for \(wakeTimeText) before Fajr."
                )
            )
            if effectiveConfig.reminderEnabled, let reminderTime {
                rows.append(
                    WakeReasonRow(
                        id: "fasting-reminder",
                        title: "Fasting reminder",
                        detail: "Reminder at \(TimeFormatters.timeFormatter.string(from: reminderTime)) on fasting mornings."
                    )
                )
            }
            if effectiveConfig.fajrEnabled {
                rows.append(
                    WakeReasonRow(
                        id: "fajr-start",
                        title: "At Fajr start",
                        detail: "If the wake is still active, the Fajr-start sound takes over."
                    )
                )
            }
        case .inFajr:
            rows.append(
                WakeReasonRow(
                    id: "primary-wake",
                    title: "Wake",
                    detail: "Set for \(wakeTimeText) during Fajr."
                )
            )
        case .postFajr:
            rows.append(
                WakeReasonRow(
                    id: "primary-wake",
                    title: "Wake",
                    detail: "Set for \(wakeTimeText) after Fajr."
                )
            )
        case .fixedWake:
            rows.append(
                WakeReasonRow(
                    id: "primary-wake",
                    title: "Wake",
                    detail: "Set for \(wakeTimeText)."
                )
            )
        }

        if effectiveConfig.iftarEnabled && computedIntentSelection.primaryIntent != .other {
            rows.append(
                WakeReasonRow(
                    id: "iftar",
                    title: "Sunset cue",
                    detail: "Stays on for this fasting day."
                )
            )
        }

        return rows
    }

    private var changePlannedSourceText: String {
        ProductSurfacePresentation.wakeSourceSummaryText(for: presentationDay)
    }

    @ViewBuilder
    private func dayDetailInfoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
            Text(title)
                .font(AppTypography.rowTitle)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DesignTokens.space2)
    }

    private var wakeDeltaEditorLabel: String {
        switch wakeRuleSelectionBinding.wrappedValue {
        case .defaultPlan, .preFajr:
            return "Minutes before Fajr"
        case .inFajr:
            return wakeAnchorBinding.wrappedValue == .fajrEnd
                ? "Minutes before Fajr ends"
                : "Minutes after Fajr begins"
        case .postFajr:
            return "Minutes after Fajr ends"
        case .fixedWake:
            return "Fixed wake time"
        }
    }

    private var wakeDraftSummaryText: String {
        switch wakeSelectionDraft {
        case .defaultPlan:
            return ProductSurfacePresentation.wakeOffsetText(for: presentationDay)
        case .preFajr:
            return ProductSurfacePresentation.wakeOffsetText(
                state: .preFajr,
                anchor: .fajrStart,
                deltaMinutes: wakeDeltaDraft,
                fixedTimeMinutes: nil
            )
        case .inFajr:
            return ProductSurfacePresentation.wakeOffsetText(
                state: .inFajr,
                anchor: wakeAnchorDraft == .fajrEnd ? .fajrEnd : .fajrStart,
                deltaMinutes: wakeDeltaDraft,
                fixedTimeMinutes: nil
            )
        case .postFajr:
            return ProductSurfacePresentation.wakeOffsetText(
                state: .postFajr,
                anchor: .fajrEnd,
                deltaMinutes: wakeDeltaDraft,
                fixedTimeMinutes: nil
            )
        case .fixedWake:
            return ProductSurfacePresentation.wakeOffsetText(
                state: .fixedWake,
                anchor: .clockTime,
                deltaMinutes: 0,
                fixedTimeMinutes: fixedWakeMinutesDraft
            )
        }
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

    private func setDayEnabled(_ isEnabled: Bool) {
        alarmConfigStore.setDayEnabled(isEnabled, for: schedule.date, timeZone: timeZone)
        scheduleManager.requestRescheduleDay(schedule.date)
    }

    private func skipDate() {
        applyEditorDraftIfNeeded()
        setDayEnabled(false)
    }

    private func restoreSkippedDate() {
        setDayEnabled(true)
    }

    private func resetDateToDefault() {
        editorCommitTask?.cancel()
        editorCommitTask = nil
        hasPendingEditorCommit = false
        alarmConfigStore.removeOverride(for: schedule.date, timeZone: timeZone)
        scheduleManager.requestRescheduleDay(schedule.date)
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
    }

    private func loadEditorDraft() {
        wakeSelectionDraft = currentWakeSelection
        wakeAnchorDraft = currentWakeAnchor
        wakeDeltaDraft = currentWakeDelta
        fixedWakeMinutesDraft = currentFixedWakeMinutes
    }

    private func scheduleEditorCommit() {
        hasPendingEditorCommit = true
        editorCommitTask?.cancel()
        editorCommitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            applyEditorDraftIfNeeded()
        }
    }

    private func applyEditorDraftIfNeeded() {
        editorCommitTask?.cancel()
        editorCommitTask = nil

        let wakeChanged = wakeSelectionDraft != currentWakeSelection
            || wakeAnchorDraft != currentWakeAnchor
            || wakeDeltaDraft != currentWakeDelta
            || fixedWakeMinutesDraft != currentFixedWakeMinutes

        hasPendingEditorCommit = false
        guard wakeChanged else { return }

        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone) { override in
            applyWakeDraft(to: &override)
        }

        clampReminderOffsetIfNeeded()
        scheduleManager.requestRescheduleDay(schedule.date)
    }

    private func applyWakeDraft(to override: inout DailyAlarmOverride) {
        switch wakeSelectionDraft {
        case .defaultPlan:
            override.wakeStateOverride = nil
            override.wakeAnchorTypeOverride = nil
            override.wakeDeltaOverrideMinutes = nil
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.suhoorEnabled = nil
        case .preFajr:
            override.wakeStateOverride = .preFajr
            override.wakeAnchorTypeOverride = .fajrStart
            override.wakeDeltaOverrideMinutes = wakeDeltaDraft
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = wakeDeltaDraft
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.suhoorEnabled = true
        case .inFajr:
            override.wakeStateOverride = .inFajr
            override.wakeAnchorTypeOverride = wakeAnchorDraft == .fajrEnd ? .fajrEnd : .fajrStart
            override.wakeDeltaOverrideMinutes = wakeDeltaDraft
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = wakeDeltaDraft
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.suhoorEnabled = true
        case .postFajr:
            override.wakeStateOverride = .postFajr
            override.wakeAnchorTypeOverride = .fajrEnd
            override.wakeDeltaOverrideMinutes = wakeDeltaDraft
            override.fixedWakeTimeOverrideMinutesFromMidnight = nil
            override.suhoorOffsetOverrideMinutes = wakeDeltaDraft
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.suhoorEnabled = true
        case .fixedWake:
            override.wakeStateOverride = .fixedWake
            override.wakeAnchorTypeOverride = .clockTime
            override.wakeDeltaOverrideMinutes = nil
            override.fixedWakeTimeOverrideMinutesFromMidnight = fixedWakeMinutesDraft
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = fixedWakeMinutesDraft
            override.suhoorEnabled = true
        }
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
        let resolvedSchedule = activeDay?.schedule ?? schedule
        let computedTagResult = activeDay?.tagResult
            ?? scheduleManager.tagPreviewResult(
                for: schedule.date,
                overrideSelection: userIntentSelection.hasMeaningfulTags ? userIntentSelection : nil,
                timeZone: timeZone
            )
        let presentationDay = activeDay
            ?? ActiveAlarmDay(
                date: schedule.date,
                dateKey: schedule.id,
                schedule: resolvedSchedule,
                effectiveConfig: effectiveConfig,
                provenances: [],
                isImplicitRamadan: false,
                isExplicitOneOff: false,
                tagResult: .empty,
                primaryDisplay: effectiveConfig.primaryDisplay(schedule: resolvedSchedule),
                sourceSummaryText: "",
                resolvedDayContext: .standard
            )

        return DayAlarmEditorContext(
            ruleSummary: summary,
            effectiveConfig: effectiveConfig,
            presentationDay: presentationDay,
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

    private var currentWakeSelection: DayWakeRuleSelection {
        if let overrideState = dayOverride?.wakeStateOverride {
            return DayWakeRuleSelection(overrideState)
        }
        if dayOverride?.fixedWakeTimeOverrideMinutesFromMidnight != nil
            || dayOverride?.suhoorTimeOverrideMinutesFromMidnight != nil {
            return .fixedWake
        }
        return .defaultPlan
    }

    private var currentWakeAnchor: WakeAnchorType {
        if let anchor = dayOverride?.wakeAnchorTypeOverride {
            return anchor == .fajrEnd ? .fajrEnd : anchor == .clockTime ? .clockTime : .fajrStart
        }
        return effectiveConfig.resolvedWakeRule.anchorType ?? .fajrStart
    }

    private var currentWakeDelta: Int {
        dayOverride?.wakeDeltaOverrideMinutes
            ?? dayOverride?.suhoorOffsetOverrideMinutes
            ?? effectiveConfig.resolvedWakeRule.deltaMinutes
    }

    private var currentFixedWakeMinutes: Int {
        dayOverride?.fixedWakeTimeOverrideMinutesFromMidnight
            ?? dayOverride?.suhoorTimeOverrideMinutesFromMidnight
            ?? minutesFromMidnight(for: currentSchedule.wakeDate)
    }

    private var primaryDisplayText: String {
        if isSkippingDay {
            return heroSummaryText
        }
        guard let primaryDisplayKind else { return heroSummaryText }
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

    private var heroSummaryText: String {
        if isSkippingDay {
            return detailAvailabilityPresentation.statusSummary
        }

        switch presentationDay.decisionLog.plannedWakeState {
        case .fixedWake:
            return hasWakeRuleOverride ? "Fixed wake for this date" : "Fixed wake"
        case .postFajr:
            return hasWakeRuleOverride ? "After Fajr for this date" : "After Fajr"
        case .preFajr, .inFajr:
            return ProductSurfacePresentation.wakeStateLabel(for: presentationDay)
        }
    }

    private var heroSummaryDetailText: String? {
        if isSkippingDay {
            return detailAvailabilityPresentation.statusDetail
        }
        return nil
    }

    private var primaryDisplayTime: Date? {
        guard !isSkippingDay else { return nil }
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
            return "Use default"
        case .preFajr:
            return "Before Fajr"
        case .inFajr:
            return "During Fajr"
        case .postFajr:
            return "After Fajr"
        case .fixedWake:
            return "Fixed wake"
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

private struct WakeModeSelector: View {
    @Binding var selection: DayWakeRuleSelection

    var body: some View {
        FlowLayout(spacing: DesignTokens.textSpacingCompact) {
            ForEach(DayWakeRuleSelection.allCases) { option in
                WakeChoiceChip(
                    title: option.title,
                    isSelected: selection == option
                ) {
                    selection = option
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Wake timing")
    }
}

private struct WakeAnchorSelector: View {
    @Binding var selection: WakeAnchorType

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
            Text("Anchor")
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)

            HStack(spacing: DesignTokens.spacingS) {
                WakeChoiceChip(
                    title: "From Fajr start",
                    isSelected: selection == .fajrStart
                ) {
                    selection = .fajrStart
                }

                WakeChoiceChip(
                    title: "From Fajr end",
                    isSelected: selection == .fajrEnd
                ) {
                    selection = .fajrEnd
                }
            }
        }
    }
}

private struct WakeChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? DawnColor.accent : Color.primary.opacity(0.82))
                .padding(.horizontal, DesignTokens.space10)
                .padding(.vertical, DesignTokens.space8)
                .background(
                    Capsule()
                        .fill(isSelected ? DawnColor.accent.opacity(0.14) : Color.secondary.opacity(0.06))
                        .overlay {
                            Capsule()
                                .stroke(isSelected ? DawnColor.accent.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
    }
}

private struct DayAlarmEditorContext {
    let ruleSummary: RuleSummary
    let effectiveConfig: EffectiveDailyConfig
    let presentationDay: ActiveAlarmDay
    let computedIntentSelection: FastIntentSelection
    let intentWarnings: [FastWarning]
}

private struct SummaryHeader: View {
    let gregorianText: String
    let hijriText: String
    let meaningSummaryText: String
    let primaryText: String
    let primaryTime: Date?
    let fajrText: String
    let isOff: Bool
    let summaryText: String
    let summaryDetailText: String?
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
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                Text(gregorianText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(hijriText)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
            }

            Text(meaningSummaryText)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            if primaryTime != nil {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    AppTimeDisplay(
                        main: primaryTimeMain,
                        suffix: primaryTimeSuffix,
                        style: .detail,
                        mainWeight: .light,
                        suffixWeight: .medium,
                        mainColor: isOff ? .secondary : .primary,
                        suffixColor: isOff ? .secondary : nil
                    )

                    Text(summaryText)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(.primary)

                    if let summaryDetailText {
                        Text(summaryDetailText)
                            .font(AppTypography.rowBody)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(summaryText)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(.primary)

                    if let summaryDetailText {
                        Text(summaryDetailText)
                            .font(AppTypography.rowBody)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Text(fajrText)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if !secondaryTagElements.isEmpty || !warningElements.isEmpty {
                FlowLayout(spacing: DesignTokens.textSpacingCompact) {
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
        var parts = ["Wake. \(primaryText).", "Day meaning: \(meaningSummaryText).", "\(fajrText)."]
        if !tagElements.isEmpty {
            parts.append("Tags: \(tagElements.joined(separator: ", ")).")
        }
        return parts.joined(separator: " ")
    }

    private var secondaryTagElements: [String] {
        intentSelection.secondaryTags.sorted { $0.title < $1.title }.map(\.title)
    }

    private var warningElements: [String] {
        warnings.map(\.title)
    }

    private var tagElements: [String] {
        var tags: [String] = []
        tags.append(meaningSummaryText)
        tags.append(contentsOf: secondaryTagElements)
        tags.append(contentsOf: warningElements)
        return tags
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
            return "This date comes from your default morning plan."
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
            return "Adjust the default morning plan from Plans."
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
