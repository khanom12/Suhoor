## Why

The v3 Weekly Fajrcast specification tightens the card's truth contract: the fixed anchored window remains, but the focused day's footer, accessibility, sizing, and marker behavior need to be precise across past, current, future, large-text, and no-marker states. This matters because the card is becoming a product-level forecast surface rather than a decorative chart.

## What Changes

- Add focused-day temporal footer wording so past/completed mornings use `began`, `ended`, and `was`, while in-progress and future mornings use the correct tense.
- Preserve the v2 anchor/focus split while documenting the v3 rule that scrubbing changes focus only and never recenters or loads an eighth day.
- Expand compact-card dynamic sizing toward the v3 seven-stop guardrails for card height, chart height, y-axis rail width, callout width, and readable axis/callout/footer text.
- Keep marker rendering truthful: active and off-with-anchor states can plot; no-alarm, quiet, and unavailable marker states remain documented as data-contract expansion until the morning engine exposes them distinctly.
- Update tests for focused-day footer tense, past-day focus, and anchored-window stability.
- Document the v3 product changelist and implementation boundary in OpenSpec.

## Capabilities

### New Capabilities

- `weekly-fajrcast-v3`: Covers the v3 compact Weekly Fajrcast contract for temporal footer tense, anchor/focus behavior, dynamic sizing guardrails, and marker truthfulness.

### Modified Capabilities

- `single-screen-morning-home`: The home Weekly Fajrcast card behavior is refined so the focused-day footer/accessibility state uses the v3 temporal truth rules and the card scales more deliberately at larger text sizes.

## Impact

- Affected UI: `Subh/Features/Wake/FajrWindowCompactCard.swift`, `Subh/Features/Wake/FajrWindowChartView.swift`, and `Subh/Features/Home/SubhHomeView.swift`.
- Affected data/presentation layer: `Subh/Core/Services/FajrWindowSurfaceProvider.swift` and existing compact snapshot models.
- Affected tests: `SubhTests/ScheduleServiceExtractionTests.swift`.
- No new production dependency.
- No persistence migration.
- Existing scheduled alarms are not modified by this card presentation change.
