## 1. OpenSpec Setup And Validation

- [x] 1.1 Review repo guidance, OpenSpec config, existing specs, completed alarm hardening changes, and the current morning-resolution contract.
- [x] 1.2 Create the `alarm-delivery-schedule-reliability` change with durable `alarm-delivery-reliability` capability and morning-resolution boundary delta.
- [x] 1.3 Run `openspec validate alarm-delivery-schedule-reliability --strict` before implementation and fix validation issues.

## 2. Current Implementation Audit

- [x] 2.1 Audit `ScheduledEvent`, `ResolvedMorningWakeState`, schedule status, alarm activation, and materialized event ownership.
- [x] 2.2 Audit `AlarmScheduler`, `RoutineScheduler`, `NotificationScheduler`, `AlarmKitScheduler`, `AlarmCoordinator`, and permission wrappers.
- [x] 2.3 Audit `SchedulingIdentifiers`, `SchedulingIdentifierSet`, schedule cache reuse, stale cancellation, reconciliation, and ledger code.
- [x] 2.4 Audit lifecycle refresh hooks and existing delivery/reconciliation tests.

## 3. Model Reuse / Model Additions

- [x] 3.1 Reuse existing `ScheduledEvent`, `ExpectedAlarmDelivery`, `DeliveryReconciliationReport`, `AlarmDeliveryLedgerStore`, and morning wake status models where possible.
- [x] 3.2 Add or adapt explicit delivery mode, permission snapshot, delivery plan, planned delivery, skipped-past, and reconciliation-category models.
- [x] 3.3 Keep new delivery models downstream of morning resolution with no prayer or day-purpose calculation inputs.

## 4. Delivery Planning

- [x] 4.1 Build delivery plans from resolver-materialized future events only.
- [x] 4.2 Represent notification fallback and mixed AlarmKit/notification delivery explicitly.
- [x] 4.3 Ensure past events are skipped without being counted as missing expected deliveries.
- [x] 4.4 Preserve active wake intent when delivery is blocked, degraded, failed, or verification-limited.

## 5. Identifier Canonicalization

- [x] 5.1 Centralize channel-aware expected identifiers through `SchedulingIdentifiers`.
- [x] 5.2 Ensure current and known legacy date-scoped identifiers remain cancellable through `SchedulingIdentifierSet`.
- [x] 5.3 Add tests proving views and adapters do not generate separate identifiers.

## 6. Platform Scheduler Adapters

- [x] 6.1 Route planned AlarmKit deliveries through existing AlarmKit adapter/coordinator with availability guards.
- [x] 6.2 Route planned notification deliveries through existing UserNotifications adapter.
- [x] 6.3 Ensure Fajr adhan audio is treated as an active wake audio role, not off/no-alarm.
- [x] 6.4 Ensure disabling later Fajr-begins adhan removes only that boundary cue.

## 7. Cancellation And Stale Cleanup

- [x] 7.1 Cancel current canonical and known legacy identifiers before stale-risky full-window or unknown-day scheduling.
- [x] 7.2 Keep per-date rescheduling scoped to the affected date when safe.
- [x] 7.3 Avoid cancelling unrelated dates or unrelated user alarms.

## 8. Reconciliation

- [x] 8.1 Compare expected deliveries to pending notifications and AlarmKit state.
- [x] 8.2 Report missing expected, fire-date mismatch, unexpected extra, duplicate, permission blocked, platform unavailable, scheduling failed, verification unavailable, matched, and skipped-past categories.
- [x] 8.3 Ensure cache reuse still performs pending-state reconciliation.
- [x] 8.4 Represent limited AlarmKit pending-state verification honestly.

## 9. Ledger And Diagnostics

- [x] 9.1 Record local transaction summaries with trigger reason, scope, counts, permission snapshot, adapter result, and status.
- [x] 9.2 Avoid raw coordinates, sensitive notes, religious analytics, provider payloads, and remote telemetry.
- [x] 9.3 Keep Home/Detail warnings compact and keep forecast surfaces out of diagnostics.

## 10. Status Mapping

- [x] 10.1 Map delivery results back to schedule status without changing wake mode, day purpose, wake boundary, wake time, alarm activation, or completion credit.
- [x] 10.2 Preserve active-but-permission-blocked as active intent with blocked delivery.
- [x] 10.3 Preserve Quiet as resolver-owned delivery suppression with restorable underlying state.

## 11. Lifecycle Refresh Triggers

- [x] 11.1 Expand refresh reasons for notification permission, AlarmKit permission/availability, calculation changes, Hijri adjustment, date-specific wake edits, mode/purpose changes, horizon rollover, and identifier migration.
- [x] 11.2 Wire refresh or reconciliation through existing app and `ScheduleManager` lifecycle paths where possible.
- [x] 11.3 Add tests for permission and time/timezone refresh behavior.

## 12. Tests

- [x] 12.1 Add delivery planning tests for active Fajr denied permission, active Fast notification fallback, AlarmKit route, mixed delivery, Quiet day, Fajr adhan audio, and later Fajr cue toggle.
- [x] 12.2 Add identifier/cancellation tests for stale legacy cancellation and idempotent repeated transactions.
- [x] 12.3 Add reconciliation tests for missing expected, fire-date mismatch, unexpected extra, duplicate, skipped past, cache reuse, and verification unavailable.
- [x] 12.4 Add ledger privacy/summary tests.
- [x] 12.5 Add static architecture tests for SwiftUI views avoiding platform scheduling APIs, identifier generation, and pending-request queries.
- [x] 12.6 Document simulator/device split and physical-device QA checklist.

## 13. Validation / Build

- [x] 13.1 Run `openspec validate alarm-delivery-schedule-reliability --strict` after implementation.
- [x] 13.2 Run focused delivery/reconciliation/ledger tests and affected morning-resolution regression tests.
- [x] 13.3 Run the documented Xcode build/test command or the closest available simulator destination.
- [x] 13.4 Run formatting/linting if the repository has a standard command. No SwiftLint/SwiftFormat command or config was found.
- [x] 13.5 Update this task list honestly with completed and deferred items.

## 14. Cleanup / Commit

- [x] 14.1 Review changed files and verify no unrelated/generated/user-specific files are included.
- [x] 14.2 Commit with `Implement alarm delivery schedule reliability contract`.
- [x] 14.3 Push the feature branch if credentials and normal workflow permit.
