## Overview

The cleanup treats Subh as an MVP morning system with one runtime path and one wake-resolution authority. Legacy product domains may remain in storage for compatibility, but production code should not launch, compute, navigate, or present them unless they are part of the retained MVP surfaces.

The implementation should prefer deletion or disconnection over hiding old code behind UI that is no longer reachable. Where deleting a domain would create unnecessary risk, keep the storage type dormant and remove app-level construction, environment injection, navigation, and schedule participation.

## Architecture

`ScheduleManager` remains the boundary for resolved schedule state, reliability state, permission state, alarm reconciliation, and home presentation snapshots. It should not require fasting, Qada, progress, or plan stores to build the MVP home or schedule alarms.

Wake calculation remains resolver-owned:

1. Alarm config/settings and location inputs feed the morning-resolution path.
2. The resolver/builders produce `DaySchedule` and decision-log projections.
3. The Subh home, Tomorrow detail, Fajrcast, Morningcast, and scheduler read those projections.
4. No view or legacy compatibility surface recomputes a separate Fajr-start offset for production display.

The home snapshot should be cached or published from schedule updates. SwiftUI views may read the current snapshot, but should not rebuild the full 10-day presentation model on every body pass.

## Legacy Domain Prune

The production MVP path keeps:

- onboarding and completed-user launch into `SubhHomeView`
- Tomorrow Morning detail
- Weekly Fajrcast detail
- 10-day Morningcast detail/list behavior
- settings for location, prayer calculation, Hijri corrections, wake sounds/reserve where still used, permissions/reliability, diagnostics/about
- alarm scheduling and reconciliation

The production MVP path removes or disconnects:

- bottom tab shell
- old Today primary surface
- old Wake list and pre-Fajr customization entry points
- Plans and Progress primary surfaces
- fasting planning widgets/sheets
- Qada planner/progress surfaces
- navigation notifications that target retired product areas

Dormant data policy: preserve existing local values and legacy `Suhoor.*` keys. This change does not clear old fasting, Qada, progress, or plan data.

## Performance Guardrails

Performance verification is relative, not budget-fragile:

- prevent duplicate launch/foreground refreshes by coalescing or skipping redundant requests
- keep schedule cache validation tied to resolver-relevant inputs
- add lightweight trace points for refresh, active-window build, home snapshot build, Fajrcast snapshot build, and alarm reconciliation
- add deterministic XCTest coverage that proves the cached home snapshot updates when schedule inputs change and does not require view-local recomputation

## Migration And Compatibility

Existing custom wake settings stay intact. Known inherited factory defaults continue migrating to the Subh default of 30 minutes before supported Fajr end.

The bundle identifier and legacy storage namespaces remain unchanged. Dormant legacy data is not deleted or rewritten solely because the runtime code path no longer uses those domains.

## Risks

The largest risk is deleting a legacy type that a retained settings or scheduling path still compiles against. The safer implementation order is to first remove production entry points and app-level dependencies, then prune domain helpers only when references are gone.

The second risk is replacing old context engines with empty/default context behavior and accidentally changing prayer-time or alarm scheduling. Focused tests must pin the Fajr-end wake rule and the MVP card shape after the prune.
