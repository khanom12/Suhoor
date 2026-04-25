## 1. Default And Migration

- [x] 1.1 Update `DefaultAlarmConfig.default` to supported Fajr end minus 30 minutes.
- [x] 1.2 Add an old factory-default detector and migrate only exact old-default persisted settings during load.
- [x] 1.3 Persist migrated settings after a successful old-default migration.
- [x] 1.4 Expand the migration to catch the inherited 45-minute Fajr-start default already present on existing installs.
- [x] 1.5 Bump the alarm-config migration version so installs that previously missed the correction are re-evaluated.
- [x] 1.6 Version schedule cache entries by wake-rule signature and discard stale active windows generated from pre-Subh defaults.
- [x] 1.7 Update remaining compatibility schedule builders/detail display paths so they use the resolved wake rule instead of assuming Fajr-start minus offset.

## 2. Tests

- [x] 2.1 Add tests for fresh default values.
- [x] 2.2 Add tests that old factory-default persisted settings migrate.
- [x] 2.3 Add tests that custom persisted wake settings remain unchanged.
- [x] 2.4 Add tests that the inherited 45-minute Fajr-start default migrates to Fajr end minus 30.
- [x] 2.5 Add effective-config coverage so Morningcast/Fajrcast consumers receive the migrated Fajr-end wake rule.
- [x] 2.6 Add coverage for stale schedule-cache invalidation.
- [x] 2.7 Add coverage for the generic DaySchedule builder computing Fajr end minus 30.
