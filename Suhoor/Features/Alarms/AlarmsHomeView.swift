import SwiftUI
import UIKit
import CoreLocation

struct AlarmsHomeView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedSchedule: DaySchedule?
    @State private var showSettingsSheet = false
    @State private var showAddDaySheet = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                if displayEntries.isEmpty {
                    Section {
                        emptyStateView
                    }
                } else {
                    ForEach(hijriMonthSections, id: \.key) { section in
                        Section {
                            ForEach(section.entries.indices, id: \.self) { index in
                                let entry = section.entries[index]
                                AlarmRowView(
                                    schedule: entry.schedule,
                                    config: entry.config,
                                    primaryDisplay: entry.primary,
                                    onSelect: {
                                        selectedSchedule = entry.schedule
                                    }
                                )
                                .deleteDisabled(!entry.isOneOff)
                            }
                            .onDelete { offsets in
                                deleteEntries(in: section.entries, at: offsets)
                            }
                        } header: {
                            Text(section.key.title)
                                .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if showsAddButton {
                        Button {
                            showAddDaySheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: navigationIsActiveBinding) {
                if let schedule = selectedSchedule {
                    AlarmDayDetailView(schedule: schedule)
                }
            }
            .onChange(of: alarmConfigStore.defaults) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: settingsStore.settings.calculationMethod) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: settingsStore.settings.fajrAdjustmentMinutes) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: settingsStore.settings.locationMode) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: settingsStore.settings.fixedLocation) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: locationService.lastLocation) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    SettingsRootView()
                }
            }
            .sheet(isPresented: $showAddDaySheet) {
                NavigationStack {
                    AddScheduleSheet(isPresented: $showAddDaySheet)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
                showSettingsSheet = true
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text(Strings.AlarmsTab.emptyTitle)
                .font(.headline.weight(.semibold))
            Text(emptyStateDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PermissionStackView(
                kinds: [.location, .alarmKit, .notifications],
                refreshKey: permissionRefreshKey,
                showOnlyBlocking: true,
                onOpenSettings: openAppSettings
            )
            .environmentObject(scheduleManager)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.spacingL)
    }

    private var emptyStateDetail: String {
        if !scheduleManager.statusText.isEmpty {
            return scheduleManager.statusText
        }
        return Strings.AlarmsTab.emptySubtitle
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private var displayEntries: [AlarmRowEntry] {
        let now = Date()
        let timeZone = TimeZone.current
        let startOfToday = DateHelpers.startOfToday(in: timeZone)
        return scheduleManager.upcomingResolvedEntries(limit: 60, timeZone: timeZone).compactMap { resolved in
            guard let schedule = scheduleForDisplay(on: resolved.date, timeZone: timeZone) else { return nil }
            let config = effectiveConfig(for: schedule)
            let primary = config.primaryDisplay(schedule: schedule)
            if schedule.date == startOfToday,
               config.hasAnyEnabled,
               shouldHideToday(schedule: schedule, config: config, now: now) {
                return nil
            }
            return AlarmRowEntry(
                schedule: schedule,
                config: config,
                primary: primary,
                isOneOff: resolved.isExplicitOneOff
            )
        }
    }

    private var hijriMonthSections: [HijriMonthSection] {
        let timeZone = TimeZone.current
        var grouped: [HijriMonthKey: [AlarmRowEntry]] = [:]
        for entry in displayEntries {
            guard let key = FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone) else { continue }
            grouped[key, default: []].append(entry)
        }
        let sorted = grouped.map { key, entries in
            let firstDate = entries.first?.schedule.date ?? Date.distantPast
            return (key: key, entries: entries, firstDate: firstDate)
        }.sorted { $0.firstDate < $1.firstDate }
        return sorted.map { HijriMonthSection(key: $0.key, entries: $0.entries) }
    }

    private func effectiveConfig(for schedule: DaySchedule) -> EffectiveDailyConfig {
        let timeZone = TimeZone.current
        let ruleEngine = RuleEngine(settings: settingsStore.settings, configStore: alarmConfigStore, timeZone: timeZone)
        return alarmConfigStore.effectiveConfig(
            for: schedule.date,
            ruleSummary: ruleEngine.ruleSummary(for: schedule.date),
            settings: settingsStore.settings,
            timeZone: timeZone
        )
    }

    private var showsAddButton: Bool {
        !editMode.isEditing
    }

    private func deleteEntries(in entries: [AlarmRowEntry], at offsets: IndexSet) {
        for index in offsets {
            guard entries.indices.contains(index) else { continue }
            let entry = entries[index]
            guard entry.isOneOff else { continue }
            deleteOneOff(entry)
        }
    }

    private func scheduleForDisplay(on date: Date, timeZone: TimeZone) -> DaySchedule? {
        if let schedule = scheduleManager.schedules.first(where: { DateHelpers.isSameDay($0.date, date, in: timeZone) }) {
            return schedule
        }
        return scheduleManager.schedule(for: date)
    }

    private func deleteOneOff(_ entry: AlarmRowEntry) {
        let date = entry.schedule.date
        Task { await scheduleManager.deleteExplicitScheduledDate(date) }
    }

    private func shouldHideToday(schedule: DaySchedule, config: EffectiveDailyConfig, now: Date) -> Bool {
        if config.fajrEnabled {
            return schedule.fajrDate <= now
        }
        let primary = config.primaryDisplay(schedule: schedule)
        guard let primary else { return false }
        return primary.time <= now
    }
}

