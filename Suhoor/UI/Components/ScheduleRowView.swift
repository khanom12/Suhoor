import SwiftUI

struct ScheduleRowView: View {
    let day: DaySchedule
    let settings: AppSettings

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                    Text(dayTitle)
                        .font(DesignTokens.rowTitleFont)

                    Spacer()

                    TimeText(text: wakeText, font: DesignTokens.primaryTimeFont, isEnabled: !isOff)
                        .minimumScaleFactor(0.85)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: proxy.size.width * 0.5, alignment: .leading)

                badgeRow
            }
            .frame(minHeight: 76, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .frame(minHeight: 76)
    }

    private var dayTitle: String {
        TimeFormatters.weekdayDate.string(from: day.date)
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settings, timeZone: .current)
    }

    private var isOff: Bool {
        let key = DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
        return settings.perDayExceptions[key]?.disabledForDay == true
    }

    private var wakeText: String {
        if isOff { return Strings.Schedule.offBadge }
        return TimeFormatters.timeFormatter.string(from: day.wakeDate)
    }

    private var detailText: String {
        let fajr = TimeFormatters.timeFormatter.string(from: day.fajrDate)
        if isOff { return "Fajr \(fajr)" }

        var parts: [String] = ["Fajr \(fajr)"]
        if ruleEngine.effectiveReminderEnabled(for: day.date) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            let reminderDate = calendar.date(byAdding: .minute, value: -ruleEngine.effectiveReminderMinutes(for: day.date), to: day.fajrDate) ?? day.fajrDate
            let reminder = TimeFormatters.timeFormatter.string(from: reminderDate)
            parts.append("Rem \(reminder)")
        }
        if ruleEngine.effectiveAtFajrEnabled(for: day.date) {
            parts.append("Adhan \(fajr)")
        }
        return parts.joined(separator: " • ")
    }

    @ViewBuilder
    private var badgeRow: some View {
        if isOff {
            PillBadge(text: Strings.Schedule.offBadge, style: .off)
        } else if isCustomRule {
            PillBadge(text: Strings.Schedule.customBadge, style: .custom)
        }
    }

    private var exception: DayException? {
        let key = DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
        return settings.perDayExceptions[key]
    }

    private var isCustomRule: Bool {
        guard let exception else { return false }
        return exception.wakeOffsetOverrideMinutes != nil
            || exception.reminderEnabledOverride != nil
            || exception.reminderMinutesOverride != nil
            || exception.atFajrEnabledOverride != nil
            || exception.atFajrSoundOverride != nil
    }
}
