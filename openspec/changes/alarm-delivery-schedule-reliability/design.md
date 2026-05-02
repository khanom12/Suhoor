## Context

The current repo already contains several delivery-layer anchors from completed incident-focused work:

- `Subh/Core/Morning/Models/MorningSchedulingModels.swift` defines resolver-materialized `ScheduledEvent`s, event types, delivery kinds, sound roles, wake-session roles, and Fajr-start behavior.
- `Subh/Core/Morning/Models/ResolvedMorningWakeState.swift` defines `AlarmActivation` and `MorningWakeScheduleStatus`, which the previous morning-resolution contract tightened so permission-blocked delivery does not become Quiet.
- `Subh/Core/Services/ScheduleService.swift` owns schedule refresh, cached-window reconciliation, permission summaries, lifecycle-triggered refresh requests, diagnostics, and ledger writes.
- `Subh/Core/Services/SchedulingReconciler.swift` currently chooses `.none`, `.notifications`, or `.alarmKit` and calls `AlarmScheduler`.
- `Subh/Core/Services/AlarmScheduler.swift` diffs resolver-materialized events against an in-memory plan and calls `RoutineScheduler`.
- `Subh/Core/Services/RoutineScheduler.swift` routes individual events to AlarmKit or UserNotifications and cancels current/legacy identifiers.
- `Subh/Core/Services/NotificationScheduler.swift` schedules and queries pending local notifications.
- `Subh/Core/Services/AlarmKitScheduler.swift`, `AlarmKitScheduling.swift`, `AlarmScheduling.swift`, and `AlarmCoordinator.swift` wrap AlarmKit scheduling, cancellation, and limited pending-state inspection.
- `Subh/Core/Scheduling/SchedulingIdentifiers.swift` and `SchedulingIdentifierSet.swift` centralize most current and legacy identifiers.
- `Subh/Core/Services/DeliveryReconciliationReport.swift` already models expected deliveries and compares pending notifications/alarms for missing and mismatched state.
- `Subh/Core/Services/AlarmDeliveryLedgerStore.swift` stores local-only schedule, cancellation, and reconciliation entries.
- `Subh/App/SubhApp.swift` triggers refresh on launch, foreground, settings change, location change, significant time change, and timezone change.
- Tests in `SubhTests/ScheduleServiceExtractionTests.swift`, `SubhTests/ScheduleManagerHijriTests.swift`, and `SubhTests/AlarmConfigMigrationTests.swift` cover schedule cache reuse, stale cancellation, diagnostics, permission-blocked status, and SwiftUI ownership guardrails.

The previous morning-resolution implementation created or reused the right upstream ownership: `ResolvedDaySnapshot`/`ActiveAlarmDay` materializes scheduled events, `ResolvedMorningWakeState` distinguishes activation from schedule status, `DailyAlarmOverride` preserves Quiet overlay semantics, and SwiftUI views are guarded from direct scheduling or boundary calculation. This delivery change starts after those events exist.

Completed OpenSpec changes `alarm-integrity-audit-and-hardening` and `harden-alarm-pipeline-diagnostics` remain valuable but narrower. This change turns their incident fixes into a durable capability contract and avoids duplicating their code.

## Goals / Non-Goals

**Goals:**

- Reuse `ScheduledEvent`, `ResolvedMorningWakeState`, `SchedulingIdentifierSet`, scheduler adapters, `DeliveryReconciliationReport`, and `AlarmDeliveryLedgerStore`.
- Introduce or adapt explicit delivery planning concepts without creating another morning resolver.
- Add delivery mode semantics for `none`, `notifications`, `alarmKit`, and `mixed`.
- Keep permission and platform availability state separate from wake intent and alarm activation.
- Make expected deliveries deterministic, channel-aware, and shared by scheduling, cancellation, reconciliation, and ledger code.
- Make schedule transactions idempotent and scoped: cancel current/legacy stale identifiers, schedule expected future deliveries, query pending state, reconcile, ledger, and report.
- Detect missing, mismatched, unexpected extra, duplicate, blocked, unavailable, failed, verification-limited, matched, and skipped-past states.
- Ensure cached schedule-window reuse still verifies pending platform state.
- Expand refresh reasons for permission changes, calculation/observance changes, date-specific wake edits, horizon rollover, and identifier migration.
- Keep user-facing surfaces compact and downstream of resolved status.
- Add deterministic XCTest coverage and a manual physical-device QA checklist for AlarmKit/audible delivery confidence.

**Non-Goals:**

- No prayer-window, Fajr-end, Maghrib, final-third, Ramadan, Qada, Tahajjud, fast-intention, or completion-credit calculation in delivery code.
- No visual redesign of Home Hero, Alarm Detail, Weekly Fajrcast, Next 10, or Settings.
- No app-level snooze UX beyond platform-provided AlarmKit behavior.
- No push-notification infrastructure.
- No remote telemetry, cloud diagnostics, raw location storage, or religious analytics.
- No migration that changes user wake defaults or date-specific morning intent.

## Decisions

### Decision: Add a small delivery-planning model around existing events

Create a model equivalent to `DeliveryPlan`, `PlannedDelivery`, `DeliveryPermissionSnapshot`, and explicit delivery modes/categories near the existing delivery services. The plan is derived from resolver-materialized `ScheduledEvent`s and current permissions only.

Rationale: `DeliveryReconciliation.expectedDeliveries` already computes expected deliveries, but planning and scheduling still depend on scattered `SchedulingMode` and `canUseAlarmKit` booleans. A delivery plan makes channel selection, skipped-past events, permission blocking, mixed mode, and diagnostics explicit without changing the upstream morning graph.

