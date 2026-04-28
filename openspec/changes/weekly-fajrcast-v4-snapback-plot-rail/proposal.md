## Why

The v4 Weekly Fajrcast specification changes chart interaction from persistent focused-day selection to temporary inspection that snaps back to the next-alarm/resting morning. It also addresses visual issues in the compact chart: the plot scale is too short, the y-axis labels need fixed right alignment, and the past/elapsed overlay must remain anchored while the user scrubs.

## What Changes

- Change compact chart interaction so tapping, pressing, or scrubbing temporarily inspects a visible day.
- On touch release, return the focused guide, callout, marker emphasis, footer, and accessibility value to the snap-back target, normally the centered anchor day.
- Keep the visible seven-day window, week pill, x-axis, y-axis scale, Fajr band, and static elapsed overlay unchanged during inspection.
- Increase the compact chart/card sizing guardrails to the v4 minimums, including a 160 pt static plot scale height.
- Right-align all compact y-axis labels to the content boundary while the y-axis rail expands leftward as text grows.
- Keep static past/elapsed overlay anchored to the resting focus boundary rather than the inspected day.
- Add tests for snap-back behavior and preserve existing focused-day footer tense tests.

## Capabilities

### New Capabilities

- `weekly-fajrcast-v4`: Covers v4 compact Weekly Fajrcast behavior for temporary inspection, snap-back focus, static elapsed overlay, taller plot height, and y-axis rail alignment.

### Modified Capabilities

- `single-screen-morning-home`: The home Weekly Fajrcast card now treats chart interaction as temporary inspection and snaps back to the resting next-alarm focus when interaction ends.

## Impact

- Affected UI: `Subh/Features/Wake/FajrWindowCompactCard.swift`, `Subh/Features/Wake/FajrWindowChartView.swift`, and `Subh/Features/Home/SubhHomeView.swift`.
- Affected models/presentation: compact Fajrcast snapshot/chart parameters may receive a snap-back/resting focus key for rendering static overlays.
- Affected tests: `SubhTests/ScheduleServiceExtractionTests.swift` and lightweight view/presentation tests if needed.
- No persistence migration.
- No alarm scheduling changes.
