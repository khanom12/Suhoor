import SwiftUI
import CoreLocation
import UIKit

struct AlarmsListView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var showAlarmInfo = false
    @State private var showLocationRationale = false
    @State private var showNotificationRationale = false
    @State private var pendingEnable = false

    private let calculator = PrayerTimeCalculator()
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
                                    value: proxy.frame(in: .named("alarmScroll")).minY
                                )
                            }
                        )

                    VStack(spacing: DesignTokens.spacingL) {
                        PermissionStackView(
                            kinds: [.location, .alarmKit, .notifications],
                            refreshKey: permissionRefreshKey,
                            showOnlyBlocking: true,
                            onOpenSettings: openSettings
                        )
                        .environmentObject(scheduleManager)

                        if let banner = banner {
                            GlassCard(style: .header, padding: DesignTokens.spacingM) {
                                MaterialBannerView(
                                    title: banner.title,
                                    message: banner.message,
                                    actionTitle: banner.actionTitle,
                                    action: { handleBannerTap(banner) }
                                )
                            }
                        }

                        GlassCard(style: .normal) {
                            wakeRow
                        }

                        GlassCard(style: .normal) {
                            reminderRow
                        }

                        GlassCard(style: .normal) {
                            fajrRow
                        }

                        if let failureText = scheduleManager.lastEnableFailureMessage {
                            Text(failureText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.headerMaxHeight + topInset + DesignTokens.spacingS)
                    .padding(.bottom, DesignTokens.spacingM)
                }
                .coordinateSpace(name: "alarmScroll")
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
                    title: nextAlarmTitleLine,
                    subtitle: nextAlarmDateLine,
                    tertiary: nextFajrTitleLine,
                    progress: progress,
                    topInset: topInset
                )
            }
        }
        .onChange(of: settingsStore.settings.baseWakeOffsetMinutes) { _, newValue in
            guard newValue > 0 else { return }
            let maxReminder = max(1, newValue - 1)
            if settingsStore.settings.reminderMinutesBeforeFajrGlobal >= maxReminder {
                settingsStore.settings.reminderMinutesBeforeFajrGlobal = maxReminder
            }
        }
        .onChange(of: locationService.authorizationStatus) { _, newValue in
            if pendingEnable,
               newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                pendingEnable = false
                Task { _ = await scheduleManager.enableFromUserAction() }
            }
        }
        .sheet(isPresented: $showAlarmInfo) {
            NavigationStack {
                AlarmInfoView()
            }
            .presentationDetents([.medium, .large])
            .sheetMaterialBackground()
        }
        .sheet(isPresented: $showLocationRationale) {
            NavigationStack {
                LocationRationaleView(
                    onContinue: {
                        showLocationRationale = false
                        pendingEnable = true
                        locationService.requestAuthorization()
                    },
                    onNotNow: {
                        showLocationRationale = false
                        pendingEnable = false
                    }
                )
            }
            .presentationDetents([.medium])
            .sheetMaterialBackground()
        }
        .sheet(isPresented: $showNotificationRationale) {
            NavigationStack {
                NotificationRationaleView(
                    onContinue: {
                        showNotificationRationale = false
                        Task { _ = await scheduleManager.enableFromUserAction() }
                    },
                    onNotNow: {
                        showNotificationRationale = false
                    }
                )
            }
            .presentationDetents([.medium])
            .sheetMaterialBackground()
        }
    }

    private var nextSchedule: DaySchedule? {
        scheduleManager.nextUpcomingSchedule
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settingsStore.settings, timeZone: .current)
    }


    private var nextWakeTimeText: String {
        guard settingsStore.settings.isEnabled, let schedule = nextSchedule else {
            return Strings.AlarmList.placeholderTime
        }
        return TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var nextReminderTimeText: String {
        guard let schedule = nextSchedule else {
            return settingsStore.settings.reminderEnabledGlobal ? Strings.AlarmList.placeholderTime : Strings.AlarmList.offLabel
        }
        guard ruleEngine.effectiveReminderEnabled(for: schedule.date) else {
            return Strings.AlarmList.offLabel
        }
        guard let reminderDate = schedule.reminderDate else {
            return Strings.AlarmList.offLabel
        }
        return TimeFormatters.timeFormatter.string(from: reminderDate)
    }

    private var nextFajrTimeText: String {
        guard let schedule = nextSchedule else {
            return settingsStore.settings.atFajrEnabledGlobal ? Strings.AlarmList.placeholderTime : Strings.AlarmList.offLabel
        }
        guard ruleEngine.effectiveAtFajrEnabled(for: schedule.date) else {
            return Strings.AlarmList.offLabel
        }
        return TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var nextReminderMinutesEffective: Int {
        guard let schedule = nextSchedule else { return settingsStore.settings.reminderMinutesBeforeFajrGlobal }
        return ruleEngine.effectiveReminderMinutes(for: schedule.date)
    }

    private var nextFajrSoundChoice: SoundChoice {
        guard let schedule = nextSchedule else { return settingsStore.settings.atFajrSoundSelectionGlobal }
        return ruleEngine.effectiveAtFajrSoundChoice(for: schedule.date)
    }

    private var wakeSubtitleText: String {
        Strings.AlarmList.wakeSubtitle(settingsStore.settings.baseWakeOffsetMinutes)
    }

    private var reminderSubtitleText: String {
        Strings.AlarmList.reminderSubtitle(settingsStore.settings.reminderMinutesBeforeFajrGlobal)
    }

    private var fajrSubtitleText: String {
        Strings.AlarmList.fajrSubtitle
    }

    private var wakeRow: some View {
        NavigationLink {
            OffsetPickerScreen(title: Strings.AlarmDetail.wakeMe, baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes, range: 1...240, step: 1)
        } label: {
            RoutineRowLayout(
                timeText: nextWakeTimeText,
                titleText: "",
                subtitleText: wakeSubtitleText,
                isEnabled: settingsStore.settings.isEnabled,
                showsChevron: true,
                trailing: {
                    Toggle("", isOn: masterEnabledBinding)
                        .labelsHidden()
                },
                footer: {
                    EmptyView()
                }
            )
        }
        .buttonStyle(PressableRowButtonStyle())
    }

    private var reminderRow: some View {
        NavigationLink {
            ReminderMinutesPickerScreen(minutes: reminderMinutesBinding, maxMinutes: maxReminderMinutes)
        } label: {
            RoutineRowLayout(
                timeText: nextReminderTimeText,
                titleText: "",
                subtitleText: reminderSubtitleText,
                isEnabled: settingsStore.settings.isEnabled && nextReminderEnabledEffective,
                showsChevron: true,
                trailing: {
                    Toggle("", isOn: reminderEnabledBinding)
                        .labelsHidden()
                        .disabled(!settingsStore.settings.isEnabled)
                },
                footer: {
                    EmptyView()
                }
            )
        }
        .buttonStyle(PressableRowButtonStyle())
    }

    private var fajrRow: some View {
        RoutineRowLayout(
            timeText: nextFajrTimeText,
            titleText: "",
            subtitleText: fajrSubtitleText,
            isEnabled: nextFajrEnabledEffective,
            showsChevron: false,
            trailing: {
                Toggle("", isOn: atFajrEnabledBinding)
                    .labelsHidden()
            },
            footer: {
                EmptyView()
            }
        )
    }

    private var nextReminderEnabledEffective: Bool {
        guard let schedule = nextSchedule else { return false }
        return ruleEngine.effectiveReminderEnabled(for: schedule.date)
    }

    private var nextFajrEnabledEffective: Bool {
        guard let schedule = nextSchedule else { return false }
        return ruleEngine.effectiveAtFajrEnabled(for: schedule.date)
    }

    private var masterEnabledBinding: Binding<Bool> {
        Binding(get: { settingsStore.settings.isEnabled }, set: { isOn in
            Task { await handleToggle(isOn) }
        })
    }

    private var banner: AlarmBanner? {
        if settingsStore.settings.isEnabled, scheduleManager.isAlarmKitUnavailable {
            return AlarmBanner(
                title: Strings.AlarmList.alarmKitUnavailableTitle,
                message: bannerMessage,
                actionTitle: Strings.AlarmList.learnMore,
                action: .showAlarmInfo
            )
        }
        return nil
    }

    private var bannerMessage: String? {
        if scheduleManager.isAlarmKitDenied {
            return Strings.AlarmList.alarmDenied
        }
        return Strings.AlarmList.alarmKitUnavailableBody
    }

    private func handleToggle(_ isOn: Bool) async {
        EventTimelineLog.shared.record(category: "toggle", message: "Wake toggled \(isOn)")
        if isOn {
            if locationService.authorizationStatus == .notDetermined {
                showLocationRationale = true
                return
            }
            if notificationsRequired && scheduleManager.notificationAuthorizationText == "Not Determined" {
                showNotificationRationale = true
                return
            }
            _ = await scheduleManager.enableFromUserAction()
        } else {
            settingsStore.settings.reminderEnabledGlobal = false
            await scheduleManager.disableFromUserAction()
        }
    }

    private var notificationsRequired: Bool {
        scheduleManager.isAlarmKitUnavailable
            || scheduleManager.isAlarmKitDenied
            || settingsStore.settings.hasAnyReminderEnabled
            || settingsStore.settings.hasAnyAtFajrNonDefaultSound
    }

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func handleBannerTap(_ banner: AlarmBanner) {
        switch banner.action {
        case .showAlarmInfo:
            showAlarmInfo = true
        case .requestLocation:
            locationService.requestAuthorization()
        case .openSettings:
            openSettings()
        case .retryLocation:
            locationService.requestLocation()
        }
    }

    private var nextAlarmDate: Date? {
        if settingsStore.settings.isEnabled {
            return nextSchedule?.wakeDate ?? fallbackFajrDate
        }
        return fallbackFajrDate
    }

    private var nextAlarmTitleLine: String {
        guard let date = nextAlarmDate else {
            return Strings.AlarmList.nextAlarmTitleLine(prefix: Strings.AlarmList.offLabel)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let prefix = calendar.isDateInToday(date) ? Strings.AlarmList.todayLabel : Strings.AlarmList.tomorrowLabel
        return Strings.AlarmList.nextAlarmTitleLine(prefix: prefix)
    }

    private var nextAlarmDateLine: String {
        guard let date = nextAlarmDate else {
            return Strings.AlarmList.placeholderTime
        }
        return TimeFormatters.fullDateTitle.string(from: date)
    }

    private var nextFajrTitleLine: String {
        let fajrDate = nextSchedule?.fajrDate ?? fallbackFajrDate
        let fajrTime = fajrDate.map { TimeFormatters.timeFormatter.string(from: $0) } ?? Strings.AlarmList.placeholderTime
        if let locationName = locationDisplayName, !locationName.isEmpty {
            return "Fajr \(fajrTime) • \(locationName)"
        }
        return "Fajr \(fajrTime)"
    }

    private var maxReminderMinutes: Int {
        max(1, settingsStore.settings.baseWakeOffsetMinutes - 1)
    }

    private var reminderMinutesBinding: Binding<Int> {
        Binding(get: {
            settingsStore.settings.reminderMinutesBeforeFajrGlobal
        }, set: { newValue in
            settingsStore.settings.reminderMinutesBeforeFajrGlobal = min(newValue, maxReminderMinutes)
        })
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(get: {
            settingsStore.settings.isEnabled && settingsStore.settings.reminderEnabledGlobal
        }, set: { newValue in
            guard settingsStore.settings.isEnabled else {
                settingsStore.settings.reminderEnabledGlobal = false
                return
            }
            settingsStore.settings.reminderEnabledGlobal = newValue
            EventTimelineLog.shared.record(category: "toggle", message: "Reminder toggled \(newValue)")
        })
    }

    private var atFajrEnabledBinding: Binding<Bool> {
        Binding(get: {
            settingsStore.settings.atFajrEnabledGlobal
        }, set: { newValue in
            settingsStore.settings.atFajrEnabledGlobal = newValue
            EventTimelineLog.shared.record(category: "toggle", message: "Adhan toggled \(newValue)")
        })
    }

    private var fallbackFajrDate: Date? {
        guard let coordinate = fallbackCoordinate else { return nil }
        let timeZone = TimeZone.current
        let today = DateHelpers.startOfToday(in: timeZone)
        if let fajrToday = calculator.fajrDate(
            for: today,
            location: coordinate,
            timeZone: timeZone,
            method: settingsStore.settings.calculationMethod,
            adjustmentMinutes: settingsStore.settings.fajrAdjustmentMinutes
        ), fajrToday > Date() {
            return fajrToday
        }
        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone)
        return calculator.fajrDate(
            for: tomorrow,
            location: coordinate,
            timeZone: timeZone,
            method: settingsStore.settings.calculationMethod,
            adjustmentMinutes: settingsStore.settings.fajrAdjustmentMinutes
        )
    }

    private var fallbackCoordinate: CLLocationCoordinate2D? {
        switch settingsStore.settings.locationMode {
        case .auto:
            return locationService.lastLocation?.coordinate
        case .fixed:
            guard let fixed = settingsStore.settings.fixedLocation else { return nil }
            return CLLocationCoordinate2D(latitude: fixed.latitude, longitude: fixed.longitude)
        }
    }

    private var locationDisplayName: String? {
        switch settingsStore.settings.locationMode {
        case .auto:
            return locationService.locationName.isEmpty ? nil : locationService.locationName
        case .fixed:
            if let fixed = settingsStore.settings.fixedLocation,
               let city = City.all.first(where: {
                   abs($0.latitude - fixed.latitude) < 0.001 && abs($0.longitude - fixed.longitude) < 0.001
               }) {
                return city.name
            }
            return locationService.locationName.isEmpty ? nil : locationService.locationName
        }
    }
}

private struct RoutineRowLayout<Trailing: View, Footer: View>: View {
    let timeText: String
    let titleText: String
    let subtitleText: String
    let isEnabled: Bool
    let showsChevron: Bool
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            HStack(alignment: .center, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 4) {
                    TimeText(text: timeText, font: DesignTokens.primaryTimeFont, isEnabled: isEnabled)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    if !titleText.isEmpty {
                        Text(titleText)
                            .font(DesignTokens.rowTitleFont)
                            .foregroundStyle(.primary)
                    }

                    Text(subtitleText)
                        .font(DesignTokens.rowSubtitleFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: DesignTokens.spacingS) {
                    trailing()
                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            footer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct AlarmBanner {
    enum Action {
        case showAlarmInfo
        case requestLocation
        case openSettings
        case retryLocation
    }

    let title: String
    let message: String?
    let actionTitle: String?
    let action: Action
}

private struct AlarmTitleView: View {
    let titleLine: String
    let dateLine: String
    let fajrLine: String

    var body: some View {
        VStack(spacing: 2) {
            Text(titleLine)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
            Text(dateLine)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
            Text(fajrLine)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
        .padding(.top, -4)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

private struct LocationRationaleView: View {
    let onContinue: () -> Void
    let onNotNow: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text(Strings.LocationRationale.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(Strings.LocationRationale.continueButton) {
                    dismiss()
                    onContinue()
                }
                Button(Strings.LocationRationale.notNowButton) {
                    dismiss()
                    onNotNow()
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Strings.LocationRationale.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationRationaleView: View {
    let onContinue: () -> Void
    let onNotNow: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text(Strings.NotificationRationale.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(Strings.NotificationRationale.continueButton) {
                    dismiss()
                    onContinue()
                }
                Button(Strings.NotificationRationale.notNowButton) {
                    dismiss()
                    onNotNow()
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Strings.NotificationRationale.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReminderMinutesPickerScreen: View {
    @Binding var minutes: Int
    let maxMinutes: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            OffsetPickerView(
                baseMinutes: $minutes,
                presetMinutes: [5, 10, 15, 20, 30].filter { $0 <= maxMinutes },
                range: 1...maxMinutes,
                step: 1,
                sentenceText: { "Remind me \($0) min before Fajr." }
            )
        }
        .navigationTitle(Strings.AlarmList.reminderMinutesLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
