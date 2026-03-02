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
    let adjustedHijriCalendar: AdjustedHijriCalendar

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
            if settings.ramadanDailyEnabled {
                let key = HijriYearMonth(hijriYear: hijriYear, month: .ramadan)
                let ramadanDates = Set((1...30).compactMap {
                    adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: $0, timeZone: timeZone)
                }.filter { isWithinHorizon($0, start: normalizedStart, end: endDate, calendar: calendar) })
                if !ramadanDates.isEmpty {
                    datesByScope[.ramadanDaily, default: []].formUnion(ramadanDates)
                }
            }

            if settings.whiteDaysEnabled {
                for month in HijriMonth.adjustmentMonths {
                    let dates = Set([13, 14, 15].compactMap {
                        adjustedHijriCalendar.gregorianDate(
                            for: HijriYearMonth(hijriYear: hijriYear, month: month),
                            dayOfMonth: $0,
                            timeZone: timeZone
                        )
                    }.filter { isWithinHorizon($0, start: normalizedStart, end: endDate, calendar: calendar) })
                    if !dates.isEmpty {
                        datesByScope[.whiteDays, default: []].formUnion(dates)
                    } else if adjustedHijriCalendar.monthStartPreview(for: HijriYearMonth(hijriYear: hijriYear, month: month), timeZone: timeZone) == nil {
                        Logging.scheduler.debug("Missing Hijri baseline for white days \(month.displayName, privacy: .public) \(String(hijriYear), privacy: .public)")
                    }
                }
            }

            addSingleDate(
                enabled: settings.ashuraEnabled,
                scope: .ashura,
                date: adjustedHijriCalendar.gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .muharram), dayOfMonth: 10, timeZone: timeZone),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.arafahEnabled,
                scope: .arafah,
                date: adjustedHijriCalendar.gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah), dayOfMonth: 9, timeZone: timeZone),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.eidAlFitrEnabled,
                scope: .eidAlFitr,
                date: adjustedHijriCalendar.gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .shawwal), dayOfMonth: 1, timeZone: timeZone),
                start: normalizedStart,
                end: endDate,
                calendar: calendar,
                into: &datesByScope
            )

            addSingleDate(
                enabled: settings.eidAlAdhaEnabled,
                scope: .eidAlAdha,
                date: adjustedHijriCalendar.gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah), dayOfMonth: 10, timeZone: timeZone),
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
