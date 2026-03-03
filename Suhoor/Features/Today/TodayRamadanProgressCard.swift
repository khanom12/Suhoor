import SwiftUI

struct TodayRamadanProgressCard: View {
    private let calendar = AdjustedHijriCalendar.shared

    var body: some View {
        let now = Date()
        guard let model = model(for: now) else {
            EmptyView()
            return
        }

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

                Text(model.detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func model(for date: Date) -> Model? {
        let timeZone = TimeZone.current
        guard calendar.isRamadan(date: date, timeZone: timeZone) else { return nil }
        guard let components = calendar.adjustedComponents(for: date, timeZone: timeZone) else { return nil }
        guard components.month == .ramadan else { return nil }

        let year = components.hijriYear
        let ramadanKey = HijriYearMonth(hijriYear: year, month: .ramadan)
        let shawwalKey = HijriYearMonth(hijriYear: year, month: .shawwal)

        let ramadanStart = calendar.gregorianDate(for: ramadanKey, dayOfMonth: 1, timeZone: timeZone)
        let shawwalStart = calendar.gregorianDate(for: shawwalKey, dayOfMonth: 1, timeZone: timeZone)

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let todayStart = gregorian.startOfDay(for: date)

        let totalDays: Int
        if let ramadanStart, let shawwalStart {
            let diff = gregorian.dateComponents([.day], from: gregorian.startOfDay(for: ramadanStart), to: gregorian.startOfDay(for: shawwalStart)).day
            totalDays = max(1, diff ?? 30)
        } else {
            totalDays = 30
        }

        let daysUntilEid: Int
        if let shawwalStart {
            let diff = gregorian.dateComponents([.day], from: todayStart, to: gregorian.startOfDay(for: shawwalStart)).day
            daysUntilEid = max(0, diff ?? 0)
        } else {
            daysUntilEid = 0
        }

        let dayNumber = max(1, min(totalDays, components.day))
        let progress = Double(dayNumber) / Double(totalDays)

        let detailText: String
        if let shawwalStart {
            detailText = "Eid starts on \(TimeFormatters.shortDate.string(from: shawwalStart))."
        } else {
            detailText = "Eid date unavailable for your current Hijri baseline."
        }

        return Model(
            dayNumber: dayNumber,
            totalDays: totalDays,
            daysUntilEid: daysUntilEid,
            progress: progress,
            detailText: detailText
        )
    }

    private struct Model: Equatable {
        let dayNumber: Int
        let totalDays: Int
        let daysUntilEid: Int
        let progress: Double
        let detailText: String
    }
}

