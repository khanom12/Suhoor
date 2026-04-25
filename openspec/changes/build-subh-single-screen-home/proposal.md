## Why

The redesigned product should answer "what does tomorrow morning look like?" from one calm home surface instead of scattering the answer across tabs. This change builds the first Subh home and presentation snapshot for the MVP.

## What Changes

- Add a unified `MorningHomeSnapshot` with tomorrow, Weekly Fajrcast, Morningcast, permission state, and context flags.
- Add `SubhHomeView` as one `NavigationStack`-based dashboard surface.
- Render the first MVP cards: Tomorrow Morning hero, Weekly Fajrcast, and next 10 Morningcast list.
- Keep settings reachable from the top bar and card taps routed to detail screens.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: Implement the Subh MVP home surface and snapshot contract.

## Impact

- Affects app root presentation, Today/Wake feature reuse, presentation snapshots, and related tests.
- Does not remove underlying scheduling or settings functionality.
