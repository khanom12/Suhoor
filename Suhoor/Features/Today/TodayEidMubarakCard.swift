import SwiftUI

struct TodayEidMubarakCard: View {
    let mode: TodaySeasonalCardMode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrationTrigger = 0
    @State private var pulse = false

    var body: some View {
        if let model = EidMubarakEngine.model(now: Date(), mode: mode) {
            GlassCard(style: .header, padding: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DawnColor.highlight.opacity(0.18),
                                    DawnColor.accent.opacity(0.14),
                                    Color(.secondarySystemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if reduceMotion {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(DawnColor.highlight.opacity(pulse ? 0.95 : 0.55))
                            .scaleEffect(pulse ? 1.08 : 0.92)
                    } else {
                        FireworksEmitterView(trigger: celebrationTrigger)
                            .allowsHitTesting(false)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Eid Mubarak")
                                    .font(DesignTokens.cardTitleFont)
                                Text(model.subtitle)
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            TodaySeasonalBadge(
                                text: "Celebrate",
                                accent: mode == .live ? DawnColor.highlight : DawnColor.highlight
                            )
                        }

                        Text(model.message)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignTokens.dashboardCardPadding)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous))
                .onTapGesture {
                    celebrationTrigger += 1
                    Haptics.medium()
                    if reduceMotion {
                        withAnimation(Motion.emphasis(reduceMotion: reduceMotion)) {
                            pulse = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                                pulse = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EidMubarakEngine {
    struct Model: Equatable, Sendable {
        let subtitle: String
        let message: String
    }

    static func model(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> Model? {
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone) else {
            return nil
        }

        switch mode {
        case .live:
            if components.month == .shawwal, components.day == 1 {
                return Model(subtitle: "Eid al-Fitr", message: "Celebrate the close of Ramadan. Tap the card for a fireworks burst.")
            }
            if components.month == .dhulHijjah, components.day == 10 {
                return Model(subtitle: "Eid al-Adha", message: "Celebrate Eid al-Adha. Tap the card for a fireworks burst.")
            }
            return nil
        case .reference:
            if components.month.rawValue < HijriMonth.shawwal.rawValue
                || (components.month == .shawwal && components.day <= 1) {
                return Model(subtitle: "Eid al-Fitr", message: "Celebrate the close of Ramadan. Tap the card for a fireworks burst.")
            }
            return Model(subtitle: "Eid al-Adha", message: "Celebrate Eid al-Adha. Tap the card for a fireworks burst.")
        }
    }
}
