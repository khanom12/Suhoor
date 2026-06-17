import SwiftUI
import UIKit

struct SettingsRootView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
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
                "Safety \(settingsStore.settings.clampedReserveBeforeEndMinutes) min",
                "Fajr start \(settingsStore.settings.fajrStartSoundSelectionGlobal.displayName)"
            ].joined(separator: " · ")
        case .defaultWakeTimes:
            if let validation = scheduleManager.defaultWakeValidation(), !validation.isValid {
                return "Needs review"
            }
            return ProductSurfacePresentation.defaultWakeTimesSummary(for: alarmConfigStore.defaults)
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
        case .defaultWakeTimes:
            if let validation = scheduleManager.defaultWakeValidation(), !validation.isValid {
                return "Needs review"
            }
            return nil
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
        case .prayerTimes, .hijriCalendarCorrections, .alarmBehavior, .defaultWakeTimes, .about:
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
        case .defaultWakeTimes:
            DefaultWakeTimesSettingsView()
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
            "Delivery check: \(scheduleManager.deliveryReconciliationSummaryText)",
            "Delivery repair: \(scheduleManager.deliveryRepairSummaryText)"
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

struct DefaultWakeTimesSettingsView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @State private var draftFajrRule = DefaultWakeRule.defaultFajr
    @State private var draftSuhoorRule = DefaultWakeRule.defaultSuhoor
    @State private var shortestFajrWindowMinutes: Int?
    @State private var longestFajrWindowMinutes: Int?
    @State private var hasPendingCommit = false
    @State private var commitTask: Task<Void, Never>?
    @State private var expandedExplanation = false
    @State private var saveMessage: String?

    private let fajrStartPresetMinutes = [0, 5, 10, 15, 30, 45]
    private let fajrEndPresetMinutes = [10, 15, 30, 45, 60]
    private let suhoorPresetMinutes = [30, 45, 60, 90]

    var body: some View {
        SettingsScrollPage {
            Text("Choose the wake times Subh should use for future mornings unless you change a specific day.")
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DesignTokens.accessoryInset)

            SettingsInfoBanner(
                title: "Manual changes are kept",
                message: "Changing defaults will not overwrite days you changed yourself.",
                systemImage: "lock"
            )
            .accessibilityElement(children: .combine)

            if currentFajrValidation?.isValid == false {
                SettingsInfoBanner(
                    title: "Your Fajr wake default needs review.",
                    message: "Your current location or Fajr time settings create a shorter Fajr window on some days. Subh will use the nearest safe wake time until you choose a new default.",
                    systemImage: "exclamationmark.triangle"
                )
                .accessibilityElement(children: .combine)
            }

            if let saveMessage {
                SettingsInfoBanner(
                    title: "Default not saved",
                    message: saveMessage,
                    systemImage: "exclamationmark.circle"
                )
                .accessibilityElement(children: .combine)
            }

            SettingsGroup(
                title: "Fajr wake default",
                supportingText: "Choose whether the default wake is based on when Fajr begins or when Fajr ends."
            ) {
                SettingsRow {
                    Picker("Wake relative to", selection: fajrAnchorBinding) {
                        Text("Fajr begins").tag(DefaultWakeAnchor.fajrStart)
                        Text("Fajr ends").tag(DefaultWakeAnchor.fajrEnd)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Wake relative to")
                }
                AppGroupDivider()
                ForEach(Array(fajrPresetRules.enumerated()), id: \.element) { index, rule in
                    defaultWakeRuleButton(rule: rule, selected: draftFajrRule == rule)
                    if index < fajrPresetRules.count - 1 {
                        AppGroupDivider()
                    }
                }
                AppGroupDivider()
                SettingsRow {
                    RelativeOffsetControl(
                        label: "Custom",
                        detail: fajrCustomDetail,
                        value: fajrCustomMinutesBinding,
                        range: fajrCustomRange,
                        step: 5
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(fajrCustomAccessibilityLabel)
                }
            }

            SettingsGroup(
                title: "Suhoor wake default",
                supportingText: "Suhoor wakes are always before Fajr begins."
            ) {
                ForEach(Array(suhoorPresetRules.enumerated()), id: \.element) { index, rule in
                    defaultWakeRuleButton(rule: rule, selected: draftSuhoorRule == rule)
                    if index < suhoorPresetRules.count - 1 {
                        AppGroupDivider()
                    }
                }
                AppGroupDivider()
                SettingsRow {
                    RelativeOffsetControl(
                        label: "Custom",
                        detail: "\(draftSuhoorRule.offsetMinutes) minutes before Fajr begins",
                        value: suhoorCustomMinutesBinding,
                        range: 5...240,
                        step: 5
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Custom Suhoor wake time")
                }
            }

            SettingsGroup {
                DisclosureGroup(isExpanded: $expandedExplanation) {
                    Text(unavailableOptionsExplanation)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DesignTokens.spacingS)
                } label: {
                    Text("Why are some options unavailable?")
                        .font(AppTypography.rowTitle)
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.vertical, DesignTokens.settingsRowVerticalPadding)
            }
        }
        .navigationTitle("Default Wake Times")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadDraftFromStore()
            refreshFajrWindowSummary()
        }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in
            guard !hasPendingCommit else { return }
            loadDraftFromStore()
            refreshFajrWindowSummary()
        }
        .onDisappear {
            applyDraftIfNeeded()
        }
    }

    private var currentFajrValidation: DefaultWakeRuleValidationResult? {
        DefaultWakeRuleValidator.validate(
            rule: draftFajrRule,
            shortestFajrWindowMinutes: shortestFajrWindowMinutes
        )
    }

    private var fajrAnchorBinding: Binding<DefaultWakeAnchor> {
        Binding(get: {
            draftFajrRule.anchor
        }, set: { newAnchor in
            switch newAnchor {
            case .fajrStart:
                draftFajrRule = DefaultWakeRule(purpose: .fajr, anchor: .fajrStart, direction: .at, offsetMinutes: 0)
            case .fajrEnd:
                draftFajrRule = DefaultWakeRule.defaultFajr
            }
            scheduleDraftCommit()
        })
    }

    private var fajrPresetRules: [DefaultWakeRule] {
        switch draftFajrRule.anchor {
        case .fajrStart:
            return fajrStartPresetMinutes.map { minutes in
                DefaultWakeRule(
                    purpose: .fajr,
                    anchor: .fajrStart,
                    direction: minutes == 0 ? .at : .after,
                    offsetMinutes: minutes
                )
            }
        case .fajrEnd:
            return fajrEndPresetMinutes.map {
                DefaultWakeRule(purpose: .fajr, anchor: .fajrEnd, direction: .before, offsetMinutes: $0)
            }
        }
    }

    private var suhoorPresetRules: [DefaultWakeRule] {
        suhoorPresetMinutes.map {
            DefaultWakeRule(purpose: .suhoor, anchor: .fajrStart, direction: .before, offsetMinutes: $0)
        }
    }

    private var fajrCustomRange: ClosedRange<Int> {
        guard let shortestFajrWindowMinutes else {
            return draftFajrRule.anchor == .fajrEnd ? 10...180 : 0...180
        }
        switch draftFajrRule.anchor {
        case .fajrStart:
            return 0...max(0, shortestFajrWindowMinutes - DefaultWakeRuleValidator.minimumFajrEndSafetyBufferMinutes)
        case .fajrEnd:
            return DefaultWakeRuleValidator.minimumFajrEndSafetyBufferMinutes...max(
                DefaultWakeRuleValidator.minimumFajrEndSafetyBufferMinutes,
                shortestFajrWindowMinutes
            )
        }
    }

    private var fajrCustomMinutesBinding: Binding<Int> {
        Binding(get: {
            draftFajrRule.offsetMinutes
        }, set: { newValue in
            switch draftFajrRule.anchor {
            case .fajrStart:
                draftFajrRule = DefaultWakeRule(
                    purpose: .fajr,
                    anchor: .fajrStart,
                    direction: newValue == 0 ? .at : .after,
                    offsetMinutes: newValue
                )
            case .fajrEnd:
                draftFajrRule = DefaultWakeRule(
                    purpose: .fajr,
                    anchor: .fajrEnd,
                    direction: .before,
                    offsetMinutes: newValue
                )
            }
            scheduleDraftCommit()
        })
    }

    private var suhoorCustomMinutesBinding: Binding<Int> {
        Binding(get: {
            draftSuhoorRule.offsetMinutes
        }, set: { newValue in
            draftSuhoorRule = DefaultWakeRule(
                purpose: .suhoor,
                anchor: .fajrStart,
                direction: .before,
                offsetMinutes: newValue
            )
            scheduleDraftCommit()
        })
    }

    private var fajrCustomDetail: String {
        switch draftFajrRule.anchor {
        case .fajrStart:
            if draftFajrRule.offsetMinutes == 0 {
                return "At Fajr begins"
            }
            return "\(draftFajrRule.offsetMinutes) minutes after Fajr begins"
        case .fajrEnd:
            return "\(draftFajrRule.offsetMinutes) minutes before Fajr ends"
        }
    }

    private var fajrCustomAccessibilityLabel: String {
        switch draftFajrRule.anchor {
        case .fajrStart:
            return "Custom Fajr wake time after Fajr begins"
        case .fajrEnd:
            return "Custom Fajr wake time before Fajr ends"
        }
    }

    private var unavailableOptionsExplanation: String {
        let base = "The Fajr window changes throughout the year. Subh only shows default Fajr wake times that fit safely for your location."
        guard let shortestFajrWindowMinutes, let longestFajrWindowMinutes else {
            return "\(base) Subh keeps a 10-minute safety buffer before Fajr ends."
        }
        return "\(base) For your location, the Fajr window ranges from \(durationText(shortestFajrWindowMinutes)) to \(durationText(longestFajrWindowMinutes)) over the next year. Subh keeps a 10-minute safety buffer before Fajr ends."
    }

    private func defaultWakeRuleButton(rule: DefaultWakeRule, selected: Bool) -> some View {
        let validation = DefaultWakeRuleValidator.validate(
            rule: rule,
            shortestFajrWindowMinutes: rule.purpose == .fajr ? shortestFajrWindowMinutes : nil
        )
        return Button {
            guard validation.isValid else { return }
            switch rule.purpose {
            case .fajr:
                draftFajrRule = rule
            case .suhoor:
                draftSuhoorRule = rule
            }
            scheduleDraftCommit()
        } label: {
            SettingsRow {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? .primary : .secondary)
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        Text(rule.optionText)
                            .font(AppTypography.rowTitle)
                            .foregroundStyle(validation.isValid ? .primary : .secondary)
                        if !validation.isValid {
                            Text("Not available for your current Fajr times.")
                                .font(AppTypography.rowBody)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!validation.isValid)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rule.optionText)
        .accessibilityValue(validation.isValid ? (selected ? "Selected" : "Available") : "Not available for your current Fajr times")
    }

    private func loadDraftFromStore() {
        draftFajrRule = alarmConfigStore.defaults.defaultFajrWakeRule
        draftSuhoorRule = alarmConfigStore.defaults.defaultSuhoorWakeRule
    }

    private func refreshFajrWindowSummary() {
        let validation = scheduleManager.defaultWakeValidation(for: draftFajrRule)
        shortestFajrWindowMinutes = validation?.shortestFajrWindowMinutes
        longestFajrWindowMinutes = validation?.longestFajrWindowMinutes
    }

    private func scheduleDraftCommit() {
        saveMessage = nil
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
        hasPendingCommit = false
        guard draftFajrRule != alarmConfigStore.defaults.defaultFajrWakeRule
            || draftSuhoorRule != alarmConfigStore.defaults.defaultSuhoorWakeRule else {
            return
        }
        let fajrValidation = DefaultWakeRuleValidator.validate(
            rule: draftFajrRule,
            shortestFajrWindowMinutes: shortestFajrWindowMinutes
        )
        let suhoorValidation = DefaultWakeRuleValidator.validate(rule: draftSuhoorRule, shortestFajrWindowMinutes: nil)
        guard fajrValidation.isValid, suhoorValidation.isValid else {
            saveMessage = fajrValidation.message ?? suhoorValidation.message ?? "Choose a safe wake time."
            return
        }
        Task { @MainActor in
            let saved = await scheduleManager.updateDefaultWakeTimes(
                fajrRule: draftFajrRule,
                suhoorRule: draftSuhoorRule
            )
            if !saved {
                saveMessage = "Choose a wake time that fits safely for your current location."
            }
            refreshFajrWindowSummary()
        }
    }

    private func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return "\(remainder)m"
        }
        if remainder == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainder)m"
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
                title: "Wake Attempts",
                supportingText: "Wake attempts control whether Subh rings once or keeps trying every 5 minutes until you confirm you are awake."
            ) {
                SettingsRow {
                    SettingsSummaryRow(
                        title: "Wake Attempts",
                        subtitle: normalizedDraftSettings.wakeAttemptMode.settingsSubtitle,
                        systemImage: normalizedDraftSettings.wakeAttemptMode == .repeatUntilAwake
                            ? "alarm.waves.left.and.right"
                            : "alarm"
                    )
                }
                AppGroupDivider()
                SettingsRow {
                    Picker("Wake Attempts", selection: wakeAttemptModeBinding) {
                        ForEach(WakeAttemptMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }
                AppGroupDivider()
                SettingsRow {
                    Text(normalizedDraftSettings.wakeAttemptMode.detailText)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
                title: "Safety Before Fajr Ends",
                supportingText: "Keeps wake attempts from landing too close to the end of Fajr."
            ) {
                SettingsRow {
                    Stepper(value: reserveBinding, in: 1...60, step: 1) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Safety time")
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

    private var wakeAttemptModeBinding: Binding<WakeAttemptMode> {
        Binding(get: {
            draftSettings.wakeAttemptMode
        }, set: { newValue in
            draftSettings.wakeAttemptMode = newValue
            draftSettings.snoozeEnabled = newValue == .repeatUntilAwake
            draftSettings.snoozeMinutes = 5
            scheduleDraftCommit()
        })
    }

    private var normalizedDraftSettings: AppSettings {
        var settings = draftSettings
        settings.reserveBeforeEndMinutes = max(1, settings.reserveBeforeEndMinutes)
        settings.snoozeEnabled = settings.wakeAttemptMode == .repeatUntilAwake
        settings.snoozeMinutes = 5
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
