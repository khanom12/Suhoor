import SwiftUI

struct CalendarLegendRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LegendItem(label: "Selected Qada", fill: DawnColor.accent.opacity(0.18), stroke: DawnColor.accent)
                LegendItem(label: "Suggested", fill: DawnColor.lightGold200.opacity(0.22), stroke: DawnColor.lightGold200)
                LegendItem(label: "Not allowed", fill: FastPrimaryIntent.forbidden.style.color.opacity(0.22), stroke: FastPrimaryIntent.forbidden.style.color)
                LegendItem(label: "Observance day", fill: FastSecondaryVirtueTag.whiteDays.style.color.opacity(0.18), stroke: FastSecondaryVirtueTag.whiteDays.style.color)
                LegendItem(label: "Today", fill: .clear, stroke: DawnColor.highlight)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct LegendItem: View {
    let label: String
    let fill: Color
    let stroke: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(fill)
                .overlay(Circle().stroke(stroke, lineWidth: 1.4))
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
