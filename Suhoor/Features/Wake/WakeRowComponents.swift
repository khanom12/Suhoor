import SwiftUI

enum WakeGlassTheme {
    static let surfaceVariant: AppGlassSurfaceVariant = .grouped
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.70)
    static let tertiaryText = Color.white.opacity(0.50)
    static let divider = Color.white.opacity(0.05)
    static let chipFill = Color.white.opacity(0.08)
    static let chipStroke = Color.white.opacity(0.08)
}

struct WakeGlassCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        padding: CGFloat = DesignTokens.dashboardCardPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.surfaceVariant,
            contentPadding: padding
        ) {
            content()
        }
    }
}

struct WakeRowView: View {
    let entry: WakeRowEntry
    let onSelect: () -> Void

    private var display: WakePageRowDisplay {
        WakePagePresentation.row(for: entry)
    }

    init(
        entry: WakeRowEntry,
        onSelect: @escaping () -> Void
    ) {
        self.entry = entry
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(display.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(titleColor)

                    Text(display.subtitle)
                        .font(.footnote)
                        .foregroundStyle(subtitleColor)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DesignTokens.spacingS)

                trailingView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.accessibilityLabel)
        }
        .buttonStyle(.plain)
        .padding(.vertical, DesignTokens.space6)
    }

    @ViewBuilder
    private var trailingView: some View {
        if let trailingTime = display.trailingTime {
            WakeAlarmTimeLockup(
                date: trailingTime,
                isDisabled: false,
                displayStyle: .row
            )
            .fixedSize(horizontal: true, vertical: false)
        } else if let trailingStatusText = display.trailingStatusText {
            Text(trailingStatusText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var titleColor: Color {
        display.isInactive ? WakeGlassTheme.primaryText.opacity(0.62) : WakeGlassTheme.primaryText.opacity(0.92)
    }

    private var subtitleColor: Color {
        display.isInactive ? WakeGlassTheme.secondaryText.opacity(0.82) : WakeGlassTheme.secondaryText
    }
}

struct WakeFeaturedEntryCard: View {
    let entry: WakeRowEntry
    let onSelect: () -> Void

    private var display: WakePageCardDisplay {
        WakePagePresentation.card(for: entry)
    }

    var body: some View {
        WakeGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(display.overline)
                        .appTextRole(.eyebrow)
                        .foregroundStyle(WakeGlassTheme.tertiaryText)
                    Spacer()
                    if let badgeTitle = display.badgeTitle {
                        WakeContextChip(title: badgeTitle, isDisabled: false, compact: true)
                    }
                }

                Text(display.dateLabel)
                    .font(AppTypography.badge)
                    .foregroundStyle(WakeGlassTheme.secondaryText)

                WakeAlarmTimeLockup(
                    date: entry.schedule.wakeDate,
                    isDisabled: display.isInactive,
                    displayStyle: .featured
                )

                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(display.title)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(WakeGlassTheme.primaryText)

                    Text(display.subtitle)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(display.accessibilityLabel)
        }
    }
}

struct WakeMonthSectionHeader: View {
    let title: String

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.secondaryText)
            Spacer()
        }
    }
}

struct WakeContextChip: View {
    let title: String
    let isDisabled: Bool
    var compact: Bool = false

    var body: some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(WakeGlassTheme.secondaryText)
            .padding(.horizontal, compact ? DesignTokens.compactChipHorizontalPadding : DesignTokens.badgeHorizontalPadding)
            .padding(.vertical, compact ? DesignTokens.compactChipVerticalPadding : DesignTokens.badgeVerticalPadding)
            .background(
                Capsule()
                    .fill(WakeGlassTheme.chipFill)
                    .overlay {
                        Capsule().stroke(WakeGlassTheme.chipStroke, lineWidth: 1)
                    }
            )
            .opacity(isDisabled ? 0.55 : 1.0)
    }
}

private struct WakeAlarmTimeLockup: View {
    enum DisplayStyle: Equatable {
        case featured
        case row
    }

