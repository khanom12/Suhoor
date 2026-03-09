import Foundation
import Testing
@testable import Suhoor

@Suite
struct ScheduleServiceExtractionTests {
    @Test
    @MainActor
    func refreshCoordinatorMergesRequestsUsingLatestReason() async {
        var received: [PendingScheduleRefresh] = []
        let coordinator = ScheduleRefreshCoordinator { request in
            received.append(request)
        }

        coordinator.requestRefresh(reason: .settingsChanged, force: false)
        coordinator.requestRefresh(reason: .manual, force: true)

        try? await Task.sleep(nanoseconds: 350_000_000)

        #expect(received == [PendingScheduleRefresh(reason: .manual, force: true)])
    }

    @Test
    @MainActor
    func refreshCoordinatorCancelDropsPendingRefresh() async {
        var received: [PendingScheduleRefresh] = []
        let coordinator = ScheduleRefreshCoordinator { request in
            received.append(request)
        }

        coordinator.requestRefresh(reason: .settingsChanged, force: true)
        coordinator.cancelAll()

        try? await Task.sleep(nanoseconds: 350_000_000)

        #expect(received.isEmpty)
    }

    @Test
    func homeSurfaceAssemblerUsesScheduleFallbackWhenTodayIsNotCached() {
        let timeZone = TimeZone(identifier: "America/Toronto") ?? .current
        let now = Self.makeDate(year: 2026, month: 4, day: 10, hour: 6, minute: 0, timeZone: timeZone)
        let schedule = Self.makeSchedule(for: now, timeZone: timeZone)

        let input = HomeSurfaceAssembler().makeInput(
            now: now,
            dismissedWarnings: [],
            activeWindowSnapshot: .empty,
            nextWakeEventSummary: nil,
            settings: .default,
            permissionSnapshot: .empty,
            adjustedHijriCalendar: AdjustedHijriCalendar.shared,
            scheduleLookup: { _ in schedule },
            timeZone: timeZone
        )

        #expect(input.currentDay == nil)
        #expect(input.todaySchedule == schedule)
    }

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components) ?? .distantPast
    }

    private static func makeSchedule(for date: Date, timeZone: TimeZone) -> DaySchedule {
        let dayStart = DateHelpers.startOfDay(date, in: timeZone)
        let fajr = dayStart.addingTimeInterval(5 * 60 * 60)
        let wake = fajr.addingTimeInterval(-45 * 60)
        let maghrib = dayStart.addingTimeInterval(19 * 60 * 60)
        return DaySchedule(
            date: dayStart,
            fajrDate: fajr,
            maghribDate: maghrib,
            wakeDate: wake,
            reminderDate: wake.addingTimeInterval(-15 * 60),
            boundaryDate: fajr,
            iftarDate: maghrib,
            locationDescription: "Test",
            offsetMinutes: 45,
            calculationMethodName: "Test",
            timeZone: timeZone
        )
    }
}
