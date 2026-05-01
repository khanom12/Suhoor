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

## 5. v3 Detail Context Card

- [x] 5.1 Update OpenSpec artifacts for v3 hero parity, context-card, fasting-opportunity, narrowed audio, and alarm-on semantics.
- [x] 5.2 Move Early purpose, fast-purpose, Fajr adhan toggle, day significance, and reset affordance into one liquid-glass context card below the hero.
- [x] 5.3 Show all applicable fasting opportunities across Fajr, Early, and Quiet modes, and default Early + Fast to today's opportunities or Voluntary fast.
- [x] 5.4 Remove broad v2 audio-choice UI and add only the non-Ramadan Early + Fast Fajr adhan-at-Fajr-begins toggle.
- [x] 5.5 Fix Fajr-mode alarm semantics so Fajr adhan audio does not disable the wake alarm; Quiet remains the only alarm-off mode.
- [x] 5.6 Add/update focused tests for v3 Fajr, Early Fast opportunities, override, Tahajjud, Quiet, Ramadan Early, Ramadan Fajr, and Ramadan Quiet states.
- [x] 5.7 Re-run OpenSpec validation plus focused Swift test/build checks, then commit and push.
