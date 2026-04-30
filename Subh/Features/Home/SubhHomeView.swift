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
                            permissionSummary: snapshot.permissionState.summaryText,
                            locationDisplayText: scheduleManager.currentPrayerLocationDisplayText,
                            locationIconName: scheduleManager.currentPrayerLocationIconName,
                            currentDate: scheduleManager.currentDate,
                            onCommitWakeAdjustment: { date, wakeTime in
                                await scheduleManager.commitHeroWakeAdjustment(for: date, wakeTime: wakeTime)
                            },
                            onSelectWakeMode: { date, mode in
                                await scheduleManager.selectHeroWakeMode(for: date, mode: mode)
                            }
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

                        NextTenMorningsCard(entries: snapshot.morningcast) { entry in
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

private enum MorningHeroModeTransitionDirection: Equatable {
    case earlier
    case later
    case toQuiet
    case fromQuiet
    case crossfade

    init(from: QuickWakeMode?, to: QuickWakeMode) {
        switch (from, to) {
        case (.some(.fajr), .fast):
            self = .earlier
        case (.some(.fast), .fajr):
            self = .later
        case (_, .quiet):
            self = .toQuiet
        case (.some(.quiet), .fast), (.some(.quiet), .fajr):
            self = .fromQuiet
        default:
            self = .crossfade
        }
    }

}

private struct TomorrowMorningHero: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let entry: WakeRowEntry?
    let permissionSummary: String
    let locationDisplayText: String
    let locationIconName: String?
    let currentDate: Date
    let onCommitWakeAdjustment: (Date, Date) async -> Bool
    let onSelectWakeMode: (Date, QuickWakeMode) async -> Bool
    let onOpen: () -> Void

    @State private var tentativeWakeTime: Date?
    @State private var isCommittingWakeAdjustment = false
    @State private var isSelectingWakeMode = false
    @State private var lastResolvedQuickMode: QuickWakeMode?
    @State private var modeTransitionDirection: MorningHeroModeTransitionDirection = .crossfade
    @Namespace private var quickSelectorHighlight

    var body: some View {
        let baseDisplay = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: permissionSummary,
            locationDisplayText: locationDisplayText,
            locationIconName: locationIconName,
            currentDate: currentDate
        )
        let display = tentativeWakeTime.map {
            MorningHomePresentation.heroDisplay(adjusting: baseDisplay, tentativeWakeTime: $0)
        } ?? baseDisplay
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)
        let modeAnimation = heroModeAnimation
        let relationTransitionKey = [
            display.selectedQuickWakeMode?.rawValue ?? "none",
            display.fajrWindowVisualMode.rawValue,
            display.relationTone.rawValue
        ].joined(separator: "-")

        VStack(alignment: .center, spacing: 0) {
            locationLine(display: display, metrics: metrics)

            Text(display.title)
                .font(.system(size: metrics.relativeLabelSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, metrics.dateToRelativeGap)
                .accessibilityIdentifier(MorningHeroUIIdentifier.relativeDay)

            primaryWakeRow(
                display: display,
                metrics: metrics,
                rollsActiveWakeTime: tentativeWakeTime == nil
            )
                .padding(.top, metrics.relativeToPrimaryGap)

            if display.fajrWindowVisualMode.rendersRange {
                FajrWindowRangeVisual(
                    display: display,
                    metrics: metrics,
                    reduceMotion: reduceMotion
                )
                    .onWakeAdjustmentChanged { wakeTime in
                        tentativeWakeTime = wakeTime
                    }
                    .onWakeAdjustmentEnded { wakeTime in
                        commitWakeAdjustment(wakeTime)
                    }
                    .heroWakeAdjustmentAccessibility(display: display) { direction in
                        adjustWakeAccessibility(display: display, direction: direction)
                    }
                    .padding(.top, metrics.primaryToWindowGap)
            }

            Text(display.detailText)
                .font(.system(size: metrics.dateLineSize, weight: .regular))
                .foregroundStyle(relationForegroundStyle(for: display.relationTone))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: metrics.relationRowHeight)
                .padding(.top, display.fajrWindowVisualMode.rendersRange ? metrics.windowToRelationGap : metrics.primaryToRelationGap)
                .accessibilityIdentifier(MorningHeroUIIdentifier.relation)
                .id(relationTransitionKey)
                .transition(relationTransition)
                .animation(modeAnimation, value: relationTransitionKey)

            if !display.quickWakeModeOptions.isEmpty {
                MorningHeroQuickWakeModeSelector(
                    options: display.quickWakeModeOptions,
                    metrics: metrics,
                    highlightNamespace: quickSelectorHighlight,
                    reduceMotion: reduceMotion,
                    isDisabled: isSelectingWakeMode || isCommittingWakeAdjustment
                ) { mode in
                    selectWakeMode(mode)
                }
                .padding(.top, metrics.relationToSelectorGap)
            }
        }
        .frame(maxWidth: metrics.maxContentWidth)
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.top, metrics.verticalBreathing)
        .padding(.bottom, metrics.verticalBreathing + metrics.bottomGapBeforeNextCard - DesignTokens.spacingL)
        .frame(maxWidth: .infinity, minHeight: metrics.minHeroRegionHeight, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture {
            guard entry != nil, !isCommittingWakeAdjustment, !isSelectingWakeMode else { return }
            onOpen()
        }
        .onChange(of: entry?.id) { _, _ in
            tentativeWakeTime = nil
            isCommittingWakeAdjustment = false
            isSelectingWakeMode = false
        }
        .onChange(of: entry?.schedule.wakeDate) { _, _ in
            if !isCommittingWakeAdjustment {
                tentativeWakeTime = nil
            }
        }
        .onAppear {
            lastResolvedQuickMode = display.selectedQuickWakeMode
        }
        .onChange(of: display.selectedQuickWakeMode) { oldMode, newMode in
            guard let newMode, oldMode != newMode else { return }
            let fromMode = lastResolvedQuickMode ?? oldMode
            modeTransitionDirection = MorningHeroModeTransitionDirection(from: fromMode, to: newMode)
            lastResolvedQuickMode = newMode
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(entry == nil ? [] : .isButton)
        .accessibilityLabel(display.accessibilityLabel)
        .accessibilityHint(entry == nil ? "" : "Double-tap for details.")
    }

    private var heroModeAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.34)
    }

    private var relationTransition: AnyTransition {
        .opacity
    }

    private func relationForegroundStyle(for tone: MorningHeroRelationTone) -> Color {
        switch tone {
        case .normal:
            return WakeGlassTheme.secondaryText.opacity(0.92)
        case .urgentRed:
            return DawnColor.danger
        }
    }

    @ViewBuilder
    private func locationLine(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics
    ) -> some View {
        HStack(alignment: .center, spacing: max(5, 5 * metrics.scale)) {
            if let iconName = display.locationIconName {
                Image(systemName: iconName)
                    .font(.system(size: metrics.dateLineSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                    .accessibilityHidden(true)
            }

            Text(display.locationText)
                .font(.system(size: metrics.dateLineSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.locationText)
        .accessibilityIdentifier(MorningHeroUIIdentifier.location)
    }

    @ViewBuilder
    private func primaryWakeRow(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics,
        rollsActiveWakeTime: Bool
    ) -> some View {
        MorningHeroPrimaryWakeRow(
            display: display,
            metrics: metrics,
            rollsActiveWakeTime: rollsActiveWakeTime,
            transitionDirection: modeTransitionDirection,
            reduceMotion: reduceMotion
        )
    }

    private func commitWakeAdjustment(_ wakeTime: Date) {
        guard let date = entry?.schedule.date else { return }
        tentativeWakeTime = wakeTime
        isCommittingWakeAdjustment = true
        Task {
            _ = await onCommitWakeAdjustment(date, wakeTime)
            await MainActor.run {
                tentativeWakeTime = nil
                isCommittingWakeAdjustment = false
            }
        }
    }

    private func selectWakeMode(_ mode: QuickWakeMode) {
        guard let date = entry?.schedule.date else { return }
        withAnimation(heroModeAnimation) {
            isSelectingWakeMode = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await onSelectWakeMode(date, mode)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isSelectingWakeMode = false
                }
            }
        }
    }

    private func adjustWakeAccessibility(
        display: MorningHomeHeroDisplay,
        direction: AccessibilityAdjustmentDirection
    ) {
        guard
            display.wakeAdjustmentEnabled,
            let minTime = display.wakeAdjustmentMinTime,
            let maxTime = display.wakeAdjustmentMaxTime
        else {
            return
        }

        let current = tentativeWakeTime ?? display.primaryTime ?? minTime
        let step = max(1, display.wakeAdjustmentStepMinutes)
        let minuteDelta: Int
        switch direction {
        case .increment:
            minuteDelta = step
        case .decrement:
            minuteDelta = -step
        @unknown default:
            return
        }

        let adjusted = Calendar.current.date(byAdding: .minute, value: minuteDelta, to: current) ?? current
        let clamped = min(max(adjusted, minTime), maxTime)
        tentativeWakeTime = clamped
        commitWakeAdjustment(clamped)
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
            minHeroRegionHeight = 294
            minTextStackHeight = 194
            bottomGapBeforeNextCard = 28
        case .small:
            scale = 0.94
            minHeroRegionHeight = 302
            minTextStackHeight = 204
            bottomGapBeforeNextCard = 30
        case .medium:
            scale = 0.98
            minHeroRegionHeight = 310
            minTextStackHeight = 212
            bottomGapBeforeNextCard = 32
        case .large:
            scale = 1.00
            minHeroRegionHeight = 320
            minTextStackHeight = 222
            bottomGapBeforeNextCard = 36
        case .xLarge:
            scale = 1.08
            minHeroRegionHeight = 346
            minTextStackHeight = 250
            bottomGapBeforeNextCard = 38
        case .xxLarge:
            scale = 1.17
            minHeroRegionHeight = 382
            minTextStackHeight = 286
            bottomGapBeforeNextCard = 42
        case .xxxLarge:
            scale = 1.28
            minHeroRegionHeight = 426
            minTextStackHeight = 328
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
    var quietWakeStateSize: CGFloat { 52 * scale }
    var fajrWindowSize: CGFloat { 15 * scale }
    var primaryRowHeight: CGFloat { max(wakeTimeSize * 1.22, quietWakeStateSize * 1.36) }
    var relationRowHeight: CGFloat { max(22, dateLineSize * 1.35) }
    var dateToRelativeGap: CGFloat { max(4, 4 * scale) }
    var relativeToDateGap: CGFloat { dateToRelativeGap }
    var relativeToPrimaryGap: CGFloat { max(9, 11 * min(scale, 1.18)) }
    var primaryToRelationGap: CGFloat { 8 * min(scale, 1.2) }
    var primaryToWindowGap: CGFloat { 8 * min(scale, 1.2) }
    var windowToRelationGap: CGFloat { 12 * min(scale, 1.2) }
    var relationToSelectorGap: CGFloat { max(12, 14 * min(scale, 1.2)) }
    var primaryRowSpacing: CGFloat { max(7, 8 * scale) }
    var iconVerticalOffset: CGFloat { -1 * scale }
    var verticalBreathing: CGFloat { max(18, (minHeroRegionHeight - minTextStackHeight) / 2) }
    var maxContentWidth: CGFloat { 390 }
    var rangeTrackHeight: CGFloat { max(3, 4 * scale) }
    var rangeTrackWidth: CGFloat { min(176, max(124, 142 * scale)) }
    var rangeMarkerSize: CGFloat { max(16, 18 * scale) }
    var rangeRowHeight: CGFloat { max(44, rangeMarkerSize + 14 * scale) }
    var rangeEndpointSize: CGFloat { max(8, 9 * scale) }
    var rangeRowSpacing: CGFloat { max(9, 10 * scale) }
    var rangeFallbackSpacing: CGFloat { max(7, 8 * scale) }
    var quickSelectorLabelSize: CGFloat { 15 * scale }
    var quickSelectorHeight: CGFloat { max(44, 44 * min(scale, 1.28)) }
    var quickSelectorWidth: CGFloat { min(maxContentWidth, max(224, 238 * min(scale, 1.22))) }
    var quickSelectorPadding: CGFloat { max(4, 4 * scale) }
}

private struct MorningHeroPrimaryWakeRow: View {
    let display: MorningHomeHeroDisplay
    let metrics: MorningHeroMetrics
    let rollsActiveWakeTime: Bool
    let transitionDirection: MorningHeroModeTransitionDirection
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            if let primaryTime = display.primaryTime {
                activeWakeRow(primaryTime)
                    .transition(.opacity)
            } else {
                stateWakeRow
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: metrics.primaryRowHeight)
        .animation(primaryCrossfadeAnimation, value: display.primaryTime == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.primaryText)
        .accessibilityIdentifier(MorningHeroUIIdentifier.primaryWakeTime)
    }

    private func activeWakeRow(_ primaryTime: Date) -> some View {
        HStack(alignment: .center, spacing: metrics.primaryRowSpacing) {
            if let iconName = display.wakeIconName {
                Image(systemName: iconName)
                    .font(.system(size: metrics.iconSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
                    .offset(y: metrics.iconVerticalOffset)
            }

            RollingHeroTimeLockup(
                targetDate: primaryTime,
                pointSize: metrics.wakeTimeSize,
                shouldRoll: rollsActiveWakeTime && !reduceMotion,
                direction: transitionDirection
            )
        }
        .lineLimit(1)
        .minimumScaleFactor(0.84)
    }

    private var stateWakeRow: some View {
        HStack(alignment: .center, spacing: metrics.primaryRowSpacing) {
            if let iconName = display.wakeIconName {
                Image(systemName: iconName)
                    .font(.system(size: metrics.iconSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.88))
                    .offset(y: metrics.iconVerticalOffset)
            }

            Text(display.primaryText)
                .font(AppTypography.timeDisplayFont(
                    size: display.wakeState == .quietHours ? metrics.quietWakeStateSize : metrics.wakeStateSize,
                    weight: .regular
                ))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }

    private var primaryCrossfadeAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.22)
    }
}

private struct MorningHeroQuickWakeModeSelector: View {
    let options: [MorningHeroQuickWakeModeOption]
    let metrics: MorningHeroMetrics
    let highlightNamespace: Namespace.ID
    let reduceMotion: Bool
    let isDisabled: Bool
    let onSelect: (QuickWakeMode) -> Void

    var body: some View {
        let segmentWidth = (metrics.quickSelectorWidth - (metrics.quickSelectorPadding * 2))
            / CGFloat(max(options.count, 1))
        ZStack(alignment: .leading) {
            if let selectedIndex {
                selectedHighlight
                    .frame(
                        width: segmentWidth,
                        height: metrics.quickSelectorHeight - (metrics.quickSelectorPadding * 2)
                    )
                    .offset(x: CGFloat(selectedIndex) * segmentWidth)
                    .matchedGeometryEffect(id: "quickWakeModeSelection", in: highlightNamespace)
                    .animation(selectorAnimation, value: selectedIndex)
            }

            HStack(spacing: 0) {
                ForEach(options) { option in
                    MorningHeroQuickWakeModeSegment(
                        option: option,
                        metrics: metrics,
                        width: segmentWidth,
                        isDisabled: isDisabled,
                        onSelect: onSelect
                    )
                }
            }
        }
        .padding(metrics.quickSelectorPadding)
        .frame(width: metrics.quickSelectorWidth)
        .frame(minHeight: metrics.quickSelectorHeight)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.035))
                .background(.thinMaterial, in: Capsule())
                .overlay {
                    Capsule().fill(Color.white.opacity(0.018))
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: max(1, metrics.quickSelectorHeight * 0.34))
                        .blur(radius: 10)
                        .padding(.horizontal, 10)
                        .offset(y: -metrics.quickSelectorHeight * 0.22)
                }
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.11), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 3)
        }
        .opacity(isDisabled ? 0.72 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Wake mode")
        .accessibilityIdentifier(MorningHeroUIIdentifier.quickWakeModeSelector)
    }

    private var selectedIndex: Int? {
        options.firstIndex(where: \.isSelected)
    }

    private var selectorAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.22, dampingFraction: 0.92, blendDuration: 0.02)
    }

    private var selectedHighlight: some View {
        Capsule()
            .fill(Color.white.opacity(0.11))
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule().fill(Color.white.opacity(0.035))
            }
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 1)
    }
}

