import SwiftUI

struct ScheduleRootView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
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
                                    value: proxy.frame(in: .named("scheduleScroll")).minY
                                )
                            }
                        )

                    VStack(spacing: DesignTokens.spacingL) {
                        scheduleRangeCard
                        scheduleCard
                    }
                    .padding(.horizontal, DesignTokens.spacingL)
                    .padding(.top, DesignTokens.headerMaxHeight + topInset + DesignTokens.spacingS)
                    .padding(.bottom, DesignTokens.spacingM)
                }
                .coordinateSpace(name: "scheduleScroll")
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
                    title: Strings.Schedule.title,
                    subtitle: Strings.Schedule.nextDays(settingsStore.settings.schedulePreviewDays),
                    tertiary: nil,
                    progress: progress,
                    topInset: topInset
                )
            }
        }
    }

    private var scheduleCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                if !settingsStore.settings.isEnabled {
                    emptyState
                } else {
                    contentRows
                }
            }
        }
    }

    private var scheduleRangeCard: some View {
        GlassCard(style: .normal, padding: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                Text(Strings.Settings.schedulePreview)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker(Strings.Settings.schedulePreview, selection: $settingsStore.settings.schedulePreviewDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .onChange(of: settingsStore.settings.schedulePreviewDays) { _, _ in
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text("Enable Suhoor to see your schedule")
                .font(.headline.weight(.semibold))
            Text("Turn on the routine in Alarm to generate times.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Go to Alarm") {
                NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
            }
            .buttonStyle(.borderedProminent)
            .tint(DawnColor.accent)
        }
        .padding(.top, DesignTokens.spacingS)
    }

    private var contentRows: some View {
        VStack(spacing: DesignTokens.spacingS) {
            ForEach(activeDays) { day in
                NavigationLink {
                    DayDetailView(settings: $settingsStore.settings, day: day)
                } label: {
                    ScheduleRowView(day: day, settings: settingsStore.settings)
                }
                .buttonStyle(PressableRowButtonStyle())

                if day.id != activeDays.last?.id {
                    Divider()
                        .opacity(0.4)
                }
            }
        }
    }

    private var activeDays: [DaySchedule] {
        Array(scheduleManager.schedules.prefix(settingsStore.settings.schedulePreviewDays))
    }
}