private struct AddScheduleSheet: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    @Binding var isPresented: Bool
    @State private var mode: AddScheduleMode = .singleDay
    @State private var selectedDate = DateHelpers.startOfToday()
    @State private var rangeStartDate = DateHelpers.startOfToday()
    @State private var rangeEndDate = DateHelpers.startOfToday()
    @State private var singleDayTagSelection = FastIntentSelection.default
    @State private var rangeTagSelection = FastIntentSelection.default
    @State private var showsTagPicker = false
    @State private var tagEditorTarget: TagEditorTarget = .singleDay

    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(AddScheduleMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch mode {
            case .singleDay:
                singleDayContent
            case .dateRange:
                dateRangeContent
            case .islamicDates:
                islamicDatesContent
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                if mode != .islamicDates {
                    Button("Add") { submitCurrentMode() }
                        .disabled(submitDisabled)
                }
            }
        }
        .sheet(isPresented: $showsTagPicker) {
            NavigationStack {
                FastTagPickerSheet(
                    date: tagEditorDate,
                    initialSelection: currentTagSelection,
                    schedules: scheduleManager.schedules,
                    selections: fastTagStore.selections,
                    onSave: { selection in
                        switch tagEditorTarget {
                        case .singleDay:
                            singleDayTagSelection = selection
                        case .dateRange:
                            rangeTagSelection = selection
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            singleDayTagSelection = fastTagStore.selection(for: selectedDate, timeZone: .current) ?? .default
        }
        .onChange(of: selectedDate) { _, newValue in
            singleDayTagSelection = fastTagStore.selection(for: newValue, timeZone: .current) ?? .default
        }
    }

    private var singleDayContent: some View {
        Group {
            Section {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            }

            Section("Tags") {
                tagEditorButton(summary: singleDayTagSummaryText, target: .singleDay)
            }

            if singleDayAlreadyActive {
                Text("This day is already scheduled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateRangeContent: some View {
        Group {
            Section {
                DatePicker(
                    "Start date",
                    selection: $rangeStartDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)

                DatePicker(
                    "End date",
                    selection: $rangeEndDate,
                    in: rangeStartDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
            }

            Section("Tags") {
                tagEditorButton(summary: rangeTagSummaryText, target: .dateRange)
            }

            Section {
                Text("This creates one schedule source for each Gregorian day in the range, up to 60 days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Dates in range: \(rangeLengthDays)")
                    .font(.footnote)
                    .foregroundStyle(rangeIsTooLong ? .red : .secondary)
            }
        }
    }

    private var islamicDatesContent: some View {
        Group {
            Section {
                Text("Use corrected Hijri dates for upcoming one-time adds or recurring presets. Alarm times still come from your existing Suhoor, reminder, and Fajr settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Upcoming Once") {
                ForEach(IslamicQuickAddKind.allCases) { kind in
                    quickAddRow(for: kind)
                }
            }

            Section("Recurring") {
                ForEach(RecurringIslamicRule.allCases) { rule in
                    recurringRuleRow(for: rule)
                }
            }
        }
    }

    private func tagEditorButton(summary: String, target: TagEditorTarget) -> some View {
        Button {
            tagEditorTarget = target
            showsTagPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Tags")
                        .foregroundStyle(.primary)
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func quickAddRow(for kind: IslamicQuickAddKind) -> some View {
        if let preview = scheduleManager.previewIslamicQuickAdd(kind) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.title)
                            .font(.body.weight(.medium))
                        Text(kind.detailText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Add") {
                        Task {
                            _ = await scheduleManager.addIslamicQuickAdd(kind)
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Text(preview.previewText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(preview.availabilityText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.body.weight(.medium))
                Text("Needs calendar data for a preview right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func recurringRuleRow(for rule: RecurringIslamicRule) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.body.weight(.medium))
                Text(rule.detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Add") {
                Task {
                    await scheduleManager.addRecurringIslamicRule(rule)
                    isPresented = false
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var singleDayAlreadyActive: Bool {
        alarmConfigStore.isDefaultsActive(on: selectedDate, timeZone: .current)
    }

    private var submitDisabled: Bool {
        switch mode {
        case .singleDay:
            return singleDayAlreadyActive
        case .dateRange:
            return rangeIsTooLong
        case .islamicDates:
            return true
        }
    }

    private func submitCurrentMode() {
        switch mode {
        case .singleDay:
            Task { await addSelectedDate() }
        case .dateRange:
            Task { await addDateRange() }
        case .islamicDates:
            break
        }
    }

    private func addSelectedDate() async {
        await scheduleManager.addSingleScheduledDate(selectedDate)
        fastTagStore.setSelection(singleDayTagSelection, for: selectedDate, timeZone: .current)
        isPresented = false
    }

    private func addDateRange() async {
        let dates = normalizedRangeDates
        await scheduleManager.addGregorianRange(startDate: rangeStartDate, endDate: rangeEndDate)
        if rangeTagSelection.hasMeaningfulTags {
            for date in dates {
                fastTagStore.setSelection(rangeTagSelection, for: date, timeZone: .current)
            }
        }
        isPresented = false
    }

    private var normalizedRangeDates: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let range = GregorianRangeSource(startDate: rangeStartDate, endDate: rangeEndDate, timeZone: .current)
        return DateHelpers.dates(from: range.startDate, to: range.endDate, calendar: calendar)
    }

    private var rangeLengthDays: Int {
        normalizedRangeDates.count
    }

    private var rangeIsTooLong: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = calendar.startOfDay(for: min(rangeStartDate, rangeEndDate))
        let end = calendar.startOfDay(for: max(rangeStartDate, rangeEndDate))
        let span = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return span > GregorianRangeSource.maxLengthDays
    }

    private var currentTagSelection: FastIntentSelection {
        switch tagEditorTarget {
        case .singleDay:
            return singleDayTagSelection
        case .dateRange:
            return rangeTagSelection
        }
    }

    private var tagEditorDate: Date {
        switch tagEditorTarget {
        case .singleDay:
            return selectedDate
        case .dateRange:
            return rangeStartDate
        }
    }

    private var singleDayTagSummaryText: String {
        tagSummaryText(for: selectedDate, selection: singleDayTagSelection)
    }

    private var rangeTagSummaryText: String {
        tagSummaryText(for: rangeStartDate, selection: rangeTagSelection)
    }

    private func tagSummaryText(for date: Date, selection: FastIntentSelection) -> String {
        let computed = TagComputationEngine.result(
            for: date,
            schedules: scheduleManager.schedules,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: .current,
            overrideSelection: selection.hasMeaningfulTags ? selection : nil
        )

        var parts: [String] = [computed.computedPrimaryIntent.shortTitle]
        let secondary = computed.computedSecondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map { $0.shortTitle }.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }
}

private enum AddScheduleMode: String, CaseIterable, Identifiable {
    case singleDay
    case dateRange
    case islamicDates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singleDay:
            return "Single Day"
        case .dateRange:
            return "Date Range"
        case .islamicDates:
            return "Islamic Dates"
        }
    }
}

private enum TagEditorTarget {
    case singleDay
    case dateRange
}

private struct AlarmRowEntry {
    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primary: PrimaryDisplay?
    let isOneOff: Bool
}

private struct HijriMonthSection {
    let key: HijriMonthKey
    let entries: [AlarmRowEntry]
}

private struct AlarmRowView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.editMode) private var editMode

    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primaryDisplay: PrimaryDisplay?
    let onSelect: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 46

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

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel)
                    .font(.footnote)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(primaryTimeMain)
                        .font(.system(size: timeFontSize, weight: .regular, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(isDisabled ? .tertiary : .primary)
                        .minimumScaleFactor(0.8)

                    if let primaryTimeSuffix {
                        Text(primaryTimeSuffix)
                            .font(.system(size: timeFontSize * 0.55, weight: .regular, design: .default))
                            .monospacedDigit()
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                            .baselineOffset(1)
                    }
                }

                Text(fajrLineText)
                    .font(.callout)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)

            Spacer()

            Toggle("", isOn: dayActiveBinding)
                .labelsHidden()
                .tint(DawnColor.accent)
                .accessibilityLabel("\(primaryLabelText) alarm")
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if editMode?.wrappedValue.isEditing != true {
                onSelect()
            }
        }
    }

    private var fajrTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var primaryTimeText: String {
        if let primaryDisplay {
            return TimeFormatters.timeFormatter.string(from: primaryDisplay.time)
        }
        return TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var primaryTimeDate: Date {
        primaryDisplay?.time ?? schedule.wakeDate
    }

    private var primaryTimeMain: String {
        AlarmRowView.timeMainFormatter.string(from: primaryTimeDate)
    }

    private var primaryTimeSuffix: String? {
        AlarmRowView.timeSuffixFormatter.string(from: primaryTimeDate)
    }

    private var fajrLineText: String {
        "Fajr \(fajrTimeText)"
    }

    private var dateLabel: String {
        let dateText = AlarmRowView.dateLabelFormatter.string(from: schedule.date)
        var parts: [String] = []
        if isToday {
            parts.append(Strings.AlarmsTab.todayLabel)
        } else if isTomorrow {
            parts.append(Strings.AlarmsTab.tomorrowLabel)
        }
        parts.append(dateText)
        if let fastDayText {
            parts.append(fastDayText)
        }
        return parts.joined(separator: " • ")
    }

    private var isToday: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.isDate(schedule.date, inSameDayAs: startOfToday)
    }

    private var isTomorrow: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        return calendar.isDate(schedule.date, inSameDayAs: startOfTomorrow)
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            config.hasAnyEnabled
        }, set: { isOn in
            let timeZone = TimeZone.current
            alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone) { override in
                override.skipDay = !isOn
            }
            Task { await scheduleManager.rescheduleDay(schedule.date) }
        })
    }

    private var accessibilitySummary: String {
        "\(dateLabelWithPrefix). \(primaryLabelText) alarm. \(primaryTimeText). Fajr \(fajrTimeText)."
    }

    private var primaryLabelText: String {
        switch primaryDisplay?.kind ?? .suhoor {
        case .suhoor:
            return "Suhoor"
        case .reminder:
            return "Reminder"
        case .fajr:
            return "Fajr"
        }
    }

    private var isDisabled: Bool {
        !config.hasAnyEnabled
    }

    private var dateLabelWithPrefix: String {
        let dateText = AlarmRowView.dateLabelFormatter.string(from: schedule.date)
        var parts: [String] = []
        if isToday {
            parts.append(Strings.AlarmsTab.todayLabel)
        } else if isTomorrow {
            parts.append(Strings.AlarmsTab.tomorrowLabel)
        }
        parts.append(dateText)
        if let fastDayText {
            parts.append(fastDayText)
        }
        return parts.joined(separator: ", ")
    }

    private var fastDayText: String? {
        guard let components = FastIntentEngine.adjustedComponents(for: schedule.date, timeZone: .current),
              components.month == .ramadan else {
            return nil
        }
        return Strings.AlarmsTab.ramadanDayLabel(components.day)
    }

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}

private extension AlarmsHomeView {
    var navigationIsActiveBinding: Binding<Bool> {
        Binding(get: {
            selectedSchedule != nil
        }, set: { isActive in
            if !isActive {
                selectedSchedule = nil
            }
        })
    }
}
