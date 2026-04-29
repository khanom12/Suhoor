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
                            currentDate: scheduleManager.currentDate,
                            onCommitWakeAdjustment: { date, wakeTime in
                                await scheduleManager.commitHeroWakeAdjustment(for: date, wakeTime: wakeTime)
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
    let currentDate: Date
    let onCommitWakeAdjustment: (Date, Date) async -> Bool
    let onOpen: () -> Void

    @State private var tentativeWakeTime: Date?
    @State private var isCommittingWakeAdjustment = false

    var body: some View {
        let baseDisplay = MorningHomePresentation.heroDisplay(
            entry: entry,
            permissionSummary: permissionSummary,
            currentDate: currentDate
        )
        let display = tentativeWakeTime.map {
            MorningHomePresentation.heroDisplay(adjusting: baseDisplay, tentativeWakeTime: $0)
        } ?? baseDisplay
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)

        VStack(alignment: .center, spacing: 0) {
            if let dateLine = display.dateLine {
                Text(dateLine)
                    .font(.system(size: metrics.dateLineSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(display.title)
                .font(.system(size: metrics.relativeLabelSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, metrics.dateToRelativeGap)

            primaryWakeRow(display: display, metrics: metrics)
                .padding(.top, metrics.relativeToPrimaryGap)

            Text(display.detailText)
                .font(.system(size: metrics.dateLineSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, metrics.primaryToRelationGap)
                .accessibilityIdentifier(MorningHeroUIIdentifier.relation)

            if display.fajrWindowVisualMode.rendersRange {
                FajrWindowRangeVisual(display: display, metrics: metrics)
                    .onWakeAdjustmentChanged { wakeTime in
                        tentativeWakeTime = wakeTime
                    }
                    .onWakeAdjustmentEnded { wakeTime in
                        commitWakeAdjustment(wakeTime)
                    }
                    .heroWakeAdjustmentAccessibility(display: display) { direction in
                        adjustWakeAccessibility(display: display, direction: direction)
                    }
                    .padding(.top, metrics.relationToWindowGap)
            }
        }
        .frame(maxWidth: metrics.maxContentWidth)
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.top, metrics.verticalBreathing)
        .padding(.bottom, metrics.verticalBreathing + metrics.bottomGapBeforeNextCard - DesignTokens.spacingL)
        .frame(maxWidth: .infinity, minHeight: metrics.minHeroRegionHeight, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture {
            guard entry != nil, !isCommittingWakeAdjustment else { return }
            onOpen()
        }
        .onChange(of: entry?.id) { _, _ in
            tentativeWakeTime = nil
            isCommittingWakeAdjustment = false
        }
        .onChange(of: entry?.schedule.wakeDate) { _, _ in
            if !isCommittingWakeAdjustment {
                tentativeWakeTime = nil
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(entry == nil ? [] : .isButton)
        .accessibilityLabel(display.accessibilityLabel)
        .accessibilityHint(entry == nil ? "" : "Double-tap for details.")
    }

    @ViewBuilder
    private func primaryWakeRow(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics
    ) -> some View {
        if let primaryTime = display.primaryTime {
            HStack(alignment: .center, spacing: metrics.primaryRowSpacing) {
                if let iconName = display.wakeIconName {
                    Image(systemName: iconName)
                        .font(.system(size: metrics.iconSize, weight: .regular))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
                        .offset(y: metrics.iconVerticalOffset)
                }

                SubhHomeHeroTimeLockup(date: primaryTime, pointSize: metrics.wakeTimeSize)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .lineLimit(1)
            .minimumScaleFactor(0.84)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.primaryText)
            .accessibilityIdentifier(MorningHeroUIIdentifier.primaryWakeTime)
        } else {
            HStack(alignment: .center, spacing: metrics.primaryRowSpacing) {
                if let iconName = display.wakeIconName {
                    Image(systemName: iconName)
                        .font(.system(size: metrics.iconSize, weight: .regular))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.86))
                        .offset(y: metrics.iconVerticalOffset)
                }

                Text(display.primaryText)
                    .font(.system(size: metrics.wakeStateSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.primaryText)
            .accessibilityIdentifier(MorningHeroUIIdentifier.primaryWakeTime)
        }
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
            minHeroRegionHeight = 236
            minTextStackHeight = 140
            bottomGapBeforeNextCard = 28
        case .small:
            scale = 0.94
            minHeroRegionHeight = 242
            minTextStackHeight = 148
            bottomGapBeforeNextCard = 30
        case .medium:
            scale = 0.98
            minHeroRegionHeight = 248
            minTextStackHeight = 154
            bottomGapBeforeNextCard = 32
        case .large:
            scale = 1.00
            minHeroRegionHeight = 256
            minTextStackHeight = 162
            bottomGapBeforeNextCard = 36
        case .xLarge:
            scale = 1.08
            minHeroRegionHeight = 276
            minTextStackHeight = 180
            bottomGapBeforeNextCard = 38
        case .xxLarge:
            scale = 1.17
            minHeroRegionHeight = 304
            minTextStackHeight = 204
            bottomGapBeforeNextCard = 42
        case .xxxLarge:
            scale = 1.28
            minHeroRegionHeight = 334
            minTextStackHeight = 232
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
    var fajrWindowSize: CGFloat { 15 * scale }
    var dateToRelativeGap: CGFloat { max(4, 4 * scale) }
    var relativeToDateGap: CGFloat { dateToRelativeGap }
    var relativeToPrimaryGap: CGFloat { max(9, 11 * min(scale, 1.18)) }
    var primaryToRelationGap: CGFloat { 8 * min(scale, 1.2) }
    var relationToWindowGap: CGFloat { 12 * min(scale, 1.2) }
    var primaryRowSpacing: CGFloat { max(7, 8 * scale) }
    var iconVerticalOffset: CGFloat { -1 * scale }
    var verticalBreathing: CGFloat { max(18, (minHeroRegionHeight - minTextStackHeight) / 2) }
    var maxContentWidth: CGFloat { 390 }
    var rangeTrackHeight: CGFloat { max(3, 4 * scale) }
    var rangeTrackWidth: CGFloat { min(176, max(124, 142 * scale)) }
    var rangeMarkerSize: CGFloat { max(16, 18 * scale) }
    var rangeEndpointSize: CGFloat { max(8, 9 * scale) }
    var rangeRowSpacing: CGFloat { max(9, 10 * scale) }
    var rangeFallbackSpacing: CGFloat { max(7, 8 * scale) }
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
                visualMode: display.fajrWindowVisualMode,
                minTime: display.wakeAdjustmentMinTime,
                maxTime: display.wakeAdjustmentMaxTime,
                stepMinutes: display.wakeAdjustmentStepMinutes,
                metrics: metrics
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
                visualMode: display.fajrWindowVisualMode,
                minTime: display.wakeAdjustmentMinTime,
                maxTime: display.wakeAdjustmentMaxTime,
                stepMinutes: display.wakeAdjustmentStepMinutes,
                metrics: metrics
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
            .accessibilityIdentifier(identifier)
    }
}

private struct FajrWindowRangeTrack: View {
    let ratio: Double?
    let indicatorState: MorningHeroWakeWindowIndicatorState
    let indicatorIconName: String?
    let visualMode: MorningHeroFajrWindowVisualMode
    let minTime: Date?
    let maxTime: Date?
    let stepMinutes: Int
    let metrics: MorningHeroMetrics
    let onAdjustmentChanged: (Date) -> Void
    let onAdjustmentEnded: (Date) -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let centerY = proxy.size.height / 2

            if visualMode == .interactiveWithinFajrWindow {
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
    }

    private func trackContent(width: CGFloat, centerY: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            trackAccessibilityElement(width: width, centerY: centerY)

            endpoint(x: 0, y: centerY)

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

            endpoint(x: width, y: centerY)

            if let ratio, indicatorState != .none, indicatorState != .unavailable {
                marker(ratio: ratio, width: width, centerY: centerY)
            }
        }
        .contentShape(Rectangle())
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

    private func endpoint(x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.84))
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.36), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 1)
            .frame(width: metrics.rangeEndpointSize, height: metrics.rangeEndpointSize)
            .position(x: x, y: y)
    }

    private func marker(ratio: Double, width: CGFloat, centerY: CGFloat) -> some View {
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

            switch indicatorState {
            case .active:
                markerIcon(
                    systemName: indicatorIconName ?? "alarm.fill",
                    size: markerSize,
                    isOffState: false
                )
            case .offAnchor:
                markerIcon(
                    systemName: indicatorIconName ?? "bell.slash.fill",
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
        .accessibilityLabel(indicatorState == .offAnchor ? "Wake marker off" : "Wake marker")
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
