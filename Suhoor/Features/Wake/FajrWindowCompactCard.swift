import SwiftUI

struct FajrWindowCompactCard: View {
    let snapshot: FajrWindowCompactSnapshot
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                            Text("Fajr Window")
                                .font(AppTypography.cardTitle)
                            Text(snapshot.period.subtitle)
                                .font(AppTypography.cardBody)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: DesignTokens.spacingS)

                        Image(systemName: "sun.horizon")
                            .font(AppTypography.cardSymbol)
                            .foregroundStyle(.secondary)
                    }

                    FajrWindowChartView(chart: snapshot.chart, layoutStyle: .compact)

                    Text(snapshot.compactInsight)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fajr Window")
        .accessibilityValue("\(snapshot.period.subtitle). \(snapshot.compactInsight)")
        .accessibilityHint("Double-tap for details.")
    }
}
