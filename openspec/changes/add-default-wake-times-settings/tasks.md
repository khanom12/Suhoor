# Tasks

## 1. OpenSpec

- [x] 1.1 Create proposal, design, tasks, and morning-resolution spec delta.
- [x] 1.2 Include validation plan covering data model, Settings UX, validation, schedule refresh, manual overrides, accessibility, and tests.
- [x] 1.3 Run `openspec validate add-default-wake-times-settings --strict`.

## 2. Data Model and Migration

- [x] 2.1 Add persisted default Fajr and Suhoor wake rule model through existing alarm config.
- [x] 2.2 Preserve decoding compatibility for existing persisted defaults.
- [x] 2.3 Preserve legacy factory default tests while making new app defaults Fajr 30 minutes before end and Suhoor 60 minutes before start.

## 3. Resolver and Validation

- [x] 3.1 Add default wake rule resolution for Fajr begins, Fajr ends, and Suhoor before Fajr begins.
- [x] 3.2 Reject invalid Fajr and Suhoor combinations without silently switching boundaries.
- [x] 3.3 Validate Fajr rules over the next 12 months using shortest-window calculations.
- [x] 3.4 Enforce the 10-minute safety buffer before Fajr ends.
- [x] 3.5 Provide safe fallback metadata when a saved rule needs review.

## 4. Spine Integration

- [x] 4.1 Route generated morning plans through the new default rules.
- [x] 4.2 Ensure Suhoor generated plans consume the Suhoor default rule.
- [x] 4.3 Refresh schedules after default changes.
- [x] 4.4 Keep wake checks separate from wake-time defaults and preserve five-minute wake-check behavior.

## 5. Manual Override Protection

- [x] 5.1 Preserve explicit date overrides over global defaults.
- [x] 5.2 Preserve past, quiet, active, fired, completed, and already-passed wake sessions on default changes.
- [x] 5.3 Preserve the existing cancelled-Suhoor to Fajr execution handoff.

## 6. Settings UI and Accessibility

- [x] 6.1 Add Settings > Wake Alarms > Default Wake Times.
- [x] 6.2 Add Fajr and Suhoor sections with presets and custom controls.
- [x] 6.3 Add concise root subtitles and needs-review state.
- [x] 6.4 Add manual-change notice and unavailable-option explanation.
- [x] 6.5 Add accessibility labels for interactive controls and avoid color-only invalid states.
- [x] 6.6 Avoid public implementation terms in the new Default Wake Times copy.

## 7. Tests and Final Verification

- [x] 7.1 Add deterministic model, resolver, validation, manual override, schedule integration, wake-check, and Settings presentation tests.
- [x] 7.2 Update affected UI tests for the new Suhoor default.
- [x] 7.3 Run focused Xcode unit tests.
- [x] 7.4 Run focused UI tests.
- [x] 7.5 Run broader Xcode validation and document any unrelated existing failures.
- [x] 7.6 Inspect diff, commit, and push.
