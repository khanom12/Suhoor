import SwiftUI
import UIKit

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
            .background(
                NavigationBarConfigurator(
                    isEditing: isEditing,
                    showsAddButton: showsAddButton,
                    onEdit: { isEditing.toggle() },
                    onAdd: { showAddDaySheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            )
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
                showsDeleteControl: true,
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
        !isEditing
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
        if alarmConfigStore.isDeletedDate(on: selectedDate, timeZone: timeZone) {
            return false
        }
        return alarmConfigStore.isDefaultsActive(on: selectedDate, timeZone: timeZone)
    }

    private func addSelectedDate() {
        let timeZone = TimeZone.current
        alarmConfigStore.removeDeletedDate(selectedDate, timeZone: timeZone)
        alarmConfigStore.addExtraOneOffDate(selectedDate, timeZone: timeZone)
        Task { await scheduleManager.rescheduleDay(selectedDate) }
        isPresented = false
    }
}

private struct NavigationBarConfigurator: UIViewControllerRepresentable {
    let isEditing: Bool
    let showsAddButton: Bool
    let onEdit: () -> Void
    let onAdd: () -> Void
    let onSettings: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onEdit = onEdit
        context.coordinator.onAdd = onAdd
        context.coordinator.onSettings = onSettings

        if let navigationBar = uiViewController.parent?.navigationController?.navigationBar {
            applyUngroupedButtonAppearance(to: navigationBar, coordinator: context.coordinator)
        }

        let targetItem = uiViewController.parent?.navigationItem ?? uiViewController.navigationItem
        targetItem.leftBarButtonItem = UIBarButtonItem(
            title: isEditing ? "Done" : "Edit",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.editTapped)
        )

        var rightItems: [UIBarButtonItem] = []
        if showsAddButton {
            rightItems.append(
                makeIconBarButtonItem(
                    systemName: "plus",
                    accessibilityLabel: "Add day",
                    selector: #selector(Coordinator.addTapped),
                    coordinator: context.coordinator
                )
            )
        }
        rightItems.insert(
            makeIconBarButtonItem(
                systemName: "gearshape",
                accessibilityLabel: "Settings",
                selector: #selector(Coordinator.settingsTapped),
                coordinator: context.coordinator
            ),
            at: 0
        )
        targetItem.rightBarButtonItems = rightItems
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        guard let navigationBar = uiViewController.parent?.navigationController?.navigationBar else { return }
        if let cached = coordinator.cachedAppearances {
            navigationBar.standardAppearance = cached.standard
            navigationBar.scrollEdgeAppearance = cached.scrollEdge
            navigationBar.compactAppearance = cached.compact
        }
    }

    final class Coordinator: NSObject {
        var onEdit: (() -> Void)?
        var onAdd: (() -> Void)?
        var onSettings: (() -> Void)?
        fileprivate var cachedAppearances: NavigationBarAppearances?

        @objc func editTapped() {
            onEdit?()
        }

        @objc func addTapped() {
            onAdd?()
        }

        @objc func settingsTapped() {
            onSettings?()
        }
    }

    fileprivate struct NavigationBarAppearances {
        let standard: UINavigationBarAppearance
        let scrollEdge: UINavigationBarAppearance?
        let compact: UINavigationBarAppearance?
    }

    private func applyUngroupedButtonAppearance(to navigationBar: UINavigationBar, coordinator: Coordinator) {
        if coordinator.cachedAppearances == nil {
            coordinator.cachedAppearances = NavigationBarAppearances(
                standard: navigationBar.standardAppearance,
                scrollEdge: navigationBar.scrollEdgeAppearance,
                compact: navigationBar.compactAppearance
            )
        }

        let standard = copyAppearance(navigationBar.standardAppearance)
        let scrollEdge = copyAppearance(navigationBar.scrollEdgeAppearance ?? navigationBar.standardAppearance)
        let compact = copyAppearance(navigationBar.compactAppearance ?? navigationBar.standardAppearance)

        clearButtonBackgrounds(standard.buttonAppearance)
        clearButtonBackgrounds(scrollEdge.buttonAppearance)
        clearButtonBackgrounds(compact.buttonAppearance)

        navigationBar.standardAppearance = standard
        navigationBar.scrollEdgeAppearance = scrollEdge
        navigationBar.compactAppearance = compact
    }

    private func copyAppearance(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
        return appearance.copy()
    }

    private func clearButtonBackgrounds(_ appearance: UIBarButtonItemAppearance) {
        let states: [UIBarButtonItemStateAppearance] = [
            appearance.normal,
            appearance.highlighted,
            appearance.disabled,
            appearance.focused
        ]
        for state in states {
            state.backgroundImage = UIImage()
        }
    }

    private func makeIconBarButtonItem(
        systemName: String,
        accessibilityLabel: String,
        selector: Selector,
        coordinator: Coordinator
    ) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(coordinator, action: selector, for: .touchUpInside)

        let materialView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        materialView.isUserInteractionEnabled = false
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.layer.cornerRadius = 16
        materialView.layer.masksToBounds = true

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(materialView)
        container.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 32),
            container.heightAnchor.constraint(equalToConstant: 32),
            materialView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            materialView.topAnchor.constraint(equalTo: container.topAnchor),
            materialView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return UIBarButtonItem(customView: container)
    }
}

private struct GlassCircleIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color.white.opacity(fillOpacity))
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }

    private var fillOpacity: Double {
        colorScheme == .dark ? 0.14 : 0.22
    }

    private var strokeOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.35
    }

    @Environment(\.colorScheme) private var colorScheme
}

private struct GlassPillLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(fillOpacity))
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }

    private var fillOpacity: Double {
        colorScheme == .dark ? 0.14 : 0.22
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
