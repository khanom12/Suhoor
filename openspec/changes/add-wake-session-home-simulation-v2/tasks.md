## 1. Spec And Guardrail Setup

- [x] 1.1 Promote `subh-wake-session-testing-and-simulation-harness-spec-v2.md` into active specs, archive v1 as superseded, and update the spec index.
- [x] 1.2 Add OpenSpec proposal, design, tasks, and delta spec for `wake-session-home-simulation-harness`.
- [x] 1.3 Validate OpenSpec with `openspec validate add-wake-session-home-simulation-v2 --strict` before app-code changes.

## 2. Simulation Domain Models

- [x] 2.1 Add or extend `RealSubhClock` / `TestSubhClock` naming around existing production and mutable test time providers.
- [x] 2.2 Add `ActiveSimulationContext`, simulation scenario kind, run mode, clock mode, prayer-window source, location, jump-point, and outcome-state models.
- [x] 2.3 Add Real AlarmKit mapping models for anchor event, start delay, sequence length, mapped real fire dates, simulated fire dates, cutoff explanation, and test alarm records.
- [x] 2.4 Add v2 named jump points for Fajr, Suhoor, and Quiet.
- [x] 2.5 Keep all test identifiers namespaced and all created sessions/logs marked `isTest`.

## 3. Harness And Scheduler Behavior

- [x] 3.1 Extend `WakeSessionTestingHarness` to own and publish the active simulation context.
- [x] 3.2 Replace v1 compressed scheduled Wake Check behavior with v2 five-minute Wake Check planning for fake playback and mapped playback.
- [x] 3.3 Preserve instant State Explorer jumps without scheduling compressed one-minute or two-minute Wake Checks.
- [x] 3.4 Build simulation plans for Fajr, Suhoor, Quiet, Suhoor-to-Fajr handoff, slider reschedule, alarm stop vs awake, permission failure, MorningLog inspection, and cross-surface consistency.
- [x] 3.5 Add fake scheduler fields for simulated fire date, mapped real fire date, role, channel, status, failure reason, and `isTest`.
- [x] 3.6 Add mapped playback plan generation with default 90-second start delay, 60-120 second clamp, primary anchor, sequence selector primary-only through primary plus five, and simulated cutoff filtering.
- [x] 3.7 Add explicit real AlarmKit scheduling handoff for mapped playback only, with confirmation-required state.
- [x] 3.8 Add cleanup for selected/all test alarms, test sessions, test MorningLogs, reset test time, and Exit Test Mode.

## 4. Home Simulation Integration

- [x] 4.1 Add a debug/internal simulation hook in `ScheduleManager` that swaps `currentMorningHomeSnapshot` to the simulated snapshot while active.
- [x] 4.2 Build simulated `MorningHomeSnapshot` values from existing `ActiveAlarmDay`, `WakeRowActionResolver`, Wake Session, MorningLog, and Fajr window snapshot paths where practical.
- [x] 4.3 Ensure exiting simulation restores the real resolved Home snapshot without mutating real settings, plans, logs, or location.
- [x] 4.4 Add Home simulation overlay/dock to `SubhHomeView` behind `#if DEBUG || INTERNAL_TESTING`.
- [x] 4.5 Overlay/dock shows `TEST MODE ACTIVE`, scenario, simulated date/time, Hijri date if available, location, run mode, jump point, and mapped playback countdown/details when active.
- [x] 4.6 Overlay/dock actions expose Change Time, Jump State, Run Real AlarmKit Playback, Cancel Test Alarms, and Exit Test Mode without obscuring the Hero.

## 5. Wake Session Lab UI

- [x] 5.1 Update `WakeSessionLabView` into a launchpad with State Explorer, Home Simulation, Real AlarmKit Mapped Playback, Fake Scheduler Playback, Dry Run, inspectors, permission/failure simulator, and safety sections.
- [x] 5.2 Add State Explorer controls for date presets, date/time, location preset, mode, prayer-window source, clock mode, jump point, Wake Session state, and outcome toggles.
- [x] 5.3 Add Activate on Home and Preview State actions that do not schedule real alarms.
- [x] 5.4 Add mapped playback builder controls for start delay, anchor, sequence length, sound summary, dry run, and confirmation sheet.
- [x] 5.5 Add MorningLog inspector fields and Copy Test Report / Clear Test Logs / Export Debug Summary actions where practical.
- [x] 5.6 Add pending alarm inspector fields plus Refresh, Cancel Selected Test Alarm, and Cancel All Test Alarms actions where practical.
- [x] 5.7 Keep all visible lab UI and routes behind debug/internal build guards.

## 6. Tests

- [x] 6.1 Add unit tests for simulated clock injection and State Explorer date/time/jump selection.
- [x] 6.2 Add tests for Fajr and Suhoor Wake Check math using five-minute intervals, cutoff filtering, and primary-too-close-to-cutoff cases.
- [x] 6.3 Add tests for sequence selector primary-only through primary plus five and default primary plus five.
- [x] 6.4 Add tests for mapped playback preserving five-minute deltas and clamping start delay to 60-120 seconds.
- [x] 6.5 Add tests for alarm stop not confirming awake, awake confirmation cancelling checks, Suhoor fasting-intent-only confirmation, and Fajr prayer separation.
- [x] 6.6 Add tests for Quiet active-session cancellation, `Keep wake checks`, `quietMorning`, and no missed prayer.
- [x] 6.7 Add tests for permission failure not becoming Quiet and test records marked `isTest`.
- [x] 6.8 Add tests for Home consuming active simulation context and restoring real Home on Exit Test Mode.
- [x] 6.9 Add tests for fake scheduler schedule/cancel records, stale ID cleanup, and no duplicate pending identifiers.
- [x] 6.10 Add release guardrail tests or source audit coverage ensuring debug routes are unavailable in release builds.

## 7. Validation And Delivery

- [x] 7.1 Run `openspec validate add-wake-session-home-simulation-v2 --strict` after implementation.
- [x] 7.2 Run targeted Swift tests for Wake Session harness, mapping, Home simulation, scheduling, logging, and guardrails.
- [x] 7.3 Run `git diff --check`.
- [x] 7.4 Run full configured Xcode test suite if reasonable in the current environment.
- [x] 7.5 Run a release configuration build or equivalent release guardrail validation.
- [x] 7.6 Document manual physical-device QA checklist and note that actual AlarmKit ringing requires Omar's iPhone.
- [x] 7.7 Confirm no StoreKit, paid features, adaptive Wake Checks, analytics, export/sync/cloud sync, family accountability, or production-visible debug controls were added.
