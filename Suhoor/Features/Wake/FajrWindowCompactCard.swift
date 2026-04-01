import SwiftUI
import UIKit

struct WeeklyFajrcastCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let snapshot: FajrWindowCompactSnapshot
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            AppGlassSurface(variant: .grouped, tint: .black, contentPadding: 0) {
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
                        compactSelectedDay: snapshot.selectedDay
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
                        .fill(Color.black.opacity(0.05))
                )
        }
        .frame(height: monthTagHeight, alignment: .top)
    }

    private var footer: some View {
        Text(snapshot.summary.primaryText)
            .font(.system(size: footerPointSize, weight: .regular))
            .foregroundStyle(footerColor)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.black.opacity(0.05))
            .frame(height: 1)
    }

    private var accessibilitySummary: String {
        [
            snapshot.summary.primaryText,
            snapshot.summary.secondaryText,
            snapshot.selectedDay.accessibilityValue,
            selectedWeekdayAccessibilityValue
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: " ")
    }

    private var selectedWeekdayAccessibilityValue: String? {
        if let selectedPoint = snapshot.points.first(where: { $0.dateKey == snapshot.selectedDay.dateKey }) {
            return "Selected day \(selectedPoint.longLabel)."
        }
        return nil
    }

    private var minimumHeight: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return 252
        }

        if dynamicTypeSize >= .xxxLarge {
            return 229
        }

        return 224
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
        if dynamicTypeSize.isAccessibilitySize {
            return 156
        }

        if dynamicTypeSize >= .xxxLarge {
            return 148
        }

        return 143
    }

    private var footerVerticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var headerTitleTopInset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 6 : 5
    }

    private var monthTagWidth: CGFloat {
        196
    }

    private var monthTagHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 28 : 24
    }

    private var titlePointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var monthTagPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var footerPointSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 12
    }

    private var titleColor: Color {
        .white
    }

    private var monthTagColor: Color {
        .white
    }

    private var footerColor: Color {
        .black
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

typealias FajrWindowCompactCard = WeeklyFajrcastCard
