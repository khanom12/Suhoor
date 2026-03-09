import Foundation

struct CompletionSurfaceProvider {
    func progressSurfaceSnapshot(
        activeWindowSnapshot: ActiveAlarmWindowSnapshot,
        now: Date = Date(),
        completionState: CompletionStateSnapshot,
        settings: AppSettings,
        wakeProgress: WakeProgressSnapshot
    ) -> ProgressSurfaceSnapshot {
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: .current)
        let todayCompletion = activeWindowSnapshot.byDateKey[todayKey]?.dailyCompletion
            ?? DailyCompletionResolver.resolve(
                dateKey: todayKey,
                resolvedDayContext: activeWindowSnapshot.byDateKey[todayKey]?.resolvedDayContext ?? .standard,
                completionState: completionState
            )
        let todayResolvedDayContext = activeWindowSnapshot.byDateKey[todayKey]?.resolvedDayContext
        return CompletionProjectionBuilder.buildProgress(
            todayCompletion: todayCompletion,
            todayResolvedDayContext: todayResolvedDayContext,
            recentDateKeys: recentDateKeys(days: 30, now: now),
            completionState: completionState,
            settings: settings,
            wakeProgress: wakeProgress
        )
    }

    func fajrHistorySurfaceSnapshot(
        days: Int = 30,
        now: Date = Date(),
        resolver: CompletionHistoryResolver
    ) -> FajrHistorySurfaceSnapshot {
        let window = completionHistoryWindow(
            days: days,
            now: now,
            resolver: resolver
        )
        return CompletionHistoryProjectionBuilder.buildFajr(window: window)
    }

    func fastHistorySurfaceSnapshot(
        days: Int = 30,
        now: Date = Date(),
        resolver: CompletionHistoryResolver
    ) -> FastHistorySurfaceSnapshot {
        let window = completionHistoryWindow(
            days: days,
            now: now,
            resolver: resolver
        )
        return CompletionHistoryProjectionBuilder.buildFast(window: window)
    }

    private func completionHistoryWindow(
        days: Int,
        now: Date,
        resolver: CompletionHistoryResolver
    ) -> CompletionHistoryWindow {
        CompletionHistoryWindowBuilder.build(
            days: days,
            now: now,
            timeZone: .current
        ) { date in
            resolver.resolveDaySnapshot(for: date, timeZone: .current)
        }
    }

    private func recentDateKeys(
        days: Int,
        now: Date,
        timeZone: TimeZone = .current
    ) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)
        return (0..<days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        }
    }
}
