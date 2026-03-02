import SwiftUI
import UIKit
import CoreLocation
import os

struct AlarmsHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var fastTagStore: FastTagStore

    @State private var selectedSchedule: DaySchedule?
    @State private var showSettingsSheet = false
    @State private var showAddDaySheet = false
    @State private var editMode: EditMode = .inactive
    @State private var sectionCollapseOverrides: [String: Bool] = [:]
    @State private var listSnapshot: AlarmListSnapshot = .empty
    @State private var pendingFocusDateKey: String?

    var body: some View {
        NavigationStack {
            List {
                if listSnapshot.sections.isEmpty {
                    Section {
                        emptyStateView
                    }
                } else {
                    ForEach(listSnapshot.sections) { section in
                        Section {
                            if !isSectionCollapsed(section) {
                                ForEach(section.entries) { entry in
                                    AlarmRowView(
                                        schedule: entry.schedule,
                                        config: entry.config,
                                        primaryDisplay: entry.primary,
                                        primaryIntent: entry.primaryIntent,
                                        secondaryTags: entry.secondaryTags,
                                        showsTags: entry.showsTags,
                                        onSelect: {
                                            selectedSchedule = entry.schedule
                                        }
                                    )
                                    .deleteDisabled(!entry.isOneOff)
                                }
                                .onDelete { offsets in
                                    deleteEntries(in: section.entries, at: offsets)
                                }
                            }
                } header: {
                    if let preview = section.preview, section.entries.isEmpty {
                        previewHeader(preview)
                    } else if section.entries.isEmpty {
                        Text(section.key.title)
                            .textCase(nil)
                    } else {
                        Button {
                            toggleSectionCollapse(section)
                        } label: {
                            HStack {
                                Text(section.key.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isSectionCollapsed(section) ? 0 : 90))
                            }
                        }
                        .buttonStyle(.plain)
                        .textCase(nil)
                    }
                }
            }
        }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if showsAddButton {
                        Button {
                            showAddDaySheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: navigationIsActiveBinding) {
                if let schedule = selectedSchedule {
                    AlarmDayDetailView(schedule: schedule)
                }
            }
            .task {
                rebuildListSnapshot()
            }
            .onChange(of: scheduleManager.activeWindowSnapshot) { _, _ in
                rebuildListSnapshot()
            }
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    SettingsRootView()
                }
            }
            .sheet(isPresented: $showAddDaySheet) {
                NavigationStack {
                    AddScheduleSheet(isPresented: $showAddDaySheet) { date in
                        pendingFocusDateKey = DateHelpers.dayIdentifier(for: date, timeZone: .current)
                        showAddDaySheet = false
                    }
                }
            }
            .onChange(of: showAddDaySheet) { _, isPresented in
                guard !isPresented, let pendingFocusDateKey else { return }
                if let existing = scheduleManager.activeWindowSnapshot.byDateKey[pendingFocusDateKey] {
                    selectedSchedule = existing.schedule
                } else if let normalizedDate = dateFromDayIdentifier(pendingFocusDateKey) {
                    selectedSchedule = scheduleManager.activeDay(for: normalizedDate)?.schedule
                }
                self.pendingFocusDateKey = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
                showSettingsSheet = true
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text(Strings.AlarmsTab.emptyTitle)
                .font(.headline.weight(.semibold))
            Text(emptyStateDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PermissionStackView(
                kinds: [.location, .alarmKit, .notifications],
                refreshKey: permissionRefreshKey,
                showOnlyBlocking: true,
                onOpenSettings: openAppSettings
            )
            .environmentObject(scheduleManager)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.spacingL)
    }

    private var emptyStateDetail: String {
        if !scheduleManager.statusText.isEmpty {
            return scheduleManager.statusText
        }
        return Strings.AlarmsTab.emptySubtitle
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private func rebuildListSnapshot() {
        let token = PerformanceTrace.begin("alarms.home.snapshot", metadata: "visible=\(scheduleManager.activeWindowSnapshot.visibleDays.count)")
        defer { PerformanceTrace.end(token) }

        let timeZone = TimeZone.current
        let displayEntries = scheduleManager.activeWindowSnapshot.visibleDays.map(AlarmRowEntry.init)

        var grouped: [HijriMonthKey: [AlarmRowEntry]] = [:]
        for entry in displayEntries {
            guard let key = FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone) else { continue }
            grouped[key, default: []].append(entry)
        }

        var sections = grouped.map { key, entries in
            let firstDate = entries.first?.schedule.date ?? Date.distantPast
            return (key: key, entries: entries, firstDate: firstDate, preview: Optional<HijriMonthPreview>.none)
        }

        let existingIdentifiers = Set(sections.map { sectionIdentifier($0.key) })
        let previewMonths = scheduleManager.rollingHijriMonths(count: 4, timeZone: timeZone)
        for yearMonth in previewMonths {
            let key = HijriMonthKey(
                year: yearMonth.hijriYear,
                month: yearMonth.month.rawValue,
                title: "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
            )
            guard !existingIdentifiers.contains(sectionIdentifier(key)) else { continue }
            guard let preview = scheduleManager.hijriMonthStartPreview(
                for: yearMonth.month,
                hijriYear: yearMonth.hijriYear,
                timeZone: timeZone
            ) else { continue }
            let previewInfo = HijriMonthPreview(key: key, startDate: preview.adjustedStart, offsetDays: preview.offsetDays)
            sections.append((key: key, entries: [], firstDate: preview.adjustedStart, preview: previewInfo))
        }

        sections.sort { $0.firstDate < $1.firstDate }
        listSnapshot = AlarmListSnapshot(
            sections: sections.map { HijriMonthSection(key: $0.key, entries: $0.entries, preview: $0.preview) }
        )
    }

    private var showsAddButton: Bool {
        !editMode.isEditing
    }

    private func deleteEntries(in entries: [AlarmRowEntry], at offsets: IndexSet) {
        for index in offsets {
            guard entries.indices.contains(index) else { continue }
            let entry = entries[index]
            guard entry.isOneOff else { continue }
            deleteOneOff(entry)
        }
    }

    private func deleteOneOff(_ entry: AlarmRowEntry) {
        let date = entry.schedule.date
        Task { await scheduleManager.deleteExplicitScheduledDate(date) }
    }

    private func isSectionCollapsed(_ section: HijriMonthSection) -> Bool {
        let identifier = sectionIdentifier(section.key)
        return sectionCollapseOverrides[identifier] ?? false
    }

    private func toggleSectionCollapse(_ section: HijriMonthSection) {
        let identifier = sectionIdentifier(section.key)
        let currentState = isSectionCollapsed(section)
        sectionCollapseOverrides[identifier] = !currentState
    }

    private func sectionIdentifier(_ key: HijriMonthKey) -> String {
        "\(key.year)-\(key.month)"
    }

    private func previewHeader(_ preview: HijriMonthPreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(preview.key.title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(adjustmentTag(for: preview.offsetDays))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(Strings.AlarmsTab.hijriMonthStarts(shortDate(preview.startDate)))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }

    private func shortDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func adjustmentTag(for offsetDays: Int) -> String {
        switch offsetDays {
        case -1:
            return Strings.Settings.hijriMinusOneDay
        case 1:
            return Strings.Settings.hijriPlusOneDay
        default:
            return Strings.Settings.hijriNoChange
        }
    }

    private func dateFromDayIdentifier(_ identifier: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: identifier)
    }
}