private struct MorningHeroQuickWakeModeSegment: View {
    let option: MorningHeroQuickWakeModeOption
    let metrics: MorningHeroMetrics
    let width: CGFloat
    let isDisabled: Bool
    let onSelect: (QuickWakeMode) -> Void

    private var textOpacity: Double {
        option.isSelected ? 0.98 : 0.76
    }

    private var fontWeight: Font.Weight {
        option.isSelected ? .semibold : .regular
    }

    var body: some View {
        Button {
            guard !option.isSelected, !isDisabled else { return }
            onSelect(option.mode)
        } label: {
            Text(option.title)
                .font(.system(size: metrics.quickSelectorLabelSize, weight: fontWeight))
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(textOpacity))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(width: width)
                .frame(minHeight: metrics.quickSelectorHeight - (metrics.quickSelectorPadding * 2))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityHint(option.accessibilityHint)
        .accessibilityAddTraits(option.isSelected ? .isSelected : [])
        .accessibilityIdentifier(MorningHeroUIIdentifier.quickWakeModeSegment(option.mode))
    }
}

private struct RollingHeroTimeLockup: View {
    let targetDate: Date
    let pointSize: CGFloat
    let shouldRoll: Bool
    let direction: MorningHeroModeTransitionDirection

    @State private var visibleDate: Date?
    @State private var rollTask: Task<Void, Never>?

