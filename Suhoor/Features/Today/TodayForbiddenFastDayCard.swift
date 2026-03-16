import SwiftUI

struct TodayForbiddenFastDayCard: View {
    let kind: FastWarning
    let mode: TodaySeasonalCardMode
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedAbout: FastTagAbout?

    private let accentColor = DawnColor.danger

    var body: some View {
        if let model = ForbiddenFastDayEngine.model(kind: kind, mode: mode, now: Date()) {
            AppGlassSurface(variant: .tinted, tint: accentColor) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                            Text(model.title)
                                .font(DesignTokens.cardTitleFont)
                            Text(model.message)
                                .font(DesignTokens.cardSubtitleFont.weight(.semibold))
                                .foregroundStyle(accentColor)
                        }

                        Spacer()

                        HStack(spacing: DesignTokens.spacingXS) {
                            if kind == .eidAlFitr {
                                HijriMonthAdjustmentMenu(
                                    month: .shawwal,
                                    iconSystemName: "moon.stars.fill",
                                    accent: accentColor
                                )
                            }

                            Button {
                                withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                                    onDismiss()
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .appToolbarButtonChrome()
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Dismiss card")
                        }
                    }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous))
            .onTapGesture {
                selectedAbout = kind.about
            }
            .sheet(item: $selectedAbout) { about in
                AboutTagSheet(about: about)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
