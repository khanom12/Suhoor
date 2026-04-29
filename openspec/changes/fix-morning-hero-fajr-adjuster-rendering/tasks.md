## 1. OpenSpec and Eligibility

- [x] 1.1 Validate the follow-up OpenSpec change and keep v0.3 as source of truth.
- [x] 1.2 Fix the Fajr-row hide gate so `.suhoor` alone does not count as a fasting day.
- [x] 1.3 Add focused presentation coverage for ordinary secondary-suhoor mornings, true fasting mornings, out-of-window wakes, and missing Fajr data.

## 2. Interaction Surface

- [x] 2.1 Add stable hero/Fajr-row identifiers for UI automation.
- [x] 2.2 Keep the Fajr row exposed as meaningful accessibility content while avoiding phantom adjustable controls.
- [x] 2.3 Extract deterministic drag-position mapping and cover clamping/rounding in tests.

## 3. UI Fixture and Verification

- [x] 3.1 Add a debug-only UI-test launch fixture for a configured Toronto home state with an active within-Fajr wake.
- [x] 3.2 Add a UI test target/test that launches the fixture, verifies the row, drags the marker, and confirms the row remains after commit.
- [x] 3.3 Run focused unit, schedule-manager, UI, OpenSpec, diff, and build validation.
