import Foundation

enum CompletionHistoryProjectionBuilder {
    static func buildFajr(window: CompletionHistoryWindow) -> FajrHistorySurfaceSnapshot {
        let rows = window.resolvedDays.map { snapshot in
            FajrHistoryRowSnapshot(
                dateKey: snapshot.dateKey,
                gregorianText: GregorianDateFormatter.shared.cardString(for: snapshot.date),
                hijriText: HijriDateFormatter.shared.shortString(from: snapshot.date),
                fajrTimeText: TimeFormatters.timeFormatter.string(from: snapshot.prayerWindow.fajrStart),
                status: snapshot.dailyCompletion.prayer.status,
                statusText: prayerStatusText(snapshot.dailyCompletion.prayer.status),
                canClear: snapshot.dailyCompletion.prayer.status != .unknown
            )
        }

        return FajrHistorySurfaceSnapshot(
            summaryText: historySummary(
                completed: rows.filter { $0.status == .completed }.count,
                missed: rows.filter { $0.status == .missed }.count,
                empty: "No prayer check-ins yet",
                completedLabel: "prayed"
            ),
            rows: rows,
            emptyText: "No mornings available yet.",
            footerText: Strings.HistorySurface.fajrFooter
        )
    }

    static func buildFast(window: CompletionHistoryWindow) -> FastHistorySurfaceSnapshot {
        let rows = window.resolvedDays.compactMap { snapshot -> FastHistoryRowSnapshot? in
            let completion = snapshot.dailyCompletion
            guard completion.fast.status != .notRequired else { return nil }

            return FastHistoryRowSnapshot(
                dateKey: snapshot.dateKey,
                gregorianText: GregorianDateFormatter.shared.cardString(for: snapshot.date),
                hijriText: HijriDateFormatter.shared.shortString(from: snapshot.date),
                meaningText: fastMeaningText(snapshot: snapshot),
                status: completion.fast.status,
                statusText: fastStatusText(completion.fast.status),
                qadaEffectText: qadaEffectText(from: completion),
                intentSnapshot: completion.fast.intentSnapshot,
                canClear: completion.fast.status != .unknown
            )
        }

        let fastSummary: String
        if rows.isEmpty {
            fastSummary = "No fasting days in the last 30 days"
        } else {
            fastSummary = historySummary(
                completed: rows.filter { $0.status == .completed }.count,
                missed: rows.filter { $0.status == .notCompleted }.count,
                empty: "No fast outcomes logged yet",
                completedLabel: "completed"
            )
        }

        return FastHistorySurfaceSnapshot(
            summaryText: fastSummary,
            rows: rows,
            emptyText: "No fasting days in the last 30 days.",
            footerText: Strings.HistorySurface.fastFooter
        )
    }

    private static func prayerStatusText(_ status: PrayerCompletionStatus) -> String {
        switch status {
        case .unknown:
            return "Not logged"
        case .completed:
            return "Prayed"
        case .missed:
            return "Not prayed"
        }
    }

    private static func fastStatusText(_ status: FastCompletionStatus) -> String {
        switch status {
        case .notRequired:
            return "Not required"
        case .unknown:
            return "Not logged"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .notCompleted:
            return "Not completed"
        }
    }

    private static func fastMeaningText(snapshot: ResolvedDaySnapshot) -> String {
        let completion = snapshot.dailyCompletion
        if completion.qadaEffect.countsTowardQada || completion.fast.intentSnapshot?.primaryIntent == .qadaMakeup {
            return "Qada fast"
        }
        if snapshot.resolvedDayContext.supportingTags.contains(.ramadan)
            || completion.fast.intentSnapshot?.primaryIntent == .ramadanObligatory {
            return "Ramadan fast"
        }
        if let intentSnapshot = completion.fast.intentSnapshot {
            if intentSnapshot.primaryIntent == .voluntary,
               let secondary = intentSnapshot.secondaryTags.sorted(by: { $0.title < $1.title }).first {
                return secondary.shortTitle
            }
            return intentSnapshot.primaryIntent.shortTitle
        }

        return ProductSurfacePresentation.primaryContextTitle(snapshot.resolvedDayContext.primaryContext)
    }

    private static func qadaEffectText(from completion: DailyCompletionSnapshot) -> String? {
        guard completion.qadaEffect.countsTowardQada else { return nil }
        if let remaining = completion.qadaEffect.remainingAfterEffect {
            return "Counts toward Qada · \(remaining) remaining"
        }
        return completion.qadaEffect.explanation ?? "Counts toward Qada"
    }

    private static func historySummary(
        completed: Int,
        missed: Int,
        empty: String,
        completedLabel: String
    ) -> String {
        guard completed > 0 || missed > 0 else { return empty }
        var parts: [String] = []
        if completed > 0 {
            parts.append("\(completed) \(completedLabel)")
        }
        if missed > 0 {
            parts.append("\(missed) missed")
        }
        return parts.joined(separator: " · ")
    }
}
