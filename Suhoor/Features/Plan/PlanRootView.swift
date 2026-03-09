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
                NavigationLink(value: PlanDestination.defaultMorningPlan) {
                    DefaultMorningPlanCard(summary: snapshot.defaultMorningPlanSummary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Upcoming Special Plans")

                    NavigationLink(value: PlanDestination.calendar) {
                        ConfiguredPlansCard(snapshot: snapshot.configuredPlansSnapshot)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: PlanDestination.calendar) {
                        DatePlanningCard()
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
                    SectionTitle("Observance Opportunities")

                    NavigationLink(value: PlanDestination.sunnahPlanner) {
                        PlansFeatureRow(
                            title: "Sunnah opportunities",
                            subtitle: "Browse upcoming fasting opportunities.",
                            systemImage: "sparkles",
                            color: DawnColor.lightGold200
                        )
                    }
                    .buttonStyle(.plain)

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
                subtitle: "Custom fasting days",
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
                        Text("Everyday around Fajr.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "sun.horizon")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                    SummaryRow(label: "Wake relation to Fajr", value: summary.wakeRelation)
                    SummaryRow(label: "Reminder", value: summary.reminder)
                    SummaryRow(label: "Follow-up", value: summary.followUp)
                    SummaryRow(label: "Fajr notice", value: summary.fajrNotice)
                    SummaryRow(label: "Fasting-day support", value: summary.fastingDaySupport)
                }

                if let compatibilityNote = summary.compatibilityNote {
                    Text(compatibilityNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        Text("Dates that differ from your default.")
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
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if snapshot.additionalSpecialMorningCount > 0 {
                            Text("+\(snapshot.additionalSpecialMorningCount) more")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DawnColor.accent)
                        }
                    }
                } else {
                    Text("Nothing special planned yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DatePlanningCard: View {
    var body: some View {
        GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.14) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Plan by date")
                        .font(.headline.weight(.semibold))
                    Text("Pick a date to adjust, fast, or plan Qada.")
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
                        Text("Qada")
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

                SummaryRow(label: "Qada", value: qadaValue)
            }
        }
    }

    private var qadaDescription: String {
        if progress.baselineOwed > 0 {
            return "Track remaining Qada and planned Qada days."
        }
        return "Set up Qada when you need it."
    }

    private var qadaValue: String {
        if progress.baselineOwed > 0 {
            return "\(progress.completed) completed · \(progress.remaining) remaining"
        }
        return "Not configured"
    }
}

private struct CustomFastingCard: View {
    var body: some View {
        GlassCard(tintColor: DawnColor.accent, tintOpacity: 0.1) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom fasting days")
                        .font(.headline.weight(.semibold))
                    Text("Plan custom fasting days.")
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

private struct PlansFeatureRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        GlassCard(tintColor: color, tintOpacity: 0.12) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
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
            .textCase(.uppercase)
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
