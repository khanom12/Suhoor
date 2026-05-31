## Context

The May 31 spec package updates Subh's current morning model across product copy, one-morning Quiet semantics, Suhoor/Fajr boundary rules, wake-session generation, late Fajr logging, and simulation coverage. The affected implementation is already concentrated in `Subh/Core/Morning`, `Subh/Core/Services/ScheduleService.swift`, `Subh/Features/Home/SubhHomeView.swift`, `Subh/Features/Settings/WakeSessionLabView.swift`, and focused tests in `SubhTests`.

The current worktree already includes wake-session lab v4 edits, so this pass should preserve existing behavior unless the active May 31 specs supersede it. SwiftUI views should continue consuming resolved presentation data rather than becoming the source of prayer-time or wake-check calculations.

## Goals / Non-Goals

**Goals:**
- Make Home/Detail visible state match May 31: `Today Morning`/`Tomorrow Morning`, minimal tappable alarm-state Slot 3, live slider feedback, sentence-based context card, late Fajr prompt below the context card, and Next 7 rows with a per-row Quiet toggle.
- Centralize May 31 wake-session math in the existing core/schedule path: relevant boundary by purpose, 5-minute checks, boundary-minus-5 final attempt, boundary-minus-6 latest creation, current-time-plus-1 earliest new wake time, and natural compression.
- Preserve domain separation among wake purpose, one-morning Quiet, global Pause, awake acknowledgement, fasting acknowledgement, Fajr wake acknowledgement, and Fajr prayer completion.
- Extend the existing wake-session testing harness rather than creating a second product engine.

**Non-Goals:**
- No broad Pause redesign beyond compatibility with May 31 surfaces.
- No new Month Planning or Weekly Fajrcast mutation controls.
- No generic Islamic content, streaks, historical analytics, or new entitlement behavior.
- No production dependency additions.

## Decisions

1. Keep time and wake-session calculation in core/services, not SwiftUI.
   - Rationale: May 31 behavior depends on auditable boundaries, cutoff rules, and date/time fixtures.
   - Alternative considered: implement simple view-side conditionals. Rejected because it would hide religious/time assumptions and make harness verification fragile.

2. Treat Quiet as delivery state layered on top of the saved purpose.
   - Rationale: Quiet must suppress ringing for one morning while preserving Suhoor/Fajr intent and alarm settings for restoration.
   - Alternative considered: reuse purpose/mode values for Quiet. Rejected because active specs explicitly remove Quiet and Pause from the wake-purpose selector.

3. Keep Suhoor and Fajr wake sessions distinct.
   - Rationale: Suhoor acknowledgement cancels Suhoor checks and may produce a single Fajr-start event, but it must not automatically create or confirm a Fajr wake-check session.
   - Alternative considered: chain a default Fajr wake session after Suhoor. Rejected by May 31 because Fajr follow-up must be user-initiated.

4. Implement late Fajr logging as a separate Home presentation model.
   - Rationale: after Fajr ends the Hero belongs to the next relevant morning, while prayer completion for the previous morning remains eligible below the context card.
   - Alternative considered: keep previous Fajr completion inside Hero. Rejected because it confuses the primary unit of the screen.

5. Extend the existing simulation/lab types and settings view.
   - Rationale: the harness already previews wake-session schedules and should now drive May 31 scenario packs, branch controls, and expected-vs-actual inspection using the same resolver path.
   - Alternative considered: a standalone simulator. Rejected because it risks a parallel morning engine.

## Risks / Trade-offs

- [Risk] The current code may not have persistent stores for every May 31 log fact yet. → Mitigation: model missing facts explicitly in the harness/presentation layer and keep persistence changes narrow.
- [Risk] AlarmKit delivery behavior cannot be fully verified in unit tests or simulator. → Mitigation: cover deterministic schedule math with XCTest and expose real/simulated event previews in the harness.
- [Risk] Existing uncommitted wake-session lab v4 changes may overlap this pass. → Mitigation: inspect before editing and preserve behavior unless superseded by active May 31 specs.
- [Risk] Last-third Suhoor windows rely on valid prior sunset/Maghrib and Fajr data. → Mitigation: keep degraded/missing-time states explicit and ensure standard harness scenarios use valid fixtures without `No time available`.

## Migration Plan

1. Sync May 31 docs to `docs/specs` and archive May 30 root/report artifacts for traceability.
2. Update OpenSpec artifacts and tasks before implementation.
3. Implement domain/schedule behavior first, then presentation and harness surfaces.
4. Run focused XCTest coverage for schedule extraction/generation and compile checks where available.

Rollback is code-level: revert this change's implementation and restore archived May 30 spec root files if needed. No data migration is planned.

## Open Questions

- Whether the production app already has a durable Fajr prayer completion store suitable for late logging, or whether this pass should keep late logging local/simulated until the store is finalized.
- Whether active-session Quiet cancellation from Slot 3 is currently exposed in production or only in the harness edge-case path.