Alternative considered: keep enriching `SchedulingMode` alone. That would be less churn, but it cannot cleanly express mixed delivery or verification-limited/permission-blocked transaction details.

### Decision: Extend, do not replace, existing scheduling adapters

`AlarmScheduler`, `RoutineScheduler`, `NotificationScheduler`, `AlarmKitScheduler`, and `AlarmCoordinator` should remain the platform handoff path. The change should add plan-aware helpers and tests around them, not a parallel platform scheduler.

Rationale: the existing adapters already handle availability guards, AlarmKit fallback, local notification scheduling, sound role handoff, and stale cancellation. Replacing them would increase risk in the most trust-sensitive area.

Alternative considered: build a new `DeliveryTransactionRunner` that bypasses `AlarmScheduler`. That would be cleaner on paper but would duplicate cancellation and adapter behavior.

### Decision: Keep identifiers canonical and channel-aware

Add channel-aware expected identifiers while preserving current and known legacy forms. `SchedulingIdentifiers` and `SchedulingIdentifierSet` remain the single source for current notification identifiers, AlarmKit UUIDs, legacy daily identifiers, and stale cancellation scopes.

Rationale: individual adapters and views must not generate identifiers. The same identifier expansion must be used by scheduling, cancellation, reconciliation, and ledger code.

Alternative considered: keep event ID plus delivery kind as the only plan ID. That is stable for many cases, but channel-aware planning is clearer when a notification fallback and AlarmKit route differ.

### Decision: Treat reconciliation as categorical, not just boolean

Extend reconciliation output to include explicit categories for matched, missing expected, fire-date mismatch, unexpected extra, duplicate, permission blocked, platform unavailable, scheduling failed, verification unavailable, and skipped past. Existing summary strings can remain compact.

Rationale: support/debugging needs to know whether a delivery was never expected, could not be scheduled, disappeared from pending state, exists at the wrong time, or cannot be verified on the current platform.

Alternative considered: continue using missing/mismatch arrays only. That is enough for a few tests but not enough to represent AlarmKit verification limits or unexpected stale extras honestly.

### Decision: Delivery status maps back without changing intent

`ScheduleService` and `MorningWakeResolutionService` should keep using `scheduleStatusOverride`/delivery status as downstream feedback only. Active intent plus permission-blocked delivery remains active. Quiet remains resolver-owned suppression.

Rationale: this matches the morning-resolution contract and avoids converting platform failure into a religious/product state.

Alternative considered: set scheduling mode to `.none` for permission-blocked active mornings and let surfaces infer off/no alarm. That is misleading and violates the product trust rule.

### Decision: Ledger remains local and minimal

Keep `AlarmDeliveryLedgerStore` local-only. Record transaction-level counts, trigger reason, scope, mode, permission snapshot, adapter result, and identifiers only at a non-sensitive level already used by scheduling.

Rationale: alarm history, observance state, and location context are sensitive. Local support data is enough for this foundation.

Alternative considered: add analytics events. That is out of scope and weakens privacy without a concrete product need.

### Decision: Physical-device QA is documented, simulator tests stay deterministic

Simulator tests will prove planning, channel selection, cancellation, reconciliation, ledger shape, cache reuse, and static ownership. Physical-device QA remains required for actual AlarmKit authorization, audible behavior, Focus/silent mode behavior, and real pending state.

Rationale: simulator cannot prove wake reliability. The code must be honest about platform limits.

Alternative considered: treat passing simulator tests as full delivery confidence. That would overclaim reliability.

## Risks / Trade-offs

- [Risk] Adding explicit delivery planning around existing scheduler code could duplicate expected-delivery calculations. -> Mitigation: make the plan feed `DeliveryReconciliation` and scheduler tests, and reuse identifier helpers.
- [Risk] Mixed mode changes may affect existing status copy. -> Mitigation: keep user-facing warnings compact and add regression tests for permission-blocked active intent.
- [Risk] AlarmKit pending-state verification may be unavailable or limited on simulator and some platform states. -> Mitigation: represent verification as unavailable/limited instead of matched success.
- [Risk] Broader stale cancellation can remove stale-looking identifiers that share legacy shapes. -> Mitigation: scope cancellation by date/horizon and use known Subh identifier formats only.
- [Risk] Ledger entries can become noisy. -> Mitigation: cap entries, record summaries, and avoid raw location or religious analytics.

## Migration Plan

No user wake settings are migrated. Existing pending current and known legacy deliveries are repaired opportunistically on app launch, foreground, permission/settings/location/time/timezone changes, date-specific override changes, schedule horizon rollover, and identifier migration refresh.

If rollback is needed, the app can keep the existing resolver and scheduler behavior while ignoring newly added delivery-plan fields and richer reconciliation categories. Local ledger entries may remain readable as diagnostics or be safely ignored.

## Rollout Order

1. Validate the OpenSpec change before implementation.
2. Add/extend delivery planning and status models with compatibility defaults.
3. Route scheduler/reconciliation through the plan while preserving existing adapters.
4. Tighten identifier generation and stale cancellation tests.
5. Add reconciliation categories, pending-extra/duplicate detection, skipped-past behavior, and verification-limited AlarmKit handling.
6. Update ledger summaries and status mapping.
7. Expand refresh reason coverage and static SwiftUI guardrails.
8. Run focused delivery tests, affected morning-resolution regression tests, OpenSpec validation, and the documented Xcode build/test command where available.
