import SwiftUI

struct AlarmsHomeView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedSchedule: DaySchedule?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    if displayEntries.isEmpty {
                        emptyStateView
                    } else {
                        let lastIndex = displayEntries.count - 1
                        ForEach(displayEntries.indices, id: \.self) { index in
                            let entry = displayEntries[index]

                            AlarmDayRowView(
                                schedule: entry.schedule,
                                config: entry.config,
                                primaryDisplay: entry.primary
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
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingS)
                .padding(.bottom, DesignTokens.spacingM)
            }
        }
        .navigationTitle(Strings.AlarmList.title)
        .navigationBarTitleDisplayMode(.large)
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
            return AlarmRowEntry(schedule: schedule, config: config, primary: primary)
        }
        return Array(entries.prefix(windowDays))
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
}

private struct AlarmRowEntry {
    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primary: PrimaryDisplay?
}

private struct AlarmDayRowView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primaryDisplay: PrimaryDisplay?
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
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
            onSelect()
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
