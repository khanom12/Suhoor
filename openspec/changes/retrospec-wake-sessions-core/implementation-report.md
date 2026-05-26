# Wake Sessions Core Retrospec Implementation Report

## Summary

This is a retrospective OpenSpec report for implementation commit `18a2404 feat: add wake sessions and wake checks`.

The implementation was completed directly from the cleaned canonical docs under `docs/specs` before this OpenSpec change existed. This retrospec captures the shipped behavior in OpenSpec so future work can use the same formal requirements trail.

## Source Of Truth Used For Implementation

- `docs/specs/00-subh-spec-index-v3.md`
- `docs/specs/subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`
- `docs/specs/subh-alarm-delivery-schedule-reliability-spec-v3.md`
- `docs/specs/subh-morning-resolution-contract-state-ownership-spec-v3.md`
- `docs/specs/subh-morning-hero-item-spec-v15.md`
- `docs/specs/subh-quiet-mode-quiet-morning-contract-spec-v1.md`
- `docs/specs/subh-sound-alarm-settings-spec-v1.md`
- `docs/specs/subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`
- `docs/specs/subh-pricing-entitlement-spec-v3.md`
- `docs/specs/subh-mvp-interaction-inventory-v4.md`

## Implementation Commit

- Commit: `18a2404 feat: add wake sessions and wake checks`
- Branch: `main`
- Push status: pushed to `origin/main`

## Files Changed By The Implementation

### Model, Persistence, And Entitlement

- `Subh/Core/Morning/WakeSessionStore.swift`
- `Subh/Core/Entitlements/SubhEntitlement.swift`

### Resolution And Scheduling

- `Subh/Core/Scheduling/MorningResolver.swift`
- `Subh/Core/Scheduling/SchedulingIdentifierSet.swift`
- `Subh/Core/Services/AlarmScheduler.swift`
- `Subh/Core/Services/RoutineScheduler.swift`
- `Subh/Core/Services/ScheduleService.swift`

### Home Hero And UI

- `Subh/Features/Home/MorningHomePresentation.swift`
- `Subh/Features/Home/SubhHomeView.swift`
- `Subh/Features/Home/MorningHomeSnapshot.swift`
- `Subh/Features/Home/MorningHeroUIIdentifier.swift`
- `Subh/Features/Alarms/AlarmDayDetailView.swift`
- Home and alarm preview wiring where required by new dependencies

### Tests

- `SubhTests/ScheduleServiceExtractionTests.swift`
- `SubhTests/ScheduleManagerHijriTests.swift`
- `SubhUITests/MorningHeroFajrAdjusterUITests.swift`

## Behavior Captured

- One local Wake Session exists for each active target morning.
- Wake Checks are deterministic follow-up wake attempts generated from the existing morning-resolution output.
- Fajr Wake Checks are bounded by five minutes before Fajr ends.
- Suhoor Wake Checks are bounded by five minutes before Fajr begins.
- Only future Wake Checks in the active scheduled horizon are scheduled.
- Wake-check identifiers are deterministic and stale identifiers are included in cancellation reconciliation.
- Native AlarmKit snooze is not used for MVP Wake Checks.
- Alarm stop or dismissal does not confirm awake.
- `I'm awake for Fajr` confirms awake and cancels remaining wake-session events without confirming Fajr prayer.
- `I'm awake for Suhoor` confirms awake, cancels remaining wake-session events, and confirms/plans fasting intent without confirming Fajr prayer or fast completion.
- `I prayed Fajr` confirms prayer separately from awake confirmation.
- Quiet active-session cancellation requires explicit confirmation before cancelling pending wake-session events.
- Quiet cancellation records `quietMorning` and does not record missed prayer.
- The Home Hero has a fixed action slot for current-morning wake/prayer actions and calm confirmation states.
- Wake Sessions, core Wake Checks, current-morning check-ins, current-day fasting intent, and Quiet Morning remain Free/core.

## Explicitly Out Of Scope

- StoreKit, paywalls, paid tier implementation, and pricing UI.
- Adaptive Wake Checks, custom interval settings, and advanced personalization.
- Long-term analytics, streaks, export, sync, Qada ledgers, historical editing UI, and household/family accountability.
- Runtime app-level system alarm volume control.
- A separate wake-session-only morning engine.

## Validation From Implementation Pass

- `git diff --check` passed.
- Targeted ScheduleService tests passed.
- Targeted ScheduleService and ScheduleManagerHijri suites passed.
- Targeted Home Hero UI selector test passed.
- Full Xcode suite passed for scheme `Subh` on the available iOS Simulator.
- Full suite result: 231 Swift tests and 4 UI tests passed.

## Known Limitations

- AlarmKit fired/stopped records are limited to platform callbacks the adapter can actually observe.
- Wake Session and MorningLog persistence currently uses local UserDefaults, which is sufficient for current-morning MVP execution but may need a local database when durable history becomes a Plus feature.
- The retrospec was created after implementation, so this change intentionally documents an already-shipped local commit rather than authorizing future code from scratch.
