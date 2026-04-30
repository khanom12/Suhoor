## Why

The Weekly Fajrcast v9 specification narrows the compact footer's second line. The first footer line remains the authoritative Fajr begin/end explanation, while the optional second line should no longer restate alarm timing, off state, adjusted state, Tahajjud context, or Ramadan context already represented elsewhere.

The card also needs a little more intentional breathing room below the final visible footer line so the footer does not feel pinned to the lower edge of the glass surface.

## What Changes

- Preserve the mandatory focused-day Fajr begin/end primary footer line and its existing tense behavior.
- Change compact footer secondary text so it appears only for an explicit non-Ramadan fasting intention/context.
- Omit compact footer secondary text for ordinary, active-alarm, off/skipped, adjusted-only, Tahajjud-only, no-alarm, quiet, and Ramadan days.
- Add tuned footer-bottom breathing space below the final visible footer line without reserving a blank second-line slot when secondary text is absent.
- Update focused Weekly Fajrcast tests to lock the v9 footer semantics.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact footer semantics and footer-bottom spacing are updated to match the v9 specification.

## Impact

- Affected code:
  - `Subh/Core/Services/FajrWindowSurfaceProvider.swift`
  - `Subh/Features/Wake/FajrWindowCompactCard.swift`
  - `SubhTests/ScheduleServiceExtractionTests.swift`
- No persisted settings, cached schedule storage, scheduled alarms, notification identifiers, prayer-time calculation methods, chart geometry, snap-back behavior, or header-pill interaction behavior are changed.
- Alarm relation copy remains available outside the compact visible secondary footer where existing accessibility, diagnostics, or detail surfaces need it.
