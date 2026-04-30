## Why

The Weekly Fajrcast v10 specification makes a larger card-grammar change: the compact card should read less like a focused-day text readout and more like a visual weekly Fajr forecast. The chart should carry the focused-day Fajr context through top weekday labels, in-chart Fajr boundary labels, and a bottom focused-day callout, while the footer becomes a stable week-level context summary.

The header pill also needs to become a Gregorian-only, fixed-width date descriptor so it remains stable during scrub and no longer mixes compact Hijri text into the top-right metadata pill.

## What Changes

- Make the compact header date pill Gregorian-only:
  - resting mode uses a full-month seven-day Gregorian range
  - active inspection mode uses the focused single Gregorian date
  - the capsule width is based on a stable longest Gregorian reference string rather than the current week's content
- Rework compact chart vertical order:
  - weekday initials move above the plot
  - the focused-day callout moves below the plot
  - the plotted scale remains at the current 128 pt standard target
  - v10 spacing rules are applied between top divider, x-axis labels, plot, bottom callout, and footer divider
- Add readable in-chart `Fajr begins` and `Fajr ends` labels near the left/past side of the compact plot.
- Change compact footer text to anchored week-level summaries:
  - line 1 summarizes default alarm, adjusted mornings, or no wake-alarm context
  - line 2 summarizes non-Ramadan fasting plans or ordinary no-fasting context when useful
  - the footer no longer changes during scrub and no longer shows focused-day Fajr begin/end sentences
- Preserve focused-day callout behavior, selected guide/marker alignment, seven-day centered window, snap-back interaction, and accessibility-focused Fajr begin/end wording.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact header, chart layout, in-chart labels, footer summary, and accessibility behavior are updated to match the v10 specification.

## Impact

- Affected code:
  - `Subh/Core/Services/FajrWindowSurfaceProvider.swift`
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
  - `Subh/Features/Wake/FajrWindowChartView.swift`
  - `SubhTests/ScheduleServiceExtractionTests.swift`
- No persisted settings, schedule storage, notification identifiers, alarm scheduling behavior, prayer-time calculation methods, or detail-view period behavior are changed.
- The implementation keeps the existing compact snapshot shape and reinterprets `summary` as the v10 week-level footer payload to avoid broad model churn in this pass.
