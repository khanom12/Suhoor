import SwiftUI

struct DayDetailView: View {
    @Binding var settings: AppSettings
    let day: DaySchedule

    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacingL) {
                    headerBar
                    timesCard
                    ruleCard
                    exceptionCard
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingM)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onDisappear {
            Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.thinMaterial)
                            .overlay(DawnColor.glassWarmOverlay.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Text(TimeFormatters.shortDate.string(from: day.date))
                .font(DesignTokens.screenTitleFont)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var timesCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.DayDetail.timesSection)

                VStack(spacing: DesignTokens.spacingS) {
                    timeRow(label: "Suhoor Alarm", value: wakeTimeText)
                    timeRow(label: "Reminder for Fajr Alarm", value: reminderValueText)
                    timeRow(label: "Fajr Adhan", value: atFajrValueText)
                }
            }
        }
    }

    private var ruleCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Strings.DayDetail.ruleSection)
                        .font(DesignTokens.sectionHeaderFont)
                    Spacer()
                    PillBadge(text: ruleBadgeText, style: ruleBadgeStyle)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                    ForEach(ruleSummaryLines, id: \.self) { line in
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var exceptionCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.DayDetail.exceptionSection)

                Toggle(Strings.DayDetail.skipDay, isOn: skipBinding)

                NavigationLink {
                    AddExceptionView(settings: $settings, initialDate: day.date, showsDatePicker: false)
                } label: {
                    ActionRowView(
                        title: exceptionExists ? Strings.DayDetail.editException : Strings.DayDetail.createException,
                        systemImage: exceptionExists ? "slider.horizontal.3" : "calendar.badge.plus"
                    )
                }
                .buttonStyle(PressableRowButtonStyle())

                if exceptionExists {
                    Button {
                        settings.perDayExceptions.removeValue(forKey: dayKey)
                        Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                    } label: {
                        ActionRowView(
                            title: Strings.DayDetail.resetDefault,
                            systemImage: "arrow.counterclockwise",
                            showsChevron: false
                        )
                    }
                    .buttonStyle(PressableRowButtonStyle())
                }
            }
        }
    }

    private func timeRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var dayKey: String {
        DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
    }

    private var exception: DayException? {
        settings.perDayExceptions[dayKey]
    }

    private var exceptionExists: Bool {
        exception != nil
    }

    private var skipBinding: Binding<Bool> {
        Binding {
            exception?.disabledForDay ?? false
        } set: { newValue in
            var current = exception ?? DayException(
                disabledForDay: false,
                wakeOffsetOverrideMinutes: nil,
                reminderEnabledOverride: nil,
                atFajrEnabledOverride: nil,
                reminderMinutesOverride: nil,
                atFajrSoundOverride: nil
            )
            current.disabledForDay = newValue
            settings.perDayExceptions[dayKey] = current
            Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
        }
    }

    private var reminderValueText: String {
        guard reminderEnabledEffective, !isDayOff else { return Strings.Schedule.offBadge }
        return reminderTimeText
    }

    private var atFajrValueText: String {
        guard atFajrEnabledEffective, !isDayOff else { return Strings.Schedule.offBadge }
        return TimeFormatters.timeFormatter.string(from: day.fajrDate)
    }

    private var reminderTimeText: String {
        if let reminderDate = day.reminderDate {
            return TimeFormatters.timeFormatter.string(from: reminderDate)
        }
        return TimeFormatters.timeFormatter.string(from: day.fajrDate)
    }

    private var wakeTimeText: String {
        let summary = RuleEngine(settings: settings, timeZone: .current).ruleSummary(for: day.date)
        if summary.disabledForDay { return Strings.Schedule.offBadge }
        return TimeFormatters.timeFormatter.string(from: day.wakeDate)
    }

    private var ruleSummaryLines: [String] {
        let summary = ruleEngine.ruleSummary(for: day.date)
        if summary.disabledForDay {
            return [
                "Suhoor Alarm: Off.",
                "Reminder alarm: Off.",
                "Fajr Adhan: Off."
            ]
        }

        let wakeLine = "Suhoor Alarm: \(summary.finalOffsetMinutes) min before Fajr."
        let reminderLine: String
        if reminderEnabledEffective {
            reminderLine = "Reminder alarm: \(reminderMinutesEffective) min before Fajr."
        } else {
            reminderLine = "Reminder alarm: Off."
        }
        let atFajrLine = atFajrEnabledEffective ? "Fajr Adhan: On." : "Fajr Adhan: Off."
        return [wakeLine, reminderLine, atFajrLine]
    }

    private var ruleBadgeText: String {
        if isDayOff { return Strings.Schedule.offBadge }
        return isCustomRule ? Strings.Schedule.customBadge : Strings.Schedule.defaultBadge
    }

    private var ruleBadgeStyle: PillBadge.Style {
        if isDayOff { return .off }
        return isCustomRule ? .custom : .default
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

    private var isDayOff: Bool {
        ruleEngine.ruleSummary(for: day.date).disabledForDay
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
