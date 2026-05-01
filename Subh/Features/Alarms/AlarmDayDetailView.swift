import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var tentativeWakeTime: Date?
    @State private var isCommittingWakeAdjustment = false
    @State private var isSelectingWakeMode = false
    @State private var isSelectingPurpose = false
    @State private var isSelectingFastType = false
    @State private var isSelectingAudio = false
    @State private var isResettingOverride = false
    @Namespace private var quickSelectorHighlight

    private let timeZone: TimeZone = .current

    var body: some View {
        ZStack {
            AppPageBackground()
                .ignoresSafeArea()

            AppHomeContrastOverlay()
                .ignoresSafeArea()

            ScrollView {
                detailHero
                    .padding(.horizontal, DesignTokens.spacingM)
                    .padding(.top, DesignTokens.spacingXL + DesignTokens.spacingL)
                    .padding(.bottom, 104)
            }
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .navigationTitle(GregorianDateFormatter.shared.cardString(for: schedule.date))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: wakeEntry?.id) { _, _ in
            tentativeWakeTime = nil
            isCommittingWakeAdjustment = false
            isSelectingWakeMode = false
            isSelectingPurpose = false
            isSelectingFastType = false
            isSelectingAudio = false
            isResettingOverride = false
        }
        .onChange(of: currentSchedule.wakeDate) { _, _ in
            if !isCommittingWakeAdjustment {
                tentativeWakeTime = nil
            }
        }
    }

    private var detailHero: some View {
        let baseDisplay = heroDisplay
        let display = tentativeWakeTime.map {
            MorningHomePresentation.heroDisplay(adjusting: baseDisplay, tentativeWakeTime: $0, timeZone: timeZone)
        } ?? baseDisplay
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)
        let purpose = wakeEntry.flatMap { AlarmDayDetailPresentation.purpose(for: $0) }
        let fastType = wakeEntry.flatMap { AlarmDayDetailPresentation.fastType(for: $0, purpose: purpose) }
        let audio = wakeEntry.flatMap { AlarmDayDetailPresentation.audio(for: $0, display: display) }
        let showsSlider = shouldShowWakeSlider(display)

        return VStack(alignment: .center, spacing: 0) {
            dateLine(metrics: metrics)

            primaryWakeRow(display: display, metrics: metrics)
                .padding(.top, metrics.relativeToPrimaryGap)

            if showsSlider {
                FajrWindowRangeVisual(
                    display: display,
                    metrics: metrics,
                    reduceMotion: reduceMotion
                )
                .onWakeAdjustmentChanged { wakeTime in
                    tentativeWakeTime = wakeTime
                }
                .onWakeAdjustmentEnded { wakeTime in
                    commitWakeAdjustment(wakeTime)
                }
                .accessibilityValue(display.wakeAdjustmentAccessibilityValue ?? "")
                .accessibilityAdjustableAction { direction in
                    adjustWakeAccessibility(display: display, direction: direction)
                }
                .padding(.top, metrics.primaryToWindowGap)
            } else {
                quietSliderRegion(display: display, audio: audio, metrics: metrics)
                    .padding(.top, metrics.primaryToWindowGap)
            }

            MorningHeroFadingRelationText(
                text: AlarmDayDetailPresentation.relationText(for: display),
                tone: display.relationTone,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
            .padding(.top, shouldShowWakeSlider(display) ? metrics.windowToRelationGap : metrics.primaryToRelationGap)

            if !display.quickWakeModeOptions.isEmpty {
                MorningHeroQuickWakeModeSelector(
                    options: AlarmDayDetailPresentation.modeOptions(for: display),
                    metrics: metrics,
                    highlightNamespace: quickSelectorHighlight,
                    reduceMotion: reduceMotion,
                    isDisabled: controlsAreBusy
                ) { mode in
                    selectWakeMode(mode)
                }
                .padding(.top, metrics.relationToSelectorGap)
            }

            if let purpose {
                purposeChip(purpose, metrics: metrics)
                    .padding(.top, max(10, 10 * min(metrics.scale, 1.2)))
            }

            if let fastType {
                fastTypeChip(fastType, metrics: metrics)
                    .padding(.top, max(8, 8 * min(metrics.scale, 1.2)))
            }

            if let audio, !AlarmDayDetailPresentation.isQuiet(display) {
                audioChip(audio, metrics: metrics)
                    .padding(.top, max(8, 8 * min(metrics.scale, 1.2)))
            }

            if hasDateOverride {
                resetOverrideButton(metrics: metrics)
                    .padding(.top, max(12, 12 * min(metrics.scale, 1.2)))
            }
        }
        .frame(maxWidth: metrics.maxContentWidth)
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.top, metrics.verticalBreathing)
        .padding(.bottom, metrics.verticalBreathing)
        .frame(maxWidth: .infinity, minHeight: metrics.minHeroRegionHeight, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AlarmDayDetailPresentation.accessibilitySummary(
            dateLine: dateLineText,
            display: display,
            purpose: purpose,
            fastType: fastType,
            audio: audio
        ))
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

    private var heroDisplay: MorningHomeHeroDisplay {
        MorningHomePresentation.heroDisplay(
            entry: wakeEntry,
            permissionSummary: "",
            locationDisplayText: dateLineText,
            locationIconName: nil,
            currentDate: scheduleManager.currentDate,
            timeZone: timeZone
        )
    }

    private var dateLineText: String {
        AlarmDayDetailPresentation.dateLine(for: currentSchedule.date, timeZone: timeZone)
    }

    private var hasDateOverride: Bool {
        alarmConfigStore.override(for: currentSchedule.date, timeZone: timeZone)?.hasOverrides == true
    }

    private var controlsAreBusy: Bool {
        isSelectingWakeMode
            || isCommittingWakeAdjustment
            || isSelectingPurpose
            || isSelectingFastType
            || isSelectingAudio
            || isResettingOverride
    }

    private var heroModeAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.22)
    }

    private func dateLine(metrics: MorningHeroMetrics) -> some View {
        Text(dateLineText)
            .font(.system(size: metrics.dateLineSize, weight: .regular))
            .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(dateLineText)
            .accessibilityIdentifier("alarmDetail.dateLine")
    }

    @ViewBuilder
    private func primaryWakeRow(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics
    ) -> some View {
        if AlarmDayDetailPresentation.isQuiet(display) {
            Text("Quiet Mode")
                .font(AppTypography.timeDisplayFont(size: metrics.quietWakeStateSize, weight: .regular))
                .foregroundStyle(WakeGlassTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: metrics.primaryRowHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Quiet Mode")
                .accessibilityIdentifier("alarmDetail.primaryWakeTime")
        } else {
            MorningHeroPrimaryWakeRow(
                display: display,
                metrics: metrics,
                rollsActiveWakeTime: tentativeWakeTime == nil,
                reduceMotion: reduceMotion
            )
            .accessibilityIdentifier("alarmDetail.primaryWakeTime")
        }
    }

    private func quietSliderRegion(
        display: MorningHomeHeroDisplay,
        audio: AlarmDetailAudioPresentation?,
        metrics: MorningHeroMetrics
    ) -> some View {
        Text(audio?.lockedNote ?? "No wake alarm")
            .font(.system(size: max(13, metrics.fajrWindowSize * 0.92), weight: .regular))
            .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: metrics.rangeRowHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(audio?.lockedNote ?? "No wake alarm for this date")
            .accessibilityIdentifier("alarmDetail.quietSliderRegion")
    }

    @ViewBuilder
    private func purposeChip(
        _ purpose: AlarmDetailPurposePresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        if purpose.isLocked {
            purposeChipLabel(purpose, metrics: metrics, showsMenuIndicator: false)
        } else {
            Menu {
                ForEach(EarlyWakePurposeOverride.allCases) { option in
                    Button {
                        selectPurpose(option)
                    } label: {
                        Label(
                            option.displayTitle,
                            systemImage: purpose.selection == option ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                purposeChipLabel(purpose, metrics: metrics, showsMenuIndicator: true)
            }
            .buttonStyle(.plain)
            .disabled(controlsAreBusy)
        }
    }

    @ViewBuilder
    private func fastTypeChip(
        _ fastType: AlarmDetailFastTypePresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        if fastType.isLocked {
            detailChipLabel(
                label: "Fast type:",
                value: fastType.title,
                metrics: metrics,
                isLocked: true,
                showsMenuIndicator: false,
                accessibilityLabel: "Fast type: \(fastType.title), locked"
            )
        } else {
            Menu {
                Button {
                    selectFastType(nil)
                } label: {
                    Label(
                        fastType.defaultOptionTitle,
                        systemImage: fastType.selection == nil ? "checkmark" : "circle"
                    )
                }

                ForEach(AlarmDetailFastTypeOverride.allCases) { option in
                    Button {
                        selectFastType(option)
                    } label: {
                        Label(
                            option.displayTitle,
                            systemImage: fastType.selection == option ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                detailChipLabel(
                    label: "Fast type:",
                    value: fastType.title,
                    metrics: metrics,
                    isLocked: false,
                    showsMenuIndicator: true,
                    accessibilityLabel: "Fast type: \(fastType.title)"
                )
            }
            .buttonStyle(.plain)
            .disabled(controlsAreBusy)
        }
    }

    @ViewBuilder
    private func audioChip(
        _ audio: AlarmDetailAudioPresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        if audio.isLocked {
            detailChipLabel(
                label: "Audio:",
                value: audio.title,
                metrics: metrics,
                isLocked: true,
                showsMenuIndicator: false,
                accessibilityLabel: "Audio: \(audio.title), locked"
            )
        } else {
            Menu {
                ForEach(audio.options) { option in
                    Button {
                        selectAudio(option.plan)
                    } label: {
                        Label(
                            option.title,
                            systemImage: audio.selection == option.plan ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                detailChipLabel(
                    label: "Audio:",
                    value: audio.title,
                    metrics: metrics,
                    isLocked: false,
                    showsMenuIndicator: true,
                    accessibilityLabel: "Audio: \(audio.title)"
                )
            }
            .buttonStyle(.plain)
            .disabled(controlsAreBusy)
        }
    }

    private func purposeChipLabel(
        _ purpose: AlarmDetailPurposePresentation,
        metrics: MorningHeroMetrics,
        showsMenuIndicator: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Text("Purpose:")
                .foregroundStyle(WakeGlassTheme.tertiaryText)
            Text(purpose.title)
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
            if purpose.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: max(10, metrics.quickSelectorLabelSize * 0.72), weight: .semibold))
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .accessibilityHidden(true)
            }
            if showsMenuIndicator {
                Image(systemName: "chevron.down")
                    .font(.system(size: max(9, metrics.quickSelectorLabelSize * 0.64), weight: .semibold))
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: max(13, metrics.quickSelectorLabelSize * 0.9), weight: .regular))
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(WakeGlassTheme.chipFill)
                .overlay {
                    Capsule().stroke(WakeGlassTheme.chipStroke, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(purpose.isLocked ? "Purpose: \(purpose.title), locked" : "Purpose: \(purpose.title)")
    }

    private func detailChipLabel(
        label: String,
        value: String,
        metrics: MorningHeroMetrics,
        isLocked: Bool,
        showsMenuIndicator: Bool,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(WakeGlassTheme.tertiaryText)
            Text(value)
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: max(10, metrics.quickSelectorLabelSize * 0.72), weight: .semibold))
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .accessibilityHidden(true)
            }
            if showsMenuIndicator {
                Image(systemName: "chevron.down")
                    .font(.system(size: max(9, metrics.quickSelectorLabelSize * 0.64), weight: .semibold))
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: max(13, metrics.quickSelectorLabelSize * 0.9), weight: .regular))
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(WakeGlassTheme.chipFill)
                .overlay {
                    Capsule().stroke(WakeGlassTheme.chipStroke, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func resetOverrideButton(metrics: MorningHeroMetrics) -> some View {
        Button {
            resetOverride()
        } label: {
            Text("Use usual plan")
                .font(.system(size: max(12, metrics.quickSelectorLabelSize * 0.82), weight: .regular))
                .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.86))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(controlsAreBusy)
        .accessibilityIdentifier("alarmDetail.useUsualPlan")
    }

    private func shouldShowWakeSlider(_ display: MorningHomeHeroDisplay) -> Bool {
        !AlarmDayDetailPresentation.isQuiet(display)
            && display.wakeAdjustmentEnabled
            && display.fajrWindowVisualMode.rendersRange
    }

    private func commitWakeAdjustment(_ wakeTime: Date) {
        let date = currentSchedule.date
        tentativeWakeTime = wakeTime
        isCommittingWakeAdjustment = true
        Task {
            _ = await scheduleManager.commitHeroWakeAdjustment(for: date, wakeTime: wakeTime, timeZone: timeZone)
            await MainActor.run {
                tentativeWakeTime = nil
                isCommittingWakeAdjustment = false
            }
        }
    }

    private func selectWakeMode(_ mode: QuickWakeMode) {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isSelectingWakeMode = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.selectHeroWakeMode(for: date, mode: mode, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isSelectingWakeMode = false
                }
            }
        }
    }

    private func selectPurpose(_ purpose: EarlyWakePurposeOverride) {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isSelectingPurpose = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.selectAlarmDetailEarlyPurpose(for: date, purpose: purpose, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isSelectingPurpose = false
                }
            }
        }
    }

    private func selectFastType(_ fastType: AlarmDetailFastTypeOverride?) {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isSelectingFastType = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.selectAlarmDetailFastType(for: date, fastType: fastType, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isSelectingFastType = false
                }
            }
        }
    }

    private func selectAudio(_ audioPlan: AlarmDetailAudioPlan) {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isSelectingAudio = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.selectAlarmDetailAudioPlan(for: date, audioPlan: audioPlan, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isSelectingAudio = false
                }
            }
        }
    }

    private func resetOverride() {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isResettingOverride = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.resetAlarmDetailOverride(for: date, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isResettingOverride = false
                }
            }
        }
    }

    private func adjustWakeAccessibility(
        display: MorningHomeHeroDisplay,
        direction: AccessibilityAdjustmentDirection
    ) {
        guard
            display.wakeAdjustmentEnabled,
            let minTime = display.wakeAdjustmentMinTime,
            let maxTime = display.wakeAdjustmentMaxTime
        else {
            return
        }

        let current = tentativeWakeTime ?? display.primaryTime ?? minTime
        let step = max(1, display.wakeAdjustmentStepMinutes)
        let minuteDelta: Int
        switch direction {
        case .increment:
            minuteDelta = step
        case .decrement:
            minuteDelta = -step
        @unknown default:
            return
        }

        let adjusted = Calendar.current.date(byAdding: .minute, value: minuteDelta, to: current) ?? current
        let clamped = min(max(adjusted, minTime), maxTime)
        tentativeWakeTime = clamped
        commitWakeAdjustment(clamped)
    }
}

