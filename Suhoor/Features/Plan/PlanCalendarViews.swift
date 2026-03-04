import SwiftUI

struct PlanCalendarDayState: Identifiable, Hashable {
    let date: Date
    let dayNumberText: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isDisabled: Bool
    let isAlreadyActive: Bool
    let isRecommended: Bool
    let hijriText: String

    var id: String {
        DateHelpers.dayIdentifier(for: date, timeZone: .current)
    }
}

struct PlanCalendarMonthContext {
    let monthTitle: String
    let weekdaySymbols: [String]
    let dayStates: [PlanCalendarDayState]
}

struct PlanMultiSelectCalendar: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @Binding var displayedMonth: Date
    let allowedDateRange: ClosedRange<Date>
    let selectedDateKeys: Set<String>
    let recommendedDateKeys: Set<String>
    let disablesAlreadyActive: Bool
    let isSelectable: (Date) -> Bool
    let onToggle: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let context = monthContext()

        VStack(spacing: DesignTokens.spacingM) {
            HStack {
                Button {
                    displayedMonth = shiftMonth(displayedMonth, by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(canMoveToPreviousMonth ? .primary : .tertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveToPreviousMonth)

                Spacer()

                Text(context.monthTitle)
                    .font(.headline.weight(.semibold))

                Spacer()

                Button {
                    displayedMonth = shiftMonth(displayedMonth, by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(canMoveToNextMonth ? .primary : .tertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canMoveToNextMonth)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(context.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(context.dayStates) { state in
                    PlanCalendarDayCell(state: state) {
                        guard !state.isDisabled else { return }
                        onToggle(state.date)
                    }
                }
            }
        }
    }

    private func monthContext() -> PlanCalendarMonthContext {
        let baseContext = scheduleManager.calendarMonthContext(
            displayedMonth: displayedMonth,
            selectedDate: displayedMonth,
            allowedDateRange: allowedDateRange
        )
        let updatedStates = baseContext.dayStates.map { base -> PlanCalendarDayState in
            let key = DateHelpers.dayIdentifier(for: base.date, timeZone: .current)
            let isSelected = selectedDateKeys.contains(key)
            let isRecommended = recommendedDateKeys.contains(key)
            let isActive = base.isAlreadyActive
            let disabledByPolicy = !isSelectable(base.date)
            let isDisabled = base.isDisabled || disabledByPolicy || (disablesAlreadyActive && isActive)
            return PlanCalendarDayState(
                date: base.date,
                dayNumberText: base.dayNumberText,
                isInDisplayedMonth: base.isInDisplayedMonth,
                isToday: base.isToday,
                isSelected: isSelected,
                isDisabled: isDisabled,
                isAlreadyActive: isActive,
                isRecommended: isRecommended,
                hijriText: base.hijriText
            )
        }
        return PlanCalendarMonthContext(
            monthTitle: baseContext.monthTitle,
            weekdaySymbols: baseContext.weekdaySymbols,
            dayStates: updatedStates
        )
    }

    private func shiftMonth(_ date: Date, by value: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let monthStart = monthStart(for: date)
        return calendar.date(byAdding: .month, value: value, to: monthStart) ?? monthStart
    }

    private func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? DateHelpers.startOfToday()
    }

    private var canMoveToPreviousMonth: Bool {
        let previousMonth = shiftMonth(displayedMonth, by: -1)
        return monthIntersectsAllowedRange(previousMonth)
    }

    private var canMoveToNextMonth: Bool {
        let nextMonth = shiftMonth(displayedMonth, by: 1)
        return monthIntersectsAllowedRange(nextMonth)
    }

    private func monthIntersectsAllowedRange(_ month: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let monthStart = monthStart(for: month)
        guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return false
        }
        return monthEnd >= allowedDateRange.lowerBound && monthStart <= allowedDateRange.upperBound
    }
}

private struct PlanCalendarDayCell: View {
    let state: PlanCalendarDayState
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(state.dayNumberText)
                    .font(.subheadline.weight(state.isSelected ? .semibold : .medium))
                    .foregroundStyle(textColor)
                    .frame(width: 34, height: 34)
                    .background(background)
                    .overlay(selectionOutline)

                HStack(spacing: 4) {
                    Circle()
                        .fill(state.isToday ? Color.primary.opacity(0.5) : .clear)
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(state.isAlreadyActive ? DawnColor.accent : .clear)
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(state.isRecommended ? DawnColor.gold500 : .clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(state.isDisabled ? 0.35 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var background: some View {
        Circle()
            .fill(state.isSelected ? DawnColor.accent.opacity(0.18) : Color.clear)
    }

    private var selectionOutline: some View {
        Circle()
            .stroke(borderColor, lineWidth: state.isSelected || state.isAlreadyActive || state.isToday ? 1.2 : 0.6)
    }

    private var borderColor: Color {
        if state.isSelected {
            return DawnColor.accent
        }
        if state.isAlreadyActive {
            return DawnColor.highlight.opacity(0.7)
        }
        if state.isToday {
            return Color.primary.opacity(0.45)
        }
        return Color.clear
    }

    private var textColor: Color {
        if state.isSelected {
            return DawnColor.accent
        }
        if state.isDisabled {
            return .secondary
        }
        return .primary
    }

    private var accessibilityLabel: String {
        let gregorian = GregorianDateFormatter.shared.headerString(for: state.date)
        let hijri = state.hijriText
        var parts = [gregorian, hijri]
        if state.isAlreadyActive {
            parts.append("Already scheduled")
        }
        if state.isRecommended {
            parts.append("Recommended")
        }
        if state.isSelected {
            parts.append("Selected")
        }
        return parts.joined(separator: ", ")
    }
}
