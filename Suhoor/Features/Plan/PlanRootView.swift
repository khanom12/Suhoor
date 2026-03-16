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
        AppGlassSurface(variant: .hero, prominence: .high, tint: DawnColor.lightGold200) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Default Morning Plan")
                            .font(.headline.weight(.semibold))
                        Text(Strings.PlansSurface.defaultSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "sun.horizon")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                AppInsetGroup(tint: DawnColor.lightGold200.opacity(0.35)) {
                    SummaryRow(label: "Wake lead", value: summary.wakeLead)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Extra wake buffer", value: summary.extraWakeBuffer)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Reminders", value: summary.reminders)
                    AppGroupDivider(inset: 0)
                    SummaryRow(label: "Prayer times", value: summary.prayerTimes)
                    if let tahajjudBehavior = summary.tahajjudBehavior {
                        AppGroupDivider(inset: 0)
                        SummaryRow(label: "Tahajjud", value: tahajjudBehavior)
                    }
                }
            }
        }
    }
}

private struct ConfiguredPlansCard: View {
    let snapshot: ConfiguredPlansSnapshot

    var body: some View {
        AppGlassSurface(variant: .standard, tint: DawnColor.accent) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Upcoming special plans")
                            .font(.headline.weight(.semibold))
                        Text(Strings.PlansSurface.upcomingSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DawnColor.accent)
                }

                if snapshot.hasUpcomingSpecialMornings {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        ForEach(snapshot.upcomingSpecialMornings) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.subtitle)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.title)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if snapshot.additionalSpecialMorningCount > 0 {
                            Text(additionalSummary)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DawnColor.accent)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.PlansSurface.upcomingEmptyTitle)
                            .font(.footnote.weight(.semibold))
                        Text(Strings.PlansSurface.upcomingEmptyBody)
                            .font(.footnote)
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
        AppGlassSurface(variant: .quiet, tint: DawnColor.lightGold200) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Plan by date")
                        .font(.headline.weight(.semibold))
                    Text("Choose a future date and shape one morning.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "calendar.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DawnColor.lightGold200)
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
                    accent: FastPrimaryIntent.qadaMakeup.style.color
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
                    accent: DawnColor.accent
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
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: DesignTokens.spacingM)

            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, DesignTokens.spacingL)
        .padding(.vertical, DesignTokens.spacingM)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, 12)
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
        AppGlassSurface(variant: .quiet, tint: tile.color) {
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
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tile.color)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(tile.color.opacity(0.10))
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
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.upcomingSpecialMornings) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.subtitle)
                                .font(.headline.weight(.semibold))
                            Text(item.title)
                                .font(.subheadline)
                            Text(WakeRowPresentation.accessibilityDateLabel(for: item.date))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if snapshot.additionalSpecialMorningCount > 0 {
                        Text("\(snapshot.additionalSpecialMorningCount) more mornings are already shaped.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                NavigationLink(value: PlanDestination.calendar) {
                    Text("View by date")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DawnColor.accent)
                }
            }
        }
        .navigationTitle("Upcoming Special Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}
