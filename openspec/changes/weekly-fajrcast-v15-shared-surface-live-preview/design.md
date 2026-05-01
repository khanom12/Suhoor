## Overview

This change keeps the Weekly Fajrcast card chart-first, but aligns the card chrome with the Next 10 Mornings Wake Forecast family. The renderer remains responsible only for presentation geometry; the data layer remains responsible for resolved dates, Fajr boundaries, wake times, footer copy, and provisional live wake values.

## Shared Card Surface

- Use `AppGlassSurface(variant: .grouped, contentPadding: 0)` without the older bespoke black tint multiplier.
- Align header/footer/divider horizontal padding with the same `DesignTokens.spacingL` grid used by Next 10 Mornings.
- Use `WakeGlassTheme.divider` for the two Weekly Fajrcast dividers.
- Style the title with the shared eyebrow role used by Next 10 Mornings: `.appTextRole(.eyebrow)` plus `WakeGlassTheme.tertiaryText`.

## Gregorian Pill

- The compact pill remains Gregorian-only.
- Resting mode shows the anchored seven-day range with full month names.
- Inspection mode shows the focused weekday plus full Gregorian date, such as `Saturday, May 2nd`.
- The pill width is measured from the widest relevant English reference strings and scales with Dynamic Type so the capsule does not resize while scrubbing.
- The renderer keeps the pill mode local to active inspection so release returns to the anchored range.

## Live Wake Preview

- Home owns temporary hero slider state while the user adjusts wake time.
- Home passes a `FajrWindowLiveWakeAdjustment` into `ScheduleManager.fajrWindowCompactSnapshot(...)` when the adjusted date is visible.
- `FajrWindowSurfaceProvider.compactSnapshot(...)` applies that live wake to the matching dataset row before projecting chart points and compact scale.
- The live adjustment updates the selected-day callout when the adjusted day is focused, marker positions for the matching visible day, compact y-axis scale, and rendered Fajr label geometry through normal chart recalculation.
- Persistence remains in the existing hero commit path; the compact card never saves provisional values.

## Fajr Boundary Label Placement

- Preserve v13 rotated-box boundary and plot-edge clearance.
- `Fajr begins` moves below the begin line when the resting wake pattern is pre-Fajr.
- `Fajr begins` also uses below-line placement when the default above-line placement would collide with the left-side marker lane.
- `Fajr ends` remains below in normal states.
- Labels remain anchored near the left/past side and do not move with scrub focus.

## Risks

- The card cannot perfectly measure post-render SwiftUI glyph outlines, so collision checks use deterministic rotated rectangle approximations.
- Live preview changes compact snapshot construction, so focused tests should assert the provisional wake affects only the intended visible date and does not recenter the seven-day window.
