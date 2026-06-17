## Why

Subh now exposes Wake Attempts as a user setting, but the scheduling integration needs to be provably event-based end to end. The active path should schedule every resolver-materialized primary and wake-check `ScheduledEvent`, while legacy direct `DaySchedule` scheduling helpers and compatibility fallbacks can make the implementation look or behave as if only one wake alarm is scheduled.

## What Changes

- Document the v5 Wake Attempts delivery model in OpenSpec: Single alarm only schedules one primary wake attempt; Repeat until I'm awake schedules independent wake-check events every five minutes through the relevant cutoff.
- Add integration tests proving `ActiveAlarmDay.scheduledEvents`, `AlarmScheduler`, expected-delivery persistence, notification mode, AlarmKit mode, and mixed mode all consume resolver-materialized wake attempts.
- Replace cache-miss activation and cancellation compatibility fallbacks with active-day construction through the resolver/event pipeline.
- Remove unused direct `DaySchedule` wake/reminder/adhan scheduling helpers from `RoutineScheduler` so `RoutineScheduling.scheduleEvent` is the canonical production scheduling seam.
- Preserve `snoozeDuration: nil` for wake attempts because Subh uses separate scheduled deliveries, not native snooze.

## Impact

- Affected areas include OpenSpec wake-session execution docs, schedule activation fallback, cancellation fallback, `RoutineScheduler`, and focused scheduling tests.
- User settings, date-specific wake intent, Quiet/Pause behavior, wake/prayer separation, and platform adapters remain conceptually unchanged.
- No external desktop specification folder, remote telemetry, or parallel wake engine is introduced.