private struct AlarmListSnapshot {
    let sections: [HijriMonthSection]

    static let empty = AlarmListSnapshot(sections: [])
}

enum AlarmRowPresentation {
    static func secondaryTags(for result: TagComputationResult) -> [FastSecondaryVirtueTag] {
        Array(FastIntentEngine.displaySecondaryTags(result.computedSecondaryTags).prefix(5))
    }

    static func showsTags(primaryIntent: FastPrimaryIntent, secondaryTags: [FastSecondaryVirtueTag]) -> Bool {
        !(primaryIntent == .other && secondaryTags.isEmpty)
    }

    static func dateLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current,
        separator: String = " • "
    ) -> String {
        var parts: [String] = []
        if isToday(date, currentDate: currentDate, timeZone: timeZone) {
            parts.append(Strings.AlarmsTab.todayLabel)
        } else if isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            parts.append(Strings.AlarmsTab.tomorrowLabel)
        }
        parts.append(dateLabelFormatter.string(from: date))
        parts.append(HijriDateFormatter.shared.string(from: date))
        return parts.joined(separator: separator)
    }

    private static func isToday(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(date, inSameDayAs: calendar.startOfDay(for: currentDate))
    }

    private static func isTomorrow(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: currentDate)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        return calendar.isDate(date, inSameDayAs: startOfTomorrow)
    }

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}

