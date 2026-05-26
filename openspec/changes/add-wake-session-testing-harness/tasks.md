## 1. Harness Domain And Test Scope

- [x] 1.1 Add or extend a time-provider seam with production real time and mutable/fixed debug time for harness scenarios.
- [x] 1.2 Add test-scope metadata to Wake Sessions, MorningLogs, records, and scenario-created identifiers with safe decode defaults for existing data.
- [x] 1.3 Add compressed Fajr, Suhoor, Suhoor-to-Fajr, Quiet, reschedule, stop-vs-awake, permission failure, cross-surface, and real AlarmKit scenario definitions.
- [x] 1.4 Add a harness coordinator/service that creates test Wake Sessions through the existing `WakeSessionStore` and `WakeSessionPlanner`.
- [x] 1.5 Add cleanup methods for test sessions, test MorningLogs, test scheduler records, and test clock state without touching real data.

## 2. Scheduler And Delivery Seams

- [x] 2.1 Add a fake scheduler adapter that records scheduled IDs, fire dates, roles, channels, cancellations, pending status, and permission failures.
- [x] 2.2 Wire fake scheduling through the same scheduling abstraction used by production code where practical.
- [x] 2.3 Add deterministic test alarm identifier helpers using a `test.wakeSession...` namespace.
- [x] 2.4 Add reschedule behavior that cancels stale test primary/Wake Check IDs and schedules only the latest expected IDs.
- [x] 2.5 Add guarded real AlarmKit compressed-test support that uses near-future real device times only when the explicit lab action is selected.

## 3. Debug UI And Guardrails

- [x] 3.1 Add a debug/internal Settings > Developer > Wake Session Lab entry point behind `#if DEBUG || INTERNAL_TESTING` or the repo's equivalent.
- [x] 3.2 Build Wake Session Lab status, scenario launcher, time controls, and `TEST MODE ACTIVE` banner.
- [x] 3.3 Add scenario buttons for Fajr, Suhoor, Suhoor-not-confirmed to Fajr, Quiet during Wake Checks, slider reschedule, alarm stop vs awake, permission failure, cross-surface consistency, and real AlarmKit compressed testing.
- [x] 3.4 Add MorningLog inspector and pending alarm inspector for test records.
- [x] 3.5 Add prominent safety actions: `Cancel All Test Alarms`, `Clear Test Wake Sessions`, `Clear Test MorningLogs`, and `Exit Test Mode`.
- [x] 3.6 Add a release guardrail test, source audit, or build-time assertion where feasible to ensure the lab route is unavailable in release builds.

## 4. Automated Tests

- [x] 4.1 Add tests for compressed Fajr scenario timing, Wake Check interval, cutoff, and test-only interval behavior.
- [x] 4.2 Add tests for compressed Suhoor scenario timing, wake checks, Suhoor awake confirmation, and fasting-intent-only logging.
- [x] 4.3 Add tests that alarm stop/dismissal does not mark the Wake Session awake and leaves Wake Checks pending.
- [x] 4.4 Add tests that Fajr/Suhoor awake confirmation cancels remaining Wake Checks and keeps Fajr prayer separate.
- [x] 4.5 Add tests for `I prayed Fajr` as a separate confirmation.
- [x] 4.6 Add tests for Quiet during active Wake Checks: confirmation requirement, cancellation, `quietMorning`, and no missed Fajr.
- [x] 4.7 Add tests for slider reschedule stale-ID cancellation and no duplicate pending checks.
- [x] 4.8 Add tests for permission failure remaining distinct from Quiet and missed prayer.
- [x] 4.9 Add tests for deterministic fake scheduler schedule/cancel recording and `isTest` marking.
- [x] 4.10 Add a safe test for real AlarmKit compressed-test guardrails without scheduling real alarms in automation.

## 5. Validation And Documentation

- [x] 5.1 Run `openspec validate add-wake-session-testing-harness --strict` and fix any OpenSpec issues.
- [x] 5.2 Run targeted Swift tests for wake-session scheduling, logging, and harness behavior.
- [x] 5.3 Run `git diff --check`.
- [x] 5.4 Run the full configured Xcode test suite if reasonable for the current environment.
- [x] 5.5 Document the physical-device manual QA checklist in the implementation summary.
- [x] 5.6 Confirm no paid, StoreKit, analytics, adaptive wake-check, export/sync, or production debug UI work was added.
