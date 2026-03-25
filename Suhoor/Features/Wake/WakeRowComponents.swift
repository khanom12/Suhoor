import SwiftUI

struct WakeRowView: View {
    let entry: WakeRowEntry
    let onSelect: () -> Void

    init(
        entry: WakeRowEntry,
        onSelect: @escaping () -> Void
    ) {
        self.entry = entry
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                HStack(alignment: .top, spacing: DesignTokens.spacingS) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                        Text(dateLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(dateLabelColor)

                        if let meaningLine {
                            Text(meaningLine)
                                .font(.caption)
                                .foregroundStyle(supportingTextColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: DesignTokens.spacingS)

                    if isSkipped {
                        Text("Off")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                    } else {
                        WakeAlarmTimeLockup(
                            date: entry.schedule.wakeDate,
                            isDisabled: false,
                            displayStyle: .row
                        )
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingS) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                        Text(entry.rowPresentation.stateLabel)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(isSkipped ? Color(UIColor.tertiaryLabel) : Color.primary.opacity(0.82))

                        Text(entry.rowPresentation.detailText)
                            .font(.caption)
                            .foregroundStyle(supportingTextColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer(minLength: DesignTokens.spacingS)

                    if let visibleChipTitle {
                        WakeContextChip(title: visibleChipTitle, isDisabled: isSkipped, compact: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        }
        .buttonStyle(.plain)
        .padding(.vertical, DesignTokens.space2)
    }

    private var dateLabel: String {
        WakeRowPresentation.dateLabel(for: entry.schedule.date)
    }

    private var accessibilitySummary: String {
        var parts = [WakeRowPresentation.accessibilityDateLabel(for: entry.schedule.date)]
        if isSkipped {
            parts.append("Morning off for this date")
        } else {
            parts.append("Wake at \(primaryTimeText)")
        }
        if entry.rowPresentation.meaningText != ProductSurfacePresentation.ordinaryDaySummaryText {
            parts.append(entry.rowPresentation.meaningText)
        }
        parts.append(entry.rowPresentation.stateLabel)
        parts.append(contentsOf: entry.rowPresentation.detailText.components(separatedBy: " · "))
        return parts.joined(separator: ". ") + "."
    }

    private var isSkipped: Bool {
        entry.rowPresentation.availability.state == .skipped
    }

    private var dateLabelColor: Color {
        isSkipped ? Color(UIColor.tertiaryLabel) : Color.primary.opacity(0.84)
    }

    private var supportingTextColor: Color {
        isSkipped ? Color(UIColor.tertiaryLabel) : .secondary
    }

    private var primaryTimeText: String {
        TimeFormatters.timeFormatter.string(from: entry.schedule.wakeDate)
    }

    private var meaningLine: String? {
        let meaning = entry.rowPresentation.meaningText
        return meaning == ProductSurfacePresentation.ordinaryDaySummaryText ? nil : meaning
    }

    private var visibleChipTitle: String? {
        entry.rowPresentation.chipTitles.first { title in
            title != entry.rowPresentation.stateLabel
                && title != entry.rowPresentation.meaningText
                && title != "Skipped"
                && title != "Fixed wake"
                && title != "After Fajr"
                && !meaningAlreadyCoversChip(title)
        }
    }

    private func meaningAlreadyCoversChip(_ title: String) -> Bool {
        guard let meaningLine else { return false }
        let loweredMeaning = meaningLine.lowercased()
        switch title {
        case "Fasting":
            return loweredMeaning.contains("fast")
        case "Qada":
            return loweredMeaning.contains("qada")
        case "Tahajjud":
            return loweredMeaning.contains("tahajjud")
        default:
            return false
        }
    }
}

struct WakeFeaturedEntryCard: View {
    let entry: WakeRowEntry
    let onSelect: () -> Void

    var body: some View {
        AppGlassSurface(variant: .standard, contentPadding: 14) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingS) {
                    Text(WakeRowPresentation.dateLabel(for: entry.schedule.date))
                        .font(AppTypography.badge)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let visibleChipTitle {
                        WakeContextChip(title: visibleChipTitle, isDisabled: isSkipped)
                    }
                }

                WakeAlarmTimeLockup(
                    date: entry.schedule.wakeDate,
                    isDisabled: isSkipped,
                    displayStyle: .featured
                )

                VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                    Text(entry.rowPresentation.stateLabel)
                        .font(AppTypography.rowTitle)

                    Text(entry.rowPresentation.detailText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let supportingLine {
                        Text(supportingLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
    }

    private var isSkipped: Bool {
        entry.rowPresentation.availability.state == .skipped
    }

    private var visibleChipTitle: String? {
        entry.rowPresentation.chipTitles.first { title in
            title != entry.rowPresentation.stateLabel
                && title != entry.rowPresentation.meaningText
                && title != "Skipped"
                && title != "Fixed wake"
                && title != "After Fajr"
                && !meaningAlreadyCoversChip(title)
        }
    }

    private var supportingLine: String? {
        let meaning = entry.rowPresentation.meaningText
        if meaning != ProductSurfacePresentation.ordinaryDaySummaryText {
            return meaning
        }

        guard visibleChipTitle == nil else { return nil }

        guard let secondaryExplanation = entry.rowPresentation.secondaryExplanation,
              secondaryExplanation != entry.rowPresentation.availability.availabilityLabel else {
            return nil
        }
        return secondaryExplanation
    }

    private func meaningAlreadyCoversChip(_ title: String) -> Bool {
        let meaning = entry.rowPresentation.meaningText.lowercased()
        switch title {
        case "Fasting":
            return meaning.contains("fast")
        case "Qada":
            return meaning.contains("qada")
        case "Tahajjud":
            return meaning.contains("tahajjud")
        default:
            return false
        }
    }
}

struct WakeMonthSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Text(title)
                .font(AppTypography.rowTitle)
            Text(count == 1 ? "1 wake" : "\(count) wakes")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, compact ? DesignTokens.compactChipHorizontalPadding : DesignTokens.badgeHorizontalPadding)
            .padding(.vertical, compact ? DesignTokens.compactChipVerticalPadding : DesignTokens.badgeVerticalPadding)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.08))
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize * suffixScale, weight: .regular))
                .foregroundStyle(isDisabled ? Color(UIColor.tertiaryLabel) : Color.secondary)
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
