import SwiftUI

struct PlanRootView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let snapshot = scheduleManager.plansSurfaceSnapshot
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Default Morning Plan")

                    NavigationLink(value: PlanDestination.defaultMorningPlan) {
                        DefaultMorningPlanCard(summary: snapshot.defaultMorningPlanSummary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Upcoming Special Mornings")

                    NavigationLink(value: PlanDestination.upcomingSpecialPlans) {
                        ConfiguredPlansCard(snapshot: snapshot.configuredPlansSnapshot)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Fasting & Qada")

                    PlanningSupportCluster(
                        progress: snapshot.qadaProgress,
                        onOpenQada: { appNavigator.openQadaPlanner() }
                    )
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Plan by Date")

                    NavigationLink(value: PlanDestination.calendar) {
                        DatePlanningCard()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader(
                        "Observance Opportunities",
                        subtitle: "Quick ways to shape a specific season or rhythm."
                    )

                    LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
                        ForEach(opportunityTiles) { tile in
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
        .appScrollableChrome()
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: DesignTokens.spacingM),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }

    private var opportunityTiles: [PlanTile] {
        [
            PlanTile(
                title: "Shawwal",
                subtitle: "Plan Shawwal mornings",
                color: FastSecondaryVirtueTag.shawwalSix.style.color,
                destination: .shawwalPlanner
            ),
            PlanTile(
                title: "Dhul Hijjah",
                subtitle: "Plan the first nine days",
                color: FastSecondaryVirtueTag.dhulHijjahFirstNine.style.color,
                destination: .dhulHijjah
            ),
            PlanTile(
                title: "Arafah",
                subtitle: "Plan Arafah",
                color: FastSecondaryVirtueTag.arafah.style.color,
                destination: .arafah
            ),
            PlanTile(
                title: "Ashura",
                subtitle: "Plan Ashura days",
                color: FastSecondaryVirtueTag.ashura.style.color,
                destination: .ashura
            ),
            PlanTile(
                title: "White Days",
                subtitle: "Plan White Days",
                color: FastSecondaryVirtueTag.whiteDays.style.color,
                destination: .whiteDays
            ),
            PlanTile(
                title: "Mon/Thurs",
                subtitle: "Plan weekly mornings",
                color: FastSecondaryVirtueTag.mondayThursday.style.color,
                destination: .mondayThursday
            ),
            PlanTile(
                title: "Custom",
                subtitle: "Choose your own date",
                color: .secondary,
                destination: .others
            ),
        ]
    }
}

private struct DefaultMorningPlanCard: View {
    let summary: DefaultMorningPlanSurfaceSummary

    var body: some View {
        AppGlassSurface(variant: .hero, prominence: .high) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                        Text("Default Morning Plan")
                            .font(AppTypography.cardTitle)
                        Text(Strings.PlansSurface.defaultSubtitle)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "sun.horizon")
                        .font(AppTypography.cardSymbol)
                        .foregroundStyle(.primary)
                }

                AppInsetGroup {
                    SummaryRow(label: "Wake timing", value: summary.wakeTiming)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Anchor", value: summary.anchor)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Wake offset", value: summary.wakeOffset)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Reserve before end", value: summary.reserveBeforeEnd)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Latest wake", value: summary.latestWake)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Fasting cues", value: summary.fastingCues)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Prayer times", value: summary.prayerTimes)
                    if let tahajjudBehavior = summary.tahajjudBehavior {
                        AppGroupDivider(inset: 0)
                        SummaryRow(label: "Tahajjud behavior", value: tahajjudBehavior)
                    }
                }
            }
        }
    }
}

private struct ConfiguredPlansCard: View {
    let snapshot: ConfiguredPlansSnapshot

    var body: some View {
        AppGlassSurface(variant: .standard) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                        Text("Upcoming special plans")
                            .font(AppTypography.cardTitle)
                        Text("After-Fajr exceptions, fixed wakes, and other adjusted mornings.")
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .font(AppTypography.cardSymbol)
                        .foregroundStyle(.secondary)
                }

