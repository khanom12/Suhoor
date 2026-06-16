## Why

Subh can resolve the correct Fajr-centered wake plan while still losing trust if iOS retains stale AlarmKit alarms, drops expected deliveries, or keeps old wake checks after the app state changes. Recent device behavior suggests cold-start, debug reinstall, mode-switch, and awake-confirmation paths need repair-grade reconciliation, not just diagnostics.

## What Changes

- Add a durable local delivery-repair layer that compares expected Subh deliveries with pending notification and AlarmKit state, cancels stale Subh-owned deliveries, and reschedules missing or mismatched expected deliveries.
- Persist a compact expected-delivery plan for cold starts so repair does not depend only on in-memory scheduler state.
- Expand awake-confirmation and mode-switch cancellation to include current resolved events, deterministic date-key wake/check identifiers, persisted expected deliveries, and known prior-mode variants.
- Route observable notification and AlarmKit fire/stop events into Wake Session operational state without falsely confirming awake, prayer, or fasting outcomes.
- Extend debug install reset cleanup to include Subh-owned AlarmKit identifiers or record a verification-limited cleanup warning when platform cleanup is unavailable.
- Keep diagnostics and ledger records local-only, compact, and privacy-preserving.

## Capabilities

### New Capabilities
- `alarm-delivery-reliability`: Defines expected-delivery persistence, platform pending-state repair, stale Subh-owned delivery cleanup, local repair diagnostics, and repair-safe scheduling transactions.

### Modified Capabilities
- `wake-session-execution`: Awake confirmation, mode switching, and platform delivery callbacks must update or cancel Wake Session execution state without leaving orphaned wake checks or creating false religious/completion outcomes.

## Impact

- Affected code includes schedule refresh/reconciliation, platform scheduler adapters, identifier helpers, Wake Session storage, notification/AlarmKit callbacks, debug install reset, reliability diagnostics, and focused XCTest coverage.
- Existing scheduled Subh-owned alarms may be cancelled and recreated when they conflict with the current resolved delivery plan. Non-Subh platform alarms must not be touched.
- Persisted user wake settings, date-specific morning intent, prayer-time calculation choices, and completion records are preserved.
- No new production dependency, remote telemetry, raw location logging, or parallel wake engine is introduced.
