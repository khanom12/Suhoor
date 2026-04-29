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

enum MorningHeroFajrWindowVisualMode: String, Equatable {
    case interactiveWithinFajrWindow
    case staticWithinFajrWindow
    case hiddenFasting
    case hiddenOutOfWindow
    case hiddenUnavailable

    var rendersRange: Bool {
        switch self {
        case .interactiveWithinFajrWindow, .staticWithinFajrWindow:
            return true
        case .hiddenFasting, .hiddenOutOfWindow, .hiddenUnavailable:
            return false
        }
    }
}

struct MorningHomeHeroDisplay: Equatable {
    let locationText: String
    let locationIconName: String?
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
    let wakeWindowIndicatorIconName: String?
    let fajrWindowVisualMode: MorningHeroFajrWindowVisualMode
    let fajrWindowAccessibilityText: String?
    let wakeAdjustmentEnabled: Bool
    let wakeAdjustmentMinTime: Date?
    let wakeAdjustmentMaxTime: Date?
    let wakeAdjustmentStepMinutes: Int
    let wakeAdjustmentRelationAnchor: WakeAnchorType?
    let wakeAdjustmentAccessibilityValue: String?
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
        locationDisplayText: String? = nil,
        locationIconName: String? = nil,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current,
        hijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil,
        accessibleHijriDateTextProvider: ((Date, TimeZone) -> String?)? = nil
    ) -> MorningHomeHeroDisplay {
        let fallbackLocation = locationDisplayText.flatMap(Self.nonEmptyLocationText) ?? "Location unavailable"
        guard let entry else {
            let detail = permissionSummary.isEmpty
                ? "Subh will show tomorrow once schedule data is available."
                : permissionSummary
            return MorningHomeHeroDisplay(
                locationText: fallbackLocation,
                locationIconName: locationIconName,
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
                wakeWindowIndicatorIconName: nil,
                fajrWindowVisualMode: .hiddenUnavailable,
                fajrWindowAccessibilityText: nil,
                wakeAdjustmentEnabled: false,
                wakeAdjustmentMinTime: nil,
                wakeAdjustmentMaxTime: nil,
                wakeAdjustmentStepMinutes: 1,
                wakeAdjustmentRelationAnchor: nil,
                wakeAdjustmentAccessibilityValue: nil,
                chipTitles: [],
                accessibilityLabel: "\(fallbackLocation). Tomorrow. Wake time unavailable. \(detail). Fajr times are not available yet."
            )
        }

        let locationText = locationDisplayText.flatMap(Self.nonEmptyLocationText)
            ?? nonEmptyLocationText(entry.schedule.locationDescription)
            ?? "Location unavailable"
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
            locationText: locationText,
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
            locationText: locationText,
            locationIconName: locationIconName,
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
            wakeWindowIndicatorIconName: wakeWindowIndicatorIconName(for: fajrWindow.indicatorState),
            fajrWindowVisualMode: fajrWindow.visualMode,
            fajrWindowAccessibilityText: fajrWindow.accessibilityText,
            wakeAdjustmentEnabled: fajrWindow.visualMode == .interactiveWithinFajrWindow,
            wakeAdjustmentMinTime: fajrWindow.adjustmentMinTime,
            wakeAdjustmentMaxTime: fajrWindow.adjustmentMaxTime,
            wakeAdjustmentStepMinutes: fajrWindow.adjustmentStepMinutes,
            wakeAdjustmentRelationAnchor: fajrWindow.adjustmentRelationAnchor,
            wakeAdjustmentAccessibilityValue: fajrWindow.adjustmentAccessibilityValue,
            chipTitles: chipTitles,
            accessibilityLabel: accessibilityLabel
        )
    }

    static func heroDisplay(
        adjusting display: MorningHomeHeroDisplay,
        tentativeWakeTime: Date,
        timeZone: TimeZone = .current
    ) -> MorningHomeHeroDisplay {
        guard
            let minTime = display.wakeAdjustmentMinTime,
            let maxTime = display.wakeAdjustmentMaxTime
        else {
            return display
        }

        let clampedWake = clamped(tentativeWakeTime, min: minTime, max: maxTime)
        let detailText = adjustedWakeRelationText(
            wakeTime: clampedWake,
            minTime: minTime,
            maxTime: maxTime,
            anchor: display.wakeAdjustmentRelationAnchor
        )
        let ratio = wakeWindowPositionRatio(
            wakeDate: clampedWake,
            fajrStart: minTime,
            fajrEnd: maxTime
        )
        let primaryText = timeFormatter(timeZone: timeZone).string(from: clampedWake)
        let accessibilityValue = wakeAdjustmentAccessibilityValue(
            wakeTime: clampedWake,
            relationText: detailText,
            minTime: minTime,
            maxTime: maxTime,
            timeZone: timeZone
        )

        return MorningHomeHeroDisplay(
            locationText: display.locationText,
            locationIconName: display.locationIconName,
            title: display.title,
            dateLine: display.dateLine,
            wakeState: display.wakeState,
            primaryTime: clampedWake,
            primaryText: primaryText,
            wakeIconName: display.wakeIconName,
            statusText: display.statusText,
            detailText: detailText,
            fajrWindowLine: display.fajrWindowLine,
            fajrBeginDisplayText: display.fajrBeginDisplayText,
            fajrEndDisplayText: display.fajrEndDisplayText,
            wakeWindowPositionRatio: ratio,
            wakeWindowIndicatorState: display.wakeWindowIndicatorState,
            wakeWindowIndicatorIconName: display.wakeWindowIndicatorIconName,
            fajrWindowVisualMode: display.fajrWindowVisualMode,
            fajrWindowAccessibilityText: display.fajrWindowAccessibilityText,
            wakeAdjustmentEnabled: display.wakeAdjustmentEnabled,
            wakeAdjustmentMinTime: display.wakeAdjustmentMinTime,
            wakeAdjustmentMaxTime: display.wakeAdjustmentMaxTime,
            wakeAdjustmentStepMinutes: display.wakeAdjustmentStepMinutes,
            wakeAdjustmentRelationAnchor: display.wakeAdjustmentRelationAnchor,
            wakeAdjustmentAccessibilityValue: accessibilityValue,
            chipTitles: display.chipTitles,
            accessibilityLabel: adjustedAccessibilityLabel(
                base: display.accessibilityLabel,
                wakeTimeText: primaryText,
                relationText: detailText,
                fajrWindowAccessibilityText: display.fajrWindowAccessibilityText
            )
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
            return activeHeroWakeRelationText(for: entry.activeDay)
        }
        return activeHeroWakeRelationText(for: entry.activeDay)
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
        return "\(heroHijriMonthDisplayName(for: components.month)) \(components.day)"
    }

    private static func accessibleHijriDateText(for date: Date, timeZone: TimeZone) -> String? {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }
        return "\(heroHijriMonthDisplayName(for: components.month)) \(components.day)"
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
            let unit = minuteUnit(for: decision.resolvedDelta.minutes)
            return "\(decision.resolvedDelta.minutes) \(unit) before Fajr begins"
        case .inFajr:
            if decision.resolvedAnchor.type == .fajrEnd {
                let unit = minuteUnit(for: decision.resolvedDelta.minutes)
                return "\(decision.resolvedDelta.minutes) \(unit) before Fajr ends"
            }
            let unit = minuteUnit(for: decision.resolvedDelta.minutes)
            return "\(decision.resolvedDelta.minutes) \(unit) after Fajr begins"
        case .postFajr:
            let unit = minuteUnit(for: decision.resolvedDelta.minutes)
            return "\(decision.resolvedDelta.minutes) \(unit) after Fajr ends"
        case .fixedWake:
            return "at the custom wake time"
        }
    }

    private static func activeHeroWakeRelationText(for day: ActiveAlarmDay) -> String {
        let decision = day.decisionLog
        if decision.resolvedDelta.minutes == 0 {
            switch decision.plannedWakeState {
            case .preFajr:
                return "Wake up at the start of Fajr"
            case .inFajr:
                return decision.resolvedAnchor.type == .fajrEnd
                    ? "Wake up at the end of Fajr"
                    : "Wake up at the start of Fajr"
            case .postFajr:
                return "Wake up at the end of Fajr"
            case .fixedWake:
                break
            }
        }
        return "Wake up \(heroWakeOffsetText(for: day))"
    }

    private static func minuteUnit(for minutes: Int) -> String {
        minutes == 1 ? "minute" : "minutes"
    }

    private struct FajrWindowDisplay {
        let beginText: String?
        let endText: String?
        let fallbackText: String
        let accessibilityText: String?
        let wakePositionRatio: Double?
        let indicatorState: MorningHeroWakeWindowIndicatorState
        let visualMode: MorningHeroFajrWindowVisualMode
        let adjustmentMinTime: Date?
        let adjustmentMaxTime: Date?
        let adjustmentStepMinutes: Int
        let adjustmentRelationAnchor: WakeAnchorType?
        let adjustmentAccessibilityValue: String?
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
                indicatorState: .unavailable,
                visualMode: .hiddenUnavailable,
                adjustmentMinTime: nil,
                adjustmentMaxTime: nil,
                adjustmentStepMinutes: 1,
                adjustmentRelationAnchor: nil,
                adjustmentAccessibilityValue: nil
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
        let visualMode = fajrWindowVisualMode(for: entry, ratio: ratio)
        let adjustmentEnabled = visualMode == .interactiveWithinFajrWindow
        let relationAnchor = adjustmentEnabled ? adjustmentRelationAnchor(for: entry) : nil
        let adjustmentAccessibilityValue: String?
        if adjustmentEnabled {
            adjustmentAccessibilityValue = wakeAdjustmentAccessibilityValue(
                wakeTime: entry.schedule.wakeDate,
                relationText: conciseWakeRelation(for: entry),
                minTime: window.fajrStart,
                maxTime: fajrEnd,
                timeZone: timeZone
            )
        } else {
            adjustmentAccessibilityValue = nil
        }

        return FajrWindowDisplay(
            beginText: beginText,
            endText: endText,
            fallbackText: "Fajr \(beginVerb): \(beginText) • Fajr \(endVerb): \(endText)",
            accessibilityText: relationVerbText,
            wakePositionRatio: ratio,
            indicatorState: ratio == nil ? .none : indicatorState,
            visualMode: visualMode,
            adjustmentMinTime: adjustmentEnabled ? window.fajrStart : nil,
            adjustmentMaxTime: adjustmentEnabled ? fajrEnd : nil,
            adjustmentStepMinutes: 1,
            adjustmentRelationAnchor: relationAnchor,
            adjustmentAccessibilityValue: adjustmentAccessibilityValue
        )
    }

    private static func heroAccessibilityLabel(
        locationText: String,
        title: String,
        entry: WakeRowEntry,
        dateLine _: String?,
        wakeState: MorningHeroWakeState,
        primaryText: String,
        detailText: String,
        fajrWindowAccessibilityText: String,
        timeZone: TimeZone,
        accessibleHijriDateTextProvider _: ((Date, TimeZone) -> String?)?
    ) -> String {
        let wakeText: String
        if wakeState == .active {
            wakeText = "Wake alarm at \(timeFormatter(timeZone: timeZone).string(from: entry.schedule.wakeDate))"
        } else {
            wakeText = primaryText
        }

        return [
            locationText,
            title,
            wakeText,
            detailText,
            fajrWindowAccessibilityText.replacingOccurrences(of: " • ", with: ". ")
        ]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    private static func nonEmptyLocationText(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
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

        return base
    }

    private static func heroHijriMonthDisplayName(for month: HijriMonth) -> String {
        switch month {
        case .dhulQadah:
            return "Dhul Qadah"
        default:
            return month.displayName
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

    private static func wakeWindowIndicatorIconName(for state: MorningHeroWakeWindowIndicatorState) -> String? {
        switch state {
        case .active:
            return "alarm.fill"
        case .offAnchor:
            return "bell.slash.fill"
        case .none, .unavailable:
            return nil
        }
    }

    private static func fajrWindowVisualMode(
        for entry: WakeRowEntry,
        ratio: Double?
    ) -> MorningHeroFajrWindowVisualMode {
        if isFastingMorning(entry.activeDay.resolvedDayContext) {
            return .hiddenFasting
        }

        let window = entry.activeDay.decisionLog.prayerWindow
        guard window.fajrEnd != nil else {
            return .hiddenUnavailable
        }

        guard let ratio else {
            return .staticWithinFajrWindow
        }

        guard ratio >= 0, ratio <= 1 else {
            return .hiddenOutOfWindow
        }

        return heroWakeState(for: entry) == .active
            ? .interactiveWithinFajrWindow
            : .staticWithinFajrWindow
    }

    private static func isFastingMorning(_ context: ResolvedDayContext) -> Bool {
        let fastingContexts: Set<MorningContextType> = [.fasting, .qadaFast, .sunnahFast]
        if fastingContexts.contains(context.primaryContext) {
            return true
        }
        if context.secondaryContexts.contains(where: { fastingContexts.contains($0) }) {
            return true
        }

        let fastingTags: Set<DayTag> = [.ramadan, .qada, .kaffarah, .vow, .voluntary]
        return context.supportingTags.contains(where: { fastingTags.contains($0) })
    }

    private static func adjustmentRelationAnchor(for entry: WakeRowEntry) -> WakeAnchorType {
        let anchor = entry.activeDay.decisionLog.resolvedAnchor.type
        switch anchor {
        case .fajrStart, .fajrEnd:
            return anchor
        case .masjidFajr, .clockTime:
            return .fajrEnd
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

    private static func clamped(_ date: Date, min minTime: Date, max maxTime: Date) -> Date {
        if date < minTime { return minTime }
        if date > maxTime { return maxTime }
        return date
    }

    private static func adjustedWakeRelationText(
        wakeTime: Date,
        minTime: Date,
        maxTime: Date,
        anchor: WakeAnchorType?
    ) -> String {
        if abs(wakeTime.timeIntervalSince(minTime)) < 0.5 {
            return "Wake up at the start of Fajr"
        }
        if abs(wakeTime.timeIntervalSince(maxTime)) < 0.5 {
            return "Wake up at the end of Fajr"
        }

        switch anchor {
        case .fajrStart:
            let minutes = Int(round(wakeTime.timeIntervalSince(minTime) / 60))
            if minutes == 0 {
                return "Wake up at the start of Fajr"
            }
            if minutes > 0 {
                return "Wake up \(minutes) \(minuteUnit(for: minutes)) after Fajr begins"
            }
            let absoluteMinutes = abs(minutes)
            return "Wake up \(absoluteMinutes) \(minuteUnit(for: absoluteMinutes)) before Fajr begins"
        case .fajrEnd, .masjidFajr, .clockTime, .none:
            let minutes = Int(round(maxTime.timeIntervalSince(wakeTime) / 60))
            if minutes == 0 {
                return "Wake up at the end of Fajr"
            }
            if minutes > 0 {
                return "Wake up \(minutes) \(minuteUnit(for: minutes)) before Fajr ends"
            }
            let absoluteMinutes = abs(minutes)
            return "Wake up \(absoluteMinutes) \(minuteUnit(for: absoluteMinutes)) after Fajr ends"
        }
    }

    private static func wakeAdjustmentAccessibilityValue(
        wakeTime: Date,
        relationText: String,
        minTime: Date,
        maxTime: Date,
        timeZone: TimeZone
    ) -> String {
        let formatter = timeFormatter(timeZone: timeZone)
        return "Wake alarm at \(formatter.string(from: wakeTime)), \(relationText). Adjustable between Fajr begin at \(formatter.string(from: minTime)) and Fajr end at \(formatter.string(from: maxTime))."
    }

    private static func adjustedAccessibilityLabel(
        base: String,
        wakeTimeText: String,
        relationText: String,
        fajrWindowAccessibilityText: String?
    ) -> String {
        let fajrText = fajrWindowAccessibilityText?.replacingOccurrences(of: " • ", with: ". ")
        return [
            base.components(separatedBy: ". Wake alarm at").first,
            "Wake alarm at \(wakeTimeText)",
            relationText,
            fajrText
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
    }

}
