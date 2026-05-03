## Overview

Implement the attached updated specs as a focused alignment of existing Home hero, selected-day detail, and Next 10 Mornings code. The implementation should reuse the existing shared wake-state resolver, date-specific override store, range visual, and presentation models rather than introducing a second detail-only wake engine.

## Relevant Code Areas

- Home hero UI and shared visual components: `Subh/Features/Home/SubhHomeView.swift`.
- Home hero and Next 10 presentation models/tag resolver: `Subh/Features/Home/MorningHomePresentation.swift`.
- Selected-day editor: `Subh/Features/Alarms/AlarmDayDetailView.swift`.
- Wake-mode enum and date-specific override models: `Subh/Core/Morning/Models/MorningPlanModels.swift`, `Subh/Core/Models/AlarmConfigModels.swift`.
- Wake-mode resolver and date-intent reducer: `Subh/Core/Morning/WakeStateSelectionResolver.swift`.
- Resolved wake state copy/boundary model: `Subh/Core/Morning/MorningWakeResolutionService.swift`.
- Persistence/rescheduling adapter: `Subh/Core/Services/ScheduleService.swift`.
- Tests: `SubhTests/ScheduleServiceExtractionTests.swift`, `SubhTests/ScheduleManagerHijriTests.swift`, `SubhUITests/MorningHeroFajrAdjusterUITests.swift`.

## Current Behavior

- The shared quick wake enum uses `.fast` internally and exposes `Fast` on the Home hero; the Alarm Detailed View remaps that mode to `Early`.
- Selecting the Pre-Fajr-equivalent mode currently applies a pre-Fajr wake and also defaults `earlyWakePurposeOverride` to `.fast`, so non-Ramadan Pre-Fajr appears as fasting unless the user changes purpose.
- Alarm Detailed View already has a hero-like surface, date line, slider, context card, purpose menu, fast-type menu, Fajr adhan toggle, and reset action, but several labels and sentences still use `Early`, `Fast`, or less prominent reset copy.
- Next 10 Mornings already has a dedicated tag resolver, compact chips, shared row metrics, and `NEXT 10 MORNINGS` title, but the card renders expanded by default.

## Required Behavior

- Home and detail quick selectors show exactly `Pre-Fajr | Fajr | Quiet` using the same order, shared resolver, and glass treatment.
- Selecting `Pre-Fajr` outside Ramadan defaults to `Tahajjud only`; selecting `Fasting` is an explicit date-specific intent. Ramadan returns to locked `Fasting` + `Ramadan fast` when Pre-Fajr is selected.
- Detail context copy uses `Pre-Fajr`, `Tahajjud only`, `Fasting`, opportunity chips, and Quiet copy from the v6 spec. It must not show `Use usual plan`, diagnostics, source, delivery, or reliability sections.
- `Fajr adhan at Fajr begins` appears only for non-Ramadan `Pre-Fajr` + `Fasting`; Fajr adhan as wake audio does not make the wake alarm off.
- `Reset to Defaults` appears prominently when the selected date has overrides.
- Next 10 Mornings is collapsed by default on Home with header visible; expanding/collapsing is UI-only and does not mutate wake state or scheduling.

## Delta

- Presentation label delta: `Fast` and `Early` must become `Pre-Fajr`; `Fast` purpose labels must become `Fasting`; `Tahajjud` must become `Tahajjud only` for the Pre-Fajr intention option.
- Resolver delta: the Pre-Fajr quick mode must no longer imply fasting outside Ramadan; it should store/restore Tahajjud-only by default unless the user explicitly selects Fasting.
- Detail copy delta: replace "waking early" and "choose Early" wording with mode-specific "waking before Fajr" and "choose Pre-Fajr" copy; keep opportunities visible in every mode.
- Forecast state delta: expanded list must be hidden until the user expands the card.

## Risk Areas

- Alarm reliability: any change that toggles `suhoorEnabled`, `fajrEnabled`, `skipDay`, or audio plan can reschedule date-specific events. Keep changes inside the existing reducer and `ScheduleService` rescheduling path.
- Date/time handling: do not change Fajr begin/end, final-third, timezone, DST, or Hijri calculations. Only consume existing resolved values.
- Fajr begin/end semantics: `Fajr` remains 30 minutes before Fajr ends; `Pre-Fajr` remains 30 minutes before Fajr begins.
- Fasting/Tahajjud behavior: Pre-Fajr defaulting to Tahajjud-only may change existing tests and any local overrides made by the current implementation. Preserve explicit fast type/audio overrides when returning from Quiet to Pre-Fajr.
- Persistence: all edits remain date-specific via `DailyAlarmOverride`; no global settings should be introduced.
- Dynamic Type/VoiceOver: keep existing measured hero metrics, stable primary row, adjustable slider accessibility, selector selected state, and row accessibility labels.
- Animations: preserve existing no-slide relation fade, time rolling, marker handoff, and reduced-motion fallbacks.

## Implementation Plan

1. Update visible labels and accessibility hints for `QuickWakeMode`, Alarm Detailed View mode remapping, purpose labels, and relevant relation/accessibility copy.
2. Update `MorningDateIntentReducer.selectWakeMode` so non-Ramadan Pre-Fajr defaults to Tahajjud-only, while Ramadan locks to fasting and Quiet restoration preserves prior explicit Pre-Fajr intention.
3. Update Alarm Detailed View context sentence/purpose/fast-type/reset presentation to match v6 copy and controls.
4. Add collapsed-by-default state and UI-only expansion to `NextTenMorningsCard` while preserving existing row/tag renderer.
5. Update focused tests, then run OpenSpec validation, targeted XCTest suites, and `git diff --check`.

## Non-Changes

- No prayer-time or Fajr-end calculation changes.
- No AlarmKit, notification delivery, onboarding, analytics, Progress/history, or navigation architecture changes.
- No new production dependencies.
