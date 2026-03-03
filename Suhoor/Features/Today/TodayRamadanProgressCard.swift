import SwiftUI

struct TodayRamadanProgressCard: View {
    var body: some View {
        if let model = RamadanProgressEngine.model(now: Date(), calendar: .shared, timeZone: .current) {
            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: DesignTokens.dashboardCardHeaderSpacing) {
                            Text("Ramadan")
                                .font(DesignTokens.cardTitleFont)
                            Text("Day \(model.dayNumber) of \(model.totalDays)")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(model.daysUntilEid) days until Eid")
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(DawnColor.accent)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        ProgressView(value: model.progress)

                        HStack {
                            Text("1")
                            Spacer()
                            Text("\(model.totalDays)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Text(model.eidDateText.map { "Eid starts on \($0)." } ?? "Eid date unavailable for your current Hijri baseline.")
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            EmptyView()
        }
    }
}
