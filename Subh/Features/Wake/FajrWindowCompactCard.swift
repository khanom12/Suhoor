import SwiftUI
import UIKit

struct WeeklyFajrcastCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var suppressNextOpen = false

    let snapshot: FajrWindowCompactSnapshot
    var onSelectDateKey: ((String) -> Void)? = nil
    var onEndSelection: (() -> Void)? = nil
    var onMoveSelection: ((Int) -> Void)? = nil
    let onOpen: () -> Void

    var body: some View {
        Button(action: openIfChartIsIdle) {
            AppGlassSurface(
                variant: .grouped,
                tint: .black,
                tintOpacityMultiplier: 4.5,
                contentPadding: 0
            ) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, headerVerticalPadding)
                        .padding(.bottom, headerVerticalPadding)

                    dividerLine
                        .padding(.horizontal, horizontalInset)

                    FajrWindowChartView(
                        chart: snapshot.chart,
                        layoutStyle: .compact,
                        compactSelectedDay: snapshot.selectedDay,
                        compactStaticBackdropDateKey: snapshot.anchorDateKey,
                        onSelectDateKey: selectDateFromChart,
                        onEndSelection: endSelectionFromChart,
                        onMoveSelection: moveSelectionFromChart,
                        accessibilityLabel: "Weekly Fajrcast chart",
                        accessibilityValue: accessibilitySummary,
                        accessibilityHint: "Adjust to focus another visible morning."
                    )
                    .frame(height: chartHeight)
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, chartVerticalPadding)

                    dividerLine
                        .padding(.horizontal, horizontalInset)

                    footer
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, footerVerticalPadding)
                        .padding(.bottom, footerVerticalPadding)
                }
                .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly Fajrcast")
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint("Double-tap for details.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                moveSelectionFromChart(1)
            case .decrement:
                moveSelectionFromChart(-1)
            @unknown default:
                break
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("WEEKLY FAJRCAST")
                .font(.system(size: titlePointSize, weight: .regular))
                .foregroundStyle(titleColor)
                .padding(.top, headerTitleTopInset)

            Spacer(minLength: 0)

            Text(monthTagText)
                .font(.system(size: monthTagPointSize, weight: .regular))
                .foregroundStyle(monthTagColor)
                .lineLimit(1)
                .frame(width: monthTagWidth, height: monthTagHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(WakeGlassTheme.divider)
                )
        }
        .frame(height: monthTagHeight, alignment: .top)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.summary.primaryText)
                .font(.system(size: footerPointSize, weight: .medium))
                .foregroundStyle(footerColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let secondaryText = snapshot.summary.secondaryText, !secondaryText.isEmpty {
                Text(secondaryText)
                    .font(.system(size: footerSecondaryPointSize, weight: .regular))
                    .foregroundStyle(footerColor.opacity(0.76))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(WakeGlassTheme.divider)
            .frame(height: 1)
    }

    private var accessibilitySummary: String {
        [
            snapshot.summary.primaryText,
            snapshot.summary.secondaryText,
            snapshot.compactInsight == snapshot.summary.primaryText || snapshot.compactInsight == snapshot.summary.secondaryText
                ? nil
                : snapshot.compactInsight,
            snapshot.selectedDay.accessibilityValue,
            focusedWeekdayAccessibilityValue
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: " ")
    }

    private var focusedWeekdayAccessibilityValue: String? {
        if let selectedPoint = snapshot.points.first(where: { $0.dateKey == snapshot.selectedDay.dateKey }) {
            return "Focused day \(selectedPoint.longLabel)."
        }
        return nil
    }

    private var layoutProfile: WeeklyFajrcastCardLayoutProfile {
        WeeklyFajrcastCardLayoutProfile(dynamicTypeSize: dynamicTypeSize)
    }

    private var minimumHeight: CGFloat {
        layoutProfile.minimumCardHeight
    }

    private var horizontalInset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 18 : 21
    }

    private var headerVerticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var chartVerticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 7
    }

    private var chartHeight: CGFloat {
        layoutProfile.minimumChartHeight
    }

    private var footerVerticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var headerTitleTopInset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 6 : 5
    }

    private var monthTagWidth: CGFloat {
        layoutProfile.monthTagWidth
    }

    private var monthTagHeight: CGFloat {
        layoutProfile.monthTagHeight
    }

    private var titlePointSize: CGFloat {
        layoutProfile.scaled(base: 12)
    }

    private var monthTagPointSize: CGFloat {
        layoutProfile.scaled(base: 12)
    }

    private var footerPointSize: CGFloat {
        layoutProfile.scaled(base: 13)
    }

    private var footerSecondaryPointSize: CGFloat {
        layoutProfile.scaled(base: 13)
    }

    private var titleColor: Color {
        WakeGlassTheme.tertiaryText
    }

    private var monthTagColor: Color {
        WakeGlassTheme.primaryText
    }

    private var footerColor: Color {
        WakeGlassTheme.primaryText
    }

    private var monthTagText: String {
        let dates = snapshot.points.map(\.date).sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else {
            return "This week"
        }

        let gregorian = gregorianWeekRange(start: firstDate, end: lastDate)
        guard let preferredHijri = hijriWeekRange(start: firstDate, end: lastDate, style: .preferred) else {
            return gregorian
        }

        let preferred = "\(gregorian) | \(preferredHijri)"
        if weekTagFitsComfortably(preferred) {
            return preferred
        }

        guard let compactHijri = hijriWeekRange(start: firstDate, end: lastDate, style: .compact) else {
            return preferred
        }

        return "\(gregorian) | \(compactHijri)"
    }

    private func openIfChartIsIdle() {
        if suppressNextOpen {
            suppressNextOpen = false
            return
        }

        onOpen()
    }

    private func selectDateFromChart(_ dateKey: String) {
        suppressOpenBriefly()
        onSelectDateKey?(dateKey)
    }

    private func endSelectionFromChart() {
        suppressOpenBriefly()
        onEndSelection?()
    }

    private func moveSelectionFromChart(_ offset: Int) {
        suppressOpenBriefly()
        onMoveSelection?(offset)
    }

    private func suppressOpenBriefly() {
        suppressNextOpen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            suppressNextOpen = false
        }
    }

    private func gregorianWeekRange(start: Date, end: Date) -> String {
        let calendar = gregorianCalendar
        let startComponents = calendar.dateComponents([.month, .day], from: start)
        let endComponents = calendar.dateComponents([.month, .day], from: end)

        guard
            let startMonth = startComponents.month,
            let startDay = startComponents.day,
            let endMonth = endComponents.month,
            let endDay = endComponents.day
        else {
            return "This week"
        }

        let startToken = gregorianMonthToken(for: startMonth)
        let endToken = gregorianMonthToken(for: endMonth)

        if startMonth == endMonth {
            if startDay == endDay {
                return "\(startToken) \(startDay)"
            }
            return "\(startToken) \(startDay)–\(endDay)"
        }

        return "\(startToken) \(startDay)–\(endToken) \(endDay)"
    }

    private func hijriWeekRange(
        start: Date,
        end: Date,
        style: WeekTagHijriTokenStyle
    ) -> String? {
        let timeZone = TimeZone.current
        guard
            let startComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: start, timeZone: timeZone),
            let endComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: end, timeZone: timeZone)
        else {
            return nil
        }

        let startToken = hijriToken(for: startComponents.month, style: style)
        let endToken = hijriToken(for: endComponents.month, style: style)

        if startComponents.hijriYear == endComponents.hijriYear,
           startComponents.month == endComponents.month {
            if startComponents.day == endComponents.day {
                return "\(startToken) \(startComponents.day)"
            }
            return "\(startToken) \(startComponents.day)–\(endComponents.day)"
        }

        return "\(startToken) \(startComponents.day)–\(endToken) \(endComponents.day)"
    }

    private func hijriToken(for month: HijriMonth, style: WeekTagHijriTokenStyle) -> String {
        switch style {
        case .preferred:
            return month.weeklyTagPreferredToken
        case .compact:
            return month.weeklyTagCompactToken
        }
    }

    private func weekTagFitsComfortably(_ text: String) -> Bool {
        let width = (text as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular)]
        ).width
        return width <= weekTagComfortWidth
    }

    private var weekTagComfortWidth: CGFloat {
        monthTagWidth - 20
    }

    private var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func gregorianMonthToken(for month: Int) -> String {
        switch month {
        case 1:
            return "Jan"
        case 2:
            return "Feb"
        case 3:
            return "Mar"
        case 4:
            return "Apr"
        case 5:
            return "May"
        case 6:
            return "Jun"
        case 7:
            return "Jul"
        case 8:
            return "Aug"
        case 9:
            return "Sep"
        case 10:
            return "Oct"
        case 11:
            return "Nov"
        case 12:
            return "Dec"
        default:
            return ""
        }
    }
}

