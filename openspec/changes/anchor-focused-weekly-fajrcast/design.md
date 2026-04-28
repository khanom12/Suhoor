# Design: Anchor/Focused Weekly Fajrcast

## Current State

`ScheduleManager.fajrWindowCompactSnapshot(selectedDateKey:)` currently treats the selected date as the center of the compact seven-day window. `SubhHomeView` stores the interacted date and asks the schedule manager to rebuild the compact snapshot around that date. This means every tap/scrub recenters the chart.

The v2 spec instead makes the chart window anchored. Interaction changes focus inside the existing window.

## Data Model

Add `anchorDateKey` to `FajrWindowCompactSnapshot`.

Existing fields keep their current roles with clarified semantics:

- `anchorDateKey`: center day of the visible seven-day window.
- `chart.points`: the anchored seven visible days, ordered `anchor - 3` through `anchor + 3`.
- `chart.selectedDateKey`: focused day key.
- `selectedDay`: focused-day callout/accessibility snapshot.
- `summary.primaryText`: focused-day Fajr begin/end line.
- `summary.secondaryText`: focused-day alarm/off relation.

This avoids a broader model rename while aligning behavior with v2.

## Schedule Manager

Replace the compact API with anchor/focus inputs:

```swift
fajrWindowCompactSnapshot(
    anchorDateKey: String? = nil,
    focusedDateKey: String? = nil,
    timeZone: TimeZone = .current
)
```

Resolution rules:

1. Resolve anchor date from `anchorDateKey`, or next-relevant-morning default when nil.
2. Generate visible days from `anchor - 3` through `anchor + 3`.
3. Resolve focus:
   - use `focusedDateKey` if it exists in the anchored visible days
   - otherwise use the anchor date key
4. Build the compact snapshot using the anchored dataset and focused key.

## Home Interaction

`SubhHomeView` stores only a focused compact date key for in-card interaction. The anchor remains the snapshot's anchor date key unless an external schedule rebuild changes it.

- Chart tap/scrub sets focused key.
- The card redraws from the same anchor with the new focus.
- Accessible increment/decrement moves focus within the current seven visible days and clamps at the edges.
- Detail opening still uses the focused date because the v2 detail payload contract is deliberately open.

## Renderer

No renderer should infer prayer times or marker times. This change does not introduce new marker policy states because the current domain still always supplies a `primaryWake` for resolved days and represents disabled days as `isSkipped`. The v2 no-alarm/quiet marker policies remain documented as future data-contract expansion until the morning engine exposes those states distinctly.

## Testing

Tests should verify:

- compact snapshots expose the anchor key separately from focused key
- focusing a non-center visible day keeps the seven visible days unchanged
- focused footer/callout update to that non-center day
- centered default still uses anchor as focus
- OpenSpec stays valid
