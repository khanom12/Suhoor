## Why

Wake Session v1 testing covers compressed lab scenarios, but Omar still cannot make the real Home surface consume an arbitrary simulated morning or run physical-device AlarmKit playback that preserves production five-minute Wake Check spacing. This change adds the v2 internal testing layer so Subh can be tested on-device across Fajr, Suhoor, Quiet, Wake Checks, Home Hero states, logs, and mapped AlarmKit delivery without waiting for real mornings.

## What Changes

- Add a debug/internal Wake Session Testing, Home Simulation, State Explorer, and Real AlarmKit Mapped Playback harness based on `subh-wake-session-testing-and-simulation-harness-spec-v2.md`.
- Promote v2 of the active testing spec and archive v1 as superseded.
- Add app-wide simulation context and injected clock support so Home, Morning Hero, Wake Session logic, MorningLog inspection, scheduler inspection, and test services can consume simulated time/state while production keeps real time.
- Add State Explorer controls for simulated date, time, location, mode, prayer-window source, clock mode, named jump points, Wake Session state, and outcome toggles.
- Add Home Simulation Mode where the actual Home/Morning Hero UI consumes a simulated resolved morning graph and shows an internal `TEST MODE ACTIVE` overlay/dock.
- Add Real AlarmKit Mapped Playback as an explicit, confirmable internal mode that maps simulated primary/wake-check events onto near-future real AlarmKit alarms while preserving five-minute Wake Check spacing.
- Add a sequence selector for `Primary only` through `Primary + 5 wake checks`, defaulting to `Primary + 5 wake checks`, with simulated cutoff filtering before real-time mapping.
- Add fake scheduler playback, pending test alarm inspection, MorningLog inspection, permission/failure simulation, and safety actions for cancelling/clearing only test-scoped state.
- Keep production wake rules unchanged: primary plus up to five Wake Checks, five-minute intervals, Fajr cutoff five minutes before Fajr ends, and Suhoor cutoff five minutes before Fajr begins.
- Do not expose Wake Session Lab, State Explorer, Home Simulation controls, fake time controls, artificial prayer-window controls, mapped playback controls, fake scheduler controls, or `TEST MODE ACTIVE` in App Store production builds.
- Do not implement paid features, StoreKit, adaptive wake checks, advanced personalization, analytics, export/sync, cloud sync, family accountability, or public user-facing features outside the internal harness.
- Do not create a second morning engine; the harness fakes the world around Subh and routes simulated state through the canonical morning-resolution/Home snapshot/Wake Session paths.

## Capabilities

### New Capabilities

- `wake-session-home-simulation-harness`: Debug/internal State Explorer, Home Simulation Mode, app-wide simulation context, fake scheduler playback, Real AlarmKit mapped playback with five-minute Wake Check spacing, test inspectors, and release guardrails.

### Modified Capabilities

- None. Production morning-resolution, Wake Session execution, delivery reliability, pricing/entitlement, sound, and Hero requirements remain unchanged; this change adds internal testing controls around the existing engine.

## Impact

- Affected code areas are expected to include time providers, Wake Session test models, active simulation context/store, ScheduleManager or equivalent Home snapshot source, Home/Morning Hero presentation hooks, Wake Session Lab settings views, scheduler identifiers, fake scheduler records, AlarmKit scheduling seams, MorningLog cleanup/inspection, and targeted tests.
- Existing production scheduled alarms, real user settings, real anchored plans, real MorningLogs, pricing/entitlement state, and real worship history must not be mutated by test scenarios or cleanup actions.
- Test sessions, test logs, and test alarm identifiers must be marked `isTest` or namespaced under `test.wakeSession...` and cancellable independently from production state.
- Production builds may retain safe architecture seams, but unsafe debug UI and controls must be compiled out or otherwise unavailable.
- No new production dependency is required.
