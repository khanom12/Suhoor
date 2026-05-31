## 1. Spec Sync and Planning

- [x] 1.1 Archive May 30 active root specs, reports, manifests, and miscellaneous spec artifacts under `docs/specs/Archive/may30-pre-may31-scenario-update/`.
- [x] 1.2 Copy the May 31 active spec package root files into `docs/specs/`.
- [x] 1.3 Validate OpenSpec artifacts for `may31-morning-state-framework`.

## 2. Resolution and Schedule Rules

- [x] 2.1 Inspect existing morning resolution, schedule extraction, and wake-session generation paths for May 31 overlap.
- [x] 2.2 Implement Suhoor last-third window calculation and Today Morning cutoff enforcement without hard-coded example times.
- [x] 2.3 Update wake-session generation to use purpose-specific relevant boundaries, 5-minute checks, boundary-minus-5 final attempts, boundary-minus-6 latest creation, and current-time-plus-1 earliest new wake time.
- [x] 2.4 Preserve separation of Suhoor acknowledgement, optional Fajr follow-up, Fajr wake acknowledgement, and Fajr prayer completion in logs/presentation state.
- [x] 2.5 Add or update domain tests for cutoff, compression, default attempts, no exact-boundary check, and acknowledgement separation.

## 3. Home and Detail Presentation

- [x] 3.1 Update Hero/Detail labels so Slot 2 shows `Today Morning` / `Tomorrow Morning` and Slot 3 remains minimal.
- [x] 3.2 Make the Hero alarm icon/wake-time control visibly tappable and route it through Quiet confirmation without instant delivery mutation.
- [x] 3.3 Apply May 31 Quiet confirmation and reverse-confirmation copy while preserving saved Suhoor/Fajr purpose.
- [x] 3.4 Keep slider primary time, thumb, and helper copy synchronized while dragging.
- [x] 3.5 Ensure visible purpose selector order is exactly `Suhoor | Fajr` and excludes Quiet/Pause.

## 4. Context, Late Logging, and Next 7

- [x] 4.1 Replace tag-heavy primary context-card messaging with sentence-based explanatory copy for purpose, opportunity, fasting plan, alarm delivery, wake time, Quiet, and Pause.
- [x] 4.2 Add the separate post-Fajr late logging prompt below the context card with same-day/yesterday copy, tap handling, and expiry rules where supported.
- [x] 4.3 Update Next 7 rows to left wake time/`Quiet` plus date, middle `Awake for Fajr/Suhoor` plus specific opportunity tags, and right Quiet toggle.
- [x] 4.4 Ensure the Next 7 Quiet toggle mutates only one-morning Quiet and Month/Weekly remain non-mutating.

## 5. Testing Harness

- [x] 5.1 Update simulation models to represent May 31 boundary presets, 24/48-hour simulated time, calculated times, expected/actual previews, branch actions, wake attempts, logs, and scheduled events.
- [x] 5.2 Update `WakeSessionLabView` so Omar can scrub/jump through May 31 scenarios and inspect real Home/context/Next 7 behavior while simulation is active.
- [x] 5.3 Ensure standard valid scenarios avoid accidental `No time available` and keep labels readable without clipping.

## 6. Verification

- [x] 6.1 Run `openspec validate --change may31-morning-state-framework` or the repository's equivalent OpenSpec validation.
- [x] 6.2 Run focused XCTest coverage for schedule service extraction and wake-session simulation behavior.
- [x] 6.3 Run a build/typecheck command or document why it could not run.
- [x] 6.4 Review the final diff for product-model drift, privacy/reliability regressions, and unrelated changes.
