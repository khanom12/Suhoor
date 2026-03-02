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

    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(AddScheduleMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch mode {
            case .singleDay:
                singleDayContent
            case .dateRange:
                dateRangeContent
            case .islamicDates:
                islamicDatesContent
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                if mode != .islamicDates {
                    Button("Add") { submitCurrentMode() }
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
                allowedDateRange: addableFutureDateRange,
                context: singleDayMonthContext
            )

            CalendarSelectionDetailCard(detail: singleDayDetail)
        }

        Section("Purpose") {
            Button {
                showsTagPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Tags")
                            .foregroundStyle(.primary)
                        Text(singleDayDetail.tagSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }

        if singleDayDetail.isAlreadyActive {
            Section("Already Active") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This day is already active.")
                        .font(.footnote.weight(.semibold))
                    if let sourceSummary = singleDayDetail.activeSourceSummary {
                        Text("Source: \(sourceSummary)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button("View Existing Day") {
                        onOpenExistingDay(selectedDate)
                        isPresented = false
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
    }

    @ViewBuilder
    private var dateRangeContent: some View {
        Section {
            CalendarSelectionButton(
                title: "Start date",
                gregorianText: rangeStartDetail.gregorianText,
                hijriText: rangeStartDetail.hijriText
            ) {
                rangePickerTarget = .start
            }

            CalendarSelectionButton(
                title: "End date",
                gregorianText: rangeEndDetail.gregorianText,
                hijriText: rangeEndDetail.hijriText
            ) {
                rangePickerTarget = .end
            }
        } header: {
            Text("Dates")
        }

        Section("Purpose") {
            Picker("Purpose", selection: $rangePurposeSelection) {
                ForEach(RangePurposeSelection.allCases) { purpose in
                    Text(purpose.title).tag(purpose)
                }
            }

            Text(rangePurposeSelection.detailText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Secondary observance tags stay automatic and are derived per date after add.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Section("Range Preview") {
            LabeledContent("Total selected") {
                Text("\(rangePreview.totalSelectedCount)")
            }
            LabeledContent("Will add") {
                Text("\(rangePreview.addedCount)")
                    .foregroundStyle(rangePreview.addedCount == 0 ? .secondary : .primary)
            }
            LabeledContent("Already active") {
                Text("\(rangePreview.skippedCount)")
                    .foregroundStyle(rangePreview.skippedCount == 0 ? Color.secondary : .orange)
            }

            Text("Dates already active, including Ramadan, are skipped automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var islamicDatesContent: some View {
        Section {
            Text("Use corrected Hijri dates for upcoming one-time adds or recurring presets. Ramadan remains automatic.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Section("Upcoming Once") {
            ForEach(IslamicQuickAddKind.addFlowVisibleCases) { kind in
                quickAddRow(for: kind)
            }
        }

        Section("Recurring") {
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.title)
                            .font(.body.weight(.medium))
                        Text(kind.detailText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(actionTitle(for: availability)) {
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
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(availability.state == .disabled)
                }

                if let preview = availability.preview {
                    Text(preview.previewText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(preview.availabilityText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let reasonText = availability.reasonText {
                    Text(reasonText)
                        .font(.footnote)
                        .foregroundStyle(availability.state == .disabled ? Color.secondary : .orange)
                }
            }
        }
    }

    private var ashuraQuickAddRow: some View {
        let recommendedPattern = scheduleManager.recommendedAshuraQuickAddPattern()
        let availability = scheduleManager.ashuraQuickAddAvailability(recommendedPattern)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(IslamicQuickAddKind.nextAshura.title)
                        .font(.body.weight(.medium))
                    Text("Choose a recommended two-day Ashura pair, or explicitly add all three dates.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Recommended: \(recommendedPattern.title)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button("Select") {
                    showsAshuraPatternSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let preview = availability.preview {
                Text(preview.previewText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(preview.availabilityText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let reasonText = availability.reasonText {
                Text(reasonText)
                    .font(.footnote)
                    .foregroundStyle(availability.state == .disabled ? Color.secondary : .orange)
            }
        }
    }

    private func recurringRuleRow(for rule: RecurringIslamicRule) -> some View {
        let status = scheduleManager.recurringRuleStatus(rule)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.body.weight(.medium))
                Text(rule.detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let detailText = status.detailText {
                    Text(detailText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(status.isAdded ? "Added" : "Add") {
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
            .disabled(status.isAdded)
        }
    }

    private var singleDayMonthContext: CalendarMonthContext {
        scheduleManager.calendarMonthContext(
            displayedMonth: singleDayDisplayedMonth,
            selectedDate: selectedDate,
            allowedDateRange: addableFutureDateRange
        )
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
}

private struct AshuraQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let onAdd: (AshuraQuickAddPattern) -> Void

    var body: some View {
        Form {
            Section {
                Text("Suhoor recommends observing Ashura as a two-day pattern. The app does not recommend 10 Muharram alone as the default quick add.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Choose Pattern") {
                ForEach(AshuraQuickAddPattern.allCases) { pattern in
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

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(pattern.title)
                            .font(.body.weight(.medium))
                        if availability.isRecommended {
                            Text("Recommended")
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.16))
                                )
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(pattern.detailText)
                        .font(.footnote)
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
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(preview.availabilityText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let reasonText = availability.reasonText {
                Text(reasonText)
                    .font(.footnote)
                    .foregroundStyle(availability.state == .disabled ? Color.secondary : .orange)
            }
        }
        .padding(.vertical, 2)
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
                context: scheduleManager.calendarMonthContext(
                    displayedMonth: displayedMonth,
                    selectedDate: selectedDate,
                    allowedDateRange: allowedDateRange
                )
            )
            .padding(.top, DesignTokens.spacingS)

            CalendarSelectionDetailCard(
                detail: scheduleManager.calendarDayDetail(
                    for: selectedDate,
                    overrideSelection: detailSelection
                )
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
    let context: CalendarMonthContext

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: DesignTokens.spacingM) {
            HStack {
                Button {
                    displayedMonth = Self.shiftMonth(displayedMonth, by: -1)
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
                    displayedMonth = Self.shiftMonth(displayedMonth, by: 1)
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
                    CalendarDayCell(state: state) {
                        guard !state.isDisabled else { return }
                        selectedDate = state.date
                        if state.isInDisplayedMonth == false {
                            displayedMonth = Self.monthStart(for: state.date)
                        }
                    }
                }
            }
        }
    }

    static func monthStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? DateHelpers.startOfToday()
    }

    private static func shiftMonth(_ date: Date, by value: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let monthStart = monthStart(for: date)
        return calendar.date(byAdding: .month, value: value, to: monthStart) ?? monthStart
    }

    private var canMoveToPreviousMonth: Bool {
        let previousMonth = Self.shiftMonth(displayedMonth, by: -1)
        return monthIntersectsAllowedRange(previousMonth)
    }

    private var canMoveToNextMonth: Bool {
        let nextMonth = Self.shiftMonth(displayedMonth, by: 1)
        return monthIntersectsAllowedRange(nextMonth)
    }

    private func monthIntersectsAllowedRange(_ month: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let monthStart = Self.monthStart(for: month)
        guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return false
        }
        return monthEnd >= allowedDateRange.lowerBound && monthStart <= allowedDateRange.upperBound
    }
}

private struct CalendarDayCell: View {
    let state: CalendarDayState
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(state.dayNumberText)
                    .font(.footnote.weight(state.isSelected ? .semibold : .regular))
                    .foregroundStyle(textColor)
                    .frame(width: 34, height: 34)
                    .background(background)
                    .overlay(selectionOutline)

                Circle()
                    .fill(state.isAlreadyActive ? DawnColor.accent : .clear)
                    .frame(width: 5, height: 5)
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
            return DawnColor.accentPressed
        }
        if state.isInDisplayedMonth {
            return .primary
        }
        return .secondary
    }

    private var accessibilityLabel: String {
        var parts = [GregorianDateFormatter.shared.headerString(for: state.date)]
        if state.isAlreadyActive {
            parts.append("Already active")
        }
        if state.isDisabled {
            parts.append("Unavailable")
        }
        return parts.joined(separator: ", ")
    }
}

private struct CalendarSelectionDetailCard: View {
    let detail: CalendarDayDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.gregorianText)
                .font(.headline.weight(.semibold))
            Text(detail.hijriText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if detail.isAlreadyActive {
                Text("Already active")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DawnColor.accentPressed)
                if let sourceSummary = detail.activeSourceSummary {
                    Text(sourceSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Available to add")
                    .font(.footnote.weight(.semibold))
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

private struct CalendarSelectionButton: View {
    let title: String
    let gregorianText: String
    let hijriText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(gregorianText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(hijriText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
