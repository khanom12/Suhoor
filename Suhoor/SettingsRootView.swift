import SwiftUI
import UIKit
import CoreLocation

struct SettingsRootView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
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
}
