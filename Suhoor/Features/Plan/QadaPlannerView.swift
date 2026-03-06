import SwiftUI

private enum QadaPlannerRoute: Equatable {
    case companion
    case wizard(QadaWizardLaunchMode)
}

struct QadaPlannerView: View {
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var qadaBatchStore: QadaBatchStore
    @EnvironmentObject private var fastLogStore: FastLogStore

    @State private var initialRoute: QadaPlannerRoute?
    @State private var routeOverride: QadaPlannerRoute?
    @State private var resolvedExperienceState: QadaExperienceState = .needsSetup(suggestion: nil)

    var body: some View {
        Group {
            switch activeRoute {
            case .companion:
                QadaCompanionView(
                    state: resolvedExperienceState,
                    onViewCurrentBatch: { routeOverride = .wizard(.reviewCurrentBatch) },
                    onPlanNextBatch: { routeOverride = .wizard(.nextBatch) },
                    onAdjustTotal: { routeOverride = .wizard(.adjustTotal) },
                    onRecoverMissedDay: { routeOverride = .wizard(.recoverMissedDay) }
                )
            case .wizard(let launchMode):
                QadaPlanWizardView(
                    launchMode: launchMode,
                    onBack: routeOverride == nil ? nil : { routeOverride = nil }
                )
            }
        }
        .onAppear {
            refreshExperienceState()
            if initialRoute == nil {
                initialRoute = defaultRoute(for: resolvedExperienceState)
            }
        }
        .onChange(of: qadaBacklogStore.state) { _, _ in
            refreshExperienceState()
        }
        .onChange(of: qadaBatchStore.state) { _, _ in
            refreshExperienceState()
        }
        .onChange(of: fastLogStore.currentRevision) { _, _ in
            refreshExperienceState()
        }
    }

    private var activeRoute: QadaPlannerRoute {
        routeOverride ?? initialRoute ?? defaultRoute(for: resolvedExperienceState)
    }

    private func defaultRoute(for state: QadaExperienceState) -> QadaPlannerRoute {
        switch state {
        case .needsSetup:
            return .wizard(.fresh)
        case .activeBatch, .batchCompleteNeedsNext, .needsRecovery:
            return .companion
        }
    }

    private func refreshExperienceState() {
        let progress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
        let suggestion = QadaBacklogSuggestionEngine.currentRamadanSuggestion(
            logEntries: fastLogStore.entriesByDateKey
        )
        resolvedExperienceState = QadaExperienceEngine.resolve(
            backlogState: qadaBacklogStore.state,
            progress: progress,
            batchState: qadaBatchStore.state,
            logEntries: fastLogStore.entriesByDateKey,
            suggestion: suggestion
        )
    }
}
