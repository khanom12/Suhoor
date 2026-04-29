## Why

Subh can still surface a future Ramadan date, such as Monday, February 8, 2027, as the active morning after onboarding or launch when cached or legacy-derived state wins over the phone's real current date. This breaks the product promise that the app explains and executes the current/tomorrow Fajr morning from device reality unless a test explicitly overrides time.

## What Changes

- Force new and migrated `MorningPlanStore` state into daily activation so current-product installs cannot create a sparse legacy active window.
- Add an injectable internal clock for scheduling, active-window generation, onboarding preview, and date-sensitive presentation, defaulting to the device clock in production.
- Add DEBUG/UI-test-only fixed-time launch support for deterministic tests without exposing production time overrides.
- Reject cached active windows that are stale, generated for another local day, or missing today/tomorrow when daily activation is active.
- Force onboarding completion to refresh the schedule before Home becomes the visible source of truth.
- Add regression tests for legacy profile initialization, stale/future cache rejection, date-sensitive presentation, and the February 8 Ramadan-anchoring failure mode.

## Capabilities

### New Capabilities

- `current-date-anchoring`: Ensures active morning resolution, cache reuse, and date-sensitive presentation are anchored to the real device date unless explicit test configuration supplies a fixed clock.

### Modified Capabilities

- `morning-resolution`: Current-product morning resolution must not fall back to sparse legacy or implicit Ramadan anchors when resolving the active window.
- `single-screen-morning-home`: Home and Fajrcast presentation must use the same current-date source as scheduling.

## Impact

- Affects `MorningPlanStore`, `ScheduleManager`, `ActiveWindowSnapshotBuilder`, onboarding, home presentation, UI-test launch configuration, and related tests.
- Existing scheduled alarms are not deliberately cancelled by this change, but stale schedule cache entries may be ignored and recomputed from the current day.
- Persisted user settings and override data are preserved; legacy compatibility activation becomes migration-only and decode-only.
- No production dependency or public API is added.
