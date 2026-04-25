## Why

Subh has pivoted from a tabbed Suhoor/fasting/planning app into a Fajr-centered morning system, but large legacy UI and domain surfaces still compile without an MVP entry point. This pass removes loose ends so the codebase is faster to build, easier to reason about, and less likely to reintroduce old product assumptions.

## What Changes

- Remove production SwiftUI surfaces that are no longer reachable from the Subh MVP: legacy tab shell, Today dashboard, Plans, Progress, Wake list, old alarm editor/info wrappers, Qada planner, Shawwal planner, and seasonal planning views.
- Remove or narrow ScheduleManager APIs and providers that only served those retired surfaces while preserving the active MVP path.
- Simplify onboarding so fresh users do not encounter the retired pre-Fajr buffer picker, Ramadan path split, or plan-support CTAs.
- Remove disabled countdown/test-alarm diagnostic infrastructure, stale AlarmKit test stores, and orphan tests that were no longer part of the MVP runtime or scheme.
- Preserve MVP functionality: onboarding, single home, Tomorrow Morning detail, Weekly Fajrcast, 10-day Morningcast, settings, permissions/reliability, prayer/Hijri configuration, and alarm scheduling.
- Preserve local legacy data; this pass removes runtime/code paths, not stored `Suhoor.*` data.
- Remove orphan test files that are no longer part of the Xcode test target and only document retired surfaces.

## Capabilities

### New Capabilities

- `subh-loose-end-prune`: Defines the criteria for removing dormant code while protecting the Subh MVP runtime path.

### Modified Capabilities

- `single-screen-morning-home`: Clarifies that retired tab-era surfaces must not remain compiled as production entry points.

## Impact

- Affects SwiftUI feature folders under `Subh/Features`, legacy surface providers under `Subh/Core/Services`, presentation snapshot helpers, and tests tied to retired product areas.
- Existing bundle id, settings, alarm scheduling, prayer/Hijri calculations, schedule cache, and legacy local data namespaces remain intact.
