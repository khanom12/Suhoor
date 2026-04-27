## Why

The GitHub audit shows Subh is architecture-rich but needs a tighter MVP readiness record: the ordinary Fajr morning loop must be proven, docs/specs still contain drift, and visible/semi-visible Suhoor-era language should be cleaned where it is not compatibility-bound. This change raises confidence without broadening the product.

## What Changes

- Run and record the current simulator build/test evidence for the Subh app target and test plan.
- Update the main MVP test plan from Suhoor-era framing to Subh's ordinary Fajr morning loop, reliability, completion, and naming requirements.
- Replace `Purpose TBD` headers in durable OpenSpec specs with product-specific purpose statements.
- Add OpenSpec coverage for MVP validation evidence and non-compatibility naming cleanup.
- Clean local onboarding preview model names that still describe the main wake as Suhoor, while preserving compatibility-bound storage, bundle, and persisted model names.

## Capabilities

### New Capabilities
- `mvp-readiness-validation`: Defines how Subh records build/test confidence, ordinary-loop readiness, and device/manual QA gaps before MVP.

### Modified Capabilities
- `subh-rename-compatibility`: Clarifies that non-compatibility docs and presentation-only symbols should use Subh/wake language while legacy storage and bundle surfaces remain intentionally preserved.

## Impact

- Affects OpenSpec artifacts, main spec purpose text, `TEST_PLAN.md`, and onboarding preview-only naming.
- Does not change prayer-time calculation, morning resolution, scheduling, AlarmKit behavior, persisted keys, migration behavior, or existing scheduled alarms.
