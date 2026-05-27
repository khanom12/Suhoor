## Context

The v2 harness already added simulation context models, an injected clock seam, fake scheduler records, Home snapshot swapping, a debug-only Home dock, mapped AlarmKit playback, and inspectors. The v3 change is primarily a UX and workflow refinement: Settings becomes a simple launchpad, Home remains the real testing stage, and diagnostics move behind collapsed troubleshooting sections.

The implementation must continue to respect Subh's one-morning-engine model. Simulated date/time/location and mapped alarms are test inputs around the canonical resolver/Home snapshot/Wake Session paths; they are not a parallel Fajr, Suhoor, Quiet, Ramadan, or alarm engine.

## Goals / Non-Goals

**Goals:**
- Make Wake Session Lab task-oriented with exactly three top-level areas: Preview Home UI, Real Alarm Test, and Diagnostics.
- Provide self-explanatory scenario cards with what-it-tests, real-alarm, duration, expected-outcome, and primary-action copy.
- Support Custom Home Preview with Date, Location, Mode, and State as the primary form fields.
- Add expected-state guidance and simple previous/next/change/exit controls to the Home simulation dock.
- Keep Real Alarm Test explicit, confirmable, cancellable, and five-minute-spaced.
- Keep diagnostics collapsed by default with human-readable labels.
- Preserve v2 technical guardrails, release-build hiding, test namespacing, and test-only logs.

**Non-Goals:**
- No production wake-rule changes.
- No StoreKit, paywalls, paid analytics, household features, cloud sync, adaptive Wake Checks, or advanced Wake Check personalization.
- No fake Home screen or fake Hero component.
- No one-minute or two-minute scheduled Wake Checks.
- No mutation of real settings, real plans, real location, real entitlements, or real worship history from test scenarios.

## Decisions

1. **Refactor the lab UI, not the product engine.**
   `WakeSessionLabView` will become a segmented/tabbed task surface. Existing harness methods remain the source of scenario setup, mapped playback, fake scheduler records, and cleanup. This avoids reimplementing scheduling or morning state inside SwiftUI.

2. **Represent v3 scenario cards as data.**
   Add lightweight metadata for preview and real alarm scenario cards so tests can validate required fields and the UI can stay compact. This keeps the visible copy plain-language while preserving technical scenario kinds internally.

3. **Map v3 human states onto existing jump points.**
   The harness will expose v3 state labels and previous/next navigation, mapping those labels to existing Fajr, Suhoor, and Quiet jump points. State jumps remain instant and do not imply compressed scheduled alarms.

4. **Keep Real Alarm Test as mapped playback with existing schedule seam.**
   The setup screen will build the same mapping plan: primary anchor at real now plus 60/90/120 seconds, Wake Checks spaced five minutes apart, and simulated cutoff filtering before real mapping. Scheduling real AlarmKit remains reachable only through explicit confirmation.

5. **Use compile-time guards for unsafe UI.**
   `SettingsRootView`, `WakeSessionLabView`, Home dock controls, and manager helpers stay behind `#if DEBUG || INTERNAL_TESTING`. Safe model/protocol seams may remain compiled, but unsafe controls are unavailable in App Store production builds.

## Risks / Trade-offs

- **Risk: v3 UI can drift from v2 harness internals.** Mitigation: keep scenario cards and state labels backed by harness enums and add tests for card metadata, state ordering, and mapped plan output.
- **Risk: Home dock could obscure Hero layout testing.** Mitigation: keep the dock compact, bottom-aligned, and focused on the required status/guidance/actions.
- **Risk: real test alarms accidentally remain scheduled.** Mitigation: keep `Cancel All Test Alarms` visible in Real Alarm Test and active Home dock states, and keep Exit Test Mode cancelling mapped and fake test alarms.
- **Risk: release builds accidentally expose debug routes.** Mitigation: preserve build guards and run release configuration build/source audit tests.
