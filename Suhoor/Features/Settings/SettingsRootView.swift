import SwiftUI
import UIKit
import CoreLocation

struct SettingsRootView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var showAlarmInfo = false
    @State private var scrollOffset: CGFloat = 0
    @State private var topInset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("settingsScroll")).minY
                                )
                            }
                        )

                    VStack(spacing: DesignTokens.spacingL) {
                        defaultAlarmsCard
                        locationCard
                        calculationCard
                        permissionsCard
                        diagnosticsCard
                        aboutCard
                    }
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.headerMaxHeight + topInset + DesignTokens.spacingS)
                    .padding(.bottom, DesignTokens.spacingM)
                }
                .coordinateSpace(name: "settingsScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .readTopSafeAreaInset { topInset = $0 }
            .overlay(alignment: .top) {
                let maxCollapse = DesignTokens.headerMaxHeight - DesignTokens.headerMinHeight
                let progress = min(1, max(0, (-scrollOffset) / maxCollapse))
                CollapsingHeaderView(
                    title: Strings.Settings.title,
                    subtitle: nil,
                    tertiary: nil,
                    progress: progress,
                    topInset: topInset
                )
            }
        }
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
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.AlarmsTab.defaultsSection)

                Toggle(Strings.AlarmsTab.suhoorLabel, isOn: suhoorDefaultBinding)
                Toggle(Strings.AlarmsTab.reminderLabel, isOn: reminderDefaultBinding)
                Toggle(Strings.AlarmsTab.fajrLabel, isOn: fajrDefaultBinding)

                Picker(Strings.AlarmsTab.suhoorMode, selection: suhoorTimeModeBinding) {
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

                Stepper(value: reminderDefaultOffsetBinding, in: 1...maxReminderDefaultOffset, step: 1) {
                    Text(Strings.AlarmsTab.reminderOffsetLabel(reminderDefaultOffsetBinding.wrappedValue))
                }

                Picker(Strings.AlarmsTab.scheduleWindow, selection: scheduleWindowBinding) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)

                Picker(Strings.AlarmsTab.activationMode, selection: activationModeBinding) {
                    ForEach(AlarmActivationMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
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
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = newValue
            if alarmConfigStore.defaults.defaultSuhoorTimeMode == .relativeToFajrMinusMinutes,
               alarmConfigStore.defaults.defaultReminderOffsetMinutes >= newValue {
                alarmConfigStore.defaults.defaultReminderOffsetMinutes = max(1, newValue - 1)
            }
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultSuhoorOffsetMinutes)
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = minutesFromMidnight(for: newValue)
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderOffsetMinutes
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderOffsetMinutes = min(newValue, maxReminderDefaultOffset)
            rescheduleFromDefaults()
        })
    }

    private var maxReminderDefaultOffset: Int {
        if alarmConfigStore.defaults.defaultSuhoorTimeMode == .relativeToFajrMinusMinutes {
            return max(1, alarmConfigStore.defaults.defaultSuhoorOffsetMinutes - 1)
        }
        return 240
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