private enum WeekTagHijriTokenStyle {
    case preferred
    case compact
}

private struct WeeklyFajrcastCardLayoutProfile {
    let textScale: CGFloat
    let minimumCardHeight: CGFloat
    let minimumChartHeight: CGFloat
    let minimumRailWidth: CGFloat

    init(dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall:
            self.init(textScale: 0.88, minimumCardHeight: 286, minimumChartHeight: 212, minimumRailWidth: 40)
        case .small:
            self.init(textScale: 0.94, minimumCardHeight: 288, minimumChartHeight: 212, minimumRailWidth: 42)
        case .medium:
            self.init(textScale: 0.98, minimumCardHeight: 290, minimumChartHeight: 214, minimumRailWidth: 44)
        case .large:
            self.init(textScale: 1.0, minimumCardHeight: 292, minimumChartHeight: 214, minimumRailWidth: 46)
        case .xLarge:
            self.init(textScale: 1.08, minimumCardHeight: 306, minimumChartHeight: 220, minimumRailWidth: 52)
        case .xxLarge:
            self.init(textScale: 1.17, minimumCardHeight: 318, minimumChartHeight: 228, minimumRailWidth: 58)
        case .xxxLarge:
            self.init(textScale: 1.28, minimumCardHeight: 332, minimumChartHeight: 236, minimumRailWidth: 64)
        case .accessibility1:
            self.init(textScale: 1.38, minimumCardHeight: 356, minimumChartHeight: 252, minimumRailWidth: 72)
        case .accessibility2:
            self.init(textScale: 1.48, minimumCardHeight: 382, minimumChartHeight: 268, minimumRailWidth: 80)
        case .accessibility3:
            self.init(textScale: 1.60, minimumCardHeight: 410, minimumChartHeight: 286, minimumRailWidth: 88)
        case .accessibility4:
            self.init(textScale: 1.72, minimumCardHeight: 438, minimumChartHeight: 304, minimumRailWidth: 96)
        case .accessibility5:
            self.init(textScale: 1.84, minimumCardHeight: 468, minimumChartHeight: 322, minimumRailWidth: 104)
        @unknown default:
            self.init(textScale: 1.0, minimumCardHeight: 292, minimumChartHeight: 214, minimumRailWidth: 46)
        }
    }

    private init(
        textScale: CGFloat,
        minimumCardHeight: CGFloat,
        minimumChartHeight: CGFloat,
        minimumRailWidth: CGFloat
    ) {
        self.textScale = textScale
        self.minimumCardHeight = minimumCardHeight
        self.minimumChartHeight = minimumChartHeight
        self.minimumRailWidth = minimumRailWidth
    }

    var monthTagWidth: CGFloat {
        max(196, 196 + ((textScale - 1) * 84))
    }

    var monthTagHeight: CGFloat {
        max(24, ceil((12 * textScale * 1.2) + 8))
    }

    func scaled(base: CGFloat) -> CGFloat {
        max(base * 0.88, (base * textScale).rounded(.toNearestOrAwayFromZero))
    }
}

typealias FajrWindowCompactCard = WeeklyFajrcastCard
