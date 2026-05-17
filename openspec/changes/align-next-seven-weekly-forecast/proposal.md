## Why

The attached Next 7 Days / Weekly Fajrcast specs retire the active `Next 10 Mornings` Home forecast and replace it with a tighter seven-day support surface. This keeps Home centered on the next resolved morning while making the list forecast and Weekly Fajrcast describe the same upcoming week.

## What Changes

- Rename the user-visible Home forecast surface from `NEXT 10 MORNINGS` / `Next 10 Mornings` to `NEXT 7 DAYS` / `Next 7 Days`.
- Limit the expanded Home forecast to exactly seven resolved rows when ready.
- Start the seven-day forecast at the next immediate alarm or next relevant morning supplied by the existing resolver, including today when today's relevant wake is still upcoming.
- Build the compact Weekly Fajrcast from the same first visible date plus six following mornings instead of centering the chart around the selected day with previous mornings.
- Keep forecast expansion, Fajrcast inspection, and row/detail routing presentation-only; they do not create durable intentions, mutate wake state, or schedule all seven visible dates.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Home support surfaces now use a shared Next 7 Days / Weekly Fajrcast date window instead of a ten-row Morningcast list and centered weekly chart.

## Impact

- Affected code: `Subh/Features/Home/MorningHomeSnapshot.swift`, `Subh/Features/Home/MorningHomePresentation.swift`, `Subh/Features/Home/SubhHomeView.swift`, `Subh/Core/Services/ScheduleService.swift`, and focused presentation/schedule tests.
- No production dependencies are added.
- Existing scheduled alarms, cached schedules, user settings, and stored overrides are not migrated or rewritten by this change.
- Alarm delivery scope is unchanged: visible forecast days are display context only unless the canonical active scheduled window materializes an event for delivery.
