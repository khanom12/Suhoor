## Context

Subh already has:

- `TimeProviding` implementations in `Subh/Core/Utilities/TimeProvider.swift`.
- A core Wake Session store/planner in `Subh/Core/Morning/WakeSessionStore.swift`.
- A v1 debug harness in `Subh/Core/Morning/WakeSessionTestingHarness.swift`.
- A debug-only lab view in `Subh/Features/Settings/WakeSessionLabView.swift`.
- `ScheduleManager.currentMorningHomeSnapshot` and `buildMorningHomeSnapshot(...)` as the Home data source in `Subh/Core/Services/ScheduleService.swift`.
- The actual Home surface in `Subh/Features/Home/SubhHomeView.swift`, which renders `MorningHomeSnapshot`.
- Production scheduling through `AlarmScheduler`, `RoutineScheduler`, `AlarmKitScheduler`, `NotificationScheduler`, `SchedulingIdentifiers`, and `AlarmDeliveryLedgerStore`.

The v1 harness intentionally used compressed one-minute Wake Checks for fast lab testing. The v2 spec supersedes that behavior for mapped playback and general State Explorer semantics: state jumps may be instant, but any scheduled or mapped Wake Check sequence must use the production five-minute interval and up to five Wake Checks.

The implementation must preserve Subh's one morning engine. Simulation creates test-scoped inputs and snapshots around the existing resolver/Wake Session/Home path; it must not create a fake Home screen, fake Hero, public production controls, paid feature, StoreKit path, adaptive Wake Check system, analytics layer, or second wake engine.

## Goals / Non-Goals

**Goals:**

- Promote `subh-wake-session-testing-and-simulation-harness-spec-v2.md` into the active docs and archive v1 as superseded.
- Add an app-wide active simulation context with simulation ID, test marker, run mode, clock mode, simulated date/time/time zone/location, prayer-window source, simulated prayer window, Wake Session, mapping plan, and created-at real date.
- Extend the existing harness into State Explorer, Home Simulation Mode, fake scheduler playback, dry run, permission/failure simulation, inspectors, and real AlarmKit mapped playback.
- Make Home consume an active simulation snapshot through `ScheduleManager.currentMorningHomeSnapshot`, so the real Home/Morning Hero UI renders simulated state.
- Add a Home simulation overlay/dock that shows `TEST MODE ACTIVE`, simulated date/time/location/scenario/run mode/jump point, mapped alarm countdown when applicable, and safety actions.
- Add mapped playback planning that maps simulated primary/wake-check events to real near-future AlarmKit fire dates while preserving five-minute deltas and sequence length choices from primary-only through primary plus five Wake Checks.
- Evaluate Fajr/Suhoor cutoff rules in simulated time before mapping real AlarmKit times.
- Add unit/integration tests for simulation context activation, five-minute Wake Check math, mapping plans, cutoff filtering, fake scheduler records, test-data isolation, Home snapshot switching, and release guardrails.

**Non-Goals:**

- No production wake-rule changes.
- No one-minute or two-minute scheduled/mapped Wake Check intervals.
- No public production access to Wake Session Lab, State Explorer, Home Simulation, fake time controls, artificial prayer-window controls, mapped playback, or simulated alarm buttons.
- No StoreKit, paywalls, paid analytics, long-term history, Qada, export/sync, cloud sync, family accountability, adaptive Wake Checks, advanced Wake Check personalization, or new public feature surfaces.
- No mutation of real location, prayer calculation method, Hijri adjustment, default wake settings, real plans, entitlement, production MorningLogs, or worship history.
- No direct SwiftUI scheduling/cancelling of platform alarms.

## Decisions

### Decision: Extend the existing harness instead of adding a parallel lab engine

`WakeSessionTestingHarness` will be extended with v2 models rather than replaced by a second implementation. It will own internal simulation state, derive test IDs, create test Wake Sessions through `WakeSessionStore`, and drive scheduling through fake or AlarmKit seams.

Alternative considered: create a separate `HomeSimulationEngine`. That would risk testing a toy product model rather than Subh's existing morning engine.

### Decision: Add an `ActiveSimulationContext` and active snapshot override in `ScheduleManager`

`ScheduleManager` will expose a debug/internal simulation context and, when active, set `currentMorningHomeSnapshot` to a simulated snapshot built from the context. When inactive, the existing real snapshot builder remains unchanged. This preserves the actual `SubhHomeView` and `MorningHero` path.

