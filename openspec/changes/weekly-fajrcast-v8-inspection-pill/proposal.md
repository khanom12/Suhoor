## Why

The Weekly Fajrcast v8 specification adds one interaction refinement to the header date pill. The chart already supports temporary inspection during scrub; the pill now needs to participate by showing the inspected day's date while the interaction is active, then returning to the anchored range on release.

## What Changes

- Keep the header date pill in its existing top-right capsule and visual style.
- Show the anchored seven-day Gregorian + Hijri range while the card is at rest.
- During chart touch/drag/scrub or accessible day adjustment, show the currently inspected day's Gregorian + Hijri single-date text.
- Restore the anchored range pill text when touch inspection ends and the card snaps back.
- Preserve the v7 compact spacing, chart geometry, visible seven-day window, y-axis scale, static overlay, footer behavior, and alarm/data logic.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast header date pill behavior changes during active inspection.

## Impact

- Affected code:
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, chart scale, footer text generation, or alarm delivery behavior are changed.
- This is a scoped Weekly Fajrcast interaction refinement only.
