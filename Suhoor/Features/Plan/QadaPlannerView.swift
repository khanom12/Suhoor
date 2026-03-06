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

    var body: some View {
        Group {
            switch activeRoute {
            case .companion:
                QadaCompanionView(
                    state: experienceState,
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
            if initialRoute == nil {
                initialRoute = defaultRoute
            }
        }
    }

    private var activeRoute: QadaPlannerRoute {
        routeOverride ?? initialRoute ?? defaultRoute
    }

    private var defaultRoute: QadaPlannerRoute {
        switch experienceState {
        case .needsSetup:
            return .wizard(.fresh)
        case .activeBatch, .batchCompleteNeedsNext, .needsRecovery:
            return .companion
        }
    }

    private var experienceState: QadaExperienceState {
        let progress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
        let suggestion = QadaBacklogSuggestionEngine.currentRamadanSuggestion(
            logEntries: fastLogStore.entriesByDateKey
        )
        return QadaExperienceEngine.resolve(
            backlogState: qadaBacklogStore.state,
            progress: progress,
            batchState: qadaBatchStore.state,
            logEntries: fastLogStore.entriesByDateKey,
            suggestion: suggestion
        )
    }
}