    var body: some View {
        SubhHomeHeroTimeLockup(date: visibleDate ?? targetDate, pointSize: pointSize)
            .onAppear {
                visibleDate = targetDate
            }
            .onChange(of: targetDate) { oldDate, newDate in
                updateVisibleDate(from: visibleDate ?? oldDate, to: newDate)
            }
            .onDisappear {
                rollTask?.cancel()
            }
    }

    private func updateVisibleDate(from oldDate: Date, to newDate: Date) {
        rollTask?.cancel()

        guard shouldRoll else {
            withAnimation(.easeOut(duration: 0.16)) {
                visibleDate = newDate
            }
            return
        }

        let totalMinutes = Int(round(newDate.timeIntervalSince(oldDate) / 60))
        guard totalMinutes != 0, direction == .earlier || direction == .later else {
            visibleDate = newDate
            return
        }

        let stepCount = min(24, max(8, abs(totalMinutes) / 4))
        let duration: TimeInterval = 0.32
        let sleepNanoseconds = UInt64((duration / Double(stepCount)) * 1_000_000_000)

        rollTask = Task {
            for step in 1...stepCount {
                if Task.isCancelled { return }

                let fraction = Double(step) / Double(stepCount)
                let minuteOffset = Int((Double(totalMinutes) * fraction).rounded())
                let intermediateDate = Calendar.current.date(
                    byAdding: .minute,
                    value: minuteOffset,
                    to: oldDate
                ) ?? newDate

                await MainActor.run {
                    visibleDate = intermediateDate
                }

                try? await Task.sleep(nanoseconds: sleepNanoseconds)
            }

            await MainActor.run {
                visibleDate = newDate
            }
        }
    }
}

