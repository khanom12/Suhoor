import SwiftUI

struct WeeklyFajrcastCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let snapshot: FajrWindowCompactSnapshot
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .topLeading) {
                cardShell

                header
                    .padding(.horizontal, horizontalInset)
                    .padding(.top, headerTopPadding)

                dividerLine
                    .padding(.horizontal, horizontalInset)
                    .offset(y: headerDividerTop)

                FajrWindowChartView(
                    chart: snapshot.chart,
                    layoutStyle: .compact,
                    compactSelectedDay: snapshot.selectedDay
                )
                .frame(height: chartHeight)
                .padding(.horizontal, horizontalInset)
                .offset(y: chartTopOffset)

                dividerLine
                    .padding(.horizontal, horizontalInset)
                    .offset(y: footerDividerTop)

                footer
                    .padding(.horizontal, horizontalInset)
                    .offset(y: footerTextTop)
            }
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
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
                .font(.system(size: titlePointSize, weight: .light))
                .tracking(0.6)
                .foregroundStyle(titleColor)
                .padding(.top, headerTitleTopInset)

            Spacer(minLength: 0)

            Text(monthTagText)
                .font(.system(size: monthTagPointSize, weight: .regular))
                .foregroundStyle(monthTagColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: monthTagWidth, height: monthTagHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.20))
                )
        }
        .frame(height: monthTagHeight, alignment: .top)
    }

    private var footer: some View {
        Text(snapshot.summary.primaryText)
            .font(.system(size: footerPointSize, weight: .regular))
            .foregroundStyle(footerColor)
            .lineLimit(1)
            .minimumScaleFactor(0.84)
            .frame(maxWidth: footerWidth, alignment: .leading)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
    }

    private var cardShell: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black.opacity(0.30))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(shellStrokeColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 24, x: 0, y: 14)
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
            return 236
        }

        return 224
    }

    private var horizontalInset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 18 : 21
    }

    private var headerTopPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var headerDividerTop: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 40 : 36
    }

    private var chartTopOffset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 48 : 43
    }

    private var chartHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 156 : 143
    }

    private var footerDividerTop: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 214 : 194
    }

    private var footerTextTop: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 220 : 200
    }

    private var headerTitleTopInset: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 6 : 5
    }

    private var monthTagWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 144 : 130
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

    private var footerWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 290 : 252
    }

    private var titleColor: Color {
        Color.white.opacity(0.5)
    }

    private var monthTagColor: Color {
        Color.white.opacity(0.5)
    }

    private var footerColor: Color {
        Color.white.opacity(0.5)
    }

    private var shellStrokeColor: Color {
        Color.white.opacity(0.08)
    }

    private var shadowColor: Color {
        Color.black.opacity(0.18)
    }

    private var monthTagText: String {
        let dates = snapshot.points.map(\.date)
        guard let firstDate = dates.first, let lastDate = dates.last else {
            return "This week"
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return formatter.string(from: firstDate)
        }

        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }
}

typealias FajrWindowCompactCard = WeeklyFajrcastCard
