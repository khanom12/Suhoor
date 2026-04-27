# Subh MVP Test Plan

## Purpose

- Prove the ordinary Fajr morning loop end to end: resolve, explain, schedule, wake, complete, and reflect.
- Validate alarm reliability and degraded-state clarity before claiming wake support is ready.
- Keep Subh framed as a Fajr-centered morning system; Suhoor-era names remain only where required for documented compatibility.

## MVP Readiness Gates

Subh is not MVP-ready until each gate has either passing evidence or a tracked exception:

| Area | Requirement | Evidence |
| --- | --- | --- |
| Build | Clean simulator build from repo root | `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| Tests | Configured unit test plan passes | `xcodebuild -project Subh.xcodeproj -scheme Subh -testPlan Subh -destination 'platform=iOS Simulator,name=iPhone 16' test` |
| Onboarding | User can configure location, calculation method, permissions, and reach Home | Simulator/manual UI pass |
| Home | Home answers tomorrow morning first and shows Fajrcast/Morningcast support | UI/manual and snapshot tests |
| Resolver | Wake plan, explanation, context flags, trust notes, and reliability state resolve deterministically | Unit tests with fixed dates/time zones |
| Alarm | Wake support schedules reliably or honestly degrades | Simulator fallback plus physical-device AlarmKit pass |
| Refresh | Launch, foreground, settings, location, and time-sensitive changes refresh schedules | Integration tests |
| Fasting/Qada | Fasting and Qada modify the same morning engine | Resolver and presentation tests |
| Override | Tomorrow can be adjusted without mutating default plan | Integration/manual pass |
| Completion | User can log Fajr and relevant fast completion | Domain tests and UI/manual pass |
| Reflection | Home/detail can reflect completion calmly without shame or engagement traps | UI/manual pass |
| Naming | Visible product language is Subh; Suhoor remains documented compatibility only | Search/audit pass |
| Edge Cases | DST, timezone, stale cache, permission loss, and location loss are covered | Unit/integration/manual pass |

## Primary MVP Path: Ordinary Fajr Morning

This is the first path to make boringly reliable before expanding advanced observance work.

1. Fresh install or reset local data.
2. Complete onboarding.
3. Choose or grant location.
4. Confirm calculation method.
5. Grant AlarmKit when available; grant notifications for fallback/reminders.
6. Land on Home.
7. Verify tomorrow hero shows date, wake time, meaningful status, and concise wake relationship.
8. Open tomorrow detail and verify the wake explanation, trust notes, and calculation settings are understandable.
9. Verify wake/reminder/Fajr notice events are scheduled or clearly degraded.
10. Simulate or reach the next morning wake path.
11. Log Fajr completion.
12. Verify Home/detail reflects completion calmly.

## Test Environments

- iOS simulator for build, unit tests, notification fallback, and most UI flows.
- Physical iOS 26+ device for AlarmKit authorization and real wake scheduling.
- Simulator or device locations covering at least two time zones.
- Fixed dates around DST start/end.
- Permission states: ready, denied, revoked, unavailable.

## Unit Tests

### Morning Resolution

- Fresh install resolves default wake to 30 minutes before supported Fajr end.
- Legacy inherited Fajr-start defaults migrate to Fajr-end minus 30.
- Custom wake settings are preserved.
- Missing supported Fajr end falls back with a trust note.
- Sunrise-derived supported Fajr end emits provider/trust metadata.
- Fasting context modifies the resolved morning without creating a separate engine.
- Qada context produces the expected context and completion effect.
- One-day override takes precedence over default plan.
- Location and timezone changes alter resolved schedules deterministically.
- DST transitions do not duplicate or skip wake events.
- Cache invalidates when wake-rule signature changes.

### Schedule And Refresh

- `DateHelpers` produces stable day keys across time zones.
- Schedule generation excludes fully past events but keeps future same-day events.
- Schedule refresh reacts to launch, foreground, settings changes, alarm config changes, location updates, and authorization changes.
- Schedule cache decode failures recover by recomputing.
- Stale schedule cache does not preserve old wake defaults.

### Alarm Reliability

- Scheduling mode selects AlarmKit when authorized and notifications when unavailable/denied.
- Wake, reminder, and Fajr notice use independent identifiers.
- Dismissing or canceling one event does not cancel unrelated events.
- Legacy identifiers are canceled during rebuild to avoid duplicates.
- Record and state stores preserve unrelated alarms.
- Permission loss produces degraded state instead of implying reliable wake support.

### Completion

- Fajr completion can be completed, missed, or not tracked.
- Fast completion can be completed, not completed, or still in progress when relevant.
- Qada effects are derived from the completion state.
- Completion snapshots are deterministic with fixed dates/time zones.
- Reflection copy is operational and non-shaming.

### Presentation

- Home hero suppresses ordinary/default labels and diagnostic provider text.
- Fasting, Qada, Tahajjud, changed, skipped, and fixed wake states produce short meaningful hero copy.
- Weekly Fajrcast selects tomorrow by default.
- Morningcast excludes today and tomorrow and respects the maximum count.
- Degraded reliability copy is short, visible, and actionable.

## Integration Tests

### Onboarding

- Missing location blocks precise schedule preview and gives clear guidance.
- Fixed city selection produces a schedule preview.
- AlarmKit denial falls back with accurate messaging.
- Notification denial explains reminder/fallback impact.
- Completed onboarding lands on `SubhHomeView`.

### Home And Details

- Tapping the tomorrow hero opens tomorrow detail when resolved.
- Weekly Fajrcast opens the Fajr-window detail for the selected date.
- Morningcast rows open the relevant day detail.
- Settings remains reachable.
- Large Dynamic Type keeps hero text readable and bottom controls clear of content.

### Scheduling Reconciliation

- App launch rebuilds or reuses schedule state appropriately.
- Foreground refresh catches stale schedules.
- Location changes regenerate active window and scheduled events.
- Timezone changes regenerate day keys and event times.
- Settings and overrides reconcile without duplicate alarms.

## Device And Manual QA

These cannot be fully proven by simulator-only CI and remain MVP gates until manually signed off.

- Physical-device AlarmKit authorization: allowed, denied, revoked.
- AlarmKit wake fires at expected time.
- Notification fallback fires on simulator and device when AlarmKit is unavailable.
- Silent mode, Focus, and notification settings are documented with honest degraded-state copy.
- Device reboot or app kill does not leave stale scheduled state unexplained.
- DST start and DST end windows are manually checked with fixed test dates.
- Location permission loss and stale location are surfaced clearly.

## Naming And Compatibility Audit

- Visible product name is Subh in primary app surfaces, docs, and test plan.
- Use wake, Fajr morning, supported Fajr end, and morning plan language for new copy.
- Retain `khanomar.Suhoor`, `Suhoor.*` storage keys, and compatibility-bound model names until an explicit migration proposal changes them.
- Any retained Suhoor-era symbol should be either compatibility-bound or filed as a cleanup follow-up.

## Out Of Scope Before MVP

- Advanced Ramadan mode.
- Full fasting calendar.
- Rich Qada management.
- Education or content library.
- Community, social, streak, or engagement mechanics.
- Masjid/jama'ah integration.
- Advanced analytics.
- Broad multi-prayer expansion.

## Execution Notes

- Prefer fixed dates, fixed calendars, injected clocks, and explicit time zones.
- Run narrow tests after focused changes, then the full configured test plan before commits that claim MVP confidence.
- Record physical-device alarm results separately from simulator test results.
- Do not weaken privacy, reliability language, or compatibility storage behavior while cleaning naming drift.
