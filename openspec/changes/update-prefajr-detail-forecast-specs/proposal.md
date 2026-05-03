## Why

The attached Subh specs update the MVP morning surfaces around a clearer `Pre-Fajr | Fajr | Quiet` model, with Pre-Fajr defaulting to Tahajjud-only outside Ramadan and Next 10 Mornings becoming supporting context instead of a permanently expanded list.

This change tightens the product around the Fajr-centered morning engine by aligning Home, the selected-day detail view, and the ten-day forecast to one date-specific wake-mode contract without changing prayer-time calculation or delivery semantics.

## What Changes

- Rename the visible quick wake mode from `Fast` / `Early` to `Pre-Fajr` across the Home hero and Alarm Detailed View.
- Keep the existing internal quick wake mode as the Pre-Fajr mode where practical, but change its default non-Ramadan intention from fasting to `Tahajjud only`.
- Preserve Ramadan as locked `Pre-Fajr` + `Fasting` + `Ramadan fast`, and preserve Eid/forbidden fasting behavior as non-fasting Pre-Fajr where supported by the current domain.
- Update Alarm Detailed View copy, controls, and reset action to match v6: plain Pre-Fajr wording, `Tahajjud only | Fasting`, opportunity-aware sentences, eligible Fajr adhan toggle only, and prominent `Reset to Defaults`.
- Make `Next 10 Mornings` collapsed by default on Home with the `NEXT 10 MORNINGS` header visible and rows shown only after expansion.
- Update tests for shared resolver semantics, presentation labels/copy, detail context behavior, and forecast collapse/header/tag behavior.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Home hero, Alarm Detailed View, and Next 10 Mornings visible behavior now follow the attached v1.3/v6/v4 surface contracts.
- `morning-resolution`: Date-specific quick wake mode selection now resolves Pre-Fajr default intention, Ramadan lock, Quiet suppression, and audio-state separation according to the attached specs.

## Impact

- Affected SwiftUI surfaces: `Subh/Features/Home/SubhHomeView.swift`, `Subh/Features/Home/MorningHomePresentation.swift`, and `Subh/Features/Alarms/AlarmDayDetailView.swift`.
- Affected resolver/persistence logic: `Subh/Core/Morning/Models/MorningPlanModels.swift`, `Subh/Core/Morning/WakeStateSelectionResolver.swift`, `Subh/Core/Morning/MorningWakeResolutionService.swift`, and `Subh/Core/Services/ScheduleService.swift`.
- Affected tests: focused presentation/resolution coverage in `SubhTests/ScheduleServiceExtractionTests.swift` and manager persistence coverage in `SubhTests/ScheduleManagerHijriTests.swift`; UI tests may require label expectation updates.
- Existing scheduled alarms may be regenerated for a date only when the user changes that date's mode, purpose, wake time, audio toggle, or reset state. This change does not alter global alarm scheduling semantics, prayer-time calculation, Fajr begin/end calculation, onboarding, navigation architecture, or persisted storage namespaces.
