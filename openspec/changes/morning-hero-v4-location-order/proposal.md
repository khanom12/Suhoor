## Why

The v0.4 Morning Hero needs to orient the user around the location used for the displayed Fajr window, while temporarily removing the visible Gregorian/Hijri date line. The Fajr-window adjuster should sit directly under the primary wake time, with the relation copy as the final explanatory row.

## What Changes

- Replace the visible top date row with a prayer-time location line.
- Show a location icon only for automatic/current-location mode.
- Keep the relative day label directly below the location line.
- Keep resolving the date text for future use, but do not render it or reserve space for it in v0.4.
- Move the eligible Fajr window visual / wake adjuster above the relation line.
- Keep the primary wake row and relation line updating live during drag.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero renders the v0.4 location-first stack and final relation row while preserving the v0.3 within-Fajr adjuster behavior.

## Impact

- Affected code:
  - `Subh/Core/Services/ScheduleService.swift`
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused tests under `SubhTests/` and `SubhUITests/`
- No prayer-time calculation behavior changes.
- No persistence or override policy changes.
- No new production dependency.
