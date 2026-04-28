## Why

The Weekly Fajrcast v5 specification tightens the compact card's readability contract after the v4 snap-back work. The current implementation still carries v4 plot height and footer hierarchy choices that make the chart feel heavier than intended and make the secondary footer line visually recede.

## What Changes

- Tune the Weekly Fajrcast seven-stop layout guardrails to the v5 card and chart sizes.
- Restore the standard plotted scale height to 150 pt across the seven standard Dynamic Type stops while preserving taller accessibility layouts.
- Add explicit x-axis-to-footer-divider breathing space so weekday labels do not feel glued to the bottom divider.
- Make footer primary and secondary text use the same regular weight, base size, and full-opacity white treatment.
- Preserve existing snap-back, static overlay, centered seven-day window, and y-axis trailing alignment behavior from the v4 change.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact-card sizing, chart breathing space, and footer visual hierarchy are updated to match the v5 card specification.

## Impact

- Affected code:
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
  - `Subh/Features/Wake/FajrWindowChartView.swift`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, or alarm reliability behavior are changed.
- This is a presentation-layer refinement of an existing Wake/Home compact forecast surface.
