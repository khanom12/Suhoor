import SwiftUI

struct FajrWindowChartView: View {
    enum LayoutStyle {
        case compact
        case detail

        var height: CGFloat {
            switch self {
            case .compact:
                return 108
            case .detail:
                return 292
            }
        }

        var plotInsets: EdgeInsets {
            switch self {
            case .compact:
                return EdgeInsets(top: 10, leading: 10, bottom: 8, trailing: 10)
            case .detail:
                return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            }
        }

        var showsYAxis: Bool {
            self == .detail
        }
    }

    let snapshot: FajrWindowSurfaceSnapshot
    let layoutStyle: LayoutStyle
    var onSelectDateKey: ((String) -> Void)? = nil

    var body: some View {
        if snapshot.points.isEmpty {
            placeholder
        } else {
            VStack(alignment: .leading, spacing: layoutStyle == .compact ? 8 : 12) {
                HStack(alignment: .top, spacing: layoutStyle.showsYAxis ? 12 : 0) {
                    if layoutStyle.showsYAxis {
                        yAxis
                            .frame(width: 52, height: layoutStyle.height)
                    }

                    plotArea
                        .frame(maxWidth: .infinity)
                }

                xAxis
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: layoutStyle.height)
            .overlay(
                Text("Upcoming mornings will appear here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            )
    }

    private var plotArea: some View {
        GeometryReader { geometry in
            let frame = plotFrame(in: geometry.size)
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.84),
                                DawnColor.lightGold900.opacity(0.30),
                                DawnColor.lightApricot900.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DawnColor.lightGold200.opacity(0.10),
                                        DawnColor.accent.opacity(0.04),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                grid(in: frame)
                boundaryBand(in: frame)
                boundaryLine(for: \.fajrStartMinutes, color: Color.white.opacity(0.34), lineWidth: 1.2, dash: [5, 4], in: frame)
                boundaryLine(for: \.fajrEndOrBoundaryMinutes, color: DawnColor.lightGold200.opacity(0.88), lineWidth: 2, dash: [], in: frame)
                primaryWakeLine(in: frame)

                if snapshot.activeOverlay != .myWake {
                    overlayLine(for: snapshot.activeOverlay, in: frame)
                }

                selectedMarker(in: frame)
                touchOverlay(in: frame)
            }
        }
        .frame(height: layoutStyle.height)
    }

    @ViewBuilder
    private func grid(in frame: CGRect) -> some View {
        Canvas { context, size in
            for tick in yTicks {
                let y = yPosition(for: tick, in: frame)
                var path = Path()
                path.move(to: CGPoint(x: frame.minX, y: y))
                path.addLine(to: CGPoint(x: frame.maxX, y: y))
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(layoutStyle == .compact ? 0.06 : 0.10)),
                    style: StrokeStyle(lineWidth: 1, dash: layoutStyle == .compact ? [3, 4] : [4, 5])
                )
            }
        }
    }

    @ViewBuilder
    private func boundaryBand(in frame: CGRect) -> some View {
        if let path = bandPath(in: frame) {
            path
                .fill(
                    LinearGradient(
                        colors: [
                            DawnColor.lightGold200.opacity(layoutStyle == .compact ? 0.24 : 0.28),
                            DawnColor.accent.opacity(layoutStyle == .compact ? 0.10 : 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    path.stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
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
            path.stroke(Color.white, style: StrokeStyle(lineWidth: layoutStyle == .compact ? 2.3 : 2.8, lineCap: .round, lineJoin: .round))
        }

        ForEach(snapshot.points) { point in
            let isSelected = point.dateKey == snapshot.selectedDateKey
            let x = xPosition(for: point, in: frame)
            let y = yPosition(for: point.primaryWakeMinutes, in: frame)
            Circle()
                .fill(Color.white)
                .frame(width: isSelected ? 10 : (layoutStyle == .compact ? 5 : 7), height: isSelected ? 10 : (layoutStyle == .compact ? 5 : 7))
                .overlay(
                    Circle()
                        .stroke(isSelected ? DawnColor.accent.opacity(0.9) : Color.clear, lineWidth: 2)
                )
                .position(x: x, y: y)
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
            dashedOverlayLine(for: \.saferWakeMinutes, color: Color.green.opacity(0.85), in: frame)
        case .compareFasting:
            dashedOverlayLine(for: \.fastingWakeMinutes, color: Color.pink.opacity(0.80), in: frame)
        case .compareTahajjud:
            dashedOverlayLine(for: \.tahajjudWakeMinutes, color: Color.blue.opacity(0.82), in: frame)
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
    private func selectedMarker(in frame: CGRect) -> some View {
        if layoutStyle == .detail,
           let selectedPoint = snapshot.points.first(where: { $0.dateKey == snapshot.selectedDateKey }) {
            let x = xPosition(for: selectedPoint, in: frame)
            Path { path in
                path.move(to: CGPoint(x: x, y: frame.minY))
                path.addLine(to: CGPoint(x: x, y: frame.maxY))
            }
            .stroke(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
        }
    }

    @ViewBuilder
    private func touchOverlay(in frame: CGRect) -> some View {
        if let onSelectDateKey {
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
        HStack(spacing: 0) {
            ForEach(xAxisPoints) { point in
                Text(xAxisLabel(for: point))
                    .font(.caption2.weight(point.dateKey == snapshot.selectedDateKey ? .semibold : .regular))
                    .foregroundStyle(point.dateKey == snapshot.selectedDateKey ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var yAxis: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yTicks, id: \.self) { tick in
                Text(timeLabel(for: tick))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity, alignment: .topTrailing)
            }
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
        guard let index = snapshot.points.firstIndex(where: { $0.id == point.id }) else { return frame.midX }
        if snapshot.points.count == 1 {
            return frame.midX
        }
        let step = frame.width / CGFloat(snapshot.points.count - 1)
        return frame.minX + (CGFloat(index) * step)
    }

    private func yPosition(for minute: Int, in frame: CGRect) -> CGFloat {
        let domain = snapshot.chartDomain
        let clamped = min(max(minute, domain.lowerBound), domain.upperBound)
        let ratio = CGFloat(clamped - domain.lowerBound) / CGFloat(max(1, domain.upperBound - domain.lowerBound))
        return frame.minY + (ratio * frame.height)
    }

    private func bandPath(in frame: CGRect) -> Path? {
        guard !snapshot.points.isEmpty else { return nil }
        if snapshot.points.count == 1, let point = snapshot.points.first {
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
        guard let first = snapshot.points.first else { return nil }
        path.move(to: CGPoint(x: xPosition(for: first, in: frame), y: yPosition(for: first.fajrStartMinutes, in: frame)))

        for point in snapshot.points.dropFirst() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point.fajrStartMinutes, in: frame)))
        }

        for point in snapshot.points.reversed() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point.fajrEndOrBoundaryMinutes, in: frame)))
        }
        path.closeSubpath()
        return path
    }

    private func linePath(
        for keyPath: KeyPath<FajrWindowPoint, Int>,
        in frame: CGRect
    ) -> Path? {
        guard let first = snapshot.points.first else { return nil }
        if snapshot.points.count == 1 {
            let y = yPosition(for: first[keyPath: keyPath], in: frame)
            return Path { path in
                path.move(to: CGPoint(x: frame.midX - 12, y: y))
                path.addLine(to: CGPoint(x: frame.midX + 12, y: y))
            }
        }

        var path = Path()
        path.move(to: CGPoint(x: xPosition(for: first, in: frame), y: yPosition(for: first[keyPath: keyPath], in: frame)))
        for point in snapshot.points.dropFirst() {
            path.addLine(to: CGPoint(x: xPosition(for: point, in: frame), y: yPosition(for: point[keyPath: keyPath], in: frame)))
        }
        return path
    }

    private func optionalLinePath(
        for keyPath: KeyPath<FajrWindowPoint, Int?>,
        in frame: CGRect
    ) -> Path? {
        let plotted = snapshot.points.compactMap { point -> (FajrWindowPoint, Int)? in
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
        snapshot.points.min { lhs, rhs in
            abs(xPosition(for: lhs, in: frame) - x) < abs(xPosition(for: rhs, in: frame) - x)
        }
    }

    private var xAxisPoints: [FajrWindowPoint] {
        switch snapshot.period {
        case .sevenDays:
            return snapshot.points
        case .thirtyDays:
            let stride = max(1, snapshot.points.count / 5)
            return snapshot.points.enumerated().compactMap { index, point in
                index == 0 || index == snapshot.points.count - 1 || index % stride == 0 ? point : nil
            }
        case .oneYear:
            var result: [FajrWindowPoint] = []
            var previousMonth: Int?
            let calendar = Calendar(identifier: .gregorian)
            for point in snapshot.points {
                let month = calendar.component(.month, from: point.date)
                if month != previousMonth {
                    result.append(point)
                    previousMonth = month
                }
            }
            return result
        }
    }

    private func xAxisLabel(for point: FajrWindowPoint) -> String {
        switch snapshot.period {
        case .sevenDays:
            return point.shortLabel
        case .thirtyDays:
            return point.mediumLabel
        case .oneYear:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            formatter.locale = .current
            formatter.timeZone = .current
            return formatter.string(from: point.date)
        }
    }

    private var yTicks: [Int] {
        let domain = snapshot.chartDomain
        let start = (domain.lowerBound / 60) * 60
        let end = ((domain.upperBound + 59) / 60) * 60
        var ticks: [Int] = []
        var current = start
        while current <= end {
            ticks.append(current)
            current += 60
        }
        return ticks.isEmpty ? [domain.lowerBound, domain.upperBound] : ticks
    }

    private func timeLabel(for minutes: Int) -> String {
        let hour = minutes / 60
        let suffix = hour >= 12 ? "PM" : "AM"
        let normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(normalizedHour) \(suffix)"
    }
}
