import SwiftUI

struct FajrWindowCompactCard: View {
    let snapshot: FajrWindowCompactSnapshot
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fajr Window")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(snapshot.period.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: DesignTokens.spacingS)

                        Image(systemName: "sun.horizon")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    FajrWindowChartView(chart: snapshot.chart, layoutStyle: .compact)

                    Text(snapshot.compactInsight)
                        .font(.footnote)
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
