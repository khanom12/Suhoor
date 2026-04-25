import SwiftUI

enum SuhoorCalendarMode {
    case single
    case multi
}

private enum SuhoorCalendarMetrics {
    static let daySize: CGFloat = 34
    static let rowSpacing: CGFloat = 10
    static let visibleWeekCount = 6
    static let verticalPadding: CGFloat = 4

    static var gridHeight: CGFloat {
        CGFloat(visibleWeekCount) * daySize
            + CGFloat(visibleWeekCount - 1) * rowSpacing
            + verticalPadding
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
    private let onFocusDate: ((Date) -> Void)?
    private let frameHeight: CGFloat

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
        self.onFocusDate = nil
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
        onToggleDate: @escaping (Date) -> Void,
        onFocusDate: ((Date) -> Void)? = nil
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
        self.onFocusDate = onFocusDate
        self.frameHeight = frameHeight
    }

    var body: some View {
        VStack(spacing: DesignTokens.spacingM) {
            header

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(AppTypography.badge)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            SuhoorCalendarWeekDeck(
                weekStart: currentWeekDeckStart,
                displayedMonth: displayedMonth,
                focusedDate: focusedDate,
                allowedDateRange: allowedDateRange,
                mode: mode,
                selectedDate: selectedDate,
                selectedDateKeys: selectedDateKeys,
                recommendedDateKeys: recommendedDateKeys,
                disablesAlreadyActive: disablesAlreadyActive,
                isSelectable: isSelectable,
                columns: columns,
                handleTap: handleTap
            )
            .id(currentWeekDeckStart)
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
            .contentShape(Rectangle())
            .gesture(weekSwipeGesture)
        }
        .onAppear {
            syncFocusedDateFromDisplayedMonthIfNeeded()
            let clamped = clampedFocusedDate(focusedDate)
            if focusedDate != clamped {
                focusedDate = clamped
                displayedMonth = normalizedMonthStart(for: clamped)
            }
        }
        .onChange(of: displayedMonth) { _, newValue in
            let clampedMonth = clampedMonthStart(for: newValue)
            if displayedMonth != clampedMonth { displayedMonth = clampedMonth }
            syncFocusedDateFromDisplayedMonthIfNeeded()
        }
        .onChange(of: focusedDate) { _, newValue in
            let clamped = clampedFocusedDate(newValue)
            if focusedDate != clamped {
                focusedDate = clamped
            }
            let monthStart = normalizedMonthStart(for: clamped)
            if displayedMonth != monthStart {
                displayedMonth = monthStart
            }
        }
    }

    private var currentWeekStart: Date {
        normalizedWeekStart(for: clampedFocusedDate(focusedDate))
    }

    private var currentWeekDeckStart: Date {
        clampedDeckStart(
            for: shiftWeek(currentWeekStart, by: -leadingContextWeeks) ?? currentWeekStart
        )
    }

    private var leadingContextWeeks: Int {
        max(0, (SuhoorCalendarMetrics.visibleWeekCount - 1) / 2)
    }

    private var minimumMonthStart: Date {
        normalizedMonthStart(for: allowedDateRange.lowerBound)
    }

    private var maximumMonthStart: Date {
        normalizedMonthStart(for: allowedDateRange.upperBound)
    }

    private var minimumWeekStart: Date {
        normalizedWeekStart(for: allowedDateRange.lowerBound)
    }

    private var maximumWeekStart: Date {
        normalizedWeekStart(for: allowedDateRange.upperBound)
    }

