import SwiftUI

struct AlarmsHomeView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedSchedule: DaySchedule?
    @State private var showSettingsSheet = false
    @State private var showAddDaySheet = false
    @State private var isEditing = false

    var body: some View {
        contentView
            .navigationTitle(Strings.AlarmList.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .navigationDestination(isPresented: navigationIsActiveBinding) {
                if let schedule = selectedSchedule {
                    AlarmDayDetailView(schedule: schedule)
                }
            }
            .onChange(of: alarmConfigStore.defaults) { _, _ in
                Task { await scheduleManager.refreshSchedules(force: true) }
            }
            .onChange(of: alarmConfigStore.overridesByDay) { _, _ in
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

    private var contentView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                listContent
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        LazyVStack(spacing: 0) {
            if displayEntries.isEmpty {
                emptyStateView
            } else {
                listEntries
            }
        }
        .padding(.horizontal, DesignTokens.spacingL)
        .padding(.top, DesignTokens.spacingS)
        .padding(.bottom, DesignTokens.spacingM)
    }

    private var listEntries: some View {
        let lastIndex = displayEntries.count - 1
        return ForEach(displayEntries.indices, id: \.self) { index in
            let entry = displayEntries[index]

            AlarmDayRowView(
                schedule: entry.schedule,
                config: entry.config,
                primaryDisplay: entry.primary,
                isEditing: isEditing,
                showsDeleteControl: entry.isOneOff,
                onDelete: { deleteOneOff(entry) }
            ) {
                selectedSchedule = entry.schedule
            }

            if index < lastIndex {
                Divider()
                    .padding(.leading, DesignTokens.spacingL)
                    .padding(.trailing, 84)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if showsAddButton {
                Button {
                    showAddDaySheet = true
                } label: {
                    GlassCircleIcon(systemName: "plus")
                }
                .buttonStyle(.plain)
            }

            Button {
                showSettingsSheet = true
            } label: {
                GlassCircleIcon(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }


    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text(Strings.AlarmsTab.emptyTitle)
                .font(.headline.weight(.semibold))
            Text(emptyStateDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var displayEntries: [AlarmRowEntry] {
        let now = Date()
        let timeZone = TimeZone.current
        let startOfToday = DateHelpers.startOfToday(in: timeZone)

        switch alarmConfigStore.defaults.activationMode {
        case .alwaysOn:
            let windowDays = max(1, alarmConfigStore.defaults.scheduleWindowDays)
            let entries = scheduleManager.schedules.compactMap { schedule -> AlarmRowEntry? in
                if schedule.date < startOfToday { return nil }
                let config = effectiveConfig(for: schedule)
                let primary = config.primaryDisplay(schedule: schedule)
                if schedule.date == startOfToday,
                   let primary,
                   primary.time <= now,
                   config.hasAnyEnabled {
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
                   let primary,
                   primary.time <= now,
                   config.hasAnyEnabled {
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
        alarmConfigStore.defaults.activationMode == .dateRange && !isEditing
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
        alarmConfigStore.removeExtraOneOffDate(date, timeZone: timeZone)
        alarmConfigStore.removeOverride(for: date, timeZone: timeZone)
        Task { await scheduleManager.cancelDay(date) }
    }
}

private struct AddFastDaySheet: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @Binding var isPresented: Bool
    @State private var selectedDate = DateHelpers.startOfToday()

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
    }

    private var isAlreadyActive: Bool {
        let timeZone = TimeZone.current
        return alarmConfigStore.isDateInActiveRange(on: selectedDate, timeZone: timeZone)
            || alarmConfigStore.isExtraOneOffDate(on: selectedDate, timeZone: timeZone)
    }

    private func addSelectedDate() {
        let timeZone = TimeZone.current
        alarmConfigStore.addExtraOneOffDate(selectedDate, timeZone: timeZone)
        Task { await scheduleManager.rescheduleDay(selectedDate) }
        isPresented = false
    }
}

private struct GlassCircleIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(.thinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                    )
            )
    }

    private var strokeOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.35
    }

    @Environment(\.colorScheme) private var colorScheme
}

private struct AlarmRowEntry {
    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primary: PrimaryDisplay?
    let isOneOff: Bool
}

private struct AlarmDayRowView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primaryDisplay: PrimaryDisplay?
    let isEditing: Bool
    let showsDeleteControl: Bool
    let onDelete: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            if isEditing && showsDeleteControl {
                deleteButton
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLine)
                    .font(.footnote)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)

                Text(primaryTimeText)
                    .font(.system(size: 48, weight: .light, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(isDisabled ? .tertiary : .primary)

                Text(secondaryLineText)
                    .font(.footnote)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)

            Spacer()

            Toggle("", isOn: dayActiveBinding)
                .labelsHidden()
                .accessibilityLabel("Enable alarms for this day")
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete one-off day")
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

    private var secondaryLineText: String {
        guard let primaryDisplay else {
            return "Off"
        }
        if primaryDisplay.kind == .fajr {
            return "Fajr (Adhan)"
        }
        return "Fajr \(fajrTimeText)"
    }

    private var dateLine: String {
        let dateText = GregorianDateFormatter.shared.cardString(for: schedule.date)
        if isToday {
            return "\(Strings.AlarmsTab.todayLabel), \(dateText)"
        }
        if isTomorrow {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(dateText)"
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
        let statusText = config.skipDay ? "skipped" : "active"
        return "\(dateLabelWithPrefix), \(primaryLabelText) \(primaryTimeText), Fajr \(fajrTimeText), \(statusText)"
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
        let dateText = GregorianDateFormatter.shared.cardString(for: schedule.date)
        if isToday {
            return "\(Strings.AlarmsTab.todayLabel), \(dateText)"
        }
        if isTomorrow {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(dateText)"
        }
        return dateText
    }
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
