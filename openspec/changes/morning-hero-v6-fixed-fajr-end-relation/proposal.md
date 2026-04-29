## Why

The v0.6 Morning Hero simplifies the final relation line so active wake timing is always expressed against Fajr end. This keeps the hero line visually compact and avoids switching between begin/end/boundary phrases while the user drags the adjuster.

## What Changes

- Change active Morning Hero relation copy to the fixed pattern `Wake up {X} min before Fajr ends`.
- Calculate `X` from the current wake time to the resolved Fajr end time.
- Use the same fixed Fajr-end pattern for live drag relation updates.
- Return to compact `min` wording for this final line and related accessibility value text.
- Preserve stateful copy for off, no-alarm, missing-Fajr, quiet, and unavailable states.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero renders v0.6 active relation copy against Fajr end while preserving the v0.4/v0.5 layout and v0.3 adjuster behavior.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - Focused presentation and UI tests
- No prayer-time calculation behavior changes.
- No persistence or override policy changes.
- No new production dependency.
