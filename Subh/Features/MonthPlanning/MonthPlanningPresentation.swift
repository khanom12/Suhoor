import Foundation

enum MonthPlanningCalendarMode: String, CaseIterable, Identifiable, Hashable {
    case gregorian
    case hijri

    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .gregorian:
            return "Calendar Months"
        case .hijri:
            return "Hijri Months"
        }
    }

    var pickerSubtitle: String {
        switch self {
        case .gregorian:
            return "Choose a month to plan your mornings."
        case .hijri:
            return "Choose an Islamic month to plan your mornings."
        }
    }
}

enum MonthPlanningMonthIdentity: Hashable, Identifiable {
    case gregorian(year: Int, month: Int)
    case hijri(year: Int, month: HijriMonth)

    var id: String {
        switch self {
        case .gregorian(let year, let month):
            return "gregorian-\(year)-\(month)"
        case .hijri(let year, let month):
            return "hijri-\(year)-\(month.rawValue)"
        }
    }

    var mode: MonthPlanningCalendarMode {
        switch self {
        case .gregorian:
            return .gregorian
        case .hijri:
            return .hijri
        }
    }
}

enum MonthPlanningAvailability: Equatable {
    case available
    case unavailable(reason: String)
    case locked(reason: String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var label: String? {
        switch self {
        case .available:
            return nil
        case .unavailable(let reason), .locked(let reason):
            return reason
        }
    }
}

struct MonthPlanningDateRange: Equatable {
    let start: Date
    let end: Date

    func count(timeZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    func contains(_ date: Date, timeZone: TimeZone) -> Bool {
        let target = DateHelpers.startOfDay(date, in: timeZone)
        return target >= DateHelpers.startOfDay(start, in: timeZone)
            && target <= DateHelpers.startOfDay(end, in: timeZone)
    }
}

struct MonthPlanningPickerMonth: Identifiable, Equatable {
    let identity: MonthPlanningMonthIdentity
    let title: String
    let subtitle: String?
    let countText: String
    let accessibilityLabel: String
    let isCurrentMonth: Bool
    let dateRange: MonthPlanningDateRange?
    let availability: MonthPlanningAvailability

    var id: String { identity.id }
}

struct MonthPlanningMorningRow: Identifiable {
    let id: String
    let entry: WakeRowEntry
    let primaryDateLabel: String
    let secondaryDateLabel: String
    let contextTags: [NextTenMorningsTagDisplay]
    let allAccessibilityTags: [NextTenMorningsTagDisplay]
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let showsOverride: Bool
    let showsCompleteLock: Bool
    let accessibilityLabel: String
}

struct MonthlyFajrcastPlaceholderSnapshot {
    let mode: MonthPlanningCalendarMode
    let monthTitle: String
    let dateRangeText: String?
    let visibleRangeText: String?
    let morningCount: Int
    let entitlement: SubhEntitlementSnapshot
    let hijriAdjustmentText: String?
}

struct MonthPlanningSnapshot {
    let mode: MonthPlanningCalendarMode
    let identity: MonthPlanningMonthIdentity
    let navigationTitle: String
    let sectionTitle: String
    let dateRange: MonthPlanningDateRange?
    let rows: [MonthPlanningMorningRow]
    let emptyStateText: String?
    let monthlyFajrcast: MonthlyFajrcastPlaceholderSnapshot
}

struct MonthPlanningDayDetailSourceContext: Equatable {
    let mode: MonthPlanningCalendarMode
    let monthIdentity: MonthPlanningMonthIdentity
    let entitlement: SubhEntitlementSnapshot

    var allowsSuhoorControls: Bool {
        entitlement.allows(.suhoorPlanning)
    }
}

enum MonthPlanningPresentation {
    static let horizonMonthCount = 13

