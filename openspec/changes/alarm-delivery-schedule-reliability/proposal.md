## Why

Morning resolution now owns what should exist for a Subh morning: day meaning, user intention, wake boundary, wake time, alarm activation, copy state, and resolver-materialized events. The next reliability gap is proving whether those resolved events are actually deliverable by iOS without rewriting the morning when permissions, platform availability, pending requests, or cache state drift.

This change is needed because a correct Fajr/Fast/Tahajjud wake plan can still fail trust if delivery is permission-blocked, stale, missing, duplicated, scheduled through the wrong channel, or only notification-backed while the UI implies stronger AlarmKit behavior.

## What Changes

- Add a durable `alarm-delivery-reliability` capability for the downstream delivery contract.
- Establish explicit separation between morning intent, alarm activation, delivery mode, platform permission, pending platform state, verification result, and completion/religious meaning.
- Reuse the existing morning-resolution pipeline, `ScheduledEvent`s, `ResolvedMorningWakeState`, identifier helpers, scheduler adapters, reconciliation report, and local ledger rather than adding a parallel wake engine.
- Tighten delivery planning so schedulers consume resolver-materialized events only.
- Make delivery modes explicit, including `none`, `notifications`, `alarmKit`, and `mixed` where wake alarms and secondary cues use different channels.
- Model notification permission, AlarmKit availability/authorization, and combined readiness separately from wake intent.
- Canonicalize expected delivery identifiers so scheduling, cancellation, reconciliation, stale cleanup, and ledger code agree.
- Treat schedule transactions as idempotent: build expected deliveries, cancel current/legacy stale deliveries in scope, schedule selected channels, query pending state, reconcile, ledger, and report status.
- Extend reconciliation categories for matched, missing expected, fire-date mismatch, unexpected extra, duplicate, permission blocked, platform unavailable, scheduling failed, verification unavailable, and skipped past events.
- Ensure cache reuse still runs pending-state reconciliation.
- Expand lifecycle refresh vocabulary for permission changes, time/timezone changes, location/settings changes, date-specific wake edits, Quiet/Fajr/Fast/Tahajjud mode changes, observance plan changes, horizon rollover, and identifier migration.
- Keep user-facing surfaces compact: Home and detail can show concise warnings, but weekly forecast and Next 10 remain presentation adapters, not diagnostics screens.

This change does not own Fajr/Maghrib/final-third calculation, Ramadan/Qada/Tahajjud/fast intention resolution, wake-time selection, Morning Hero layout, Alarm Detail layout, Weekly Fajrcast geometry, Next 10 tag doctrine, completion credit, remote telemetry, or push-notification infrastructure.

## Capabilities

### New Capabilities

- `alarm-delivery-reliability`: Defines how resolver-materialized Subh events become platform deliveries, how expected and pending platform state are reconciled, how stale deliveries are cancelled, how local diagnostics are recorded, and how delivery status flows back without altering morning intent.

### Modified Capabilities

- `morning-resolution`: Delivery status feedback remains downstream of morning resolution; this change clarifies that delivery failure or degraded fallback must not rewrite wake mode, day purpose, alarm activation, boundary, wake time, or completion credit.

## Impact

- Affected code areas include:
  - `Subh/Core/Morning/Models/ResolvedMorningWakeState.swift`
  - `Subh/Core/Morning/Models/MorningSchedulingModels.swift`
  - `Subh/Core/Services/ScheduleService.swift`
  - `Subh/Core/Services/SchedulingReconciler.swift`
  - `Subh/Core/Services/AlarmScheduler.swift`
  - `Subh/Core/Services/RoutineScheduler.swift`
  - `Subh/Core/Services/NotificationScheduler.swift`
  - `Subh/Core/Services/AlarmKitScheduler.swift`
  - `Subh/Core/Services/AlarmKitScheduling.swift`
  - `Subh/Core/Services/DeliveryReconciliationReport.swift`
  - `Subh/Core/Services/AlarmDeliveryLedgerStore.swift`
  - `Subh/Core/Scheduling/SchedulingIdentifiers.swift`
  - `Subh/Core/Scheduling/SchedulingIdentifierSet.swift`
  - `Subh/App/SubhApp.swift`
  - settings and permissions reliability surfaces that show compact delivery status
  - XCTest coverage for scheduling, reconciliation, ledger, lifecycle refresh, permission handling, and static SwiftUI guardrails
- Existing scheduled alarms are affected through resolver-driven reconciliation and broader scoped stale cancellation. Current and known legacy identifiers may be cancelled and recreated when the app refreshes schedule state.
- Existing schedule caches may still be reused for calculation, but reuse must not skip delivery reconciliation.
- Persisted user wake settings and date-specific morning intent should remain compatible. Ledger shape may evolve locally, but no remote telemetry or raw location storage is introduced.
- No new production dependency is expected.
