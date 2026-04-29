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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let entry: WakeRowEntry?
    let permissionSummary: String
    let onOpen: () -> Void

    var body: some View {
        let display = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: permissionSummary
        )
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)

        Button(action: onOpen) {
            VStack(alignment: .center, spacing: 0) {
                Text(display.title)
                    .font(.system(size: metrics.relativeLabelSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let dateLine = display.dateLine {
                    Text(dateLine)
                        .font(.system(size: metrics.dateLineSize, weight: .regular))
                        .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, metrics.relativeToDateGap)
                }

                primaryWakeRow(display: display, metrics: metrics)
                    .padding(.top, metrics.dateToPrimaryGap)

                Text(display.detailText)
                    .font(.system(size: metrics.relationSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, metrics.primaryToRelationGap)

                Text(display.fajrWindowLine)
                    .font(.system(size: metrics.fajrWindowSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.88))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, metrics.relationToWindowGap)
            }
            .frame(maxWidth: metrics.maxContentWidth)
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.top, metrics.verticalBreathing)
            .padding(.bottom, metrics.verticalBreathing + metrics.bottomGapBeforeNextCard - DesignTokens.spacingL)
            .frame(maxWidth: .infinity, minHeight: metrics.minHeroRegionHeight, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.accessibilityLabel)
        .accessibilityHint(entry == nil ? "" : "Double-tap for details.")
    }

    @ViewBuilder
    private func primaryWakeRow(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics
    ) -> some View {
        if let primaryTime = display.primaryTime {
            HStack(alignment: .firstTextBaseline, spacing: metrics.primaryRowSpacing) {
                if let iconName = display.wakeIconName {
                    Image(systemName: iconName)
                        .font(.system(size: metrics.iconSize, weight: .regular))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
                        .baselineOffset(metrics.iconBaselineOffset)
                }

                SubhHomeHeroTimeLockup(date: primaryTime, pointSize: metrics.wakeTimeSize)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .lineLimit(1)
            .minimumScaleFactor(0.84)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: metrics.primaryRowSpacing) {
                if let iconName = display.wakeIconName {
                    Image(systemName: iconName)
                        .font(.system(size: metrics.iconSize, weight: .regular))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.86))
                        .baselineOffset(metrics.iconBaselineOffset)
                }

                Text(display.primaryText)
                    .font(.system(size: metrics.wakeStateSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct MorningHeroMetrics {
    let scale: CGFloat
    let minHeroRegionHeight: CGFloat
    let minTextStackHeight: CGFloat
    let bottomGapBeforeNextCard: CGFloat

    init(dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall:
            scale = 0.88
            minHeroRegionHeight = 236
            minTextStackHeight = 150
            bottomGapBeforeNextCard = 28
        case .small:
            scale = 0.94
            minHeroRegionHeight = 242
            minTextStackHeight = 158
            bottomGapBeforeNextCard = 30
        case .medium:
            scale = 0.98
            minHeroRegionHeight = 248
            minTextStackHeight = 164
            bottomGapBeforeNextCard = 32
        case .large:
            scale = 1.00
            minHeroRegionHeight = 256
            minTextStackHeight = 172
            bottomGapBeforeNextCard = 36
        case .xLarge:
            scale = 1.08
            minHeroRegionHeight = 276
            minTextStackHeight = 190
            bottomGapBeforeNextCard = 38
        case .xxLarge:
            scale = 1.17
            minHeroRegionHeight = 304
            minTextStackHeight = 214
            bottomGapBeforeNextCard = 42
        case .xxxLarge:
            scale = 1.28
            minHeroRegionHeight = 334
            minTextStackHeight = 242
            bottomGapBeforeNextCard = 46
        case .accessibility1:
            scale = 1.38
            minHeroRegionHeight = 366
            minTextStackHeight = 266
            bottomGapBeforeNextCard = 50
        case .accessibility2:
            scale = 1.50
            minHeroRegionHeight = 404
            minTextStackHeight = 300
            bottomGapBeforeNextCard = 54
        case .accessibility3:
            scale = 1.64
            minHeroRegionHeight = 452
            minTextStackHeight = 344
            bottomGapBeforeNextCard = 58
        case .accessibility4:
            scale = 1.80
            minHeroRegionHeight = 510
            minTextStackHeight = 398
            bottomGapBeforeNextCard = 62
        case .accessibility5:
            scale = 1.96
            minHeroRegionHeight = 574
            minTextStackHeight = 460
            bottomGapBeforeNextCard = 66
        @unknown default:
            scale = 1.28
            minHeroRegionHeight = 334
            minTextStackHeight = 242
            bottomGapBeforeNextCard = 46
        }
    }

    var relativeLabelSize: CGFloat { 28 * scale }
    var dateLineSize: CGFloat { 17 * scale }
    var iconSize: CGFloat { 22 * scale }
    var wakeTimeSize: CGFloat { 68 * scale }
    var wakeStateSize: CGFloat { 44 * scale }
    var relationSize: CGFloat { 20 * scale }
    var fajrWindowSize: CGFloat { 15 * scale }
    var relativeToDateGap: CGFloat { max(4, 4 * scale) }
    var dateToPrimaryGap: CGFloat { 22 * min(scale, 1.2) }
    var primaryToRelationGap: CGFloat { 8 * min(scale, 1.2) }
    var relationToWindowGap: CGFloat { 12 * min(scale, 1.2) }
    var primaryRowSpacing: CGFloat { max(7, 8 * scale) }
    var iconBaselineOffset: CGFloat { 4 * scale }
    var verticalBreathing: CGFloat { max(18, (minHeroRegionHeight - minTextStackHeight) / 2) }
    var maxContentWidth: CGFloat { 390 }
}

private struct SubhHomeHeroTimeLockup: View {
    let date: Date
    let pointSize: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize, weight: .light))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize * 0.41, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.78))
                .monospacedDigit()
                .baselineOffset(3 * min(pointSize / 68, 1.4))
        }
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
