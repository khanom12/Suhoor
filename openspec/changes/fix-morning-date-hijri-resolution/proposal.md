## Why

Users reported that the app can surface a future Ramadan day (for example, Monday, February 8) as if it were "today," which then makes Fajr/Maghrib values and Hijri labeling look incorrect for the current morning. This breaks the core product promise to resolve and explain **tomorrow morning** from the real current date.

The current behavior can happen when migrated users stay in legacy compatibility activation mode, causing the active window to anchor on sparse scheduled sources (such as implicit Ramadan dates) instead of a contiguous daily morning plan.

## What Changes

- Migrate `MorningPlanStore` state so persisted `legacyCompat` activation is upgraded to `dailyActive` for the current product model.
- Ensure the migration is durable and recorded with an updated `lastMigrationAt` timestamp.
- Add focused tests proving migrated users resolve daily activation and do not remain anchored to legacy sparse date windows.
- Document this as a morning-resolution requirement so date anchoring behavior remains auditable.

## Capabilities

### Modified Capabilities
- `morning-resolution`: Active-window resolution must anchor on real current-day progression, not legacy sparse scheduled dates.

## Impact

- Affected code: `Subh/Core/Morning/MorningPlanStore.swift`, plus new coverage in `SubhTests/MorningPlanStoreTests.swift`.
- User-visible impact: Home cards, Fajrcast selection labels, Hijri labeling, and prayer times are aligned to actual current calendar dates instead of a future Ramadan placeholder.
- Risk: Low-to-medium migration risk; mitigated with deterministic, one-way migration and unit tests.
