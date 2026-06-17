## Context

The active scheduling path is resolver-driven:

`MorningResolver` materializes `ScheduledEvent`s -> `LegacyResolvedDayAdapter` stores them on `ActiveAlarmDay.scheduledEvents` -> `AlarmScheduler.buildPlannedEvents` iterates each future event and delivery kind -> `RoutineScheduler.scheduleEvent` schedules each delivery through Notification or AlarmKit adapters.

This means `snoozeDuration: nil` is expected: Wake Checks are not native snooze. They are separate Subh-owned wake deliveries with deterministic event IDs.

## Decisions

1. **Use resolver-materialized events everywhere scheduling needs a day.**
   Cache hits may reuse `ActiveAlarmDay`s, but cache misses must build an active day through `ActiveDayResolver.buildActiveDayIfNeeded` or equivalent resolver pipeline. Compatibility fallback events are only for legacy degraded contexts where resolver inputs are unavailable.

2. **Make `scheduleEvent` the canonical scheduler seam.**
   `RoutineScheduler` direct helpers that schedule `DaySchedule.wakeDate` are removed if unused. Production scheduling should not call APIs that can only schedule one wake alarm.

3. **Test the delivery handoff, not only pure planning.**
   Tests must prove the complete handoff from wake attempt mode to `ActiveAlarmDay.scheduledEvents`, then into scheduler calls, and finally into expected-delivery records.

4. **Keep stale cleanup broader than active scheduling.**
   Identifier cancellation may still include deterministic stale wake-check lookahead IDs. That cleanup horizon is not a product attempt count.

## Risks

- AlarmKit pending delivery behavior cannot be fully proven on simulator. Fake schedulers can prove that Subh submits every expected event to the adapter layer.
- Removing direct helper APIs should be limited to unused methods. If a call site exists, it must be migrated to event-based scheduling instead of deleted blindly.