    private var weekdaySymbols: [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let prefixIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[prefixIndex...]) + Array(symbols[..<prefixIndex])
    }

    private var header: some View {
        HStack {
            Text(GregorianDateFormatter.shared.monthYearString(for: clampedFocusedDate(focusedDate)))
                .font(AppTypography.cardTitle)
            Spacer()
        }
    }

    private var weekSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let verticalTravel = value.translation.height
                let horizontalTravel = value.translation.width
                guard abs(verticalTravel) > abs(horizontalTravel) else { return }
                guard abs(verticalTravel) > 42 else { return }
                if verticalTravel < 0 {
                    moveWeek(by: 1)
                } else {
                    moveWeek(by: -1)
                }
            }
    }

    private func moveWeek(by offset: Int) {
        guard let shifted = shiftWeek(currentWeekStart, by: offset) else { return }
        let targetWeekStart = clampedWeekStart(for: shifted)
        guard targetWeekStart != currentWeekStart else {
            Haptics.medium()
            return
        }
        let targetFocusDate = alignedFocusDate(forWeekStart: targetWeekStart, relativeTo: focusedDate)
        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
            focusedDate = targetFocusDate
            displayedMonth = normalizedMonthStart(for: targetFocusDate)
        }
        Haptics.light()
    }

    private func handleTap(state: CalendarDayState, isEnabledForToggle: Bool) {
        focusedDate = state.date
        displayedMonth = normalizedMonthStart(for: state.date)
        onFocusDate?(state.date)

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

    private func clampedMonthStart(for date: Date) -> Date {
        let normalized = normalizedMonthStart(for: date)
        if normalized < minimumMonthStart {
            return minimumMonthStart
        }
        if normalized > maximumMonthStart {
            return maximumMonthStart
        }
        return normalized
    }

    private func clampedFocusedDate(_ date: Date) -> Date {
        let normalized = DateHelpers.startOfDay(date, in: .current)
        let lowerBound = DateHelpers.startOfDay(allowedDateRange.lowerBound, in: .current)
        let upperBound = DateHelpers.startOfDay(allowedDateRange.upperBound, in: .current)
        if normalized < lowerBound { return lowerBound }
        if normalized > upperBound { return upperBound }
        return normalized
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

    private func normalizedWeekStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }

    private func shiftWeek(_ date: Date, by value: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(byAdding: .day, value: value * 7, to: normalizedWeekStart(for: date))
    }

    private func clampedWeekStart(for date: Date) -> Date {
        let normalized = normalizedWeekStart(for: date)
        if normalized < minimumWeekStart { return minimumWeekStart }
        if normalized > maximumWeekStart { return maximumWeekStart }
        return normalized
    }

    private func clampedDeckStart(for date: Date) -> Date {
        let normalized = clampedWeekStart(for: date)
        guard SuhoorCalendarMetrics.visibleWeekCount > 1 else { return normalized }
        guard let maxDeckStartCandidate = shiftWeek(maximumWeekStart, by: -(SuhoorCalendarMetrics.visibleWeekCount - 1)) else {
            return normalized
        }
        let maxDeckStart = max(minimumWeekStart, maxDeckStartCandidate)
        if normalized < minimumWeekStart { return minimumWeekStart }
        if normalized > maxDeckStart { return maxDeckStart }
        return normalized
    }

    private func alignedFocusDate(for monthStart: Date, relativeTo seedDate: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let preferredDay = max(1, calendar.component(.day, from: seedDate))
        let rawCandidate = calendar.date(byAdding: .day, value: preferredDay - 1, to: monthStart) ?? monthStart
        let monthRange = allowedMonthRange(for: monthStart)
        let candidate = DateHelpers.startOfDay(rawCandidate, in: .current)
        if candidate < monthRange.lowerBound {
            return monthRange.lowerBound
        }
        if candidate > monthRange.upperBound {
            return monthRange.upperBound
        }
        return candidate
    }

    private func allowedMonthRange(for monthStart: Date) -> ClosedRange<Date> {
        let lowerBound = max(
            DateHelpers.startOfDay(allowedDateRange.lowerBound, in: .current),
            monthStart
        )
        let nextMonth = shiftMonth(monthStart, by: 1)
        let lastDayInMonth = nextMonth.map {
            DateHelpers.startOfDay($0.addingTimeInterval(-24 * 60 * 60), in: .current)
        } ?? monthStart
        let upperBound = min(
            DateHelpers.startOfDay(allowedDateRange.upperBound, in: .current),
            lastDayInMonth
        )
        let clampedUpperBound = upperBound < lowerBound ? lowerBound : upperBound
        return lowerBound...clampedUpperBound
    }

    private func alignedFocusDate(forWeekStart weekStart: Date, relativeTo seedDate: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let offset = calendar.dateComponents([.day], from: normalizedWeekStart(for: seedDate), to: seedDate).day ?? 0
        let rawCandidate = calendar.date(byAdding: .day, value: max(0, min(6, offset)), to: weekStart) ?? weekStart
        return clampedFocusedDate(rawCandidate)
    }

    private func syncFocusedDateFromDisplayedMonthIfNeeded() {
        let targetMonthStart = clampedMonthStart(for: displayedMonth)
        if normalizedMonthStart(for: focusedDate) == targetMonthStart {
            return
        }
        let aligned = alignedFocusDate(for: targetMonthStart, relativeTo: focusedDate)
        focusedDate = clampedFocusedDate(aligned)
    }
}

