## Context

Subh already has one Fajr-centered morning engine, deterministic Wake Sessions, core Wake Checks, local MorningLogs, Quiet active-session cancellation, and AlarmKit/notification scheduling adapters. The missing piece is an internal way to compress Fajr/Suhoor timing and exercise those real seams on a developer iPhone without waiting for real mornings.

This change is constrained by the active specs: debug-only, no StoreKit or paid features, no adaptive wake-check personalization, no long-term analytics, no production exposure, and no second wake engine. The harness must fake the world around Subh: time, prayer windows, scheduler outcomes, permissions, and alarm events. The real Wake Session store, planner, confirmation semantics, scheduling identifiers, and Home/Hero state must remain the source of truth.

Likely affected implementation anchors:

- `Subh/Core/Utilities/TimeProvider.swift`
- `Subh/Core/Morning/WakeSessionStore.swift`
- `Subh/Core/Morning/WakeSessionTestingHarness.swift` or equivalent new internal domain file
- `Subh/Core/Services/AlarmScheduler.swift`
- `Subh/Core/Services/RoutineScheduler.swift`
- `Subh/Core/Scheduling/SchedulingIdentifiers.swift`
- `Subh/Core/Services/DeliveryReconciliationReport.swift`
- `Subh/Core/Services/ScheduleService.swift`
- `Subh/Features/Settings/SettingsRootView.swift`
- `Subh/Features/Settings/WakeSessionLabView.swift`
- `SubhTests/WakeSessionTestingHarnessTests.swift` or targeted additions to `ScheduleServiceExtractionTests.swift`

## Goals / Non-Goals

**Goals:**

- Add injectable clock support for harness and deterministic tests while preserving production `Date()` behavior where unchanged.
- Add compressed Fajr and Suhoor scenario creation that feeds the existing Wake Session planner/store rather than inventing a separate morning engine.
- Add a fake scheduler adapter that records scheduled, cancelled, pending, fired, failed, and permission-blocked test alarm records through the same scheduling abstraction used by production code.
- Add a debug-only Wake Session Lab under Settings > Developer with scenario launchers, test status, pending alarm inspector, MorningLog inspector, and cleanup/safety actions.
- Add explicit support for a real AlarmKit compressed physical-device test using near-future real device fire dates.
- Mark test sessions/logs/alarm IDs as test-scoped and provide clear cleanup that cannot delete real user logs/settings.
- Add tests for compressed scenario math, awake/prayer/fasting separation, Quiet behavior, permission failure distinction, scheduler records, reschedule cleanup, release guardrails where feasible, and test-data isolation.

**Non-Goals:**

- No production wake-rule changes.
- No public test controls or release-build Wake Session Lab.
- No paid features, StoreKit, entitlement enforcement changes, analytics, export/sync, Qada, durable history UI, or adaptive wake checks.
- No direct SwiftUI scheduling or cancellation of AlarmKit alarms.
- No system clock changes.

## Decisions

### Decision: Add a debug harness coordinator around existing stores and planners

Create a `WakeSessionTestingHarness` model/coordinator that owns test-only scenario state, uses the existing `WakeSessionStore`, derives deterministic test IDs, and records scheduler/test log state. Views invoke coordinator methods; they do not schedule/cancel platform alarms directly.

Alternative considered: put scenario code directly in `WakeSessionLabView`. That would place business rules in SwiftUI and make scenario behavior difficult to test.

### Decision: Extend the clock seam instead of replacing production time

Keep `SystemTimeProvider` as production default and add mutable/fixed test clock support for harness code and tests. Production code remains on real time unless it is explicitly passed an injected provider.

Alternative considered: globally override `Date()`. Swift does not support that safely, and it would risk hidden production behavior changes.

### Decision: Use test scenario windows as inputs to the real Wake Session path

Compressed Fajr and Suhoor scenarios construct a resolved test morning graph with real `WakeSessionDraft`, primary alarm, wake-check events, and mode-specific cutoffs. Test-only configuration permits one-minute intervals and compressed cutoffs; production `WakeSessionPlanner` defaults remain five checks at five-minute intervals.

Alternative considered: create a separate fake session model. That would test a toy version of Subh rather than the real morning execution model.

### Decision: Add fake scheduling through the existing scheduling abstraction

The fake scheduler records schedule/cancel requests, permission failures, pending alarms, and stale IDs. It should be injectable anywhere a scheduler abstraction is accepted, and real AlarmKit is used only by the explicit compressed real-device scenario.

Alternative considered: let the lab mutate a standalone array unrelated to scheduling. That would not prove identifier reconciliation or stale cancellation behavior.

### Decision: Compile out visible lab UI in release builds

The Settings > Developer entry point and lab views are wrapped in `#if DEBUG || INTERNAL_TESTING`. Test-support types that are safe to compile may remain, but production must not register routes, show lab labels, or expose fake controls.

Alternative considered: runtime-only hiding. Runtime hiding is useful for internal TestFlight, but compile-time protection is stronger for App Store safety.

### Decision: Keep test data namespaced and locally clearable

Test Wake Sessions, MorningLogs, and scheduled IDs receive `isTest` or equivalent test metadata plus `test.wakeSession...` identifiers. Cleanup actions remove only test-scoped records and cancel only test-scoped alarms.

Alternative considered: reuse real records and delete by recent timestamp. That can corrupt real user history and is too risky for a private/religious domain.

## Risks / Trade-offs

- [Risk] Not every production path currently accepts an injected time provider. -> Mitigation: add narrow injection points around harness/test code first and leave broader production refactors out unless required by tests.
- [Risk] Real AlarmKit behavior cannot be fully validated in CI. -> Mitigation: keep real compressed AlarmKit behind an explicit debug button and document a physical-device QA checklist.
- [Risk] Test fields added to persisted models may be forward-only. -> Mitigation: provide default decoding values so existing local data remains readable.
- [Risk] Debug code could leak into production UI. -> Mitigation: compile-time guards plus a release guardrail test or source audit where feasible.
- [Risk] Adding broad harness UI could distract from the core app surface. -> Mitigation: nest under Settings > Developer and keep it operational, text-light, and debug-labeled.

## Migration Plan

- Add optional test-scoping fields with safe decode defaults so existing `Subh.WakeSessionsAndMorningLogs` payloads continue to load.
- Ship the lab only in debug/internal builds. Release builds keep user-facing behavior unchanged.
- Cleanup actions cancel test IDs and clear test records without touching real settings, production schedule cache, or real MorningLogs.
- Rollback can ignore or delete test-scoped records; production app behavior does not depend on them.

## Open Questions

- Whether `INTERNAL_TESTING` is already available in the project build settings or should be introduced later for TestFlight-only access.
- Which AlarmKit callbacks are available on Omar's physical target OS for observing fired/stopped events. The harness can simulate those records safely, but real callback wiring may remain platform-limited.
