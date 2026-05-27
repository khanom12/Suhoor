## 1. Spec Setup

- [x] 1.1 Promote `subh-wake-session-testing-and-simulation-harness-spec-v3.md` into active specs, archive v2 as superseded, and update the spec index.
- [x] 1.2 Add OpenSpec proposal, design, tasks, and `wake-session-lab-v3` spec delta.
- [x] 1.3 Validate OpenSpec with `openspec validate add-wake-session-lab-v3 --strict` before app-code changes.

## 2. Harness Models And Copy

- [x] 2.1 Add v3 plain-language preview scenario card metadata for Fajr Flow, Suhoor Flow, Quiet During Wake Checks, and Custom Date & Time.
- [x] 2.2 Add v3 Real Alarm Test card metadata for Fajr Alarm Test and Suhoor Alarm Test.
- [x] 2.3 Add Custom Home Preview state labels and mode-adaptive state ordering.
- [x] 2.4 Add expected-state guidance text for Home dock states.
- [x] 2.5 Add previous/next/change-state helpers that map v3 labels to existing simulation jump points without scheduling compressed Wake Checks.

## 3. Wake Session Lab UX

- [x] 3.1 Rework `WakeSessionLabView` into three top-level areas: Preview Home UI, Real Alarm Test, and Diagnostics.
- [x] 3.2 Add compact active/inactive status header with Return to Home, Exit Test Mode, and Cancel Test Alarms when relevant.
- [x] 3.3 Add Preview Home UI scenario cards with required explanatory fields and primary actions.
- [x] 3.4 Add Custom Home Preview UI with Date, Location, Mode, and State as primary fields and Advanced Options collapsed by default.
- [x] 3.5 Add Real Alarm Test cards and focused setup flow with Scenario, Start delay, Sequence length, Sound, mapping preview, and confirmation sheet.
- [x] 3.6 Rework Diagnostics into collapsed Scheduled Test Alarms, Test Event Log, Permission Simulation, and Reset Test Mode sections.
- [x] 3.7 Replace overly technical visible labels with v3 human-readable labels.

## 4. Home Simulation And Real Alarm Behavior

- [x] 4.1 Update Home simulation dock to show expected-state guidance and required Previous State, Next State, Change State, and Exit actions.
- [x] 4.2 Keep Home consuming the simulated resolved morning snapshot through the existing Home snapshot path while simulation is active.
- [x] 4.3 Preserve Real Alarm Test mapping: 60/90/120-second start delay, primary-only through primary plus five sequence selector, default primary plus five, and five-minute Wake Check spacing.
- [x] 4.4 Keep real AlarmKit scheduling explicit, confirmable, and cancellable, with no platform alarms scheduled from Preview Home UI.
- [x] 4.5 Keep test sessions, event records, and alarm identifiers marked or namespaced as test data.

## 5. Tests And Guardrails

- [x] 5.1 Add or update unit tests for scenario card metadata, Custom Home Preview state ordering, expected-state guidance, and previous/next state navigation.
- [x] 5.2 Add or update integration tests for Home simulation context, Test Event Log records, Scheduled Test Alarms inspector data, fake scheduler records, and cleanup.
- [x] 5.3 Add or update mapped playback tests for sequence selection and five-minute Wake Check deltas.
- [x] 5.4 Add or update guardrail tests or release build validation so v3 lab routes and controls are unavailable in release builds.
- [x] 5.5 Run targeted XCTest coverage for Wake Session Lab, mapping, Home simulation, scheduling, logging, and guardrails.

## 6. Validation And Delivery

- [x] 6.1 Run `openspec validate add-wake-session-lab-v3 --strict` after implementation.
- [x] 6.2 Run `git diff --check`.
- [x] 6.3 Run full configured Xcode tests if reasonable in the current environment.
- [x] 6.4 Run a release configuration build or equivalent release guardrail validation.
- [x] 6.5 Document manual physical-device Real Alarm Test QA steps and note that real AlarmKit ringing requires Omar's iPhone.
- [x] 6.6 Confirm no production wake rules, StoreKit, paid features, analytics, adaptive Wake Checks, household features, or cloud sync were added.
