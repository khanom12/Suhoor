import SwiftUI

struct PlanRootView: View {
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var progress = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                NavigationLink(value: PlanDestination.calendar) {
                    GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.25) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("View Calendar")
                                    .font(.headline.weight(.semibold))
                                Text("See scheduled days and upcoming observances.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
                    ForEach(tiles(progress: progress)) { tile in
                        if tile.destination == .qadaPlanner {
                            Button {
                                NotificationCenter.default.post(name: .openPlanQada, object: nil)
                            } label: {
                                PlanTileView(tile: tile)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: tile.destination) {
                                PlanTileView(tile: tile)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshProgress()
        }
        .onChange(of: qadaBacklogStore.state) { _, _ in
            refreshProgress()
        }
        .onChange(of: fastLogStore.currentRevision) { _, _ in
            refreshProgress()
        }
    }

    private func refreshProgress() {
        progress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func tiles(progress: QadaProgressSnapshot) -> [PlanTile] {
        let qadaStatus: String
        if progress.baselineOwed > 0 {
            switch qadaBacklogStore.state.inputMode {
            case .exact:
                qadaStatus = "Remaining: \(progress.remaining)"
            case .estimate:
                qadaStatus = "About \(progress.remaining) remaining"
            }
        } else {
            qadaStatus = "Plan your Qada"
        }

        return [
            PlanTile(
                title: "Qada",
                subtitle: qadaStatus,
                color: FastPrimaryIntent.qadaMakeup.style.color,
                destination: .qadaPlanner
            ),
            PlanTile(
                title: "Shawwal",
                subtitle: "Plan Shawwal 6",
                color: FastSecondaryVirtueTag.shawwalSix.style.color,
                destination: .shawwalPlanner
            ),
            PlanTile(
                title: "Dhul Hijjah",
                subtitle: "First 9 days",
                color: FastSecondaryVirtueTag.dhulHijjahFirstNine.style.color,
                destination: .dhulHijjah
            ),
            PlanTile(
                title: "Arafah",
                subtitle: "9 Dhul Hijjah",
                color: FastSecondaryVirtueTag.arafah.style.color,
                destination: .arafah
            ),
            PlanTile(
                title: "Ashura",
                subtitle: "9–11 Muharram",
                color: FastSecondaryVirtueTag.ashura.style.color,
                destination: .ashura
            ),
            PlanTile(
                title: "White Days",
                subtitle: "13–15 each month",
                color: FastSecondaryVirtueTag.whiteDays.style.color,
                destination: .whiteDays
            ),
            PlanTile(
                title: "Mon/Thurs",
                subtitle: "Weekly Sunnah",
                color: FastSecondaryVirtueTag.mondayThursday.style.color,
                destination: .mondayThursday
            ),
            PlanTile(
                title: "Others",
                subtitle: "Custom days",
                color: .secondary,
                destination: .others
            ),
        ]
    }
}

private struct PlanTile: Identifiable {
    let title: String
    let subtitle: String
    let color: Color
    let destination: PlanDestination

    var id: PlanDestination { destination }
}

private struct PlanTileView: View {
    let tile: PlanTile

    var body: some View {
        GlassCard(tintColor: tile.color, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tile.title)
                            .font(.headline.weight(.semibold))
                        Text(tile.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("+")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tile.color)
                }
            }
        }
    }
}
