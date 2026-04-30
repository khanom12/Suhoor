## Context

The current Morning Hero already resolves `Fast`, `Fajr`, and `Quiet` through the shared wake-state path and renders the segmented selector below the relation line. The v1.1 spec keeps that data flow intact, but requires the visual state changes to animate smoothly and remain layout-stable, especially when entering or leaving Quiet.

The implementation should stay in the home presentation/view layer:

- `MorningHomePresentation` continues to provide resolved text, visual mode, marker ratio, selected quick mode, and accessibility content.
- `TomorrowMorningHero` owns transient UI state needed to animate from the previous resolved display to the next resolved display.
- `ScheduleManager` remains the owner of quick-mode persistence and scheduling side effects.

## Goals / Non-Goals

**Goals:**

- Make the segmented selected highlight glide as one moving treatment rather than redrawing three independent buttons.
- Animate primary wake text, relation text, boundary labels, range row, and marker changes when the selected quick mode changes.
- Preserve a stable primary row and range-row footprint so `Quiet mode on` does not collapse the hero stack.
- Use direction-aware marker transitions for `Fajr -> Fast` and `Fast -> Fajr`.
- Respect Reduce Motion with short crossfades and minimal physical travel.
- Keep UI tests able to verify the selector remains tappable and the hero state updates.

**Non-Goals:**

- Do not change quick-mode persistence, alarm scheduling, prayer-time calculation, or default wake offsets.
- Do not add a new animation framework or dependency.
- Do not introduce a Tahajjud segment.
- Do not reintroduce the hidden Gregorian/Hijri date row.

## Decisions

### Use SwiftUI transitions inside the existing hero component

Use `withAnimation`, `transition`, `animation(value:)`, and `@Namespace`/`matchedGeometryEffect` where useful inside `SubhHomeView.swift`. This keeps the motion local to the visual layer and avoids changing the snapshot/resolver contract.

Alternative considered: introduce animation state into `MorningHomeHeroDisplay`. Rejected because the presentation model should describe resolved state, not view-transition mechanics.

### Preserve row footprint with stable frames

The primary row should use a stable minimum height based on the large wake time token so `Quiet mode on` occupies the same slot as the wake time. The range visual should keep its row height stable across interactive/default/static modes when data is present.

Alternative considered: rely on natural SwiftUI stack sizing. Rejected because the v1.1 spec explicitly forbids a vertical jump when Quiet replaces the large time.

### Animate marker direction from mode transition context

Track the previous selected quick mode and derive a transition direction:

- `Fajr -> Fast`: earlier/leftward handoff.
- `Fast -> Fajr`: later/rightward handoff.
- Transitions to/from `Quiet`: fade marker out/in without drag affordance.

This uses resolved before/after display values; it does not invent prayer times or wake positions.

### Keep the selector's selected state authoritative

The selected segment remains driven by the resolver-returned display. The view may show pressed/disabled feedback while a selection is in flight, but it should not permanently commit a selected segment until the snapshot updates.

## Risks / Trade-offs

- [Risk] Snapshot refresh latency could make the selector feel delayed. -> Mitigation: keep the existing disabled/opacity feedback during selection and animate once the resolved display changes.
- [Risk] UI animation tests can be flaky if they assert exact intermediate frames. -> Mitigation: test final visible state and stable element presence, not frame-by-frame animation.
- [Risk] Directional marker transitions may be overdone. -> Mitigation: use restrained 300-380 ms animations and Reduce Motion crossfades.
- [Risk] Stable row frames can add too much vertical weight. -> Mitigation: use existing v1.1 dynamic type guardrails and only reserve the primary/range slots that are already part of normal eligible hero content.

## Migration Plan

No data migration is required. The change is a SwiftUI refinement on top of existing quick-mode state and scheduling behavior. Rollback is reverting the visual transition code; persisted quick-mode overrides remain compatible.

## Open Questions

- Whether a future design pass should add snapshot-level transition hints from the resolver. For v1.1, local view-derived transition direction is sufficient.
