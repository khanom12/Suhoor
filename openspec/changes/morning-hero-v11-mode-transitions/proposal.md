## Why

The v1.1 Morning Hero spec refines the newly added `Fast | Fajr | Quiet` selector so mode changes feel intentional, directional, and stable instead of abrupt text and row swaps. This matters because the selector now changes the user's immediate wake plan from the hero, and the visual transition should reinforce trust in what changed.

## What Changes

- Animate quick-mode changes across the selected segment, primary wake row, wake-boundary visual, marker, boundary labels, and relation/status line.
- Preserve vertical stability when entering or leaving Quiet; `Quiet mode on` remains in the same primary row slot as the large wake time.
- Add directional adjuster transitions for `Fajr -> Fast` and `Fast -> Fajr` using the resolved before/after snapshots without inventing missing times.
- Refine the segmented selector glass treatment so it reads as one translucent liquid-glass control with a moving selected highlight.
- Respect Reduce Motion by replacing directional travel with short crossfades while keeping clear selected-state feedback.
- Preserve the existing shared resolver and scheduling pipeline; no local alarm creation, cancellation, or prayer-time calculation is added to SwiftUI.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Add v1.1 Morning Hero transition, selector, Quiet layout stability, and reduced-motion requirements.

## Impact

- Affected UI: `Subh/Features/Home/SubhHomeView.swift`, especially `TomorrowMorningHero`, `MorningHeroQuickWakeModeSelector`, and `FajrWindowRangeVisual`.
- Affected presentation contract/tests: `Subh/Features/Home/MorningHomePresentation.swift`, `SubhTests/ScheduleServiceExtractionTests.swift`, and `SubhUITests/MorningHeroFajrAdjusterUITests.swift`.
- No persistence migration is required.
- Existing scheduled alarms and cached schedule data are not changed by this refinement; quick-mode selections continue to route through the existing shared resolver and `ScheduleManager` intent.
