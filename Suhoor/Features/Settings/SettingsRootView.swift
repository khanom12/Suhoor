import SwiftUI
import UIKit
import CoreLocation

struct SettingsRootView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var showAlarmInfo = false
    @State private var reminderTimeClamped = false

    var body: some View {
        Form {
            Section(Strings.Settings.defaultsEnabledSection) {
                Text(Strings.Settings.defaultsEnabledHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Toggle(Strings.Settings.defaultSuhoorToggle, isOn: suhoorDefaultBinding)
                Toggle(Strings.Settings.defaultReminderToggle, isOn: reminderDefaultBinding)
                Toggle(Strings.Settings.defaultFajrToggle, isOn: fajrDefaultBinding)
            }
            Section(Strings.Settings.suhoorTimingSection) {
                Text(Strings.Settings.suhoorTimingHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(Strings.Settings.suhoorTimeBasedOn, selection: suhoorTimeModeBinding) {
                    ForEach(SuhoorTimeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
                    DatePicker(
                        Strings.AlarmsTab.suhoorTime,
                        selection: defaultSuhoorTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )
                } else {
                    Stepper(value: defaultSuhoorOffsetBinding, in: 5...240, step: 5) {
                        Text("Minutes before Fajr: \(defaultSuhoorOffsetBinding.wrappedValue)m")
                    }
                }
            }

            Section(Strings.Settings.reminderTimingSection) {
                Text(Strings.Settings.reminderTimingHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(Strings.Settings.reminderTimeBasedOn, selection: reminderTimeModeBinding) {
                    ForEach(ReminderTimeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime {
                    DatePicker(
                        Strings.Settings.reminderTime,
                        selection: defaultReminderTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )

                    if showsReminderBeforeSuhoorWarning {
                        Text(Strings.Settings.reminderBeforeSuhoorWarning)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                } else {
                    Stepper(value: reminderDefaultOffsetBinding, in: 5...maxReminderDefaultOffset, step: 1) {
                        Text(Strings.AlarmsTab.reminderOffsetLabel(reminderDefaultOffsetBinding.wrappedValue))
                    }

                    if showsReminderBeforeSuhoorWarning {
                        Text(Strings.Settings.reminderBeforeSuhoorWarning)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section(Strings.Settings.activePeriodSection) {
                Text(Strings.Settings.activePeriodHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(Strings.Settings.defaultsActive, selection: activationModeBinding) {
                    Text(Strings.Settings.activeAlways).tag(AlarmActivationMode.alwaysOn)
                    Text(Strings.Settings.activeDateRange).tag(AlarmActivationMode.dateRange)
                }
                .pickerStyle(.segmented)

                if alarmConfigStore.defaults.activationMode == .dateRange {
                    DatePicker(
                        Strings.AlarmsTab.activeStartDate,
                        selection: activeStartDateBinding,
                        displayedComponents: [.date]
                    )

                    DatePicker(
                        Strings.AlarmsTab.activeEndDate,
                        selection: activeEndDateBinding,
                        displayedComponents: [.date]
                    )
                }

                NavigationLink {
                    AdditionalActiveDaysView()
                } label: {
                    HStack {
                        Text("Additional active days")
                        Spacer()
                        Text("\(extraOneOffDates.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(Strings.Settings.alarmsListRangeSection) {
                Text(Strings.Settings.alarmsListRangeHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(Strings.Settings.alarmsListRangeLabel, selection: scheduleWindowBinding) {
                    Text("7").tag(7)
                    Text("14").tag(14)
                    Text("30").tag(30)
                }
                .pickerStyle(.segmented)
            }

            Section(Strings.Settings.locationSection) {
                NavigationLink {
                    LocationSettingsView()
                        .environmentObject(settingsStore)
                        .environmentObject(scheduleManager)
                        .environmentObject(locationService)
                } label: {
                    ActionRowView(title: Strings.Settings.locationSettings, systemImage: "location.circle")
                }
            }

            Section(Strings.Settings.calculationSection) {
                Picker(Strings.Settings.method, selection: $settingsStore.settings.calculationMethod) {
                    ForEach(CalculationMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settingsStore.settings.calculationMethod) { _, _ in
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                }

                Stepper(value: $settingsStore.settings.fajrAdjustmentMinutes, in: -30...30, step: 1) {
                    Text("\(Strings.Settings.fajrAdjustment): \(settingsStore.settings.fajrAdjustmentMinutes)m")
                }
                .onChange(of: settingsStore.settings.fajrAdjustmentMinutes) { _, _ in
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                }

                Text(Strings.Settings.fajrAdjustmentHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(Strings.Settings.permissionsSection) {
                HStack {
                    Text("\(Strings.Settings.locationStatus): \(locationStatusText)")
                    Spacer()
                    Button(Strings.AlarmList.openSettings) { openAppSettings() }
                        .font(.footnote)
                }

                HStack {
                    Text("\(Strings.Settings.notificationsStatus): \(notificationsStatusText)")
                    Spacer()
                    Button(Strings.AlarmList.openSettings) { openAppSettings() }
                        .font(.footnote)
                }

                HStack {
                    Text("AlarmKit")
                    Spacer()
                    Text(scheduleManager.alarmAuthorizationText)
                        .foregroundStyle(.secondary)
                }

                Button(Strings.Settings.aboutAlarms) { showAlarmInfo = true }
                    .font(.footnote.weight(.semibold))
            }

            Section("Diagnostics") {
                NavigationLink {
                    DiagnosticsView()
                        .environmentObject(scheduleManager)
                } label: {
                    ActionRowView(title: "Scheduling audit & logs", systemImage: "waveform.path.ecg")
                }

                if FeatureFlags.enableAlarmKitTestMode {
                    NavigationLink {
                        AlarmKitTestModeView(testSettingsStore: scheduleManager.testSettingsStore)
                            .environmentObject(scheduleManager)
                    } label: {
                        ActionRowView(title: "AlarmKit Test Mode", systemImage: "alarm")
                    }
                }
            }

            Section(Strings.Settings.aboutSection) {
                HStack {
                    Text(Strings.Settings.version)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--")
                        .foregroundStyle(.secondary)
                }

                Text(Strings.LocationRationale.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await scheduleManager.refreshPermissionSummary()
        }
        .sheet(isPresented: $showAlarmInfo) {
            NavigationStack {
                AlarmInfoView()
            }
            .presentationDetents([.medium, .large])
            .sheetMaterialBackground()
        }
    }

    private var defaultAlarmsCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                defaultEnabledSection
                suhoorTimingSection
                reminderTimingSection
                activePeriodSection
                alarmsListRangeSection
            }
        }
    }

    private var defaultEnabledSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            SectionHeaderView(Strings.Settings.defaultsEnabledSection)
            Text(Strings.Settings.defaultsEnabledHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle(Strings.Settings.defaultSuhoorToggle, isOn: suhoorDefaultBinding)
            Toggle(Strings.Settings.defaultReminderToggle, isOn: reminderDefaultBinding)
            Toggle(Strings.Settings.defaultFajrToggle, isOn: fajrDefaultBinding)
        }
    }

    private var suhoorTimingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            SectionHeaderView(Strings.Settings.suhoorTimingSection)
            Text(Strings.Settings.suhoorTimingHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker(Strings.Settings.suhoorTimeBasedOn, selection: suhoorTimeModeBinding) {
                ForEach(SuhoorTimeMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
                DatePicker(
                    Strings.AlarmsTab.suhoorTime,
                    selection: defaultSuhoorTimeBinding,
                    displayedComponents: [.hourAndMinute]
                )
            } else {
                OffsetPickerView(
                    baseMinutes: defaultSuhoorOffsetBinding,
                    presetMinutes: [15, 30, 45, 60, 90],
                    range: 5...240,
                    step: 5,
                    sentenceText: { "Wake me \($0) min before Fajr." }
                )
            }
        }
    }

    private var reminderTimingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            SectionHeaderView(Strings.Settings.reminderTimingSection)
            Text(Strings.Settings.reminderTimingHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker(Strings.Settings.reminderTimeBasedOn, selection: reminderTimeModeBinding) {
                ForEach(ReminderTimeMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime {
                DatePicker(
                    Strings.Settings.reminderTime,
                    selection: defaultReminderTimeBinding,
                    displayedComponents: [.hourAndMinute]
                )

                if showsReminderBeforeSuhoorWarning {
                    Text(Strings.Settings.reminderBeforeSuhoorWarning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } else {
                Stepper(value: reminderDefaultOffsetBinding, in: 5...maxReminderDefaultOffset, step: 1) {
                    Text(Strings.AlarmsTab.reminderOffsetLabel(reminderDefaultOffsetBinding.wrappedValue))
                }

                if showsReminderBeforeSuhoorWarning {
                    Text(Strings.Settings.reminderBeforeSuhoorWarning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var activePeriodSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            SectionHeaderView(Strings.Settings.activePeriodSection)
            Text(Strings.Settings.activePeriodHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker(Strings.Settings.defaultsActive, selection: activationModeBinding) {
                Text(Strings.Settings.activeAlways).tag(AlarmActivationMode.alwaysOn)
                Text(Strings.Settings.activeDateRange).tag(AlarmActivationMode.dateRange)
            }
            .pickerStyle(.segmented)

            if alarmConfigStore.defaults.activationMode == .dateRange {
                DatePicker(
                    Strings.AlarmsTab.activeStartDate,
                    selection: activeStartDateBinding,
                    displayedComponents: [.date]
                )

                DatePicker(
                    Strings.AlarmsTab.activeEndDate,
                    selection: activeEndDateBinding,
                    displayedComponents: [.date]
                )
            }
        }
    }

    private var alarmsListRangeSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            SectionHeaderView(Strings.Settings.alarmsListRangeSection)
            Text(Strings.Settings.alarmsListRangeHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker(Strings.Settings.alarmsListRangeLabel, selection: scheduleWindowBinding) {
                Text("7").tag(7)
                Text("14").tag(14)
                Text("30").tag(30)
            }
            .pickerStyle(.segmented)
        }
    }

    private var locationCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.Settings.locationSection, meta: locationSummaryText)

                NavigationLink {
                    LocationSettingsView()
                        .environmentObject(settingsStore)
                        .environmentObject(scheduleManager)
                        .environmentObject(locationService)
                } label: {
                    ActionRowView(title: Strings.Settings.locationSettings, systemImage: "location.circle")
                }
                .buttonStyle(PressableRowButtonStyle())
            }
        }
    }

    private var calculationCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.Settings.calculationSection)

                Picker(Strings.Settings.method, selection: $settingsStore.settings.calculationMethod) {
                    ForEach(CalculationMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settingsStore.settings.calculationMethod) { _, _ in
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                }

                Stepper(value: $settingsStore.settings.fajrAdjustmentMinutes, in: -30...30, step: 1) {
                    Text("\(Strings.Settings.fajrAdjustment): \(settingsStore.settings.fajrAdjustmentMinutes)m")
                }
                .onChange(of: settingsStore.settings.fajrAdjustmentMinutes) { _, _ in
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                }

                Text(Strings.Settings.fajrAdjustmentHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }


    private var permissionsCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.Settings.permissionsSection)

                HStack {
                    Text("\(Strings.Settings.locationStatus): \(locationStatusText)")
                    Spacer()
                    Button(Strings.AlarmList.openSettings) { openAppSettings() }
                        .font(.footnote)
                }

                HStack {
                    Text("\(Strings.Settings.notificationsStatus): \(notificationsStatusText)")
                    Spacer()
                    Button(Strings.AlarmList.openSettings) { openAppSettings() }
                        .font(.footnote)
                }

                HStack {
                    Text("AlarmKit")
                    Spacer()
                    Text(scheduleManager.alarmAuthorizationText)
                        .foregroundStyle(.secondary)
                }

                Button(Strings.Settings.aboutAlarms) { showAlarmInfo = true }
                    .font(.footnote.weight(.semibold))
            }
        }
    }

    private var diagnosticsCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView("Diagnostics")

                NavigationLink {
                    DiagnosticsView()
                        .environmentObject(scheduleManager)
                } label: {
                    ActionRowView(title: "Scheduling audit & logs", systemImage: "waveform.path.ecg")
                }
                .buttonStyle(PressableRowButtonStyle())

                if FeatureFlags.enableAlarmKitTestMode {
                    NavigationLink {
                        AlarmKitTestModeView(testSettingsStore: scheduleManager.testSettingsStore)
                            .environmentObject(scheduleManager)
                    } label: {
                        ActionRowView(title: "AlarmKit Test Mode", systemImage: "alarm")
                    }
                    .buttonStyle(PressableRowButtonStyle())
                }
            }
        }
    }

    private var aboutCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.Settings.aboutSection)

                HStack {
                    Text(Strings.Settings.version)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--")
                        .foregroundStyle(.secondary)
                }

                Text(Strings.LocationRationale.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not set"
        @unknown default:
            return "Unknown"
        }
    }

    private var notificationsStatusText: String {
        let text = scheduleManager.notificationAuthorizationText
        if text == "Not Determined" { return "Not set" }
        return text
    }

    private var extraOneOffDates: [Date] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return alarmConfigStore.defaults.extraOneOffDates
            .compactMap { formatter.date(from: $0) }
            .sorted()
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var locationSummaryText: String {
        switch settingsStore.settings.locationMode {
        case .auto:
            return Strings.Settings.locationAuto
        case .fixed:
            guard let fixed = settingsStore.settings.fixedLocation else {
                return Strings.Settings.locationCity
            }
            if let city = City.all.first(where: {
                abs($0.latitude - fixed.latitude) < 0.001 && abs($0.longitude - fixed.longitude) < 0.001
            }) {
                return city.name
            }
            return Strings.Settings.locationCustom
        }
    }

    private var suhoorDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.suhoorEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.suhoorEnabledDefault = newValue
            if newValue {
                Task { _ = await scheduleManager.enableFromUserAction() }
            } else {
                rescheduleFromDefaults()
            }
        })
    }

    private var reminderDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.reminderEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.reminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var fajrDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.fajrEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.fajrEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var suhoorTimeModeBinding: Binding<SuhoorTimeMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorTimeMode
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorTimeMode = newValue
            if newValue == .fixedTime, let wakeDate = scheduleManager.schedules.first?.wakeDate {
                alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = minutesFromMidnight(for: wakeDate)
            } else if newValue == .relativeToFajrMinusMinutes,
                      alarmConfigStore.defaults.defaultSuhoorOffsetMinutes > 240 {
                alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = 30
            }
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = newValue
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultSuhoorOffsetMinutes)
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = minutesFromMidnight(for: newValue)
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr
        }, set: { newValue in
            let clamped = min(newValue, maxReminderDefaultOffset)
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr = clamped
            reminderTimeClamped = clamped != newValue
            rescheduleFromDefaults()
        })
    }

    private var reminderTimeModeBinding: Binding<ReminderTimeMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderTimeMode
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderTimeMode = newValue
            if newValue == .fixedTime {
                let reminderSeed = scheduleManager.schedules.first?.reminderDate
                    ?? scheduleManager.schedules.first?.fajrDate
                    ?? Date()
                alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: reminderSeed)
                clampReminderFixedTimeIfNeeded()
            } else {
                reminderTimeClamped = false
            }
            rescheduleFromDefaults()
        })
    }

    private var defaultReminderTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultReminderFixedTimeMinutes)
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: newValue)
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var showsReminderBeforeSuhoorWarning: Bool {
        reminderTimeClamped
    }

    private var maxReminderDefaultOffset: Int {
        guard let schedule = scheduleManager.schedules.first else { return 180 }
        let minutesBetween = Int(round(schedule.fajrDate.timeIntervalSince(schedule.wakeDate) / 60))
        return max(1, min(180, minutesBetween))
    }

    private var scheduleWindowBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.scheduleWindowDays
        }, set: { newValue in
            alarmConfigStore.defaults.scheduleWindowDays = newValue
            rescheduleFromDefaults()
        })
    }

    private var activationModeBinding: Binding<AlarmActivationMode> {
        Binding(get: {
            alarmConfigStore.defaults.activationMode
        }, set: { newValue in
            alarmConfigStore.defaults.activationMode = newValue
            if newValue == .alwaysOn {
                alarmConfigStore.defaults.activeStartDate = nil
                alarmConfigStore.defaults.activeEndDate = nil
            } else {
                if alarmConfigStore.defaults.activeStartDate == nil {
                    alarmConfigStore.defaults.activeStartDate = DateHelpers.startOfToday(in: .current)
                }
                if alarmConfigStore.defaults.activeEndDate == nil {
                    alarmConfigStore.defaults.activeEndDate = DateHelpers.startOfToday(in: .current)
                }
            }
            rescheduleFromDefaults()
        })
    }

    private var activeStartDateBinding: Binding<Date> {
        Binding(get: {
            alarmConfigStore.defaults.activeStartDate ?? DateHelpers.startOfToday(in: .current)
        }, set: { newValue in
            let start = calendar.startOfDay(for: newValue)
            alarmConfigStore.defaults.activeStartDate = start
            if let end = alarmConfigStore.defaults.activeEndDate, end < start {
                alarmConfigStore.defaults.activeEndDate = start
            }
            rescheduleFromDefaults()
        })
    }

    private var activeEndDateBinding: Binding<Date> {
        Binding(get: {
            alarmConfigStore.defaults.activeEndDate ?? DateHelpers.startOfToday(in: .current)
        }, set: { newValue in
            let end = calendar.startOfDay(for: newValue)
            alarmConfigStore.defaults.activeEndDate = end
            if let start = alarmConfigStore.defaults.activeStartDate, start > end {
                alarmConfigStore.defaults.activeStartDate = end
            }
            rescheduleFromDefaults()
        })
    }

    private func rescheduleFromDefaults() {
        Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
    }

    private func clampReminderFixedTimeIfNeeded() {
        guard alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime else {
            reminderTimeClamped = false
            return
        }
        guard let suhoorTime = defaultSuhoorSampleTime else { return }
        let reminderTime = dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultReminderFixedTimeMinutes)
        let validation = TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: reminderTime)
        reminderTimeClamped = validation.wasClampedToSuhoor
        if validation.wasClampedToSuhoor {
            alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: validation.reminderTime)
        }
    }

    private var defaultSuhoorSampleTime: Date? {
        if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultSuhoorOffsetMinutes)
        }
        return scheduleManager.schedules.first?.wakeDate
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func minutesFromMidnight(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return max(0, Int(round(date.timeIntervalSince(start) / 60)))
    }

    private func dateFromMidnight(for day: Date, minutes: Int) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}

private struct AdditionalActiveDaysView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        List {
            if extraOneOffDates.isEmpty {
                Text("No additional active days yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(extraOneOffDates, id: \.self) { date in
                    Text(GregorianDateFormatter.shared.headerString(for: date))
                }
                .onDelete(perform: delete)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Additional active days")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var extraOneOffDates: [Date] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return alarmConfigStore.defaults.extraOneOffDates
            .compactMap { formatter.date(from: $0) }
            .sorted()
    }

    private func delete(at offsets: IndexSet) {
        let dates = extraOneOffDates
        for index in offsets {
            let date = dates[index]
            alarmConfigStore.removeExtraOneOffDate(date, timeZone: .current)
            alarmConfigStore.removeOverride(for: date, timeZone: .current)
            Task { await scheduleManager.cancelDay(date) }
        }
    }
}
