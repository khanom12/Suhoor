## Why

The v0.1 Morning Hero made the next Fajr-centered morning explicit, but the updated spec asks for a more compact and glanceable final row. The hero should now lead with the date and show the Fajr begin/end window as a calm visual range, with the wake marker positioned truthfully inside or outside that window.

## What Changes

- Reorder the hero text rows so the compact Gregorian/Hijri date appears first and the relative day appears second.
- Change the visible Gregorian date to omit weekday and use a month-name + ordinal-day pattern in English.
- Change the compact Hijri token to the v0.2 style, such as `ZQ12`.
- Restyle the relation line to match the date line's secondary typography.
- Replace the visible `Fajr begins` / `Fajr ends` sentence with a compact Fajr-window range visual that shows begin time, a horizontal bar, an optional wake/off-anchor indicator, and end time.
- Preserve accessibility text for the full Fajr begin/end meaning and wake relation.
- Keep the renderer from inventing missing wake, Fajr begin, or Fajr end values; missing Fajr data remains a calm text fallback.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero anatomy and Fajr-window presentation change from v0.1 text rows to the v0.2 date-first layout and range visual.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused presentation tests under `SubhTests/`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, calculation methods, or alarm delivery behavior are changed.
- This is a scoped home presentation and accessibility refinement.
