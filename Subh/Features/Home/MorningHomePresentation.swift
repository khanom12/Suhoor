import Foundation

enum MorningHeroWakeState: String, Equatable {
    case active
    case offWithAnchor
    case noAlarm
    case quietHours
    case unavailable
}

enum MorningHeroWakeWindowIndicatorState: String, Equatable {
    case active
    case offAnchor
    case none
    case unavailable
}

struct MorningHomeHeroDisplay: Equatable {
    let title: String
    let dateLine: String?
    let wakeState: MorningHeroWakeState
    let primaryTime: Date?
    let primaryText: String
    let wakeIconName: String?
    let statusText: String
    let detailText: String
    let fajrWindowLine: String
    let fajrBeginDisplayText: String?
    let fajrEndDisplayText: String?
    let wakeWindowPositionRatio: Double?
    let wakeWindowIndicatorState: MorningHeroWakeWindowIndicatorState
    let fajrWindowAccessibilityText: String?
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
        timeZone: TimeZone = .current,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil,
        accessibleHijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil
    ) -> MorningHomeHeroDisplay {
        guard let entry else {
            let detail = permissionSummary.isEmpty
                ? "Subh will show tomorrow once schedule data is available."
                : permissionSummary
            return MorningHomeHeroDisplay(
                title: "Tomorrow",
                dateLine: nil,
                wakeState: .unavailable,
                primaryTime: nil,
                primaryText: "Wake time unavailable",
                wakeIconName: nil,
                statusText: "Wake time unavailable",
                detailText: detail,
                fajrWindowLine: "Fajr times are not available yet",
                fajrBeginDisplayText: nil,
                fajrEndDisplayText: nil,
                wakeWindowPositionRatio: nil,
                wakeWindowIndicatorState: .unavailable,
                fajrWindowAccessibilityText: nil,
                chipTitles: [],
                accessibilityLabel: "Tomorrow. Wake time unavailable. \(detail). Fajr times are not available yet."
            )
        }

        let title = relativeDayLabel(
            targetDate: entry.schedule.date,
            wakeDate: entry.schedule.wakeDate,
            currentDate: currentDate,
            timeZone: timeZone
        )
        let dateLine = heroDateLine(
            for: entry.schedule.date,
            timeZone: timeZone,
            hijriDateTextProvider: hijriDateTextProvider
        )
        let wakeState = heroWakeState(for: entry)
        let statusText = heroStatusText(for: entry)
        let detailText = conciseWakeRelation(for: entry)
        let chipTitles = actionableChipTitles(for: entry)
        let fajrWindow = fajrWindowDisplay(for: entry, currentDate: currentDate, timeZone: timeZone)
        let primaryTime = wakeState == .active ? entry.schedule.wakeDate : nil
        let primaryText = primaryDisplayText(for: entry, wakeState: wakeState, timeZone: timeZone)
        let accessibilityLabel = heroAccessibilityLabel(
            title: title,
            entry: entry,
            dateLine: dateLine,
            wakeState: wakeState,
            primaryText: primaryText,
            detailText: detailText,
            fajrWindowAccessibilityText: fajrWindow.accessibilityText ?? fajrWindow.fallbackText,
            timeZone: timeZone,
            accessibleHijriDateTextProvider: accessibleHijriDateTextProvider
        )

        return MorningHomeHeroDisplay(
            title: title,
            dateLine: dateLine,
            wakeState: wakeState,
            primaryTime: primaryTime,
            primaryText: primaryText,
            wakeIconName: wakeIconName(for: wakeState),
            statusText: statusText,
            detailText: detailText,
            fajrWindowLine: fajrWindow.fallbackText,
            fajrBeginDisplayText: fajrWindow.beginText,
            fajrEndDisplayText: fajrWindow.endText,
            wakeWindowPositionRatio: fajrWindow.wakePositionRatio,
            wakeWindowIndicatorState: fajrWindow.indicatorState,
            fajrWindowAccessibilityText: fajrWindow.accessibilityText,
            chipTitles: chipTitles,
            accessibilityLabel: accessibilityLabel
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
            return entry.activeDay.effectiveConfig.skipDay ? "Alarm off" : "No alarm set"
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
            if entry.activeDay.effectiveConfig.skipDay,
               entry.activeDay.decisionLog.prayerWindow.fajrEnd != nil {
                return "Planned wake was \(heroWakeOffsetText(for: entry.activeDay))"
            }
            return entry.activeDay.effectiveConfig.skipDay
                ? "Alarm is off for this date"
                : "No wake alarm is set for this date"
        }
        if entry.activeDay.decisionLog.plannedWakeState != .fixedWake,
           entry.activeDay.decisionLog.resolvedAnchor.type == .fajrEnd,
           entry.activeDay.decisionLog.prayerWindow.fajrEnd == nil {
            return "Fajr times are not available yet"
        }
        if entry.activeDay.decisionLog.plannedWakeState == .fixedWake {
            return "Set for a custom wake time"
        }
        return heroWakeOffsetText(for: entry.activeDay)
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
        formatter.dateFormat = "MMMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func heroDateLine(
        for date: Date,
        timeZone: TimeZone,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)?
    ) -> String {
        let gregorian = compactGregorianDateText(for: date, timeZone: timeZone)
        let hijri: String?
        if let hijriDateTextProvider {
            hijri = hijriDateTextProvider(date, timeZone)
        } else {
            hijri = compactHijriDateText(for: date, timeZone: timeZone)
        }
        guard let hijri else {
            return gregorian
        }
        return "\(gregorian) • \(hijri)"
    }

    private static func compactHijriDateText(for date: Date, timeZone: TimeZone) -> String? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }
        return "\(compactHeroHijriToken(for: components.month))\(components.day)"
    }

    private static func accessibleHijriDateText(for date: Date, timeZone: TimeZone) -> String? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }
        return "\(components.month.displayName) \(components.day)"
    }

    private static func heroWakeState(for entry: WakeRowEntry) -> MorningHeroWakeState {
        guard entry.isEnabled else {
            return entry.activeDay.effectiveConfig.skipDay ? .offWithAnchor : .noAlarm
        }
        return .active
    }

    private static func primaryDisplayText(
        for entry: WakeRowEntry,
        wakeState: MorningHeroWakeState,
        timeZone: TimeZone
    ) -> String {
        switch wakeState {
        case .active:
            return timeFormatter(timeZone: timeZone).string(from: entry.schedule.wakeDate)
        case .offWithAnchor:
            return "Alarm off"
        case .noAlarm:
            return "No alarm set"
        case .quietHours:
            return "Quiet morning"
        case .unavailable:
            return "Wake time unavailable"
        }
    }

    private static func wakeIconName(for wakeState: MorningHeroWakeState) -> String? {
        switch wakeState {
        case .active:
            return "alarm.fill"
        case .offWithAnchor:
            return "bell.slash.fill"
        case .quietHours:
            return "moon.fill"
        case .noAlarm, .unavailable:
            return nil
        }
    }

    private static func heroWakeOffsetText(for day: ActiveAlarmDay) -> String {
        let decision = day.decisionLog
        switch decision.plannedWakeState {
        case .preFajr:
            let unit = decision.resolvedDelta.minutes == 1 ? "min" : "min"
            return "\(decision.resolvedDelta.minutes) \(unit) before Fajr begins"
        case .inFajr:
            if decision.resolvedAnchor.type == .fajrEnd {
                let unit = decision.resolvedDelta.minutes == 1 ? "min" : "min"
                return "\(decision.resolvedDelta.minutes) \(unit) before Fajr ends"
            }
            let unit = decision.resolvedDelta.minutes == 1 ? "min" : "min"
            return "\(decision.resolvedDelta.minutes) \(unit) after Fajr begins"
        case .postFajr:
            let unit = decision.resolvedDelta.minutes == 1 ? "min" : "min"
            return "\(decision.resolvedDelta.minutes) \(unit) after Fajr ends"
        case .fixedWake:
            return "Set for a custom wake time"
        }
    }

    private struct FajrWindowDisplay {
        let beginText: String?
        let endText: String?
        let fallbackText: String
        let accessibilityText: String?
        let wakePositionRatio: Double?
        let indicatorState: MorningHeroWakeWindowIndicatorState
    }

    private static func fajrWindowDisplay(
        for entry: WakeRowEntry,
        currentDate: Date,
        timeZone: TimeZone
    ) -> FajrWindowDisplay {
        let window = entry.activeDay.decisionLog.prayerWindow
        guard let fajrEnd = window.fajrEnd else {
            return FajrWindowDisplay(
                beginText: nil,
                endText: nil,
                fallbackText: "Fajr times are not available yet",
                accessibilityText: nil,
                wakePositionRatio: nil,
                indicatorState: .unavailable
            )
        }

        let beginVerb: String
        let endVerb: String
        if entry.schedule.date <= currentDate, currentDate >= fajrEnd {
            beginVerb = "began"
            endVerb = "ended"
        } else if currentDate >= window.fajrStart, currentDate < fajrEnd {
            beginVerb = "began"
            endVerb = "ends"
        } else {
            beginVerb = "begins"
            endVerb = "ends"
        }

        let formatter = timeFormatter(timeZone: timeZone)
        let beginText = formatter.string(from: window.fajrStart)
        let endText = formatter.string(from: fajrEnd)
        let relationVerbText = "Fajr \(beginVerb): \(beginText). Fajr \(endVerb): \(endText)"
        let indicatorState = wakeWindowIndicatorState(for: entry)
        let markerDate = wakeWindowMarkerDate(for: entry, indicatorState: indicatorState)
        let ratio = markerDate.flatMap {
            wakeWindowPositionRatio(wakeDate: $0, fajrStart: window.fajrStart, fajrEnd: fajrEnd)
        }

        return FajrWindowDisplay(
            beginText: beginText,
            endText: endText,
            fallbackText: "Fajr \(beginVerb): \(beginText) • Fajr \(endVerb): \(endText)",
            accessibilityText: relationVerbText,
            wakePositionRatio: ratio,
            indicatorState: ratio == nil ? .none : indicatorState
        )
    }

    private static func heroAccessibilityLabel(
        title: String,
        entry: WakeRowEntry,
        dateLine: String?,
        wakeState: MorningHeroWakeState,
        primaryText: String,
        detailText: String,
        fajrWindowAccessibilityText: String,
        timeZone: TimeZone,
        accessibleHijriDateTextProvider: ((Date, TimeZone) -> String?)?
    ) -> String {
        let fullDate = compactGregorianDateText(for: entry.schedule.date, timeZone: timeZone)
        let hijri: String?
        if let accessibleHijriDateTextProvider {
            hijri = accessibleHijriDateTextProvider(entry.schedule.date, timeZone)
        } else {
            hijri = accessibleHijriDateText(for: entry.schedule.date, timeZone: timeZone)
        }
        let dateText = [fullDate, hijri].compactMap { $0 }.joined(separator: ", ")
        let wakeText: String
        if wakeState == .active {
            wakeText = "Wake alarm at \(timeFormatter(timeZone: timeZone).string(from: entry.schedule.wakeDate))"
        } else {
            wakeText = primaryText
        }

        return [
            dateText.isEmpty ? dateLine : dateText,
            title,
            wakeText,
            detailText,
            fajrWindowAccessibilityText.replacingOccurrences(of: " • ", with: ". ")
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
    }

    private static func relativeDayLabel(
        targetDate: Date,
        wakeDate: Date,
        currentDate: Date,
        timeZone: TimeZone
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let targetStart = calendar.startOfDay(for: targetDate)
        let today = calendar.startOfDay(for: currentDate)

        if targetStart == today, wakeDate >= currentDate {
            return "Today"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           targetStart == tomorrow {
            return "Tomorrow"
        }

        return weekdayFormatter(timeZone: timeZone).string(from: targetDate)
    }

    private static func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func weekdayFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }

    private static func compactGregorianDateText(for date: Date, timeZone: TimeZone) -> String {
        let locale = Locale.current
        let formatter = compactDateFormatter(timeZone: timeZone)
        let base = formatter.string(from: date)
        guard locale.language.languageCode?.identifier == "en" else {
            return base
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = calendar.component(.day, from: date)
        return "\(monthNameFormatter(timeZone: timeZone).string(from: date)) \(ordinalDay(day))"
    }

    private static func ordinalDay(_ day: Int) -> String {
        let suffix: String
        let ones = day % 10
        let tens = (day / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1:
                suffix = "st"
            case 2:
                suffix = "nd"
            case 3:
                suffix = "rd"
            default:
                suffix = "th"
            }
        }
        return "\(day)\(suffix)"
    }

    private static func compactHeroHijriToken(for month: HijriMonth) -> String {
        switch month {
        case .muharram:
            return "M"
        case .safar:
            return "S"
        case .rabiAlAwwal:
            return "R1"
        case .rabiAlThani:
            return "R2"
        case .jumadaAlAwwal:
            return "J1"
        case .jumadaAlThani:
            return "J2"
        case .rajab:
            return "Rj"
        case .shaban:
            return "Sh"
        case .ramadan:
            return "R"
        case .shawwal:
            return "Sw"
        case .dhulQadah:
            return "ZQ"
        case .dhulHijjah:
            return "ZH"
        }
    }

    private static func wakeWindowIndicatorState(for entry: WakeRowEntry) -> MorningHeroWakeWindowIndicatorState {
        switch heroWakeState(for: entry) {
        case .active:
            return .active
        case .offWithAnchor:
            return .offAnchor
        case .noAlarm:
            return .none
        case .quietHours, .unavailable:
            return .unavailable
        }
    }

    private static func wakeWindowMarkerDate(
        for entry: WakeRowEntry,
        indicatorState: MorningHeroWakeWindowIndicatorState
    ) -> Date? {
        switch indicatorState {
        case .active, .offAnchor:
            return entry.schedule.wakeDate
        case .none, .unavailable:
            return nil
        }
    }

    private static func wakeWindowPositionRatio(wakeDate: Date, fajrStart: Date, fajrEnd: Date) -> Double? {
        let duration = fajrEnd.timeIntervalSince(fajrStart)
        guard duration > 0 else { return nil }
        return wakeDate.timeIntervalSince(fajrStart) / duration
    }

    private static func monthNameFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter
    }
}