struct AlarmDetailPurposePresentation: Equatable {
    let title: String
    let isLocked: Bool
    let selection: EarlyWakePurposeOverride?
}

struct AlarmDetailFastTypePresentation: Equatable {
    let title: String
    let defaultOptionTitle: String
    let isLocked: Bool
    let selection: AlarmDetailFastTypeOverride?
}

struct AlarmDetailAudioOption: Identifiable, Equatable {
    let plan: AlarmDetailAudioPlan
    let title: String

    var id: AlarmDetailAudioPlan { plan }
}

struct AlarmDetailAudioPresentation: Equatable {
    let title: String
    let isLocked: Bool
    let selection: AlarmDetailAudioPlan
    let options: [AlarmDetailAudioOption]
    let lockedNote: String?
}

enum AlarmDayDetailPresentation {
    static func dateLine(
        for date: Date,
        timeZone: TimeZone,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil
    ) -> String {
        let gregorian = gregorianDateFormatter(timeZone: timeZone).string(from: date)
        let hijri = hijriDateTextProvider?(date, timeZone)
            ?? HijriDateFormatter.shared.string(from: date)
        guard !hijri.isEmpty else { return gregorian }
        return "\(gregorian) · \(hijri)"
    }

    static func isQuiet(_ display: MorningHomeHeroDisplay) -> Bool {
        display.selectedQuickWakeMode == .quiet || display.wakeState == .quietHours
    }

