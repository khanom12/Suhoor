## Why

The Weekly Fajrcast v7 specification makes a final compact-spacing correction after v6: the graph still reads too tall, and the callout spacing is too open for the card's intended compact forecast role.

## What Changes

- Reduce the standard compact plotted y-axis scale target from 144 pt to 128 pt.
- Update the seven standard Dynamic Type card and chart guardrails to the v7 values.
- Halve the focused callout's top and bottom breathing space so it remains balanced but compact.
- Add a small plot-to-x-axis label gap so weekday labels do not touch the lower plot boundary.
- Preserve the existing x-axis-to-footer spacing, y-axis right alignment, centered seven-day window, snap-back behavior, and focused footer-context behavior.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact chart sizing and internal spacing are updated to match the v7 specification.

## Impact

- Affected code:
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
  - `Subh/Features/Wake/FajrWindowChartView.swift`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, footer data behavior, or alarm delivery behavior are changed.
- This is a scoped Weekly Fajrcast presentation refinement only.