private struct AlarmRowEntry: Identifiable {
    let activeDay: ActiveAlarmDay
    let secondaryTags: [FastSecondaryVirtueTag]
    let showsTags: Bool

    init(activeDay: ActiveAlarmDay) {
        let secondaryTags = AlarmRowPresentation.secondaryTags(for: activeDay.tagResult)
        self.activeDay = activeDay
        self.secondaryTags = secondaryTags
        self.showsTags = AlarmRowPresentation.showsTags(
            primaryIntent: activeDay.tagResult.computedPrimaryIntent,
            secondaryTags: secondaryTags
        )
    }

    var schedule: DaySchedule { activeDay.schedule }
    var config: EffectiveDailyConfig { activeDay.effectiveConfig }
    var primary: PrimaryDisplay? { activeDay.primaryDisplay }
    var isOneOff: Bool { activeDay.isExplicitOneOff }
    var primaryIntent: FastPrimaryIntent { activeDay.tagResult.computedPrimaryIntent }
    var id: String { activeDay.dateKey }
}

private struct HijriMonthSection: Identifiable {
    let key: HijriMonthKey
    let entries: [AlarmRowEntry]
    let preview: HijriMonthPreview?

    var id: String { "\(key.year)-\(key.month)" }
}

private struct HijriMonthPreview {
    let key: HijriMonthKey
    let startDate: Date
    let offsetDays: Int
}

