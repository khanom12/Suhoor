import SwiftUI
import UIKit

struct SettingsRootView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @State private var showingCopiedAlert = false

    var body: some View {
        SettingsScrollPage {
            if !issues.isEmpty {
                SettingsGroup(title: Strings.Settings.needsAttentionSection) {
                    ForEach(issues) { issue in
                        NavigationLink {
                            destinationView(for: issue.destination)
                        } label: {
                            SettingsRow {
                                SettingsSummaryRow(
                                    title: issue.title,
                                    subtitle: issue.message,
                                    systemImage: issue.systemImage,
                                    badgeText: issue.statusText,
                                    badgeTone: badgeTone(for: issue.tone),
                                    showsDisclosureIndicator: true
                                )
                            }
                        }

                        if issue.id != issues.last?.id {
                            AppGroupDivider()
                        }
                    }
                }
            }

#if DEBUG || INTERNAL_TESTING
            if WakeSessionLabBuildGate.isAvailableInCurrentBuild {
                SettingsGroup(title: "Developer") {
                    NavigationLink {
                        WakeSessionLabView(harness: scheduleManager.wakeSessionTestingHarness)
                    } label: {
                        SettingsRow {
                            SettingsSummaryRow(
                                title: "Wake Session Lab",
                                subtitle: "Preview Home UI, run real alarm tests, and inspect diagnostics.",
                                systemImage: "testtube.2",
                                badgeText: "Debug",
                                badgeTone: .warning,
                                showsDisclosureIndicator: true
                            )
                        }
                    }
                }
            }
#endif

            ForEach(SettingsDestinationGroup.allCases) { group in
                SettingsGroup(title: group.title) {
                    ForEach(Array(group.destinations.enumerated()), id: \.element.id) { index, destination in
                        NavigationLink {
                            destinationView(for: destination)
                        } label: {
                            SettingsRow {
                                SettingsSummaryRow(
                                    title: destination.title,
                                    subtitle: summary(for: destination),
                                    systemImage: destination.systemImage,
                                    badgeText: badgeText(for: destination),
                                    badgeTone: badgeTone(for: destination),
                                    showsDisclosureIndicator: true
                                )
                            }
                        }

                        if index < group.destinations.count - 1 {
                            AppGroupDivider()
                        }
                    }
                }
            }

            SettingsGroup(
                title: "Support",
                footer: "Diagnostics leave out precise location unless you add it yourself."
            ) {
                Button {
                    openFeedbackEmail()
                } label: {
                    SettingsRow {
                        SettingsSummaryRow(
                            title: "Send Feedback",
                            subtitle: "Share feedback or report a problem.",
                            systemImage: "envelope",
                            badgeText: nil,
                            badgeTone: .neutral
                        )
                    }
                }
                .buttonStyle(.plain)

                AppGroupDivider()

                Button {
                    UIPasteboard.general.string = diagnosticsText
                    showingCopiedAlert = true
                } label: {
                    SettingsRow {
                        SettingsSummaryRow(
                            title: "Copy Diagnostics",
                            subtitle: "Version, device, locale, and permission summary.",
                            systemImage: "doc.on.doc",
                            badgeText: nil,
                            badgeTone: .neutral
                        )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Diagnostics copied to clipboard.")
        }
    }

    private var issues: [SettingsIssue] {
        SettingsSummaryFormatter.issues(
            settings: settingsStore.settings,
            schedulingMode: scheduleManager.schedulingMode,
            presentations: permissionPresentations
        )
    }

    private func summary(for destination: SettingsDestination) -> String {
        switch destination {
        case .location:
            return SettingsSummaryFormatter.locationSummary(settings: settingsStore.settings, locationService: locationService)
        case .prayerTimes:
            return SettingsSummaryFormatter.prayerTimesSummary(settings: settingsStore.settings)
        case .hijriCalendarCorrections:
            return SettingsSummaryFormatter.hijriCorrectionsSummary(scheduleManager: scheduleManager)
        case .alarmBehavior:
            let pause = settingsStore.settings.wakeAlarmsPausedIndefinitely ? "Alarms paused" : "Alarms active"
            return [
                pause,
                "Sounds \(ProductSurfacePresentation.soundSummaryText(settings: settingsStore.settings))",
                "Reserve \(settingsStore.settings.clampedReserveBeforeEndMinutes) min",
                "Fajr start \(settingsStore.settings.fajrStartSoundSelectionGlobal.displayName)"
            ].joined(separator: " · ")
        case .permissionsReliability:
            return reliabilitySummary
        case .quietPeriod:
            if !settingsStore.settings.quietPeriodEnabled {
                return Strings.QuietPeriod.summaryOff
            }
            if settingsStore.settings.pausePrayerPrompts && settingsStore.settings.pauseFastingPrompts {
                return Strings.QuietPeriod.summaryOn
            }
            return Strings.QuietPeriod.summaryPartial
        case .about:
            return SettingsSummaryFormatter.aboutSummary(version: appVersion)
        }
    }

    private func badgeText(for destination: SettingsDestination) -> String? {
        switch destination {
        case .prayerTimes, .hijriCalendarCorrections, .alarmBehavior, .about:
            return nil
        case .quietPeriod:
            return settingsStore.settings.quietPeriodEnabled ? "On" : nil
        case .location:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .location }) {
                return issues.first(where: { $0.destination == .location })?.statusText
            }
            return nil
        case .permissionsReliability:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .permissionsReliability }) {
                return nil
            }
            if scheduleManager.schedulingMode == .notifications {
                return Strings.Settings.badgeUsingFallback
            }
            return Strings.Settings.badgeReady
        }
    }

    private func badgeTone(for destination: SettingsDestination) -> SettingsBadgeTone {
        switch destination {
        case .permissionsReliability:
            guard hasLoadedPermissions else { return .neutral }
            let permissionIssues = issues.filter { $0.destination == .permissionsReliability }
            if permissionIssues.contains(where: { $0.tone == .critical }) {
                return .critical
            }
            if !permissionIssues.isEmpty {
                return .warning
            }
            return scheduleManager.schedulingMode == .notifications ? .warning : .success
        case .location:
            guard hasLoadedPermissions else { return .neutral }
            if let issue = issues.first(where: { $0.destination == .location }) {
                return badgeTone(for: issue.tone)
            }
            return .neutral
        case .prayerTimes, .hijriCalendarCorrections, .alarmBehavior, .about:
            return .neutral
        case .quietPeriod:
            return settingsStore.settings.quietPeriodEnabled ? .warning : .neutral
        }
    }

    private func badgeTone(for tone: SettingsIssue.Tone) -> SettingsBadgeTone {
        switch tone {
        case .warning:
            return .warning
        case .critical:
            return .critical
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .location:
            LocationSettingsView()
        case .prayerTimes:
            PrayerTimeSettingsView()
        case .hijriCalendarCorrections:
            HijriCalendarSettingsView()
        case .alarmBehavior:
            AlarmBehaviorSettingsView()
        case .permissionsReliability:
            PermissionsReliabilityView()
        case .quietPeriod:
            QuietPeriodSettingsView()
        case .about:
            AboutSettingsView()
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--"
    }

    private var permissionPresentations: [AppPermissionKind: PermissionPresentation] {
        scheduleManager.permissionSnapshot.presentations
    }

    private var hasLoadedPermissions: Bool {
        SettingsSummaryFormatter.hasLoadedPermissions(permissionPresentations)
    }

    private var diagnosticsText: String {
        let device = UIDevice.current
        let timeZone = TimeZone.current.identifier
        let locale = Locale.current.identifier
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "--"

        return """
        Subh Diagnostics
        - Version: \(appVersion) (\(buildNumber))
        - Device: \(device.model) (\(device.systemName) \(device.systemVersion))
        - Time Zone: \(timeZone)
        - Locale: \(locale)
        - Permissions: \(scheduleManager.permissionSummary)

        \(scheduleManager.deliveryDiagnosticsText)
        """
    }

    private var reliabilitySummary: String {
        [
            "Wake delivery: \(wakeDeliveryModeText)",
            "Notifications: \(notificationPermissionText)",
            "Next scheduled wake: \(nextScheduledWakeText)",
            "Last schedule update: \(scheduleManager.lastUpdatedText)",
            "Delivery check: \(scheduleManager.deliveryReconciliationSummaryText)"
        ].joined(separator: "\n")
    }

    private var wakeDeliveryModeText: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "AlarmKit"
        case .mixed:
            return "Mixed"
        case .notifications:
            return "Notification fallback"
        case .none:
            return "Not ready"
        }
    }

    private var notificationPermissionText: String {
        permissionPresentations[.notifications]?.statusText ?? "Checking"
    }

    private var nextScheduledWakeText: String {
        guard let wakeDate = scheduleManager.nextUpcomingSchedule?.wakeDate else {
            return "--"
        }
        return TimeFormatters.shortDateTime.string(from: wakeDate)
    }

    private func openFeedbackEmail() {
        let subject = "Subh Feedback"
        let body = diagnosticsText + "\n\nWhat happened?\n"
        guard let url = mailtoURL(subject: subject, body: body) else { return }
        UIApplication.shared.open(url)
    }

    private func mailtoURL(subject: String, body: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")

        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        }

        let urlString = "mailto:?subject=\(encode(subject))&body=\(encode(body))"
        return URL(string: urlString)
    }
}

