## Context

The current local prayer-time path calculates Fajr begin, sunrise/Fajr end, and Maghrib in `PrayerTimeCalculator`, then passes those values through `DailyPrayerWindow`, `MorningScheduleResolver`, `DayScheduleBuilder`, and Fajr-window presentation providers. This is the right architectural direction, but the contract is still thin: `CalculationMethod` only exposes labels and Fajr angle, the solar calculator derives day-of-year with a timezone-less Gregorian calendar, downstream Fajr-end metadata still says "sunrise proxy", and final dates can retain seconds from floating-point solar math.

The attached spec asks for a broader provider/mosque/high-latitude roadmap. This design implements the first production-safe slice: local calculation remains the canonical offline source, existing user settings are preserved, Fajr end is represented as source-tagged data, and behavior is covered with deterministic tests.

Affected code includes `Subh/Core/Models/CalculationMethod.swift`, `Subh/Core/Models/AppSettings.swift`, `Subh/Core/Services/PrayerTimeCalculator.swift`, `Subh/Core/Services/DayScheduleBuilder.swift`, `Subh/Core/Scheduling/MorningResolver.swift`, `Subh/Core/Morning/Models/MorningSchedulingModels.swift`, `Subh/Core/FajrWindowSurfaceModels.swift`, `Subh/Core/Services/FajrWindowSurfaceProvider.swift`, `Subh/Features/Settings/PrayerTimeSettingsView.swift`, `Subh/Core/Utilities/Strings.swift`, and focused tests under `SubhTests`.

## Goals / Non-Goals

**Goals:**
- Make local calculation timezone-correct for the selected location timezone.
- Round adjusted Fajr begin, Fajr end, and Maghrib boundaries to minute precision before scheduling/display.
- Add source and diagnostics metadata to the resolved prayer-window contract without moving prayer logic into SwiftUI.
- Preserve current five method angles while introducing canonical IDs and legacy decode aliases.
- Add a persisted Fajr-end adjustment defaulting to `0`, applied independently from Fajr begin.
- Detect invalid local windows instead of producing guessed alarms or fake chart values.

**Non-Goals:**
- Do not implement AlAdhan, Mawaqit, mosque timetable import, or provider cache behavior in this change.
- Do not add a custom method editor or a full region/country reverse-geocoding picker.
- Do not redesign the Morning Hero or Weekly Fajrcast UI.
- Do not change the product's default wake anchor away from supported Fajr end minus 30 minutes.

## Decisions

1. Keep `CalculationMethod` as the persisted setting, but wrap it with `PrayerCalculationMethod` metadata.
   - Rationale: this keeps the diff compatible with existing settings and UI while making method IDs, authority names, Fajr angles, and region hints explicit.
   - Alternative considered: replace the enum with a new persisted method-ID string immediately. That is more flexible, but too broad for this cleanup because many scheduling and settings paths already depend on the enum.

2. Add custom Codable handling for legacy method IDs.
   - Rationale: existing persisted values like `northAmerica`, `makkah`, and `egyptian` must continue decoding, while newly encoded values can use canonical IDs such as `isna`, `ummAlQura`, and `egyptianGeneralAuthority`.
   - Alternative considered: keep encoding old raw values forever. That preserves storage bytes but leaves the code contract misaligned with the spec's stable method-ID rule.

3. Extend `DailyPrayerWindow` with metadata and defaulted initializer parameters.
   - Rationale: `DailyPrayerWindow` is already the shared data contract consumed by scheduling, hero, and Fajrcast paths. Adding defaults minimizes call-site churn and keeps renderer logic passive.
   - Alternative considered: introduce a parallel `ResolvedPrayerWindow` immediately. That matches the long-term spec, but would force a larger migration across cache, snapshots, and presentation models.

4. Keep high-latitude behavior compatible but explicit.
   - Rationale: existing behavior uses a middle-of-night fallback only when direct Fajr calculation fails at absolute latitude above 55 degrees. This change records requested/applied rule and fallback usage without changing most users' times.
   - Alternative considered: switch immediately to full `automatic` angle-based policy. That is desirable later, but risks changing high-latitude schedules without a settings surface and golden tests.

5. Apply adjustment before rounding and validate after rounding.
   - Rationale: the attached spec requires `raw boundary -> adjustment -> rounding -> validation`. This avoids arbitrary seconds in scheduled alarms and keeps validation aligned with what users see.

## Risks / Trade-offs

- Canonical encoding changes stored method strings -> mitigated by legacy decode aliases and tests.
- Adding metadata to cached `DailyPrayerWindow` could leave old cache entries without sources -> mitigated by decode defaults and schedule refresh on settings changes.
- First-wave diagnostics are not the full spec contract -> mitigated by keeping fields explicit and local-calculation-oriented so provider metadata can be added later.
- Fajr-end adjustment is newly persisted and surfaced -> mitigated by defaulting to `0`, using the existing `-30...30` control pattern, and proving Fajr begin/end adjust independently.