Alternative considered: make `SubhHomeView` branch into a fake simulation screen. That is forbidden by the spec and would not test the production Home UI.

### Decision: Use the existing `TimeProviding` seam and add v2 naming aliases

`SystemTimeProvider` remains production real time. `MutableTimeProvider` remains the test clock. Lightweight aliases or wrappers such as `RealSubhClock` / `TestSubhClock` may be added for spec language clarity without changing production behavior.

Alternative considered: globally override `Date()` or make all views read a global clock. That would be risky and unnecessary; domain decisions should use injected providers and snapshots.

### Decision: Build simulation snapshots from test-scoped `ActiveAlarmDay` data

The harness will create or derive a simulated `ActiveAlarmDay` / `MorningHomeSnapshot` using real model types and the same `WakeRowActionResolver` / `MorningHomeSnapshot` flow where practical. Scenario state and jump points update the simulated time, Wake Session status, and MorningLog test records; Home then renders the updated snapshot.

Alternative considered: manually construct Hero copy in the overlay. The overlay may display test metadata, but the Hero itself must continue to render from `MorningHomeSnapshot`.

### Decision: Preserve five-minute Wake Checks for v2 scheduling and mapped playback

V2 State Explorer can jump instantly between named states. Fake scheduler playback and real mapped playback will use `WakeSessionPlanner.WakeCheckConfiguration.production`, not compressed one-minute configuration. Mapped playback can move the primary alarm to real now plus a 60-120 second start delay, but later wake checks stay five real minutes apart.

Alternative considered: keep v1 compressed Wake Checks for convenience. The v2 spec explicitly supersedes that behavior because physical-device QA must match production spacing.

### Decision: Add a mapping plan separate from scheduled-event identity

The mapped playback builder will produce an `AlarmKitMappingPlan` / mapped test alarm records containing simulated fire date and mapped real fire date. The fake scheduler records both. The production AlarmKit adapter receives near-future real fire dates only after the tester confirms scheduling.

Alternative considered: mutate the simulated `ScheduledEvent.fireDate` in place without retaining simulated dates. That loses the audit trail needed by the overlay and pending-alarm inspector.

### Decision: Keep visible controls compile-time guarded

The Settings lab entry point, State Explorer, Home overlay/dock controls, fake scheduler controls, and mapped playback confirmation UI remain behind `#if DEBUG || INTERNAL_TESTING` or equivalent. Safe test-support models may compile in release, but routes and UI controls must not be visible or routeable.

Alternative considered: runtime hiding only. Runtime gating is useful for internal builds, but compile-time guards are stronger for App Store safety.

## Risks / Trade-offs

- [Risk] Full real-prayer State Explorer for arbitrary location/date may require broader resolver wiring than a single pass can safely refactor. -> Mitigation: use existing resolver/snapshot paths where available, add deterministic test presets/custom windows where needed, and keep artificial windows debug-only.
- [Risk] Home simulation may accidentally mutate real settings if implemented through real stores. -> Mitigation: context activation writes only test-scoped Wake Sessions/MorningLogs and snapshot state; it must not persist settings, plans, location, Hijri adjustment, or entitlement changes.
- [Risk] Real AlarmKit behavior cannot be fully validated in simulator/CI. -> Mitigation: tests verify mapping plan generation and guarded scheduling paths; final summary includes physical-device QA steps for Omar.
- [Risk] V1 tests or scenarios may assume compressed one-minute Wake Checks. -> Mitigation: update harness/tests to the v2 rule: instant jumps for exploration, five-minute intervals for scheduled/mapped sequences.
- [Risk] Debug UI could leak into production. -> Mitigation: compile-time guards, release build validation, and source/build guardrail tests where practical.

## Migration Plan

- Promote v2 docs and archive v1 as superseded. No user data migration is needed.
- Add optional test-only fields with safe decode defaults when extending persisted test records.
- Update existing v1 harness scenarios to v2 spacing and context semantics.
- Test cleanup cancels only namespaced test alarms and clears only `isTest` records.
- Rollback can remove/ignore active simulation context and test-scoped records; production Home and scheduling do not depend on them.

## Open Questions

- Whether an `INTERNAL_TESTING` build configuration is already defined for internal TestFlight distribution or should remain a future build-setting addition.
- How much of real arbitrary-location selection should be wired in this pass versus using current app location plus safe test presets.
- Which AlarmKit callbacks are available on Omar's physical device/OS for detecting fired/stopped events; the harness can simulate records and schedule mapped alarms, but final Lock Screen behavior still requires manual device QA.
