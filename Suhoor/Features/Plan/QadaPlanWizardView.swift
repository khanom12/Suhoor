import SwiftUI

struct QadaPlanWizardView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = QadaPlanWizardViewModel()

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
            .padding(.bottom, 120)
        }
        .background(Color.clear)
        .navigationTitle("Plan Your Qada")
        .navigationBarTitleDisplayMode(.inline)
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
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.step == .setup ? "Plan Your Qada" : "Your plan")
                    .font(.title3.weight(.semibold))
                Text(viewModel.step == .setup
                     ? "Set a pace that feels realistic, and we’ll suggest a clean starting plan for you."
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
                    sectionLabel("How many fasts do you need to make up?")

                    Picker("Count type", selection: Binding(
                        get: { viewModel.draft.inputMode },
                        set: viewModel.updateInputMode
                    )) {
                        ForEach(QadaPlanInputMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

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

                    Text("Start with what you know — you can adjust later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if viewModel.progressSnapshot.baselineOwed > 0 {
                        Text("\(viewModel.progressSnapshot.remaining) still remaining based on your tracked Qada.")
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
                    sectionLabel("Keep these dates free")

                    Toggle("Keep Shawwal free (for the 6 fasts)", isOn: Binding(
                        get: { viewModel.draft.avoidShawwal },
                        set: viewModel.updateAvoidShawwal
                    ))

                    Toggle("Keep important Sunnah fasts separate", isOn: Binding(
                        get: { viewModel.draft.avoidImportantSunnah },
                        set: viewModel.updateAvoidImportantSunnah
                    ))
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
                            Text("Plan the next")
                            Spacer()
                            Text("\(viewModel.draft.planBatchCount) fast\(viewModel.draft.planBatchCount == 1 ? "" : "s")")
                                .font(.headline.weight(.semibold))
                        }
                    }

                    Text("Recommended: Most people start with 6-10 to keep it manageable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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
                GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.12) {
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
                    notScheduledText: "Not scheduled for Qada"
                )
            }
        }
    }

    private var summaryCard: some View {
        GlassCard(style: .header, tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.14) {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Plan summary")

                summaryRow(title: "Fasts planned", value: "\(viewModel.planSummary.plannedCount)")
                summaryRow(title: "Starts", value: formattedDate(viewModel.planSummary.startDate))
                summaryRow(title: "Estimated finish", value: formattedDate(viewModel.planSummary.finishDate))
                summaryRow(title: "Pace", value: viewModel.planSummary.paceTitle)
                summaryRow(title: "Protected", value: viewModel.planSummary.protectedSummary)
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
            .padding(.vertical, DesignTokens.spacingM)
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

            Button("Go to Alarms") {
                viewModel.proceedToAlarms()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(DawnColor.accent)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(DesignTokens.spacingL)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
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
