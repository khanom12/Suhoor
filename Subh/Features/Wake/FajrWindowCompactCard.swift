import SwiftUI
import UIKit

struct WeeklyFajrcastCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var suppressNextOpen = false
    @State private var isInspectingDatePill = false

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
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, chartVerticalPadding)

                    dividerLine
                        .padding(.horizontal, horizontalInset)

                    footer
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, footerVerticalPadding)
                        .padding(.bottom, footerBottomPadding)
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

            Text(headerDatePillText)
                .font(.system(size: monthTagPointSize, weight: .regular))
                .foregroundStyle(monthTagColor)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(width: monthTagWidth, height: monthTagHeight, alignment: .center)
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
                .font(.system(size: footerPointSize, weight: .regular))
                .foregroundStyle(footerColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let secondaryText = snapshot.summary.secondaryText, !secondaryText.isEmpty {
                Text(secondaryText)
                    .font(.system(size: footerSecondaryPointSize, weight: .regular))
                    .foregroundStyle(footerColor)
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

    private var footerVerticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var footerBottomPadding: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            let scaledFooterLineHeight = layoutProfile.scaled(base: 13) * 1.22
            return max(22, 0.75 * scaledFooterLineHeight)
        }

        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 16
        case .large:
            return 20
        case .xLarge, .xxLarge, .xxxLarge:
            return 22
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            let scaledFooterLineHeight = layoutProfile.scaled(base: 13) * 1.22
            return max(22, 0.75 * scaledFooterLineHeight)
        @unknown default:
            return 20
        }
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

    private var headerDatePillText: String {
        if isInspectingDatePill,
           let selectedPoint = snapshot.points.first(where: { $0.dateKey == snapshot.selectedDay.dateKey }) {
            return singleDatePillText(for: selectedPoint.date)
        }

        return monthTagText
    }

    private var monthTagText: String {
        let dates = snapshot.points.map(\.date).sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else {
            return "This week"
        }

        return gregorianWeekRange(start: firstDate, end: lastDate)
    }

    private func openIfChartIsIdle() {
        if suppressNextOpen {
            suppressNextOpen = false
            return
        }

        onOpen()
    }

    private func selectDateFromChart(_ dateKey: String) {
        isInspectingDatePill = true
        suppressOpenBriefly()
        onSelectDateKey?(dateKey)
    }

    private func endSelectionFromChart() {
        isInspectingDatePill = false
        suppressOpenBriefly()
        onEndSelection?()
    }

    private func moveSelectionFromChart(_ offset: Int) {
        isInspectingDatePill = true
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

        let startToken = gregorianMonthName(for: start)
        let endToken = gregorianMonthName(for: end)

        if startMonth == endMonth {
            if startDay == endDay {
                return "\(startToken) \(startDay)"
            }
            return "\(startToken) \(startDay)–\(endDay)"
        }

        return "\(startToken) \(startDay)–\(endToken) \(endDay)"
    }

    private func singleDatePillText(for date: Date) -> String {
        gregorianSingleDate(date)
    }

    private func gregorianSingleDate(_ date: Date) -> String {
        let components = gregorianCalendar.dateComponents([.month, .day], from: date)
        guard components.month != nil, let day = components.day else {
            return "This day"
        }

        return "\(gregorianMonthName(for: date)) \(day)"
    }

    private var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func gregorianMonthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.calendar = gregorianCalendar
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter.string(from: date)
    }
}

private struct WeeklyFajrcastCardLayoutProfile {
    let textScale: CGFloat
    let minimumCardHeight: CGFloat

    init(dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall:
            self.init(textScale: 0.88, minimumCardHeight: 266)
        case .small:
            self.init(textScale: 0.94, minimumCardHeight: 268)
        case .medium:
            self.init(textScale: 0.98, minimumCardHeight: 270)
        case .large:
            self.init(textScale: 1.0, minimumCardHeight: 272)
        case .xLarge:
            self.init(textScale: 1.08, minimumCardHeight: 284)
        case .xxLarge:
            self.init(textScale: 1.17, minimumCardHeight: 296)
        case .xxxLarge:
            self.init(textScale: 1.28, minimumCardHeight: 310)
        case .accessibility1:
            self.init(textScale: 1.38, minimumCardHeight: 328)
        case .accessibility2:
            self.init(textScale: 1.48, minimumCardHeight: 354)
        case .accessibility3:
            self.init(textScale: 1.60, minimumCardHeight: 382)
        case .accessibility4:
            self.init(textScale: 1.72, minimumCardHeight: 410)
        case .accessibility5:
            self.init(textScale: 1.84, minimumCardHeight: 440)
        @unknown default:
            self.init(textScale: 1.0, minimumCardHeight: 272)
        }
    }

    private init(
        textScale: CGFloat,
        minimumCardHeight: CGFloat
    ) {
        self.textScale = textScale
        self.minimumCardHeight = minimumCardHeight
    }

    var monthTagWidth: CGFloat {
        let font = UIFont.systemFont(ofSize: scaled(base: 12), weight: .regular)
        let referenceWidth = ("September 30–October 6" as NSString).size(
            withAttributes: [.font: font]
        ).width
        return ceil(max(196, referenceWidth + 30))
    }

    var monthTagHeight: CGFloat {
        max(24, ceil((12 * textScale * 1.2) + 8))
    }

    func scaled(base: CGFloat) -> CGFloat {
        max(base * 0.88, (base * textScale).rounded(.toNearestOrAwayFromZero))
    }
}

typealias FajrWindowCompactCard = WeeklyFajrcastCard