    static func relationText(for display: MorningHomeHeroDisplay) -> String {
        if isQuiet(display) {
            return "No wake alarm for this date"
        }
        return display.detailText
    }

    static func modeOptions(for display: MorningHomeHeroDisplay) -> [MorningHeroQuickWakeModeOption] {
        display.quickWakeModeOptions.map { option in
            let title = detailTitle(for: option.mode)
            return MorningHeroQuickWakeModeOption(
                mode: option.mode,
                title: title,
                isSelected: option.isSelected,
                accessibilityLabel: "\(title)\(option.isSelected ? ", selected" : "")",
                accessibilityHint: detailAccessibilityHint(for: option.mode)
            )
        }
    }

    static func purpose(for entry: WakeRowEntry) -> AlarmDetailPurposePresentation? {
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
        guard selectedMode == .fast else { return nil }

        let context = entry.activeDay.resolvedDayContext
        let tags = Set(context.supportingTags)
        let hasTahajjud = context.primaryContext == .tahajjud
            || context.secondaryContexts.contains(.tahajjud)
            || entry.activeDay.effectiveConfig.tahajjudRefinement

        if tags.contains(.ramadan) || entry.activeDay.isImplicitRamadan {
            return AlarmDetailPurposePresentation(title: "Fast", isLocked: true, selection: .fast)
        }
        if let override = entry.activeDay.effectiveConfig.earlyWakePurposeOverride {
            let selection: EarlyWakePurposeOverride = override == .tahajjud ? .tahajjud : .fast
            return AlarmDetailPurposePresentation(title: selection.displayTitle, isLocked: false, selection: selection)
        }
        if hasTahajjud && !isFastingContext(context) {
            return AlarmDetailPurposePresentation(title: "Tahajjud", isLocked: false, selection: .tahajjud)
        }
        return AlarmDetailPurposePresentation(title: "Fast", isLocked: false, selection: .fast)
    }

