import SwiftUI

struct PlanSunnahView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var showsAshuraPatternSheet = false

    var body: some View {
        List {
            Section {
                InfoBanner(
                    systemImage: "calendar.badge.clock",
                    text: "Plan upcoming Sunnah observances with your Hijri corrections."
                ) {
                    NavigationLink("Manage corrections") {
                        HijriCalendarSettingsView()
                    }
                    .font(.footnote.weight(.semibold))
                }
            }

            Section("Upcoming Once") {
                ashuraQuickAddRow
                quickAddRow(for: .nextArafah)
                quickAddRow(for: .nextWhiteDays)
                quickAddRow(for: .nextMondayThursdayPair)
            }

            Section("Recurring") {
                ForEach(RecurringIslamicRule.addFlowVisibleCases) { rule in
                    recurringRuleRow(for: rule)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sunnah Observances")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showsAshuraPatternSheet) {
            NavigationStack {
                AshuraQuickAddSheet(
                    onAdd: { pattern in
                        Task {
                            _ = await scheduleManager.addAshuraQuickAdd(pattern)
                            showsAshuraPatternSheet = false
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func quickAddRow(for kind: IslamicQuickAddKind) -> some View {
        let availability = scheduleManager.islamicQuickAddAvailability(kind)
        let statusLine = quickAddStatusLine(
            previewDates: availability.preview?.dates ?? [],
            state: availability.state,
            fallback: availability.reasonText
        )
        QuickAddCard(
            title: kind.title,
            description: kind.detailText,
            previewLine: compactPreviewLine(for: availability.preview?.dates),
            statusLine: statusLine
        ) {
            actionView(for: availability) {
                Task { _ = await scheduleManager.addIslamicQuickAdd(kind) }
            }
        }
    }

    private var ashuraQuickAddRow: some View {
        let recommendedPattern = scheduleManager.recommendedAshuraQuickAddPattern()
        let availability = scheduleManager.ashuraQuickAddAvailability(recommendedPattern)
        let statusLine = quickAddStatusLine(
            previewDates: availability.preview?.dates ?? [],
            state: availability.state,
            fallback: availability.reasonText
        )

        return QuickAddCard(
            title: IslamicQuickAddKind.nextAshura.title,
            description: IslamicQuickAddKind.nextAshura.detailText,
            previewLine: compactPreviewLine(for: availability.preview?.dates),
            statusLine: statusLine,
            leadingAccessory: {
                PillBadge(text: "Recommended", style: .custom)
            },
            action: {
                actionView(for: availability) {
                    showsAshuraPatternSheet = true
                }
            }
        )
    }

    private func recurringRuleRow(for rule: RecurringIslamicRule) -> some View {
        let status = scheduleManager.recurringRuleStatus(rule)
        return QuickAddCard(
            title: rule.title,
            description: rule.detailText,
            statusLine: status.detailText
        ) {
            if status.isAdded {
                PillBadge(text: "Added", style: .off)
            } else {
                Button("Add") {
                    Task { _ = await scheduleManager.addRecurringIslamicRule(rule) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private func actionTitle(for availability: IslamicQuickAddAvailability) -> String {
        switch availability.state {
        case .available:
            return "Add"
        case .partial:
            return "Add Remaining"
        case .disabled:
            return "Added"
        }
    }

    private func actionView(for availability: IslamicQuickAddAvailability, action: @escaping () -> Void) -> some View {
        switch availability.state {
        case .disabled:
            return AnyView(PillBadge(text: "Added", style: .off))
        case .available, .partial:
            return AnyView(
                Button(actionTitle(for: availability)) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            )
        }
    }

    private func actionView(for availability: AshuraQuickAddAvailability, action: @escaping () -> Void) -> some View {
        switch availability.state {
        case .disabled:
            return AnyView(PillBadge(text: "Added", style: .off))
        case .available, .partial:
            return AnyView(
                Button("Select") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            )
        }
    }

    private func compactPreviewLine(for dates: [Date]?) -> String? {
        guard let dates, !dates.isEmpty else { return nil }
        let gregorian = dates
            .map { GregorianDateFormatter.shared.headerString(for: $0) }
            .joined(separator: " · ")
        guard let hijri = compactHijriSummary(for: dates) else { return gregorian }
        return "\(gregorian) (\(hijri))"
    }

    private func compactHijriSummary(for dates: [Date]) -> String? {
        let components = dates.compactMap { AdjustedHijriCalendar.shared.adjustedComponents(for: $0, timeZone: .current) }
        guard components.count == dates.count else { return nil }
        guard let first = components.first else { return nil }

        let sameMonth = components.allSatisfy {
            $0.hijriYear == first.hijriYear && $0.month == first.month
        }

        if sameMonth {
            let days = components.map(\.day).sorted()
            let isSequential = zip(days, days.dropFirst()).allSatisfy { current, next in next == current + 1 }
            if let firstDay = days.first, let lastDay = days.last {
                let dayText = (isSequential && days.count > 1) ? "\(firstDay)-\(lastDay)" : days.map(String.init).joined(separator: ", ")
                return "\(dayText) \(first.month.displayName) \(first.hijriYear)"
            }
        }

        return components
            .map { "\($0.day) \($0.month.displayName) \($0.hijriYear)" }
            .joined(separator: " · ")
    }

    private func quickAddStatusLine(
        previewDates: [Date],
        state: IslamicQuickAddAvailabilityState,
        fallback: String?
    ) -> String? {
        switch state {
        case .available:
            return fallback == Strings.AddSchedule.previewUnavailable ? fallback : nil
        case .partial:
            return someActiveDatesCoveredByRecurring(previewDates)
                ? Strings.AddSchedule.someDatesAlreadyCovered
                : Strings.AddSchedule.someAlreadyActive
        case .disabled:
            return allActiveDatesCoveredByRecurring(previewDates)
                ? Strings.AddSchedule.alreadyActiveThroughRecurring
                : (fallback ?? Strings.AddSchedule.allMatchingDatesActive)
        }
    }

    private func someActiveDatesCoveredByRecurring(_ dates: [Date]) -> Bool {
        let activeDates = dates.filter { !scheduleManager.provenance(for: $0, timeZone: .current).isEmpty }
        guard !activeDates.isEmpty else { return false }
        return activeDates.contains { date in
            scheduleManager.provenance(for: date, timeZone: .current).contains {
                if case .recurringIslamic = $0.sourceOrigin {
                    return true
                }
                return false
            }
        }
    }

    private func allActiveDatesCoveredByRecurring(_ dates: [Date]) -> Bool {
        let activeDates = dates.filter { !scheduleManager.provenance(for: $0, timeZone: .current).isEmpty }
        guard activeDates.isEmpty == false else { return false }
        return activeDates.allSatisfy { date in
            scheduleManager.provenance(for: date, timeZone: .current).contains {
                if case .recurringIslamic = $0.sourceOrigin {
                    return true
                }
                return false
            }
        }
    }
}
