import SwiftUI

struct TodayForbiddenFastDayCard: View {
    let kind: FastWarning
    let mode: TodaySeasonalCardMode

    private let accentColor = DawnColor.danger

    var body: some View {
        if let model = ForbiddenFastDayEngine.model(kind: kind, mode: mode, now: Date()) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.title)
                                .font(DesignTokens.cardTitleFont)
                            Text(model.message)
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(accentColor)
                        }

                        Spacer()

                        Text(model.badgeText)
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(model.isLive ? accentColor : .secondary)
                            .padding(.horizontal, DesignTokens.spacingS)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }

                    Text(model.detail)
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        Button("Hijri Calendar Settings") {
                            NotificationCenter.default.post(name: .switchToHijriCorrections, object: nil)
                        }
                        .font(DesignTokens.cardMetaFont)

                        Spacer(minLength: 0)

                        if mode == .preview {
                            Text("Shown automatically on the day.")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
