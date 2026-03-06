import SwiftUI

struct CalendarLegendRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LegendItem(label: "Selected") {
                    Circle()
                        .fill(DawnColor.accent.opacity(0.22))
                        .overlay(Circle().stroke(DawnColor.accent, lineWidth: 1.3))
                }

                LegendItem(label: "Suggested") {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                        .foregroundStyle(DawnColor.lightGold200)
                }

                LegendItem(label: "Blocked") {
                    Circle()
                        .fill(Color.secondary.opacity(0.08))
                        .overlay(Circle().stroke(Color.secondary.opacity(0.35), lineWidth: 1))
                        .overlay(
                            Rectangle()
                                .fill(Color.secondary.opacity(0.6))
                                .frame(width: 12, height: 1.4)
                                .rotationEffect(.degrees(-45))
                        )
                }

                LegendItem(label: "Today") {
                    Circle()
                        .stroke(DawnColor.highlight.opacity(0.9), lineWidth: 1.2)
                        .overlay(Circle().fill(DawnColor.highlight).frame(width: 4, height: 4))
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct LegendItem<Indicator: View>: View {
    let label: String
    @ViewBuilder let indicator: () -> Indicator

    var body: some View {
        HStack(spacing: 8) {
            indicator()
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
