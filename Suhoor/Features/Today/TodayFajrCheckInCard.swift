import SwiftUI

struct TodayFajrCheckInCard: View {
    @EnvironmentObject private var fajrLogStore: FajrLogStore
    let presentation: FajrHomeSupportPresentation
    var onLater: (() -> Void)? = nil

    var body: some View {
        AppGlassSurface(variant: .quiet, tint: DawnColor.lightGold200) {
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
                    .appControlStyle(.primary, tint: .green)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            fajrLogStore.setStatus(.missed, for: presentation.dateKey, now: Date())
                        }
                    } label: {
                        Text(Strings.HomeSurface.fajrPromptSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .appControlStyle(.secondary, tint: .secondary)
                }

                if let onLater {
                    Button(Strings.HomeSurface.fajrPromptLater, action: onLater)
                        .font(.footnote.weight(.semibold))
                        .appControlStyle(.quiet)
                }
            }
        }
    }
}
