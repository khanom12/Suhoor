## Why

The April 30, 2026 alarm incident exposed a trust-risk in delivery integrity: the default wake calculation was correct, but cached app lifecycle refreshes and stale platform identifiers could allow expected alarms to be missing, late, or unverifiable. Alarm reliability is core product behavior, so schedule reuse must never bypass delivery reconciliation.

## What Changes

- Keep `MorningScheduleResolver` as the authoritative source for wake times by scheduling platform deliveries from resolved `ScheduledEvent`s.
- Reconcile platform notification and AlarmKit delivery state on app launch and foreground refresh, even when the schedule window cache is reused.
- Make stale cancellation per-day safe by cancelling every current and legacy notification and AlarmKit identifier for a date when no prior in-memory plan is known.
- Add a shared identifier set so scheduling, cancellation, diagnostics, and tests use the same identifier universe.
- Verify expected-vs-pending delivery state after scheduling for notifications and AlarmKit.
- Add a local-only alarm delivery ledger for scheduling and cancellation decisions without analytics or raw location.
- Surface delivery reconciliation and ledger summaries in settings diagnostics/export.
- Force schedule refresh and delivery reconciliation for significant time and timezone changes.

## Capabilities

### New Capabilities
- `alarm-delivery-integrity`: Covers platform delivery reconciliation, stale identifier cancellation, local delivery ledgering, and lifecycle/time-change handling for resolved morning wake events.

### Modified Capabilities
- `fajr-end-mvp-wake`: Confirms the existing default wake requirement remains Fajr end minus 30 minutes and requires delivery hardening to consume resolver-materialized events instead of recomputing wake time.

## Impact

- Affected code: `ScheduleManager`, `AlarmScheduler`, `RoutineScheduler`, `NotificationScheduler`, `AlarmKitScheduler`, scheduling identifiers, settings diagnostics, app lifecycle hooks, and unit tests.
- User-visible impact: settings diagnostics now report delivery verification state and local ledger summary; alarms are reasserted on launch/foreground and after significant time changes.
- Existing scheduled alarms: stale current and legacy identifiers are cancelled more completely before rescheduling unknown days.
- Persisted settings: no user wake settings, location, or raw schedule history are migrated or synced.
- Dependencies/APIs: no external services, analytics, or user-data sync changes.
