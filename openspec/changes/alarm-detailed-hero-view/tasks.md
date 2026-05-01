## 1. OpenSpec and Presentation Contract

- [x] 1.1 Add a delta spec for the alarm detailed hero view requirements.
- [x] 1.2 Inspect the existing Home hero, alarm detail screen, and wake-resolution override flow.

## 2. Detail Hero Implementation

- [x] 2.1 Replace the list-based alarm day detail layout with a hero-style liquid-glass detail surface.
- [x] 2.2 Add Gregorian · Hijri date presentation and quiet primary wake display.
- [x] 2.3 Reuse or extract Home hero wake-time display, relative text, and adjustment slider behavior.
- [x] 2.4 Reuse the existing quick wake mode persistence path while presenting detail labels as `Fajr | Early | Quiet`.
- [x] 2.5 Add compact purpose display/control for Early, Ramadan, and fasting-opportunity states without adding diagnostics or source sections.

## 3. Validation

- [x] 3.1 Add/update focused tests or preview coverage for Fajr, Early, Quiet, Ramadan, and fasting-opportunity states.
- [x] 3.2 Run OpenSpec validation and the narrowest meaningful Swift test/build checks available.

## 4. v2 Detail Controls

- [x] 4.1 Update the OpenSpec delta/design to cover v2 purpose, fast-type, audio, Quiet Mode, Ramadan, and stable hero layout requirements.
- [x] 4.2 Replace `Fast + Tahajjud` user-facing purpose behavior with only `Fast` and `Tahajjud`.
- [x] 4.3 Add compact fast-type presentation and date-specific override persistence for `Early + Fast`, including Ramadan locking.
- [x] 4.4 Add compact audio presentation and date-specific persistence for wake alarm and Fajr adhan behavior without exposing delivery diagnostics.
- [x] 4.5 Keep Quiet Mode visually stable, use `Quiet Mode`, and preserve Ramadan Fajr adhan behavior.
- [x] 4.6 Add/update focused tests for Fajr audio, Early Fast, Early Tahajjud, fast type overrides, Quiet Mode, Ramadan Early, and Ramadan Quiet.
- [x] 4.7 Re-run OpenSpec validation plus focused Swift build/test checks.