    static func fastType(
        for entry: WakeRowEntry,
        purpose: AlarmDetailPurposePresentation?
    ) -> AlarmDetailFastTypePresentation? {
        guard purpose?.selection == .fast else { return nil }

        if isRamadan(entry) {
            return AlarmDetailFastTypePresentation(
                title: "Ramadan fast",
                defaultOptionTitle: "Ramadan fast",
                isLocked: true,
                selection: nil
            )
        }

        if let override = entry.activeDay.effectiveConfig.alarmDetailFastTypeOverride {
            let defaultTitle = defaultFastTypeTitle(for: entry)
            return AlarmDetailFastTypePresentation(
                title: override.displayTitle,
                defaultOptionTitle: "Use \(defaultTitle)",
                isLocked: false,
                selection: override
            )
        }

        let title = defaultFastTypeTitle(for: entry)
        return AlarmDetailFastTypePresentation(
            title: title,
            defaultOptionTitle: "Use \(title)",
            isLocked: false,
            selection: nil
        )
    }

    static func audio(
        for entry: WakeRowEntry,
        display: MorningHomeHeroDisplay
    ) -> AlarmDetailAudioPresentation? {
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
        let isRamadan = isRamadan(entry)

        if selectedMode == .quiet {
            guard isRamadan else { return nil }
            return AlarmDetailAudioPresentation(
                title: "Fajr adhan remains on",
                isLocked: true,
                selection: .fajrAdhan,
                options: [],
                lockedNote: "Fajr adhan remains on for Ramadan"
            )
        }

        let configuredSelection = entry.activeDay.effectiveConfig.alarmDetailAudioPlanOverride
        let selection = normalizedAudioSelection(
            configuredSelection,
            mode: selectedMode,
            isRamadan: isRamadan
        )

        if isRamadan && selectedMode == .fast {
            return AlarmDetailAudioPresentation(
                title: audioTitle(for: .wakeAlarmAndFajrAdhan, mode: selectedMode),
                isLocked: true,
                selection: .wakeAlarmAndFajrAdhan,
                options: [],
                lockedNote: "Fajr adhan stays on for Ramadan"
            )
        }

        let options = audioOptions(mode: selectedMode, isRamadan: isRamadan)
        return AlarmDetailAudioPresentation(
            title: audioTitle(for: selection, mode: selectedMode),
            isLocked: false,
            selection: selection,
            options: options,
            lockedNote: isRamadan ? "Fajr adhan stays on for Ramadan" : nil
        )
    }

