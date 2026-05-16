## Why

The P0/P1 spec-to-code audit identified a product-model drift: older specs and code paths still treated before-Fajr waking as `Pre-Fajr`, `Fast`, Tahajjud, or other early worship, while the MVP decision is to expose only Suhoor as the before-Fajr wake intent.

This retrospective change records the decision and implementation contract so the codebase, Desktop working specs, and OpenSpec history all point at one morning engine with `Suhoor | Fajr | Quiet` as the canonical MVP wake modes.

## What Changes

- Replace the visible MVP quick wake mode set with `Suhoor`, `Fajr`, and `Quiet`.
- Remove Tahajjud-only and other early-worship choices from MVP surfaces and resolution behavior.
- Treat Suhoor as the only MVP reason for waking before Fajr begins.
- Preserve fasting-intention logic inside Suhoor: default to the relevant Sunnah opportunity when one exists, otherwise use voluntary fasting, while allowing supported fasting-intention overrides.
- Normalize legacy persisted quick-wake values such as `Fast`, `Pre-Fajr`, and `Early` into Suhoor-compatible state instead of creating a parallel engine.
- Keep Alarm Detail selection and reset behavior immediate, matching the implemented code path rather than a staged-until-done interaction.
- Update Home, Alarm Detail, Fajr Window, Next 10, Weekly Fajrcast, tests, and device-QA documentation to use the Suhoor vocabulary.
- Add simulator-test evidence that scheduled event fire dates are handed off correctly; physical-device alarm reliability QA remains a manual follow-up.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `morning-resolution`: Date-specific wake resolution now uses Suhoor as the only MVP before-Fajr mode, removes Tahajjud/other-early-worship from exposed MVP behavior, and keeps Quiet as the only alarm-off mode.
- `single-screen-morning-home`: Home, Alarm Detail, Fajr Window, Next 10, and Weekly Fajrcast surfaces now expose Suhoor/Fajr/Quiet language and immediate Alarm Detail persistence.

## Impact

- Affected Swift domain and persistence code: `Subh/Core/Morning/Models/MorningPlanModels.swift`, `Subh/Core/Morning/Models/MorningContextModels.swift`, `Subh/Core/Morning/WakeStateSelectionResolver.swift`, `Subh/Core/Morning/MorningWakeResolutionService.swift`, `Subh/Core/Morning/Planning/MorningPlanResolver.swift`, `Subh/Core/Scheduling/MorningResolver.swift`, and `Subh/Core/Services/ScheduleService.swift`.
- Affected SwiftUI and presentation surfaces: `Subh/Features/Home/SubhHomeView.swift`, `Subh/Features/Home/MorningHomePresentation.swift`, `Subh/Features/Alarms/AlarmDayDetailView.swift`, `Subh/Features/Wake/FajrWindowDetailView.swift`, and related support models.
- Affected tests: `SubhTests/ScheduleManagerHijriTests.swift` and `SubhTests/ScheduleServiceExtractionTests.swift`.
- Affected docs: `/Users/omar/Desktop/Subh Working Specification/` canonical specs and `docs/alarm-delivery-device-qa.md`.
- Existing saved legacy values are compatible through decode normalization. This change does not rename storage namespaces, alter Fajr calculation methods, or claim physical-device AlarmKit reliability has been fully verified.
