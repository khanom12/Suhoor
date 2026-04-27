import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let timeZone: TimeZone = .current

    var body: some View {
        List {
            Section {
                MorningDetailSummaryHeader(
                    gregorianText: fullGregorianDate,
                    hijriText: HijriDateFormatter.shared.string(from: currentSchedule.date),
                    title: titleText,
                    wakeDate: currentSchedule.wakeDate,
                    summaryText: summaryText,
                    accessibilitySummary: accessibilitySummary
                )
                .padding(.vertical, DesignTokens.spacingS)
                .padding(.horizontal, 12)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.secondarySystemGroupedBackground))

            Section {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    ForEach(fajrSupportRows) { row in
                        detailInfoRow(title: row.title, detail: row.detail)
                    }
                }
            } header: {
                Text("Fajr support window")
                    .textCase(nil)
            }

            Section {
                detailInfoRow(title: deliveryTitle, detail: deliveryDetail)
            } header: {
                Text("Wake delivery")
                    .textCase(nil)
            }

            if let trustNote {
                Section {
                    detailInfoRow(title: "Supported Fajr end", detail: trustNote)
                } header: {
                    Text("Trust")
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .appPageBackground()
        .navigationTitle(GregorianDateFormatter.shared.cardString(for: schedule.date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var activeDay: ActiveAlarmDay? {
        scheduleManager.activeDay(for: schedule.date, timeZone: timeZone)
    }

    private var currentSchedule: DaySchedule {
        activeDay?.schedule ?? schedule
    }

    private var wakeEntry: WakeRowEntry? {
        activeDay.map {
            WakeRowActionResolver.makeEntry(
                activeDay: $0,
                overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys)
            )
        }
    }

    private var titleText: String {
        guard let wakeEntry else { return "Resolved morning" }
        return WakePagePresentation.card(for: wakeEntry).title
    }

    private var summaryText: String {
        guard let activeDay else {
            return "Daily Fajr morning plan."
        }

        let anchor = activeDay.decisionLog.resolvedAnchor
        if anchor.type == .fajrEnd {
            return "Wake is set inside the supported Fajr wake window."
        }
        return "Wake is set from the daily Fajr morning plan."
    }

    private var fajrSupportRows: [DetailReasonRow] {
        guard let activeDay else {
            return [
                DetailReasonRow(
                    id: "fajr-start",
                    title: "Fajr starts",
                    detail: TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)
                ),
                DetailReasonRow(
                    id: "wake",
                    title: "Wake",
                    detail: TimeFormatters.timeFormatter.string(from: currentSchedule.wakeDate)
                ),
                DetailReasonRow(
                    id: "supported-end",
                    title: "Supported Fajr end",
                    detail: currentSchedule.boundaryDate.map(TimeFormatters.timeFormatter.string(from:)) ?? "Not available for this date"
                )
            ]
        }

        let decisionLog = activeDay.decisionLog
        let anchor = decisionLog.resolvedAnchor
        let supportedEnd = decisionLog.prayerWindow.fajrEnd ?? anchor.date

        return [
            DetailReasonRow(
                id: "fajr-start",
                title: "Fajr starts",
                detail: TimeFormatters.timeFormatter.string(from: decisionLog.prayerWindow.fajrStart)
            ),
            DetailReasonRow(
                id: "wake",
                title: "Wake",
                detail: activeDay.effectiveConfig.skipDay
                    ? "Off for this date"
                    : TimeFormatters.timeFormatter.string(from: decisionLog.resolvedWakeTime)
            ),
            DetailReasonRow(
                id: "supported-end",
                title: supportedEndTitle(for: anchor.providerNotes),
                detail: TimeFormatters.timeFormatter.string(from: supportedEnd)
            ),
            DetailReasonRow(
                id: "rule",
                title: "Rule",
                detail: ruleText(for: decisionLog)
            )
        ]
    }

    private var trustNote: String? {
        guard let note = activeDay?.decisionLog.resolvedAnchor.providerNotes else { return nil }
        switch note {
        case "provider:solar_sunrise_proxy":
            return "The supported Fajr end is based on sunrise for this date."
        case "fallback:missing_fajr_end":
            return "Subh could not resolve a separate supported Fajr end, so it used the closest supported fallback."
        default:
            return nil
        }
    }

    private var deliveryTitle: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "Using AlarmKit"
        case .notifications:
            return "Using notification fallback"
        case .none:
            return "Wake delivery not ready"
        }
    }

    private var deliveryDetail: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "Subh is using the most reliable wake delivery available on this device."
        case .notifications:
            return "Notifications may be affected by Focus, Silent Mode, or notification settings."
        case .none:
            return "Open Reliability in Settings to finish wake delivery setup."
        }
    }

    private func supportedEndTitle(for providerNotes: String?) -> String {
        providerNotes == "provider:solar_sunrise_proxy"
            ? "Supported Fajr end"
            : "Supported Fajr boundary"
    }

    private func ruleText(for decisionLog: RuleDecisionLog) -> String {
        let minutes = decisionLog.resolvedDelta.minutes
        let unit = minutes == 1 ? "min" : "min"
        let relation: String
        switch decisionLog.resolvedDelta.relation {
        case .before:
            relation = "\(minutes) \(unit) before"
        case .after:
            relation = "\(minutes) \(unit) after"
        }

        switch decisionLog.resolvedAnchor.type {
        case .fajrEnd:
            return "Wake \(relation) supported Fajr end"
        case .fajrStart:
            return "Wake \(relation) Fajr starts"
        case .masjidFajr:
            return "Wake \(relation) masjid Fajr"
        case .clockTime:
            return "Fixed wake"
        }
    }

    @ViewBuilder
    private func detailInfoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
            Text(title)
                .font(AppTypography.rowTitle)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DesignTokens.space2)
    }

    private var fullGregorianDate: String {
        MorningDetailSummaryHeader.fullDateFormatter.string(from: schedule.date)
    }

    private var accessibilitySummary: String {
        "\(fullGregorianDate). Wake at \(TimeFormatters.timeFormatter.string(from: currentSchedule.wakeDate)). \(summaryText) \(deliveryTitle)."
    }
}

private struct DetailReasonRow: Identifiable {
    let id: String
    let title: String
    let detail: String
}

private struct MorningDetailSummaryHeader: View {
    let gregorianText: String
    let hijriText: String
    let title: String
    let wakeDate: Date
    let summaryText: String
    let accessibilitySummary: String

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

    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                Text(gregorianText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(hijriText)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                AppTimeDisplay(
                    main: Self.timeMainFormatter.string(from: wakeDate),
                    suffix: Self.timeSuffixFormatter.string(from: wakeDate),
                    style: .detail,
                    mainWeight: .light,
                    suffixWeight: .medium
                )

                Text(summaryText)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }
}
