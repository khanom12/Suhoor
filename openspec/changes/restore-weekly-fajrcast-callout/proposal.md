## Why

The compact Weekly Fajrcast selected-day callout drifted from the intended home-card contract: the chart axis carries weekday initials, while the overlay callout should identify the immediate morning as `TODAY` or `TOMORROW` when applicable. This matters because the card's job is low-friction morning clarity, not a generic week chart.

## What Changes

- Restore the compact selected-day callout label to relative wording for today and tomorrow.
- Preserve weekday initials on the compact x-axis and weekday naming in accessibility/detail context.
- Add focused test coverage so tomorrow selection remains explicit and the visible callout does not regress back to weekday-only text.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Clarifies the compact Weekly Fajrcast selected-day callout contract.

## Impact

- Affected code: `FajrWindowSurfaceProvider`, compact Fajrcast presentation tests, and this OpenSpec change bundle.
- No scheduling, alarm delivery, calculation, persistence, cache, dependency, or migration behavior changes.
