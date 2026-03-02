import Foundation
import os

enum HijriSpecialDayFeatureScope: CaseIterable, Hashable {
    case ramadanDaily
    case whiteDays
    case ashura
    case arafah
    case eidAlFitr
    case eidAlAdha
}

struct HijriSpecialDayPlan {
    let datesByScope: [HijriSpecialDayFeatureScope: Set<Date>]

    func isActive(on date: Date, timeZone: TimeZone) -> Bool {
        datesByScope.values.contains { dates in
            dates.contains(where: { DateHelpers.isSameDay($0, date, in: timeZone) })
        }
    }

    func dates(for scope: HijriSpecialDayFeatureScope) -> Set<Date> {
        datesByScope[scope] ?? []
    }
}

struct HijriSpecialDayPlanner {
    let calendarService: HijriCalendarService

    func plan(
        settings: HijriSpecialDaySettings,
        startDate: Date,
        days: Int,
        timeZone: TimeZone = .current
    ) -> HijriSpecialDayPlan {
        guard settings.isEnabled, days > 0 else {
            return HijriSpecialDayPlan(datesByScope: [:])
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: startDate)
        let endDate = calendar.date(byAdding: .day, value: max(0, days - 1), to: normalizedStart) ?? normalizedStart

        var datesByScope: [HijriSpecialDayFeatureScope: Set<Date>] = [:]
        for hijriYear in HijriBaselineMonthStarts.supportedHijriYears {
            let map = calendarService.buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)

            if settings.ramadanDailyEnabled {
                let key = HijriYearMonth(hijriYear: hijriYear, month: .ramadan)
                let ramadanDates = Set((1...30).compactMap {
                    calendarService.gregorianDate(for: key, dayOfMonth: $0, monthMap: map, timeZone: timeZone)
                }.filter { isWithinHorizon($0, start: normalizedStart, end: endDate, calendar: calendar) })
                if !ramadanDates.isEmpty {
                    datesByScope[.ramadanDaily, default: []].formUnion(ramadanDates)
                }
            }

            if settings.whiteDaysEnabled {
                for month in HijriMonth.adjustmentMonths {
                    let dates = Set([13, 14, 15].compactMap {
                        calendarService.gregorianDate(
                            for: HijriYearMonth(hijriYear: hijriYear, month: month),
                            dayOfMonth: $0,
                            monthMap: map,
                            timeZone: timeZone
                        )
                    }.filter { isWithinHorizon($0, start: normalizedStart, end: endDate, calendar: calendar) })
                    if !dates.isEmpty {
                        datesByScope[.whiteDays, default: []].formUnion(dates)
                    } else if map.resolvedStart(for: month) == nil {
                        Logging.scheduler.debug("Missing Hijri baseline for white days \(month.displayName, privacy: .public) \(String(hijriYear), privacy: .public)")
                    }
                }
            }

            addSingleDate(
                enabled: settings.ashuraEnabled,
                scope: .ashura,
                date: calendarService.gregorianDate(
                    for: HijriYearMonth(hijriYear: hijriYear, month: .muharram),
                    dayOfMonth: 10,
                    monthMap: map,
                    timeZone: timeZone
                ),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.arafahEnabled,
                scope: .arafah,
                date: calendarService.gregorianDate(
                    for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah),
                    dayOfMonth: 9,
                    monthMap: map,
                    timeZone: timeZone
                ),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.eidAlFitrEnabled,
                scope: .eidAlFitr,
                date: calendarService.gregorianDate(
                    for: HijriYearMonth(hijriYear: hijriYear, month: .shawwal),
                    dayOfMonth: 1,
                    monthMap: map,
                    timeZone: timeZone
                ),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.eidAlAdhaEnabled,
                scope: .eidAlAdha,
                date: calendarService.gregorianDate(
                    for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah),
                    dayOfMonth: 10,
                    monthMap: map,
                    timeZone: timeZone
                ),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )
        }

        return HijriSpecialDayPlan(datesByScope: datesByScope)
    }

    private func addSingleDate(
        enabled: Bool,
        scope: HijriSpecialDayFeatureScope,
        date: Date?,
        start: Date,
        end: Date,
        calendar: Calendar,
        into datesByScope: inout [HijriSpecialDayFeatureScope: Set<Date>]
    ) {
        guard enabled, let date, isWithinHorizon(date, start: start, end: end, calendar: calendar) else { return }
        datesByScope[scope, default: []].insert(calendar.startOfDay(for: date))
    }

    private func isWithinHorizon(_ date: Date, start: Date, end: Date, calendar: Calendar) -> Bool {
        let normalized = calendar.startOfDay(for: date)
        return normalized >= start && normalized <= end
    }
}
