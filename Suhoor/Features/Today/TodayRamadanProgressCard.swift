import SwiftUI

struct TodayRamadanProgressCard: View {
    var body: some View {
        if let model = RamadanProgressEngine.model(now: Date(), calendar: .shared, timeZone: .current) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ramadan")
                                .font(.headline.weight(.semibold))
                            Text("Day \(model.dayNumber) of \(model.totalDays)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(model.daysUntilEid) days until Eid")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: model.progress)
                        .tint(DawnColor.accent)

                    Text(model.eidDateText.map { "Eid starts on \($0)." } ?? "Eid date unavailable for your current Hijri baseline.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            EmptyView()
        }
    }
}
