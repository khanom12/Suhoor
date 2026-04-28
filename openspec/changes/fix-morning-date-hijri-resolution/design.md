## Overview

The product model now treats the next morning as the primary unit. Legacy compatibility activation mode can cause date anchoring drift because it relies on sparse schedule sources. To prevent future-date anchoring regressions, we will migrate persisted morning-plan state to daily activation.

## Design

### 1) Activation mode migration in `MorningPlanStore`

On store initialization:

1. Load persisted `MorningPlanState` when present.
2. Normalize the state for the current product model:
   - If `activationMode == .legacyCompat`, convert to `.dailyActive`.
   - Set `lastMigrationAt` to `Date()` when conversion happens.
3. Persist only when normalization changes state.

This keeps migration deterministic and avoids repeated writes.

### 2) Behavior guarantees

After migration:

- `usesDailyActivation` returns `true` for prior legacy users.
- Active-window generation resolves from contiguous current-day progression.
- Hijri and prayer-time labels are tied to the real day being resolved.

## Test Plan

Add `MorningPlanStoreTests` to verify:

1. Fresh state still initializes as `.dailyActive`.
2. Persisted `.legacyCompat` state is migrated to `.dailyActive` and persists the migrated value.
3. Existing `.dailyActive` state remains unchanged.

## Risks and Mitigations

- **Risk:** Unexpected migration side effects for old persisted profiles.
  - **Mitigation:** The migration only changes activation mode and migration timestamp; default daily plan payload remains intact.
- **Risk:** Regression in onboarding/new-install behavior.
  - **Mitigation:** Fresh install path is unchanged and covered by test.
