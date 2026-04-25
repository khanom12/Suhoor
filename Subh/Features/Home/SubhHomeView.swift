import Combine
import SwiftUI

private enum SubhHomeDestination: Identifiable, Hashable {
    case day(DaySchedule)
    case fajrcast(selectedDateKey: String?)

    var id: String {
        switch self {
        case .day(let schedule):
            return "day-\(schedule.id)"
        case .fajrcast(let selectedDateKey):
            return "fajrcast-\(selectedDateKey ?? "default")"
        }
    }

    static func == (lhs: SubhHomeDestination, rhs: SubhHomeDestination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private enum SettingsRoute: Hashable {
    case hijriCorrections
    case alarmBehavior
}

struct SubhHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var appNavigator: AppNavigator

    @State private var destination: SubhHomeDestination?
    @State private var settingsPath = NavigationPath()
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppPageBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                        TomorrowMorningCard(
                            entry: snapshot.tomorrow,
                            permissionSummary: snapshot.permissionState.summaryText,
                            contextFlags: snapshot.contextFlags
                        ) {
                            if let entry = snapshot.tomorrow {
                                destination = .day(entry.schedule)
                            }
                        }

                        WeeklyFajrcastCard(snapshot: snapshot.weeklyFajrcast) {
                            destination = .fajrcast(selectedDateKey: snapshot.weeklyFajrcast.selectedDay.dateKey)
                        }

                        MorningcastCard(entries: snapshot.morningcast) { entry in
                            destination = .day(entry.schedule)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingM)
                    .padding(.top, DesignTokens.spacingS)
                    .padding(.bottom, DesignTokens.spacingXL)
                }
                .appScrollableChrome()
            }
            .navigationTitle("Subh")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(item: $destination) { destination in
                switch destination {
                case .day(let schedule):
                    AlarmDayDetailView(schedule: schedule)
                case .fajrcast(let selectedDateKey):
                    FajrWindowDetailView(
                        initialPeriod: .sevenDays,
                        initialSelectedDateKey: selectedDateKey
                    )
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack(path: $settingsPath) {
                SettingsRootView()
                    .navigationDestination(for: SettingsRoute.self) { destination in
                        switch destination {
                        case .hijriCorrections:
                            HijriCalendarSettingsView()
                        case .alarmBehavior:
                            AlarmBehaviorSettingsView()
                        }
                    }
            }
            .appPresentedChrome()
        }
        .onReceive(appNavigator.$latestRequest.compactMap { $0 }) { request in
            handle(request.intent)
        }
    }

    private var snapshot: MorningHomeSnapshot {
        scheduleManager.currentMorningHomeSnapshot
    }

    private func handle(_ intent: AppNavigationIntent) {
        switch intent {
        case .openSettings:
            presentSettings()
        case .openHijriCorrections:
            presentSettings(route: .hijriCorrections)
        case .openAlarmBehavior:
            presentSettings(route: .alarmBehavior)
        case .switchToWake:
            if let entry = snapshot.tomorrow {
                destination = .day(entry.schedule)
            }
        }
    }

    private func presentSettings(route: SettingsRoute? = nil) {
        settingsPath.removeLast(settingsPath.count)
        if let route {
            settingsPath.append(route)
        }
        isShowingSettings = true
    }
}

private struct TomorrowMorningCard: View {
    let entry: WakeRowEntry?
    let permissionSummary: String
    let contextFlags: [MorningHomeContextFlag]
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            AppGlassSurface(
                variant: .hero,
                prominence: .high,
                contentPadding: 18
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    HStack(alignment: .top, spacing: DesignTokens.spacingS) {
                        Text("TOMORROW MORNING")
                            .appTextRole(.eyebrow)
                            .foregroundStyle(WakeGlassTheme.tertiaryText)

                        Spacer(minLength: DesignTokens.spacingS)

                        if let dateText {
                            Text(dateText)
                                .font(AppTypography.badge)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    if let entry {
                        SubhHomeTimeLockup(date: entry.schedule.wakeDate, isDisabled: !entry.isEnabled)

                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                            Text(heroTitle(for: entry))
                                .font(AppTypography.rowTitle)
                                .foregroundStyle(WakeGlassTheme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(heroDetail(for: entry))
                                .font(AppTypography.cardBody)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !contextFlags.isEmpty {
                            FlowLayout(spacing: DesignTokens.spacingS) {
                                ForEach(contextFlags) { flag in
                                    WakeContextChip(title: flag.title, isDisabled: false, compact: true)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                            Text("Morning not resolved yet")
                                .font(AppTypography.rowTitle)
                                .foregroundStyle(WakeGlassTheme.primaryText)

                            Text(unresolvedDetail)
                                .font(AppTypography.cardBody)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .disabled(entry == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(entry == nil ? "" : "Double-tap for details.")
    }

    private var dateText: String? {
        guard let entry else { return nil }
        return WakeRowPresentation.dateLabel(for: entry.schedule.date)
    }

    private var unresolvedDetail: String {
        if permissionSummary.isEmpty {
            return "Subh will show the next resolved Fajr morning after schedule data is available."
        }
        return permissionSummary
    }

    private var accessibilityLabel: String {
        guard let entry else {
            return "Tomorrow Morning. \(unresolvedDetail)"
        }
        return "Tomorrow Morning. Wake at \(TimeFormatters.timeFormatter.string(from: entry.schedule.wakeDate)). \(heroDetail(for: entry))"
    }

    private func heroTitle(for entry: WakeRowEntry) -> String {
        if !entry.isEnabled {
            return "No wake scheduled"
        }
        return WakePagePresentation.card(for: entry).title
    }

    private func heroDetail(for entry: WakeRowEntry) -> String {
        let anchor = entry.activeDay.decisionLog.resolvedAnchor
        var parts: [String] = []

        if anchor.type == .fajrEnd {
            parts.append("30 min before supported Fajr end")
        } else {
            parts.append(WakePagePresentation.card(for: entry).subtitle)
        }

        if anchor.providerNotes == "provider:solar_sunrise_proxy" {
            parts.append("sunrise-derived boundary")
        } else if anchor.providerNotes == "fallback:missing_fajr_end" {
            parts.append("using Fajr start fallback")
        }

        return parts.joined(separator: " • ")
    }
}

private struct MorningcastCard: View {
    let entries: [WakeRowEntry]
    let onSelect: (WakeRowEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            AppSectionHeader(
                "Morningcast",
                subtitle: entries.isEmpty ? nil : "Next \(entries.count) resolved mornings"
            )

            if entries.isEmpty {
                WakeGlassCard(padding: 14) {
                    Text("Upcoming mornings will appear once Subh has resolved schedule data.")
                        .font(AppTypography.rowBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                AppInsetGroup {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        WakeRowView(entry: entry) {
                            onSelect(entry)
                        }
                        .padding(.horizontal, DesignTokens.spacingM)

                        if index < entries.count - 1 {
                            AppGroupDivider(inset: DesignTokens.spacingM)
                        }
                    }
                }
            }
        }
    }
}

private struct SubhHomeTimeLockup: View {
    let date: Date
    let isDisabled: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var pointSize: CGFloat = 52

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize, weight: .light))
                .foregroundStyle(isDisabled ? WakeGlassTheme.secondaryText : WakeGlassTheme.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize * 0.46, weight: .regular))
                .foregroundStyle(isDisabled ? WakeGlassTheme.tertiaryText : WakeGlassTheme.secondaryText)
                .monospacedDigit()
                .baselineOffset(2)
        }
        .lineLimit(1)
        .accessibilityHidden(true)
    }

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
}
