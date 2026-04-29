## 1. Presentation Contract

- [x] 1.1 Update hero display data for full-month Gregorian/Hijri date text and v0.3 Fajr visual mode fields.
- [x] 1.2 Add tentative wake formatting helpers for live primary time, relation text, marker ratio, and accessibility value.
- [x] 1.3 Cover full date text, hidden fasting/out-of-window rows, and adjustment eligibility in focused presentation tests.

## 2. Engine-Backed Override

- [x] 2.1 Add a focused ScheduleManager commit method that stores the target date wake as a date-specific fixed wake override.
- [x] 2.2 Ensure the commit path refreshes/reschedules only the target date through existing schedule-engine paths.
- [x] 2.3 Cover override persistence and same-day re-resolution in tests.

## 3. SwiftUI Hero Interaction

- [x] 3.1 Reduce v0.3 relative-to-primary spacing and update range drawing with endpoint circles plus alarm/off marker icons.
- [x] 3.2 Add drag state so eligible active within-Fajr rows update the large wake time and relation line live.
- [x] 3.3 Commit the dragged wake time on release and restore local state when the resolved snapshot changes.
- [x] 3.4 Add accessible increment/decrement behavior for eligible rows and avoid phantom controls for hidden/static rows.

## 4. Validation

- [x] 4.1 Run focused presentation and schedule tests.
- [x] 4.2 Run OpenSpec strict validation and available diff/type/build checks.
