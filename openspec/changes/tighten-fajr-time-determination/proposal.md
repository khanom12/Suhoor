## Why

Subh's Fajr engine is now central to wake planning, the Morning Hero, and Weekly Fajrcast, so local prayer-window resolution needs to be explicit, timezone-correct, rounded to minute precision, and consistent across surfaces.

The attached Fajr determination spec identifies several first-wave gaps: method identity is still legacy-label-oriented, Fajr end is treated as a sunrise proxy in downstream copy, high-latitude behavior is hidden, and the solar calculator can derive day-of-year outside the selected location timezone.

## What Changes

- Stabilize the local calculation path so day-of-year, start-of-day, adjustment, and rounding are all based on the selected location timezone.
- Preserve current user-visible method behavior while adding stable canonical method IDs, legacy raw-value decoding, authority metadata, and clearer display names for ISNA, Egyptian General Authority, and Umm al-Qura.
- Publish Fajr end as a first-class resolved sunrise boundary with explicit source metadata instead of renderer-owned proxy language.
- Add focused diagnostics for local calculation source, method profile, applied adjustments, high-latitude rule, and validation warnings.
- Keep provider/API and mosque timetable sources out of this implementation slice; local calculation remains the offline default.
- Add behavior tests for current five method angles, legacy migration, rounding, independent Fajr begin/end adjustments, timezone day-of-year use, and invalid-window detection.

## Capabilities

### New Capabilities
- `prayer-time-determination`: Defines how Subh locally resolves, labels, validates, and exposes Fajr begin, Fajr end, and related calculation metadata.

### Modified Capabilities
- `morning-resolution`: Morning resolution must consume one resolved prayer-window snapshot with first-class Fajr begin/end data and source metadata.
- `fajr-end-mvp-wake`: Wake planning and trust copy must refer to the supported Fajr end boundary as sunrise-derived source data, not a renderer approximation.

## Impact

- Affected code: `PrayerTimeCalculator`, `CalculationMethod`, `AppSettings`, `DayScheduleBuilder`, `MorningResolver`, `DailyPrayerWindow`, Fajr window surface models/provider, settings presentation, and focused XCTest coverage.
- Persistence: existing method raw values must continue decoding; existing Fajr and Maghrib adjustment values are preserved. New Fajr-end adjustment defaults to `0`.
- Scheduling: schedule cache signatures should account for any newly persisted calculation settings that affect resolved prayer windows.
- Dependencies: no new production dependencies. Provider/API work remains future-facing and is not required for alarms.