    static func gregorianPickerMonths(
        now: Date,
        timeZone: TimeZone,
        hijriRangeTextProvider: ((MonthPlanningDateRange) -> String?)? = nil,
        activeDayProvider: (Date) -> ActiveAlarmDay?
    ) -> [MonthPlanningPickerMonth] {
        gregorianMonthIdentities(now: now, count: horizonMonthCount, timeZone: timeZone).compactMap { identity in
            guard let range = dateRange(for: identity, timeZone: timeZone) else { return nil }
            let title = title(for: identity, dateRange: range, timeZone: timeZone)
            let isCurrent = isCurrentMonth(identity, now: now, timeZone: timeZone)
            let count = isCurrent
                ? actionableDays(in: range, now: now, timeZone: timeZone, activeDayProvider: activeDayProvider).count
                : range.count(timeZone: timeZone)
            let countText = morningCountText(count: count, isCurrent: isCurrent)
            let availability: MonthPlanningAvailability = isCurrent && count == 0
                ? .unavailable(reason: "No remaining mornings")
                : .available

            return MonthPlanningPickerMonth(
                identity: identity,
                title: title,
                subtitle: hijriRangeTextProvider?(range),
                countText: availability.label ?? countText,
                accessibilityLabel: [title, hijriRangeTextProvider?(range), availability.label ?? countText]
                    .compactMap { $0 }
                    .joined(separator: ", "),
                isCurrentMonth: isCurrent,
                dateRange: range,
                availability: availability
            )
        }
    }

    static func hijriPickerMonths(
        months: [HijriYearMonth],
        now: Date,
        timeZone: TimeZone,
        dateRangeProvider: (HijriYearMonth) -> MonthPlanningDateRange?,
        activeDayProvider: (Date) -> ActiveAlarmDay?
    ) -> [MonthPlanningPickerMonth] {
        months.prefix(horizonMonthCount).compactMap { yearMonth in
            let identity = MonthPlanningMonthIdentity.hijri(year: yearMonth.hijriYear, month: yearMonth.month)
            guard let range = dateRangeProvider(yearMonth) else {
                let title = "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
                return MonthPlanningPickerMonth(
                    identity: identity,
                    title: title,
                    subtitle: nil,
                    countText: "Calculation unavailable",
                    accessibilityLabel: "\(title), calculation unavailable",
                    isCurrentMonth: false,
                    dateRange: nil,
                    availability: .unavailable(reason: "Calculation unavailable")
                )
            }

            let title = "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
            let isCurrent = range.contains(now, timeZone: timeZone)
            let count = isCurrent
                ? actionableDays(in: range, now: now, timeZone: timeZone, activeDayProvider: activeDayProvider).count
                : range.count(timeZone: timeZone)
            let countText = morningCountText(count: count, isCurrent: isCurrent)
            let rangeText = gregorianRangeText(range, timeZone: timeZone)
            let availability: MonthPlanningAvailability = isCurrent && count == 0
                ? .unavailable(reason: "No remaining mornings")
                : .available

            return MonthPlanningPickerMonth(
                identity: identity,
                title: title,
                subtitle: rangeText,
                countText: availability.label ?? countText,
                accessibilityLabel: "\(title), \(rangeText), \(availability.label ?? countText)",
                isCurrentMonth: isCurrent,
                dateRange: range,
                availability: availability
            )
        }
    }

    static func detailSnapshot(
        identity: MonthPlanningMonthIdentity,
        dateRange: MonthPlanningDateRange?,
        activeDays: [ActiveAlarmDay],
        now: Date,
        timeZone: TimeZone,
        entitlement: SubhEntitlementSnapshot,
        hijriComponentsProvider: (Date, TimeZone) -> AdjustedHijriDateComponents?,
        hijriAdjustmentText: String? = nil
    ) -> MonthPlanningSnapshot {
        let mode = identity.mode
        let isCurrent = dateRange?.contains(now, timeZone: timeZone) ?? false
        let visibleDays = activeDays
            .filter { day in
                guard isCurrent else { return true }
                return isActionable(day, now: now)
            }
            .sorted { $0.date < $1.date }
        let rows = visibleDays.map {
            morningRow(
                for: $0,
                mode: mode,
                identity: identity,
                entitlement: entitlement,
                timeZone: timeZone,
                hijriComponentsProvider: hijriComponentsProvider
            )
        }
        let title = title(for: identity, dateRange: dateRange, timeZone: timeZone)
        let section = sectionTitle(for: identity, dateRange: dateRange, timeZone: timeZone)
        let emptyState = rows.isEmpty && isCurrent
            ? "No remaining mornings in this month. Choose another month to plan ahead."
            : (rows.isEmpty ? "Month mornings are not available yet." : nil)
        let visibleRangeText = rowsVisibleRangeText(rows, timeZone: timeZone)
        return MonthPlanningSnapshot(
            mode: mode,
            identity: identity,
            navigationTitle: title,
            sectionTitle: section,
            dateRange: dateRange,
            rows: rows,
            emptyStateText: emptyState,
            monthlyFajrcast: MonthlyFajrcastPlaceholderSnapshot(
                mode: mode,
                monthTitle: title,
                dateRangeText: dateRange.map { gregorianRangeText($0, timeZone: timeZone) },
                visibleRangeText: visibleRangeText,
                morningCount: rows.count,
                entitlement: entitlement,
                hijriAdjustmentText: hijriAdjustmentText
            )
        )
    }

