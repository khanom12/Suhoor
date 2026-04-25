## Why

Subh has completed the first redesign from a tabbed Suhoor-era app into a Fajr-centered morning system, but the codebase still carries many runtime paths from the old fasting, planning, progress, and wake-list product model. Those paths increase launch cost, make wake resolution easier to contradict, and make the MVP feel clunky.

This change prunes production behavior back to the Subh MVP while preserving legacy local data for compatibility and future recovery.

## What Changes

- Add a Subh MVP performance-prune doctrine: production entry points are limited to onboarding, the single Subh home, Tomorrow Morning detail, Weekly Fajrcast, 10-day Morningcast, settings, reliability, prayer/Hijri configuration, and alarm scheduling.
- Centralize wake determination so Tomorrow Morning, Fajrcast, Morningcast, alarm scheduling, and detail copy consume one resolved wake path.
- Remove or disconnect legacy tab-era primary surfaces, including Plans, Progress, old Wake lists, fasting planning, and Qada planning, from the production runtime path.
- Slim launch-time state by avoiding construction and injection of dormant legacy stores where the MVP does not need them.
- Cache or publish the home snapshot from schedule state instead of rebuilding expensive presentation projections from SwiftUI body evaluation.
- Add performance guardrails that measure refresh/snapshot behavior and prevent duplicate launch refreshes without relying on brittle fixed simulator timing budgets.
- Preserve existing bundle id, `Suhoor.*` storage namespaces, and dormant legacy domain data. No old fasting, planning, Qada, or progress data is deleted in this pass.

## Capabilities

### New Capabilities
- `subh-mvp-performance-prune`: Defines the MVP-only production runtime path, legacy data dormancy, and performance guardrails for the cleanup pass.

### Modified Capabilities
- `morning-resolution`: Require production displays and scheduling to consume a single resolver-owned wake pathway and cached/published presentation snapshots.
- `single-screen-morning-home`: Strengthen the requirement that legacy tab-era surfaces have no production entry point in the MVP.
- `subh-rename-compatibility`: Clarify that dormant legacy local data is preserved even when old runtime domains are pruned.

## Impact

- Affected app areas: `SubhApp`, `ContentView`, Subh home/detail views, schedule refresh/resolution services, notification/navigation bridges, settings entry points, and tests around home snapshots and wake resolution.
- Existing scheduled alarms may be reconciled through the current resolver-backed schedules; unrelated alarms must not be cancelled by this cleanup.
- Existing schedule caches may be invalidated when their wake-rule or presentation signatures do not match the current resolver.
- Persisted settings and legacy local data are preserved. Dormant old data remains readable by future explicit migrations but is not used by the MVP runtime path.
