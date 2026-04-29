## 1. Clock and Activation

- [x] 1.1 Add internal `TimeProviding` and `FixedTimeProvider` support for deterministic scheduling tests.
- [x] 1.2 Inject the clock through `ScheduleManager`, `ActiveWindowSnapshotBuilder`, and date-sensitive presentation/onboarding paths.
- [x] 1.3 Make missing `MorningPlanState` initialize as `dailyActive` regardless of legacy settings presence.

## 2. Cache and Onboarding Hardening

- [x] 2.1 Reject cached active windows that are stale, missing today/tomorrow, or future sparse-context anchored.
- [x] 2.2 Force onboarding completion to refresh schedules before Home can present stale state.
- [x] 2.3 Add DEBUG/UI-test-only fixed-current-time launch argument parsing.

## 3. Regression Tests

- [x] 3.1 Add MorningPlanStore coverage for legacy settings without existing morning-plan state.
- [x] 3.2 Add ScheduleManager/cache tests for February 8, 2027 stale anchoring and cache reuse edge cases.
- [x] 3.3 Add presentation/onboarding tests for injected current-date behavior.

## 4. Validation

- [x] 4.1 Run focused unit tests for morning-plan, schedule extraction/cache, Hijri scheduling, and home presentation.
- [x] 4.2 Run the configured Xcode test plan or document any simulator/device limitation.
- [x] 4.3 Record remaining physical-device AlarmKit manual validation items.

## Validation Notes

- Focused tests passed:
  - `xcodebuild -project Subh.xcodeproj -scheme Subh -testPlan Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' -only-testing:SubhTests/MorningPlanStoreTests test`
  - `xcodebuild -project Subh.xcodeproj -scheme Subh -testPlan Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' -only-testing:SubhTests/ScheduleServiceExtractionTests test`
  - `xcodebuild -project Subh.xcodeproj -scheme Subh -testPlan Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' -only-testing:SubhTests/ScheduleManagerHijriTests test`
- Full configured test plan passed on the available iPhone 17 simulator because this workstation does not have an `iPhone 16` simulator installed:
  - `xcodebuild -project Subh.xcodeproj -scheme Subh -testPlan Subh -destination 'platform=iOS Simulator,id=055E11D4-3FE1-4879-BEBC-D139A7E4B9D7' test`
- Remaining manual validation before release: fresh physical-device install, reinstall with retained app data/cache, TestFlight-style build without fixed-time launch arguments, location/AlarmKit/notification permission grant path, launch or foreground after local date rollover, timezone change, and DST-adjacent date check.
