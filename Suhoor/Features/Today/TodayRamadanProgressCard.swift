import SwiftUI

struct TodayRamadanProgressCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        if let model = RamadanProgressEngine.model(now: Date(), calendar: .shared, timeZone: .current) {
            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            Text("Ramadan")
                                .font(DesignTokens.cardTitleFont)

                            Spacer()

                            Text("Day \(model.dayNumber)")
                                .font(DesignTokens.cardMetaFont)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DesignTokens.spacingS)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }

                        ProgressView(value: model.progress)
                            .tint(DawnColor.accent)

                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            if model.daysUntilEid == 0 {
                                Text("Eid is next")
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(model.daysUntilEid) days until Eid")
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let eidDateText = model.eidDateText {
                                Label(eidDateText, systemImage: "moon.stars")
                                    .font(DesignTokens.cardMetaFont)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Button("Adjust Hijri Calendar") {
                            NotificationCenter.default.post(name: .switchToHijriCorrections, object: nil)
                        }
                        .font(DesignTokens.cardMetaFont)

                        Spacer()
                    }
                }
            }
            .onAppear { _ = hijriChangeCount }
        } else {
            EmptyView()
        }
    }
}
