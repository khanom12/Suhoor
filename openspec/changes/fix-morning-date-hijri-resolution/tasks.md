## 1. Migration

- [x] 1.1 Update `MorningPlanStore` initialization to normalize persisted activation mode from `legacyCompat` to `dailyActive`.
- [x] 1.2 Persist migrated state only when normalization changes data.

## 2. Validation

- [x] 2.1 Add unit tests for fresh initialization, legacy-to-daily migration, and no-op daily state load.
- [x] 2.2 Run focused tests for `MorningPlanStoreTests` and related suites.