    static func gregorianMonthIdentities(
        now: Date,
        count: Int,
        timeZone: TimeZone
    ) -> [MonthPlanningMonthIdentity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? DateHelpers.startOfDay(now, in: timeZone)
        return (0..<max(0, count)).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { return nil }
            return .gregorian(year: year, month: month)
        }
    }

    static func dateRange(
        for identity: MonthPlanningMonthIdentity,
        timeZone: TimeZone
    ) -> MonthPlanningDateRange? {
        switch identity {
        case .gregorian(let year, let month):
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            guard
                let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                let next = calendar.date(byAdding: .month, value: 1, to: start),
                let end = calendar.date(byAdding: .day, value: -1, to: next)
            else {
                return nil
            }
            return MonthPlanningDateRange(start: start, end: end)
        case .hijri:
            return nil
        }
    }

    static func hijriDateRange(
        for yearMonth: HijriYearMonth,
        startProvider: (HijriYearMonth) -> Date?,
        timeZone: TimeZone
    ) -> MonthPlanningDateRange? {
        guard let start = startProvider(yearMonth),
              let next = yearMonth.advanced(byMonths: 1).flatMap(startProvider) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let end = calendar.date(byAdding: .day, value: -1, to: next) else { return nil }
        return MonthPlanningDateRange(start: start, end: end)
    }

    static func dates(in range: MonthPlanningDateRange, timeZone: TimeZone) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return DateHelpers.dates(from: range.start, to: range.end, calendar: calendar)
    }

    static func title(
        for identity: MonthPlanningMonthIdentity,
        dateRange: MonthPlanningDateRange?,
        timeZone: TimeZone
    ) -> String {
        switch identity {
        case .gregorian:
            guard let range = dateRange else { return "Calendar Month" }
            return gregorianMonthYearFormatter(timeZone: timeZone).string(from: range.start)
        case .hijri(let year, let month):
            return "\(month.displayName) \(year)"
        }
    }

    private static func sectionTitle(
        for identity: MonthPlanningMonthIdentity,
        dateRange: MonthPlanningDateRange?,
        timeZone: TimeZone
    ) -> String {
        switch identity {
        case .gregorian:
            guard let range = dateRange else { return "Month mornings" }
            return "\(gregorianMonthFormatter(timeZone: timeZone).string(from: range.start)) mornings"
        case .hijri(_, let month):
            return "\(month.displayName) mornings"
        }
    }

    private static func morningRow(
        for day: ActiveAlarmDay,
        mode: MonthPlanningCalendarMode,
        identity: MonthPlanningMonthIdentity,
        entitlement: SubhEntitlementSnapshot,
        timeZone: TimeZone,
        hijriComponentsProvider: (Date, TimeZone) -> AdjustedHijriDateComponents?
    ) -> MonthPlanningMorningRow {
        let overrideKeys: Set<String> = day.effectiveConfig.hasOverrides ? [day.dateKey] : []
        let entry = WakeRowActionResolver.makeEntry(activeDay: day, overrideDateKeys: overrideKeys)
        let hijri = hijriComponentsProvider(day.date, timeZone)
        let gregorian = gregorianDayFormatter(timeZone: timeZone).string(from: day.date)
        let hijriText = hijri.map { "\($0.month.displayName) \($0.day)" } ?? "Hijri date unavailable"
        let selectedMode = WakeStateSelectionResolver.selectedMode(for: day)
        let resolvedWake = MorningWakeResolutionService.resolve(for: day, timeZone: timeZone)
        let quietModeState: NextTenMorningsQuietModeState = selectedMode == .quiet || resolvedWake.alarmActivation == .quietSuppressed
            ? .active
            : .inactive
        let compatibleOpportunityTags = FastIntentEngine.displaySecondaryTags(
            FastIntentEngine.dateDerivedObservanceTags(
                for: day.date,
                timeZone: timeZone,
                includeShawwalPotential: true
            )
        )
        let tagResolution = NextTenMorningsTagResolver.resolve(
            NextTenMorningsTagResolverInput(
                date: day.date,
                dateKey: day.dateKey,
                resolvedDayPurpose: day.resolvedDayPurpose,
                resolvedContext: day.resolvedDayContext,
                tagResult: day.tagResult,
                compatibleOpportunityTags: compatibleOpportunityTags,
                quietModeState: quietModeState,
                selectedQuickWakeMode: selectedMode,
                shawwalSixProgress: nil,
                hasDayOverride: entry.hasDayOverride
            )
        )
        let trailing = rowTrailingDisplay(resolvedWake: resolvedWake)
        let primary = mode == .gregorian ? gregorian : hijriText
        let secondary = mode == .gregorian ? hijriText : gregorian
        let showsCompleteLock = selectedMode == .suhoor && !entitlement.allows(.suhoorPlanning)
        let lockText = showsCompleteLock ? ", Complete required for Suhoor controls" : ""
        let accessibilityStatus: String
        if let trailingTime = trailing.time {
            accessibilityStatus = "Wake at \(timeFormatter(timeZone: timeZone).string(from: trailingTime))"
        } else {
            accessibilityStatus = trailing.status ?? "Wake status unavailable"
        }
        let tagText = accessibilityTagSummary(tagResolution.accessibilityTags)

        return MonthPlanningMorningRow(
            id: day.dateKey,
            entry: entry,
            primaryDateLabel: primary,
            secondaryDateLabel: secondary,
            contextTags: tagResolution.visibleTags,
            allAccessibilityTags: tagResolution.accessibilityTags,
            trailingTime: trailing.time,
            trailingStatusText: trailing.status,
            isInactive: trailing.time == nil,
            showsOverride: entry.hasDayOverride,
            showsCompleteLock: showsCompleteLock,
            accessibilityLabel: "\(primary), \(secondary), \(tagText), \(accessibilityStatus)\(entry.hasDayOverride ? ", changed for this date" : "")\(lockText)"
        )
    }

