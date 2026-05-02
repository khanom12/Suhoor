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

## 6. v4 Alignment and Fast Purpose Taxonomy

- [x] 6.1 Update OpenSpec artifacts for v4 title, hero alignment, always-present sentence-led context card, and fast-purpose taxonomy requirements.
- [x] 6.2 Change the navigation title to `Detailed Daily View` and keep the selected date inside the hero.
- [x] 6.3 Align the detail hero with the Home hero vertical rhythm, placing the date in the relative-day slot and preserving the Quiet Mode moon icon.
- [x] 6.4 Make the context card always present, sentence-led, and free of the old usual-plan reset wording.
- [x] 6.5 Expand fast-purpose overrides to the existing app taxonomy, de-duplicate menu rows, and preserve date-specific persistence.
- [x] 6.6 Add/update focused coverage for sentence copy, Quiet Mode icon/title semantics, fast-purpose options, duplicate prevention, and Ramadan locking.
- [x] 6.7 Re-run OpenSpec validation plus focused Swift test/build checks, then commit and push.

## 7. v5 Detail Copy, Chips, and Anchor Tightening

- [x] 7.1 Update OpenSpec artifacts for v5 title, fixed wake-time anchor, Sunnah opportunity copy, inline chips, and Voluntary return semantics.
- [x] 7.2 Change the navigation title to `Detailed View for the Day`.
- [x] 7.3 Tighten detail hero spacing so the date uses the Home relative-day slot without shifting the primary wake anchor below Home.
- [x] 7.4 Render context-card opportunity tags as inline, color-coded chips integrated with sentence copy in Fajr, Early, and Quiet modes.
- [x] 7.5 Update mode-specific copy for no-opportunity, Quiet Mode no-alarm, Early + Fast defaults, Tahajjud, and explicit fast-purpose overrides.
- [x] 7.6 Make Voluntary fast clear explicit fast-purpose overrides and return to opportunity chips when opportunities exist, without duplicate Voluntary rows or chips.
- [x] 7.7 Add/update focused tests for v5 copy, chips, Monday/Thursday display, override replacement, Voluntary return, Quiet copy, and Ramadan locking.
- [x] 7.8 Re-run OpenSpec validation plus focused Swift test/build checks.
