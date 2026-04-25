## 1. OpenSpec

- [x] 1.1 Create proposal, design, spec deltas, and implementation tasks for `prune-subh-mvp-performance`.
- [x] 1.2 Validate the new OpenSpec change in strict mode.

## 2. Runtime Path And Navigation

- [x] 2.1 Remove or disconnect legacy tab-era entry points, navigation notifications, and onboarding routes that target retired Plans, Progress, Wake-list, fasting, or Qada surfaces.
- [x] 2.2 Keep completed-user launch focused on the single Subh home and settings toolbar path.

## 3. Wake Resolution And Presentation

- [x] 3.1 Ensure Tomorrow Morning, Fajrcast, Morningcast, scheduling, and detail copy consume one resolver-owned 30-minutes-before-supported-Fajr-end wake path.
- [x] 3.2 Remove remaining production Fajr-start/45-minute display or scheduling fallbacks.
- [x] 3.3 Cache or publish `MorningHomeSnapshot` from schedule state instead of rebuilding it from SwiftUI body evaluation.

## 4. App Object Graph And Legacy Domain Prune

- [x] 4.1 Stop constructing and injecting dormant legacy stores in the app launch path when they are not needed by the MVP.
- [x] 4.2 Remove fasting/planning/Qada/progress domain participation from active-window and home snapshot construction while preserving legacy data on disk.
- [x] 4.3 Keep settings, prayer/Hijri configuration, permissions/reliability, and alarm scheduling functional.

## 5. Performance Guardrails

- [x] 5.1 Coalesce duplicate app-launch/home-appear/foreground refresh requests for the same scheduler state.
- [x] 5.2 Add lightweight DEBUG/test-visible traces or counters for schedule refresh, active-window build, home snapshot build, Fajrcast snapshot build, and alarm reconciliation.
- [x] 5.3 Add focused performance/structure tests that use relative guardrails instead of brittle hard timing budgets.

## 6. Verification

- [x] 6.1 Run `openspec validate prune-subh-mvp-performance --strict`.
- [x] 6.2 Run `openspec validate --all --strict` and `openspec status --change prune-subh-mvp-performance --json`.
- [x] 6.3 Run `xcodebuild -list -project Subh.xcodeproj`.
- [x] 6.4 Run focused or full `xcodebuild test -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,id=8368874B-C3CE-41C6-A760-A58A46B57E17'`.
- [x] 6.5 Commit and push the validated change to `main`.
