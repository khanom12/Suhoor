import SwiftUI

private enum QadaWizardInfoSheet: Identifiable {
    case protectedDays

    var id: String {
        switch self {
        case .protectedDays:
            return "protectedDays"
        }
    }
}

struct QadaPlanWizardView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var qadaBatchStore: QadaBatchStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: QadaPlanWizardViewModel
    @State private var activeInfoSheet: QadaWizardInfoSheet?
    @State private var showsSummaryDetails = false

    private let onBack: (() -> Void)?

    init(
        launchMode: QadaWizardLaunchMode = .fresh,
        onBack: (() -> Void)? = nil
    ) {
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: QadaPlanWizardViewModel(launchMode: launchMode))
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                    Color.clear
                        .frame(height: 1)
                        .id("qada-wizard-top")

                    Group {
                        switch viewModel.step {
                        case .setup:
                            setupContent
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .review:
                            reviewContent
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, viewModel.step == .review ? 120 : 112)
            }
            .background(Color.clear)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        handleBack()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.24), value: viewModel.step)
            .animation(.easeInOut(duration: 0.24), value: viewModel.setupPage)
            .safeAreaInset(edge: .bottom) {
                if viewModel.step == .review {
                    reviewBottomBar
                } else {
                    setupBottomBar
                }
            }
            .sheet(isPresented: $viewModel.isShowingSuccess) {
                successSheet
                    .presentationDetents([.medium])
            }
            .sheet(item: $activeInfoSheet) { sheet in
                infoSheet(sheet)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.isShowingDateDetail, onDismiss: {
                viewModel.dismissDateDetail()
            }) {
                if let detail = viewModel.detailCardData() {
                    dateDetailSheet(detail)
                        .presentationDetents([.height(280), .medium])
                }
            }
            .onChange(of: viewModel.scrollResetToken) { _, _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    reader.scrollTo("qada-wizard-top", anchor: .top)
                }
            }
            .onChange(of: viewModel.shouldDismissFlow) { _, shouldDismiss in
                guard shouldDismiss else { return }
                dismiss()
            }
            .onAppear {
                viewModel.configure(
                    scheduleManager: scheduleManager,
                    alarmConfigStore: alarmConfigStore,
                    fastTagStore: fastTagStore,
                    fastLogStore: fastLogStore,
                    qadaBacklogStore: qadaBacklogStore,
                    qadaBatchStore: qadaBatchStore
                )
            }
        }
    }

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            setupIntro

            switch viewModel.setupPage {
            case .intake:
                intakePage
            case .pace:
                pacePage
            case .preferences:
                preferencesPage
            }
        }
    }

    private var setupIntro: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                pageIndicators
                Text(viewModel.setupProgressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.setupTitle)
                .font(.title2.weight(.semibold))

            Text(viewModel.setupSubtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var intakePage: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            if let suggestion = viewModel.backlogSuggestion, draftCountIsEmpty {
                GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.1) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("We found \(suggestion.suggestedOwed) missed fast\(suggestion.suggestedOwed == 1 ? "" : "s") from your Ramadan check-ins.")
                            .font(.subheadline.weight(.semibold))
                        Text("Use this as your starting count, or enter your own total below.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Use \(suggestion.suggestedOwed)") {
                            viewModel.useSuggestedBacklog()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DawnColor.accent)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        sectionLabel("Fasts to make up")
                        Spacer()
                    }

                    Stepper(value: Binding(
                        get: { viewModel.draft.baselineOwed },
                        set: viewModel.updateBaselineOwed
                    ), in: 0...366) {
                        HStack {
                            Text("Total to make up")
                            Spacer()
                            Text("\(viewModel.draft.baselineOwed)")
                                .font(.headline.weight(.semibold))
                        }
                    }

                    if let progressLine = viewModel.progressLineText {
                        Text(progressLine)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Start with the best total you know. You can adjust it later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    if let helper = viewModel.intakeSuggestionHelperText {
                        Text(helper)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var pacePage: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(QadaPlanPace.allCases) { pace in
                QadaPaceCard(
                    pace: pace,
                    isSelected: viewModel.draft.pace == pace,
                    action: { viewModel.updatePace(pace) }
                )
            }
        }
    }

    private var preferencesPage: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        sectionLabel("Keep these dates free")
                        Spacer()
                        Button {
                            activeInfoSheet = .protectedDays
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(viewModel.protectedDatesHelperText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Keep Shawwal free (for the 6 fasts)", isOn: Binding(
                        get: { viewModel.draft.avoidShawwal },
                        set: viewModel.updateAvoidShawwal
                    ))

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Keep important Sunnah fasts separate", isOn: Binding(
                            get: { viewModel.draft.avoidImportantSunnah },
                            set: viewModel.updateAvoidImportantSunnah
                        ))

                        Text("Arafah, Ashura, White Days, Dhul Hijjah…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("Plan this batch")

                    Stepper(value: Binding(
                        get: { viewModel.draft.planBatchCount },
                        set: viewModel.updatePlanBatchCount
                    ), in: 1...viewModel.maxPlanBatchCount) {
                        HStack {
                            Text("How many fasts")
                            Spacer()
                            Text("\(viewModel.draft.planBatchCount)")
                                .font(.headline.weight(.semibold))
                        }
                    }

                    Text(viewModel.batchRecommendationText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let estimatedFinish = viewModel.estimatedBatchFinishText {
                        Text("Estimated finish for this batch: \(estimatedFinish)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            summaryCard

            if let fallback = viewModel.fallbackDisplayCopy {
                Text(fallback)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 16) {
                Button("Regenerate") {
                    viewModel.regeneratePlan()
                }
                .buttonStyle(.bordered)

                Button("Edit setup") {
                    viewModel.editSetup()
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            sectionLabel("Review your calendar")
                            Text("Tap a date to add, remove, or inspect it.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    CalendarLegendRow()

                    PlanMultiSelectCalendar(
                        displayedMonth: $viewModel.displayedMonth,
                        allowedDateRange: viewModel.allowedRange,
                        selectedDateKeys: viewModel.selectedKeys,
                        recommendedDateKeys: viewModel.recommendedKeys,
                        disablesAlreadyActive: false,
                        isSelectable: viewModel.isSelectable(_:),
                        onToggle: viewModel.toggleDate(_:),
                        focusedDate: $viewModel.focusedDate,
                        onFocusDate: viewModel.openDateDetail(for:)
                    )
                }
            }
        }
    }

    private var summaryCard: some View {
        GlassCard(style: .header, tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.08) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(viewModel.planSummary.plannedCount) fast\(viewModel.planSummary.plannedCount == 1 ? "" : "s") planned")
                    .font(.title3.weight(.semibold))

                if let dateRange = viewModel.summaryDateRange {
                    Text(dateRange)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.planSummary.paceTitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                if !viewModel.planSummaryProtectionChips.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.planSummaryProtectionChips, id: \.self) { chip in
                                summaryChip(chip)
                            }
                        }
                    }
                }

                DisclosureGroup("Plan details", isExpanded: $showsSummaryDetails) {
                    VStack(alignment: .leading, spacing: 10) {
                        summaryRow(title: "Starts", value: formattedDate(viewModel.planSummary.startDate))
                        summaryRow(title: "Estimated finish", value: formattedDate(viewModel.planSummary.finishDate))
                        summaryRow(title: "Pace", value: viewModel.planSummary.paceTitle)
                        summaryRow(title: "Protected", value: viewModel.planSummary.protectedSummary)
                    }
                    .padding(.top, 8)
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }

    private var setupBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                pageIndicators

                Spacer()

                Button(viewModel.setupPrimaryActionTitle) {
                    viewModel.advanceSetup()
                }
                .buttonStyle(.borderedProminent)
                .tint(DawnColor.accent)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingM)
            .padding(.bottom, max(DesignTokens.spacingM, 12))
            .background(.ultraThinMaterial)
        }
    }

    private var reviewBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Text("\(viewModel.selectedKeys.count) / \(viewModel.draft.planBatchCount) selected")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(viewModel.isApplying ? "Confirming..." : "Confirm Qada Schedule") {
                    Task { await viewModel.applyPlan() }
                }
                .buttonStyle(.borderedProminent)
                .tint(DawnColor.accent)
                .disabled(!viewModel.canConfirmSchedule || viewModel.isApplying)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingM)
            .padding(.bottom, max(DesignTokens.spacingM, 12))
            .background(.ultraThinMaterial)
        }
    }

    private var successSheet: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            Text("Your Qada plan is ready.")
                .font(.title3.weight(.semibold))

            if let nextDate = viewModel.nextPlannedDate {
                Text("Next Qada fast: \(formattedDate(nextDate))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text("If you miss a day, you can move it to the next available date.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Go to Alarms") {
                viewModel.proceedToAlarms()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(DawnColor.accent)

            Button("Done") {
                viewModel.finishFlow()
            }
            .buttonStyle(.plain)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(DesignTokens.spacingL)
    }

    private func dateDetailSheet(_ detail: CalendarDayDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            SuhoorCalendarDetailCard(
                detail: detail,
                notScheduledText: "Available to add",
                selectionStatus: viewModel.detailSelectionStatus()
            )

            Button("Done") {
                viewModel.dismissDateDetail()
            }
            .buttonStyle(.plain)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(DesignTokens.spacingL)
    }

    @ViewBuilder
    private func infoSheet(_ sheet: QadaWizardInfoSheet) -> some View {
        switch sheet {
        case .protectedDays:
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                Text("Important Sunnah fasts")
                    .font(.title3.weight(.semibold))
                Text("These are observances many people prefer to keep separate from Qada.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("This includes Arafah, Ashura, the White Days, and the early days of Dhul Hijjah. Shawwal-related observances are also kept separate when they apply.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button("Done") {
                    activeInfoSheet = nil
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(DesignTokens.spacingL)
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 6) {
            ForEach(QadaSetupPage.allCases, id: \.self) { page in
                Capsule(style: .continuous)
                    .fill(page == viewModel.setupPage ? DawnColor.accent : Color.secondary.opacity(0.18))
                    .frame(width: page == viewModel.setupPage ? 20 : 8, height: 8)
            }
        }
    }

    private var draftCountIsEmpty: Bool {
        viewModel.draft.baselineOwed == 0
    }

    private func handleBack() {
        if viewModel.goBackWithinFlow() {
            return
        }
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DawnColor.lightGold200.opacity(0.16))
            .foregroundStyle(.secondary)
            .clipShape(Capsule(style: .continuous))
    }

    private func summaryRow(title: String, value: String?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "-")
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return GregorianDateFormatter.shared.headerString(for: date)
    }
}
