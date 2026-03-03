import Foundation
import Testing
@testable import Suhoor

@Suite
struct ScheduledDateSourceResolverTests {
    @Test
    func explicitSingleDaySourceResolves() {
        let suiteName = "ScheduledDateSourceResolverTests.SingleDay"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let sourceStore = ScheduledDateSourceStore(defaults: defaults)
        let suppressedStore = SuppressedScheduledDateStore(defaults: defaults)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = makeDate(year: 2026, month: 2, day: 20)
        sourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(
                    SingleDaySource(
                        dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                        date: date
                    )
                ),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualSingleDay,
                groupID: nil
            )
        )
        let resolver = ScheduledDateSourceResolver(
            sourceStore: sourceStore,
            suppressedDateStore: suppressedStore
        )
        let entries = resolver.resolvedEntries(from: makeDate(year: 2026, month: 2, day: 1), limit: 60, timeZone: timeZone)

        #expect(entries.count == 1)
        #expect(entries.first?.date == date)
        #expect(entries.first?.isExplicitOneOff == true)
    }

    @Test
    func implicitUpcomingRamadanAppearsWithoutSavedSources() {
        let suiteName = "ScheduledDateSourceResolverTests.ImplicitRamadan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let resolver = ScheduledDateSourceResolver(
            sourceStore: ScheduledDateSourceStore(defaults: defaults),
            suppressedDateStore: SuppressedScheduledDateStore(defaults: defaults)
        )
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let entries = resolver.resolvedEntries(
            from: makeDate(year: 2026, month: 1, day: 1),
            limit: 40,
            timeZone: timeZone
        )

        #expect(entries.isEmpty == false)
        #expect(entries.allSatisfy { entry in
            entry.provenances.contains { $0.sourceOrigin == .defaultRamadan }
        })
    }

    @Test
    func implicitCurrentRamadanUsesRemainingDaysOfOngoingMonth() {
        let suiteName = "ScheduledDateSourceResolverTests.CurrentRamadan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let resolver = ScheduledDateSourceResolver(
            sourceStore: ScheduledDateSourceStore(defaults: defaults),
            suppressedDateStore: SuppressedScheduledDateStore(defaults: defaults)
        )
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let entries = resolver.resolvedEntries(
            from: makeDate(year: 2026, month: 3, day: 2),
            limit: 10,
            timeZone: timeZone
        )

        #expect(entries.isEmpty == false)
        #expect(entries.first?.dateKey == "2026-03-02")
        #expect(entries.allSatisfy { entry in
            entry.provenances.contains { $0.sourceOrigin == .defaultRamadan }
        })
    }

    @Test
    func overlappingSourcesDeduplicateAndSuppressionSkipsOneDate() {
        let suiteName = "ScheduledDateSourceResolverTests.Deduped"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let sourceStore = ScheduledDateSourceStore(defaults: defaults)
        let suppressedStore = SuppressedScheduledDateStore(defaults: defaults)
        sourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .gregorianRange(
                    GregorianRangeSource(
                        startDate: makeDate(year: 2026, month: 2, day: 20),
                        endDate: makeDate(year: 2026, month: 2, day: 22),
                        timeZone: timeZone
                    )
                ),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualGregorianRange,
                groupID: nil
            )
        )
        sourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(
                    SingleDaySource(
                        dateKey: "2026-02-21",
                        date: makeDate(year: 2026, month: 2, day: 21)
                    )
                ),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualSingleDay,
                groupID: nil
            )
        )
        suppressedStore.insert("2026-02-22")
        let resolver = ScheduledDateSourceResolver(
            sourceStore: sourceStore,
            suppressedDateStore: suppressedStore
        )
        let entries = resolver.resolvedEntries(from: makeDate(year: 2026, month: 2, day: 1), limit: 60, timeZone: timeZone)

        let focusKeys: Set<String> = ["2026-02-20", "2026-02-21", "2026-02-22"]
        let focusEntries = entries.filter { focusKeys.contains($0.dateKey) }

        #expect(focusEntries.map(\.dateKey) == ["2026-02-20", "2026-02-21"])

        let feb20 = focusEntries.first(where: { $0.dateKey == "2026-02-20" })
        #expect(feb20?.provenances.contains(where: { $0.sourceOrigin == .manualGregorianRange }) == true)

        let feb21 = focusEntries.first(where: { $0.dateKey == "2026-02-21" })
        #expect(feb21?.provenances.contains(where: { $0.sourceOrigin == .manualGregorianRange }) == true)
        #expect(feb21?.provenances.contains(where: { $0.sourceOrigin == .manualSingleDay }) == true)
    }

    @Test
    func recurringRamadanRespectsAdjustment() {
        let suiteName = "ScheduledDateSourceResolverTests.Ramadan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        adjustmentStore.setAdjustment(for: HijriYearMonth(hijriYear: 1447, month: .ramadan), offsetDays: 1)
        let adjustedCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(
                baselineProvider: HijriBaselineMonthStarts.starts,
                adjustmentStore: adjustmentStore
            )
        )
        let sourceStore = ScheduledDateSourceStore(defaults: defaults)
        let suppressedStore = SuppressedScheduledDateStore(defaults: defaults)
        sourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .recurringIslamic(
                    RecurringIslamicSource(
                        rule: .ramadan,
                        startDate: makeDate(year: 2026, month: 2, day: 1)
                    )
                ),
                createdAt: Date(),
                isEnabled: true,
                origin: .recurringIslamic(.ramadan),
                groupID: nil
            )
        )
        let resolver = ScheduledDateSourceResolver(
            sourceStore: sourceStore,
            suppressedDateStore: suppressedStore,
            adjustedHijriCalendar: adjustedCalendar
        )
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let entries = resolver.resolvedEntries(from: makeDate(year: 2026, month: 2, day: 1), limit: 5, timeZone: timeZone)

        let expectedStart = adjustedCalendar.gregorianDate(
            for: HijriYearMonth(hijriYear: 1447, month: .ramadan),
            dayOfMonth: 1,
            timeZone: timeZone
        )
        #expect(expectedStart != nil)
        if let expectedStart {
            let expectedKey = DateHelpers.dayIdentifier(for: expectedStart, timeZone: timeZone)
            #expect(entries.first?.dateKey == expectedKey)
        }
        #expect(entries.allSatisfy { adjustedCalendar.isRamadan(date: $0.date, timeZone: timeZone) })
    }

    @Test
    func quickAddGeneratorFindsNextMondayThursdayPair() {
        let generator = IslamicQuickAddGenerator()
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let dates = generator.dates(
            for: .nextMondayThursdayPair,
            startDate: makeDate(year: 2026, month: 3, day: 2),
            timeZone: timeZone
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        #expect(dates.count == 2)
        #expect(calendar.component(.weekday, from: dates[0]) == 2)
        #expect(calendar.component(.weekday, from: dates[1]) == 5)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
