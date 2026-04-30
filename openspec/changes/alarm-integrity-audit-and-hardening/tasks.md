## 1. Identifier And Scheduling Integrity

- [x] 1.1 Add a shared scheduling identifier set for current, daily, legacy dot, legacy V1, notification, and AlarmKit IDs.
- [x] 1.2 Update notification and AlarmKit cancellation paths to use the shared identifier set.
- [x] 1.3 Make unknown-day rescheduling cancel all possible identifiers for that date before scheduling resolved events.
- [x] 1.4 Keep single-event cancellation scoped to that event so unchanged sibling events are not cancelled.

## 2. Lifecycle Reconciliation

- [x] 2.1 Reconcile platform deliveries on app launch when the cached schedule window is reused.
- [x] 2.2 Reconcile platform deliveries on foreground refresh when the cached schedule window is reused.
- [x] 2.3 Add significant time-change refresh handling.
- [x] 2.4 Add timezone-change refresh handling.

## 3. Delivery Verification And Ledger

- [x] 3.1 Add delivery reconciliation models for expected deliveries, pending notifications, scheduled AlarmKit alarms, and report summaries.
- [x] 3.2 Compare all expected notification pending IDs and fire dates after scheduling.
- [x] 3.3 Compare available AlarmKit scheduled alarm IDs and fire dates after scheduling.
- [x] 3.4 Add local-only delivery ledger entries for scheduling, cancellation, permission mode, lifecycle reason, wake-rule signature, and result.
- [x] 3.5 Keep notification fallback classified as degraded delivery and leave app-level snooze disabled.

## 4. Diagnostics And Settings

- [x] 4.1 Add delivery reconciliation status to reliability settings.
- [x] 4.2 Include delivery reconciliation and ledger summaries in settings diagnostics/export.
- [x] 4.3 Log delivery mismatch warnings when expected delivery state diverges from pending platform state.

## 5. Verification

- [x] 5.1 Add a unit test proving the default daily wake remains supported Fajr end minus 30 minutes.
- [x] 5.2 Add unit coverage that cache reuse still requires delivery reconciliation on lifecycle refresh.
- [x] 5.3 Add unit coverage for stale-safe current and legacy identifier cancellation.
- [x] 5.4 Add unit coverage for missing pending notification detection when some deliveries remain.
- [x] 5.5 Add unit coverage for AlarmKit fire-date mismatch detection.
- [x] 5.6 Add unit coverage that time and timezone changes reject schedule cache reuse.
- [x] 5.7 Run focused scheduling tests and the full `SubhTests` unit target.
