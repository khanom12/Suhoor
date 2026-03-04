import SwiftUI

struct PlanCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var displayedMonth = DateHelpers.startOfToday()
    @State private var selectedDate = DateHelpers.startOfToday()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let context = scheduleManager.calendarMonthContext(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            allowedDateRange: allowedRange
        )

        ScrollView {
            VStack(spacing: DesignTokens.spacingL) {
                calendarHeader(monthTitle: context.monthTitle)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(context.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(context.dayStates) { state in
                        PlanCalendarDayView(
                            state: state,
                            isForbidden: FastIntentEngine.isForbiddenToFast(state.date, timeZone: .current),
                            isRamadan: FastIntentEngine.isRamadan(state.date, timeZone: .current),
                            isSelected: Calendar.current.isDate(state.date, inSameDayAs: selectedDate)
                        ) {
                            guard !state.isDisabled else { return }
                            selectedDate = state.date
                        }
                    }
                }

                PlanCalendarDetailCard(
                    detail: scheduleManager.calendarDayDetail(for: selectedDate)
                )
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
    }

    private var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
    }

    private func calendarHeader(monthTitle: String) -> some View {
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

            Text(monthTitle)
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
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
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
        return monthEnd >= allowedRange.lowerBound && monthStart <= allowedRange.upperBound
    }

    private func nextRamadanStart() -> Date {
        let calendar = AdjustedHijriCalendar.shared
        let now = Date()
        let components = calendar.adjustedComponents(for: now, timeZone: .current)
        let targetYear: Int
        if let components {
            if components.month == .ramadan {
                targetYear = components.hijriYear + 1
            } else if components.month.rawValue < HijriMonth.ramadan.rawValue {
                targetYear = components.hijriYear
            } else {
                targetYear = components.hijriYear + 1
            }
        } else {
            targetYear = Calendar(identifier: .islamicUmmAlQura).component(.year, from: now) + 1
        }
        let key = HijriYearMonth(hijriYear: targetYear, month: .ramadan)
        return calendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: .current) ?? now
    }
}

private struct PlanCalendarDayView: View {
    let state: CalendarDayState
    let isForbidden: Bool
    let isRamadan: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(state.dayNumberText)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
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
                        .fill(isForbidden ? DawnColor.danger : .clear)
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(isRamadan ? DawnColor.highlight : .clear)
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
            .fill(isSelected ? DawnColor.accent.opacity(0.18) : Color.clear)
    }

    private var selectionOutline: some View {
        Circle()
            .stroke(borderColor, lineWidth: isSelected || state.isAlreadyActive || state.isToday ? 1.2 : 0.6)
    }

    private var borderColor: Color {
        if isSelected {
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
        if isSelected {
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
            parts.append("Scheduled")
        }
        if isForbidden {
            parts.append("Forbidden")
        }
        if isRamadan {
            parts.append("Ramadan")
        }
        if isSelected {
            parts.append("Selected")
        }
        return parts.joined(separator: ", ")
    }
}

private struct PlanCalendarDetailCard: View {
    let detail: CalendarDayDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.gregorianText)
                .font(.headline.weight(.semibold))
            Text(detail.hijriText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                PillBadge(
                    text: detail.isAlreadyActive ? "Scheduled" : "Not scheduled",
                    style: detail.isAlreadyActive ? .custom : .default
                )
                Spacer()
            }

            if detail.isAlreadyActive, let sourceSummary = detail.activeSourceSummary {
                Text(sourceSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(detail.tagSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.spacingM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