                if snapshot.hasUpcomingSpecialMornings {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        ForEach(snapshot.upcomingSpecialMornings) { item in
                            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                                Text(item.subtitle)
                                    .font(AppTypography.rowTitle)
                                Text(item.title)
                                    .font(AppTypography.rowBody)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if snapshot.additionalSpecialMorningCount > 0 {
                            Text(additionalSummary)
                                .font(AppTypography.metricLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        Text(Strings.PlansSurface.upcomingEmptyTitle)
                            .font(AppTypography.metricLabel)
                        Text(Strings.PlansSurface.upcomingEmptyBody)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var additionalSummary: String {
        let titles = Set(snapshot.upcomingSpecialMornings.map(\.title))
        if titles == ["Ramadan fast"] {
            let total = snapshot.upcomingSpecialMornings.count + snapshot.additionalSpecialMorningCount
            return "Ramadan continues on \(total) upcoming mornings"
        }
        return "\(snapshot.additionalSpecialMorningCount) more mornings"
    }
}

private struct DatePlanningCard: View {
    var body: some View {
        AppGlassSurface(variant: .quiet) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text("Plan by date")
                        .font(AppTypography.cardTitle)
                    Text("Choose a date and set a special wake or day meaning for that morning.")
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "calendar.badge.plus")
                    .font(AppTypography.cardSymbol)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PlanningSupportCluster: View {
    let progress: QadaProgressSnapshot
    let onOpenQada: () -> Void

    var body: some View {
        AppInsetGroup {
            Button(action: onOpenQada) {
                PlanningSupportRow(
                    title: progress.baselineOwed > 0 ? "Qada remaining" : "Qada tracking",
                    subtitle: qadaDescription,
                    value: qadaValue,
                    symbol: "checklist",
                    accent: FastPrimaryIntent.qadaMakeup.style.color,
                    valueColor: FastPrimaryIntent.qadaMakeup.style.color
                )
            }
            .buttonStyle(.plain)

            AppGroupDivider()

            NavigationLink(value: PlanDestination.others) {
                PlanningSupportRow(
                    title: "Custom fasting days",
                    subtitle: "Choose a date for a voluntary or one-off fasting morning.",
                    value: "Shape a day",
                    symbol: "moon.stars",
                    accent: nil,
                    valueColor: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var qadaDescription: String {
        if progress.baselineOwed > 0 {
            return "Completed Qada fasts reduce what remains."
        }
        return "Plan your first Qada day when you're ready."
    }

    private var qadaValue: String {
        if progress.baselineOwed > 0 {
            return "\(progress.completed) completed · \(progress.remaining) remaining"
        }
        return "Enable Qada tracking"
    }
}

private struct PlanningSupportRow: View {
    let title: String
    let subtitle: String
    let value: String
    let symbol: String
    let accent: Color?
    let valueColor: Color?

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                Text(title)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppTypography.metricLabel)
                    .foregroundStyle(valueColor ?? Color.secondary)
            }

            Spacer(minLength: DesignTokens.spacingM)

            Image(systemName: symbol)
                .font(AppTypography.cardSymbol)
                .foregroundStyle(accent ?? Color.secondary)
        }
        .padding(.horizontal, DesignTokens.spacingL)
        .padding(.vertical, DesignTokens.rowVerticalPadding)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(label)
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(AppTypography.metricValue)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.rowVerticalPadding)
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
        AppGlassSurface(variant: .quiet) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                        Text(tile.title)
                            .font(AppTypography.cardTitle)
                        Text(tile.subtitle)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "plus")
                        .font(AppTypography.controlIcon)
                        .foregroundStyle(.secondary)
                        .padding(DesignTokens.inlineSpacingMedium)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.10))
                                .overlay {
                                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                                }
                        )
                }
            }
        }
    }
}

private extension DefaultAlarmConfig {
    var wakeAlarmEnabledText: String {
        wakeAlarmEnabledDefault ? "Wake alarm on" : "Wake alarm off"
    }

    var wakeAlarmEnabledDefault: Bool {
        suhoorEnabledDefault
    }
}

struct UpcomingSpecialPlansView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let snapshot = scheduleManager.plansSurfaceSnapshot.configuredPlansSnapshot

        List {
            Section {
                if snapshot.upcomingSpecialMornings.isEmpty {
                    Text("Nothing special is planned yet.")
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.upcomingSpecialMornings) { item in
                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                            Text(item.subtitle)
                                .font(AppTypography.cardTitle)
                            Text(item.title)
                                .font(AppTypography.rowTitle)
                            Text(WakeRowPresentation.accessibilityDateLabel(for: item.date))
                                .font(AppTypography.rowBody)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, DesignTokens.textSpacingTight)
                    }

                    if snapshot.additionalSpecialMorningCount > 0 {
                        Text("\(snapshot.additionalSpecialMorningCount) more mornings are already shaped.")
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                NavigationLink(value: PlanDestination.calendar) {
                    Text("View by date")
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Upcoming Special Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}
