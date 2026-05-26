## Context

This change is a retrospective OpenSpec record for commit `18a2404 feat: add wake sessions and wake checks`. The implementation was driven from the cleaned canonical docs in `docs/specs`, especially the wake-session, alarm-delivery, morning-resolution, hero, Quiet, sound/alarm, pricing, and interaction inventory specs.

Before this change, Subh had a resolved morning, materialized scheduled events, AlarmKit/notification adapters, and Home Hero quick modes, but it did not have a local execution lifecycle that separated platform alarm stop from true awake confirmation. The new implementation adds that execution layer without creating a second morning engine.

Affected implementation anchors:

- `Subh/Core/Morning/WakeSessionStore.swift`
- `Subh/Core/Morning/Models/MorningSchedulingModels.swift`
- `Subh/Core/Scheduling/MorningResolver.swift`
- `Subh/Core/Scheduling/SchedulingIdentifierSet.swift`
- `Subh/Core/Services/AlarmScheduler.swift`
- `Subh/Core/Services/RoutineScheduler.swift`
- `Subh/Core/Services/ScheduleService.swift`
- `Subh/Core/Entitlements/SubhEntitlement.swift`
- `Subh/Features/Home/MorningHomePresentation.swift`
- `Subh/Features/Home/SubhHomeView.swift`
- `Subh/Features/Home/MorningHomeSnapshot.swift`
- `Subh/Features/Home/MorningHeroUIIdentifier.swift`
- `Subh/Features/Alarms/AlarmDayDetailView.swift`
- `SubhTests/ScheduleServiceExtractionTests.swift`
- `SubhTests/ScheduleManagerHijriTests.swift`
- `SubhUITests/MorningHeroFajrAdjusterUITests.swift`

## Goals / Non-Goals

**Goals:**

- Add one core/free Wake Session for the active target morning.
- Schedule deterministic Wake Checks from the existing resolver output and existing scheduler adapters.
- Preserve one Fajr-centered morning-resolution engine rather than creating a Free/Plus split or a wake-session-only resolver.
- Keep platform stop/dismissal, awake confirmation, Fajr prayer confirmation, fasting intent, fast completion, Quiet Morning, and expired/unconfirmed state separate.
- Keep Quiet as intentional suppression and active-session cancellation, not missed prayer or delivery failure.
- Add local MorningLog operational records that support current-morning execution and later history without building paid history UI now.
- Add a stable Home Hero Action Slot for active-session CTAs and confirmed states.
- Keep core behavior Free and avoid StoreKit/paywall work.

**Non-Goals:**

- No paid tier implementation, StoreKit, paywalls, or pricing UI.
- No adaptive wake checks, custom wake-check intervals, or advanced personalization.
- No long-term analytics, trends, streaks, export, cloud sync, household/family accountability, Qada ledger UI, or historical editing UI.
- No runtime AlarmKit/system volume-control promise.
- No new primary surface or separate wake engine.

## Decisions

### Decision: Add `WakeSessionStore` as a local execution store

`WakeSessionStore` owns `WakeSession`, `WakeSessionStatus`, `WakeSessionMode`, `MorningLogEntry`, and `MorningLogRecord`. It uses the app's existing local UserDefaults/debounced-persistence style and stores under `Subh.WakeSessionsAndMorningLogs`.

Alternative considered: fold wake-session fields into `DailyAlarmOverride` or schedule cache. That would blur user intent overrides, resolved schedule output, and observed execution outcomes. A dedicated local execution store keeps the lifecycle auditable while preserving the existing resolver spine.

### Decision: Generate Wake Checks from resolved scheduled events

`MorningScheduleResolver` still resolves the morning and primary wake event. `WakeSessionPlanner` derives wake checks from the resolved primary wake, mode, prayer window, and cutoff. The scheduler consumes the resulting materialized events just like other scheduled events.

Alternative considered: let `AlarmScheduler` synthesize follow-ups directly. That would make the scheduler infer morning intent and recreate a parallel wake engine.

### Decision: Use deterministic identifiers and reconciliation stubs

