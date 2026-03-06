import SwiftUI

private enum QadaWizardInfoSheet: Identifiable {
    case estimate
    case protectedDays

    var id: String {
        switch self {
        case .estimate:
            return "estimate"
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
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = QadaPlanWizardViewModel()
    @State private var activeInfoSheet: QadaWizardInfoSheet?
    @State private var showsSummaryDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                headerCard

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
            .padding(.bottom, viewModel.step == .review ? 116 : DesignTokens.spacingXL)
        }
        .background(Color.clear)
        .navigationTitle("Plan Your Qada")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 0.24), value: viewModel.step)
        .safeAreaInset(edge: .bottom) {
            if viewModel.step == .review {
                reviewBottomBar
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
                qadaBacklogStore: qadaBacklogStore
            )
        }
    }

    private var headerCard: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.step == .setup ? "Plan Your Qada" : "Your plan")
                    .font(.title3.weight(.semibold))
                Text(viewModel.step == .setup
                     ? "Choose a pace that feels realistic, and we’ll build a plan to help you get started."
                     : "Review the suggested dates, make any changes you need, then confirm your schedule.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        sectionLabel("How many fasts do you need to make up?")
                        Spacer()
                        Button {
                            activeInfoSheet = .estimate
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Picker("Count type", selection: Binding(
                        get: { viewModel.draft.inputMode },
                        set: viewModel.updateInputMode
                    )) {
                        ForEach(QadaPlanInputMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(alignment: .top, spacing: 12) {
                        setupHint(title: "Exact", body: "Keep an exact remaining count.")
                        setupHint(title: "Estimate", body: "Start with an estimate and adjust it later.")
                    }

                    Stepper(value: Binding(
                        get: { viewModel.draft.baselineOwed },
                        set: viewModel.updateBaselineOwed
                    ), in: 0...366) {
                        HStack {
                            Text("Fasts to make up")
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
                        Text("You can adjust this later.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("Choose your pace")

                    VStack(spacing: 12) {
                        ForEach(QadaPlanPace.allCases) { pace in
                            QadaPaceCard(
                                pace: pace,
                                isSelected: viewModel.draft.pace == pace,
                                action: { viewModel.updatePace(pace) }
                            )
                        }
                    }
                }
            }

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

                    Toggle("Keep Shawwal free (for the 6 fasts)", isOn: Binding(
                        get: { viewModel.draft.avoidShawwal },
                        set: viewModel.updateAvoidShawwal
                    ))

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Keep important Sunnah fasts separate", isOn: Binding(
                            get: { viewModel.draft.avoidImportantSunnah },
                            set: viewModel.updateAvoidImportantSunnah
                        ))

                        Text("Arafah, Ashura, White Days, Dhul Hijjah...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("How many should we plan right now?")

                    Stepper(value: Binding(
                        get: { viewModel.draft.planBatchCount },
                        set: viewModel.updatePlanBatchCount
                    ), in: 1...viewModel.maxPlanBatchCount) {
                        HStack {
                            Text("Plan this batch")
                            Spacer()
                            Text("\(viewModel.draft.planBatchCount) fast\(viewModel.draft.planBatchCount == 1 ? "" : "s")")
                                .font(.headline.weight(.semibold))
                        }
                    }

                    Text(viewModel.batchRecommendationText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let estimatedFinish = viewModel.estimatedBatchFinishText {
                Text("Estimated finish for this batch: \(estimatedFinish)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            Button("Create My Qada Plan") {
                viewModel.createPlan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(DawnColor.accent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
            summaryCard

            if let fallback = viewModel.fallbackDisplayCopy {
                GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.08) {
                    Text(fallback)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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
                    sectionLabel("Review your calendar")

                    Text("Tap a date to add or remove it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    CalendarLegendRow()

                    PlanMultiSelectCalendar(
                        displayedMonth: $viewModel.displayedMonth,
                        allowedDateRange: viewModel.allowedRange,
                        selectedDateKeys: viewModel.selectedKeys,
                        recommendedDateKeys: viewModel.recommendedKeys,
                        disablesAlreadyActive: false,
                        isSelectable: viewModel.isSelectable(_:),
                        onToggle: viewModel.toggleDate(_:),
                        focusedDate: $viewModel.focusedDate
                    )
                }
            }

            if let detail = viewModel.detailCardData() {
                SuhoorCalendarDetailCard(
                    detail: detail,
                    notScheduledText: "Available to add",
                    selectionStatus: viewModel.detailSelectionStatus()
                )
            }
        }
    }

    private var summaryCard: some View {
        GlassCard(style: .header, tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.08) {
            VStack(alignment: .leading, spacing: 12) {
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

    @ViewBuilder
    private func infoSheet(_ sheet: QadaWizardInfoSheet) -> some View {
        switch sheet {
        case .estimate:
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                Text("Not sure?")
                    .font(.title3.weight(.semibold))
                Text("Start with a simple estimate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("You can update the number later whenever you have a more precise count.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button("Done") {
                    activeInfoSheet = nil
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.spacingL)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            .padding(DesignTokens.spacingL)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
    }

    private func setupHint(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.vertical, DesignTokens.spacingXS)
            .background(DawnColor.lightGold200.opacity(0.14))
            .foregroundStyle(.secondary)
            .clipShape(Capsule(style: .continuous))
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return GregorianDateFormatter.shared.headerString(for: date)
    }
}