    static func accessibilitySummary(
        dateLine: String,
        display: MorningHomeHeroDisplay,
        purpose: AlarmDetailPurposePresentation?,
        fastType: AlarmDetailFastTypePresentation?,
        audio: AlarmDetailAudioPresentation?
    ) -> String {
        var parts = [dateLine]
        if isQuiet(display) {
            parts.append("Quiet Mode")
        } else {
            parts.append(display.primaryText)
        }
        parts.append(relationText(for: display))
        if let purpose {
            parts.append("Purpose: \(purpose.title)")
        }
        if let fastType {
            parts.append("Fast type: \(fastType.title)")
        }
        if let audio {
            parts.append("Audio: \(audio.title)")
        }
        return parts.joined(separator: ". ")
    }

    private static func detailTitle(for mode: QuickWakeMode) -> String {
        switch mode {
        case .fast:
            return "Early"
        case .fajr:
            return "Fajr"
        case .quiet:
            return "Quiet"
        }
    }

    private static func detailAccessibilityHint(for mode: QuickWakeMode) -> String {
        switch mode {
        case .fast:
            return "Wakes before Fajr begins for this date."
        case .fajr:
            return "Wakes in the Fajr window for this date."
        case .quiet:
            return "No wake alarm will ring for this date."
        }
    }

