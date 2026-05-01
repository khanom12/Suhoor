## Context

The affected code is contained in `Subh/Features/Home/SubhHomeView.swift`, specifically `TomorrowMorningHero`, `MorningHeroPrimaryWakeRow`, `RollingHeroTimeLockup`, `FajrWindowRangeVisual`, and `FajrWindowRangeTrack`. The resolved morning engine and scheduling persistence are already producing the correct states; the issue is SwiftUI transition state and marker handoff sequencing.

## Goals / Non-Goals

**Goals:**
- Keep the range row physically anchored while endpoint labels and relation copy fade through.
- Correct the marker handoff direction for Fajr/Fast transitions using deterministic ratios.
- Ensure active wake-time rolling is based on actual target time deltas after Quiet, not on stale transition direction state.
- Preserve existing drag, commit, selected-mode, and reduced-motion behavior.

**Non-Goals:**
- No changes to wake resolution, alarm scheduling, persistence, copy beyond the affected transitions, or quick-mode semantics.
- No new UI controls or layout rearrangement.

## Decisions

- Use explicit view-local transition state for the range labels instead of relying on `.id(text).transition(.opacity)` on the raw text nodes. This keeps the row stable and makes the fade visible when endpoint copy changes.
- Sequence marker handoff as a two-phase animation. Fajr to Fast animates the current marker to the left edge, fades it out, reappears at the right edge, then animates leftward to the Fast target. Fast to Fajr performs the inverse.
- Let `RollingHeroTimeLockup` roll whenever the target time changes by minutes and rolling is enabled. This removes the stale-direction dependency that suppresses the first active transition after leaving Quiet.
- Keep reduced motion as direct target updates with short fades only.

## Risks / Trade-offs

- [Risk] SwiftUI state updates may race during rapid repeated taps. → Mitigate by cancelling in-flight marker and rolling tasks before starting a new sequence.
- [Risk] UI tests can observe final state more reliably than intermediate animation frames. → Mitigate with existing render/drag assertions and focused unit/presentation coverage where deterministic behavior exists.
- [Risk] Additional view-local state increases complexity in the hero view. → Keep it private to the affected components and avoid touching the domain model.
