import SwiftUI

struct PlanRootView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
    ]

    var body: some View {
        let snapshot = scheduleManager.plansSurfaceSnapshot
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Default Morning Plan")

                    NavigationLink(value: PlanDestination.defaultMorningPlan) {
                        DefaultMorningPlanCard(summary: snapshot.defaultMorningPlanSummary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Upcoming Special Plans")

                    NavigationLink(value: PlanDestination.upcomingSpecialPlans) {
                        ConfiguredPlansCard(snapshot: snapshot.configuredPlansSnapshot)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Fasting & Qada")

                    Button {
                        appNavigator.openQadaPlanner()
                    } label: {
                        ConfiguredQadaCard(progress: snapshot.qadaProgress)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: PlanDestination.others) {
                        CustomFastingCard()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Plan by Date")

                    NavigationLink(value: PlanDestination.calendar) {
                        DatePlanningCard()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Observance Opportunities")

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
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
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
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.25) {
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

                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                    SummaryRow(label: "Wake lead", value: summary.wakeLead)
                    SummaryRow(label: "Extra wake buffer", value: summary.extraWakeBuffer)
                    SummaryRow(label: "Reminders", value: summary.reminders)
                    SummaryRow(label: "Prayer times", value: summary.prayerTimes)
                    if let tahajjudBehavior = summary.tahajjudBehavior {
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
        GlassCard(tintColor: DawnColor.accent, tintOpacity: 0.12) {
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
        GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.14) {
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

private struct ConfiguredQadaCard: View {
    let progress: QadaProgressSnapshot

    var body: some View {
        GlassCard(tintColor: FastPrimaryIntent.qadaMakeup.style.color, tintOpacity: 0.14) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(progress.baselineOwed > 0 ? "Qada remaining" : "Qada tracking")
                            .font(.headline.weight(.semibold))
                        Text(qadaDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checklist")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FastPrimaryIntent.qadaMakeup.style.color)
                }

                SummaryRow(label: progress.baselineOwed > 0 ? "Progress" : "Next step", value: qadaValue)
            }
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

private struct CustomFastingCard: View {
    var body: some View {
        GlassCard(tintColor: DawnColor.accent, tintOpacity: 0.1) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom fasting days")
                        .font(.headline.weight(.semibold))
                    Text("Choose a date for a voluntary or one-off fasting morning.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "moon.stars")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DawnColor.accent)
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
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

            Spacer()

            Text(value)
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
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
