## 1. Method And Settings Contract

- [x] 1.1 Add prayer calculation method profile metadata, canonical IDs, authority names, Fajr angles, and legacy decode aliases.
- [x] 1.2 Add persisted Fajr-end adjustment and local calculation policy defaults without disturbing existing Fajr/Maghrib adjustments.
- [x] 1.3 Update settings copy and controls to distinguish Fajr begin adjustment, Fajr end adjustment, and Maghrib adjustment.

## 2. Local Prayer Window Resolution

- [x] 2.1 Make `PrayerTimeCalculator` use the selected timezone calendar for solar day-of-year and local date anchoring.
- [x] 2.2 Round adjusted Fajr begin, Fajr end, and Maghrib boundaries to nearest minute.
- [x] 2.3 Resolve local prayer windows through one validation path that rejects invalid boundary ordering.
- [x] 2.4 Add source and diagnostics metadata to `DailyPrayerWindow` with decode-safe defaults for cached windows.

## 3. Scheduling And Surfaces

- [x] 3.1 Update `DayScheduleBuilder` and `MorningScheduleResolver` to use the resolved prayer-window path and Fajr-end adjustment.
- [x] 3.2 Update Fajr-end wake anchor source notes and Fajr-window presentation labels away from renderer proxy language.
- [x] 3.3 Ensure cache/signature behavior reflects calculation settings that change resolved prayer windows.

## 4. Verification

- [x] 4.1 Add unit tests for method angles, canonical IDs, and legacy raw-value migration.
- [x] 4.2 Add unit tests for timezone day-of-year behavior, minute rounding, independent boundary adjustments, Fajr-end sunrise source, and invalid-window rejection.
- [x] 4.3 Run targeted XCTest coverage and the narrowest available build/typecheck command.