struct AlarmBehaviorSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @State private var draftSettings = AppSettings.default
    @State private var hasPendingCommit = false
    @State private var commitTask: Task<Void, Never>?

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(
                title: "Wake Alarm Pause",
                supportingText: "Pause wake alarms indefinitely while keeping your morning plans saved."
            ) {
                SettingsRow {
                    Toggle(
                        draftSettings.wakeAlarmsPausedIndefinitely ? "Alarms paused" : "Alarms active",
                        isOn: pauseBinding
                    )
                }
            }

            SettingsGroup(
                title: "Wake Sounds",
                supportingText: "Choose the sound used before Fajr, at Fajr start, during Fajr, after Fajr, and for fixed wakes."
            ) {
                soundPickerRow(
                    title: "Suhoor alarm sound",
                    binding: soundBinding(\.preFajrWakeSoundSelectionGlobal)
                )
                AppGroupDivider()
                soundPickerRow(
                    title: "At Fajr start sound",
                    binding: soundBinding(\.fajrStartSoundSelectionGlobal)
                )
                AppGroupDivider()
                soundPickerRow(
                    title: "Wake during Fajr sound",
                    binding: soundBinding(\.inFajrWakeSoundSelectionGlobal)
                )
                AppGroupDivider()
                soundPickerRow(
                    title: "Wake after Fajr sound",
                    binding: soundBinding(\.postFajrWakeSoundSelectionGlobal)
                )
                AppGroupDivider()
                soundPickerRow(
                    title: "Fixed alarm sound",
                    binding: soundBinding(\.fixedWakeSoundSelectionGlobal)
                )
            }

            SettingsGroup(
                title: "Reserve Before Fajr Ends",
                supportingText: "Applies when the default wake is In-Fajr and anchored to Fajr start."
            ) {
                SettingsRow {
                    Stepper(value: reserveBinding, in: 1...60, step: 1) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reserve")
                            Text("\(normalizedDraftSettings.clampedReserveBeforeEndMinutes) min")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Wake Alarms")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadDraftFromStore()
        }
        .onChange(of: settingsStore.currentRevision) { _, _ in
            guard !hasPendingCommit else { return }
            loadDraftFromStore()
        }
        .onDisappear {
            applyDraftIfNeeded()
        }
    }

    private func soundPickerRow(title: String, binding: Binding<SoundChoice>) -> some View {
        SettingsRow {
            Picker(title, selection: binding) {
                ForEach(SoundChoice.allCases) { choice in
                    Text(choice.displayName).tag(choice)
                }
            }
        }
    }

    private func soundBinding(_ keyPath: WritableKeyPath<AppSettings, SoundChoice>) -> Binding<SoundChoice> {
        Binding(get: {
            draftSettings[keyPath: keyPath]
        }, set: { newValue in
            draftSettings[keyPath: keyPath] = newValue
            scheduleDraftCommit()
        })
    }

    private var reserveBinding: Binding<Int> {
        Binding(get: {
            normalizedDraftSettings.clampedReserveBeforeEndMinutes
        }, set: { newValue in
            draftSettings.reserveBeforeEndMinutes = max(1, newValue)
            scheduleDraftCommit()
        })
    }

    private var pauseBinding: Binding<Bool> {
        Binding(get: {
            draftSettings.wakeAlarmsPausedIndefinitely
        }, set: { newValue in
            draftSettings.wakeAlarmsPausedIndefinitely = newValue
            scheduleDraftCommit()
        })
    }

    private var normalizedDraftSettings: AppSettings {
        var settings = draftSettings
        settings.reserveBeforeEndMinutes = max(1, settings.reserveBeforeEndMinutes)
        return settings
    }

    private func loadDraftFromStore() {
        draftSettings = settingsStore.settings
    }

    private func scheduleDraftCommit() {
        hasPendingCommit = true
        commitTask?.cancel()
        commitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            applyDraftIfNeeded()
        }
    }

    private func applyDraftIfNeeded() {
        commitTask?.cancel()
        commitTask = nil
        let nextSettings = normalizedDraftSettings
        let changed = settingsStore.settings != nextSettings
        hasPendingCommit = false
        guard changed else { return }
        settingsStore.set(nextSettings)
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }
}
