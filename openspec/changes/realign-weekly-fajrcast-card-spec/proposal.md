## Why

The compact Weekly Fajrcast card has drifted from the provided recreation specification in several visible and data-layer details: shell tinting, an extra chart context row, compact chart opacity values, inactive marker strength, inline interval labels, and footer summary semantics. This change restores the card as the wake-root signature visual described by the spec while preserving current app information architecture.

## What Changes

- Realign `WeeklyFajrcastCard` structure to the specified shell, header, divider, compact chart, divider, and footer sequence.
- Restore the explicit dark glass shell parameters for the card.
- Normalize compact chart color/opacity values, boundary band stroke, boundary line strength, marker strength, and inline interval label rendering.
- Generate the footer primary summary from the selected day using the specified `{Subject}'s alarm is {relation clause}.` template.
- Preserve secondary compact summary data for DST, adjusted, and fasting week signals without rendering it in the footer.
- Add focused tests for selected-day callout, footer summary, secondary summary, and compact chart scale/axis contract.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Refines the Weekly Fajrcast card contract for the currently rendered compact card.

## Impact

- Affected code: `FajrWindowCompactCard`, `FajrWindowChartView`, `FajrWindowSurfaceProvider`, and focused tests.
- No alarm scheduling, prayer-time calculation, persistence, cache migration, dependencies, or external services are changed.
- Placement remains the current single-home Fajrcast surface per existing OpenSpec; a separate Wake-primary placement would require an information-architecture spec update.
