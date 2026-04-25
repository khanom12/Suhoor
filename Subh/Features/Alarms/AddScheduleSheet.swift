import SwiftUI

struct AddScheduleSheet: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastTagStore: FastTagStore

    @Binding var isPresented: Bool
    let onOpenExistingDay: (Date) -> Void

    @State private var mode: AddScheduleMode = .singleDay
    @State private var selectedDate = DateHelpers.startOfToday()
    @State private var singleDayDisplayedMonth = AddScheduleMonthView.monthStart(for: DateHelpers.startOfToday())
    @State private var rangeStartDate = DateHelpers.startOfToday()
    @State private var rangeEndDate = DateHelpers.startOfToday()
    @State private var rangeStartDisplayedMonth = AddScheduleMonthView.monthStart(for: DateHelpers.startOfToday())
    @State private var rangeEndDisplayedMonth = AddScheduleMonthView.monthStart(for: DateHelpers.startOfToday())
    @State private var singleDayTagSelection = FastIntentSelection.default
    @State private var rangePurposeSelection: RangePurposeSelection = .auto
    @State private var showsTagPicker = false
    @State private var showsAshuraPatternSheet = false
    @State private var rangePickerTarget: RangePickerTarget?

    init(
        isPresented: Binding<Bool>,
        onOpenExistingDay: @escaping (Date) -> Void,
        initialSelectedDate: Date? = nil
    ) {
        _isPresented = isPresented
        self.onOpenExistingDay = onOpenExistingDay

        let seedDate = DateHelpers.startOfDay(initialSelectedDate ?? DateHelpers.startOfToday(), in: .current)
        _selectedDate = State(initialValue: seedDate)
        _singleDayDisplayedMonth = State(initialValue: AddScheduleMonthView.monthStart(for: seedDate))
        _rangeStartDate = State(initialValue: seedDate)
        _rangeEndDate = State(initialValue: seedDate)
        _rangeStartDisplayedMonth = State(initialValue: AddScheduleMonthView.monthStart(for: seedDate))
        _rangeEndDisplayedMonth = State(initialValue: AddScheduleMonthView.monthStart(for: seedDate))
    }

    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(AddScheduleMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(modeHelperText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            }

            switch mode {
            case .singleDay:
                singleDayContent
            case .dateRange:
                dateRangeContent
            case .islamicDates:
                islamicDatesContent
            }

            if let disabledReason, mode != .islamicDates {
                Section {
                    Text(disabledReason)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.AddSchedule.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                if mode != .islamicDates {
                    Button(confirmActionTitle) { submitCurrentMode() }
                        .disabled(submitDisabled)
                }
            }
        }
        .sheet(isPresented: $showsTagPicker) {
            NavigationStack {
                FastTagPickerSheet(
                    date: selectedDate,
                    initialSelection: singleDayTagSelection,
                    seeds: scheduleManager.activeWindowSnapshot.visibleDays.map(\.tagSeed),
                    selections: fastTagStore.selections,
                    onSave: { selection in
                        singleDayTagSelection = selection
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsAshuraPatternSheet) {
            NavigationStack {
                AshuraQuickAddSheet(
                    onAdd: { pattern in
                        Task {
                            let result = await scheduleManager.addAshuraQuickAdd(pattern)
                            if let firstDate = result.addedDates.first {
                                onOpenExistingDay(firstDate)
                            }
                            if !result.addedDates.isEmpty {
                                showsAshuraPatternSheet = false
                                isPresented = false
                            }
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $rangePickerTarget) { target in
            NavigationStack {
                RangeCalendarPickerSheet(
                    title: target.title,
                    selectedDate: binding(for: target),
                    displayedMonth: displayedMonthBinding(for: target),
                    allowedDateRange: allowedDateRange(for: target),
                    detailSelection: rangePurposeSelection.selection(
                        for: target == .start ? rangeStartDate : rangeEndDate,
                        timeZone: .current
                    )
                )
            }
            .presentationDetents([.large])
        }
        .onAppear {
            syncSingleDaySelection(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            singleDayDisplayedMonth = AddScheduleMonthView.monthStart(for: newValue)
            syncSingleDaySelection(for: newValue)
        }
        .onChange(of: rangeStartDate) { _, newValue in
            let maxEndDate = maximumRangeEndDate(from: newValue)
            if rangeEndDate < newValue {
                rangeEndDate = newValue
            } else if rangeEndDate > maxEndDate {
                rangeEndDate = maxEndDate
            }
            rangeStartDisplayedMonth = AddScheduleMonthView.monthStart(for: newValue)
        }
        .onChange(of: rangeEndDate) { _, newValue in
            rangeEndDisplayedMonth = AddScheduleMonthView.monthStart(for: newValue)
        }
    }

    @ViewBuilder
    private var singleDayContent: some View {
        Section {
            AddScheduleMonthView(
                displayedMonth: $singleDayDisplayedMonth,
                selectedDate: $selectedDate,
                allowedDateRange: addableFutureDateRange
            )

            SuhoorCalendarDetailCard(detail: singleDayDetail, notScheduledText: "Available to add")

            if singleDayDetail.isAlreadyActive {
                Button("View Existing Day") {
                    onOpenExistingDay(selectedDate)
                    isPresented = false
                }
                .font(AppTypography.metricLabel)
            }
        }

        Section("Day Meaning") {
            Button {
                showsTagPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        Text("Edit day meaning")
                            .font(AppTypography.rowTitle)
                            .foregroundStyle(.primary)
                        Text(singleDayDetail.tagSummary)
                            .font(AppTypography.rowBody)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTypography.navAccessory)
                        .foregroundStyle(.tertiary)
                }
            }
        }

    }

    @ViewBuilder
    private var dateRangeContent: some View {
        Section {
            RangeSelectionCard(
                startTitle: "Start",
                startGregorian: rangeStartDetail.gregorianText,
                startHijri: rangeStartDetail.hijriText,
                endTitle: "End",
                endGregorian: rangeEndDetail.gregorianText,
                endHijri: rangeEndDetail.hijriText,
                onSelectStart: { rangePickerTarget = .start },
                onSelectEnd: { rangePickerTarget = .end }
            )
        } header: {
            Text("Dates")
        } footer: {
            Text(Strings.AddSchedule.rangeHelper)
        }

        Section("Day Meaning") {
            Picker("Purpose", selection: $rangePurposeSelection) {
                ForEach(RangePurposeSelection.allCases) { purpose in
                    Text(purpose.title).tag(purpose)
                }
            }

            Text(Strings.AddSchedule.purposeHelper)
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)

            DisclosureGroup(Strings.AddSchedule.detailsTitle) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(rangePurposeSelection.detailText)
                    Text("Secondary observance tags stay automatic and are derived per date after add.")
                }
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
                .padding(.top, DesignTokens.textSpacingTight)
            }
            .font(AppTypography.metricLabel)
            .foregroundStyle(.secondary)
        }

        Section("Range Preview") {
            RangePreviewGrid(
                total: rangePreview.totalSelectedCount,
                added: rangePreview.addedCount,
                skipped: rangePreview.skippedCount
            )

            Text(Strings.AddSchedule.rangePreviewFooter)
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var islamicDatesContent: some View {
        Section {
            InfoBanner(
                systemImage: "calendar.badge.clock",
                text: Strings.AddSchedule.hijriBanner
            ) {
                NavigationLink(Strings.AddSchedule.manageCorrections) {
                    HijriCalendarSettingsView()
                }
                .font(AppTypography.metricLabel)
            }
        }

        Section("Upcoming Once") {
            ForEach(IslamicQuickAddKind.addFlowVisibleCases) { kind in
                quickAddRow(for: kind)
            }
        }

        Section("Recurring") {
            InfoBanner(
                systemImage: "repeat",
                text: Strings.AddSchedule.recurringBanner
            )

            ForEach(RecurringIslamicRule.addFlowVisibleCases) { rule in
                recurringRuleRow(for: rule)
            }
        }
    }

    @ViewBuilder
    private func quickAddRow(for kind: IslamicQuickAddKind) -> some View {
        if kind == .nextAshura {
            ashuraQuickAddRow
        } else {
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
                    Task {
                        let result = await scheduleManager.addIslamicQuickAdd(kind)
                        if let firstDate = result.addedDates.first {
                            onOpenExistingDay(firstDate)
                        }
                        if !result.addedDates.isEmpty {
                            isPresented = false
                        }
                    }
                }
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
                    Task {
                        let added = await scheduleManager.addRecurringIslamicRule(rule)
                        guard added else { return }
                        if let firstDate = scheduleManager.activeWindowSnapshot.visibleDays.first(where: { day in
                            day.provenances.contains(where: { $0.sourceOrigin == .recurringIslamic(rule) })
                        })?.date {
                            onOpenExistingDay(firstDate)
                        }
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private var singleDayDetail: CalendarDayDetail {
        scheduleManager.calendarDayDetail(
            for: selectedDate,
            overrideSelection: singleDayTagSelection.hasMeaningfulTags ? singleDayTagSelection : nil
        )
    }

    private var rangeStartDetail: CalendarDayDetail {
        scheduleManager.calendarDayDetail(
            for: rangeStartDate,
            overrideSelection: rangePurposeSelection.selection(for: rangeStartDate, timeZone: .current)
        )
    }

    private var rangeEndDetail: CalendarDayDetail {
        scheduleManager.calendarDayDetail(
            for: rangeEndDate,
            overrideSelection: rangePurposeSelection.selection(for: rangeEndDate, timeZone: .current)
        )
    }

    private var rangePreview: AddScheduledDatesResult {
        scheduleManager.previewGregorianRangeAdd(startDate: rangeStartDate, endDate: rangeEndDate)
    }

    private var addableFutureDateRange: ClosedRange<Date> {
        DateHelpers.startOfToday()...Date.distantFuture
    }

    private var submitDisabled: Bool {
        switch mode {
        case .singleDay:
            return singleDayDetail.isAlreadyActive
        case .dateRange:
            return rangePreview.addedDates.isEmpty
        case .islamicDates:
            return true
        }
    }

    private var disabledReason: String? {
        guard submitDisabled else { return nil }
        switch mode {
        case .singleDay:
            return Strings.AddSchedule.disabledSingleDay
        case .dateRange:
            return Strings.AddSchedule.disabledRange
        case .islamicDates:
            return nil
        }
    }

    private var confirmActionTitle: String {
        switch mode {
        case .singleDay:
            return Strings.AddSchedule.addDay
        case .dateRange:
            return Strings.AddSchedule.addRange
        case .islamicDates:
            return Strings.AddSchedule.addDay
        }
    }

    private var modeHelperText: String {
        switch mode {
        case .singleDay:
            return Strings.AddSchedule.modeHelperSingleDay
        case .dateRange:
            return Strings.AddSchedule.modeHelperDateRange
        case .islamicDates:
            return Strings.AddSchedule.modeHelperIslamicDates
        }
    }

    private func submitCurrentMode() {
        switch mode {
        case .singleDay:
            Task {
                let result = await scheduleManager.addSingleScheduledDate(
                    selectedDate,
                    selection: singleDayTagSelection
                )
                if let firstDate = result.addedDates.first {
                    onOpenExistingDay(firstDate)
                    isPresented = false
                }
            }
        case .dateRange:
            Task {
                let result = await scheduleManager.addGregorianRange(
                    startDate: rangeStartDate,
                    endDate: rangeEndDate,
                    purpose: rangePurposeSelection
                )
                if let firstDate = result.addedDates.first {
                    onOpenExistingDay(firstDate)
                    isPresented = false
                }
            }
        case .islamicDates:
            break
        }
    }

    private func syncSingleDaySelection(for date: Date) {
        if let existing = fastTagStore.selection(for: date, timeZone: .current) {
            singleDayTagSelection = existing
        } else {
            singleDayTagSelection = FastIntentEngine.defaultAddFlowSelection(for: date, timeZone: .current)
        }
    }

    private func maximumRangeEndDate(from startDate: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(byAdding: .day, value: GregorianRangeSource.maxLengthDays - 1, to: startDate) ?? startDate
    }

    private func allowedDateRange(for target: RangePickerTarget) -> ClosedRange<Date> {
        switch target {
        case .start:
            return addableFutureDateRange
        case .end:
            return rangeStartDate...maximumRangeEndDate(from: rangeStartDate)
        }
    }

    private func binding(for target: RangePickerTarget) -> Binding<Date> {
        switch target {
        case .start:
            return $rangeStartDate
        case .end:
            return $rangeEndDate
        }
    }

    private func displayedMonthBinding(for target: RangePickerTarget) -> Binding<Date> {
        switch target {
        case .start:
            return $rangeStartDisplayedMonth
        case .end:
            return $rangeEndDisplayedMonth
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
        case .available:
            return AnyView(
                Button("Select") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            )
        case .partial:
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

struct AshuraQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let onAdd: (AshuraQuickAddPattern) -> Void

    var body: some View {
        Form {
            Section {
            Text("Subh recommends observing Ashura as a two-day pattern.")
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            }

            Section {
                let recommendedPattern = scheduleManager.recommendedAshuraQuickAddPattern()
                let availability = scheduleManager.ashuraQuickAddAvailability(recommendedPattern)
                Button(recommendedActionTitle(for: availability)) {
                    onAdd(recommendedPattern)
                }
                .buttonStyle(.borderedProminent)
                .disabled(availability.state == .disabled)
            }

            Section("Choose Pattern") {
                let recommendedPattern = scheduleManager.recommendedAshuraQuickAddPattern()
                let patterns = [recommendedPattern] + AshuraQuickAddPattern.allCases.filter { $0 != recommendedPattern }
                ForEach(patterns) { pattern in
                    ashuraPatternRow(pattern)
                }
            }
        }
        .navigationTitle("Next Ashura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func ashuraPatternRow(_ pattern: AshuraQuickAddPattern) -> some View {
        let availability = scheduleManager.ashuraQuickAddAvailability(pattern)

        VStack(alignment: .leading, spacing: DesignTokens.textSpacingRegular) {
            HStack(alignment: .top, spacing: DesignTokens.space12) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                    HStack(spacing: DesignTokens.inlineSpacingMedium) {
                        Text(pattern.title)
                            .font(AppTypography.rowTitle)
                        if availability.isRecommended {
                            Text("Recommended")
                                .font(AppTypography.badge)
                                .padding(.vertical, DesignTokens.accessoryInset + 1)
                                .padding(.horizontal, DesignTokens.badgeHorizontalPadding)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.16))
                                )
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(pattern.detailText)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(ashuraActionTitle(for: availability)) {
                    onAdd(pattern)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(availability.state == .disabled)
            }

            if let preview = availability.preview {
                Text(preview.previewText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                Text(preview.availabilityText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            }

            if let reasonText = availability.reasonText {
                Text(reasonText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(availability.state == .disabled ? Color.secondary : .orange)
            }
        }
        .padding(.vertical, DesignTokens.accessoryInset)
    }

    private func ashuraActionTitle(for availability: AshuraQuickAddAvailability) -> String {
        switch availability.state {
        case .available:
            return "Add"
        case .partial:
            return "Add Remaining"
        case .disabled:
            return "Added"
        }
    }

    private func recommendedActionTitle(for availability: AshuraQuickAddAvailability) -> String {
        switch availability.state {
        case .available:
            return "Add Recommended"
        case .partial:
            return "Add Recommended Remaining"
        case .disabled:
            return "Added"
        }
    }
}

private enum AddScheduleMode: String, CaseIterable, Identifiable {
    case singleDay
    case dateRange
    case islamicDates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singleDay:
            return "Single Day"
        case .dateRange:
            return "Date Range"
        case .islamicDates:
            return "Islamic Dates"
        }
    }
}

private enum RangePickerTarget: String, Identifiable {
    case start
    case end

    var id: String { rawValue }

    var title: String {
        switch self {
        case .start:
            return "Start Date"
        case .end:
            return "End Date"
        }
    }
}

private struct RangeCalendarPickerSheet: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let allowedDateRange: ClosedRange<Date>
    let detailSelection: FastIntentSelection?

    var body: some View {
        VStack(spacing: 0) {
            AddScheduleMonthView(
                displayedMonth: $displayedMonth,
                selectedDate: $selectedDate,
                allowedDateRange: allowedDateRange,
            )
            .padding(.top, DesignTokens.spacingS)

            SuhoorCalendarDetailCard(
                detail: scheduleManager.calendarDayDetail(
                    for: selectedDate,
                    overrideSelection: detailSelection
                ),
                notScheduledText: "Available to add"
            )
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingM)

            Spacer(minLength: 0)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct AddScheduleMonthView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let allowedDateRange: ClosedRange<Date>

    var body: some View {
        SuhoorCalendarView(
            displayedMonth: $displayedMonth,
            focusedDate: $selectedDate,
            selectedDate: selectedDate,
            allowedDateRange: allowedDateRange,
            onSelectDate: { selectedDate = $0 }
        )
    }

    static func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? DateHelpers.startOfToday()
    }
}

private struct RangeSelectionCard: View {
    let startTitle: String
    let startGregorian: String
    let startHijri: String
    let endTitle: String
    let endGregorian: String
    let endHijri: String
    let onSelectStart: () -> Void
    let onSelectEnd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            rangeRow(title: startTitle, gregorian: startGregorian, hijri: startHijri, action: onSelectStart)
            Divider()
            rangeRow(title: endTitle, gregorian: endGregorian, hijri: endHijri, action: onSelectEnd)
        }
        .padding(.vertical, DesignTokens.textSpacingCompact)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func rangeRow(title: String, gregorian: String, hijri: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                    Text(title)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(.primary)
                    Text(gregorian)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                    Text(hijri)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(AppTypography.controlIcon)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, DesignTokens.compactRowVerticalPadding)
            .padding(.horizontal, DesignTokens.spacingM)
        }
        .buttonStyle(.plain)
    }
}

private struct RangePreviewGrid: View {
    let total: Int
    let added: Int
    let skipped: Int

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            previewCell(title: "Total", value: total, accent: .secondary)
            Divider()
            previewCell(title: "Will add", value: added, accent: added == 0 ? .secondary : .primary)
            Divider()
            previewCell(title: "Already active", value: skipped, accent: skipped == 0 ? .secondary : .orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.textSpacingTight)
    }

    private func previewCell(title: String, value: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
            Text(title)
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(AppTypography.summaryMetricValue)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CalendarSelectionButton: View {
    let title: String
    let gregorianText: String
    let hijriText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                    Text(title)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(.primary)
                    Text(gregorianText)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                    Text(hijriText)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(AppTypography.controlIcon)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
