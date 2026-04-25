## Why

AlarmKit test-mode settings and test-run state are persisted in UserDefaults as JSON. If that stored data becomes corrupt or incompatible with a future shape, the app currently falls back silently but leaves the invalid payload in place, which can cause repeated failed loads and make test-mode behavior harder to reason about.

## What Changes

- Detect invalid persisted AlarmKit test settings and reset the stored settings payload back to defaults.
- Detect invalid persisted AlarmKit test-run state and clear the stale run payload.
- Preserve existing behavior for valid persisted values and for first launch with no stored values.
- Add focused tests for valid persistence, corrupt payload recovery, and default fallback behavior.

## Capabilities

### New Capabilities

- `alarmkit-test-store-recovery`: Defines recovery behavior for AlarmKit test settings and test-run persistence when stored data is missing, valid, or invalid.

### Modified Capabilities

- None.

## Impact

- Affected code:
  - `Suhoor/Core/AlarmKitTest/AlarmKitTestSettings.swift`
  - `Suhoor/Core/AlarmKitTest/AlarmKitTestRunStore.swift`
  - `SuhoorTests/SuhoorTests.swift` or focused AlarmKit test store tests
- Existing scheduled alarms are not changed by this proposal.
- Cached schedules, Hijri adjustments, and user alarm preferences are not changed by this proposal.
- Invalid AlarmKit test-mode diagnostic data may be removed or replaced with defaults during load.
