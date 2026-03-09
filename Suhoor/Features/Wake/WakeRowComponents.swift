import SwiftUI

struct WakeRowView: View {
    @Environment(\.editMode) private var editMode

    private let editAccessoryWidth: CGFloat = 40

    let entry: WakeRowEntry
    let deleteCapability: WakeRowDeleteCapability
    let onToggleChanged: (Bool) -> Void
    let onSelect: () -> Void
    let onRequestRamadanDisable: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 46
    @State private var localIsOn: Bool

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

    init(
        entry: WakeRowEntry,
        deleteCapability: WakeRowDeleteCapability,
        onToggleChanged: @escaping (Bool) -> Void = { _ in },
        onSelect: @escaping () -> Void,
        onRequestRamadanDisable: @escaping () -> Void
    ) {
        self.entry = entry
        self.deleteCapability = deleteCapability
        self.onToggleChanged = onToggleChanged
        self.onSelect = onSelect
        self.onRequestRamadanDisable = onRequestRamadanDisable
        _localIsOn = State(initialValue: !entry.config.skipDay && entry.config.hasAnyEnabled)
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            if showsRamadanEditAccessory {
                Button(action: onRequestRamadanDisable) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.gray)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .frame(width: editAccessoryWidth)
                .accessibilityLabel("Ramadan alarms can't be deleted")
                .accessibilityHint("Turn this day off instead")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel)
                    .font(.footnote)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(primaryTimeMain)
                        .font(.system(size: timeFontSize, weight: .regular, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(isDisabled ? .tertiary : .primary)
                        .minimumScaleFactor(0.8)

                    if let primaryTimeSuffix {
                        Text(primaryTimeSuffix)
                            .font(.system(size: timeFontSize * 0.55, weight: .regular, design: .default))
                            .monospacedDigit()
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                            .baselineOffset(1)
                    }
                }

                HStack(spacing: 8) {
                    Text(entry.rowPresentation.meaningText)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDisabled ? .tertiary : .primary)

                Text(entry.rowPresentation.detailText)
                    .font(.callout)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    .monospacedDigit()

                if !entry.rowPresentation.chipTitles.isEmpty {
                    HStack(spacing: DesignTokens.spacingXS) {
                        ForEach(entry.rowPresentation.chipTitles, id: \.self) { title in
                            WakeContextChip(
                                title: title,
                                isDisabled: isDisabled
                            )
                        }
                    }
                }

                if let provenanceText = entry.rowPresentation.provenanceText {
                    Text(provenanceText)
                        .font(.caption)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .onTapGesture {
                guard editMode?.wrappedValue.isEditing != true else { return }
                onSelect()
            }

            VStack(alignment: .trailing, spacing: 10) {
                if editMode?.wrappedValue.isEditing != true {
                    Button("Adjust this date") {
                        onSelect()
                    }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DawnColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(DawnColor.accent.opacity(0.12)))
                    .accessibilityLabel("Adjust this date")
                }

                Toggle("", isOn: Binding(
                    get: { localIsOn },
                    set: { isOn in
                        localIsOn = isOn
                        onToggleChanged(isOn)
                    }
                ))
                .labelsHidden()
                .tint(DawnColor.accent)
                .accessibilityLabel("Keep this morning active")
                .frame(minWidth: 51, alignment: .trailing)
            }
            .frame(minWidth: 74, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .onChange(of: entry.config) { _, newValue in
            localIsOn = !newValue.skipDay && newValue.hasAnyEnabled
        }
    }

    private var showsRamadanEditAccessory: Bool {
        editMode?.wrappedValue.isEditing == true && deleteCapability == .ramadan
    }

    private var primaryTimeMain: String {
        Self.timeMainFormatter.string(from: entry.schedule.wakeDate)
    }

    private var primaryTimeSuffix: String? {
        Self.timeSuffixFormatter.string(from: entry.schedule.wakeDate)
    }

    private var dateLabel: String {
        WakeRowPresentation.dateLabel(for: entry.schedule.date)
    }

    private var accessibilitySummary: String {
        var summary = "\(WakeRowPresentation.accessibilityDateLabel(for: entry.schedule.date)). Wake at \(primaryTimeText). \(entry.rowPresentation.meaningText). \(entry.rowPresentation.detailText)."
        if !entry.rowPresentation.chipTitles.isEmpty {
            summary += " \(entry.rowPresentation.chipTitles.joined(separator: ", "))."
        }
        if let provenanceText = entry.rowPresentation.provenanceText {
            summary += " \(provenanceText)."
        }
        return summary
    }

    private var isDisabled: Bool { !localIsOn }

    private var primaryTimeText: String {
        TimeFormatters.timeFormatter.string(from: entry.schedule.wakeDate)
    }
}

struct WakeContextChip: View {
    let title: String
    let isDisabled: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .opacity(isDisabled ? 0.55 : 1.0)
    }
}

struct MonthWakeCountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(count == 0 ? .secondary : DawnColor.accent)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(count == 0 ? Color.secondary.opacity(0.12) : DawnColor.accent.opacity(0.14))
            )
            .accessibilityLabel(Strings.AlarmsTab.alarmCountAccessibility(count))
    }
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
        .font((isCompact ? Font.caption2 : Font.caption).weight(.semibold))
        .foregroundStyle(base)
        .padding(.vertical, isCompact ? 3 : 4)
        .padding(.horizontal, isCompact ? 6 : 8)
        .background(Capsule().fill(base.opacity(fillOpacity)))
        .overlay(
            Capsule()
                .stroke(base.opacity(strokeOpacity), lineWidth: 0.8)
        )
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityHidden(true)
    }
}
