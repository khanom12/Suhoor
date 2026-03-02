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
                    AddFastDaySheet(isPresented: $showAddDaySheet)
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

        switch alarmConfigStore.defaults.activationMode {
        case .alwaysOn:
            let windowDays = max(1, alarmConfigStore.defaults.scheduleWindowDays)
            let entries = scheduleManager.schedules.compactMap { schedule -> AlarmRowEntry? in
                if schedule.date < startOfToday { return nil }
                if alarmConfigStore.isDeletedDate(on: schedule.date, timeZone: timeZone) { return nil }
                let config = effectiveConfig(for: schedule)
                let primary = config.primaryDisplay(schedule: schedule)
                if schedule.date == startOfToday,
                   config.hasAnyEnabled,
                   shouldHideToday(schedule: schedule, config: config, now: now) {
                    return nil
                }
                let isOneOff = alarmConfigStore.isExtraOneOffDate(on: schedule.date, timeZone: timeZone)
                return AlarmRowEntry(
                    schedule: schedule,
                    config: config,
                    primary: primary,
                    isOneOff: isOneOff
                )
            }
            return Array(entries.prefix(windowDays))
        case .dateRange:
            let dates = displayDatesForDateRange(startOfToday: startOfToday, timeZone: timeZone)
            return dates.compactMap { date -> AlarmRowEntry? in
                guard let schedule = scheduleForDisplay(on: date, timeZone: timeZone) else { return nil }
                let config = effectiveConfig(for: schedule)
                let primary = config.primaryDisplay(schedule: schedule)
                if schedule.date == startOfToday,
                   config.hasAnyEnabled,
                   shouldHideToday(schedule: schedule, config: config, now: now) {
                    return nil
                }
                let isOneOff = alarmConfigStore.isExtraOneOffDate(on: schedule.date, timeZone: timeZone)
                return AlarmRowEntry(
                    schedule: schedule,
                    config: config,
                    primary: primary,
                    isOneOff: isOneOff
                )
            }
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

    private func displayDatesForDateRange(startOfToday: Date, timeZone: TimeZone) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var dates: [Date] = []
        if let start = alarmConfigStore.defaults.activeStartDate,
           let end = alarmConfigStore.defaults.activeEndDate {
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            dates.append(contentsOf: DateHelpers.dates(from: startDay, to: endDay, calendar: calendar))
        }

        let oneOffDates = alarmConfigStore.defaults.extraOneOffDates
            .compactMap { dateFromKey($0, timeZone: timeZone) }
            .map { calendar.startOfDay(for: $0) }
        dates.append(contentsOf: oneOffDates)

        var seenKeys = Set<String>()
        return dates.sorted().filter { date in
            guard date >= startOfToday else { return false }
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if alarmConfigStore.defaults.deletedDates.contains(key) { return false }
            if seenKeys.contains(key) { return false }
            seenKeys.insert(key)
            return true
        }
    }

    private func scheduleForDisplay(on date: Date, timeZone: TimeZone) -> DaySchedule? {
        if let schedule = scheduleManager.schedules.first(where: { DateHelpers.isSameDay($0.date, date, in: timeZone) }) {
            return schedule
        }
        return scheduleManager.schedule(for: date)
    }

    private func dateFromKey(_ key: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func deleteOneOff(_ entry: AlarmRowEntry) {
        let date = entry.schedule.date
        let timeZone = TimeZone.current
        alarmConfigStore.addDeletedDate(date, timeZone: timeZone)
        alarmConfigStore.removeOverride(for: date, timeZone: timeZone)
        Task { await scheduleManager.cancelDay(date) }
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

private struct AddFastDaySheet: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    @Binding var isPresented: Bool
    @State private var selectedDate = DateHelpers.startOfToday()
    @State private var tagSelection = FastIntentSelection.default
    @State private var showsTagPicker = false

    var body: some View {
        Form {
            Section {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            }

            Section("Tags") {
                Button {
                    showsTagPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Tags")
                                .foregroundStyle(.primary)
                            Text(tagSummaryText)
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

            if isAlreadyActive {
                Text("This day is already active.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add a fasting day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { addSelectedDate() }
                    .disabled(isAlreadyActive)
            }
        }
        .sheet(isPresented: $showsTagPicker) {
            NavigationStack {
                FastTagPickerSheet(
                    date: selectedDate,
                    initialSelection: tagSelection,
                    schedules: scheduleManager.schedules,
                    selections: fastTagStore.selections,
                    onSave: { selection in
                        tagSelection = selection
                        fastTagStore.setSelection(selection, for: selectedDate, timeZone: .current)
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            tagSelection = fastTagStore.selection(for: selectedDate, timeZone: .current) ?? .default
        }
        .onChange(of: selectedDate) { _, newValue in
            tagSelection = fastTagStore.selection(for: newValue, timeZone: .current) ?? .default
        }
    }

    private var isAlreadyActive: Bool {
        let timeZone = TimeZone.current
        if alarmConfigStore.isDeletedDate(on: selectedDate, timeZone: timeZone) {
            return false
        }
        return alarmConfigStore.isDefaultsActive(on: selectedDate, timeZone: timeZone)
    }

    private func addSelectedDate() {
        let timeZone = TimeZone.current
        alarmConfigStore.removeDeletedDate(selectedDate, timeZone: timeZone)
        alarmConfigStore.addExtraOneOffDate(selectedDate, timeZone: timeZone)
        fastTagStore.setSelection(tagSelection, for: selectedDate, timeZone: timeZone)
        Task { await scheduleManager.rescheduleDay(selectedDate) }
        isPresented = false
    }

    private var tagSummaryText: String {
        let computed = TagComputationEngine.result(
            for: selectedDate,
            schedules: scheduleManager.schedules,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: .current,
            overrideSelection: tagSelection.hasMeaningfulTags ? tagSelection : nil
        )

        var parts: [String] = [computed.computedPrimaryIntent.shortTitle]
        let secondary = computed.computedSecondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map { $0.shortTitle }.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }
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
        if isTomorrow {
            return "\(Strings.AlarmsTab.tomorrowLabel) • \(dateText)"
        }
        if isToday {
            return "\(Strings.AlarmsTab.todayLabel) • \(dateText)"
        }
        return dateText
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
            let isDateRangeMode = alarmConfigStore.defaults.activationMode == .dateRange
            let isWithinRange = alarmConfigStore.isDateInActiveRange(on: schedule.date, timeZone: timeZone)
            let isOneOff = alarmConfigStore.isExtraOneOffDate(on: schedule.date, timeZone: timeZone)
            if isDateRangeMode, isOn, !isWithinRange && !isOneOff {
                alarmConfigStore.addExtraOneOffDate(schedule.date, timeZone: timeZone)
            }
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
        if isToday {
            return "\(Strings.AlarmsTab.todayLabel), \(dateText)"
        }
        if isTomorrow {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(dateText)"
        }
        return dateText
    }

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
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
