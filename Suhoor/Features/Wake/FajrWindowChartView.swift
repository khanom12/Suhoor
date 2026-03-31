import SwiftUI

struct FajrWindowChartView: View {
    enum LayoutStyle {
        case compact
        case detail

        var plotHeight: CGFloat {
            switch self {
            case .compact:
                return 90
            case .detail:
                return 292
            }
        }

        var plotInsets: EdgeInsets {
            switch self {
            case .compact:
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            case .detail:
                return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            }
        }

        var plotCornerRadius: CGFloat {
            switch self {
            case .compact:
                return 0
            case .detail:
                return DesignTokens.innerCardRadius
            }
        }

        var showsDetailYAxis: Bool {
            self == .detail
        }
    }

    private struct CompactLayoutMetrics {
        let calloutFrame: CGRect
        let chartFrame: CGRect
        let plotFrame: CGRect
        let dayColumnFrame: CGRect
        let weekdayRowY: CGFloat
        let yAxisLabelWidth: CGFloat
        let yAxisLabelMinX: CGFloat
        let rightRailMinX: CGFloat
        let rightRailMaxX: CGFloat
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let chart: FajrWindowChartSnapshot
    let layoutStyle: LayoutStyle
    var compactSelectedDay: FajrWindowCompactSelectedDaySnapshot? = nil
    var onSelectDateKey: ((String) -> Void)? = nil
    var onMoveSelection: ((Int) -> Void)? = nil
    var accessibilityLabel: String? = nil
    var accessibilityValue: String? = nil
    var accessibilityHint: String? = nil

    var body: some View {
        accessibleChart(baseChart)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: layoutStyle == .compact ? compactTotalHeight : layoutStyle.plotHeight)
            .overlay(
                Text("Upcoming mornings will appear here.")
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            )
    }

    private var baseChart: some View {
        Group {
            if chart.points.isEmpty {
                placeholder
            } else if layoutStyle == .compact {
                compactChart
            } else {
                detailChart
            }
        }
    }

    private var detailChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                yAxis
                    .frame(width: 60, height: layoutStyle.plotHeight)

