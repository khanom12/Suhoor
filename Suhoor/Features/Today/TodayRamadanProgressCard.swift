import SwiftUI

struct TodayRamadanProgressCard: View {
    let mode: TodaySeasonalCardMode

    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        if let model = RamadanProgressEngine.model(now: Date(), mode: mode, calendar: .shared, timeZone: .current) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            Text("Ramadan \(String(model.hijriYear))")
                                .font(DesignTokens.cardTitleFont)

                            Spacer()

                            TodaySeasonalBadge(
                                text: "Day \(model.dayNumber)",
                                accent: nil
                            )
                        }

                        progressRow(progress: model.progress)
                    }
                }
            }
            .onAppear { _ = hijriChangeCount }
        } else {
            EmptyView()
        }
    }

    private func progressRow(progress: Double) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            HijriMonthAdjustmentMenu(
                month: .ramadan,
                iconSystemName: "moonphase.new.moon",
                accent: DawnColor.accent
            )

            ProgressView(value: progress)
                .tint(DawnColor.accent)
                .accessibilityLabel("Ramadan progress")
                .accessibilityValue(progressAccessibilityValue)

            HijriMonthAdjustmentMenu(
                month: .shawwal,
                iconSystemName: "moon.stars.fill",
                accent: DawnColor.accent
            )
        }
    }

    private var currentRamadanAdjustment: Int {
        scheduleManager.hijriAdjustment(for: .ramadan, hijriYear: scheduleManager.currentHijriAdjustmentYear)
    }

    private var currentShawwalAdjustment: Int {
        scheduleManager.hijriAdjustment(for: .shawwal, hijriYear: scheduleManager.currentHijriAdjustmentYear)
    }

    private var shouldShowTotalDays: Bool {
        currentRamadanAdjustment == 0 && currentShawwalAdjustment == 0
    }

    private var progressAccessibilityValue: String {
        guard let model = RamadanProgressEngine.model(now: Date(), mode: mode, calendar: .shared, timeZone: .current) else {
            return "Progress unavailable"
        }
        guard shouldShowTotalDays, mode == .live else {
            return "Day \(model.dayNumber)"
        }
        return "Day \(model.dayNumber) of \(model.totalDays)"
    }
}