private struct SubhHomeHeroTimeLockup: View {
    let date: Date
    let pointSize: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize, weight: .light))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: pointSize * 0.41, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.78))
                .monospacedDigit()
                .offset(y: pointSize * 0.015)
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

private struct FajrWindowRangeVisual: View {
    let display: MorningHomeHeroDisplay
    let metrics: MorningHeroMetrics
    let reduceMotion: Bool
    var adjustmentChanged: (Date) -> Void = { _ in }
    var adjustmentEnded: (Date) -> Void = { _ in }

    func onWakeAdjustmentChanged(_ action: @escaping (Date) -> Void) -> Self {
        var copy = self
        copy.adjustmentChanged = action
        return copy
    }

    func onWakeAdjustmentEnded(_ action: @escaping (Date) -> Void) -> Self {
        var copy = self
        copy.adjustmentEnded = action
        return copy
    }

    var body: some View {
        if display.fajrWindowVisualMode.rendersRange,
           let begin = display.fajrBeginDisplayText,
           let end = display.fajrEndDisplayText {
            ViewThatFits(in: .horizontal) {
                horizontalRange(begin: begin, end: end)
                stackedRange(begin: begin, end: end)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: metrics.rangeRowHeight)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MorningHeroUIIdentifier.fajrWindow)
            .accessibilityLabel(accessibilityLabel)
        } else {
            Text(display.fajrWindowLine)
                .font(.system(size: metrics.fajrWindowSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.88))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func horizontalRange(begin: String, end: String) -> some View {
        HStack(alignment: .center, spacing: metrics.rangeRowSpacing) {
            rangeTime(begin, identifier: MorningHeroUIIdentifier.fajrWindowBeginTime)

            FajrWindowRangeTrack(
                ratio: display.wakeWindowPositionRatio,
                indicatorState: display.wakeWindowIndicatorState,
                indicatorIconName: display.wakeWindowIndicatorIconName,
                leftBoundaryMarkerStyle: display.leftBoundaryMarkerStyle,
                rightBoundaryMarkerStyle: display.rightBoundaryMarkerStyle,
                visualMode: display.fajrWindowVisualMode,
                minTime: display.wakeAdjustmentMinTime,
                maxTime: display.wakeAdjustmentMaxTime,
                stepMinutes: display.wakeAdjustmentStepMinutes,
                metrics: metrics,
                reduceMotion: reduceMotion
            ) { wakeTime in
                adjustmentChanged(wakeTime)
            } onAdjustmentEnded: { wakeTime in
                adjustmentEnded(wakeTime)
            }
            .frame(width: metrics.rangeTrackWidth, height: max(metrics.rangeMarkerSize, 18 * metrics.scale))

            rangeTime(end, identifier: MorningHeroUIIdentifier.fajrWindowEndTime)
        }
    }

    private func stackedRange(begin: String, end: String) -> some View {
        VStack(alignment: .center, spacing: metrics.rangeFallbackSpacing) {
            HStack {
                rangeTime(begin, identifier: MorningHeroUIIdentifier.fajrWindowBeginTime)
                Spacer(minLength: metrics.rangeRowSpacing)
                rangeTime(end, identifier: MorningHeroUIIdentifier.fajrWindowEndTime)
            }
            .frame(width: metrics.rangeTrackWidth + 44)

            FajrWindowRangeTrack(
                ratio: display.wakeWindowPositionRatio,
                indicatorState: display.wakeWindowIndicatorState,
                indicatorIconName: display.wakeWindowIndicatorIconName,
                leftBoundaryMarkerStyle: display.leftBoundaryMarkerStyle,
                rightBoundaryMarkerStyle: display.rightBoundaryMarkerStyle,
                visualMode: display.fajrWindowVisualMode,
                minTime: display.wakeAdjustmentMinTime,
                maxTime: display.wakeAdjustmentMaxTime,
                stepMinutes: display.wakeAdjustmentStepMinutes,
                metrics: metrics,
                reduceMotion: reduceMotion
            ) { wakeTime in
                adjustmentChanged(wakeTime)
            } onAdjustmentEnded: { wakeTime in
                adjustmentEnded(wakeTime)
            }
            .frame(width: metrics.rangeTrackWidth + 28, height: max(metrics.rangeMarkerSize, 18 * metrics.scale))
        }
    }

    private var accessibilityLabel: String {
        [
            display.fajrWindowAccessibilityText,
            display.wakeAdjustmentEnabled ? display.wakeAdjustmentAccessibilityValue : nil
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
    }

    private func rangeTime(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.system(size: metrics.fajrWindowSize, weight: .regular))
            .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.90))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: true, vertical: false)
            .id(text)
            .transition(.opacity)
            .animation(rangeTextAnimation, value: text)
            .accessibilityIdentifier(identifier)
    }

    private var rangeTextAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.18)
    }
}