private struct AlarmRowView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.editMode) private var editMode

    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primaryDisplay: PrimaryDisplay?
    let primaryIntent: FastPrimaryIntent
    let secondaryTags: [FastSecondaryVirtueTag]
    let showsTags: Bool
    let onSelect: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 46
    @State private var localIsOn: Bool

    private static let timeMainFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let timeSuffixFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    init(
        schedule: DaySchedule,
        config: EffectiveDailyConfig,
        primaryDisplay: PrimaryDisplay?,
        primaryIntent: FastPrimaryIntent,
        secondaryTags: [FastSecondaryVirtueTag],
        showsTags: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.schedule = schedule
        self.config = config
        self.primaryDisplay = primaryDisplay
        self.primaryIntent = primaryIntent
        self.secondaryTags = secondaryTags
        self.showsTags = showsTags
        self.onSelect = onSelect
        _localIsOn = State(initialValue: AlarmRowView.isEnabled(config: config))
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingM) {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateLabel)
                            .font(.footnote)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(primaryTimeMain)
                                    .font(.system(size: timeFontSize, weight: .regular, design: .default))
                                    .monospacedDigit()
                                    .foregroundStyle(isDisabled ? .tertiary : .primary)
                                    .minimumScaleFactor(0.8)

                                if let primaryTimeSuffix {
                                    Text(primaryTimeSuffix)
                                        .font(.system(size: timeFontSize * 0.55, weight: .regular, design: .default))
                                        .monospacedDigit()
                                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                                        .baselineOffset(1)
                                }
                            }

                            Spacer(minLength: 8)

                            Text(fajrLineText)
                                .font(.callout)
                                .foregroundStyle(isDisabled ? .tertiary : .secondary)
                                .monospacedDigit()
                        }
                    }

                    if showsTags {
                        HomeTagCapsuleRow(
                            primaryIntent: primaryIntent,
                            secondaryTags: secondaryTags,
                            isDisabled: isDisabled
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)
            }
            .buttonStyle(.plain)
            .disabled(editMode?.wrappedValue.isEditing == true)

            Toggle("", isOn: dayActiveBinding)
                .labelsHidden()
                .tint(DawnColor.accent)
                .accessibilityLabel("\(primaryLabelText) alarm")
                .padding(.top, 4)
        }
        .padding(.vertical, 6)
        .onChange(of: config) { _, newValue in
            localIsOn = AlarmRowView.isEnabled(config: newValue)
        }
    }

    private var fajrTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var primaryTimeText: String {
        if let primaryDisplay {
            return TimeFormatters.timeFormatter.string(from: primaryDisplay.time)
        }
        return TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var primaryTimeDate: Date {
        primaryDisplay?.time ?? schedule.wakeDate
    }

    private var primaryTimeMain: String {
        AlarmRowView.timeMainFormatter.string(from: primaryTimeDate)
    }

    private var primaryTimeSuffix: String? {
        AlarmRowView.timeSuffixFormatter.string(from: primaryTimeDate)
    }

    private var fajrLineText: String {
        "Fajr \(fajrTimeText)"
    }

    private var dateLabel: String {
        AlarmRowPresentation.dateLabel(for: schedule.date, separator: " • ")
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            localIsOn
        }, set: { isOn in
            localIsOn = isOn
            let timeZone = TimeZone.current
            alarmConfigStore.setDayEnabled(isOn, for: schedule.date, timeZone: timeZone)
            scheduleManager.requestRescheduleDay(schedule.date)
        })
    }

    private var accessibilitySummary: String {
        var summary = "\(dateLabelWithPrefix). \(primaryLabelText) alarm. \(primaryTimeText). Fajr \(fajrTimeText)."
        if let tagAccessibilityText {
            summary += " \(tagAccessibilityText)"
        }
        return summary
    }

    private var primaryLabelText: String {
        switch primaryDisplay?.kind ?? .suhoor {
        case .suhoor:
            return "Suhoor"
        case .reminder:
            return "Reminder"
        case .fajr:
            return "Fajr"
        }
    }

    private var isDisabled: Bool {
        !localIsOn
    }

    private var dateLabelWithPrefix: String {
        AlarmRowPresentation.dateLabel(for: schedule.date, separator: ", ")
    }

    private var tagAccessibilityText: String? {
        guard showsTags else { return nil }
        var titles: [String] = [primaryIntent.style.title]
        titles.append(contentsOf: secondaryTags.map { $0.title })
        return "Tags: \(titles.joined(separator: ", "))."
    }

    private static func isEnabled(config: EffectiveDailyConfig) -> Bool {
        !config.skipDay && config.hasAnyEnabled
    }
}

private extension AlarmsHomeView {
    var navigationIsActiveBinding: Binding<Bool> {
        Binding(get: {
            selectedSchedule != nil
        }, set: { isActive in
            if !isActive {
                selectedSchedule = nil
            }
        })
    }
}

private struct HomeTagCapsuleRow: View {
    let primaryIntent: FastPrimaryIntent
    let secondaryTags: [FastSecondaryVirtueTag]
    let isDisabled: Bool

    var body: some View {
        FlowLayout(spacing: 6) {
            HomeTagCapsule(style: primaryIntent.style, prominence: .strong, isDisabled: isDisabled)
            ForEach(secondaryTags, id: \.self) { tag in
                HomeTagCapsule(style: tag.style, prominence: .subtle, isDisabled: isDisabled)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct HomeTagCapsule: View {
    enum Prominence {
        case strong
        case subtle
    }

    let style: FastTagStyle
    let prominence: Prominence
    let isDisabled: Bool

    var body: some View {
        let base = style.color
        let fillOpacity = prominence == .strong ? 0.18 : 0.10
        let strokeOpacity = prominence == .strong ? 0.35 : 0.22

        HStack(spacing: 5) {
            if let systemImage = style.systemImage {
                Image(systemName: systemImage)
            }
            Text(style.shortTitle)
                .lineLimit(1)
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(base)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(base.opacity(fillOpacity))
            )
            .overlay(
                Capsule()
                    .stroke(base.opacity(strokeOpacity), lineWidth: 0.8)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .accessibilityHidden(true)
    }
}
