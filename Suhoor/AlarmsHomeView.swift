import SwiftUI

struct AlarmsHomeView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var scrollOffset: CGFloat = 0
    @State private var topInset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("alarmsScroll")).minY
                                )
                            }
                        )

                    VStack(spacing: DesignTokens.spacingL) {
                        scheduleRangeCard

                        if displaySchedules.isEmpty {
                            emptyStateCard
                        } else {
                            ForEach(displaySchedules) { schedule in
                                NavigationLink {
                                    AlarmDayDetailView(schedule: schedule)
                                } label: {
                                    GlassCard(style: .normal) {
                                        AlarmDayCardView(
                                            schedule: schedule,
                                            config: effectiveConfig(for: schedule)
                                        )
                                    }
                                }
                                .buttonStyle(PressableRowButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.headerMaxHeight + topInset + DesignTokens.spacingS)
                    .padding(.bottom, DesignTokens.spacingM)
                }
                .coordinateSpace(name: "alarmsScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .readTopSafeAreaInset { topInset = $0 }
            .overlay(alignment: .top) {
                let maxCollapse = DesignTokens.headerMaxHeight - DesignTokens.headerMinHeight
                let progress = min(1, max(0, (-scrollOffset) / maxCollapse))
                CollapsingHeaderView(
                    title: Strings.AlarmList.title,
                    subtitle: Strings.AlarmsTab.nextDays(alarmConfigStore.defaults.scheduleWindowDays),
                    tertiary: nil,
                    progress: progress,
                    topInset: topInset
                )
            }
        }
    }

    private var scheduleRangeCard: some View {
        GlassCard(style: .normal, padding: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                Text(Strings.AlarmsTab.scheduleWindow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker(Strings.AlarmsTab.scheduleWindow, selection: scheduleWindowBinding) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var emptyStateCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                Text(Strings.AlarmsTab.emptyTitle)
                    .font(.headline.weight(.semibold))
                Text(emptyStateDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyStateDetail: String {
        if !scheduleManager.statusText.isEmpty {
            return scheduleManager.statusText
        }
        return Strings.AlarmsTab.emptySubtitle
    }

    private var displaySchedules: [DaySchedule] {
        let windowDays = max(1, alarmConfigStore.defaults.scheduleWindowDays)
        return Array(scheduleManager.schedules.prefix(windowDays))
    }

    private var scheduleWindowBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.scheduleWindowDays
        }, set: { newValue in
            alarmConfigStore.defaults.scheduleWindowDays = newValue
            Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
        })
    }

    private func effectiveConfig(for schedule: DaySchedule) -> EffectiveDailyConfig {
        let timeZone = TimeZone.current
        let ruleEngine = RuleEngine(settings: settingsStore.settings, configStore: alarmConfigStore, timeZone: timeZone)
        return alarmConfigStore.effectiveConfig(
            for: schedule.date,
            ruleSummary: ruleEngine.ruleSummary(for: schedule.date),
            settings: settingsStore.settings,
            timeZone: timeZone
        )
    }
}

private struct AlarmDayCardView: View {
    let schedule: DaySchedule
    let config: EffectiveDailyConfig

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayTitle)
                        .font(DesignTokens.rowTitleFont)
                    Text(TimeFormatters.shortDate.string(from: schedule.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if config.skipDay {
                    PillBadge(text: Strings.AlarmsTab.skippedBadge, style: .off)
                } else if config.hasOverrides {
                    PillBadge(text: Strings.AlarmsTab.customizedBadge, style: .custom)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                alarmLine(title: Strings.AlarmsTab.suhoorLabel, time: suhoorTimeText, enabled: config.suhoorEnabled)
                alarmLine(title: Strings.AlarmsTab.reminderLabel, time: reminderTimeText, enabled: config.reminderEnabled)
                alarmLine(title: Strings.AlarmsTab.fajrLabel, time: fajrTimeText, enabled: config.fajrEnabled)
            }
        }
        .padding(.vertical, 2)
    }

    private var dayTitle: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        if calendar.isDateInToday(schedule.date) { return Strings.AlarmsTab.todayLabel }
        if calendar.isDateInTomorrow(schedule.date) { return Strings.AlarmsTab.tomorrowLabel }
        return TimeFormatters.dayFormatter.string(from: schedule.date)
    }

    private var suhoorTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var reminderTimeText: String {
        guard let reminderDate = schedule.reminderDate else { return Strings.AlarmList.offLabel }
        return TimeFormatters.timeFormatter.string(from: reminderDate)
    }

    private var fajrTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private func alarmLine(title: String, time: String, enabled: Bool) -> some View {
        HStack(spacing: DesignTokens.spacingS) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 86, alignment: .leading)

            Text(time)
                .font(.subheadline)
                .foregroundStyle(enabled ? .primary : .secondary)
                .monospacedDigit()

            Spacer()

            Text(enabled ? Strings.AlarmsTab.onLabel : Strings.AlarmsTab.offLabel)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(enabled ? .primary : .secondary)
        }
    }
}
