import Foundation
import Testing
@testable import Suhoor

@Suite
struct ScheduleManagerHijriTests {
    @Test
    @MainActor
    func appSettingsDecodeDefaultsHijriSpecialDaySettingsSafely() throws {
        let data = try JSONEncoder().encode(AppSettings.default)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded.hijriSpecialDaySettings == .default)
    }

    @Test
    @MainActor
    func ramadanOffsetPreviewOnlyTouchesRamadanDerivedDates() async {
        let suiteName = "ScheduleManagerHijriTests.Ramadan"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: adjustmentStore
        )

        settingsStore.update { draft in
            draft.hijriSpecialDaySettings = HijriSpecialDaySettings(
                isEnabled: true,
                ramadanDailyEnabled: true,
                whiteDaysEnabled: false,
                ashuraEnabled: false,
                arafahEnabled: true,
                eidAlFitrEnabled: true,
                eidAlAdhaEnabled: true
            )
        }

        let affected = manager.previewAffectedHijriDateIdentifiersForMonthAdjustment(
            .ramadan,
            offsetDays: 1,
            startDate: makeDate(year: 2026, month: 2, day: 1),
            days: 140,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        #expect(!affected.isEmpty)
        #expect(affected.contains(where: { $0.hasPrefix("2026-02") || $0.hasPrefix("2026-03") }))
        #expect(!affected.contains("2026-05-26"))
        #expect(!affected.contains("2026-05-27"))
    }

    @Test
    @MainActor
    func muharramPreviewDoesNotTouchRamadanDates() async {
        let suiteName = "ScheduleManagerHijriTests.Muharram"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            hijriAdjustmentStore: adjustmentStore
        )

        settingsStore.update { draft in
            draft.hijriSpecialDaySettings = HijriSpecialDaySettings(
                isEnabled: true,
                ramadanDailyEnabled: true,
                whiteDaysEnabled: false,
                ashuraEnabled: true,
                arafahEnabled: false,
                eidAlFitrEnabled: false,
                eidAlAdhaEnabled: false
            )
        }

        let affected = manager.previewAffectedHijriDateIdentifiersForMonthAdjustment(
            .muharram,
            offsetDays: 1,
            startDate: makeDate(year: 2025, month: 6, day: 20),
            days: 30,
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        #expect(!affected.isEmpty)
        #expect(!affected.contains(where: { $0.hasPrefix("2026-02") || $0.hasPrefix("2026-03") }))
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
