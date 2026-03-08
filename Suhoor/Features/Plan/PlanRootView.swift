import SwiftUI

struct PlanRootView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var qadaProgress = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
        GridItem(.flexible(), spacing: DesignTokens.spacingM),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                NavigationLink(value: PlanDestination.defaultMorningPlan) {
                    DefaultMorningPlanCard(summary: defaultMorningPlanSummary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    SectionTitle("Upcoming Special Plans")

                    NavigationLink(value: PlanDestination.calendar) {
                        ConfiguredPlansCard(snapshot: configuredPlansSnapshot)
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
                        NotificationCenter.default.post(name: .openPlanQada, object: nil)
                    } label: {
                        ConfiguredQadaCard(progress: qadaProgress)
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
                            subtitle: "Browse recurring and upcoming fasting opportunities.",
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
        .onAppear(perform: refreshProgress)
        .onChange(of: qadaBacklogStore.state) { _, _ in
            refreshProgress()
        }
        .onChange(of: fastLogStore.currentRevision) { _, _ in
            refreshProgress()
        }
    }

    private var defaultMorningPlanSummary: DefaultMorningPlanSummary {
        let defaults = alarmConfigStore.defaults
        let wakeRelation: String
        switch defaults.defaultSuhoorTimeMode {
        case .relativeToFajrMinusMinutes:
            wakeRelation = "\(defaults.defaultSuhoorOffsetMinutes) min before Fajr"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultSuhoorOffsetMinutes)
            wakeRelation = "\(timeText) fixed wake (compatibility)"
        }

        let reminderSummary = defaults.reminderEnabledDefault
            ? defaultReminderSummary
            : "Reminder off"
        let followUpSummary = settingsStore.settings.snoozeEnabled
            ? "\(settingsStore.settings.snoozeMinutes) min after wake"
            : "Off"

        return DefaultMorningPlanSummary(
            wakeRelation: wakeRelation,
            reminder: reminderSummary,
            followUp: followUpSummary,
            fajrNotice: defaults.fajrEnabledDefault ? "On" : "Off",
            fastingDaySupport: defaults.iftarEnabledDefault ? "Iftar support on" : "Wake-only support",
            compatibilityNote: defaults.defaultSuhoorTimeMode == .fixedTime ? "Using fixed-time compatibility." : nil
        )
    }

    private var defaultReminderSummary: String {
        let defaults = alarmConfigStore.defaults
        switch defaults.defaultReminderTimeMode {
        case .beforeFajr:
            return "Reminder \(defaults.defaultReminderMinutesBeforeFajr) min before Fajr"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultReminderFixedTimeMinutes)
            return "Reminder \(timeText) fixed"
        }
    }

    private var configuredPlansSnapshot: ConfiguredPlansSnapshot {
        ProductSurfacePresentation.configuredPlansSnapshot(
            upcomingDays: scheduleManager.activeWindowSnapshot.visibleDays,
            overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys),
            qadaProgress: qadaProgress
        )
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

    private func refreshProgress() {
        qadaProgress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
    }
}

private struct DefaultMorningPlanSummary {
    let wakeRelation: String
    let reminder: String
    let followUp: String
    let fajrNotice: String
    let fastingDaySupport: String
    let compatibilityNote: String?
}

private struct DefaultMorningPlanCard: View {
    let summary: DefaultMorningPlanSummary

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.25) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Default Morning Plan")
                            .font(.headline.weight(.semibold))
                        Text("Your everyday wake setup around Fajr.")
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
                        Text("Upcoming non-default mornings.")
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
                            Text("+\(snapshot.additionalSpecialMorningCount) more in Wake")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DawnColor.accent)
                        }
                    }
                } else {
                    Text("No special mornings planned yet.")
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
                    Text("Pick a date for a one-day change, fasting day, or Qada day.")
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
            return "Track remaining Qada obligations and planned Qada mornings."
        }
        return "Set up Qada obligations when you need them."
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
                    Text("Plan selected fasting days and other custom mornings.")
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