private struct FajrWindowRangeTrack: View {
    let ratio: Double?
    let indicatorState: MorningHeroWakeWindowIndicatorState
    let indicatorIconName: String?
    let leftBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
    let rightBoundaryMarkerStyle: MorningHeroBoundaryMarkerStyle
    let visualMode: MorningHeroFajrWindowVisualMode
    let minTime: Date?
    let maxTime: Date?
    let stepMinutes: Int
    let metrics: MorningHeroMetrics
    let reduceMotion: Bool
    let onAdjustmentChanged: (Date) -> Void
    let onAdjustmentEnded: (Date) -> Void

    @State private var animatedMarkerRatio: Double?
    @State private var markerOpacity: Double = 1
    @State private var renderedIndicatorState: MorningHeroWakeWindowIndicatorState = .none
    @State private var renderedIndicatorIconName: String?
    @State private var markerRemovalTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let centerY = proxy.size.height / 2

            if visualMode.isInteractive {
                trackContent(width: width, centerY: centerY)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                onAdjustmentChanged(wakeTime(for: value.location.x, width: width))
                            }
                            .onEnded { value in
                                onAdjustmentEnded(wakeTime(for: value.location.x, width: width))
                            }
                    )
            } else {
                    trackContent(width: width, centerY: centerY)
            }
        }
        .onAppear {
            animatedMarkerRatio = ratio
            renderedIndicatorState = indicatorState
            renderedIndicatorIconName = indicatorIconName
            markerOpacity = indicatorState == .none || indicatorState == .unavailable ? 0 : 1
        }
        .onChange(of: ratio) { _, newRatio in
            updateMarker(targetRatio: newRatio, previousMode: visualMode, newMode: visualMode)
        }
        .onChange(of: visualMode) { oldMode, newMode in
            updateMarker(targetRatio: ratio, previousMode: oldMode, newMode: newMode)
        }
        .onChange(of: indicatorState) { _, newState in
            updateMarkerVisibility(for: newState)
        }
    }

    private func trackContent(width: CGFloat, centerY: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            trackAccessibilityElement(width: width, centerY: centerY)

            boundaryMarker(style: leftBoundaryMarkerStyle, x: 0, y: centerY)
                .id(leftBoundaryMarkerStyle.rawValue)
                .transition(.opacity)
                .animation(boundaryAnimation, value: leftBoundaryMarkerStyle.rawValue)

            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(height: metrics.rangeTrackHeight)
                .position(x: width / 2, y: centerY)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.32),
                            Color.white.opacity(0.18)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: max(1.5, metrics.rangeTrackHeight * 0.52))
                .position(x: width / 2, y: centerY)

            boundaryMarker(style: rightBoundaryMarkerStyle, x: width, y: centerY)
                .id(rightBoundaryMarkerStyle.rawValue)
                .transition(.opacity)
                .animation(boundaryAnimation, value: rightBoundaryMarkerStyle.rawValue)

            if let markerRatio = animatedMarkerRatio ?? ratio,
               renderedIndicatorState != .none,
               renderedIndicatorState != .unavailable {
                marker(
                    ratio: markerRatio,
                    width: width,
                    centerY: centerY,
                    state: renderedIndicatorState,
                    iconName: renderedIndicatorIconName
                )
                    .opacity(markerOpacity)
                    .animation(markerAnimation, value: animatedMarkerRatio)
                    .animation(markerAnimation, value: markerOpacity)
            }
        }
        .contentShape(Rectangle())
    }

    private var markerAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.38)
    }

    private var boundaryAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.18)
    }

    private func updateMarker(
        targetRatio: Double?,
        previousMode: MorningHeroFajrWindowVisualMode,
        newMode: MorningHeroFajrWindowVisualMode
    ) {
        guard let targetRatio else {
            withAnimation(markerAnimation) {
                markerOpacity = 0
            }
            animatedMarkerRatio = nil
            return
        }

        guard indicatorState != .none, indicatorState != .unavailable else {
            animatedMarkerRatio = targetRatio
            markerOpacity = 0
            return
        }

        guard !reduceMotion else {
            withAnimation(markerAnimation) {
                animatedMarkerRatio = targetRatio
                markerOpacity = 1
            }
            return
        }

        if previousMode != newMode, let handoffRatio = markerHandoffRatio(from: previousMode, to: newMode) {
            markerOpacity = 0
            animatedMarkerRatio = handoffRatio
            withAnimation(markerAnimation) {
                markerOpacity = 1
                animatedMarkerRatio = targetRatio
            }
        } else {
            withAnimation(markerAnimation) {
                markerOpacity = 1
                animatedMarkerRatio = targetRatio
            }
        }
    }

    private func updateMarkerVisibility(for state: MorningHeroWakeWindowIndicatorState) {
        markerRemovalTask?.cancel()
        let isHidden = state == .none || state == .unavailable
        if isHidden {
            withAnimation(markerAnimation) {
                markerOpacity = 0
            }
            markerRemovalTask = Task {
                try? await Task.sleep(nanoseconds: reduceMotion ? 120_000_000 : 180_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    renderedIndicatorState = state
                    renderedIndicatorIconName = nil
                    animatedMarkerRatio = ratio
                }
            }
        } else {
            renderedIndicatorState = state
            renderedIndicatorIconName = indicatorIconName
            withAnimation(markerAnimation) {
                animatedMarkerRatio = ratio
                markerOpacity = 1
            }
        }
    }

    private func markerHandoffRatio(
        from previousMode: MorningHeroFajrWindowVisualMode,
        to newMode: MorningHeroFajrWindowVisualMode
    ) -> Double? {
        if previousMode == .interactiveWithinFajrWindow,
           newMode == .interactiveEarlyWorshipWindow {
            return 1
        }
        if previousMode == .interactiveEarlyWorshipWindow,
           newMode == .interactiveWithinFajrWindow {
            return 0
        }
        return nil
    }

    private func trackAccessibilityElement(width: CGFloat, centerY: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: width, height: max(metrics.rangeMarkerSize, 44))
            .position(x: width / 2, y: centerY)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Fajr window track")
            .accessibilityIdentifier(MorningHeroUIIdentifier.fajrWindowTrack)
    }

    @ViewBuilder
    private func boundaryMarker(style: MorningHeroBoundaryMarkerStyle, x: CGFloat, y: CGFloat) -> some View {
        switch style {
        case .endpointCircle:
            Circle()
                .fill(Color.white.opacity(0.84))
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.36), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 1)
                .frame(width: metrics.rangeEndpointSize, height: metrics.rangeEndpointSize)
                .position(x: x, y: y)
        case .verticalLine:
            Capsule()
                .fill(Color.white.opacity(0.84))
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 1)
                .frame(
                    width: max(2, metrics.rangeEndpointSize * 0.32),
                    height: max(metrics.rangeEndpointSize * 1.8, metrics.rangeTrackHeight * 3.2)
                )
                .position(x: x, y: y)
        case .none:
            EmptyView()
        }
    }

    private func marker(
        ratio: Double,
        width: CGFloat,
        centerY: CGFloat,
        state: MorningHeroWakeWindowIndicatorState,
        iconName: String?
    ) -> some View {
        let markerSize = metrics.rangeMarkerSize
        let isBefore = ratio < 0
        let isAfter = ratio > 1
        let clampedRatio = min(max(ratio, 0), 1)
        let x: CGFloat = if isBefore {
            -markerSize * 0.34
        } else if isAfter {
            width + markerSize * 0.34
        } else {
            width * clampedRatio
        }

        return ZStack {
            if isBefore || isAfter {
                Capsule()
                    .fill(Color.white.opacity(0.64))
                    .frame(width: max(2, markerSize * 0.22), height: markerSize * 1.25)
                    .offset(x: isBefore ? markerSize * 0.38 : -markerSize * 0.38)
            }

            switch state {
            case .active:
                markerIcon(
                    systemName: iconName ?? "alarm.fill",
                    size: markerSize,
                    isOffState: false
                )
            case .offAnchor:
                markerIcon(
                    systemName: iconName ?? "bell.slash.fill",
                    size: markerSize,
                    isOffState: true
                )
            case .none, .unavailable:
                EmptyView()
            }
        }
        .frame(width: max(markerSize, 44), height: max(markerSize, 44))
        .position(x: x, y: centerY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state == .offAnchor ? "Wake marker off" : "Wake marker")
        .accessibilityIdentifier(MorningHeroUIIdentifier.fajrWindowMarker)
    }

    private func markerIcon(systemName: String, size: CGFloat, isOffState: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(WakeGlassTheme.primaryText.opacity(isOffState ? 0.78 : 0.96))
            .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 1)
            .accessibilityHidden(true)
    }

    private func wakeTime(for x: CGFloat, width: CGFloat) -> Date {
        guard let minTime, let maxTime, width > 0 else {
            return minTime ?? Date()
        }

        return MorningHeroWakeAdjustmentMapper.wakeTime(
            forX: x,
            width: width,
            minTime: minTime,
            maxTime: maxTime,
            stepMinutes: stepMinutes
        )
    }
}

