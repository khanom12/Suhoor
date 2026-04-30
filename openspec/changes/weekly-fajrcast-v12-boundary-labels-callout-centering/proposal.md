## Why

The Weekly Fajrcast v12 spec tightens two visual details that affect the card's precision: the in-chart Fajr boundary labels should feel attached to the sloped boundary lines, and the bottom focused-day callout should sit evenly between the lower plot boundary and footer divider. These are small refinements, but they protect the premium forecast feel of the Wake signature card.

## What Changes

- Rotate the `Fajr begins` and `Fajr ends` labels from the rendered local boundary tangent instead of using flat or decorative label angles.
- Offset the boundary labels outward from their respective lines using the boundary normal so they remain attached to the line without covering the band.
- Recompute compact chart callout placement from the plot-bottom and chart/footer boundary pocket so the measured callout block is geometrically centered.
- Preserve the v11 Fajr trend footer, Gregorian pill, scrub/snap-back, y-axis, and snapshot behavior.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact chart label alignment and bottom callout centering requirements are refined for v12.

## Impact

- Affected SwiftUI presentation: `Subh/Features/Wake/FajrWindowChartView.swift`.
- OpenSpec docs and focused tests/validation only; no persistence, scheduling, alarm delivery, cached schedule, or migration behavior changes.
