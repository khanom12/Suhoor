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
                    fajrText: Strings.AlarmsTab.fajrTime(TimeFormatters.timeFormatter.string(from: currentSchedule.fajrDate)),
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
                    ForEach(reasonRows) { row in
                        detailInfoRow(title: row.title, detail: row.detail)
                    }
                }
            } header: {
                Text("Why this wake")
                    .textCase(nil)
            }

            if let trustNote {
                Section {
                    detailInfoRow(title: "Boundary", detail: trustNote)
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
            return "Subh resolved this morning from the current Fajr window."
        }

        let anchor = activeDay.decisionLog.resolvedAnchor
        if anchor.type == .fajrEnd {
            return "Wake is set 30 minutes before the supported Fajr end."
        }
        return "Wake is set from the currently resolved morning plan."
    }

    private var reasonRows: [DetailReasonRow] {
        guard let activeDay else {
            return [
                DetailReasonRow(
                    id: "wake",
                    title: "Wake",
                    detail: "Set for \(TimeFormatters.timeFormatter.string(from: currentSchedule.wakeDate))."
                )
            ]
        }

        let decisionLog = activeDay.decisionLog
        let anchor = decisionLog.resolvedAnchor
        let anchorText: String
        switch anchor.type {
        case .fajrEnd:
            anchorText = "supported Fajr end"
        case .fajrStart:
            anchorText = "Fajr start"
        case .masjidFajr:
            anchorText = "masjid Fajr"
        case .clockTime:
            anchorText = "fixed clock time"
        }

        return [
            DetailReasonRow(
                id: "wake",
                title: "Wake",
                detail: "Set for \(TimeFormatters.timeFormatter.string(from: decisionLog.resolvedWakeTime))."
            ),
            DetailReasonRow(
                id: "anchor",
                title: "Anchor",
                detail: "Resolved from \(anchorText) with a \(decisionLog.resolvedDelta.minutes)-minute buffer."
            ),
            DetailReasonRow(
                id: "source",
                title: "Source",
                detail: activeDay.sourceSummaryText.isEmpty
                    ? "Default Subh morning plan."
                    : activeDay.sourceSummaryText
            )
        ]
    }

    private var trustNote: String? {
        guard let note = activeDay?.decisionLog.resolvedAnchor.providerNotes else { return nil }
        switch note {
        case "provider:solar_sunrise_proxy":
            return "Subh is using its current sunrise-derived supported end marker for this date."
        case "fallback:missing_fajr_end":
            return "Subh could not resolve a separate Fajr end marker, so it used the supported fallback."
        default:
            return nil
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
        "\(fullGregorianDate). Wake at \(TimeFormatters.timeFormatter.string(from: currentSchedule.wakeDate)). \(summaryText)"
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
    let fajrText: String
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

            Text(fajrText)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }
}
