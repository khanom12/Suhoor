import SwiftUI
import CoreLocation

struct RamadanScheduleView: View {
    @Binding var settings: AppSettings
    let showCustomOnly: Bool
    let showsSettingsButton: Bool
    let onShowSettings: (() -> Void)?

    @EnvironmentObject private var locationService: LocationService

    @State private var previewDays: [RamadanPreviewDay] = []
    @State private var statusText: String?
    @State private var selectedDay: RamadanPreviewDay?

    private let calculator = PrayerTimeCalculator()

    init(
        settings: Binding<AppSettings>,
        showCustomOnly: Bool,
        showsSettingsButton: Bool = false,
        onShowSettings: (() -> Void)? = nil
    ) {
        _settings = settings
        self.showCustomOnly = showCustomOnly
        self.showsSettingsButton = showsSettingsButton
        self.onShowSettings = onShowSettings
    }

    var body: some View {
        List {
            if showsSettingsButton {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rangeText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(layerSummaryText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Ramadan settings") {
                        onShowSettings?()
                    }
                }
            }

            if let statusText {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(previewDays) { day in
                Button {
                    selectedDay = day
                } label: {
                    RamadanScheduleRow(day: day, settings: settings)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(showCustomOnly ? "Custom Days" : "Ramadan Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshPreview() }
        .onChange(of: settings) { _, _ in
            refreshPreview()
        }
        .sheet(item: $selectedDay) { day in
            DayOverrideSheet(settings: $settings, day: day)
        }
    }

    private var rangeText: String {
        let ruleEngine = RuleEngine(settings: settings, timeZone: .current)
        guard let range = ruleEngine.ramadanRangeForDisplay() else { return "Range unavailable" }
        let start = TimeFormatters.shortDate.string(from: range.startDate)
        let end = TimeFormatters.shortDate.string(from: range.endDate)
        return "Range: \(start) – \(end)"
    }

    private var layerSummaryText: String {
        var parts: [String] = []
        if settings.weekendBoostEnabled { parts.append("Weekends") }
        if settings.last10Enabled { parts.append("Last 10 nights") }
        if settings.lqEnabled { parts.append("Laylatul Qadr") }
        if parts.isEmpty { return "Layers: None" }
        return "Layers: \(parts.joined(separator: ", "))"
    }

    private func refreshPreview() {
        guard settings.ramadanModeEnabled else {
            statusText = "Turn on Ramadan Mode to see the schedule."
            previewDays = []
            return
        }

        guard let coordinate = locationService.lastLocation?.coordinate else {
            statusText = "Location is needed to preview the schedule."
            locationService.requestLocation()
            previewDays = []
            return
        }

        let timeZone = TimeZone.current
        let ruleEngine = RuleEngine(settings: settings, timeZone: timeZone)
        guard let range = ruleEngine.ramadanRangeForDisplay() else {
            statusText = "Ramadan range unavailable."
            previewDays = []
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dates = DateHelpers.dates(from: calendar.startOfDay(for: range.startDate), to: calendar.startOfDay(for: range.endDate), calendar: calendar)

        var rows: [RamadanPreviewDay] = []
        let profileEngine = RamadanProfileEngine()

        for date in dates {
            guard let fajr = calculator.fajrDate(
                for: date,
                location: coordinate,
                timeZone: timeZone,
                method: settings.calculationMethod,
                adjustmentMinutes: settings.fajrAdjustmentMinutes
            ) else { continue }

            let offset = ruleEngine.effectiveWakeOffsetMinutes(for: date)
            let wake = calendar.date(byAdding: .minute, value: -offset, to: fajr) ?? fajr
            let dayNumber = profileEngine.computeRamadanDayNumber(for: date, range: range, timeZone: timeZone) ?? 1
            let badges = ruleEngine.applicableBadges(for: date)

            if showCustomOnly, !badges.contains(.custom) {
                continue
            }

            rows.append(
                RamadanPreviewDay(
                    id: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                    date: date,
                    dayNumber: dayNumber,
                    fajrDate: fajr,
                    wakeDate: wake,
                    badges: badges,
                    offsetMinutes: offset
                )
            )
        }

        statusText = nil
        previewDays = rows
    }
}

private struct RamadanScheduleRow: View {
    let day: RamadanPreviewDay
    let settings: AppSettings

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ramadan Day \(day.dayNumber)")
                    .font(.subheadline.weight(.semibold))
                Text(TimeFormatters.shortDate.string(from: day.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(TimeFormatters.timeFormatter.string(from: day.wakeDate))
                    .font(.title2)
                    .monospacedDigit()

                Text(detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !day.badges.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(day.badges) { badge in
                            Text(badge.label)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.primary.opacity(0.08))
                                )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var detailText: String {
        let fajr = TimeFormatters.timeFormatter.string(from: day.fajrDate)
        var parts: [String] = ["Fajr \(fajr)"]
        if reminderEnabledEffective {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            let reminderDate = calendar.date(byAdding: .minute, value: -reminderMinutesEffective, to: day.fajrDate) ?? day.fajrDate
            let reminder = TimeFormatters.timeFormatter.string(from: reminderDate)
            parts.append("Reminder \(reminder)")
        }
        if atFajrEnabledEffective {
            parts.append("At Fajr \(fajr)")
        }
        return parts.joined(separator: " • ")
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settings, timeZone: .current)
    }

    private var reminderEnabledEffective: Bool {
        ruleEngine.effectiveReminderEnabled(for: day.date)
    }

    private var atFajrEnabledEffective: Bool {
        ruleEngine.effectiveAtFajrEnabled(for: day.date)
    }

    private var reminderMinutesEffective: Int {
        ruleEngine.effectiveReminderMinutes(for: day.date)
    }
}
