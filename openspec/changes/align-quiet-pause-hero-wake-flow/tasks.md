## 1. Orientation And Spec Sync

- [x] 1.1 Confirm branch, working tree, app structure, OpenSpec setup, build/test commands, repo spec folder, and Desktop spec folder.
- [x] 1.2 Unpack the attached specification bundle and read the change report, index, alignment spec, and affected domain/surface specs.
- [x] 1.3 Archive superseded active Desktop specs, copy the latest bundle into the active Desktop specs folder, and write a sync report.
- [x] 1.4 Create OpenSpec proposal, design, and delta specs for `align-quiet-pause-hero-wake-flow`.
- [x] 1.5 Validate OpenSpec before implementation.

## 2. Domain Model And Persistence

- [x] 2.1 Add or adapt typed models for wake purpose, date alarm override, global wake-alarm pause policy, resolved alarm state, and acknowledgement source.
- [x] 2.2 Preserve separate Fajr and Suhoor alarm configurations when purpose, Quiet, Pause, resume, or ring-once state changes.
- [x] 2.3 Normalize legacy/internal Pre-Fajr, Early, Fast, and Quiet-mode values to the MVP-visible Fajr/Suhoor plus alarm-state model without destructive migration.
- [x] 2.4 Add domain/persistence tests for Quiet/Pause precedence, ring-once exception clearing, manual Quiet surviving resume, and purpose-specific alarm memory.

## 3. Scheduling And Wake Execution

- [x] 3.1 Suppress/cancel target-morning primary and follow-up wake alarms for Quiet without cancelling unrelated date keys or alarms.
- [x] 3.2 Implement indefinite app-wide Pause scheduling suppression and one-morning ring exception scheduling.
- [x] 3.3 Treat `I’m awake` and explicit system alarm dismissal as wake acknowledgement for MVP, cancelling remaining follow-up alarms for that morning.
- [x] 3.4 Enforce Fajr and Suhoor follow-up boundaries and expose `Final alarm this morning` when no follow-up is eligible.
- [x] 3.5 Add wake-session/scheduling tests for acknowledgement source, scoped cancellation, pause suppression, ring-once exception, and boundary cutoff behavior.

## 4. Home, Detail, Forecast, And Settings UI

- [x] 4.1 Update Home Hero presentation to fixed six-slot state semantics with stable Slot 6 behavior.
- [x] 4.2 Update Home planning selector to `Fajr | Suhoor` only and move Quiet/Pause actions into alarm-state controls.
- [x] 4.3 Update active alarm Hero to show only `I’m awake` and remove user-facing `Stop checks`/two-button active flows.
- [x] 4.4 Update post-awake CTAs and copy for delayed `I’m fasting today`, delayed `I prayed Fajr`, Fajr-begin Suhoor handoff, and Fajr-end next-morning handoff.
- [x] 4.5 Update Day Detail, Next 7 Mornings, Month Planning, and Settings copy/state controls to distinguish Quiet, Paused, Rings once, setup, and issue states.

## 5. Testing Harness And Copy Audit

- [x] 5.1 Update Wake Session Lab/Home simulation scenario cards for Active, Quiet, Paused, Exception, Setup/issue, Execution, Post-awake, Boundary, and Handoff states.
- [x] 5.2 Audit user-facing strings for deprecated Pre-Fajr, Early, Fast mode, Quiet mode, Pause mode, Saved wake, Stop checks, and wake-as-noun copy.
- [x] 5.3 Add presentation/harness tests for final user-facing vocabulary and task-oriented scenario labels.

## 6. Validation And Reporting

- [x] 6.1 Run focused XCTest suites for changed domain, scheduling, presentation, and harness behavior.
- [x] 6.2 Run broader build/lint/type checks available in the Xcode project.
- [x] 6.3 Write an implementation report covering what changed, validation, user-visible impact, privacy/reliability notes, and remaining risks.
- [x] 6.4 Commit the final reviewed diff on `main` and push `main` to origin.