private extension View {
    @ViewBuilder
    func heroWakeAdjustmentAccessibility(
        display: MorningHomeHeroDisplay,
        onAdjust: @escaping (AccessibilityAdjustmentDirection) -> Void
    ) -> some View {
        if display.wakeAdjustmentEnabled {
            self
                .accessibilityValue(display.wakeAdjustmentAccessibilityValue ?? "")
                .accessibilityAdjustableAction { direction in
                    onAdjust(direction)
                }
        } else {
            self
        }
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

private struct NextTenMorningsCard: View {
    let entries: [WakeRowEntry]
    let onSelect: (WakeRowEntry) -> Void

    var body: some View {
        let forecast = MorningHomePresentation.nextTenMorningsSnapshot(from: entries)

        AppGlassSurface(
            variant: .grouped,
            contentPadding: 0
        ) {
            VStack(spacing: 0) {
                Text(forecast.title)
                    .appTextRole(.eyebrow)
                    .foregroundStyle(WakeGlassTheme.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.spacingL)
                    .padding(.bottom, DesignTokens.spacingS)

                NextTenMorningsDivider(inset: DesignTokens.spacingL)

                if forecast.loadingState == .empty {
                    Text("Wake forecast will appear once times are available.")
                        .font(AppTypography.rowBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignTokens.spacingL)
                        .padding(.vertical, DesignTokens.spacingM)
                } else {
                    ForEach(Array(forecast.rows.enumerated()), id: \.element.id) { index, row in
                        NextTenMorningsRow(display: row, rowMetrics: forecast.rowMetrics) {
                            guard let entry = entries.first(where: { $0.id == row.id }) else { return }
                            onSelect(entry)
                        }
                        .padding(.horizontal, DesignTokens.spacingM)

                        if index < forecast.rows.count - 1 {
                            NextTenMorningsDivider(inset: DesignTokens.spacingM)
                        }
                    }
                }
            }
        }
    }
}

private struct NextTenMorningsRow: View {
    let display: NextTenMorningsRowDisplay
    let rowMetrics: NextTenMorningsRowMetrics
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            rowContent
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.accessibilityLabel)
        }
        .buttonStyle(.plain)
        .padding(.vertical, DesignTokens.compactRowVerticalPadding)
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(display.dateLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(display.isInactive ? WakeGlassTheme.primaryText.opacity(0.62) : WakeGlassTheme.primaryText.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: CGFloat(rowMetrics.dateLaneWidth), alignment: .leading)

            Color.clear
                .frame(width: CGFloat(rowMetrics.minimumDateToTagGap))

            tagLane
                .frame(
                    minWidth: CGFloat(rowMetrics.minimumTagLaneWidth),
                    maxWidth: .infinity,
                    alignment: .center
                )

            Color.clear
                .frame(width: CGFloat(rowMetrics.minimumTagToTimeGap))

            trailingLockup
                .frame(width: CGFloat(rowMetrics.trailingLaneWidth), alignment: .trailing)
        }
    }

    private var tagLane: some View {
        ViewThatFits(in: .horizontal) {
            NextTenMorningsTagCluster(tags: display.tags, isDisabled: display.isInactive)
            NextTenMorningsTagCluster(tags: Array(display.tags.prefix(2)), isDisabled: display.isInactive)
            NextTenMorningsTagCluster(tags: Array(display.tags.prefix(1)), isDisabled: display.isInactive)
        }
    }

    @ViewBuilder
    private var trailingLockup: some View {
        if let trailingTime = display.trailingTime {
            NextTenMorningsTimeLockup(date: trailingTime, isDisabled: display.isInactive)
                .fixedSize(horizontal: true, vertical: false)
        } else if let trailingStatusText = display.trailingStatusText {
            Text(trailingStatusText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)
        }
    }
}

