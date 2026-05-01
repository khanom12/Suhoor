## Why

The Weekly Fajrcast v15 specification brings the compact card closer to the Home surface family. The card should visually harmonize with Next 10 Mornings, show richer Gregorian inspection pill text, respond live to the Morning Hero wake slider, and keep the in-chart Fajr labels clear of markers and plot boundaries.

## What Changes

- Align the Weekly Fajrcast outer shell, dividers, content grid, and header title style with the Next 10 Mornings grouped card family.
- Keep the compact header pill Gregorian-only, fixed width, and stable across rest and scrub states.
- Show weekday plus Gregorian date in the pill during active inspection/scrub, then return to the anchored week range on release.
- Propagate provisional Morning Hero wake-time slider changes into the Weekly Fajrcast snapshot so markers, callout, y-axis scale, and label geometry update before commit.
- Refine compact Fajr boundary label side/placement logic to account for left-side marker collisions as well as pre-Fajr wake patterns.

## Capabilities

### New Capabilities

- Weekly Fajrcast live wake preview from the Home hero slider.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast shared surface styling, header/pill behavior, live preview behavior, and Fajr boundary-label placement rules are refined for v15.

## Impact

- Affected presentation: `Subh/Features/Wake/FajrWindowCompactCard.swift`, `Subh/Features/Wake/FajrWindowChartView.swift`, `Subh/Features/Home/SubhHomeView.swift`.
- Affected compact snapshot/data projection: `Subh/Core/FajrWindowSurfaceModels.swift`, `Subh/Core/Services/FajrWindowSurfaceProvider.swift`, `Subh/Core/Services/ScheduleService.swift`.
- Tests should cover live preview snapshot behavior and the fixed Gregorian pill/geometry helper rules where practical.
- No alarm persistence, scheduling delivery, permission, notification, or prayer-time calculation behavior should change.
