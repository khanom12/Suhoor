## Why

The tab-first app shell reinforces the old mental model of separate product areas. The Subh MVP should launch into one morning surface and expose retained legacy surfaces only contextually.

## What Changes

- Stop using `RootTabView` as the post-onboarding app shell.
- Route completed onboarding into `SubhHomeView`.
- Remove Wake, Plans, and Progress from primary bottom-tab navigation.
- Keep retained legacy views compiled and reachable only through contextual or settings paths where still useful.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: Retire bottom-tab IA from the primary experience.

## Impact

- Affects `ContentView`, root navigation, and app navigator handling.
- Does not delete planning/progress code in this wave.
