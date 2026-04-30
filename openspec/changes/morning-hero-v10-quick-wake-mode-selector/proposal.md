# Morning Hero v1.0 Quick Wake-Mode Selector

## Summary
Add the v1.0 Morning Hero quick wake-state selector so the user can choose the target morning's `Fast`, `Fajr`, or `Quiet` state directly from the hero.

## Motivation
The hero currently explains the next wake and supports wake-time dragging, but it does not provide a fast way to choose the target morning's mode. The v1.0 spec requires a calm liquid-glass segmented selector that updates the hero, Weekly Fajrcast, next 10 mornings, and scheduling through one shared wake-state path.

## Scope
- Add a canonical target-morning quick wake-mode selection to daily wake resolution.
- Persist hero selections as single-date overrides only.
- Route `Fast`, `Fajr`, and `Quiet` selections through `ScheduleManager`, active-day rebuilds, and existing scheduling reconciliation.
- Render a three-segment liquid-glass selector in the Morning Hero.
- Update hero, Weekly Fajrcast, and next-ten morning presentation behavior for selected `Fast`, `Fajr`, and `Quiet`.
- Add focused tests for resolver, presentation, persistence/scheduling, and UI rendering.

## Non-Goals
- Do not add recurring wake-mode defaults.
- Do not add a fourth Tahajjud segment.
- Do not create a second alarm engine or view-owned scheduler.
- Do not reintroduce the hidden date row.
- Do not change prayer-time calculation methods.
