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
    @State private var isTogglingFajrAdhan = false
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
                detailContent
                    .padding(.horizontal, DesignTokens.spacingM)
                    .padding(.top, DesignTokens.spacingXL + DesignTokens.spacingL)
                    .padding(.bottom, 104)
            }
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .navigationTitle("Detailed Daily View")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: wakeEntry?.id) { _, _ in
            tentativeWakeTime = nil
            isCommittingWakeAdjustment = false
            isSelectingWakeMode = false
            isSelectingPurpose = false
            isSelectingFastType = false
            isTogglingFajrAdhan = false
            isResettingOverride = false
        }
        .onChange(of: currentSchedule.wakeDate) { _, _ in
            if !isCommittingWakeAdjustment {
                tentativeWakeTime = nil
            }
        }
    }

    private var detailContent: some View {
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)
        let display = AlarmDayDetailPresentation.detailHeroDisplay(displayedHeroDisplay)
        let purpose = wakeEntry.flatMap { AlarmDayDetailPresentation.purpose(for: $0) }
        let fastType = wakeEntry.flatMap { AlarmDayDetailPresentation.fastType(for: $0, purpose: purpose) }
        let fajrAdhan = wakeEntry.flatMap { AlarmDayDetailPresentation.fajrAdhanSetting(for: $0, purpose: purpose) }
        let context = wakeEntry.map {
            AlarmDayDetailPresentation.context(
                for: $0,
                display: display,
                purpose: purpose,
                fastType: fastType,
                fajrAdhan: fajrAdhan,
                showsReset: hasDateOverride
            )
        } ?? AlarmDetailContextPresentation(
            summary: "Wake details are not available for this date yet.",
            significance: nil,
            purpose: nil,
            fastType: nil,
            fajrAdhan: nil,
            showsReset: false
        )

        return VStack(alignment: .center, spacing: DesignTokens.spacingM) {
            detailHero(
                display: display,
                metrics: metrics,
                purpose: purpose,
                fastType: fastType,
                fajrAdhan: fajrAdhan
            )

            contextCard(context, metrics: metrics)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .animation(heroModeAnimation, value: context)
    }

    private var detailHero: some View {
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)
        let display = AlarmDayDetailPresentation.detailHeroDisplay(displayedHeroDisplay)
        let purpose = wakeEntry.flatMap { AlarmDayDetailPresentation.purpose(for: $0) }
        let fastType = wakeEntry.flatMap { AlarmDayDetailPresentation.fastType(for: $0, purpose: purpose) }
        let fajrAdhan = wakeEntry.flatMap { AlarmDayDetailPresentation.fajrAdhanSetting(for: $0, purpose: purpose) }

        return detailHero(
            display: display,
            metrics: metrics,
            purpose: purpose,
            fastType: fastType,
            fajrAdhan: fajrAdhan
        )
    }

    private func detailHero(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics,
        purpose: AlarmDetailPurposePresentation?,
        fastType: AlarmDetailFastPurposePresentation?,
        fajrAdhan: AlarmDetailFajrAdhanPresentation?
    ) -> some View {
        let showsSlider = shouldShowWakeSlider(display)
        return VStack(alignment: .center, spacing: 0) {
            heroTopAlignmentSlot(metrics: metrics)

            dateLine(metrics: metrics)
                .padding(.top, metrics.dateToRelativeGap)

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
                quietSliderRegion(display: display, fajrAdhan: fajrAdhan, metrics: metrics)
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
        }
        .frame(maxWidth: metrics.maxContentWidth)
        .padding(.horizontal, DesignTokens.spacingS)
        .padding(.top, metrics.verticalBreathing)
        .padding(.bottom, metrics.verticalBreathing + metrics.bottomGapBeforeNextCard - DesignTokens.spacingL)
        .frame(maxWidth: .infinity, minHeight: metrics.minHeroRegionHeight, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AlarmDayDetailPresentation.accessibilitySummary(
            dateLine: dateLineText,
            display: display,
            purpose: purpose,
            fastType: fastType,
            fajrAdhan: fajrAdhan
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

    private var displayedHeroDisplay: MorningHomeHeroDisplay {
        let baseDisplay = heroDisplay
        return tentativeWakeTime.map {
            MorningHomePresentation.heroDisplay(adjusting: baseDisplay, tentativeWakeTime: $0, timeZone: timeZone)
        } ?? baseDisplay
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
            || isTogglingFajrAdhan
            || isResettingOverride
    }

    private var heroModeAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.22)
    }

    private func heroTopAlignmentSlot(metrics: MorningHeroMetrics) -> some View {
        Color.clear
            .frame(height: metrics.relationRowHeight)
            .accessibilityHidden(true)
    }

    private func dateLine(metrics: MorningHeroMetrics) -> some View {
        Text(dateLineText)
            .font(.system(size: metrics.dateLineSize, weight: .regular))
            .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: metrics.relativeLabelSize * 1.18)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(dateLineText)
            .accessibilityIdentifier("alarmDetail.dateLine")
    }

    @ViewBuilder
    private func primaryWakeRow(
        display: MorningHomeHeroDisplay,
        metrics: MorningHeroMetrics
    ) -> some View {
        MorningHeroPrimaryWakeRow(
            display: display,
            metrics: metrics,
            rollsActiveWakeTime: tentativeWakeTime == nil,
            reduceMotion: reduceMotion
        )
        .accessibilityIdentifier("alarmDetail.primaryWakeTime")
    }

    private func quietSliderRegion(
        display: MorningHomeHeroDisplay,
        fajrAdhan: AlarmDetailFajrAdhanPresentation?,
        metrics: MorningHeroMetrics
    ) -> some View {
        Text(fajrAdhan?.lockedNote ?? "No wake alarm")
            .font(.system(size: max(13, metrics.fajrWindowSize * 0.92), weight: .regular))
            .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: metrics.rangeRowHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(fajrAdhan?.lockedNote ?? "No wake alarm for this date")
            .accessibilityIdentifier("alarmDetail.quietSliderRegion")
    }

    private func contextCard(
        _ context: AlarmDetailContextPresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 16,
            maxWidth: metrics.maxContentWidth,
            alignment: .leading
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(context.summary)
                    .font(.subheadline)
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("alarmDetail.contextSummary")

                if let significance = context.significance {
                    contextDividerIfNeeded(after: true)
                    contextSection(title: significance.title) {
                        chipFlow(significance.items)
                    }
                }

                if let purpose = context.purpose {
                    contextDividerIfNeeded(after: context.significance != nil)
                    contextSection(title: "Early purpose") {
                        purposeChip(purpose, metrics: metrics)
                    }
                }

                if let fastType = context.fastType {
                    contextDividerIfNeeded(after: context.significance != nil || context.purpose != nil)
                    contextSection(title: "Selected purpose") {
                        VStack(alignment: .leading, spacing: 10) {
                            fastTypeChip(fastType, metrics: metrics)
                            if !fastType.selectedOpportunityTitles.isEmpty {
                                chipFlow(fastType.selectedOpportunityTitles)
                            }
                        }
                    }
                }

                if let fajrAdhan = context.fajrAdhan {
                    contextDividerIfNeeded(after: context.significance != nil || context.purpose != nil || context.fastType != nil)
                    fajrAdhanToggle(fajrAdhan, metrics: metrics)
                }

                if context.showsReset {
                    contextDividerIfNeeded(after: context.significance != nil || context.purpose != nil || context.fastType != nil || context.fajrAdhan != nil)
                    resetOverrideButton(metrics: metrics)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("alarmDetail.contextCard")
    }

    private func contextSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.tertiaryText)
                .textCase(.uppercase)
                .tracking(0.4)
            content()
        }
    }

    @ViewBuilder
    private func contextDividerIfNeeded(after condition: Bool) -> some View {
        if condition {
            Rectangle()
                .fill(WakeGlassTheme.divider)
                .frame(height: 1)
        }
    }

    private func chipFlow(_ items: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(WakeGlassTheme.chipFill)
                            .overlay {
                                Capsule().stroke(WakeGlassTheme.chipStroke, lineWidth: 1)
                            }
                    }
            }
        }
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
        _ fastType: AlarmDetailFastPurposePresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        if fastType.isLocked {
            detailChipLabel(
                label: "Fast purpose:",
                value: fastType.title,
                metrics: metrics,
                isLocked: true,
                showsMenuIndicator: false,
                accessibilityLabel: "Fast purpose: \(fastType.title), locked"
            )
        } else {
            Menu {
                ForEach(fastType.options) { option in
                    Button {
                        selectFastType(option.selection)
                    } label: {
                        Label(
                            option.title,
                            systemImage: fastType.selection == option.selection ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                detailChipLabel(
                    label: "Fast purpose:",
                    value: fastType.title,
                    metrics: metrics,
                    isLocked: false,
                    showsMenuIndicator: true,
                    accessibilityLabel: "Fast purpose: \(fastType.title)"
                )
            }
            .buttonStyle(.plain)
            .disabled(controlsAreBusy)
        }
    }

    private func fajrAdhanToggle(
        _ fajrAdhan: AlarmDetailFajrAdhanPresentation,
        metrics: MorningHeroMetrics
    ) -> some View {
        Toggle(isOn: Binding(
            get: { fajrAdhan.isEnabled },
            set: { toggleFajrAdhan($0) }
        )) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Fajr adhan at Fajr begins")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.92))
                Text(fajrAdhan.subtitle)
                    .font(.footnote)
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .disabled(fajrAdhan.isLocked || controlsAreBusy)
        .accessibilityLabel("Fajr adhan at Fajr begins")
        .accessibilityValue(fajrAdhan.isEnabled ? "On" : "Off")
        .accessibilityHint(fajrAdhan.isLocked ? "Locked for Ramadan." : "Toggles only the later Fajr adhan for this date.")
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
            Text("Reset date changes")
                .font(.system(size: max(12, metrics.quickSelectorLabelSize * 0.82), weight: .regular))
                .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.86))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(controlsAreBusy)
        .accessibilityIdentifier("alarmDetail.resetDateChanges")
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

    private func toggleFajrAdhan(_ isEnabled: Bool) {
        let date = currentSchedule.date
        withAnimation(heroModeAnimation) {
            isTogglingFajrAdhan = true
            tentativeWakeTime = nil
        }
        Task {
            _ = await scheduleManager.setAlarmDetailFajrAdhanAfterWake(for: date, isEnabled: isEnabled, timeZone: timeZone)
            await MainActor.run {
                withAnimation(heroModeAnimation) {
                    isTogglingFajrAdhan = false
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

struct AlarmDetailFastPurposePresentation: Equatable {
    let title: String
    let defaultOptionTitle: String
    let selectedOpportunityTitles: [String]
    let options: [AlarmDetailFastPurposeOption]
    let isLocked: Bool
    let selection: AlarmDetailFastTypeOverride?
}

struct AlarmDetailFastPurposeOption: Identifiable, Equatable {
    let selection: AlarmDetailFastTypeOverride?
    let title: String

    var id: String { selection?.rawValue ?? "__default" }
}

struct AlarmDetailDaySignificancePresentation: Equatable {
    let title: String
    let items: [String]
}

struct AlarmDetailFajrAdhanPresentation: Equatable {
    let isEnabled: Bool
    let isLocked: Bool
    let subtitle: String
    let lockedNote: String?
}

struct AlarmDetailContextPresentation: Equatable {
    let summary: String
    let significance: AlarmDetailDaySignificancePresentation?
    let purpose: AlarmDetailPurposePresentation?
    let fastType: AlarmDetailFastPurposePresentation?
    let fajrAdhan: AlarmDetailFajrAdhanPresentation?
    let showsReset: Bool

    var hasContent: Bool {
        !summary.isEmpty
            || significance != nil
            || purpose != nil
            || fastType != nil
            || fajrAdhan != nil
            || showsReset
    }
}

enum AlarmDayDetailPresentation {
    static func detailHeroDisplay(_ display: MorningHomeHeroDisplay) -> MorningHomeHeroDisplay {
        guard isQuiet(display), display.primaryText != "Quiet Mode" else {
            return display
        }
        return MorningHomeHeroDisplay(
            locationText: display.locationText,
            locationIconName: display.locationIconName,
            title: display.title,
            dateLine: display.dateLine,
            wakeState: display.wakeState,
            primaryTime: display.primaryTime,
            primaryText: "Quiet Mode",
            wakeIconName: display.wakeIconName,
            statusText: display.statusText,
            detailText: display.detailText,
            relationTone: display.relationTone,
            fajrWindowLine: display.fajrWindowLine,
            fajrBeginDisplayText: display.fajrBeginDisplayText,
            fajrEndDisplayText: display.fajrEndDisplayText,
            wakeWindowPositionRatio: display.wakeWindowPositionRatio,
            wakeWindowIndicatorState: display.wakeWindowIndicatorState,
            wakeWindowIndicatorIconName: display.wakeWindowIndicatorIconName,
            leftBoundaryMarkerStyle: display.leftBoundaryMarkerStyle,
            rightBoundaryMarkerStyle: display.rightBoundaryMarkerStyle,
            fajrWindowVisualMode: display.fajrWindowVisualMode,
            fajrWindowAccessibilityText: display.fajrWindowAccessibilityText,
            wakeAdjustmentEnabled: display.wakeAdjustmentEnabled,
            wakeAdjustmentMinTime: display.wakeAdjustmentMinTime,
            wakeAdjustmentMaxTime: display.wakeAdjustmentMaxTime,
            wakeAdjustmentFajrEndTime: display.wakeAdjustmentFajrEndTime,
            wakeAdjustmentStepMinutes: display.wakeAdjustmentStepMinutes,
            wakeAdjustmentRelationAnchor: display.wakeAdjustmentRelationAnchor,
            wakeAdjustmentAccessibilityValue: display.wakeAdjustmentAccessibilityValue,
            selectedQuickWakeMode: display.selectedQuickWakeMode,
            quickWakeModeOptions: display.quickWakeModeOptions,
            chipTitles: display.chipTitles,
            accessibilityLabel: display.accessibilityLabel
        )
    }

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
    ) -> AlarmDetailFastPurposePresentation? {
        guard purpose?.selection == .fast else { return nil }

        if isRamadan(entry) {
            return AlarmDetailFastPurposePresentation(
                title: "Ramadan fast",
                defaultOptionTitle: "Ramadan fast",
                selectedOpportunityTitles: ["Ramadan fast"],
                options: [AlarmDetailFastPurposeOption(selection: nil, title: "Ramadan fast")],
                isLocked: true,
                selection: nil
            )
        }

        if let override = entry.activeDay.effectiveConfig.alarmDetailFastTypeOverride {
            let defaultTitle = defaultFastPurposeTitle(for: entry)
            return AlarmDetailFastPurposePresentation(
                title: override.displayTitle,
                defaultOptionTitle: defaultTitle,
                selectedOpportunityTitles: [],
                options: fastPurposeOptions(defaultTitle: defaultTitle),
                isLocked: false,
                selection: override
            )
        }

        let opportunities = fastingOpportunityTitles(for: entry)
        let title = opportunities.isEmpty ? "Voluntary fast" : "Today's opportunities"
        return AlarmDetailFastPurposePresentation(
            title: title,
            defaultOptionTitle: title,
            selectedOpportunityTitles: opportunities,
            options: fastPurposeOptions(defaultTitle: title),
            isLocked: false,
            selection: nil
        )
    }

    static func fajrAdhanSetting(
        for entry: WakeRowEntry,
        purpose: AlarmDetailPurposePresentation?
    ) -> AlarmDetailFajrAdhanPresentation? {
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
        let isRamadan = isRamadan(entry)

        if selectedMode == .quiet {
            guard isRamadan else { return nil }
            return AlarmDetailFajrAdhanPresentation(
                isEnabled: true,
                isLocked: true,
                subtitle: "Locked on for Ramadan.",
                lockedNote: "Fajr adhan remains on for Ramadan"
            )
        }

        if isRamadan {
            return selectedMode == .fast ? AlarmDetailFajrAdhanPresentation(
                isEnabled: true,
                isLocked: true,
                subtitle: "Locked on for Ramadan.",
                lockedNote: "Fajr adhan stays on for Ramadan"
            ) : nil
        }

        guard selectedMode == .fast, purpose?.selection == .fast else { return nil }
        let isEnabled = entry.activeDay.effectiveConfig.alarmDetailAudioPlanOverride != .wakeAlarm
        return AlarmDetailFajrAdhanPresentation(
            isEnabled: isEnabled,
            isLocked: false,
            subtitle: isEnabled
                ? "Keep the Fajr adhan after the pre-Fajr wake."
                : "Only the pre-Fajr wake alarm will ring.",
            lockedNote: nil
        )
    }

    static func context(
        for entry: WakeRowEntry,
        display: MorningHomeHeroDisplay,
        purpose: AlarmDetailPurposePresentation?,
        fastType: AlarmDetailFastPurposePresentation?,
        fajrAdhan: AlarmDetailFajrAdhanPresentation?,
        showsReset: Bool
    ) -> AlarmDetailContextPresentation {
        let significance = daySignificance(for: entry)
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: entry.activeDay)
        let showPurpose = selectedMode == .fast ? purpose : nil
        let showFastType = selectedMode == .fast && purpose?.selection == .fast ? fastType : nil
        return AlarmDetailContextPresentation(
            summary: contextSummary(
                for: entry,
                display: display,
                selectedMode: selectedMode,
                purpose: purpose
            ),
            significance: significance,
            purpose: showPurpose,
            fastType: showFastType,
            fajrAdhan: fajrAdhan,
            showsReset: showsReset
        )
    }

    static func accessibilitySummary(
        dateLine: String,
        display: MorningHomeHeroDisplay,
        purpose: AlarmDetailPurposePresentation?,
        fastType: AlarmDetailFastPurposePresentation?,
        fajrAdhan: AlarmDetailFajrAdhanPresentation?
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
            parts.append("Fast purpose: \(fastType.title)")
        }
        if let fajrAdhan {
            parts.append("Fajr adhan at Fajr begins: \(fajrAdhan.isEnabled ? "On" : "Off")")
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

    private static func daySignificance(for entry: WakeRowEntry) -> AlarmDetailDaySignificancePresentation? {
        if isRamadan(entry) {
            return AlarmDetailDaySignificancePresentation(title: "Day significance", items: ["Ramadan"])
        }
        let opportunities = fastingOpportunityTitles(for: entry)
        guard !opportunities.isEmpty else { return nil }
        return AlarmDetailDaySignificancePresentation(title: "Fasting opportunities", items: opportunities)
    }

    private static func contextSummary(
        for entry: WakeRowEntry,
        display: MorningHomeHeroDisplay,
        selectedMode: QuickWakeMode,
        purpose: AlarmDetailPurposePresentation?
    ) -> String {
        let opportunities = fastingOpportunityTitles(for: entry)
        let opportunityList = sentenceList(opportunities)

        if selectedMode == .quiet || isQuiet(display) {
            return "You are on Quiet Mode for this date."
        }

        if isRamadan(entry) {
            if selectedMode == .fast {
                return "You are waking early for Ramadan."
            }
            return "This is a Ramadan date."
        }

        switch selectedMode {
        case .fajr:
            if opportunities.isEmpty {
                return "There are no fasting opportunities for this date. You can still choose an early fasting wake for a Voluntary, Qada, Vow, Kaffarah, or Other fast."
            }
            return "This day has fasting opportunities: \(opportunityList)."
        case .fast:
            if purpose?.selection == .tahajjud {
                if opportunities.isEmpty {
                    return "You are waking early for Tahajjud. There are no fasting opportunities for this date."
                }
                return "You are waking early for Tahajjud. This day also has fasting opportunities: \(opportunityList)."
            }
            if opportunities.isEmpty {
                return "You are waking early to fast. This will be saved as a Voluntary fast unless you choose another fast type."
            }
            return "You are waking early to fast. Today's fasting opportunities will apply by default."
        case .quiet:
            return "You are on Quiet Mode for this date."
        }
    }

    private static func defaultFastPurposeTitle(for entry: WakeRowEntry) -> String {
        let opportunities = fastingOpportunityTitles(for: entry)
        if !opportunities.isEmpty {
            return "Today's opportunities"
        }
        return "Voluntary fast"
    }

    private static func fastPurposeOptions(defaultTitle: String) -> [AlarmDetailFastPurposeOption] {
        var seenTitles: Set<String> = []
        var options: [AlarmDetailFastPurposeOption] = []

        func append(selection: AlarmDetailFastTypeOverride?, title: String) {
            guard seenTitles.insert(title).inserted else { return }
            options.append(AlarmDetailFastPurposeOption(selection: selection, title: title))
        }

        append(selection: nil, title: defaultTitle)
        AlarmDetailFastTypeOverride.allCases.forEach { option in
            append(selection: option, title: option.displayTitle)
        }
        return options
    }

    private static func fastingOpportunityTitles(for entry: WakeRowEntry) -> [String] {
        let tags = Set(entry.activeDay.resolvedDayContext.supportingTags)
        var titles: [String] = []
        if tags.contains(.arafah) { titles.append("Arafah fast") }
        if tags.contains(.ashura) { titles.append("Ashura fast") }
        if tags.contains(.dhulHijjahFirstNine) { titles.append("Dhul Hijjah fast") }
        if tags.contains(.whiteDays) { titles.append("White Days fast") }
        if tags.contains(.shawwalSix) { titles.append("Shawwal Six fast") }
        if tags.contains(.mondayThursday) { titles.append(weekdayFastTitle(for: entry.activeDay.date)) }
        return titles
    }

    private static func weekdayFastTitle(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2:
            return "Monday fast"
        case 5:
            return "Thursday fast"
        default:
            return "Monday / Thursday fast"
        }
    }

    private static func sentenceList(_ items: [String]) -> String {
        switch items.count {
        case 0:
            return ""
        case 1:
            return items[0]
        case 2:
            return "\(items[0]) and \(items[1])"
        default:
            let head = items.dropLast().joined(separator: ", ")
            return "\(head), and \(items[items.count - 1])"
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
