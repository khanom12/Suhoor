import SwiftUI

enum SuhoorCalendarMode {
    case single
    case multi
}

private struct SuhoorCalendarMonthOffsetKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]

    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private enum SuhoorCalendarMetrics {
    static let daySize: CGFloat = 34
    static let rowSpacing: CGFloat = 10
    static let rowCount: CGFloat = 6
    static let verticalPadding: CGFloat = 4

    static var gridHeight: CGFloat {
        rowCount * daySize + (rowCount - 1) * rowSpacing + verticalPadding
    }
}

struct SuhoorCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var displayedMonth: Date
    @Binding private var focusedDate: Date

    private let allowedDateRange: ClosedRange<Date>
    private let mode: SuhoorCalendarMode
    private let selectedDate: Date?
    private let selectedDateKeys: Set<String>
    private let recommendedDateKeys: Set<String>
    private let disablesAlreadyActive: Bool
    private let isSelectable: (Date) -> Bool
    private let onSelectDate: ((Date) -> Void)?
    private let onToggleDate: ((Date) -> Void)?
    private let frameHeight: CGFloat

    @State private var hasPerformedInitialScroll = false
    @State private var visibleMonthStart: Date?
    @State private var isSyncingFromScroll = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    init(
        displayedMonth: Binding<Date>,
        focusedDate: Binding<Date>,
        selectedDate: Date,
        allowedDateRange: ClosedRange<Date>,
        frameHeight: CGFloat = SuhoorCalendarMetrics.gridHeight,
        onSelectDate: ((Date) -> Void)? = nil
    ) {
        _displayedMonth = displayedMonth
        _focusedDate = focusedDate
        self.allowedDateRange = allowedDateRange
        self.mode = .single
        self.selectedDate = selectedDate
        self.selectedDateKeys = []
        self.recommendedDateKeys = []
        self.disablesAlreadyActive = false
        self.isSelectable = { _ in true }
        self.onSelectDate = onSelectDate
        self.onToggleDate = nil
        self.frameHeight = frameHeight
    }

    init(
        displayedMonth: Binding<Date>,
        focusedDate: Binding<Date>,
        allowedDateRange: ClosedRange<Date>,
        selectedDateKeys: Set<String>,
        recommendedDateKeys: Set<String>,
        disablesAlreadyActive: Bool,
        isSelectable: @escaping (Date) -> Bool,
        frameHeight: CGFloat = SuhoorCalendarMetrics.gridHeight,
        onToggleDate: @escaping (Date) -> Void
    ) {
        _displayedMonth = displayedMonth
        _focusedDate = focusedDate
        self.allowedDateRange = allowedDateRange
        self.mode = .multi
        self.selectedDate = nil
        self.selectedDateKeys = selectedDateKeys
        self.recommendedDateKeys = recommendedDateKeys
        self.disablesAlreadyActive = disablesAlreadyActive
        self.isSelectable = isSelectable
        self.onSelectDate = nil
        self.onToggleDate = onToggleDate
        self.frameHeight = frameHeight
    }

    var body: some View {
        ScrollViewReader { reader in
            VStack(spacing: DesignTokens.spacingM) {
                header(reader: reader)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                        ForEach(monthStarts, id: \.self) { monthStart in
                            SuhoorCalendarMonthGrid(
                                monthStart: monthStart,
                                focusedDate: focusedDate,
                                allowedDateRange: allowedDateRange,
                                mode: mode,
                                selectedDate: selectedDate,
                                selectedDateKeys: selectedDateKeys,
                                recommendedDateKeys: recommendedDateKeys,
                                disablesAlreadyActive: disablesAlreadyActive,
                                isSelectable: isSelectable,
                                columns: columns,
                                scrollReader: reader,
                                handleTap: handleTap
                            )
                            .id(monthStart)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: SuhoorCalendarMonthOffsetKey.self,
                                        value: [monthStart: proxy.frame(in: .named("SuhoorCalendarScroll")).minY]
                                    )
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .coordinateSpace(name: "SuhoorCalendarScroll")
                .frame(height: frameHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                        .stroke(Color(.separator).opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .onPreferenceChange(SuhoorCalendarMonthOffsetKey.self) { offsets in
                syncVisibleMonth(with: offsets)
            }
            .onAppear {
                guard !hasPerformedInitialScroll else { return }
                hasPerformedInitialScroll = true
                let target = normalizedMonthStart(for: displayedMonth)
                visibleMonthStart = target
                DispatchQueue.main.async {
                    reader.scrollTo(target, anchor: .top)
                }
            }
            .onChange(of: displayedMonth) { _, newValue in
                guard !isSyncingFromScroll else { return }
                let target = normalizedMonthStart(for: newValue)
                withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                    reader.scrollTo(target, anchor: .top)
                }
            }
        }
    }

    private var currentMonthStart: Date {
        visibleMonthStart ?? normalizedMonthStart(for: displayedMonth)
    }

    private var monthStarts: [Date] {
        var starts: [Date] = []
        var cursor = normalizedMonthStart(for: allowedDateRange.lowerBound)
        let end = normalizedMonthStart(for: allowedDateRange.upperBound)
        while cursor <= end {
            starts.append(cursor)
            guard let next = shiftMonth(cursor, by: 1) else { break }
            cursor = next
        }
        return starts
    }

    private var weekdaySymbols: [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let prefixIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[prefixIndex...]) + Array(symbols[..<prefixIndex])
    }

    private func header(reader: ScrollViewProxy) -> some View {
        HStack {
            Text(GregorianDateFormatter.shared.monthYearString(for: currentMonthStart))
                .font(.headline.weight(.semibold))

            Spacer()

            Button {
                let today = DateHelpers.startOfToday()
                let todayStart = normalizedMonthStart(for: today)
                focusedDate = today
                displayedMonth = todayStart
                visibleMonthStart = todayStart
                withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                    reader.scrollTo(todayStart, anchor: .top)
                }
            } label: {
                Text("Today")
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
    }

    private func handleTap(state: CalendarDayState, isEnabledForToggle: Bool, scrollReader: ScrollViewProxy) {
        guard state.isInDisplayedMonth else { return }
        focusedDate = state.date

        switch mode {
        case .single:
            guard !state.isDisabled else {
                Haptics.medium()
                return
            }
            onSelectDate?(state.date)
            Haptics.light()
        case .multi:
            guard isEnabledForToggle else {
                Haptics.medium()
                return
            }
            onToggleDate?(state.date)
            Haptics.light()
        }
    }

    private func syncVisibleMonth(with offsets: [Date: CGFloat]) {
        guard let nearest = offsets.min(by: { abs($0.value) < abs($1.value) })?.key else { return }
        if nearest == visibleMonthStart { return }

        visibleMonthStart = nearest
        if displayedMonth != nearest {
            isSyncingFromScroll = true
            displayedMonth = nearest
            DispatchQueue.main.async {
                isSyncingFromScroll = false
            }
        }
    }

    private func normalizedMonthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? DateHelpers.startOfToday()
    }

    private func shiftMonth(_ date: Date, by value: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let monthStart = normalizedMonthStart(for: date)
        return calendar.date(byAdding: .month, value: value, to: monthStart)
    }
}

