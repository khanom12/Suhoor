import SwiftUI

struct TodayFajrCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fajrLogStore: FajrLogStore

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            card(now: context.date)
        }
    }

    @ViewBuilder
    private func card(now: Date) -> some View {
        let calendar = todayCalendar(timeZone: .current)
        let todayStart = calendar.startOfDay(for: now)
        let dateKey = DateHelpers.dayIdentifier(for: todayStart, timeZone: .current)
        let schedule = scheduleManager.schedule(for: todayStart)
            ?? scheduleManager.activeWindowSnapshot.byDateKey[dateKey]?.schedule

        if let schedule {
            GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Did you make Fajr?")
                                .font(DesignTokens.cardTitleFont)

                            Text("Fajr was at \(TimeFormatters.timeFormatter.string(from: schedule.fajrDate)).")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        NavigationLink {
                            FajrHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(DesignTokens.cardMetaFont.weight(.semibold))
                                .foregroundStyle(DawnColor.accent)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open Fajr completion history")
                    }

                    HStack(spacing: DesignTokens.spacingS) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                fajrLogStore.setStatus(.completed, for: dateKey, now: now)
                            }
                        } label: {
                            Text("Yes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                fajrLogStore.setStatus(.missed, for: dateKey, now: now)
                            }
                        } label: {
                            Text("Missed")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
            }
        }
    }

    private func todayCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