private enum NextTenMorningsTagMetrics {
    static let interTagSpacing: CGFloat = 4
    static let horizontalPadding: CGFloat = 6
    static let verticalPadding: CGFloat = 3
    static let strokeWidth: CGFloat = 0.8
}

private struct NextTenMorningsTagCluster: View {
    let tags: [NextTenMorningsTagDisplay]
    let isDisabled: Bool

    var body: some View {
        tagRow(tags)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func tagRow(_ tags: [NextTenMorningsTagDisplay]) -> some View {
        HStack(spacing: NextTenMorningsTagMetrics.interTagSpacing) {
            ForEach(tags) { tag in
                NextTenMorningsTagChip(tag: tag, isDisabled: isDisabled)
            }
        }
    }
}

private struct NextTenMorningsTagChip: View {
    let tag: NextTenMorningsTagDisplay
    let isDisabled: Bool

    var body: some View {
        let base = color(for: tag.semantic)
        let fillOpacity = fillOpacity(for: tag.prominence)
        let strokeOpacity = strokeOpacity(for: tag.prominence)

        Text(tag.title)
            .font(AppTypography.badge)
            .foregroundStyle(textColor(base: base, prominence: tag.prominence))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.vertical, NextTenMorningsTagMetrics.verticalPadding)
            .padding(.horizontal, NextTenMorningsTagMetrics.horizontalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(base.opacity(fillOpacity))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(base.opacity(strokeOpacity), lineWidth: NextTenMorningsTagMetrics.strokeWidth)
                    }
            )
            .opacity(isDisabled ? 0.55 : 1.0)
            .accessibilityHidden(true)
    }

    private func color(for semantic: NextTenMorningsTagSemantic) -> Color {
        switch semantic {
        case .fajrFallback:
            return Color.white
        case .quietMode:
            return Color.gray
        case .ramadan:
            return FastPrimaryIntent.ramadanObligatory.style.color
        case .fastingIntent:
            return FastPrimaryIntent.voluntary.style.color
        case .tahajjudIntent:
            return Color.purple
        case .qada:
            return FastPrimaryIntent.qadaMakeup.style.color
        case .kaffarah:
            return FastPrimaryIntent.kaffarahExpiation.style.color
        case .vow:
            return FastPrimaryIntent.vowNadhr.style.color
        case .observanceOpportunity(let tag), .observanceIntended(let tag):
            return tag.style.color
        }
    }

    private func textColor(
        base: Color,
        prominence: NextTenMorningsTagProminence
    ) -> Color {
        switch prominence {
        case .fallback:
            return WakeGlassTheme.secondaryText
        case .strong, .opportunity:
            return base
        }
    }

    private func fillOpacity(for prominence: NextTenMorningsTagProminence) -> Double {
        switch prominence {
        case .strong:
            return 0.18
        case .opportunity:
            return 0.10
        case .fallback:
            return 0.07
        }
    }

    private func strokeOpacity(for prominence: NextTenMorningsTagProminence) -> Double {
        switch prominence {
        case .strong:
            return 0.34
        case .opportunity:
            return 0.22
        case .fallback:
            return 0.12
        }
    }
}

private struct NextTenMorningsDivider: View {
    let inset: CGFloat

    var body: some View {
        Rectangle()
            .fill(WakeGlassTheme.divider)
            .frame(height: 1)
            .padding(.leading, inset)
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

private struct NextTenMorningsTimeLockup: View {
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
