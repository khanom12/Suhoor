## Why

Subh needs to distinguish what a date means from what the user intends, what the app schedules, what the user actually logs, and what future analytics may count. Optional Sunnah observance opportunities can exist on a day without becoming an active fast plan, alarm escalation, missed action, or completion credit.

## What Changes

- Add a resolved day-purpose layer that separates observance opportunities, user intention, wake classification, required actions, and analytics credits.
- Treat optional Sunnah meanings as opportunities unless the user selects or inherits a fast intention for that date.
- Treat Ramadan as an auto-obligatory fast context unless a future suppression or exception policy applies.
- Treat qada as a primary user-selected intention that does not automatically credit secondary Sunnah opportunities.
- Adapt existing `fastTagSelections` as the MVP source of fast intentions without requiring a persistence migration.
- Keep existing Fajr/prayer-time calculation, wake-rule resolution, alarm materialization, cached schedule invalidation, and user settings behavior intact.

## Capabilities

### New Capabilities

- `morning-day-purpose-resolution`: Resolves each date into observance opportunities, user intention, wake classification, required actions, and analytics credits.

### Modified Capabilities

- `morning-resolution`: Resolved morning snapshots expose the day-purpose aggregate alongside existing context, plan, event, and completion data.

## Impact

- Affected code:
  - `Subh/Core/Morning/Models/ResolvedDaySnapshot.swift`
  - New purpose models and resolvers under `Subh/Core/Morning/`
  - `Subh/Core/Scheduling/MorningResolver.swift`
  - Focused XCTest coverage under `SubhTests/`
- No prayer-time calculation behavior changes.
- No existing scheduled alarm, schedule cache, or persisted wake-setting migration behavior changes.
- No new production dependency.
