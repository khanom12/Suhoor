## Context

Subh already has resolver-materialized `ScheduledEvent`s, channel-aware identifiers, `DeliveryReconciliationReport`, `AlarmDeliveryLedgerStore`, `AlarmScheduler`, `RoutineScheduler`, `NotificationScheduler`, and `AlarmKitScheduler`. The gap is that diagnostics can detect stale or missing platform deliveries, but repair is not yet a first-class transaction and cold starts still lose the scheduler's in-memory `lastPlannedEvents`.

## Decisions

1. **Persist expected deliveries, not wake truth.**
   Store compact expected delivery snapshots derived from the current resolver output. The store is only for delivery repair and diagnostics; morning resolution remains authoritative.

2. **Repair only Subh-owned identifiers.**
   Cancellation targets current and known legacy Subh notification identifiers and AlarmKit UUIDs within the scheduling horizon. Pending deliveries that do not match Subh identifier shapes are ignored.

3. **Run repair after normal reconciliation.**
   Schedule refresh continues to build resolved days and schedule through `AlarmScheduler`. A repair coordinator then compares expected, persisted, and pending platform state, cancels stale Subh-owned extras, and reschedules missing or mismatched expected deliveries.

4. **Broaden execution cancellation by date.**
   Awake confirmation and mode switches must cancel every Subh wake primary/check delivery for the affected date, including persisted expected deliveries and deterministic prior-mode identifiers, before recording confirmation or cancellation.

5. **Platform callbacks are factual records.**
   Notification and AlarmKit fire/stop observations may mark Wake Session events fired or stopped. They must not confirm awake, prayer, missed prayer, or fast completion unless a future explicitly supported acknowledgement flow is added and tested.

6. **Debug reset cleans both channels when possible.**
   Debug install reset already can clear pending notifications. It should also cancel Subh-owned AlarmKit identifiers across the scheduling horizon when AlarmKit is available; otherwise it records a local warning.

## Model And API Shape

- Add `ExpectedDeliveryPlanStore` with a capped local payload of expected delivery records.
- Add `DeliveryRepairCoordinator` and `DeliveryRepairResult` around existing reconciliation models.
- Extend scheduler protocol seams to support pending-state repair in tests and production adapters without exposing platform APIs to SwiftUI.
- Extend `SchedulingIdentifierSet` with helpers for date-scoped wake-session delivery cancellation and persisted expected delivery cancellation.

## Risks

- AlarmKit pending-state inspection may be unavailable on simulator or older platform states. Repair should mark verification limited rather than claiming success.
- Broad stale cleanup can be dangerous if identifiers are overbroad. Keep cancellation scoped to known Subh identifier formats, date keys, and the configured scheduling horizon.
- Persisted expected deliveries can become stale. Always rebuild and replace them from current resolved events after successful schedule refresh.

## Validation

Use deterministic unit tests for repair decisions and fake schedulers. Physical-device QA remains required for audible AlarmKit delivery, Focus/silent behavior, and real OS callback behavior.
