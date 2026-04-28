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
    @State private var weeklyFajrcastFocusedDateKey: String?

    var body: some View {
        let weeklyFajrcast = weeklyFajrcastSnapshot

        NavigationStack {
            ZStack {
                AppPageBackground()
                    .ignoresSafeArea()

                AppHomeContrastOverlay()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                        TomorrowMorningHero(
                            entry: snapshot.tomorrow,
                            permissionSummary: snapshot.permissionState.summaryText
                        ) {
                            if let entry = snapshot.tomorrow {
                                destination = .day(entry.schedule)
                            }
                        }

                        WeeklyFajrcastCard(
                            snapshot: weeklyFajrcast,
                            onSelectDateKey: selectWeeklyFajrcastDate,
                            onEndSelection: resetWeeklyFajrcastFocus,
                            onMoveSelection: moveWeeklyFajrcastSelection
                        ) {
                            destination = .fajrcast(selectedDateKey: weeklyFajrcast.selectedDay.dateKey)
                        }

                        MorningcastCard(entries: snapshot.morningcast) { entry in
                            destination = .day(entry.schedule)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingM)
                    .padding(.top, DesignTokens.spacingXL + DesignTokens.spacingL)
                    .padding(.bottom, 104)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HomeSettingsFloatingControl {
                    presentSettings()
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
            .appSettingsPresentedChrome()
        }
        .onReceive(appNavigator.$latestRequest.compactMap { $0 }) { request in
            handle(request.intent)
        }
    }

    private var snapshot: MorningHomeSnapshot {
        scheduleManager.currentMorningHomeSnapshot
    }

    private var weeklyFajrcastSnapshot: FajrWindowCompactSnapshot {
        guard let weeklyFajrcastFocusedDateKey else {
            return snapshot.weeklyFajrcast
        }

        return scheduleManager.fajrWindowCompactSnapshot(
            anchorDateKey: snapshot.weeklyFajrcast.anchorDateKey,
            focusedDateKey: weeklyFajrcastFocusedDateKey
        )
    }

    private func selectWeeklyFajrcastDate(_ dateKey: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            weeklyFajrcastFocusedDateKey = dateKey
        }
    }

    private func resetWeeklyFajrcastFocus() {
        guard weeklyFajrcastFocusedDateKey != nil else { return }

        withAnimation(.easeInOut(duration: 0.22)) {
            weeklyFajrcastFocusedDateKey = nil
        }
    }

    private func moveWeeklyFajrcastSelection(by offset: Int) {
        let compactSnapshot = weeklyFajrcastSnapshot
        guard
            let selectedDateKey = compactSnapshot.selectedDateKey,
            let selectedIndex = compactSnapshot.points.firstIndex(where: { $0.dateKey == selectedDateKey })
        else {
            return
        }

        let nextIndex = min(max(selectedIndex + offset, 0), compactSnapshot.points.count - 1)
        guard nextIndex != selectedIndex else { return }

        selectWeeklyFajrcastDate(compactSnapshot.points[nextIndex].dateKey)
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

private struct TomorrowMorningHero: View {
    let entry: WakeRowEntry?
    let permissionSummary: String
    let onOpen: () -> Void

    var body: some View {
        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: permissionSummary
        )

        Button(action: onOpen) {
            VStack(alignment: .center, spacing: DesignTokens.textSpacingRegular) {
                VStack(spacing: DesignTokens.textSpacingMicro) {
                    Text(display.title)
                        .font(.title3.weight(.regular))
                        .foregroundStyle(WakeGlassTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    if let dateLine = display.dateLine {
                        Text(dateLine)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .lineLimit(1)
                    }
                }

                if let entry {
                    SubhHomeTimeLockup(date: entry.schedule.wakeDate, isDisabled: !entry.isEnabled)

                    VStack(spacing: DesignTokens.textSpacingTight) {
                        Text(display.statusText)
                            .font(.title3.weight(.regular))
                            .foregroundStyle(WakeGlassTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(display.detailText)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    if !display.chipTitles.isEmpty {
                        FlowLayout(spacing: DesignTokens.spacingS) {
                            ForEach(display.chipTitles, id: \.self) { title in
                                WakeContextChip(title: title, isDisabled: false, compact: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, DesignTokens.textSpacingTight)
                    }
                } else {
                    VStack(spacing: DesignTokens.textSpacingCompact) {
                        Text(display.statusText)
                            .font(.title3.weight(.regular))
                            .foregroundStyle(WakeGlassTheme.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        Text(display.detailText)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, DesignTokens.spacingS)
                }
            }
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.top, DesignTokens.spacingXL)
            .padding(.bottom, DesignTokens.spacingXL)
            .frame(maxWidth: .infinity, minHeight: 268, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.accessibilityLabel)
        .accessibilityHint(entry == nil ? "" : "Double-tap for details.")
    }
}

private struct HomeSettingsFloatingControl: View {
    let onOpenSettings: () -> Void

    var body: some View {
        HStack {
            Spacer()

            HomeFloatingIconButton(
                systemName: "gearshape",
                accessibilityLabel: "Settings",
                action: onOpenSettings
            )
        }
        .padding(.horizontal, DesignTokens.spacingL)
        .padding(.top, DesignTokens.spacingS)
        .padding(.bottom, DesignTokens.spacingS)
    }
}

private struct HomeFloatingIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppTypography.toolbarIcon.weight(.medium))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(.thinMaterial)
                        .overlay {
                            Circle().fill(Color.white.opacity(0.20))
                        }
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.36), lineWidth: 1)
                        }
                }
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct MorningcastCard: View {
    let entries: [WakeRowEntry]
    let onSelect: (WakeRowEntry) -> Void

    var body: some View {
        AppGlassSurface(
            variant: .grouped,
            contentPadding: 0
        ) {
            VStack(spacing: 0) {
                AppSectionHeader(
                    MorningHomeSnapshot.forecastTitle,
                    subtitle: MorningHomeSnapshot.forecastSubtitle
                )
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingM)
                .padding(.bottom, DesignTokens.spacingS)

                AppGroupDivider(inset: DesignTokens.spacingL)

                if entries.isEmpty {
                    Text("Upcoming mornings will appear once Subh has resolved schedule data.")
                        .font(AppTypography.rowBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignTokens.spacingL)
                        .padding(.vertical, DesignTokens.spacingM)
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        MorningcastCompactRow(entry: entry) {
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

private struct MorningcastCompactRow: View {
    let entry: WakeRowEntry
    let onSelect: () -> Void

    var body: some View {
        let display = MorningHomePresentation.morningcastRowDisplay(for: entry)

        Button(action: onSelect) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(display.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(display.isInactive ? WakeGlassTheme.primaryText.opacity(0.62) : WakeGlassTheme.primaryText.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle = display.subtitle {
                        Text(subtitle)
                            .font(AppTypography.rowBody)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: DesignTokens.spacingS)

                if let trailingTime = display.trailingTime {
                    MorningcastTimeLockup(date: trailingTime, isDisabled: display.isInactive)
                        .fixedSize(horizontal: true, vertical: false)
                } else if let trailingStatusText = display.trailingStatusText {
                    Text(trailingStatusText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.accessibilityLabel)
        }
        .buttonStyle(.plain)
        .padding(.vertical, DesignTokens.space8)
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

private struct MorningcastTimeLockup: View {
    let date: Date
    let isDisabled: Bool

    @ScaledMetric(relativeTo: .title3) private var pointSize: CGFloat = 30

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize, weight: .regular))
                .foregroundStyle(isDisabled ? WakeGlassTheme.secondaryText : WakeGlassTheme.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize * 0.42, weight: .regular))
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
