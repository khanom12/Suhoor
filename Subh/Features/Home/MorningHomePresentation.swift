import Foundation

struct MorningHomeHeroDisplay: Equatable {
    let title: String
    let dateLine: String?
    let statusText: String
    let detailText: String
    let chipTitles: [String]
    let accessibilityLabel: String
}

struct MorningcastRowDisplay: Equatable {
    let title: String
    let subtitle: String?
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let accessibilityLabel: String
}

enum MorningHomePresentation {
    static func heroDisplay(
        entry: WakeRowEntry?,
        permissionSummary: String,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> MorningHomeHeroDisplay {
        guard let entry else {
            let detail = permissionSummary.isEmpty
                ? "Subh will show tomorrow once schedule data is available."
                : permissionSummary
            return MorningHomeHeroDisplay(
                title: "Tomorrow",
                dateLine: nil,
                statusText: "Morning not resolved yet",
                detailText: detail,
                chipTitles: [],
                accessibilityLabel: "Tomorrow. Morning not resolved yet. \(detail)"
            )
        }

        let dateLine = compactDateFormatter(timeZone: timeZone).string(from: entry.schedule.date)
        let statusText = heroStatusText(for: entry)
        let detailText = conciseWakeRelation(for: entry)
        let chipTitles = actionableChipTitles(for: entry)
        let wakeText = entry.isEnabled
            ? "Wake at \(TimeFormatters.timeFormatter.string(from: entry.schedule.wakeDate))"
            : "No wake scheduled"

        return MorningHomeHeroDisplay(
            title: "Tomorrow",
            dateLine: dateLine,
            statusText: statusText,
            detailText: detailText,
            chipTitles: chipTitles,
            accessibilityLabel: [
                "Tomorrow",
                dateLine,
                wakeText,
                statusText,
                detailText
            ]
                .compactMap { $0 }
                .joined(separator: ". ")
        )
    }

    static func morningcastEntries(
        from entries: [WakeRowEntry],
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [WakeRowEntry] {
        MorningHomeSnapshot.morningcastEntries(
            from: entries,
            currentDate: currentDate,
            timeZone: timeZone
        )
    }

    static func shouldShowInMorningcast(
        _ entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        MorningHomeSnapshot.shouldShowInMorningcast(entry, currentDate: currentDate, timeZone: timeZone)
    }

    static func morningcastRowDisplay(
        for entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> MorningcastRowDisplay {
        let fullDisplay = WakePagePresentation.row(
            for: entry,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return MorningcastRowDisplay(
            title: fullDisplay.title,
            subtitle: compactMorningcastSubtitle(for: entry),
            trailingTime: fullDisplay.trailingTime,
            trailingStatusText: fullDisplay.trailingStatusText,
            isInactive: fullDisplay.isInactive,
            accessibilityLabel: fullDisplay.accessibilityLabel
        )
    }

    private static func heroStatusText(for entry: WakeRowEntry) -> String {
        if !entry.isEnabled {
            return "No wake scheduled"
        }
        if entry.rowPresentation.availability.state == .activeOverride {
            return "Changed wake"
        }

        let context = entry.activeDay.resolvedDayContext
        let tags = Set(context.supportingTags)
        if context.primaryContext == .qadaFast || tags.contains(.qada) {
            return "Qada planned"
        }
        if context.primaryContext == .tahajjud || entry.activeDay.effectiveConfig.tahajjudRefinement {
            return "Tahajjud planned"
        }
        if context.primaryContext == .fasting
            || context.primaryContext == .suhoor
            || context.primaryContext == .sunnahFast
            || tags.contains(.ramadan)
            || tags.contains(.voluntary) {
            return "Fasting morning"
        }

        return "Wake alarm"
    }

    private static func conciseWakeRelation(for entry: WakeRowEntry) -> String {
        if !entry.isEnabled {
            return entry.activeDay.effectiveConfig.skipDay ? "No wake for this date" : "No wake scheduled"
        }
        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            return "Fixed wake"
        }
        return ProductSurfacePresentation.wakeOffsetText(for: entry.activeDay)
    }

    private static func actionableChipTitles(for entry: WakeRowEntry) -> [String] {
        let redundantTitles: Set<String> = [
            "Fasting",
            "Qada",
            "Tahajjud",
            "Changed",
            "Skipped",
            "Fixed wake",
            "Daily plan",
            "Location-based"
        ]

        return entry.rowPresentation.chipTitles
            .filter { title in
                !redundantTitles.contains(title)
            }
            .prefix(2)
            .map { $0 }
    }

    private static func compactMorningcastSubtitle(for entry: WakeRowEntry) -> String? {
        if !entry.isEnabled {
            return "No wake for this date"
        }
        if entry.rowPresentation.availability.state == .activeOverride {
            return "Changed wake"
        }
        if entry.activeDay.decisionLog.latestWakeCapApplied {
            return "Moved earlier"
        }
        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            return "Fixed wake"
        }

        let status = heroStatusText(for: entry)
        return status == "Wake alarm" ? nil : status
    }

    private static func compactDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }
}
