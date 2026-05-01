import SwiftUI
import UIKit

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

    private enum CompactSelectedDayPlacement {
        case leading
        case center
        case trailing
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let chart: FajrWindowChartSnapshot
    let layoutStyle: LayoutStyle
    var compactSelectedDay: FajrWindowCompactSelectedDaySnapshot? = nil
    var compactStaticBackdropDateKey: String? = nil
    var onSelectDateKey: ((String) -> Void)? = nil
    var onEndSelection: (() -> Void)? = nil
    var onMoveSelection: ((Int) -> Void)? = nil
    var accessibilityLabel: String? = nil
    var accessibilityValue: String? = nil
    var accessibilityHint: String? = nil

    var body: some View {
        accessibleChart(baseChart)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
            .fill(layoutStyle == .compact ? WakeGlassTheme.chipFill : Color.white.opacity(0.06))
            .frame(height: layoutStyle == .compact ? compactTotalHeight : layoutStyle.plotHeight)
            .overlay(
                Text("Upcoming mornings will appear here.")
                    .font(AppTypography.cardBody)
                    .foregroundStyle(layoutStyle == .compact ? WakeGlassTheme.secondaryText : WakeGlassTheme.secondaryText)
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
                compactFrameChrome(in: metrics)
                horizontalGrid(in: metrics.plotFrame)
                verticalGrid(in: metrics.dayColumnFrame)
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
                compactBoundaryLabels(in: metrics)
                compactSelectedDayGuide(in: metrics)
                markerLayer(in: metrics.plotFrame)
                compactYAxis(in: metrics)
                compactXAxis(in: metrics)
                compactSelectedDayCallout(in: metrics)
                touchOverlay(
                    in: CGRect(
                        x: metrics.dayColumnFrame.minX,
                        y: metrics.chartFrame.minY,
                        width: metrics.dayColumnFrame.width,
                        height: metrics.chartFrame.height
                    )
                )
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
        if layoutStyle == .detail {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.black.opacity(0.18),
                    DawnColor.lightGold900.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

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
        if layoutStyle == .detail {
            return Color.white.opacity(0.10)
        }
        return colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var boundaryStartColor: Color {
        if layoutStyle == .detail {
            return Color.white.opacity(0.54)
        }
        return colorScheme == .dark ? Color.white.opacity(0.54) : Color.black.opacity(0.42)
    }

    private var boundaryEndColor: Color {
        if layoutStyle == .detail {
            return DawnColor.lightGold100.opacity(0.92)
        }
        return colorScheme == .dark ? DawnColor.lightGold100.opacity(0.92) : Color.black.opacity(0.74)
    }

    private var compactBoundaryColor: Color {
        Color.white.opacity(0.10)
    }

    private var selectedAxisColor: Color {
        if layoutStyle == .detail {
            return Color.white.opacity(0.22)
        }
        return colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.16)
    }

    private var compactSelectedGuideColor: Color {
        .white
    }

    private var gridColor: Color {
        layoutStyle == .compact
            ? Color.white.opacity(0.05)
            : (layoutStyle == .detail ? Color.white.opacity(0.12) : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10)))
    }

    private var compactPrimaryTextColor: Color {
        .white
    }

    private var compactSecondaryTextColor: Color {
        Color.white.opacity(0.70)
    }

    private var compactTertiaryTextColor: Color {
        Color.white.opacity(0.70)
    }

    private var compactBandFill: Color {
        Color.white.opacity(0.05)
    }

    private var compactPlotMarkerColor: Color {
        .white
    }

    private var compactCalloutPrimaryColor: Color {
        .white
    }

    private var compactCalloutSecondaryColor: Color {
        .white
    }

    private var compactInactiveMarkerColor: Color {
        Color.white.opacity(0.50)
    }

    private var compactInactiveMarkerSize: CGFloat {
        9
    }

    private var compactEdgeInactiveMarkerVisibleWidth: CGFloat {
        compactInactiveMarkerSize / 2
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
                        ? Color.white.opacity(0.12)
                        : (layoutStyle == .detail ? Color.white.opacity(0.10) : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))),
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
                layoutStyle == .detail ? Color.white.opacity(0.92) : (colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.80)),
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
        ForEach(markerPoints.filter { $0.dateKey != chart.selectedDateKey }) { point in
            let x = xPosition(for: point, in: frame)
            let y = yPosition(for: point.primaryWakeMinutes, in: frame)

            if point.isSkipped {
                skippedMarker
                    .position(x: x, y: y)
            } else {
                if layoutStyle == .compact, isCompactEdgeInactiveMarker(point) {
                    compactEdgeInactiveMarker(for: point)
                        .position(x: compactEdgeInactiveMarkerCenterX(for: point, baseX: x), y: y)
                } else {
                    Circle()
                        .fill(layoutStyle == .compact ? compactInactiveMarkerColor : regularMarkerColor)
                        .frame(
                            width: layoutStyle == .compact ? compactInactiveMarkerSize : 7,
                            height: layoutStyle == .compact ? compactInactiveMarkerSize : 7
                        )
                        .position(x: x, y: y)
                }
            }
        }

        ForEach(markerPoints.filter { $0.dateKey == chart.selectedDateKey }) { point in
            let x = xPosition(for: point, in: frame)
            let y = yPosition(for: point.primaryWakeMinutes, in: frame)

            selectedMarker(point: point)
                .position(x: x, y: y)
        }
    }

    private var regularMarkerColor: Color {
        if layoutStyle == .detail {
            return Color.white.opacity(0.34)
        }
        return colorScheme == .dark ? Color.white.opacity(0.34) : Color.black.opacity(0.28)
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
                .foregroundStyle(Color.white)
                .padding(6)
                .background(
                    Circle()
                        .fill(DawnColor.lightGold200.opacity(0.28))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
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
                    .foregroundStyle(Color.white.opacity(0.42))
                    .padding(4)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
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
                .frame(width: metrics.yAxisLabelWidth, height: compactYAxisLabelHeight, alignment: .topTrailing)
                .offset(
                    x: metrics.yAxisLabelMinX,
                    y: yPosition(for: tick.minutes, in: metrics.plotFrame) + compactYAxisLabelTopInset
                )
        }
    }

    @ViewBuilder
    private func touchOverlay(in frame: CGRect) -> some View {
        if let onSelectDateKey, (layoutStyle == .detail || layoutStyle == .compact) {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard let point = nearestPoint(to: value.location.x, in: frame) else { return }
                            onSelectDateKey(point.dateKey)
                        }
                        .onEnded { _ in
                            onEndSelection?()
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
                        .foregroundStyle(label.dateKey == chart.selectedDateKey ? WakeGlassTheme.primaryText : WakeGlassTheme.secondaryText)
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
                    .foregroundStyle(WakeGlassTheme.secondaryText)
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
        compactLayoutProfile.resolvedChartHeight
    }

    private var compactLayoutProfile: CompactFajrcastChartLayoutProfile {
        CompactFajrcastChartLayoutProfile(dynamicTypeSize: dynamicTypeSize)
    }

    private var compactMarkerPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 13)
    }

    private var compactSkippedMarkerPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 10)
    }

    private var compactYAxisValuePointSize: CGFloat {
        compactLayoutProfile.scaled(base: 13)
    }

    private var compactYAxisLabelHeight: CGFloat {
        compactLayoutProfile.scaled(base: 16)
    }

    private var compactYAxisLabelTopInset: CGFloat {
        1
    }

    private var compactAxisPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 13)
    }

    private var compactBoundaryLabelPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 13)
    }

    private var compactBoundaryLabelLineHeight: CGFloat {
        compactLayoutProfile.xAxisLineHeight
    }

    private var compactCalloutLabelPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 13)
    }

    private var compactCalloutTimePointSize: CGFloat {
        compactLayoutProfile.scaled(base: 18)
    }

    private var compactCalloutSuffixPointSize: CGFloat {
        compactLayoutProfile.scaled(base: 11)
    }

    private var compactCalloutStackSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 0 : -1
    }

    private var compactSelectedGuideHalfHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8.5 : 7
    }

    private var compactSelectedCalloutYOffset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 0 : 0
    }

    private var compactSelectedCalloutWidth: CGFloat {
        compactLayoutProfile.calloutWidth
    }

    private var compactXAxisLabelFrameWidth: CGFloat {
        compactLayoutProfile.scaled(base: 16)
    }

    private var compactXAxisLabelCenterOffset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 10 : 8
    }

    private func compactLayoutMetrics(in size: CGSize) -> CompactLayoutMetrics {
        let layoutProfile = compactLayoutProfile
        let topAxisSpacing = layoutProfile.resolvedTopAxisSpacing
        let xAxisLineHeight = layoutProfile.xAxisLineHeight
        let xAxisToPlotSpacing = layoutProfile.resolvedXAxisToPlotSpacing
        let plotToCalloutSpacing = layoutProfile.resolvedPlotToCalloutSpacing
        let calloutHeight = layoutProfile.calloutBlockHeight
        let plotTop = topAxisSpacing + xAxisLineHeight + xAxisToPlotSpacing
        let plotHeight = layoutProfile.staticPlotScaleHeight
        let rightRailWidth = layoutProfile.minimumRailWidth
        let plotMinX = 1.0
        let dayColumnWidth = max(1, size.width - rightRailWidth - plotMinX)
        let plotWidth = max(1, dayColumnWidth - 1)
        let weekdayRowY = topAxisSpacing + (xAxisLineHeight / 2)
        let yAxisLabelWidth = max(32.0, rightRailWidth - 7.0)
        let rightRailMinX = size.width - rightRailWidth
        let yAxisLabelMinX = rightRailMinX + 4.0

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
        let calloutTop = CompactFajrcastGeometry.centeredCalloutTop(
            plotBottom: plotFrame.maxY,
            chartBottom: size.height,
            calloutHeight: calloutHeight,
            minimumGap: plotToCalloutSpacing
        )

        return CompactLayoutMetrics(
            calloutFrame: CGRect(x: 0, y: calloutTop, width: size.width, height: calloutHeight),
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
        let backdropDateKey = compactStaticBackdropDateKey ?? chart.selectedDateKey
        if let backdropPoint = chart.points.first(where: { $0.dateKey == backdropDateKey }) {
            let placement = compactSelectedDayPlacement(for: backdropPoint)
            let backdropX = xPosition(for: backdropPoint, in: metrics.dayColumnFrame)

            if placement != .leading {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .frame(
                        width: max(0, backdropX),
                        height: metrics.plotFrame.height
                    )
                    .position(
                        x: max(0, backdropX) / 2,
                        y: metrics.plotFrame.midY
                    )
            }
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
    private func compactBoundaryLabels(in metrics: CompactLayoutMetrics) -> some View {
        if let beginGeometry = compactBoundaryLabelGeometry(
            title: "Fajr begins",
            keyPath: \.fajrStartMinutes,
            placement: compactFajrBeginBoundaryLabelPlacement(in: metrics),
            in: metrics
        ) {
            Text("Fajr begins")
                .font(.system(size: compactBoundaryLabelPointSize, weight: .medium))
                .foregroundStyle(compactSecondaryTextColor)
                .lineLimit(1)
                .frame(width: beginGeometry.labelWidth, alignment: .leading)
                .rotationEffect(.radians(beginGeometry.angleRadians))
                .position(beginGeometry.center)
        }

        if let endGeometry = compactBoundaryLabelGeometry(
            title: "Fajr ends",
            keyPath: \.fajrEndOrBoundaryMinutes,
            placement: .below,
            in: metrics
        ) {
            Text("Fajr ends")
                .font(.system(size: compactBoundaryLabelPointSize, weight: .medium))
                .foregroundStyle(compactSecondaryTextColor)
                .lineLimit(1)
                .frame(width: endGeometry.labelWidth, alignment: .leading)
                .rotationEffect(.radians(endGeometry.angleRadians))
                .position(endGeometry.center)
        }
    }

    private func compactFajrBeginBoundaryLabelPlacement(
        in metrics: CompactLayoutMetrics
    ) -> CompactFajrcastGeometry.BoundaryLabelPlacement {
        if compactWakePatternPlacesMarkersBeforeFajr {
            return .below
        }

        guard let aboveGeometry = compactBoundaryLabelGeometry(
            title: "Fajr begins",
            keyPath: \.fajrStartMinutes,
            placement: .above,
            in: metrics
        ) else {
            return .above
        }

        return compactBoundaryLabelCollidesWithLeftMarkerLane(aboveGeometry, in: metrics)
            ? .below
            : .above
    }

    private var compactWakePatternPlacesMarkersBeforeFajr: Bool {
        let restingDateKey = compactStaticBackdropDateKey ?? chart.selectedDateKey

        if let restingDateKey,
           let restingPoint = chart.points.first(where: { $0.dateKey == restingDateKey }),
           restingPoint.isSkipped == false {
            return restingPoint.primaryWakeMinutes < restingPoint.fajrStartMinutes
        }

        let activeVisiblePoints = chart.renderPoints.filter { $0.isSkipped == false }
        guard activeVisiblePoints.isEmpty == false else { return false }

        let preFajrCount = activeVisiblePoints.filter {
            $0.primaryWakeMinutes < $0.fajrStartMinutes
        }.count

        return preFajrCount > activeVisiblePoints.count / 2
    }

    private func compactBoundaryLabelCollidesWithLeftMarkerLane(
        _ geometry: CompactBoundaryLabelGeometry,
        in metrics: CompactLayoutMetrics
    ) -> Bool {
        let labelBounds = CompactFajrcastGeometry.rotatedBoundingRect(
            center: geometry.center,
            labelWidth: geometry.labelWidth,
            labelHeight: compactBoundaryLabelLineHeight,
            angleRadians: geometry.angleRadians
        ).insetBy(dx: -6, dy: -6)
        let checkedColumnLimit = dynamicTypeSize.isAccessibilitySize || dynamicTypeSize == .xxxLarge ? 2 : 1

        return markerPoints.contains { point in
            guard point.dayOrdinal <= checkedColumnLimit else { return false }
            let markerCenter = CGPoint(
                x: xPosition(for: point, in: metrics.plotFrame),
                y: yPosition(for: point.primaryWakeMinutes, in: metrics.plotFrame)
            )
            let markerRadius = compactMarkerCollisionRadius(for: point)
            let markerBounds = CGRect(
                x: markerCenter.x - markerRadius,
                y: markerCenter.y - markerRadius,
                width: markerRadius * 2,
                height: markerRadius * 2
            )

            return labelBounds.intersects(markerBounds)
        }
    }

    private func compactMarkerCollisionRadius(for point: FajrWindowPoint) -> CGFloat {
        if point.dateKey == chart.selectedDateKey {
            return max(8, compactMarkerPointSize * 0.75)
        }

        if point.isSkipped {
            return max(7, compactSkippedMarkerPointSize * 0.75)
        }

        return max(6, compactInactiveMarkerSize * 0.75)
    }

    private func compactBoundaryLabelGeometry(
        title: String,
        keyPath: KeyPath<FajrWindowPoint, Int>,
        placement: CompactFajrcastGeometry.BoundaryLabelPlacement,
        in metrics: CompactLayoutMetrics
    ) -> CompactBoundaryLabelGeometry? {
        let preferredEdgeClearance: CGFloat = 6
        let minimumEdgeClearance: CGFloat = 4
        let availableWidth = max(48, metrics.plotFrame.width - (preferredEdgeClearance * 2))
        let labelWidth = compactBoundaryLabelWidth(title, maxWidth: availableWidth)
        let labelHeight = compactBoundaryLabelLineHeight
        let dayStep = metrics.dayColumnFrame.width / CGFloat(max(chart.points.count - 1, 1))
        let sampleRadius = min(max(12, 0.35 * dayStep), 28)
        let initialCenterX = metrics.plotFrame.minX + preferredEdgeClearance + labelWidth / 2
        let initialX0 = min(max(initialCenterX - sampleRadius, metrics.plotFrame.minX), metrics.plotFrame.maxX)
        let initialX1 = min(max(initialCenterX + sampleRadius, metrics.plotFrame.minX), metrics.plotFrame.maxX)

        guard
            let initialY0 = compactBoundaryY(at: initialX0, keyPath: keyPath, in: metrics.plotFrame),
            let initialY1 = compactBoundaryY(at: initialX1, keyPath: keyPath, in: metrics.plotFrame)
        else {
            return nil
        }

        let initialAngle = CompactFajrcastGeometry.tangentAngleRadians(
            x0: initialX0,
            y0: initialY0,
            x1: initialX1,
            y1: initialY1
        )
        let initialHalfExtents = CompactFajrcastGeometry.rotatedHalfExtents(
            labelWidth: labelWidth,
            labelHeight: labelHeight,
            angleRadians: initialAngle
        )
        let minCenterX = metrics.plotFrame.minX + preferredEdgeClearance + initialHalfExtents.width
        let maxCenterX = metrics.plotFrame.maxX - preferredEdgeClearance - initialHalfExtents.width
        let centerX = CompactFajrcastGeometry.clamped(
            initialCenterX,
            lowerBound: minCenterX,
            upperBound: maxCenterX
        )
        let x0 = min(max(centerX - sampleRadius, metrics.plotFrame.minX), metrics.plotFrame.maxX)
        let x1 = min(max(centerX + sampleRadius, metrics.plotFrame.minX), metrics.plotFrame.maxX)

        guard
            let boundaryY = compactBoundaryY(at: centerX, keyPath: keyPath, in: metrics.plotFrame),
            let y0 = compactBoundaryY(at: x0, keyPath: keyPath, in: metrics.plotFrame),
            let y1 = compactBoundaryY(at: x1, keyPath: keyPath, in: metrics.plotFrame)
        else {
            return nil
        }

        let angle = CompactFajrcastGeometry.tangentAngleRadians(x0: x0, y0: y0, x1: x1, y1: y1)
        let normal = CompactFajrcastGeometry.outwardNormal(for: angle, placement: placement)
        let halfExtents = CompactFajrcastGeometry.rotatedHalfExtents(
            labelWidth: labelWidth,
            labelHeight: labelHeight,
            angleRadians: angle
        )
        let halfExtentAlongNormal = CompactFajrcastGeometry.rotatedHalfExtentAlongNormal(
            labelWidth: labelWidth,
            labelHeight: labelHeight,
            angleRadians: angle,
            normal: normal
        )
        let minimumBoundaryClearance = max(5, 0.30 * labelHeight)
        let preferredBoundaryClearance = max(6, 0.35 * labelHeight)
        let preferredNormalOffset = preferredBoundaryClearance + halfExtentAlongNormal
        let minimumNormalOffset = minimumBoundaryClearance + halfExtentAlongNormal
        let preferredCenter = CGPoint(
            x: centerX + (normal.x * preferredNormalOffset),
            y: boundaryY + (normal.y * preferredNormalOffset)
        )
        let minimumCenter = CGPoint(
            x: centerX + (normal.x * minimumNormalOffset),
            y: boundaryY + (normal.y * minimumNormalOffset)
        )
        let preferredEdgeBounds = CompactFajrcastGeometry.insetBounds(
            for: metrics.plotFrame,
            halfExtents: halfExtents,
            clearance: preferredEdgeClearance
        )
        let minimumEdgeBounds = CompactFajrcastGeometry.insetBounds(
            for: metrics.plotFrame,
            halfExtents: halfExtents,
            clearance: minimumEdgeClearance
        )
        let center: CGPoint
        if CompactFajrcastGeometry.point(preferredCenter, fitsIn: preferredEdgeBounds) {
            center = preferredCenter
        } else if CompactFajrcastGeometry.point(preferredCenter, fitsIn: minimumEdgeBounds) {
            center = preferredCenter
        } else if CompactFajrcastGeometry.point(minimumCenter, fitsIn: minimumEdgeBounds) {
            center = minimumCenter
        } else {
            center = CompactFajrcastGeometry.clamped(preferredCenter, inside: minimumEdgeBounds)
        }

        return CompactBoundaryLabelGeometry(
            center: center,
            labelWidth: labelWidth,
            angleRadians: angle
        )
    }

    private func compactBoundaryY(
        at x: CGFloat,
        keyPath: KeyPath<FajrWindowPoint, Int>,
        in frame: CGRect
    ) -> CGFloat? {
        let samples = chart.renderPoints
            .map { point in
                (
                    x: xPosition(for: point, in: frame),
                    y: yPosition(for: point[keyPath: keyPath], in: frame)
                )
            }
            .sorted { $0.x < $1.x }

        guard let first = samples.first else { return nil }
        guard samples.count > 1 else { return first.y }
        if x <= first.x { return first.y }
        if let last = samples.last, x >= last.x { return last.y }

        for pair in zip(samples, samples.dropFirst()) {
            let left = pair.0
            let right = pair.1
            guard x >= left.x, x <= right.x else { continue }
            let ratio = (x - left.x) / max(1, right.x - left.x)
            return left.y + ((right.y - left.y) * ratio)
        }

        return samples.last?.y
    }

    private func compactBoundaryLabelWidth(_ title: String, maxWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: compactBoundaryLabelPointSize, weight: .medium)
        let measuredWidth = (title as NSString).size(withAttributes: [.font: font]).width
        return ceil(min(maxWidth, measuredWidth + 2))
    }

    @ViewBuilder
    private func compactSelectedDayCallout(in metrics: CompactLayoutMetrics) -> some View {
        if let compactSelectedDay,
           let selectedPoint = chart.points.first(where: { $0.dateKey == compactSelectedDay.dateKey }) {
            let placement = compactSelectedDayPlacement(for: selectedPoint)
            let rawCenterX = xPosition(for: selectedPoint, in: metrics.dayColumnFrame)
            let calloutWidth = compactSelectedCalloutWidth
            let calloutLayout: (centerX: CGFloat, textAlignment: HorizontalAlignment, contentAlignment: Alignment) = {
                switch placement {
                case .leading:
                    return (
                        metrics.plotFrame.minX + (calloutWidth / 2),
                        .leading,
                        .leading
                    )
                case .trailing:
                    return (
                        metrics.dayColumnFrame.maxX - (calloutWidth / 2),
                        .trailing,
                        .trailing
                    )
                case .center:
                    return (
                        min(
                            max(rawCenterX, metrics.calloutFrame.minX + calloutWidth / 2),
                            metrics.calloutFrame.maxX - calloutWidth / 2
                        ),
                        .center,
                        .center
                    )
                }
            }()

            VStack(alignment: calloutLayout.textAlignment, spacing: compactCalloutStackSpacing) {
                Text(compactSelectedDay.relativeLabel)
                    .font(.system(size: compactCalloutLabelPointSize, weight: .medium))
                    .foregroundStyle(compactCalloutPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: calloutLayout.contentAlignment)

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
                .frame(maxWidth: .infinity, alignment: calloutLayout.contentAlignment)
            }
            .frame(width: calloutWidth)
            .position(x: calloutLayout.centerX, y: metrics.calloutFrame.midY + compactSelectedCalloutYOffset)
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
                .frame(width: compactXAxisLabelFrameWidth, alignment: .leading)
                .position(x: x + compactXAxisLabelCenterOffset, y: metrics.weekdayRowY)
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

    private func compactSelectedDayPlacement(for point: FajrWindowPoint) -> CompactSelectedDayPlacement {
        if point.dayOrdinal == 0 {
            return .leading
        }

        if point.dayOrdinal == chart.points.count - 1 {
            return .trailing
        }

        return .center
    }

    private func isCompactEdgeInactiveMarker(_ point: FajrWindowPoint) -> Bool {
        point.dayOrdinal == 0 || point.dayOrdinal == chart.points.count - 1
    }

    @ViewBuilder
    private func compactEdgeInactiveMarker(for point: FajrWindowPoint) -> some View {
        Circle()
            .fill(compactInactiveMarkerColor)
            .frame(width: compactInactiveMarkerSize, height: compactInactiveMarkerSize)
            .frame(
                width: compactEdgeInactiveMarkerVisibleWidth,
                height: compactInactiveMarkerSize,
                alignment: point.dayOrdinal == 0 ? .trailing : .leading
            )
            .clipped()
    }

    private func compactEdgeInactiveMarkerCenterX(for point: FajrWindowPoint, baseX: CGFloat) -> CGFloat {
        let offset = compactEdgeInactiveMarkerVisibleWidth / 2
        return point.dayOrdinal == 0 ? baseX + offset : baseX - offset
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

private struct CompactFajrcastChartLayoutProfile {
    let textScale: CGFloat
    let minimumChartHeight: CGFloat
    let minimumRailWidth: CGFloat
    let staticPlotScaleHeight: CGFloat
    let topAxisSpacing: CGFloat
    let xAxisToPlotSpacing: CGFloat
    let plotToCalloutSpacing: CGFloat
    let bottomCalloutSpacing: CGFloat

    init(dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall:
            self.init(textScale: 0.88, minimumChartHeight: 184, minimumRailWidth: 40, staticPlotScaleHeight: 128, topAxisSpacing: 6, xAxisToPlotSpacing: 3, plotToCalloutSpacing: 4, bottomCalloutSpacing: 4)
        case .small:
            self.init(textScale: 0.94, minimumChartHeight: 184, minimumRailWidth: 42, staticPlotScaleHeight: 128, topAxisSpacing: 6, xAxisToPlotSpacing: 3, plotToCalloutSpacing: 4, bottomCalloutSpacing: 4)
        case .medium:
            self.init(textScale: 0.98, minimumChartHeight: 186, minimumRailWidth: 44, staticPlotScaleHeight: 128, topAxisSpacing: 6, xAxisToPlotSpacing: 3, plotToCalloutSpacing: 4, bottomCalloutSpacing: 4)
        case .large:
            self.init(textScale: 1.0, minimumChartHeight: 188, minimumRailWidth: 46, staticPlotScaleHeight: 128, topAxisSpacing: 8, xAxisToPlotSpacing: 4, plotToCalloutSpacing: 5, bottomCalloutSpacing: 5)
        case .xLarge:
            self.init(textScale: 1.08, minimumChartHeight: 194, minimumRailWidth: 52, staticPlotScaleHeight: 128, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .xxLarge:
            self.init(textScale: 1.17, minimumChartHeight: 202, minimumRailWidth: 58, staticPlotScaleHeight: 128, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .xxxLarge:
            self.init(textScale: 1.28, minimumChartHeight: 210, minimumRailWidth: 64, staticPlotScaleHeight: 128, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .accessibility1:
            self.init(textScale: 1.38, minimumChartHeight: 224, minimumRailWidth: 72, staticPlotScaleHeight: 136, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .accessibility2:
            self.init(textScale: 1.48, minimumChartHeight: 240, minimumRailWidth: 80, staticPlotScaleHeight: 144, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .accessibility3:
            self.init(textScale: 1.60, minimumChartHeight: 258, minimumRailWidth: 88, staticPlotScaleHeight: 152, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .accessibility4:
            self.init(textScale: 1.72, minimumChartHeight: 276, minimumRailWidth: 96, staticPlotScaleHeight: 160, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        case .accessibility5:
            self.init(textScale: 1.84, minimumChartHeight: 294, minimumRailWidth: 104, staticPlotScaleHeight: 168, topAxisSpacing: 9, xAxisToPlotSpacing: 5, plotToCalloutSpacing: 6, bottomCalloutSpacing: 6)
        @unknown default:
            self.init(textScale: 1.0, minimumChartHeight: 188, minimumRailWidth: 46, staticPlotScaleHeight: 128, topAxisSpacing: 8, xAxisToPlotSpacing: 4, plotToCalloutSpacing: 5, bottomCalloutSpacing: 5)
        }
    }

    private init(
        textScale: CGFloat,
        minimumChartHeight: CGFloat,
        minimumRailWidth: CGFloat,
        staticPlotScaleHeight: CGFloat,
        topAxisSpacing: CGFloat,
        xAxisToPlotSpacing: CGFloat,
        plotToCalloutSpacing: CGFloat,
        bottomCalloutSpacing: CGFloat
    ) {
        self.textScale = textScale
        self.minimumChartHeight = minimumChartHeight
        self.minimumRailWidth = minimumRailWidth
        self.staticPlotScaleHeight = staticPlotScaleHeight
        self.topAxisSpacing = topAxisSpacing
        self.xAxisToPlotSpacing = xAxisToPlotSpacing
        self.plotToCalloutSpacing = plotToCalloutSpacing
        self.bottomCalloutSpacing = bottomCalloutSpacing
    }

    var calloutWidth: CGFloat {
        max(86, 86 + ((textScale - 1) * 72))
    }

    var xAxisLineHeight: CGFloat {
        max(16, scaled(base: 13) * 1.22)
    }

    var resolvedTopAxisSpacing: CGFloat {
        textScale >= 1.38 ? max(topAxisSpacing, xAxisLineHeight * 0.45) : topAxisSpacing
    }

    var resolvedXAxisToPlotSpacing: CGFloat {
        textScale >= 1.38 ? max(xAxisToPlotSpacing, xAxisLineHeight * 0.25) : xAxisToPlotSpacing
    }

    var resolvedPlotToCalloutSpacing: CGFloat {
        textScale >= 1.38 ? max(plotToCalloutSpacing, compactCalloutTimeLineHeight * 0.28) : plotToCalloutSpacing
    }

    var resolvedBottomCalloutSpacing: CGFloat {
        textScale >= 1.38 ? max(bottomCalloutSpacing, compactCalloutTimeLineHeight * 0.28) : bottomCalloutSpacing
    }

    var resolvedChartHeight: CGFloat {
        max(
            minimumChartHeight,
            ceil(
                resolvedTopAxisSpacing
                + xAxisLineHeight
                + resolvedXAxisToPlotSpacing
                + staticPlotScaleHeight
                + resolvedPlotToCalloutSpacing
                + calloutBlockHeight
                + resolvedBottomCalloutSpacing
            )
        )
    }

    var calloutBlockHeight: CGFloat {
        ceil(compactCalloutLabelLineHeight + compactCalloutTimeLineHeight + compactCalloutStackSpacing)
    }

    private var compactCalloutLabelLineHeight: CGFloat {
        scaled(base: 13) * 1.22
    }

    private var compactCalloutTimeLineHeight: CGFloat {
        scaled(base: 18) * 1.18
    }

    private var compactCalloutStackSpacing: CGFloat {
        textScale >= 1.38 ? 0 : -1
    }

    func scaled(base: CGFloat) -> CGFloat {
        max(base * 0.88, (base * textScale).rounded(.toNearestOrAwayFromZero))
    }
}

struct CompactFajrcastGeometry {
    enum BoundaryLabelPlacement {
        case above
        case below
    }

    static func centeredCalloutTop(
        plotBottom: CGFloat,
        chartBottom: CGFloat,
        calloutHeight: CGFloat,
        minimumGap: CGFloat
    ) -> CGFloat {
        let pocketHeight = chartBottom - plotBottom
        let centeredGap = (pocketHeight - calloutHeight) / 2
        return plotBottom + max(minimumGap, centeredGap)
    }

    static func tangentAngleRadians(
        x0: CGFloat,
        y0: CGFloat,
        x1: CGFloat,
        y1: CGFloat
    ) -> CGFloat {
        atan2(y1 - y0, x1 - x0)
    }

    static func outwardNormal(
        for angleRadians: CGFloat,
        placement: BoundaryLabelPlacement
    ) -> CGPoint {
        let dx = cos(angleRadians)
        let dy = sin(angleRadians)
        var normal = CGPoint(x: -dy, y: dx)

        switch placement {
        case .above where normal.y > 0:
            normal.x *= -1
            normal.y *= -1
        case .below where normal.y < 0:
            normal.x *= -1
            normal.y *= -1
        default:
            break
        }

        return normal
    }

    static func rotatedHalfExtents(
        labelWidth: CGFloat,
        labelHeight: CGFloat,
        angleRadians: CGFloat
    ) -> CGSize {
        let cosine = abs(cos(angleRadians))
        let sine = abs(sin(angleRadians))

        return CGSize(
            width: ((labelWidth * cosine) + (labelHeight * sine)) / 2,
            height: ((labelWidth * sine) + (labelHeight * cosine)) / 2
        )
    }

    static func rotatedBoundingRect(
        center: CGPoint,
        labelWidth: CGFloat,
        labelHeight: CGFloat,
        angleRadians: CGFloat
    ) -> CGRect {
        let halfExtents = rotatedHalfExtents(
            labelWidth: labelWidth,
            labelHeight: labelHeight,
            angleRadians: angleRadians
        )

        return CGRect(
            x: center.x - halfExtents.width,
            y: center.y - halfExtents.height,
            width: halfExtents.width * 2,
            height: halfExtents.height * 2
        )
    }

    static func rotatedHalfExtentAlongNormal(
        labelWidth: CGFloat,
        labelHeight: CGFloat,
        angleRadians: CGFloat,
        normal: CGPoint
    ) -> CGFloat {
        let tangent = CGPoint(x: cos(angleRadians), y: sin(angleRadians))
        let perpendicular = CGPoint(x: -sin(angleRadians), y: cos(angleRadians))
        let halfWidthProjection = abs((tangent.x * normal.x) + (tangent.y * normal.y)) * labelWidth / 2
        let halfHeightProjection = abs((perpendicular.x * normal.x) + (perpendicular.y * normal.y)) * labelHeight / 2

        return halfWidthProjection + halfHeightProjection
    }

    static func point(_ point: CGPoint, fitsIn rect: CGRect) -> Bool {
        point.x >= rect.minX
            && point.x <= rect.maxX
            && point.y >= rect.minY
            && point.y <= rect.maxY
    }

    static func insetBounds(
        for rect: CGRect,
        halfExtents: CGSize,
        clearance: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.minX + clearance + halfExtents.width,
            y: rect.minY + clearance + halfExtents.height,
            width: max(0, rect.width - (clearance * 2) - (halfExtents.width * 2)),
            height: max(0, rect.height - (clearance * 2) - (halfExtents.height * 2))
        )
    }

    static func clamped(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        let resolvedUpperBound = max(lowerBound, upperBound)
        return min(max(value, lowerBound), resolvedUpperBound)
    }

    static func clamped(_ point: CGPoint, inside rect: CGRect) -> CGPoint {
        CGPoint(
            x: clamped(point.x, lowerBound: rect.minX, upperBound: rect.maxX),
            y: clamped(point.y, lowerBound: rect.minY, upperBound: rect.maxY)
        )
    }
}

private struct CompactBoundaryLabelGeometry {
    let center: CGPoint
    let labelWidth: CGFloat
    let angleRadians: CGFloat
}