    private static func actionableDays(
        in range: MonthPlanningDateRange,
        now: Date,
        timeZone: TimeZone,
        activeDayProvider: (Date) -> ActiveAlarmDay?
    ) -> [ActiveAlarmDay] {
        dates(in: range, timeZone: timeZone)
            .compactMap(activeDayProvider)
            .filter { isActionable($0, now: now) }
    }

    private static func isCurrentMonth(
        _ identity: MonthPlanningMonthIdentity,
        now: Date,
        timeZone: TimeZone
    ) -> Bool {
        guard case .gregorian(let year, let month) = identity else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month], from: now)
        return components.year == year && components.month == month
    }

    private static func isActionable(_ day: ActiveAlarmDay, now: Date) -> Bool {
        day.schedule.wakeDate >= now
    }

    private static func morningCountText(count: Int, isCurrent: Bool) -> String {
        if count == 0 {
            return isCurrent ? "No remaining mornings" : "No mornings"
        }
        let suffix = count == 1 ? "morning" : "mornings"
        return isCurrent ? "\(count) \(suffix) left" : "\(count) \(suffix)"
    }

    private static func rowTrailingDisplay(
        resolvedWake: ResolvedMorningWakeState
    ) -> (time: Date?, status: String?) {
        switch resolvedWake.alarmActivation {
        case .active:
            guard let wakeTime = resolvedWake.wakeTimeResolution.wakeTime else {
                return (nil, "Unavailable")
            }
            return (wakeTime, nil)
        case .quietSuppressed:
            return (nil, "Quiet")
        case .pausedSuppressed:
            return (nil, "Paused")
        case .offWithAnchor, .noAnchor:
            return (nil, "No alarm")
        case .unavailable:
            return (nil, "Unavailable")
        }
    }

    private static func accessibilityTagSummary(_ tags: [NextTenMorningsTagDisplay]) -> String {
        guard !tags.isEmpty else { return "Fajr morning" }
        return tags.map(\.accessibilityText).joined(separator: ", ")
    }

    private static func rowsVisibleRangeText(_ rows: [MonthPlanningMorningRow], timeZone: TimeZone) -> String? {
        guard let first = rows.first?.entry.schedule.date, let last = rows.last?.entry.schedule.date else {
            return nil
        }
        let formatter = gregorianShortFormatter(timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if calendar.isDate(first, inSameDayAs: last) {
            return formatter.string(from: first)
        }
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    static func gregorianRangeText(_ range: MonthPlanningDateRange, timeZone: TimeZone) -> String {
        let formatter = gregorianShortFormatter(timeZone: timeZone)
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }

    private static func gregorianMonthYearFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private static func gregorianMonthFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "MMMM"
        return formatter
    }

    private static func gregorianShortFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private static func gregorianDayFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }

    private static func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private static func gregorianCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
