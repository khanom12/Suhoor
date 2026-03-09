import Foundation

struct CalendarPlanningProvider {
    struct Dependencies {
        let activeWindowSnapshot: ActiveAlarmWindowSnapshot
        let fastTagSelections: [String: FastIntentSelection]
        let provenance: (Date, TimeZone) -> [ResolvedScheduledDateProvenance]
        let activeDay: (Date, TimeZone) -> ActiveAlarmDay?
        let tagPreviewResult: (Date, FastIntentSelection?, FastPrimaryIntent?, TimeZone) -> TagComputationResult
    }

    func duplicateStatus(
        for date: Date,
        timeZone: TimeZone = .current,
        dependencies: Dependencies
    ) -> DuplicateDateStatus {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let existing = dependencies.activeWindowSnapshot.byDateKey[key] {
            return .active(provenances: existing.provenances, existingDay: existing)
        }

        let provenances = dependencies.provenance(date, timeZone)
        guard !provenances.isEmpty,
              let existingDay = dependencies.activeDay(date, timeZone) else {
            return .available
        }
        return .active(provenances: provenances, existingDay: existingDay)
    }

    func calendarMonthContext(
        displayedMonth: Date,
        selectedDate: Date,
        allowedDateRange: ClosedRange<Date>,
        timeZone: TimeZone = .current,
        dependencies: Dependencies
    ) -> CalendarMonthContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        ) ?? DateHelpers.startOfToday(in: timeZone)
        let weekdaySymbols = reorderedWeekdaySymbols(calendar: calendar)
        let firstDisplayedDate = firstVisibleDate(in: monthStart, calendar: calendar)
        let gridDates = DateHelpers.dates(startingFrom: firstDisplayedDate, count: 42, calendar: calendar)
        let inMonthDates = gridDates.filter {
            calendar.isDate($0, equalTo: monthStart, toGranularity: .month)
        }
        let cachedByKey = dependencies.activeWindowSnapshot.byDateKey
        let missingDates = inMonthDates.filter {
            cachedByKey[DateHelpers.dayIdentifier(for: $0, timeZone: timeZone)] == nil
        }
        let missingProvenance = Dictionary(uniqueKeysWithValues: missingDates.map {
            (DateHelpers.dayIdentifier(for: $0, timeZone: timeZone), dependencies.provenance($0, timeZone))
        })
        let seeds: [ActiveTagComputationSeed] = inMonthDates.map { date in
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let cached = cachedByKey[key]
            let provenances = cached?.provenances ?? missingProvenance[key] ?? []
            return ActiveTagComputationSeed(
                date: DateHelpers.startOfDay(date, in: timeZone),
                dateKey: key,
                defaultPrimaryIntent: provenances.defaultFastPrimaryIntent()
            )
        }
        let tagResults = TagComputationEngine.results(
            seeds: seeds,
            selections: dependencies.fastTagSelections,
            ruleset: .strict,
            timeZone: timeZone
        )

        let dayStates = gridDates.map { date in
            let isInDisplayedMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            guard isInDisplayedMonth else {
                return CalendarDayState(
                    date: date,
                    dayNumberText: "",
                    isInDisplayedMonth: false,
                    isToday: false,
                    isSelected: false,
                    isDisabled: true,
                    isAlreadyActive: false,
                    activeSourceSummary: nil,
                    hijriText: "",
                    computedPrimaryIntent: .other,
                    computedSecondaryTags: [],
                    previewSecondaryTags: [],
                    warnings: [],
                    isForbidden: false,
                    isRamadan: false,
                    isLocked: true
                )
            }

            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let cached = cachedByKey[key]
            let provenances = cached?.provenances ?? missingProvenance[key] ?? []
            let summary = summaryText(for: provenances)
            let tagResult = tagResults[key] ?? .empty
            let previewTags = FastIntentEngine.displaySecondaryTags(
                FastIntentEngine.dateDerivedObservanceTags(
                    for: date,
                    timeZone: timeZone,
                    includeShawwalPotential: true
                )
            )
            let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
            let isRamadan = FastIntentEngine.isRamadan(date, timeZone: timeZone)
            return CalendarDayState(
                date: date,
                dayNumberText: String(calendar.component(.day, from: date)),
                isInDisplayedMonth: true,
                isToday: calendar.isDateInToday(date),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                isDisabled: !allowedDateRange.contains(date),
                isAlreadyActive: !provenances.isEmpty,
                activeSourceSummary: summary.isEmpty ? nil : summary,
                hijriText: HijriDateFormatter.shared.string(from: date),
                computedPrimaryIntent: tagResult.computedPrimaryIntent,
                computedSecondaryTags: FastIntentEngine.displaySecondaryTags(tagResult.computedSecondaryTags),
                previewSecondaryTags: previewTags,
                warnings: warnings,
                isForbidden: !warnings.isEmpty,
                isRamadan: isRamadan,
                isLocked: !warnings.isEmpty || isRamadan
            )
        }

        return CalendarMonthContext(
            monthStart: monthStart,
            monthTitle: GregorianDateFormatter.shared.monthYearString(for: monthStart),
            weekdaySymbols: weekdaySymbols,
            dayStates: dayStates
        )
    }

    func calendarDayStates(
        dates: [Date],
        selectedDate: Date,
        allowedDateRange: ClosedRange<Date>,
        timeZone: TimeZone = .current,
        dependencies: Dependencies
    ) -> [CalendarDayState] {
        guard !dates.isEmpty else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let normalizedDates = dates.map { DateHelpers.startOfDay($0, in: timeZone) }
        let cachedByKey = dependencies.activeWindowSnapshot.byDateKey
        let missingDates = normalizedDates.filter {
            cachedByKey[DateHelpers.dayIdentifier(for: $0, timeZone: timeZone)] == nil
        }
        let missingProvenance = Dictionary(uniqueKeysWithValues: missingDates.map {
            (DateHelpers.dayIdentifier(for: $0, timeZone: timeZone), dependencies.provenance($0, timeZone))
        })
        let seeds: [ActiveTagComputationSeed] = normalizedDates.map { date in
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let cached = cachedByKey[key]
            let provenances = cached?.provenances ?? missingProvenance[key] ?? []
            return ActiveTagComputationSeed(
                date: date,
                dateKey: key,
                defaultPrimaryIntent: provenances.defaultFastPrimaryIntent()
            )
        }
        let tagResults = TagComputationEngine.results(
            seeds: seeds,
            selections: dependencies.fastTagSelections,
            ruleset: .strict,
            timeZone: timeZone
        )

        return normalizedDates.map { date in
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let cached = cachedByKey[key]
            let provenances = cached?.provenances ?? missingProvenance[key] ?? []
            let summary = summaryText(for: provenances)
            let tagResult = tagResults[key] ?? .empty
            let previewTags = FastIntentEngine.displaySecondaryTags(
                FastIntentEngine.dateDerivedObservanceTags(
                    for: date,
                    timeZone: timeZone,
                    includeShawwalPotential: true
                )
            )
            let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
            let isRamadan = FastIntentEngine.isRamadan(date, timeZone: timeZone)
            return CalendarDayState(
                date: date,
                dayNumberText: String(calendar.component(.day, from: date)),
                isInDisplayedMonth: true,
                isToday: calendar.isDateInToday(date),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                isDisabled: !allowedDateRange.contains(date),
                isAlreadyActive: !provenances.isEmpty,
                activeSourceSummary: summary.isEmpty ? nil : summary,
                hijriText: HijriDateFormatter.shared.string(from: date),
                computedPrimaryIntent: tagResult.computedPrimaryIntent,
                computedSecondaryTags: FastIntentEngine.displaySecondaryTags(tagResult.computedSecondaryTags),
                previewSecondaryTags: previewTags,
                warnings: warnings,
                isForbidden: !warnings.isEmpty,
                isRamadan: isRamadan,
                isLocked: !warnings.isEmpty || isRamadan
            )
        }
    }

    func calendarDayDetail(
        for date: Date,
        overrideSelection: FastIntentSelection? = nil,
        timeZone: TimeZone = .current,
        dependencies: Dependencies
    ) -> CalendarDayDetail {
        let provenances = dependencies.provenance(date, timeZone)
        let tagResult = dependencies.tagPreviewResult(
            date,
            overrideSelection,
            provenances.defaultFastPrimaryIntent(),
            timeZone
        )
        let sourceSummary = summaryText(for: provenances)
        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
        return CalendarDayDetail(
            date: date,
            gregorianText: GregorianDateFormatter.shared.headerString(for: date),
            hijriText: HijriDateFormatter.shared.string(from: date),
            isAlreadyActive: !provenances.isEmpty,
            activeSourceSummary: sourceSummary.isEmpty ? nil : sourceSummary,
            tagSummary: tagSummaryText(
                primaryIntent: tagResult.computedPrimaryIntent,
                secondaryTags: tagResult.computedSecondaryTags
            ),
            computedPrimaryIntent: tagResult.computedPrimaryIntent,
            computedSecondaryTags: FastIntentEngine.displaySecondaryTags(tagResult.computedSecondaryTags),
            previewSecondaryTags: FastIntentEngine.displaySecondaryTags(
                FastIntentEngine.dateDerivedObservanceTags(
                    for: date,
                    timeZone: timeZone,
                    includeShawwalPotential: true
                )
            ),
            warnings: warnings
        )
    }

    private func summaryText(for provenances: [ResolvedScheduledDateProvenance]) -> String {
        let labels = provenances.map(\.label)
        return Array(NSOrderedSet(array: labels)).compactMap { $0 as? String }.joined(separator: " • ")
    }

    private func tagSummaryText(
        primaryIntent: FastPrimaryIntent,
        secondaryTags: Set<FastSecondaryVirtueTag>
    ) -> String {
        var parts: [String] = [primaryIntent.shortTitle]
        let secondary = secondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map(\.shortTitle).joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private func reorderedWeekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let prefixIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[prefixIndex...]) + Array(symbols[..<prefixIndex])
    }

    private func firstVisibleDate(in monthStart: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: monthStart)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: monthStart) ?? monthStart
    }
}
