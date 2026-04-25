## Why

The existing Fajrcast and wake-list work is valuable, but it should read as part of a morning-system dashboard rather than an alarm tab. This change adapts card naming and presentation to Subh's Morningcast/Fajrcast framing.

## What Changes

- Preserve the visual and functional Fajrcast work.
- Adapt home card labels and explanatory copy from alarm-first language to Fajr-centered morning language.
- Present the next 10 upcoming wakes as Morningcast.
- Keep timezone/day correctness by relying on existing provider outputs.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: Adapt retained Fajrcast and Morningcast cards for the new home.

## Impact

- Affects home card presentation, labels, and tests.
- Does not change prayer-time calculations.
