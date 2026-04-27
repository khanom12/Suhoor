## Context

The home surface already uses `SubhHomeView`, `MorningHomeSnapshot`, `ScheduleManager.buildMorningHomeSnapshot`, `FajrWindowSurfaceProvider`, and existing wake-row presentation output. The current weather-style hero established the visual direction, but the information hierarchy still repeated "Tomorrow Morning / Tomorrow," surfaced ordinary/default context, and exposed provider diagnostics in the highest-value home real estate.

## Goals / Non-Goals

**Goals:**
- Make tomorrow the single primary home answer: date, wake time, meaningful status, and concise wake relationship.
- Keep calculation, scheduling, alarm, and permission behavior unchanged.
- Add a small presentation model so SwiftUI renders prepared display text instead of owning product-copy branching.
- Align Weekly Fajrcast and Morningcast to support tomorrow without repeating it.
- Preserve accessibility labels with enough detail for the compact visual rows.

**Non-Goals:**
- No change to Fajr start/end calculation, wake-resolution precedence, or AlarmKit scheduling.
- No new persistence, migration, analytics, or dependencies.
- No redesign of deeper day-detail, Fajr-window, settings, or alarm execution surfaces.

## Decisions

- Introduce `MorningHomePresentation` beside the home feature to prepare hero and compact Morningcast display models. This keeps copy selection testable and avoids embedding status heuristics inside `SubhHomeView`.
- Continue using `WakeRowEntry`, `ProductSurfacePresentation`, and existing row presentation chips as inputs. The new model filters redundant chip titles rather than creating a second context engine.
- Move Morningcast date filtering into `MorningHomeSnapshot` so the forward-looking list contract is available outside SwiftUI.
- Pass tomorrow's date key into `ScheduleManager.fajrWindowCompactSnapshot` so compact Fajrcast can default to tomorrow without changing the underlying Fajr window dataset.
- Change compact Fajrcast summary copy to prefer meaningful week-level signals and otherwise show a neutral fallback, avoiding duplicate wake-relationship copy for the selected day.
- Keep the visual contrast overlay reusable in `AppGlassSystem` because the home background needs stable text contrast independent of the hero copy.

## Risks / Trade-offs

- [Risk] Compact hero copy can hide calculation trust details. -> Mitigation: keep diagnostic/provider details in detail surfaces and accessibility/deeper explanations rather than prime hero space.
- [Risk] Filtering Morningcast after tomorrow can show fewer rows if the active window does not include enough future days. -> Mitigation: preserve the maximum count and use available resolved rows without fabricating schedule data.
- [Risk] Status labels could drift from future context types. -> Mitigation: tests cover ordinary, fasting, changed, skipped, and fixed states, and the presentation model centralizes the mapping for future extension.
