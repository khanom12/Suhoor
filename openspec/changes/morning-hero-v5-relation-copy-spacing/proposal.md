## Why

The v0.5 Morning Hero keeps the v0.4 location-first anatomy, but tightens the final wake relation line so it reads as a complete user instruction. The Fajr-window visual also needs the v0.5 vertical spacing relationship: closer to the primary wake time, with the explanatory relation line slightly farther below the visual.

## What Changes

- Change active wake relation copy from compact offset phrases such as `30 min before Fajr ends` to complete phrases such as `Wake up 30 minutes before Fajr ends`.
- Use full-word minute wording in active hero relation copy, drag relation copy, and related accessibility value text.
- Keep no-alarm/off/unavailable state copy stateful rather than pretending an active wake relation exists.
- Keep the Fajr-window visual directly below the primary wake row and set the visual-to-relation gap to the v0.5 baseline.
- Keep drag behavior and commit behavior unchanged while updating the live final relation text.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero renders v0.5 active relation copy and spacing while preserving v0.4 location-first ordering and v0.3 adjuster behavior.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused presentation and UI tests
- No prayer-time calculation behavior changes.
- No persistence or override policy changes.
- No new production dependency.
