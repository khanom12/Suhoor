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
