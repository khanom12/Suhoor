## Why

The home screen still has three trust and clarity issues: compact Fajrcast can show an expired calendar week on Sunday night, the 10-day forecast omits tomorrow even though users expect the next alarm there, and settings inherits the warm home image background. This change keeps the home calm while making the forecast surfaces forward-looking and settings readable.

## What Changes

- Change the compact home Fajrcast to use a rolling 7-day window starting tomorrow.
- Include tomorrow as the first 10-day forecast row.
- Rename Morningcast to `10-Day Wake Forecast` and move its header inside the glass card.
- Remove the redundant floating Fajrcast/calendar shortcut and keep only a white-glass settings button.
- Give settings a neutral sheet background and remove orange warning badge styling.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: Home forecast surfaces start with the next relevant morning and avoid redundant controls.
- `subh-rename-compatibility`: Settings and home support Subh's calm, high-contrast presentation without legacy/warm visual drift.

## Impact

- Affects home snapshot construction, compact Fajrcast source window, home forecast presentation, settings chrome, warning badge styling, and focused presentation/snapshot tests.
- Does not change wake resolution, scheduling, AlarmKit behavior, persisted storage, compatibility keys, or bundle identity.
