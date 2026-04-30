## Why

The Weekly Fajrcast v13 spec tightens the in-chart `Fajr begins` and `Fajr ends` label placement. The labels should read as native boundary annotations near the left side of the plot, angled with their rendered Fajr boundary lines, but not printed directly on top of those lines or chart edges. The current v12 implementation follows the boundary tangent, but its offset is baseline-oriented and does not account for the rotated label box.

## What Changes

- Preserve the existing anchored seven-day Weekly Fajrcast chart, scrub/snap-back behavior, top weekday labels, bottom callout, y-axis rail, and footer semantics.
- Refine the Fajr boundary label geometry so boundary clearance is computed from the rotated label box instead of only from the text baseline.
- Keep labels near the leading/past side while maintaining left, top, and bottom plot-edge clearance.
- Place `Fajr begins` above its boundary by default, but move it below the begin line when the resting/weekly wake pattern is before Fajr begins.
- Keep `Fajr ends` below the end line in normal states.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact chart Fajr boundary label positioning is refined for v13.

## Impact

- Affected SwiftUI presentation: `Subh/Features/Wake/FajrWindowChartView.swift`.
- OpenSpec documentation and focused validation only.
- No persistence, alarm delivery, scheduling, prayer-time calculation, or snapshot-generation behavior changes.
