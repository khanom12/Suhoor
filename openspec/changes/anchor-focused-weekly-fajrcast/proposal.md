# Anchor Focused Weekly Fajrcast

## Summary

Implement the Weekly Fajrcast v2 interaction model from `/Users/omar/Downloads/Weekly_Fajrcast_Card_Specification_v2.md`: separate the card's centered anchor day from the currently focused day, so tapping or scrubbing visible columns updates the callout/footer/marker emphasis without moving, panning, or recentering the seven-day window.

## Problem

The current implementation from the prior iteration centers the selected day and rebuilds the visible seven-day window every time the user selects another day. The v2 spec changes the model:

- the anchor day defines the fixed seven visible dates
- the focused day is the visible day the user is inspecting
- on first load, focus normally equals anchor
- chart interaction changes focus only
- the week pill, x-axis days, Fajr band, and visible date range remain anchored during scrub

Without this split, a simple chart scrub changes the user's spatial context, making the card feel like a moving forecast instead of a stable seven-day Fajr context window.

## Scope

In scope:

- Add an explicit compact snapshot anchor date key.
- Preserve next-relevant-morning anchor resolution.
- Let compact snapshots take both an anchor date and focused date.
- Keep visible days fixed as anchor minus 3 through anchor plus 3.
- Update home/card interaction so chart selection changes focus only.
- Keep detail opening on the currently focused day while preserving existing route behavior.
- Update accessibility language from selected-day to focused-day where relevant.
- Add tests proving focus can move to another visible column without changing the anchored date window.
- Document v2 requirements in OpenSpec.

Out of scope:

- Adding a new detail route payload with both anchor and focused day; v2 leaves the detail destination as an open item.
- Introducing new no-alarm/quiet marker domain states beyond states currently represented by the morning engine.
- Redesigning the full Fajrcast detail screen.
- Moving the card to a separate Wake tab; current repository architecture renders it on the single Subh home surface.

## Product Notes

The product language now treats Weekly Fajrcast as an anchored context card:

- **Anchor day**: the center day that defines the seven visible columns.
- **Focused day**: the day currently emphasized by callout, guide, marker treatment, footer, and accessibility summary.

This preserves the mental map while letting the user inspect nearby mornings.

## Product Changelist

- Replaces the previous selection-as-recentering behavior with a fixed anchor plus movable focus.
- Keeps the week pill, visible weekday columns, x-axis labels, and Fajr band stable while the user taps or scrubs visible days.
- Updates the selected-day language in interaction and accessibility surfaces to focused-day language where that is the product meaning.
- Keeps the footer tied to the focused morning, including the mandatory Fajr begin/end line and the optional wake/off relation.
- Documents no-alarm and quiet-hours marker states as a future data-contract expansion until the morning engine exposes those states distinctly.

## Validation

- OpenSpec strict validation.
- Focused schedule/provider tests for anchor/focus separation and footer behavior.
- Xcode focused test run for `ScheduleServiceExtractionTests`.
- `git diff --check`.
