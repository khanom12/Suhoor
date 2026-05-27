## Why

The v2 Wake Session harness has the right technical seams, but its visible lab is still subsystem-oriented and too dense for personal device QA. v3 makes the lab task-oriented so Omar can preview Home UI states, run explicit real alarm tests, and use diagnostics only when needed.

## What Changes

- Promote `subh-wake-session-testing-and-simulation-harness-spec-v3.md` as the active testing harness spec and archive v2 as superseded.
- Rework Wake Session Lab into three top-level areas: `Preview Home UI`, `Real Alarm Test`, and `Diagnostics`.
- Make `Preview Home UI` the default area with scenario cards for Fajr Flow, Suhoor Flow, Quiet During Wake Checks, and Custom Date & Time.
- Replace the broad v2 State Explorer form with a smaller Custom Home Preview focused on Date, Location, Mode, and State, with advanced controls collapsed.
- Keep Home as the testing stage: Home consumes the active simulated resolved morning snapshot and shows a compact `TEST MODE ACTIVE` dock.
- Add plain-language expected-state guidance and Previous State / Next State / Change State / Exit controls to the Home simulation dock.
- Reframe Real AlarmKit mapped playback as `Real Alarm Test` with Fajr and Suhoor alarm test cards, a focused setup screen, mapping preview, and required confirmation sheet.
- Preserve production Wake Check behavior: primary plus up to five Wake Checks, five-minute Wake Check interval, and mode-specific cutoffs.
- Keep the sequence selector from `Primary only` through `Primary + 5 wake checks`, defaulting to `Primary + 5 wake checks`.
- Collapse diagnostics by default and rename inspectors to `Scheduled Test Alarms`, `Test Event Log`, `Permission Simulation`, and `Reset Test Mode`.
- Keep test data visibly marked, namespaced, cancellable, and isolated from real settings, real plans, real MorningLogs, real worship history, and production pending alarms.
- Do not expose Wake Session Lab, Preview Home UI, Home Simulation controls, Diagnostics controls, Real Alarm Test, fake clocks, fake scheduler controls, or `TEST MODE ACTIVE` in App Store production builds.
- Do not implement paid features, StoreKit, analytics, adaptive Wake Checks, household features, cloud sync, or production-visible public features.

## Capabilities

### New Capabilities
- `wake-session-lab-v3`: Tester-first debug/internal Wake Session Lab UX, Preview Home UI, Home Simulation dock, Real Alarm Test setup, Diagnostics, test event log, scheduled test alarm inspector, fake scheduler records, and release guardrails.

### Modified Capabilities
- None. Production morning-resolution, Wake Session execution, pricing/entitlement, sound, and delivery reliability requirements remain unchanged; this change adds and refines internal testing controls around the existing engine.

## Impact

- Affected code areas include `WakeSessionTestingHarness`, simulation context models, `ScheduleManager`, `SubhHomeView`, `WakeSessionLabView`, `SettingsRootView`, fake scheduling records, mapped AlarmKit scheduling seams, and targeted XCTest/UI coverage.
- Existing scheduled production alarms, real user settings, real anchored plans, real location settings, real Hijri adjustments, real entitlements, and real MorningLogs must not be mutated by test scenarios.
- Test alarm identifiers remain deterministic and namespaced under the test Wake Session context.
- No new production dependency is required.
