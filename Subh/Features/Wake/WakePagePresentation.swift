import Foundation

struct WakePageRowDisplay: Equatable {
    let title: String
    let subtitle: String
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let accessibilityLabel: String
}

struct WakePageCardDisplay: Equatable {
    let overline: String
    let dateLabel: String
    let title: String
    let subtitle: String
    let badgeTitle: String?
    let isInactive: Bool
    let accessibilityLabel: String
}

enum WakePagePresentation {
    static let nextWakeOverline = "NEXT WAKE"
    static let adjustedLabel = "Adjusted"
    static let ordinaryMeaningText = "Regular Fajr morning"
    static let noWakeSetText = "No wake set"
    static let skippedForDateText = "Skipped for this date"
    static let noWakeTrailingText = "No wake"

    static func row(
        for entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> WakePageRowDisplay {
        let title = WakeRowPresentation.dateLabel(
            for: entry.schedule.date,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let subtitle = rowSummary(for: entry)
        let accessibilityLabel = accessibilityLabel(
            for: entry,
            title: title,
            subtitle: subtitle,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return WakePageRowDisplay(
            title: title,
            subtitle: subtitle,
            trailingTime: isSkipped(entry) ? nil : entry.schedule.wakeDate,
            trailingStatusText: isSkipped(entry) ? noWakeTrailingText : nil,
            isInactive: isSkipped(entry),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func card(
        for entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> WakePageCardDisplay {
        let dateLabel = WakeRowPresentation.dateLabel(
            for: entry.schedule.date,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let title = normalizedMeaningText(for: entry, includeOrdinary: true) ?? ordinaryMeaningText
        let subtitle = cardSummary(for: entry)
        let accessibilityLabel = accessibilityLabel(
            for: entry,
            title: title,
            subtitle: subtitle,
            currentDate: currentDate,
            timeZone: timeZone
        )

        return WakePageCardDisplay(
            overline: nextWakeOverline,
            dateLabel: dateLabel,
            title: title,
            subtitle: subtitle,
            badgeTitle: isAdjusted(entry) ? adjustedLabel : nil,
            isInactive: isSkipped(entry),
            accessibilityLabel: accessibilityLabel
        )
    }

    private static func rowSummary(for entry: WakeRowEntry) -> String {
        var parts: [String] = []

        if let meaning = normalizedMeaningText(
            for: entry,
            includeOrdinary: !isAdjusted(entry) && !isSkipped(entry)
        ) {
            parts.append(meaning)
        }

        if isAdjusted(entry) {
            parts.append(adjustedLabel)
        }

        parts.append(primaryTimingText(for: entry))

        if let secondaryTiming = secondaryTimingText(for: entry) {
            parts.append(secondaryTiming)
        }

        return parts.joined(separator: " • ")
    }

    private static func cardSummary(for entry: WakeRowEntry) -> String {
        var parts = [primaryTimingText(for: entry)]
        if let secondaryTiming = secondaryTimingText(for: entry) {
            parts.append(secondaryTiming)
        }
        return parts.joined(separator: " • ")
    }

    private static func primaryTimingText(for entry: WakeRowEntry) -> String {
        if isSkipped(entry) {
            return entry.hasDayOverride ? skippedForDateText : noWakeSetText
        }

        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            return entry.hasDayOverride ? "Fixed wake for this date" : "Fixed wake"
        }

        return entry.rowPresentation.detailText
    }

    private static func secondaryTimingText(for entry: WakeRowEntry) -> String? {
        guard entry.activeDay.decisionLog.latestWakeCapApplied else { return nil }
        return "Moved earlier by latest wake"
    }

    private static func normalizedMeaningText(
        for entry: WakeRowEntry,
        includeOrdinary: Bool
    ) -> String? {
        let meaning = entry.rowPresentation.meaningText

        switch meaning {
        case ProductSurfacePresentation.ordinaryDaySummaryText:
            return includeOrdinary ? ordinaryMeaningText : nil
        case "Qada planned":
            return "Qada fast"
        case "Fasting tomorrow":
            return "Fasting day"
        default:
            return meaning
        }
    }

    private static func accessibilityLabel(
        for entry: WakeRowEntry,
        title: String,
        subtitle: String,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        var parts = [
            WakeRowPresentation.accessibilityDateLabel(
                for: entry.schedule.date,
                currentDate: currentDate,
                timeZone: timeZone
            )
        ]

        if isSkipped(entry) {
            parts.append(primaryTimingText(for: entry))
        } else {
            parts.append("Wake at \(TimeFormatters.timeFormatter.string(from: entry.schedule.wakeDate))")
        }

        parts.append(title)
        parts.append(contentsOf: subtitle.components(separatedBy: " • "))

        return parts.joined(separator: ". ") + "."
    }

    private static func isAdjusted(_ entry: WakeRowEntry) -> Bool {
        entry.rowPresentation.availability.state == .activeOverride
    }

    private static func isSkipped(_ entry: WakeRowEntry) -> Bool {
        entry.rowPresentation.availability.state == .skipped
    }
}
