import SwiftUI

struct TodayFastCheckInCard: View {
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var isPulsing = false

    let presentation: FastingHomeSupportPresentation
    var onLater: (() -> Void)? = nil

    var body: some View {
        AppGlassSurface(variant: .quiet) {
            VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                switch presentation.phase {
                case .fastingStatusPrompt, .fastCompletionPrompt:
                    promptContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .fastingInProgress, .fastCompletionLogged:
                    loggedContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.22), value: currentStatus)
        }
        .task(id: currentStatus) {
            normalizeAutoCompletionIfNeeded()
        }
    }

    private var currentStatus: FastLogStatus {
        fastLogStore.status(for: presentation.dateKey)
    }

    private var effectiveStatus: FastLogStatus {
        if presentation.phase == .fastCompletionLogged, currentStatus == .inProgress {
            return .completed
        }
        return currentStatus
    }

    @ViewBuilder
    private var promptContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                    Text(presentation.title)
                        .font(AppTypography.cardTitle)

                    Text(presentation.detail)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                historyButton
            }

            HStack(spacing: DesignTokens.spacingS) {
                if let primaryActionTitle = presentation.primaryActionTitle {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            fastLogStore.setStatus(primaryActionStatus, for: presentation.dateKey, intentSnapshot: presentation.intentSnapshot)
                        }
                    } label: {
                        Text(primaryActionTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .appControlStyle(.primary, tint: .green)
                }

                if let secondaryActionTitle = presentation.secondaryActionTitle {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            fastLogStore.setStatus(.missed, for: presentation.dateKey, intentSnapshot: presentation.intentSnapshot)
                        }
                    } label: {
                        Text(secondaryActionTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .appControlStyle(
                        .secondary,
                        tint: presentation.phase == .fastCompletionPrompt ? .red : .secondary
                    )
                }
            }

            if let onLater {
                Button(Strings.HomeSurface.fajrPromptLater, action: onLater)
                    .font(AppTypography.metricLabel)
                    .appControlStyle(.quiet)
            }
        }
    }

    @ViewBuilder
    private var loggedContent: some View {
        ZStack(alignment: .top) {
            VStack(spacing: DesignTokens.spacingXS) {
                Text(presentation.statusTitle ?? statusTitle)
                    .font(AppTypography.cardSymbol)
                    .foregroundStyle(statusColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(shouldPulse ? (isPulsing ? 1.0 : 0.82) : 1.0)
                    .scaleEffect(shouldPulse ? (isPulsing ? 1.0 : 0.99) : 1.0)

                Text(presentation.detail)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .center)
            .onAppear {
                guard shouldPulse else {
                    isPulsing = false
                    return
                }
                isPulsing = false
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onDisappear {
                isPulsing = false
            }

            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                if presentation.showsUndo {
                    undoButton
                }

                Spacer()

                historyButton
            }
        }
    }

    @ViewBuilder
    private var historyButton: some View {
        NavigationLink {
            FastHistoryView()
        } label: {
            Text("View history")
                .font(AppTypography.metricLabel)
        }
        .appControlStyle(.quiet)
        .accessibilityLabel("Open fast completion history")
    }

    @ViewBuilder
    private var undoButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                fastLogStore.setStatus(.unknown, for: presentation.dateKey)
            }
        } label: {
            Text("Clear")
                .font(AppTypography.metricLabel)
        }
        .appControlStyle(.quiet)
        .accessibilityLabel("Clear fasting status")
    }

    private var primaryActionStatus: FastLogStatus {
        switch presentation.phase {
        case .fastingStatusPrompt:
            return .inProgress
        case .fastCompletionPrompt:
            return .completed
        default:
            return .completed
        }
    }

    private var shouldPulse: Bool {
        presentation.phase == .fastingInProgress && effectiveStatus == .inProgress
    }

    private var statusTitle: String {
        switch effectiveStatus {
        case .inProgress:
            return "Fasting in progress"
        case .completed:
            return "Fast completed"
        case .missed:
            return "Not completed"
        case .unknown:
            return ""
        }
    }

    private var statusColor: Color {
        switch effectiveStatus {
        case .unknown:
            return .primary
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .missed:
            return .secondary
        }
    }

    private func normalizeAutoCompletionIfNeeded() {
        guard presentation.phase == .fastCompletionLogged, currentStatus == .inProgress else {
            return
        }
        fastLogStore.setStatus(.completed, for: presentation.dateKey, intentSnapshot: presentation.intentSnapshot)
    }
}
