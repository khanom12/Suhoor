## Why

The May 31 active specification package resolves several product-critical morning-state distinctions that were previously blurred across Home, Quiet, Suhoor/Fajr wake execution, late Fajr logging, and the testing harness. This change makes Subh explain and execute the next relevant morning consistently, without turning Quiet/Pause into wake purposes or creating a second wake engine.

## What Changes

- Align Home Hero and Detail Hero copy so Slot 2 uses `Today Morning` / `Tomorrow Morning`, Slot 3 stays minimal, and the alarm icon/wake-time control opens Quiet confirmation instead of instantly mutating delivery.
- Update the primary context card to use sentence-based explanatory copy that describes the morning, opportunity, fasting plan, wake purpose, alarm delivery, wake time, and Quiet/Pause state when relevant.
- Rework Next 7 Mornings rows to left wake time/`Quiet` plus date, middle `Awake for Fajr`/`Awake for Suhoor` plus specific opportunity tags, and right-side one-morning Quiet toggle.
- Apply May 31 Suhoor/Fajr timing rules: Suhoor starts at the daily last-third boundary, sensitive-window purpose switching may require confirmation, and new Suhoor scheduling is blocked after `Fajr begins - 6 minutes`.
- Update wake-session generation so Suhoor ends at Fajr begins, Fajr ends at Fajr ends, new sessions use current-time and boundary cutoffs, and wake checks occur every five minutes without scheduling at the exact relevant boundary.
- Keep Suhoor wake acknowledgement, optional Fajr follow-up, Fajr wake acknowledgement, and Fajr prayer completion as separate facts.
- Move unresolved post-window Fajr prayer logging below the context card after Hero rollover, using the May 31 CTA copy and expiry rules.
- Extend the testing/simulation harness so May 31 states can be scrubbed and branched without waiting for real mornings.
- Preserve existing scheduled-alarm and persisted-setting meaning where not explicitly superseded; Quiet clears delivery for one morning while preserving the saved Fajr/Suhoor plan.

## Capabilities

### New Capabilities
- `morning-state-simulation-harness`: Supports May 31 scenario packs, minute-level scrubbing, boundary jumps, expected-vs-actual previews, branch actions, and calculated-time validation across real Home/context/Next 7 surfaces.

### Modified Capabilities
- `morning-resolution`: Adds May 31 morning labels, Suhoor last-third/cutoff rules, one-morning Quiet semantics, late Fajr prompt eligibility, and preserved separation of purpose, delivery, and observed outcomes.
- `single-screen-morning-home`: Updates Hero, context card, late Fajr prompt placement, and Next 7 row/toggle behavior.
- `wake-session-execution`: Updates wake-check generation, Suhoor/Fajr acknowledgement and follow-up semantics, active-session Quiet cancellation, and Fajr prayer completion separation.

## Impact

- Affected code: `Subh/Core/Morning`, `Subh/Core/Services/ScheduleService.swift`, `Subh/Features/Home/SubhHomeView.swift`, `Subh/Features/Settings/WakeSessionLabView.swift`, and focused XCTest coverage under `SubhTests`.
- Affected systems: local schedule generation/reconciliation, wake-session simulation models, Home presentation state, Quiet mutation flows, operational morning logs, and AlarmKit event previews.
- Persistence/migration: no broad migration is intended. Existing purpose-specific settings should remain intact; one-morning Quiet records suppress delivery without replacing the saved Suhoor/Fajr plan. Existing scheduled alarms may be reconciled to match the updated wake-check boundaries and Quiet cancellation reasons.
- Dependencies: no new production dependency is planned.
