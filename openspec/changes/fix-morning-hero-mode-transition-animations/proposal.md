## Why

The Morning Hero quick-mode transitions still drift from the intended v1.2 behavior: endpoint times and relation copy do not visibly fade, the range marker handoff moves in the wrong direction between Fajr and Fast, and active wake-time rolling can be skipped immediately after leaving Quiet.

## What Changes

- Correct the Fajr/Fast slider marker handoff so Fajr to Fast travels left, disappears, reappears at the right edge, then settles leftward into the Fast position; Fast to Fajr performs the inverse.
- Make the slider endpoint times fade out and in during Fajr/Fast mode changes without moving the row.
- Make the relation text fade out and in for “before Fajr ends” / “before Fajr begins” copy changes.
- Keep the active wake-time rolling animation available after transitions from Quiet into either active mode.
- Preserve reduced-motion behavior with short fades and no marker travel.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Clarifies Morning Hero quick-mode transition animation requirements for endpoint labels, marker handoff direction, relation copy, and post-Quiet active-time rolling.

## Impact

- Affected code: `Subh/Features/Home/SubhHomeView.swift`.
- Affected tests: focused Morning Hero presentation/UI tests where useful.
- No API, persistence, alarm scheduling, cached schedule, or migration behavior changes.
