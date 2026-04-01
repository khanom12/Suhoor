import SwiftUI

struct PlanCalendarView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var selectedDate = DateHelpers.startOfToday()
    @State private var showsAddSheet = false
    @State private var selectedSchedule: DaySchedule?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    Text("Choose a date")
                        .font(AppTypography.cardTitle)

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: allowedRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }

                GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.14) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                            Text(detail.gregorianText)
                                .font(AppTypography.cardTitle)
                            Text(detail.hijriText)
                                .font(AppTypography.cardBody)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                            Text(existingSchedule == nil ? "No special plan yet" : "Morning already shaped")
                                .font(AppTypography.rowTitle)
                            Text(detail.tagSummary)
                                .font(AppTypography.rowBody)
                                .foregroundStyle(.secondary)
                            if let activeSourceSummary = detail.activeSourceSummary {
                                Text(activeSourceSummary)
                                    .font(AppTypography.rowBody)
                                    .foregroundStyle(.secondary)
                            }
                            if let warning = detail.warnings.first {
                                Text(warning.title)
                                    .font(AppTypography.metricLabel)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                    Button(primaryActionTitle) {
                        if let existingSchedule {
                            selectedSchedule = existingSchedule
                        } else {
                            showsAddSheet = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DawnColor.accent)
                    .disabled(primaryActionDisabled)

                    Text(primaryActionSubtitle)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .navigationTitle("Plan by Date")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showsAddSheet) {
            NavigationStack {
                AddScheduleSheet(
                    isPresented: $showsAddSheet,
                    onOpenExistingDay: { date in
                        selectedDate = date
                        selectedSchedule = scheduleManager.schedule(for: date)
                    },
                    initialSelectedDate: selectedDate
                )
            }
        }
        .sheet(item: $selectedSchedule) { schedule in
            NavigationStack {
                AlarmDayDetailView(schedule: schedule)
            }
        }
    }

    private var detail: CalendarDayDetail {
        scheduleManager.calendarDayDetail(for: normalizedSelectedDate)
    }

    private var existingSchedule: DaySchedule? {
        scheduleManager.schedule(for: normalizedSelectedDate)
    }

    private var normalizedSelectedDate: Date {
        DateHelpers.startOfDay(selectedDate, in: .current)
    }

    private var primaryActionTitle: String {
        existingSchedule == nil ? "Plan this date" : "Open this morning"
    }

    private var primaryActionSubtitle: String {
        if existingSchedule == nil {
            if let warning = detail.warnings.first {
                return warning.about.subtitle ?? warning.about.title
            }
            return "Create a one-day plan for this morning."
        }
        return "Inspect or adjust the wake, meaning, and one-day settings."
    }

    private var primaryActionDisabled: Bool {
        existingSchedule == nil && !detail.warnings.isEmpty
    }

    private var allowedRange: ClosedRange<Date> {
        let start = DateHelpers.startOfToday()
        let end = nextRamadanStart().addingTimeInterval(-24 * 60 * 60)
        return start...max(start, end)
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