private struct SuhoorCalendarMonthGrid: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let monthStart: Date
    let focusedDate: Date
    let allowedDateRange: ClosedRange<Date>
    let mode: SuhoorCalendarMode
    let selectedDate: Date?
    let selectedDateKeys: Set<String>
    let recommendedDateKeys: Set<String>
    let disablesAlreadyActive: Bool
    let isSelectable: (Date) -> Bool
    let columns: [GridItem]
    let scrollReader: ScrollViewProxy
    let handleTap: (CalendarDayState, Bool, ScrollViewProxy) -> Void

    @State private var dayStates: [CalendarDayState] = []

    var body: some View {
        LazyVGrid(columns: columns, spacing: SuhoorCalendarMetrics.rowSpacing) {
            if !dayStates.isEmpty {
                ForEach(Array(dayStates.enumerated()), id: \.offset) { _, state in
                    let key = DateHelpers.dayIdentifier(for: state.date, timeZone: .current)
                    let isSelected = switch mode {
                    case .single:
                        if let selectedDate {
                            Calendar.current.isDate(state.date, inSameDayAs: selectedDate)
                        } else {
                            false
                        }
                    case .multi:
                        selectedDateKeys.contains(key)
                    }
                    let isRecommended = mode == .multi && recommendedDateKeys.contains(key) && !isSelected
                    let canToggle = !state.isDisabled
                        && !state.isLocked
                        && isSelectable(state.date)
                        && !(disablesAlreadyActive && state.isAlreadyActive)
                    let isUnavailable = state.isLocked || !isSelectable(state.date)

                    SuhoorCalendarDayCell(
                        state: state,
                        isSelected: isSelected,
                        isRecommended: isRecommended,
                        isUnavailable: isUnavailable,
                        isEnabledForToggle: canToggle,
                        mode: mode
                    ) {
                        handleTap(state, canToggle, scrollReader)
                    }
                }
            } else {
                ForEach(0..<42, id: \.self) { _ in
                    Color.clear
                        .frame(width: SuhoorCalendarMetrics.daySize, height: SuhoorCalendarMetrics.daySize)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            dayStates = scheduleManager.calendarMonthContext(
                displayedMonth: monthStart,
                selectedDate: focusedDate,
                allowedDateRange: allowedDateRange
            ).dayStates
        }
        .onChange(of: scheduleManager.lastUpdated) { _, _ in
            dayStates = scheduleManager.calendarMonthContext(
                displayedMonth: monthStart,
                selectedDate: focusedDate,
                allowedDateRange: allowedDateRange
            ).dayStates
        }
    }
}

struct PlanMultiSelectCalendar: View {
    @Binding var displayedMonth: Date
    let allowedDateRange: ClosedRange<Date>
    let selectedDateKeys: Set<String>
    let recommendedDateKeys: Set<String>
    let disablesAlreadyActive: Bool
    let isSelectable: (Date) -> Bool
    let onToggle: (Date) -> Void
    @Binding var focusedDate: Date

    var body: some View {
        SuhoorCalendarView(
            displayedMonth: $displayedMonth,
            focusedDate: $focusedDate,
            allowedDateRange: allowedDateRange,
            selectedDateKeys: selectedDateKeys,
            recommendedDateKeys: recommendedDateKeys,
            disablesAlreadyActive: disablesAlreadyActive,
            isSelectable: isSelectable,
            onToggleDate: onToggle
        )
    }
}

private struct SuhoorCalendarDayCell: View {
    let state: CalendarDayState
    let isSelected: Bool
    let isRecommended: Bool
    let isUnavailable: Bool
    let isEnabledForToggle: Bool
    let mode: SuhoorCalendarMode
    let onSelect: () -> Void

    var body: some View {
        if state.isInDisplayedMonth {
            Button(action: onSelect) {
                Text(state.dayNumberText)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(textColor)
                    .frame(width: SuhoorCalendarMetrics.daySize, height: SuhoorCalendarMetrics.daySize)
                    .background(baseBackground)
                    .overlay(suggestedOutline)
                    .overlay(todayRing)
                    .overlay(unavailableSlash)
                    .overlay(selectionOutline)
                    .frame(maxWidth: .infinity)
                    .opacity(opacity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        } else {
            Color.clear
                .frame(width: SuhoorCalendarMetrics.daySize, height: SuhoorCalendarMetrics.daySize)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        }
    }

    private var baseBackground: some View {
        Circle()
            .fill(backgroundFill)
    }

    private var todayRing: some View {
        Circle()
            .stroke(state.isToday ? DawnColor.highlight.opacity(0.7) : .clear, lineWidth: state.isToday ? 1.0 : 0)
    }

    private var suggestedOutline: some View {
        Circle()
            .stroke(
                isRecommended ? DawnColor.lightGold200 : .clear,
                style: StrokeStyle(lineWidth: isRecommended ? 1.1 : 0, dash: [3, 2])
            )
    }

    private var unavailableSlash: some View {
        Rectangle()
            .fill(isUnavailable ? Color.secondary.opacity(0.65) : .clear)
            .frame(width: 16, height: isUnavailable ? 1.5 : 0)
            .rotationEffect(.degrees(-45))
    }

    private var selectionOutline: some View {
        Circle()
            .stroke(borderColor, lineWidth: borderLineWidth)
    }

    private var borderColor: Color {
        if isSelected {
            return DawnColor.accent
        }
        if state.isToday {
            return DawnColor.highlight.opacity(0.7)
        }
        return Color.clear
    }

    private var borderLineWidth: CGFloat {
        if isSelected {
            return 1.5
        }
        if state.isToday {
            return 0.9
        }
        return 0
    }

    private var backgroundFill: Color {
        if isSelected {
            return DawnColor.accent.opacity(0.26)
        }
        if isUnavailable {
            return Color.secondary.opacity(0.08)
        }
        return .clear
    }

    private var displayAsDimmed: Bool {
        isUnavailable || state.isDisabled
    }

    private var displayAsUnavailableText: Bool {
        displayAsDimmed
    }

    private var selectedTextColor: Color {
        DawnColor.accentPressed
    }

    private var defaultTextColor: Color {
        .primary
    }

    private var dimmedTextColor: Color {
        .secondary
    }

    private var todayTextColor: Color {
        .primary
    }

    private var recommendationTextColor: Color {
        .primary
    }

    private var statusTextColor: Color {
        if isSelected {
            return selectedTextColor
        }
        if displayAsUnavailableText {
            return dimmedTextColor
        }
        if state.isToday {
            return todayTextColor
        }
        if isRecommended {
            return recommendationTextColor
        }
        return defaultTextColor
    }

    private var textColor: Color {
        statusTextColor
    }

    private var opacity: Double {
        if displayAsDimmed {
            return 0.35
        }
        return 1.0
    }

    private var accessibilityLabel: String {
        var parts = [
            GregorianDateFormatter.shared.headerString(for: state.date),
            state.hijriText
        ]

        if state.isToday {
            parts.append("Today")
        }

        if state.isLocked {
            if state.isRamadan {
                parts.append("Locked, Ramadan")
            } else {
                parts.append("Locked")
            }
        }

        if state.isAlreadyActive {
            parts.append("Scheduled as \(state.computedPrimaryIntent.shortTitle)")
            if !state.computedSecondaryTags.isEmpty {
                parts.append(
                    state.computedSecondaryTags
                        .map(\.shortTitle)
                        .joined(separator: ", ")
                )
            }
        }

        if isSelected {
            parts.append("Selected")
        } else if isRecommended {
            parts.append("Suggested")
        }

        return parts.joined(separator: ", ")
    }
}

struct SuhoorCalendarSelectionStatus {
    let title: String
    let detailLabel: String
    let reason: String
    let color: Color
}

struct SuhoorCalendarDetailCard: View {
    let detail: CalendarDayDetail
    let notScheduledText: String
    let selectionStatus: SuhoorCalendarSelectionStatus?

    init(
        detail: CalendarDayDetail,
        notScheduledText: String = "Not scheduled",
        selectionStatus: SuhoorCalendarSelectionStatus? = nil
    ) {
        self.detail = detail
        self.notScheduledText = notScheduledText
        self.selectionStatus = selectionStatus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail.gregorianText)
                .font(.headline.weight(.semibold))
            Text(detail.hijriText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let selectionStatus {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(selectionStatus.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selectionStatus.color)

                    Text(selectionStatus.detailLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(selectionStatus.reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !detail.warnings.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(detail.warnings, id: \.self) { warning in
                        SuhoorCalendarTagChip(
                            text: warning.title,
                            systemImage: warning.systemImage,
                            color: FastPrimaryIntent.forbidden.style.color
                        )
                    }
                }
            }

            let observanceTags = detail.isAlreadyActive ? detail.computedSecondaryTags : detail.previewSecondaryTags
            if !observanceTags.isEmpty {
                Text("Observances")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(observanceTags, id: \.self) { tag in
                        SuhoorCalendarTagChip(
                            text: tag.shortTitle,
                            systemImage: tag.style.systemImage,
                            color: tag.style.color
                        )
                    }
                }
            } else if selectionStatus == nil {
                Text(notScheduledText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if detail.isAlreadyActive, let sourceSummary = detail.activeSourceSummary {
                Text(sourceSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.spacingM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct SuhoorCalendarTagChip: View {
    let text: String
    let systemImage: String?
    let color: Color

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.vertical, DesignTokens.spacingXS)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule(style: .continuous))
    }
}
