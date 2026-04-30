## Context

Subh already resolves the default wake time correctly through the morning engine: active daily, anchored to supported Fajr end, 30 minutes before the boundary. The weak point was delivery integrity after resolution. `ScheduleManager` could reuse a cached window on app launch or foreground without rechecking pending platform deliveries; per-day rescheduling could miss stale legacy identifiers when the prior in-memory plan was empty; diagnostics only detected some empty-delivery failures.

The affected code spans app lifecycle handling, scheduling adapters, diagnostics, local persistence, and settings export:
- `Subh/App/SubhApp.swift`
- `Subh/Core/Scheduling/SchedulingIdentifierSet.swift`
- `Subh/Core/Services/ScheduleService.swift`
- `Subh/Core/Services/ScheduleRefreshCoordinator.swift`
- `Subh/Core/Services/AlarmScheduler.swift`
- `Subh/Core/Services/RoutineScheduler.swift`
- `Subh/Core/Services/NotificationScheduler.swift`
- `Subh/Core/Services/AlarmKitScheduling.swift`
- `Subh/Core/Services/AlarmKitScheduler.swift`
- `Subh/Core/Services/DeliveryReconciliationReport.swift`
- `Subh/Core/Services/AlarmDeliveryLedgerStore.swift`
- `Subh/Features/Settings/PermissionsReliabilityView.swift`
- `Subh/Features/Settings/SettingsRootView.swift`
- `SubhTests/ScheduleServiceExtractionTests.swift`

## Goals / Non-Goals

**Goals:**
- Keep the resolver-materialized `ScheduledEvent` list as the source used by notifications, AlarmKit, schedule rows, and diagnostics.
- Reconcile platform deliveries whenever lifecycle events make the current delivery state suspect, even if schedule-window calculation can be reused.
- Cancel stale current and legacy identifiers before unknown-day rescheduling.
- Verify pending notification and AlarmKit state against every expected delivery, not only against the zero-delivery case.
- Persist local-only scheduling and cancellation ledger entries for user support and release diagnostics without analytics or raw location.
- Force refresh and reconciliation after significant time and timezone changes.

**Non-Goals:**
- Do not change the default wake rule.
- Do not add app-level snooze or imply snooze behavior.
- Do not add remote telemetry, analytics, sync, or raw location logging.
- Do not create another wake engine or parallel alarm-time calculation path.

## Decisions

1. Centralize identifier expansion in `SchedulingIdentifierSet`.
   - Rationale: cancellation, scheduling diagnostics, and tests must agree on the full set of current event IDs, current daily IDs, legacy dot IDs, and legacy V1 IDs.
   - Alternative considered: keep identifier expansion inside each scheduler. That preserves local coupling but makes stale cancellation and diagnostics easier to drift.

2. Reconcile cached windows through the existing scheduling reconciler.
   - Rationale: cache reuse is acceptable for calculation cost, but platform delivery state is external mutable state and must be reasserted on launch/foreground.
   - Alternative considered: disable schedule cache reuse on launch/foreground. That is simpler but does unnecessary date calculation and still leaves the conceptual bug that cache reuse and delivery verification are coupled.

3. Treat unknown prior day state as stale-risky.
   - Rationale: if the app does not know what it previously scheduled for a date, the safest behavior is to cancel every possible identifier for that date before scheduling the resolved event list.
   - Alternative considered: cancel only current event IDs. That leaves migrated/legacy pending requests behind.

4. Model delivery verification separately from scheduling side effects.
   - Rationale: `DeliveryReconciliationReport` is testable without device APIs and can compare expected deliveries against pending notification requests or AlarmKit alarms.
   - Alternative considered: rely on logs from scheduler calls. That proves requests were submitted, not that the platform still has the expected pending state.

5. Keep the ledger local and minimal.
   - Rationale: location, observance state, and alarm history are sensitive. `AlarmDeliveryLedgerStore` records scheduling decisions and outcomes in local defaults only, capped to recent entries.
   - Alternative considered: analytics events. That would weaken privacy for a support/debugging need that can be handled locally.

## Risks / Trade-offs

- [Risk] The simulator notification center can show transient mismatches during highly concurrent tests. -> Mitigation: reconciliation is deterministic and unit-tested with fake pending deliveries; full tests passed despite expected simulator churn.
- [Risk] AlarmKit state inspection is limited by platform availability. -> Mitigation: the scheduler exposes a state-inspection protocol and gracefully returns no AlarmKit deliveries where unavailable.
- [Risk] Broader stale cancellation can remove identifiers that share old naming shapes. -> Mitigation: identifier sets are scoped by schedule date and known Subh identifier formats.
- [Risk] Ledger entries could grow over time. -> Mitigation: the store caps entries and avoids raw location or remote export.

## Migration Plan

No persisted user wake settings are migrated. Existing pending deliveries are corrected opportunistically on app launch, foreground, significant time change, timezone change, schedule refresh, and per-day rescheduling. Rollback is code-level: remove reconciliation and ledger use while preserving the default wake rule.

## Open Questions

- Device-specific April 30 root cause still requires device evidence: delivery mode, pending alarm state, Focus/DND state, permissions, battery optimization, and whether another app interfered.
- App-level snooze remains intentionally out of scope until a separate AlarmKit-backed snooze/countdown design exists.
