# Suhoor Test Plan

Purpose
- Provide comprehensive coverage of core alarm scheduling, settings, and Ramadan logic while preserving current behavior.
- Validate the 3-alarm workflow (Suhoor wake, Fajr reminder, Fajr adhan) and ensure independence of each alarm.
- Ensure scheduling reliability across permissions, location, and edge-case date/time scenarios.

Scope
- Included: scheduling, notifications, AlarmKit routing, settings persistence, rule engine, Ramadan profile, offsets, and audit/logging.
- Excluded: new features, UI redesigns, third-party services not present in project.

Environments
- iOS 26+ device with AlarmKit available.
- iOS 16.1+ device for Live Activities (countdown).
- Simulator (AlarmKit unavailable) for notification fallback testing.
- Time zone coverage: at least 2 time zones; include DST transitions.

Feature Flags (default OFF)
- enableCountdown
- enableSnooze
- enableAlarmKitTestMode
- useAlarmCoordinatorForScheduling (derived)

Test Data Setup
- Fixed location with known coordinates and time zone.
- Auto location with mock/real location updates.
- Settings variations: enabled/disabled, reminder enabled/disabled, at-Fajr enabled/disabled, sound selection, offsets.
- Ramadan profile variations: base, weekend boost, last 10 nights, Laylatul Qadr overrides, per-day exceptions.


1) Unit Tests

1.1 AppSettings
- Encode/decode symmetry using JSONEncoder/JSONDecoder.
- Default values stable; toggling settings results in expected property changes.

1.2 DateHelpers
- startOfToday/startOfTomorrow in specified time zones.
- dayIdentifier stable across time zones.
- dates(startingFrom/count) and dates(from/to) inclusive range behavior.

1.3 SchedulingIdentifiers
- dailyIdentifier format; legacy format; test identifier format.
- alarmID/testAlarmID stable UUID mapping.
- No collisions between dailyIdentifier and legacyIdentifier for same day/kind.

1.4 ScheduleEventKind
- Titles and bodies correct.
- Codable conformance round-trip with JSON.

1.5 RuleEngine / RamadanProfileEngine
- Ramadan range computed for current and next year; day count >= 29.
- Adjustments shift range start/end.
- Precedence rules: per-day override > LQ > last10 > weekend > base.
- Disabled day yields disabled summary.
- Sound overrides propagate.

1.6 ScheduleEventCalculator
- wake/reminder date computation based on offsets; verify with known inputs.
- Boundary date equals fajr date when enabled.

1.7 AlarmRecordStore
- Upsert/replace by ID.
- remove(id), clearAllTests, clearAll.
- Codable persistence round-trip via UserDefaults.

1.8 AlarmStateStore
- Update state, clear state, entries order and lookup.

1.9 CountdownSessionStore
- Store/load session and activityId round-trips.


2) Integration Tests (Logic-Only)

2.1 ScheduleManager Refresh
- Disabled settings: cancels all; schedules empty; mode .none; status "Off".
- Location missing with auto mode: status "Locating…"; no schedule.
- Fixed location missing: status "Fixed location required."; no schedule.

2.2 Scheduling Mode Selection
- AlarmKit authorized: schedulingMode == .alarmKit.
- AlarmKit denied/unavailable: schedulingMode == .notifications.

2.3 Schedule Generation
- Dates generated match rule engine range rules.
- Upcoming filter: schedule excluded if all events <= now.
- Per-day exceptions remove disabled days.

2.4 Schedule All Enabled Events
- Each schedule triggers wake/reminder/adhan when enabled and in future.
- Cancel All Upcoming removes both current and legacy identifiers.

2.5 AlarmCoordinator / AlarmEventRouter
- AlarmCoordinator schedule stores AlarmRecord and state.
- Dismiss one alarm does not remove others.
- AlarmEventRouter: alerting -> fired event; missing alarm -> dismissed event.

2.6 NotificationScheduler
- Schedule/cancel by identifier; legacy cancellation included.
- Test notifications schedule for correct kind and delay.


3) AlarmKit & Notifications (Device/Simulator)

3.1 AlarmKit Authorization
- Authorized -> schedules AlarmKit alarms.
- Denied -> uses notifications fallback.
- Simulator -> AlarmKit path disabled; notifications used.

3.2 AlarmKit Scheduling
- Wake/reminder/adhan scheduled independently.
- Dismissal of one does not cancel others.
- Legacy AlarmKit IDs canceled to avoid duplicates.

3.3 Notification Scheduling
- Wake/reminder/adhan scheduled with distinct identifiers.
- Cancel only cancels specified identifiers.
- Legacy identifiers canceled during cleanup.

3.4 AlarmKit Test Mode (feature flag)
- Disabled flag: no test alarms scheduled.
- Enabled flag: three-event test creates records and state.
- Cancel test alarms clears stores and logs.


4) Countdown / Live Activities (Feature Flag)

4.1 Countdown Disabled
- enableCountdown OFF: no countdown state changes.

4.2 Countdown Enabled (device only)
- Fajr reminder triggers countdown start.
- Fajr adhan triggers countdown end.
- Reconcile ends when time >= fajrDateTime.
- CleanupLiveActivities ends orphan activities.


5) UI & Settings Behavior (Manual)

5.1 Onboarding / Enable Flow
- Enable with missing location prompts; shows error message.
- Notification denial shows guidance text.
- AlarmKit denial fallback messaging.

5.2 Settings Toggles
- Wake enabled/disabled reflects schedule generation.
- Reminder enabled toggles reminder schedule.
- At-Fajr enabled toggles adhan schedule and sound selection.
- Snooze toggle has no effect when enableSnooze OFF.

5.3 Schedule Screens
- Schedule list shows correct day labels: Today/Tomorrow/weekday.
- Day detail shows offsets, badges, and overrides.


6) Edge Cases

6.1 Time & Calendar
- DST start/end within scheduled window: no skipped or duplicated alarms.
- Time zone change after schedules created: refresh creates new schedules.
- Daylight boundary where fajr occurs near midnight.

6.2 Past Events
- Scheduling skips events in the past but keeps future events same day.
- Schedule generation for day with reminder earlier than wake.

6.3 Data Persistence
- App relaunch with cached schedules: data displayed without crash.
- Cache cleared on reset.

6.4 Location
- Auto location updates trigger refresh and schedule regeneration.
- Fixed location parsing and bounds checks.

6.5 Alarm Reliability
- Cancel wake does not cancel reminder or adhan.
- Dismiss reminder does not cancel adhan.
- Record store retains unrelated alarms.


7) Logging & Diagnostics
- Scheduling audit reports expected vs scheduled.
- DebugEventLog records fired/dismissed/scheduled events.
- No noisy logging in release configurations.


Execution Notes
- Prioritize unit tests for RuleEngine, SchedulingIdentifiers, DateHelpers, AlarmRecordStore, ScheduleEventCalculator.
- Use device runs for AlarmKit and Live Activities.
- Use simulator for notification fallback logic.

Deliverables
- Implement test cases in `Suhoor/SuhoorTests/SuhoorTests.swift` using Testing framework.
- Add UI tests with XCUIAutomation for enable/disable flows and schedule list states if needed.
