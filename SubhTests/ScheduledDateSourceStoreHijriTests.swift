import Foundation
import Testing
@testable import Subh

@Suite
struct ScheduledDateSourceStoreHijriTests {
    @Test
    func migrationConvertsHijriQuickAddSingleDaySources() {
        let suiteName = "ScheduledDateSourceStoreHijriTests.Migration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current

        let date = Self.makeDate(year: 2026, month: 7, day: 1, timeZone: timeZone)
        let single = SingleDaySource(
            dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
            date: date
        )
        let source = ScheduledDateSource(
            id: UUID(),
            kind: .singleDay(single),
            createdAt: Date(),
            isEnabled: true,
            origin: .islamicQuickAdd(.nextWhiteDays),
            groupID: nil
        )
        let data = try? JSONEncoder().encode([source])
        defaults.set(data, forKey: "Suhoor.ScheduledDateSources")
        defaults.set(0, forKey: "Suhoor.ScheduledDateSourcesMigrationVersion")

        let store = ScheduledDateSourceStore(defaults: defaults, timeZone: timeZone)
        #expect(store.sources.count == 1)
        guard case .hijriSingleDay(let hijri) = store.sources[0].kind else {
            #expect(false)
            return
        }

        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let calendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
        )
        let components = calendar.adjustedComponents(for: date, timeZone: timeZone)
        #expect(components != nil)
        guard let components else { return }
        #expect(hijri.hijriYear == components.hijriYear)
        #expect(hijri.month == components.month)
        #expect(hijri.day == components.day)
        #expect(store.sources[0].intentAnchor.kind == .observance)
        #expect(store.sources[0].intentAnchor.observanceID == IslamicQuickAddKind.nextWhiteDays.rawValue)
        #expect(store.sources[0].intentAnchor.isCalendarMovable)
    }

    @Test
    func legacyDecodedSourcesDerivePlanningAnchors() throws {
        struct LegacySource: Codable {
            let id: UUID
            let kind: ScheduledDateSourceKind
            let createdAt: Date
            let isEnabled: Bool
            let origin: ScheduledDateSourceOrigin
            let groupID: UUID?
        }

        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 7, day: 2, timeZone: timeZone)
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let legacy = LegacySource(
            id: UUID(),
            kind: .singleDay(SingleDaySource(dateKey: key, date: date)),
            createdAt: Date(),
            isEnabled: true,
            origin: .manualSingleDay,
            groupID: nil
        )

        let data = try JSONEncoder().encode([legacy])
        let decoded = try JSONDecoder().decode([ScheduledDateSource].self, from: data)

        #expect(decoded.first?.intentAnchor.kind == .gregorianDate)
        #expect(decoded.first?.intentAnchor.gregorianDateKey == key)
        #expect(decoded.first?.intentAnchor.isCalendarMovable == false)
    }

    @Test
    func sourceKindsExposeExpectedPlanningAnchors() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 7, day: 2, timeZone: timeZone)
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)

        let manual = ScheduledDateSource(
            id: UUID(),
            kind: .singleDay(SingleDaySource(dateKey: key, date: date)),
            createdAt: Date(),
            isEnabled: true,
            origin: .manualSingleDay,
            groupID: nil
        )
        let arafah = ScheduledDateSource(
            id: UUID(),
            kind: .hijriSingleDay(HijriSingleDaySource(hijriYear: 1447, month: .dhulHijjah, day: 9)),
            createdAt: Date(),
            isEnabled: true,
            origin: .islamicQuickAdd(.nextArafah),
            groupID: nil
        )
        let mondayThursday = ScheduledDateSource(
            id: UUID(),
            kind: .recurringIslamic(RecurringIslamicSource(rule: .mondayThursday, startDate: date)),
            createdAt: Date(),
            isEnabled: true,
            origin: .recurringIslamic(.mondayThursday),
            groupID: nil
        )
        let completion = MorningIntentAnchor.completionHistory(
            historyID: "fast-\(key)",
            dateKey: key
        )

        #expect(manual.intentAnchor.kind == .gregorianDate)
        #expect(manual.intentAnchor.gregorianDateKey == key)
        #expect(manual.intentAnchor.isCalendarMovable == false)
        #expect(arafah.intentAnchor.kind == .observance)
        #expect(arafah.intentAnchor.observanceID == IslamicQuickAddKind.nextArafah.rawValue)
        #expect(arafah.intentAnchor.isCalendarMovable)
        #expect(mondayThursday.intentAnchor.kind == .weekdayPattern)
        #expect(mondayThursday.intentAnchor.weekdays == [2, 5])
        #expect(completion.kind == .completionHistory)
        #expect(completion.isCalendarMovable == false)
    }

    @Test
    func resolverProvenanceCarriesPlanningAnchor() {
        let suiteName = "ScheduledDateSourceStoreHijriTests.ProvenanceAnchor"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let date = Self.makeDate(year: 2026, month: 7, day: 2, timeZone: timeZone)
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let sourceStore = ScheduledDateSourceStore(defaults: defaults)
        sourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(SingleDaySource(dateKey: key, date: date)),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualSingleDay,
                groupID: nil
            )
        )
        let resolver = ScheduledDateSourceResolver(
            sourceStore: sourceStore,
            suppressedDateStore: SuppressedScheduledDateStore(defaults: defaults)
        )

        let entries = resolver.resolvedEntries(from: date, limit: 5, timeZone: timeZone)
        let provenance = entries.first(where: { $0.dateKey == key })?.provenances.first {
            $0.sourceOrigin == .manualSingleDay
        }

        #expect(provenance?.intentAnchor.kind == .gregorianDate)
        #expect(provenance?.intentAnchor.gregorianDateKey == key)
    }

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
