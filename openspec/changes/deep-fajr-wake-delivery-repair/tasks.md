## 1. OpenSpec

- [x] 1.1 Create proposal, design, tasks, and spec deltas for deep Fajr wake delivery repair.
- [x] 1.2 Validate `deep-fajr-wake-delivery-repair` in strict mode before code changes.

## 2. Expected Delivery Persistence

- [x] 2.1 Add a local expected delivery plan store derived from resolver-materialized future deliveries.
- [x] 2.2 Save refreshed expected delivery plans after full-window and per-day schedule reconciliation.
- [x] 2.3 Ensure persisted expected deliveries are used only for delivery repair and diagnostics.

## 3. Delivery Repair

- [x] 3.1 Add a repair coordinator that compares expected, persisted, and pending platform deliveries.
- [x] 3.2 Cancel unexpected, duplicate, or mismatched Subh-owned pending deliveries inside the scheduling horizon.
- [x] 3.3 Reschedule missing or mismatched expected deliveries through the existing scheduler adapters.
- [x] 3.4 Record local repair results and keep non-Subh platform deliveries untouched.

## 4. Wake Session Cancellation And Callbacks

- [x] 4.1 Expand awake-confirmation cancellation to include current events, deterministic date-key wake/check IDs, persisted expected deliveries, and known prior-mode identifiers.
- [x] 4.2 Expand Fajr/Suhoor/Quiet mode-switch cancellation so no orphaned wake checks remain.
- [x] 4.3 Route mappable notification and AlarmKit fire/stop callbacks into Wake Session fired/stopped records without false awake/prayer/fast outcomes.

## 5. Debug Reset And Diagnostics

- [x] 5.1 Extend debug install reset cleanup to cancel Subh-owned AlarmKit identifiers when available.
- [x] 5.2 Record verification-limited cleanup warnings when AlarmKit cleanup cannot be verified.
- [x] 5.3 Update reliability diagnostics/export with repair counts and local ledger summaries.

## 6. Tests And Validation

- [x] 6.1 Add unit/fake-scheduler tests for cold-start stale pending repair, missing reschedule, mismatched replacement, non-Subh ignore, confirmation cancellation, mode-switch cleanup, debug reset cleanup, and platform callback facts.
- [x] 6.2 Run focused scheduling/reconciliation tests.
- [x] 6.3 Run `xcodebuild test -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' -only-testing:SubhTests/ScheduleServiceExtractionTests`.
- [ ] 6.4 Run broader available unit target if focused tests pass.
  - Attempted `xcodebuild test -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' -only-testing:SubhTests`; reliability tests passed, but the target still fails existing `ScheduleManagerHijriTests.heroWakeAdjustmentKeepsFajrRowAtWindowBoundaries` because it expects `As Fajr ends` while the app returns `5 min before Fajr ends`.
- [x] 6.5 Validate OpenSpec strict mode again before commit.