Wake-check event IDs use `dateKey.wakeCheck.index`, and the wake-session ID uses `dateKey.wake-session`. `SchedulingIdentifierSet` includes wake-check stubs for cold reconciliation so stale wake-check identifiers are cancelled after schedule changes.

Alternative considered: random IDs per schedule. That makes cancellation and stale reconciliation harder and weakens trust after edits, timezone changes, or app relaunch.

### Decision: Disable native snooze for MVP

`RoutineScheduler` now sends no AlarmKit snooze duration for wake-session events. Wake Checks are separate scheduled attempts; platform Stop only stops the current occurrence and does not confirm awake.

Alternative considered: map Wake Checks to AlarmKit snooze. That would make platform stop/snooze semantics ambiguous and conflict with the canonical rule that true confirmation happens inside Subh.

### Decision: Confirmations are service methods, not view-local mutations

`ScheduleService` exposes current-morning methods for awake confirmation, Fajr prayer confirmation, Quiet confirmation, and Quiet confirmation eligibility. The Home Hero calls these methods and does not write stores or cancel alarms directly.

Alternative considered: let `SubhHomeView` mutate `WakeSessionStore` and scheduler objects directly. That would put business rules in SwiftUI and make tests less focused.

### Decision: Quiet cancellation requires explicit confirmation

When Quiet is selected while pending wake-session events exist, the Home view shows the confirmation dialog before cancellation. Confirming cancels remaining wake-session events, marks/logs `quietMorning`, then applies the existing Quiet quick-mode override. Re-selecting Fajr or Suhoor reactivates the same morning's wake session.

Alternative considered: immediately switch to Quiet. That could silently cancel active wake checks while the user is half awake, which is too high-risk for a reliability surface.

### Decision: Add a fixed Hero Action Slot

`MorningHomePresentation` computes a `MorningHeroActionSlotDisplay`, and `SubhHomeView` renders it in a fixed-height slot. The slot can be empty, compact, primary, confirmation, or quiet, but its presence keeps the hero layout stable.

Alternative considered: insert CTAs only when active. That creates vertical jumps during low-consciousness use and risks moving key controls under the user's finger.

### Decision: Keep core behavior free

`SubhEntitlement` includes explicit core/free gates for Wake Sessions, Wake Checks, current-morning check-ins, and Quiet Morning. No StoreKit or paywall implementation was added.

Alternative considered: leave entitlement behavior implicit. Explicit gates make future pricing work less likely to accidentally block the core utility loop.

## Risks / Trade-offs

- [Risk] AlarmKit fire/stop observation is limited by the current adapter. -> Mitigation: the store exposes record APIs for fired/stopped events, but the implementation only records what the app can observe.
- [Risk] UserDefaults local persistence is sufficient for MVP but not a long-term event ledger. -> Mitigation: the record model is structured and local-first, while paid history/export/sync remains out of scope.
- [Risk] Wake-session status may become stale after large schedule changes. -> Mitigation: schedule refresh syncs the active scheduled horizon, deterministic IDs support cancellation, and Quiet sessions can reactivate when the user restores an active mode.
- [Risk] Added hero actions could crowd small screens. -> Mitigation: the slot uses compact copy, fixed height, scaling, and existing UI test coverage for selector layout.
- [Risk] Native AlarmKit secondary open-app affordances are platform/API dependent. -> Mitigation: the implementation avoids inventing unsupported behavior and keeps in-app confirmation as the source of truth.

## Migration Plan

- Ship as a forward-only local addition. Existing saved wake settings, schedule cache compatibility, and legacy namespace reads remain intact.
- Existing users get wake sessions only as active scheduled mornings are resolved/refreshed.
- Rollback can ignore the new `Subh.WakeSessionsAndMorningLogs` payload; older app code should not depend on it.
- No server-side migration, remote data migration, or StoreKit migration is required.

## Open Questions

- Which platform callback, if any, should be used to reliably record AlarmKit fired/stopped events on-device?
- Should wake-session persistence eventually move from UserDefaults to a small local database once durable history becomes a Plus feature?
- Should a future logging-only Quiet surface allow a user to record "I was awake anyway" without re-enabling wake checks?
