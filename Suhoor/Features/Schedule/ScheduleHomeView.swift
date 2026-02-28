import SwiftUI
import CoreLocation

struct ScheduleRootView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case upcoming
        case ramadan

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedSegment: Segment = .upcoming
    @State private var scrollOffset: CGFloat = 0
    @State private var topInset: CGFloat = 0

    private let calculator = PrayerTimeCalculator()

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
                        if settingsStore.settings.ramadanModeEnabled {
                            Picker("Schedule", selection: $selectedSegment) {
                                Text(Segment.upcoming.title).tag(Segment.upcoming)
                                Text(Segment.ramadan.title).tag(Segment.ramadan)
                            }
                            .pickerStyle(.segmented)
                        }

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
        .onChange(of: settingsStore.settings.ramadanModeEnabled) { _, enabled in
            if !enabled {
                selectedSegment = .upcoming
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
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
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

    private var activeDays: [RamadanPreviewDay] {
        if selectedSegment == .ramadan, settingsStore.settings.ramadanModeEnabled {
            return ramadanDays
        }
        return upcomingDays
    }

    private var upcomingDays: [RamadanPreviewDay] {
        let timeZone = TimeZone.current
        let ruleEngine = RuleEngine(settings: settingsStore.settings, timeZone: timeZone)
        let profileEngine = RamadanProfileEngine()
        let range = ruleEngine.ramadanRangeForDisplay()

        return scheduleManager.schedules.prefix(settingsStore.settings.schedulePreviewDays).map { schedule in
            let dayNumber = range.flatMap { profileEngine.computeRamadanDayNumber(for: schedule.date, range: $0, timeZone: timeZone) } ?? 0
            return RamadanPreviewDay(
                id: schedule.id,
                date: schedule.date,
                dayNumber: dayNumber,
                fajrDate: schedule.fajrDate,
                wakeDate: schedule.wakeDate,
                badges: ruleEngine.applicableBadges(for: schedule.date),
                offsetMinutes: schedule.offsetMinutes
            )
        }
    }

    private var ramadanDays: [RamadanPreviewDay] {
        guard settingsStore.settings.ramadanModeEnabled else { return [] }
        guard let coordinate = locationService.lastLocation?.coordinate else { return [] }

        let timeZone = TimeZone.current
        let ruleEngine = RuleEngine(settings: settingsStore.settings, timeZone: timeZone)
        guard let range = ruleEngine.ramadanRangeForDisplay() else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dates = DateHelpers.dates(from: calendar.startOfDay(for: range.startDate), to: calendar.startOfDay(for: range.endDate), calendar: calendar)
        let profileEngine = RamadanProfileEngine()

        return dates.compactMap { date in
            guard let fajr = calculator.fajrDate(
                for: date,
                location: coordinate,
                timeZone: timeZone,
                method: settingsStore.settings.calculationMethod,
                adjustmentMinutes: settingsStore.settings.fajrAdjustmentMinutes
            ) else { return nil }

            let offset = ruleEngine.effectiveWakeOffsetMinutes(for: date)
            let wake = calendar.date(byAdding: .minute, value: -offset, to: fajr) ?? fajr
            let dayNumber = profileEngine.computeRamadanDayNumber(for: date, range: range, timeZone: timeZone) ?? 0
            let badges = ruleEngine.applicableBadges(for: date)

            return RamadanPreviewDay(
                id: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                date: date,
                dayNumber: dayNumber,
                fajrDate: fajr,
                wakeDate: wake,
                badges: badges,
                offsetMinutes: offset
            )
        }
    }
}