                plotArea
                    .frame(maxWidth: .infinity)
            }

            xAxis
                .frame(height: 18)
        }
    }

    private var compactChart: some View {
        GeometryReader { geometry in
            let metrics = compactLayoutMetrics(in: geometry.size)

            ZStack(alignment: .topLeading) {
                compactSelectedRangeBackdrop(in: metrics)
                compactSelectedDayOverlay(in: metrics)
                compactFrameChrome(in: metrics)
                horizontalGrid(in: metrics.plotFrame)
                verticalGrid(in: metrics.dayColumnFrame)
                compactSelectedDayGuide(in: metrics)
                boundaryBand(in: metrics.plotFrame)
                boundaryLine(
                    for: \.fajrStartMinutes,
                    color: compactBoundaryColor,
                    lineWidth: 1.1,
                    dash: [],
                    in: metrics.plotFrame
                )
                boundaryLine(
                    for: \.fajrEndOrBoundaryMinutes,
                    color: compactBoundaryColor,
                    lineWidth: 1.1,
                    dash: [],
                    in: metrics.plotFrame
                )
                markerLayer(in: metrics.plotFrame)
                compactYAxis(in: metrics)
                compactSelectedDayCallout(in: metrics)
                compactXAxis(in: metrics)
            }
        }
        .frame(height: compactTotalHeight)
    }

    @ViewBuilder
    private func accessibleChart<Content: View>(_ content: Content) -> some View {
        if let accessibilityLabel, let accessibilityValue {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(accessibilityValue)
                .accessibilityHint(
                    accessibilityHint
                    ?? "The shaded band shows this week's Fajr interval and the markers show your alarms."
                )
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        onMoveSelection?(1)
                    case .decrement:
                        onMoveSelection?(-1)
                    @unknown default:
                        break
                    }
                }
        } else {
            content
        }
    }

    private var plotArea: some View {
        GeometryReader { geometry in
            let frame = plotFrame(in: geometry.size)

            ZStack {
                RoundedRectangle(cornerRadius: layoutStyle.plotCornerRadius, style: .continuous)
                    .fill(plotBackgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: layoutStyle.plotCornerRadius, style: .continuous)
                            .stroke(plotBorderColor, lineWidth: 1)
                    )

                horizontalGrid(in: frame)
                verticalGrid(in: frame)
                selectedDayAxis(in: frame)
                boundaryBand(in: frame)
                boundaryLine(for: \.fajrStartMinutes, color: boundaryStartColor, lineWidth: 1.1, dash: [], in: frame)
                boundaryLine(for: \.fajrEndOrBoundaryMinutes, color: boundaryEndColor, lineWidth: 1.4, dash: [], in: frame)
                primaryWakeLine(in: frame)

                if chart.activeOverlay != .myWake {
                    overlayLine(for: chart.activeOverlay, in: frame)
                }

                markerLayer(in: frame)
                touchOverlay(in: frame)
            }
        }
        .frame(height: layoutStyle.plotHeight)
    }

    private var plotBackgroundFill: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.black.opacity(0.18),
                    DawnColor.lightGold900.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(0.78),
                DawnColor.lightGold100.opacity(0.78),
                DawnColor.lightApricot100.opacity(0.52)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var plotBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var boundaryStartColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.54) : Color.black.opacity(0.42)
    }

    private var boundaryEndColor: Color {
        colorScheme == .dark ? DawnColor.lightGold100.opacity(0.92) : Color.black.opacity(0.74)
    }

    private var compactBoundaryColor: Color {
        Color.white.opacity(0.5)
    }

    private var selectedAxisColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.16)
    }

    private var compactSelectedGuideColor: Color {
        .white
    }

    private var gridColor: Color {
        layoutStyle == .compact
            ? Color.white.opacity(0.10)
            : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10))
    }

    private var compactPrimaryTextColor: Color {
        .white
    }

    private var compactSecondaryTextColor: Color {
        Color.white.opacity(0.5)
    }

    private var compactTertiaryTextColor: Color {
        Color.white.opacity(0.42)
    }

    private var compactBandFill: Color {
        Color.black.opacity(0.48)
    }

    private var compactPlotMarkerColor: Color {
        .white
    }

    private var compactCalloutPrimaryColor: Color {
        .white
    }

    private var compactCalloutSecondaryColor: Color {
        Color.white.opacity(0.5)
    }

    @ViewBuilder
    private func horizontalGrid(in frame: CGRect) -> some View {
        ForEach(displayTicks) { tick in
            Path { path in
                let y = yPosition(for: tick.minutes, in: frame)
                path.move(to: CGPoint(x: frame.minX, y: y))
                path.addLine(to: CGPoint(x: frame.maxX, y: y))
            }
            .stroke(
                gridColor,
                style: StrokeStyle(lineWidth: layoutStyle == .compact ? 1 : 1, dash: layoutStyle == .compact ? [] : [4, 5])
            )
        }
    }

    @ViewBuilder
    private func verticalGrid(in frame: CGRect) -> some View {
        ForEach(chart.points) { point in
            let isSelected = point.dateKey == chart.selectedDateKey

            Path { path in
                let x = xPosition(for: point, in: frame)
                path.move(to: CGPoint(x: x, y: frame.minY))
                path.addLine(to: CGPoint(x: x, y: frame.maxY))
            }
            .stroke(
                layoutStyle == .compact ? gridColor : (isSelected ? selectedAxisColor : gridColor.opacity(0.9)),
                lineWidth: layoutStyle == .compact ? 1 : (isSelected ? 1.2 : 1)
            )
        }
    }

    @ViewBuilder
    private func selectedDayAxis(in frame: CGRect) -> some View {
        if layoutStyle == .detail,
           let selectedPoint = chart.points.first(where: { $0.dateKey == chart.selectedDateKey }) {
            let x = xPosition(for: selectedPoint, in: frame)
            Path { path in
                path.move(to: CGPoint(x: x, y: frame.minY))
                path.addLine(to: CGPoint(x: x, y: frame.maxY))
            }
            .stroke(selectedAxisColor, style: StrokeStyle(lineWidth: 1.4, dash: [4, 5]))
        }
    }

    @ViewBuilder
    private func boundaryBand(in frame: CGRect) -> some View {
        if let path = bandPath(in: frame) {
            path
                .fill(layoutStyle == .compact ? AnyShapeStyle(compactBandFill) : AnyShapeStyle(detailBandFill))
                .overlay(
                    path.stroke(
                        layoutStyle == .compact
                        ? compactBoundaryColor.opacity(0.12)
                        : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)),
                        lineWidth: 1
                    )
                )
        }
    }

    private var detailBandFill: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color.black.opacity(0.48),
                    DawnColor.lightGold900.opacity(0.44)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [
                Color.black.opacity(0.26),
                DawnColor.lightGold900.opacity(0.22)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private func boundaryLine(
        for keyPath: KeyPath<FajrWindowPoint, Int>,
        color: Color,
        lineWidth: CGFloat,
        dash: [CGFloat],
        in frame: CGRect
    ) -> some View {
        if let path = linePath(for: keyPath, in: frame) {
            path.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: dash))
        }
    }

    @ViewBuilder
    private func primaryWakeLine(in frame: CGRect) -> some View {
        if let path = linePath(for: \.primaryWakeMinutes, in: frame) {
            path.stroke(
                colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.80),
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )
        }
    }

    @ViewBuilder
    private func overlayLine(
        for overlay: FajrWindowOverlay,
        in frame: CGRect
    ) -> some View {
        switch overlay {
        case .myWake:
            EmptyView()
        case .compareSafe:
            dashedOverlayLine(for: \.saferWakeMinutes, color: Color.green.opacity(0.82), in: frame)
        case .compareFasting:
            dashedOverlayLine(for: \.fastingWakeMinutes, color: Color.pink.opacity(0.78), in: frame)
        case .compareTahajjud:
            dashedOverlayLine(for: \.tahajjudWakeMinutes, color: Color.blue.opacity(0.80), in: frame)
        }
    }

    @ViewBuilder
    private func dashedOverlayLine(
        for keyPath: KeyPath<FajrWindowPoint, Int?>,
        color: Color,
        in frame: CGRect
    ) -> some View {
        if let path = optionalLinePath(for: keyPath, in: frame) {
            path.stroke(
                color,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 6])
            )
        }
    }

    @ViewBuilder
    private func markerLayer(in frame: CGRect) -> some View {
        ForEach(markerPoints) { point in
            let isSelected = point.dateKey == chart.selectedDateKey
            let x = xPosition(for: point, in: frame)
            let y = yPosition(for: point.primaryWakeMinutes, in: frame)

            if isSelected {
                selectedMarker(point: point)
                    .position(x: x, y: y)
            } else if point.isSkipped {
                skippedMarker
                    .position(x: x, y: y)
            } else {
                Circle()
                    .fill(layoutStyle == .compact ? compactSecondaryTextColor.opacity(0.74) : regularMarkerColor)
                    .frame(
                        width: layoutStyle == .compact ? 9 : 7,
                        height: layoutStyle == .compact ? 9 : 7
                    )
                    .position(x: x, y: y)
            }
        }
    }

    private var regularMarkerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.34) : Color.black.opacity(0.28)
    }

    @ViewBuilder
    private func selectedMarker(point: FajrWindowPoint) -> some View {
        if layoutStyle == .compact {
            Image(systemName: point.isSkipped ? "bell.slash.fill" : "alarm.fill")
                .font(.system(size: compactMarkerPointSize, weight: .semibold))
                .foregroundStyle(compactPlotMarkerColor)
        } else {
            Image(systemName: point.isSkipped ? "bell.slash.fill" : "alarm.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                .padding(6)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? DawnColor.lightGold200.opacity(0.28) : Color.white.opacity(0.92))
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private var skippedMarker: some View {
        Group {
            if layoutStyle == .compact {
                Image(systemName: "bell.slash")
                    .font(.system(size: compactSkippedMarkerPointSize, weight: .medium))
                    .foregroundStyle(compactSecondaryTextColor)
            } else {
                Image(systemName: "bell.slash")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.42) : Color.black.opacity(0.36))
                    .padding(4)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    )
            }
        }
    }

    @ViewBuilder
    private func compactYAxis(in metrics: CompactLayoutMetrics) -> some View {
        ForEach(displayTicks) { tick in
            Text(splitTickLabel(tick.label).main)
                .font(.system(size: compactYAxisValuePointSize, weight: .medium))
                .foregroundStyle(compactSecondaryTextColor)
                .monospacedDigit()
                .frame(width: metrics.yAxisLabelWidth, height: compactYAxisLabelHeight, alignment: .topLeading)
                .offset(
                    x: metrics.yAxisLabelMinX,
                    y: yPosition(for: tick.minutes, in: metrics.plotFrame) + compactYAxisLabelTopInset
                )
        }
    }

    @ViewBuilder
    private func inlineIntervalLabels(in frame: CGRect) -> some View {
        if layoutStyle == .compact,
           dynamicTypeSize < .accessibility1,
           chart.renderPoints.count >= 3 {
            let anchor = chart.renderPoints[min(chart.renderPoints.count / 2, chart.renderPoints.count - 1)]
            let labelX = frame.midX

            Text("FAJR BEGINS")
                .font(.system(size: 6, weight: .light))
                .foregroundStyle(compactTertiaryTextColor)
                .rotationEffect(.degrees(-4.5))
                .position(
                    x: labelX,
                    y: yPosition(for: anchor.fajrStartMinutes, in: frame) - 7
                )

            Text("FAJR ENDS")
                .font(.system(size: 6, weight: .light))
                .foregroundStyle(compactTertiaryTextColor)
                .rotationEffect(.degrees(-4.5))
                .position(
                    x: labelX + 1,
                    y: yPosition(for: anchor.fajrEndOrBoundaryMinutes, in: frame) + 8
                )
        }
    }

    @ViewBuilder
    private func touchOverlay(in frame: CGRect) -> some View {
        if let onSelectDateKey, layoutStyle == .detail {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard let point = nearestPoint(to: value.location.x, in: frame) else { return }
                            onSelectDateKey(point.dateKey)
                        }
                )
        }
    }

    private var xAxis: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                ForEach(displayXAxisLabels) { label in
                    Text(label.title)
                        .font(.caption.weight(label.dateKey == chart.selectedDateKey ? .semibold : .regular))
                        .foregroundStyle(label.dateKey == chart.selectedDateKey ? .primary : .secondary)
                        .position(
                            x: xPosition(forOrdinal: label.dayOrdinal, width: geometry.size.width),
                            y: geometry.size.height / 2
                        )
                }
            }
        }
    }

    private var yAxis: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(displayTicks) { tick in
                Text(tick.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    private var displayDomain: ClosedRange<Int> {
        if layoutStyle == .compact {
            guard let firstTick = chart.compactYTicks.first?.minutes,
                  let lastTick = chart.compactYTicks.last?.minutes else {
                return chart.compactChartDomain
            }

            let step = chart.compactYTicks.count > 1
                ? max(1, chart.compactYTicks[1].minutes - firstTick)
                : 30
            return firstTick...min((24 * 60), lastTick + step)
        }

        return chart.chartDomain
    }

    private var displayTicks: [FajrWindowChartTick] {
        layoutStyle == .compact ? chart.compactYTicks : chart.yTicks
    }

    private var displayXAxisLabels: [FajrWindowAxisLabel] {
        if layoutStyle == .compact {
            return chart.points.map { point in
                FajrWindowAxisLabel(
                    dateKey: point.dateKey,
                    title: weekdayInitial(for: point.date),
                    dayOrdinal: point.dayOrdinal
                )
            }
        }

        return chart.xAxisLabels
    }

    private var markerPoints: [FajrWindowPoint] {
        if chart.period == .oneYear, let selected = chart.points.first(where: { $0.dateKey == chart.selectedDateKey }) {
            return [selected]
        }
        return chart.points
    }

    private var compactTotalHeight: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return 156
        }

        if dynamicTypeSize >= .xxxLarge {
            return 148
        }

        return 143
    }

    private var compactMarkerPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var compactSkippedMarkerPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 11 : 10
    }

    private var compactYAxisValuePointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 12
    }

    private var compactYAxisLabelHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 14
    }

    private var compactYAxisLabelTopInset: CGFloat {
        1
    }

    private var compactAxisPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var compactCalloutLabelPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var compactCalloutTimePointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 18 : 16
    }

    private var compactCalloutSuffixPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 11 : 10
    }

    private var compactSelectedGuideHalfHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 7.5 : 6.5
    }

    private var compactSelectedCalloutYOffset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? -1 : -2
    }

    private func compactLayoutMetrics(in size: CGSize) -> CompactLayoutMetrics {
        let plotTop = dynamicTypeSize.isAccessibilitySize ? 34.0 : 31.0
        let plotHeight = dynamicTypeSize.isAccessibilitySize ? 94.0 : 89.0
        let rightRailWidth = dynamicTypeSize.isAccessibilitySize ? 40.0 : 35.0
        let plotMinX = 1.0
        let dayColumnWidth = max(1, size.width - rightRailWidth - plotMinX)
        let plotWidth = max(1, dayColumnWidth - 1)
        let weekdayRowY = plotTop + plotHeight + (dynamicTypeSize.isAccessibilitySize ? 14 : 12.5)
        let yAxisLabelWidth = dynamicTypeSize.isAccessibilitySize ? 32.0 : 28.0
        let yAxisLabelMinX = size.width - (dynamicTypeSize.isAccessibilitySize ? 35.0 : 31.0)
        let rightRailMinX = size.width - rightRailWidth

        let chartFrame = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height
        )
        let plotFrame = CGRect(
            x: plotMinX,
            y: plotTop,
            width: plotWidth,
            height: plotHeight
        )
        let dayColumnFrame = CGRect(
            x: plotFrame.minX,
            y: plotFrame.minY,
            width: dayColumnWidth,
            height: plotHeight
        )

        return CompactLayoutMetrics(
            calloutFrame: CGRect(x: 0, y: 0, width: size.width, height: plotTop),
            chartFrame: chartFrame,
            plotFrame: plotFrame,
            dayColumnFrame: dayColumnFrame,
            weekdayRowY: weekdayRowY,
            yAxisLabelWidth: yAxisLabelWidth,
            yAxisLabelMinX: yAxisLabelMinX,
            rightRailMinX: rightRailMinX,
            rightRailMaxX: size.width
        )
    }

    @ViewBuilder
    private func compactSelectedDayGuide(in metrics: CompactLayoutMetrics) -> some View {
        if let selectedPoint = chart.points.first(where: { $0.dateKey == chart.selectedDateKey }) {
            let x = xPosition(for: selectedPoint, in: metrics.dayColumnFrame)
            let markerY = yPosition(for: selectedPoint.primaryWakeMinutes, in: metrics.plotFrame)
            let markerHalfHeight = compactSelectedGuideHalfHeight

            Path { path in
                path.move(to: CGPoint(x: x, y: metrics.plotFrame.minY))
                path.addLine(to: CGPoint(x: x, y: markerY - markerHalfHeight))
                path.move(to: CGPoint(x: x, y: markerY + markerHalfHeight))
                path.addLine(to: CGPoint(x: x, y: metrics.plotFrame.maxY))
            }
            .stroke(compactSelectedGuideColor, style: StrokeStyle(lineWidth: 1.8, dash: [5, 4]))
        }
    }

    @ViewBuilder
    private func compactSelectedRangeBackdrop(in metrics: CompactLayoutMetrics) -> some View {
        if let selectedPoint = chart.points.first(where: { $0.dateKey == chart.selectedDateKey }) {
            let selectedX = xPosition(for: selectedPoint, in: metrics.dayColumnFrame)

            Rectangle()
                .fill(Color.black.opacity(0.30))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .frame(
                    width: max(0, selectedX),
                    height: metrics.plotFrame.height
                )
                .position(
                    x: max(0, selectedX) / 2,
                    y: metrics.plotFrame.midY
                )
        }
    }

    @ViewBuilder
    private func compactSelectedDayOverlay(in metrics: CompactLayoutMetrics) -> some View {
        if let selectedPoint = chart.points.first(where: { $0.dateKey == chart.selectedDateKey }) {
            let selectedX = xPosition(for: selectedPoint, in: metrics.dayColumnFrame)

            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(
                    width: dynamicTypeSize.isAccessibilitySize ? 82 : 74,
                    height: metrics.plotFrame.maxY
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                .position(
                    x: selectedX,
                    y: metrics.plotFrame.maxY / 2
                )
        }
    }

    @ViewBuilder
    private func compactFrameChrome(in metrics: CompactLayoutMetrics) -> some View {
        Path { path in
            path.move(to: CGPoint(x: metrics.plotFrame.minX, y: metrics.plotFrame.minY))
            path.addLine(to: CGPoint(x: metrics.rightRailMinX, y: metrics.plotFrame.minY))
            path.move(to: CGPoint(x: metrics.plotFrame.minX, y: metrics.plotFrame.minY))
            path.addLine(to: CGPoint(x: metrics.plotFrame.minX, y: metrics.plotFrame.maxY))
            path.move(to: CGPoint(x: metrics.rightRailMinX, y: metrics.plotFrame.minY))
            path.addLine(to: CGPoint(x: metrics.rightRailMinX, y: metrics.plotFrame.maxY))
            path.move(to: CGPoint(x: metrics.plotFrame.minX, y: metrics.plotFrame.maxY))
            path.addLine(to: CGPoint(x: metrics.rightRailMinX, y: metrics.plotFrame.maxY))
        }
        .stroke(gridColor, lineWidth: 1)

        ForEach(displayTicks) { tick in
            let y = yPosition(for: tick.minutes, in: metrics.plotFrame)

            Path { path in
                path.move(to: CGPoint(x: metrics.rightRailMinX, y: y))
                path.addLine(to: CGPoint(x: metrics.rightRailMaxX, y: y))
            }
            .stroke(gridColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }

    @ViewBuilder
    private func compactSelectedDayCallout(in metrics: CompactLayoutMetrics) -> some View {
        if let compactSelectedDay,
           let selectedPoint = chart.points.first(where: { $0.dateKey == compactSelectedDay.dateKey }) {
            let rawCenterX = xPosition(for: selectedPoint, in: metrics.dayColumnFrame)
            let calloutWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 82 : 74
            let calloutCenterX = min(
                max(rawCenterX, metrics.calloutFrame.minX + calloutWidth / 2),
                metrics.calloutFrame.maxX - calloutWidth / 2
            )

            VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 1 : 0) {
                Text(compactSelectedDay.relativeLabel)
                    .font(.system(size: compactCalloutLabelPointSize, weight: .medium))
                    .foregroundStyle(compactCalloutPrimaryColor)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(compactSelectedDay.timeMain)
                        .font(.system(size: compactCalloutTimePointSize, weight: .bold))
                        .foregroundStyle(compactCalloutPrimaryColor)
                        .monospacedDigit()

                    if let suffix = compactSelectedDay.timeSuffix {
                        Text(suffix)
                            .font(.system(size: compactCalloutSuffixPointSize, weight: .regular))
                            .foregroundStyle(compactCalloutPrimaryColor)
                            .monospacedDigit()
                    }
                }
            }
            .frame(width: calloutWidth)
            .position(x: calloutCenterX, y: metrics.calloutFrame.midY + compactSelectedCalloutYOffset)
        }
    }

    @ViewBuilder
    private func compactXAxis(in metrics: CompactLayoutMetrics) -> some View {
        ForEach(chart.points) { point in
            let x = xPosition(for: point, in: metrics.dayColumnFrame)

            Text(weekdayInitial(for: point.date))
                .font(.system(size: compactAxisPointSize, weight: .medium))
                .foregroundStyle(
                    point.dateKey == chart.selectedDateKey
                        ? compactPrimaryTextColor
                        : compactSecondaryTextColor
                )
                .position(x: x, y: metrics.weekdayRowY)
        }
    }

    private func plotFrame(in size: CGSize) -> CGRect {
        let insets = layoutStyle.plotInsets
        return CGRect(
            x: insets.leading,
            y: insets.top,
            width: max(1, size.width - insets.leading - insets.trailing),
            height: max(1, size.height - insets.top - insets.bottom)
        )
    }

    private func xPosition(for point: FajrWindowPoint, in frame: CGRect) -> CGFloat {
        xPosition(forOrdinal: point.dayOrdinal, width: frame.width) + frame.minX
    }

    private func xPosition(forOrdinal ordinal: Int, width: CGFloat) -> CGFloat {
        guard chart.points.count > 1 else { return width / 2 }
        let step = width / CGFloat(chart.points.count - 1)
        return CGFloat(ordinal) * step
    }

    private func yPosition(for minute: Int, in frame: CGRect) -> CGFloat {
        let domain = displayDomain
        let clamped = min(max(minute, domain.lowerBound), domain.upperBound)
        let ratio = CGFloat(clamped - domain.lowerBound) / CGFloat(max(1, domain.upperBound - domain.lowerBound))
        return frame.minY + (ratio * frame.height)
    }

    private func bandPath(in frame: CGRect) -> Path? {
        guard !chart.renderPoints.isEmpty else { return nil }
        if chart.renderPoints.count == 1, let point = chart.renderPoints.first {
            let x = xPosition(for: point, in: frame)
            let top = yPosition(for: point.fajrStartMinutes, in: frame)
            let bottom = yPosition(for: point.fajrEndOrBoundaryMinutes, in: frame)
            var path = Path()
            path.addRoundedRect(
                in: CGRect(x: x - 10, y: top, width: 20, height: max(10, bottom - top)),
                cornerSize: CGSize(width: 8, height: 8)
            )
            return path
        }

        var path = Path()
        guard let first = chart.renderPoints.first else { return nil }
        path.move(to: CGPoint(x: xPosition(for: first, in: frame), y: yPosition(for: first.fajrStartMinutes, in: frame)))

        for point in chart.renderPoints.dropFirst() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point.fajrStartMinutes, in: frame)))
        }

        for point in chart.renderPoints.reversed() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point.fajrEndOrBoundaryMinutes, in: frame)))
        }
        path.closeSubpath()
        return path
    }

    private func linePath(
        for keyPath: KeyPath<FajrWindowPoint, Int>,
        in frame: CGRect
    ) -> Path? {
        guard let first = chart.renderPoints.first else { return nil }
        if chart.renderPoints.count == 1 {
            let y = yPosition(for: first[keyPath: keyPath], in: frame)
            return Path { path in
                path.move(to: CGPoint(x: frame.midX - 12, y: y))
                path.addLine(to: CGPoint(x: frame.midX + 12, y: y))
            }
        }

        var path = Path()
        path.move(to: CGPoint(x: xPosition(for: first, in: frame), y: yPosition(for: first[keyPath: keyPath], in: frame)))
        for point in chart.renderPoints.dropFirst() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point[keyPath: keyPath], in: frame)))
        }
        return path
    }

    private func optionalLinePath(
        for keyPath: KeyPath<FajrWindowPoint, Int?>,
        in frame: CGRect
    ) -> Path? {
        let plotted = chart.renderPoints.compactMap { point -> (FajrWindowPoint, Int)? in
            guard let value = point[keyPath: keyPath] else { return nil }
            return (point, value)
        }
        guard let first = plotted.first else { return nil }

        var path = Path()
        path.move(to: CGPoint(x: xPosition(for: first.0, in: frame), y: yPosition(for: first.1, in: frame)))
        for entry in plotted.dropFirst() {
            path.addLine(to: CGPoint(x: xPosition(for: entry.0, in: frame), y: yPosition(for: entry.1, in: frame)))
        }
        return path
    }

    private func nearestPoint(to x: CGFloat, in frame: CGRect) -> FajrWindowPoint? {
        guard !chart.points.isEmpty else { return nil }
        guard chart.points.count > 1 else { return chart.points.first }

        let ratio = min(max((x - frame.minX) / max(frame.width, 1), 0), 1)
        let index = Int(round(ratio * CGFloat(chart.points.count - 1)))
        return chart.points[min(max(index, 0), chart.points.count - 1)]
    }

    private func weekdayInitial(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        switch calendar.component(.weekday, from: date) {
        case 2:
            return "M"
        case 3:
            return "T"
        case 4:
            return "W"
        case 5:
            return "T"
        case 6:
            return "F"
        case 7:
            return "S"
        default:
            return "S"
        }
    }

    private func splitTickLabel(_ label: String) -> (main: String, suffix: String?) {
        let tokens = label.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return (label, nil) }
        return (tokens.dropLast().joined(separator: " "), tokens.last)
    }

}
