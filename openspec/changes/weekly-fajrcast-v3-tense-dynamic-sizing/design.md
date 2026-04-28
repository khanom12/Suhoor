## Context

The prior Weekly Fajrcast passes established the dark glass card, seven-day anchored window, and focus-without-recentering interaction. The v3 spec adds stronger requirements around temporal wording, dynamic measured sizing, marker truthfulness, and resolved-data ownership.

The current implementation already has a compact snapshot, chart snapshot, anchor date key, focused selected date key, and two-line footer. It still uses a mostly fixed set of Dynamic Type thresholds and the footer primary/secondary text always reads as future/current (`Fajr begins`, `alarm is`) even when the focused day is in the past.

## Goals / Non-Goals

**Goals:**

- Make the compact footer primary line tense-aware for focused past, in-progress, and future Fajr windows.
- Make the secondary wake/off sentence tense-aware for focused past versus current/future mornings.
- Keep chart interaction anchored: focus moves inside the same seven visible days.
- Improve dynamic layout guardrails with seven-stop minimums for card height, chart height, rail width, callout width, and readable typography.
- Preserve Fajr end as resolved schedule data rather than deriving it inside the renderer.
- Add focused tests around v3 temporal footer behavior.

**Non-Goals:**

- Introduce new morning-engine alarm states for no-alarm, quiet-hours, or unavailable marker policies.
- Redesign the full Fajrcast detail route or payload.
- Add a new navigation model or separate Wake tab.
- Replace SwiftUI text measurement with a custom layout engine in this pass.

## Decisions

1. **Resolve footer tense in `FajrWindowSurfaceProvider`.**
   - The provider already converts resolved schedule points into compact display strings. Keeping tense there prevents the SwiftUI renderer from guessing temporal state.
   - Alternative considered: calculate tense in `WeeklyFajrcastCard`. Rejected because the v3 spec says the renderer should prefer resolved footer strings and not infer prayer-time truth.

2. **Classify Fajr window state from focused point dates and injected `now`.**
   - If `now` is before focused Fajr begin, use future wording.
   - If `now` is between focused Fajr begin and end on the same local day, use in-progress wording.
   - If `now` is after focused Fajr end, or the focused date is a previous date, use completed/past wording.

3. **Keep marker policy bounded to current data.**
   - Current points always contain `primaryWake` and represent disabled days with `isSkipped`, which maps cleanly to active versus off-with-anchor.
   - No-alarm, quiet-hours, and unavailable no-marker states are documented as future data-contract work until the morning engine exposes them distinctly.

4. **Use Dynamic Type stop guardrails rather than a full custom measured layout.**
   - SwiftUI already measures and wraps text. This pass adds a compact layout profile derived from `DynamicTypeSize` with seven non-accessibility stops and accessibility continuation values.
   - Alternative considered: custom text measurement with UIKit for every label. Deferred because it would add complexity without changing the current product behavior enough to justify it.

## Risks / Trade-offs

- **Risk: Past-tense relation text misses rare relation phrases.** → Mitigation: normalize known Fajr-relative and fixed-time cases in tests; preserve fallback lowercasing.
- **Risk: Seven-stop sizing is still approximate because SwiftUI owns final layout.** → Mitigation: encode the spec guardrails as minimums and allow footer wrapping/card growth.
- **Risk: No-alarm/quiet requirements remain partially documentary.** → Mitigation: explicitly document the boundary and avoid rendering invented markers.