    private static func isFastingContext(_ context: ResolvedDayContext) -> Bool {
        let tags = Set(context.supportingTags)
        return context.primaryContext == .fasting
            || context.primaryContext == .suhoor
            || context.primaryContext == .sunnahFast
            || context.primaryContext == .qadaFast
            || tags.contains(.voluntary)
            || tags.contains(.qada)
    }

    private static func isRamadan(_ entry: WakeRowEntry) -> Bool {
        entry.activeDay.isImplicitRamadan
            || entry.activeDay.resolvedDayContext.supportingTags.contains(.ramadan)
    }

    private static func defaultFastTypeTitle(for entry: WakeRowEntry) -> String {
        let context = entry.activeDay.resolvedDayContext
        let tags = Set(context.supportingTags)
        if context.primaryContext == .qadaFast || tags.contains(.qada) {
            return "Qada fast"
        }
        if let opportunity = fastingOpportunityTitle(from: tags) {
            return opportunity
        }
        return "Voluntary fast"
    }

    private static func fastingOpportunityTitle(from tags: Set<DayTag>) -> String? {
        if tags.contains(.ramadan) { return "Ramadan fast" }
        if tags.contains(.arafah) { return "Arafah fast" }
        if tags.contains(.ashura) { return "Ashura fast" }
        if tags.contains(.dhulHijjahFirstNine) { return "Dhul Hijjah fast" }
        if tags.contains(.whiteDays) { return "White Days fast" }
        if tags.contains(.shawwalSix) { return "Shawwal fast" }
        if tags.contains(.mondayThursday) { return "Monday / Thursday fast" }
        return nil
    }

    private static func normalizedAudioSelection(
        _ configuredSelection: AlarmDetailAudioPlan?,
        mode: QuickWakeMode,
        isRamadan: Bool
    ) -> AlarmDetailAudioPlan {
        if isRamadan && mode == .fast {
            return .wakeAlarmAndFajrAdhan
        }

        let defaultSelection: AlarmDetailAudioPlan = mode == .fajr ? .fajrAdhan : .wakeAlarmAndFajrAdhan
        let selection = configuredSelection ?? defaultSelection
        if isRamadan && selection == .wakeAlarm {
            return .wakeAlarmAndFajrAdhan
        }
        if mode == .fast && selection == .fajrAdhan {
            return .wakeAlarmAndFajrAdhan
        }
        return selection
    }

    private static func audioOptions(
        mode: QuickWakeMode,
        isRamadan: Bool
    ) -> [AlarmDetailAudioOption] {
        switch mode {
        case .fajr:
            let plans: [AlarmDetailAudioPlan] = isRamadan
                ? [.fajrAdhan, .wakeAlarmAndFajrAdhan]
                : [.fajrAdhan, .wakeAlarm, .wakeAlarmAndFajrAdhan]
            return plans.map { AlarmDetailAudioOption(plan: $0, title: audioTitle(for: $0, mode: mode)) }
        case .fast:
            let plans: [AlarmDetailAudioPlan] = isRamadan
                ? [.wakeAlarmAndFajrAdhan]
                : [.wakeAlarmAndFajrAdhan, .wakeAlarm]
            return plans.map { AlarmDetailAudioOption(plan: $0, title: audioTitle(for: $0, mode: mode)) }
        case .quiet:
            return []
        }
    }

    private static func audioTitle(for plan: AlarmDetailAudioPlan, mode: QuickWakeMode) -> String {
        switch (mode, plan) {
        case (.fajr, .fajrAdhan):
            return "Fajr adhan"
        case (.fajr, .wakeAlarm):
            return "Wake alarm"
        case (.fajr, .wakeAlarmAndFajrAdhan):
            return "Both"
        case (.fast, .wakeAlarmAndFajrAdhan):
            return "Wake alarm + Fajr adhan"
        case (.fast, .wakeAlarm):
            return "Wake alarm only"
        case (.fast, .fajrAdhan):
            return "Wake alarm + Fajr adhan"
        case (.quiet, .fajrAdhan):
            return "Fajr adhan remains on"
        case (.quiet, .wakeAlarm):
            return "No wake alarm"
        case (.quiet, .wakeAlarmAndFajrAdhan):
            return "Fajr adhan remains on"
        }
    }

    private static func gregorianDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }
}
