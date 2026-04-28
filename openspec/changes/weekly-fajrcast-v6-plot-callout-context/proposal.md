## Why

The Weekly Fajrcast v6 specification refines the compact chart after the v5 spacing pass: the plotted y-axis scale should be a little shorter, the focused callout needs balanced breathing room above the plot, and footer secondary text must explicitly represent the focused day's strongest context/status.

## What Changes

- Reduce the standard compact plotted y-axis scale target from 150 pt to 144 pt.
- Preserve the existing seven-stop card, chart-region, and y-axis rail guardrails while allowing measured chart height to grow when callout spacing requires it.
- Add balanced top callout-to-plot spacing so the focused alarm/status block does not sit tight against the plot boundary.
- Preserve v5 x-axis-to-footer breathing and full-opacity footer treatment.
- Document and verify that footer secondary copy is precomposed from the focused day's context/status, including adjusted and fasting contexts where the existing model can express them.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact-card plot height, focused-callout spacing, and focused-day contextual footer requirements are updated to match the v6 card specification.

## Impact

- Affected code:
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
  - `Subh/Features/Wake/FajrWindowChartView.swift`
  - `Subh/Core/Services/FajrWindowSurfaceProvider.swift`
  - `SubhTests/ScheduleServiceExtractionTests.swift`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, or alarm delivery behavior are changed.
- This is a compact forecast presentation and snapshot-copy refinement.