    let date: Date
    let isDisabled: Bool
    let displayStyle: DisplayStyle

    @ScaledMetric(relativeTo: .title3) private var rowTimePointSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var featuredTimePointSize: CGFloat = 36

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize, weight: displayStyle == .row ? .regular : .light))
                .foregroundStyle(isDisabled ? WakeGlassTheme.secondaryText : WakeGlassTheme.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize * suffixScale, weight: .regular))
                .foregroundStyle(isDisabled ? WakeGlassTheme.tertiaryText : WakeGlassTheme.secondaryText)
                .monospacedDigit()
                .baselineOffset(2)
        }
    }

    private var timePointSize: CGFloat {
        switch displayStyle {
        case .featured:
            return featuredTimePointSize
        case .row:
            return rowTimePointSize
        }
    }

    private var suffixScale: CGFloat {
        switch displayStyle {
        case .featured:
            return 0.46
        case .row:
            return 0.42
        }
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

enum WakeRowPresentation {
    private static let adjustedHijriCalendar = AdjustedHijriCalendar.shared

    static func dateLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        if isToday(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.todayLabel
        }
        if isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.tomorrowLabel
        }
        if let ramadanLabel = ramadanLabel(for: date, timeZone: timeZone, weekdayFormatter: fullWeekdayFormatter) {
            return ramadanLabel
        }
        return dateLabelFormatter.string(from: date)
    }

    static func accessibilityDateLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        if isToday(date, currentDate: currentDate, timeZone: timeZone) {
            return "\(Strings.AlarmsTab.todayLabel), \(accessibilityDateLabelFormatter.string(from: date))"
        }
        if isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(accessibilityDateLabelFormatter.string(from: date))"
        }
        if let ramadanLabel = ramadanLabel(for: date, timeZone: timeZone, weekdayFormatter: accessibilityWeekdayFormatter) {
            return ramadanLabel
        }
        return accessibilityDateLabelFormatter.string(from: date)
    }

    private static func isToday(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(date, inSameDayAs: calendar.startOfDay(for: currentDate))
    }

    private static func isTomorrow(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: currentDate)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        return calendar.isDate(date, inSameDayAs: startOfTomorrow)
    }

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let fullWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let accessibilityDateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let accessibilityWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static func ramadanLabel(
        for date: Date,
        timeZone: TimeZone,
        weekdayFormatter: DateFormatter
    ) -> String? {
        guard adjustedHijriCalendar.isRamadan(date: date, timeZone: timeZone) else { return nil }
        guard let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) else { return nil }
        return "\(weekdayFormatter.string(from: date)), \(components.day) Ramadan"
    }
}

struct WakeFilterChip: View {
    enum Prominence {
        case strong
        case subtle
    }

    let style: FastTagStyle
    let prominence: Prominence
    let isDisabled: Bool
    let showsTitle: Bool
    let isCompact: Bool

    var body: some View {
        let base = style.color
        let fillOpacity = prominence == .strong ? 0.18 : 0.10
        let strokeOpacity = prominence == .strong ? 0.35 : 0.22

        HStack(spacing: isCompact ? 4 : 5) {
            if let systemImage = style.systemImage {
                Image(systemName: systemImage)
            }
            if showsTitle {
                Text(style.shortTitle)
                    .lineLimit(1)
            }
        }
        .font(AppTypography.badge)
        .foregroundStyle(base)
        .padding(.vertical, isCompact ? DesignTokens.compactChipVerticalPadding : DesignTokens.badgeVerticalPadding)
        .padding(.horizontal, isCompact ? DesignTokens.compactChipHorizontalPadding : DesignTokens.badgeHorizontalPadding)
        .background(Capsule().fill(base.opacity(fillOpacity)))
        .overlay(
            Capsule()
                .stroke(base.opacity(strokeOpacity), lineWidth: 0.8)
        )
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityHidden(true)
    }
}
