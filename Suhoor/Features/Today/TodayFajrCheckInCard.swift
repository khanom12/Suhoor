import SwiftUI

struct TodayFajrCheckInCard: View {
    @EnvironmentObject private var fajrLogStore: FajrLogStore
    let presentation: FajrHomeSupportPresentation

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(presentation.title)
                        .font(DesignTokens.cardTitleFont)

                    Text(presentation.detail)
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: DesignTokens.spacingS) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            fajrLogStore.setStatus(.completed, for: presentation.dateKey, now: Date())
                        }
                    } label: {
                        Text(Strings.HomeSurface.fajrPromptPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            fajrLogStore.setStatus(.missed, for: presentation.dateKey, now: Date())
                        }
                    } label: {
                        Text(Strings.HomeSurface.fajrPromptSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }

                Text(Strings.HomeSurface.fajrPromptLater)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DawnColor.accent)
            }
        }
    }
}
