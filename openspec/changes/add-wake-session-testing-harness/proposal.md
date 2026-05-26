## Why

Wake Sessions are now core to Subh's morning execution, but the most important edge cases currently require waiting for real Fajr/Suhoor windows or manually exercising AlarmKit on-device. A debug/internal Wake Session Lab lets Omar verify the real morning engine, Wake Checks, Quiet cancellation, MorningLogs, and compressed physical-device AlarmKit behavior in minutes without weakening production trust.

## What Changes

- Add a debug/internal Wake Session Testing and Simulation Harness driven by `subh-wake-session-testing-and-simulation-harness-spec-v1.md`.
- Add injected time, compressed prayer-window scenario inputs, fake scheduling, permission-failure simulation, pending-alarm inspection, and test MorningLog inspection for internal testing.
- Add a debug-only Settings > Developer > Wake Session Lab entry point with `TEST MODE ACTIVE` labeling and scenario launchers for Fajr, Suhoor, Suhoor-to-Fajr, Quiet active-session cancellation, slider reschedule, alarm stop vs awake confirmation, permission failure, cross-surface consistency, and explicit real AlarmKit compressed testing.
- Mark all harness-created Wake Sessions, MorningLogs, scheduled test IDs, and events as test-scoped so they do not count as real worship, fasting, history, analytics, Qada, export, or Plus-layer records.
- Keep the production morning resolver, Wake Session lifecycle, scheduling abstraction, pricing/entitlement behavior, and core wake rules unchanged.
- Do not expose the lab, fake clock controls, compressed windows, simulated alarm-fired controls, test inspectors, or real compressed AlarmKit button in App Store production/release builds.
- Do not implement paid features, StoreKit, adaptive wake checks, advanced personalization, long-term analytics, export/sync, Qada ledgers, or a second morning/wake engine.

## Capabilities

### New Capabilities

- `wake-session-testing-harness`: Debug/internal Wake Session Lab, injected testing seams, compressed scenario provider, fake scheduler records, test-scoped logs, release guardrails, and real-device AlarmKit compressed QA support.

### Modified Capabilities

- None. Production wake-session, morning-resolution, delivery, entitlement, and hero requirements remain unchanged; this change adds internal test controls around the existing engine.

## Impact

- Affected code areas are expected to include `TimeProvider`, `WakeSessionStore`, `WakeSessionPlanner`, `AlarmScheduler`/`RoutineScheduling`, `SchedulingIdentifiers`, delivery diagnostics, `ScheduleService` or equivalent current-morning actions, Settings views, and new debug-only harness models/views under the existing app target.
- Affected tests are expected to include `SubhTests/ScheduleServiceExtractionTests.swift` or a focused new harness test file, plus any practical debug-route guardrail tests.
- Existing scheduled production alarms, cached production schedules, real user settings, and real user MorningLogs must not be deleted or mutated by starting or clearing test scenarios.
- Production builds may keep protocol seams and test-scope cleanup helpers, but unsafe debug UI and compressed scenario controls must be compiled out or otherwise unavailable.
- No new production dependency is required.