private struct SuhoorCalendarWeekDeck: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let weekStart: Date
    let displayedMonth: Date
    let focusedDate: Date
    let allowedDateRange: ClosedRange<Date>
    let mode: SuhoorCalendarMode
    let selectedDate: Date?
    let selectedDateKeys: Set<String>
    let recommendedDateKeys: Set<String>
    let disablesAlreadyActive: Bool
    let isSelectable: (Date) -> Bool
    let columns: [GridItem]
    let handleTap: (CalendarDayState, Bool) -> Void

    @State private var dayStates: [CalendarDayState] = []

    var body: some View {
        LazyVGrid(columns: columns, spacing: SuhoorCalendarMetrics.rowSpacing) {
            if !dayStates.isEmpty {
                ForEach(Array(dayStates.enumerated()), id: \.offset) { _, state in
                    let key = DateHelpers.dayIdentifier(for: state.date, timeZone: .current)
                    let isInDisplayedMonth = isDateInDisplayedMonth(state.date)
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
                    let selectable = isSelectable(state.date)
                    let isBlockedByExistingActivity = disablesAlreadyActive && state.isAlreadyActive
                    let canToggle = !state.isDisabled
                        && !state.isLocked
                        && selectable
                        && !isBlockedByExistingActivity
                    let isUnavailable = state.isLocked || !selectable || isBlockedByExistingActivity

                    SuhoorCalendarDayCell(
                        state: state,
                        isInDisplayedMonth: isInDisplayedMonth,
                        isSelected: isSelected,
                        isRecommended: isRecommended,
                        isUnavailable: isUnavailable,
                        isEnabledForToggle: canToggle,
                        mode: mode
                    ) {
                        handleTap(state, canToggle)
                    }
                }
            } else {
                ForEach(0..<(SuhoorCalendarMetrics.visibleWeekCount * 7), id: \.self) { _ in
                    Color.clear
                        .frame(width: SuhoorCalendarMetrics.daySize, height: SuhoorCalendarMetrics.daySize)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear(perform: refreshDayStates)
        .onChange(of: weekStart) { _, _ in refreshDayStates() }
        .onChange(of: focusedDate) { _, _ in refreshDayStates() }
        .onChange(of: scheduleManager.currentRevision) { _, _ in
            refreshDayStates()
        }
    }

    private func refreshDayStates() {
        let visibleDates = weekDates()
        dayStates = scheduleManager.calendarDayStates(
            dates: visibleDates,
            selectedDate: focusedDate,
            allowedDateRange: allowedDateRange
        )
    }

    private func weekDates() -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let clampedWeekStart = DateHelpers.startOfDay(weekStart, in: .current)
        return (0..<(SuhoorCalendarMetrics.visibleWeekCount * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: clampedWeekStart)
        }
    }

    private func isDateInDisplayedMonth(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.isDate(
            date,
            equalTo: DateHelpers.startOfDay(displayedMonth, in: .current),
            toGranularity: .month
        )
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
    let onFocusDate: ((Date) -> Void)?

    init(
        displayedMonth: Binding<Date>,
        allowedDateRange: ClosedRange<Date>,
        selectedDateKeys: Set<String>,
        recommendedDateKeys: Set<String>,
        disablesAlreadyActive: Bool,
        isSelectable: @escaping (Date) -> Bool,
        onToggle: @escaping (Date) -> Void,
        focusedDate: Binding<Date>,
        onFocusDate: ((Date) -> Void)? = nil
    ) {
        _displayedMonth = displayedMonth
        self.allowedDateRange = allowedDateRange
        self.selectedDateKeys = selectedDateKeys
        self.recommendedDateKeys = recommendedDateKeys
        self.disablesAlreadyActive = disablesAlreadyActive
        self.isSelectable = isSelectable
        self.onToggle = onToggle
        _focusedDate = focusedDate
        self.onFocusDate = onFocusDate
    }

    var body: some View {
        SuhoorCalendarView(
            displayedMonth: $displayedMonth,
            focusedDate: $focusedDate,
            allowedDateRange: allowedDateRange,
            selectedDateKeys: selectedDateKeys,
            recommendedDateKeys: recommendedDateKeys,
            disablesAlreadyActive: disablesAlreadyActive,
            isSelectable: isSelectable,
            onToggleDate: onToggle,
            onFocusDate: onFocusDate
        )
    }
}

private struct SuhoorCalendarDayCell: View {
    let state: CalendarDayState
    let isInDisplayedMonth: Bool
    let isSelected: Bool
    let isRecommended: Bool
    let isUnavailable: Bool
    let isEnabledForToggle: Bool
    let mode: SuhoorCalendarMode
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(state.dayNumberText)
                .font(AppTypography.calendarDayNumber(isSelected: isSelected))
                .foregroundStyle(textColor)
                .frame(width: SuhoorCalendarMetrics.daySize, height: SuhoorCalendarMetrics.daySize)
                .background(baseBackground)
                .overlay(suggestedOutline)
                .overlay(todayRing)
                .overlay(unavailableSlash)
                .overlay(selectionOutline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
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
        if !isInDisplayedMonth {
            return .secondary
        }
        return .primary
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
        if !isInDisplayedMonth && !isSelected {
            return 0.55
        }
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
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
            Text(detail.gregorianText)
                .font(AppTypography.cardTitle)
            Text(detail.hijriText)
                .font(AppTypography.metricValue)
                .foregroundStyle(.secondary)

            if let selectionStatus {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text("Status")
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(.secondary)

                    Text(selectionStatus.title)
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(selectionStatus.color)

                    Text(selectionStatus.detailLabel)
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(.secondary)

                    Text(selectionStatus.reason)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }
            }

            if !detail.warnings.isEmpty {
                FlowLayout(spacing: DesignTokens.textSpacingCompact) {
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
                    .font(AppTypography.metricLabel)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: DesignTokens.textSpacingCompact) {
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
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            }

            if detail.isAlreadyActive, let sourceSummary = detail.activeSourceSummary {
                Text(sourceSummary)
                    .font(AppTypography.cardBody)
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
        .font(AppTypography.badge)
        .padding(.horizontal, DesignTokens.badgeHorizontalPadding)
        .padding(.vertical, DesignTokens.badgeVerticalPadding)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule(style: .continuous))
    }
}
