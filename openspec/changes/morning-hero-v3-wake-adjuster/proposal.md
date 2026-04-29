## Why

The v0.3 Morning Hero needs to remain the immediate answer for the next Fajr-centered morning while letting the user adjust the most immediate wake time directly from that context. This solves a concrete setup friction problem: changing tomorrow's wake should feel like adjusting the resolved morning, not hunting through a generic alarm editor.

## What Changes

- Update the hero date row to use full Gregorian and full Hijri month names by default, without weekday text or compact Hijri tokens.
- Reduce the gap between the relative day label and the primary wake row to the v0.3 target.
- Update the Fajr window visual to show endpoint circles and use an alarm icon as the active wake indicator.
- Hide the Fajr window visual for fasting days and for wake anchors outside the Fajr begin/end window.
- Make eligible active within-Fajr hero wake indicators draggable.
- During drag, update the large wake time and relation line locally from the tentative wake time.
- On release, persist the updated wake time as a date-specific override for the target morning, then let the resolved snapshot reconcile through the existing schedule engine.
- Keep missing Fajr data, no-alarm, quiet, and unavailable states truthful without invented marker positions.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `single-screen-morning-home`: The Morning Hero moves from the v0.2 static range visual to the v0.3 full-date, conditional, interactive within-Fajr wake adjuster.
- `morning-resolution`: The most immediate hero wake adjustment SHALL persist as a date-specific wake override and re-resolve through the existing morning engine.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - `Subh/Core/Services/ScheduleService.swift`
  - `Subh/Core/Services/AlarmConfigStore.swift`
  - Focused tests under `SubhTests/`
- Existing scheduled alarms for unrelated days must not be cancelled or rewritten.
- Persisted default wake settings are not migrated or changed.
- The immediate adjusted morning may update its date-specific override and require schedule refresh/rescheduling for that morning through existing mechanisms.
- No new production dependency is introduced.
