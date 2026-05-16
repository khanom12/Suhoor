import Foundation

#if DEBUG
enum UITestFixtureConfigurator {
    static var isMorningHeroFajrAdjusterFixtureRequested: Bool {
        UITestLaunchConfiguration.usesMorningHeroFajrAdjusterFixture
            || UITestLaunchConfiguration.usesMorningHeroEarlyWorshipAdjusterFixture
    }

    static func resetPersistentStateIfNeeded() {
        guard isMorningHeroFajrAdjusterFixtureRequested,
              let bundleIdentifier = Bundle.main.bundleIdentifier
        else {
            return
        }

        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }

    @MainActor
    static func applyIfNeeded(
        settingsStore: SuhoorSettingsStore,
        alarmConfigStore: AlarmConfigStore,
        timeProvider: any TimeProviding = SystemTimeProvider()
    ) {
        guard isMorningHeroFajrAdjusterFixtureRequested else { return }

        settingsStore.update { draft in
            draft.isConfigured = true
            draft.isEnabled = true
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
            draft.reminderEnabledGlobal = true
            draft.atFajrEnabledGlobal = true
            draft.pausePrayerPrompts = false
            draft.pauseFastingPrompts = false
            draft.hijriSpecialDaySettings = .default
            draft.quietPeriodEnabled = false
        }

        alarmConfigStore.defaults = .default
        seedUpcomingMorning(alarmConfigStore: alarmConfigStore, timeProvider: timeProvider)
    }

    private static func seedUpcomingMorning(
        alarmConfigStore: AlarmConfigStore,
        timeProvider: any TimeProviding
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: timeProvider.now())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        alarmConfigStore.addSingleDaySource(tomorrow, timeZone: calendar.timeZone)

        guard UITestLaunchConfiguration.usesMorningHeroEarlyWorshipAdjusterFixture else { return }

        alarmConfigStore.updateOverride(for: tomorrow, timeZone: calendar.timeZone) { override in
            override.wakeStateOverride = .preFajr
            override.wakeAnchorTypeOverride = .fajrStart
            override.wakeDeltaOverrideMinutes = 30
            override.quickWakeModeOverride = .suhoor
            override.earlyWakePurposeOverride = .fast
            override.tahajjudRefinement = false
            override.bypassLatestWakeCap = true
        }
    }
}
#endif
