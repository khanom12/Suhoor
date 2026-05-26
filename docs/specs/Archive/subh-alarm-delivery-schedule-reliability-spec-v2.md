# Subh Alarm Delivery and Schedule Reliability Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-delivery-schedule-reliability-spec-v2.md` |
| Version | 2 |
| Spec status | Draft; reconciled Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v1.md`, `subh-morning-resolution-contract-state-ownership-spec-v2.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-quick-wake-mode-intent-mutation-contract-v1.md`, `subh-fajr-time-calculation-determination-selection-spec-v1.md` |
| Owning domain / surface | Alarm delivery, scheduling, reconciliation, and diagnostics |
| Implementation audit status | Needs implementation audit |

## Purpose
Define how resolved morning events are materialized, scheduled, reconciled, diagnosed, and honestly degraded across AlarmKit and notification delivery paths.

## What This Spec Owns
- Delivery plan and reconciliation contracts.
- Permission, fallback, stale identifier, and degraded-state rules.
- Reliability QA and diagnostics expectations.

## Normative Requirements
The normative requirements in this spec are the explicit MUST, SHALL, required, acceptance, and scenario statements below. Recommendations, implementation guidance, examples, and future-direction notes are advisory unless this spec or a later canonical spec promotes them to requirements.

## Out of Scope / Deferred
- Code/spec divergence classification is deferred to a later implementation audit.
- App code, tests, and OpenSpec library artifacts are out of scope for this docs-only cleanup.
- Historical archive filenames are kept only as historical references and are not promoted back into the active spec set.

## Open Questions and Deferred Work
Open questions, TODO-style notes, future ideas, and implementation audit prompts below are retained as the working queue for later spec improvement. This cleanup standardizes them as deferred work rather than claiming they are resolved.

## Cleanup Notes
- This file was renamed and header-normalized in the Desktop working-spec cleanup pass.
- The Desktop folder remains the canonical working-spec location.
- Implementation completeness claims in older prose should be treated as historical context until the later audit updates this field.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- Delivery consumes resolved events for `Suhoor`, `Fajr`, and `Quiet`.
- `Suhoor` is the only exposed before-Fajr wake mode in MVP.
- Delivery must not treat legacy Tahajjud-only, Other early worship, or generic Pre-Fajr labels as separate MVP delivery classes.
- Quiet suppresses/cancels delivery while preserving the underlying Suhoor or Fajr meaning upstream.
- Turning off a later Fajr-begins adhan cue must not disable the earlier Suhoor wake event.
- Physical-device QA is required before claiming reliability for AlarmKit permission, audible wake under Focus/silent states, app termination, reboot, timezone/time changes, wrong-time firing, and missed wake reports.

## 0. One-page summary

Subh’s morning-resolution system decides **what should happen** for a morning: the prayer window, day meaning, user intention, wake boundary, wake time, alarm activation, and materialized scheduled events.

This specification defines the next layer: **whether the resolved events are actually deliverable by iOS, whether they are scheduled on the selected platform channel, whether stale platform state has been cancelled, whether pending state still matches the resolved events, and how failures are reported without rewriting the user’s intent.**

The central contract is:

```text
ResolvedMorningWakeState + ResolvedDaySnapshot.materializedEvents inside active scheduled horizon
        ↓
Delivery planning
        ↓
Platform scheduling: AlarmKit and/or UserNotifications
        ↓
Pending-state reconciliation
        ↓
Local delivery ledger + diagnostics
        ↓
Schedule/delivery status feedback
```

The most important separation is:

```text
Display/edit/knowledge horizon ≠ active scheduled horizon
Morning intent ≠ alarm activation ≠ delivery mode ≠ platform permission ≠ pending platform state ≠ delivery verification result
```

Examples:

```text
The user may intend an active Fajr wake while notification permission is denied.
That must be reported as blocked delivery, not Quiet Mode.

The user may select Quiet Mode.
That must cancel/suppress delivery, but it must not delete underlying Fajr/Suhoor state.

The wake event may use Fajr adhan audio.
That means the event is active with an adhan sound role, not that the alarm is off.

A schedule window cache may still be valid.
That does not prove platform pending requests still exist; delivery reconciliation must still run.

A notification fallback may be scheduled.
That is degraded delivery relative to AlarmKit and must not claim AlarmKit-level behavior, app-level snooze, or stronger guarantees.
```

This spec is deliberately **not** a visual screen spec. It is the reliability contract for the delivery layer that Codex should implement before visual surfaces rely on delivery status with confidence.

---


## 0.1 v2 Alignment Summary

This revision aligns delivery reliability with the Planning Horizon / Intention Anchoring model.

The key boundary is:

> **Delivery schedules the active scheduled horizon, not the display horizon.**

The delivery layer consumes resolver-materialized events that the parent morning/window builder marks as operational. It must not schedule events merely because they appear in Next 10, Weekly Fajrcast, month browsing, or a day detail view.

When a Hijri adjustment or other anchor rebind moves a planned observance from one Gregorian date to another, delivery receives an affected-date scope. It cancels stale deliveries on old dates and schedules/verifies new deliveries only if the new date/event is inside the active scheduled horizon.

The delivery layer still must not decide:

```text
whether Ashura moved
whether a White Day fast was date-specific or observance-specific
whether a completed fast should move
whether a visible month day is editable
```

Those decisions belong upstream to Planning Horizon / Intention Anchoring and Morning Resolution.

---

## 1. Purpose

This spec defines how Subh schedules, verifies, reconciles, diagnoses, and reports delivery of resolved morning events.

It answers:

```text
Which resolved events are expected to become platform deliveries?
Which channel should each event use?
When should AlarmKit be used?
When should UserNotifications be used?
When is notification fallback acceptable but degraded?
How are identifiers generated and migrated?
How are stale current and legacy deliveries cancelled?
How does the app verify pending notification and AlarmKit state?
How does delivery status flow back without redefining morning intent?
How are permission failures, platform failures, and missing pending requests represented?
How are lifecycle, time change, timezone change, and settings changes handled?
What should be logged locally for support while preserving privacy?
What must be tested on simulator versus physical device?
```

The objective is to prevent silent missed alarms and misleading UI state by making delivery reliability a first-class system contract.

---

## 2. Problem statement

Subh’s resolved wake time may be correct while the actual platform delivery is missing, stale, late, duplicated, permission-blocked, or scheduled through the wrong channel.

This can happen when:

1. A cached schedule window is reused but platform pending deliveries were cleared or changed.
2. A prior app version left stale identifiers behind.
3. A per-day reschedule does not know what was previously scheduled for that date.
4. AlarmKit authorization is unavailable, denied, or changes after schedule generation.
5. Notification authorization is unavailable, denied, provisional, or changes after schedule generation.
6. The device time, timezone, location, calculation method, Fajr adjustment, date override, or wake mode changes.
7. A platform scheduling call succeeds but the pending request is later missing or mismatched.
8. A sound role is misinterpreted as an on/off state.
9. A later Fajr adhan cue is disabled but the pre-Fajr wake is accidentally cancelled.
10. User-facing surfaces collapse delivery failure into Quiet Mode, no-alarm, or off state.

The risk is product trust. For Subh, a missed Fajr/Suhoor wake is not a cosmetic bug. The app must be conservative, explicit, and verifiable around delivery.

---

## 3. Scope

This spec owns:

- delivery planning from materialized `ScheduledEvent`s
- AlarmKit vs UserNotifications channel selection
- notification fallback policy
- permission and platform availability modeling
- delivery-mode selection and degradation rules
- expected-delivery data contract
- notification identifier and AlarmKit identifier rules
- current and legacy stale cancellation
- delivery transaction lifecycle
- pending-state reconciliation
- missing, mismatched, extra, stale, duplicate, and failed delivery detection
- local-only delivery ledger
- lifecycle/time/timezone/permission refresh triggers
- delivery diagnostics and support export
- schedule-status feedback into the morning-resolution layer
- device/simulator QA expectations
- acceptance criteria for Codex implementation

This spec does **not** own:

- Fajr begin, Fajr end, Maghrib, or final-third calculation
- user intention, day meaning, Ramadan, Qada, Tahajjud, or observance resolution
- selecting Fajr/Fast/Quiet or date-specific wake overrides
- Morning Hero layout or animation
- Alarm Detailed View layout or context-card contents
- Weekly Fajrcast chart geometry
- Next 10 row layout or tag doctrine
- completion/progress analytics credit rules
- app-level snooze UX beyond platform-provided AlarmKit behavior
- remote telemetry or cloud analytics
- push-notification infrastructure

The delivery layer begins **after** morning resolution has materialized events. It must not compute morning meaning or wake times itself.

---

## 4. Related specs and boundary map

### 4.1 Parent spec

**Subh Morning Resolution Contract and State Ownership** is the parent system-layer spec. It owns the canonical resolved morning graph and states that schedule/delivery status must not redefine user intent.

This delivery spec owns the downstream reliability layer:

```text
Morning Resolution Contract
    owns: intent, wake boundary, wake time, activation, materialized events

Alarm Delivery and Schedule Reliability
    owns: platform channel, permission state, scheduling transaction, pending-state verification, diagnostics
```

### 4.2 Child and sibling specs

| Spec | What it owns | Boundary with this spec |
|---|---|---|
| Planning Horizon, Day Resolution, and Intention Anchoring | supported current range, display/edit horizons, intention anchors, Hijri adjustment movement, affected-date sets | this spec consumes only active scheduled horizon and affected delivery refresh scopes; it does not move intentions |
| Wake State Selection and Alarm Resolution | wake-state model, activation vs schedule status | this spec implements the delivery/schedule-status side only |
| Morning Hero | top-surface presentation and quick intents | may show delivery warning from resolved status; must not schedule directly |
| Alarm Detailed View | selected-day editor and date-specific controls | may commit delivery-relevant user intents; must not show full diagnostics |
| Weekly Fajrcast | chart rendering and live preview | consumes wake/event state; must not schedule or reconcile |
| Next 10 Mornings | compact row forecast and tags | consumes schedule/delivery status only as resolved row state; no delivery diagnostics |
| Fajr Time Calculation | prayer-window source and Fajr end | this spec never calculates Fajr boundaries |
| Early Worship Boundary | final-third semantics | this spec never calculates final-third start |
| Day Purpose / Observance | opportunity, intention, outcome, credit | this spec never infers religious meaning from delivery events |

### 4.3 Existing OpenSpec changes to preserve

The repository already has incident-focused changes such as:

- `alarm-integrity-audit-and-hardening`
- `harden-alarm-pipeline-diagnostics`

Those changes are valuable but narrower. This spec should become the **durable capability contract** that absorbs/generalizes their rules into the library specs. Codex should not create a duplicate parallel delivery model. It should either:

1. archive this as a new permanent capability `alarm-delivery-reliability`, or
2. expand/rename the existing `alarm-delivery-integrity` capability if that is the repo’s preferred canonical name.

Recommended durable name:

```text
alarm-delivery-reliability
```

Allowed compatibility name:

```text
alarm-delivery-integrity
```

---

## 5. One-sentence definition

**Alarm Delivery and Schedule Reliability is the infrastructure layer that turns resolver-materialized Subh events into platform deliveries, verifies that pending platform state matches expected deliveries, cancels stale state, records local diagnostics, and reports delivery status without altering morning intent.**

---

## 6. Product doctrine

Subh is a Fajr-centered morning system. Its delivery layer must therefore be designed around trust.

### 6.1 Reliability principles

1. **Resolved events are the source of truth.**
   The delivery layer schedules `ScheduledEvent`s. It does not calculate prayer times or wake times.

2. **Delivery verification is required, not optional.**
   A successful schedule call does not prove the platform still has the expected delivery.

3. **Cache reuse must not skip delivery verification.**
   A valid schedule-window cache means calculation can be reused. It does not mean pending platform state is valid.

4. **Delivery failures must not rewrite user intent.**
   Permission-blocked active alarms remain active user intent with blocked delivery.

5. **Quiet Mode is intentional suppression.**
   Quiet Mode cancels/suppresses delivery for that date but preserves underlying morning state.

6. **Notification fallback is degraded delivery.**
   Notifications may be used when AlarmKit is unavailable or not selected, but they must not be represented as equivalent to AlarmKit.

7. **Stale platform state is dangerous.**
   Unknown prior state should be treated as stale-risky and cancelled conservatively by date-scoped identifier sets.

8. **Local diagnostics should be privacy-preserving.**
   The app can record local delivery outcomes without raw location, remote telemetry, or religious analytics.

9. **Device QA is required for audible confidence.**
   Simulator tests can validate planning and reconciliation logic, but audible/AlarmKit behavior needs physical-device verification.

---

## 7. Core vocabulary

### 7.1 Resolved event

A `ScheduledEvent` produced by the morning-resolution pipeline.

Examples:

```text
wake
reminder
fajrStartBoundaryCue
iftarNotification
iftarAlarm
iftarAdhan
```

A resolved event already has its semantic fire date, event type, delivery kinds, sound role, date key, and schedule provenance. The delivery layer must not recompute those values.

### 7.2 Delivery kind

The user/product-facing event channel role represented by `ScheduleEventKind` or equivalent.

Examples:

```text
wake
reminder
boundary
iftarNotification
iftarAlarm
iftarAdhan
```

A resolved event may have multiple delivery kinds only when the resolver intentionally materializes more than one delivery role.

### 7.3 Delivery channel

The platform mechanism used to deliver an event:

```swift
enum AlarmDeliveryChannel {
    case alarmKit
    case notification
}
```

### 7.4 Delivery mode

The app-level selected or effective mode for the scheduling transaction:

```swift
enum DeliveryMode {
    case none
    case notifications
    case alarmKit
    case mixed
}
```

`mixed` is used when some events are AlarmKit deliveries and others remain notifications, such as a policy where `iftarNotification` stays notification-based.

### 7.5 Expected delivery

A normalized record saying what platform delivery **should** exist after scheduling.

```swift
struct ExpectedAlarmDelivery {
    let dateKey: String
    let eventID: String
    let eventType: ScheduledEventType
    let deliveryKind: ScheduleEventKind
    let fireDate: Date
    let timeZone: TimeZone
    let channel: AlarmDeliveryChannel
    let notificationIdentifier: String
    let alarmIdentifier: UUID
    let soundRole: MorningSoundRole?
    let wakeSessionID: String?
    let scheduleSignature: String
}
```

### 7.6 Pending delivery

A platform delivery currently known to iOS:

```swift
struct PendingNotificationDelivery {
    let identifier: String
    let fireDate: Date?
}

struct PendingAlarmDelivery {
    let id: UUID
    let fireDate: Date?
}
```

### 7.7 Delivery reconciliation report

A deterministic comparison between expected deliveries and pending platform state.

It identifies:

```text
missing expected deliveries
mismatched fire dates
unexpected extra deliveries
wrong channel deliveries
duplicate identifiers
expired/past deliveries that should have been pruned
platform-state-unavailable cases
```

### 7.8 Delivery ledger

A capped local-only log of scheduling, cancellation, reconciliation, and permission decisions.

It exists for support/debugging, not analytics.

### 7.9 Schedule status

The summarized delivery outcome exposed back to the morning-resolution system.

Examples:

```text
scheduled
partiallyScheduled
pending
permissionBlocked
channelUnavailable
verificationWarning
failed
notScheduledBecauseQuiet
notScheduledBecauseNoAnchor
notScheduledBecauseUnavailable
```

The parent morning-resolution layer may collapse this into its existing `ScheduleStatus` enum, but the delivery layer should preserve richer diagnostics internally.

---

## 8. Current implementation anchors

The current repo already contains important delivery infrastructure. Codex should extend and stabilize these anchors rather than replacing them with a parallel scheduler.

| Current file/type | Current responsibility | Reliability contract direction |
|---|---|---|
| `Subh/Core/Services/AlarmScheduler.swift` | builds planned events from `ActiveAlarmDay.scheduledEvents`, reconciles previous vs next plans, delegates platform scheduling | keep as central delivery planner/reconciler; strengthen status reporting and verification feedback |
| `Subh/Core/Services/RoutineScheduler.swift` | schedules/cancels through AlarmKit or notifications | keep as platform abstraction; make outcomes structured and testable |
| `Subh/Core/Services/NotificationScheduler.swift` | requests authorization, schedules local notifications, reads pending requests | keep as UserNotifications adapter; add structured errors and timezone-safe pending extraction where needed |
| `Subh/Core/Services/AlarmKitScheduler.swift` | schedules/cancels AlarmKit alarms when available | keep as AlarmKit adapter; expose authorization and pending state through protocol/fakes |
| `Subh/Core/Services/AlarmCoordinator.swift` | thin AlarmKit scheduling wrapper | ensure it preserves event metadata and does not hide schedule failure reasons |
| `Subh/Core/Services/DeliveryReconciliationReport.swift` | compares expected deliveries against pending notification/alarm state | expand to include extra/stale/channel/duplicate and per-date aggregation if missing |
| `Subh/Core/Services/AlarmDeliveryLedgerStore.swift` | local delivery ledger | retain local-only privacy-preserving role; define retention and required fields |
| `Subh/Core/Services/SchedulingReconciler.swift` | reconciles schedule mode and status text | move from plain status strings toward structured delivery status |
| `Subh/Core/Scheduling/SchedulingIdentifiers.swift` | identifier generation | make canonical, deterministic, versioned, and shared |
| `Subh/Core/Scheduling/SchedulingIdentifierSet.swift` | identifier expansion and cancellation sets | use for all current + legacy stale cancellation |
| `Subh/Core/Services/ScheduleRefreshCoordinator.swift` | schedule refresh orchestration | must trigger reconciliation after lifecycle/time/settings changes |
| `Subh/Core/Services/ScheduleCacheStore.swift` | cache persistence | cache validity must not skip delivery verification |
| `Subh/Core/Services/PermissionState.swift` | permission representation | align notification + AlarmKit + app scheduling permission states |
| `Subh/Core/Services/ActiveWindowBuilder.swift` | active alarm window snapshot | snapshot supplies scheduled days/events and horizon |

---

## 9. Architecture model

### 9.1 Required dependency direction

```text
MorningScheduleResolver / MorningWakeResolutionService
        ↓
ResolvedDaySnapshot + ResolvedMorningWakeState
        ↓
ActiveAlarmWindowSnapshot / PlanningWindowSnapshot
        ↓
activeScheduledDateKeys + ActiveAlarmDay.scheduledEvents
        ↓
AlarmScheduler / DeliveryPlanner
        ↓
RoutineScheduler
        ↓
AlarmKitScheduler + NotificationScheduler
        ↓
DeliveryReconciliation
        ↓
DeliveryLedger + ScheduleStatus feedback
```

### 9.2 Forbidden dependency direction

The delivery layer must not call into UI or independently resolve religious/morning state.

Forbidden:

```text
NotificationScheduler -> calculate Fajr end
AlarmKitScheduler -> infer Ramadan/Fast/Tahajjud
AlarmScheduler -> select Fajr/Fast/Quiet
SwiftUI view -> create/cancel platform alarms directly
DeliveryReconciliation -> change wake mode to Quiet
Settings diagnostics -> mutate schedule plan
```

### 9.3 Delivery transaction shape

Every delivery operation should be modeled as an idempotent transaction:

```text
1. Receive resolved scheduled days/events.
2. Build expected deliveries.
3. Preflight permissions, channel availability, duplicate IDs, and past events.
4. Cancel stale identifiers for affected scope.
5. Schedule expected deliveries through platform adapters.
6. Query pending platform state.
7. Reconcile expected vs pending state.
8. Persist local ledger entries.
9. Publish structured delivery status.
```

A transaction may be best-effort because platform APIs are external mutable state. But it must never return a confident `scheduled` status without either:

1. successful platform scheduling and successful verification, or
2. explicit policy saying verification is unavailable and the status is degraded/pending.

---

## 10. Layer ownership matrix

| Concern | Owner | Consumers | Forbidden duplication |
|---|---|---|---|
| prayer-window times | Fajr/prayer resolver | morning resolver, scheduler input | notification/alarm adapters |
| wake time | morning resolver | delivery planner | platform adapters recomputing offsets |
| event materialization | morning resolver / schedule resolver | delivery planner | SwiftUI, notification scheduler |
| delivery channel choice | delivery planner | platform adapters, diagnostics | UI components deciding channel |
| notification authorization | notification adapter / permission service | delivery planner, settings | morning resolver deciding notification state from UI strings |
| AlarmKit authorization | AlarmKit adapter / permission service | delivery planner, settings | notification adapter |
| identifiers | scheduling identifier service | all scheduling/cancellation/diagnostics/tests | ad-hoc string/UUID creation |
| stale cancellation | delivery planner using identifier set | platform adapters | view-level cancellation |
| pending-state reconciliation | delivery reconciliation service | diagnostics, status feedback | relying only on schedule-call logs |
| delivery ledger | local ledger store | diagnostics/export | remote analytics |
| schedule status aggregation | delivery planner + morning-resolution adapter | surfaces | delivery status rewriting wake intent |

---

## 11. Delivery modes and channel-selection rules

### 11.1 DeliveryMode.none

Use when global scheduling is disabled or no deliverable events exist.

Rules:

- Do not schedule new platform deliveries.
- Cancel stale deliveries within the active scheduling scope.
- Publish `notScheduledBecauseGlobalDeliveryDisabled`, `notScheduledBecauseNoEvents`, or more specific internal status.
- Do not rewrite individual active wake intent as Quiet.

### 11.2 DeliveryMode.notifications

Use when AlarmKit is unavailable, unsupported, not selected, not authorized, or intentionally disabled for the current environment.

Rules:

- Schedule eligible future events through UserNotifications.
- Treat this as degraded delivery for wake events.
- Do not claim app-level snooze behavior.
- Do not claim AlarmKit lock-screen/Dynamic Island alarm behavior.
- Verify pending notification requests after scheduling.
- If notification permission is denied, publish `permissionBlocked` and do not call the morning Quiet.

### 11.3 DeliveryMode.alarmKit

Use when AlarmKit is supported, selected, and authorized for eligible alarm-style events.

Rules:

- Schedule wake/reminder/Fajr-boundary alarm-style events through AlarmKit when eligible.
- Events explicitly designated as notification-only remain notifications.
- Verify AlarmKit pending/scheduled state when the platform adapter can expose it.
- If AlarmKit authorization is denied or unavailable, fall back only according to the app’s explicit fallback policy.
- If fallback is disabled, publish blocked/unavailable status.

### 11.4 DeliveryMode.mixed

Use when the transaction intentionally schedules some events through AlarmKit and others through notifications.

Example:

```text
wake event -> AlarmKit
iftar notification -> UserNotifications
```

Rules:

- Expected deliveries must preserve channel per event.
- Reconciliation must compare each expected delivery against the correct platform state.
- A missing notification must not be hidden by a successful AlarmKit event, and vice versa.
- Aggregate status may be `partiallyScheduled` if one channel succeeds and another fails.

### 11.5 Channel-selection table

| Event / delivery kind | Preferred channel when AlarmKit available | Notification fallback | Notes |
|---|---|---|---|
| wake | AlarmKit | yes, degraded | highest reliability priority |
| pre-Fajr wake | AlarmKit | yes, degraded | generic wake sound role unless resolver says otherwise |
| in-Fajr wake | AlarmKit | yes, degraded | may use Fajr adhan sound role |
| Fajr begins boundary cue | AlarmKit or notification based on resolver/delivery policy | yes | must not duplicate wake unless resolver materializes both |
| reminder | AlarmKit or notification based on product policy | yes | lower priority than wake |
| iftar notification | notification | yes | may remain notification-only |
| iftar alarm / adhan | AlarmKit if modeled as alarm | yes, degraded | future policy may refine |

---

## 12. Permission and availability model

### 12.1 Notification permission

Represent UserNotifications authorization explicitly:

```swift
enum NotificationPermissionState {
    case authorized
    case provisional
    case ephemeral
    case denied
    case notDetermined
    case restricted
    case unknown
}
```

Rules:

- `.authorized`, `.provisional`, and `.ephemeral` may permit scheduling, but UI copy should not overstate audible reliability for provisional/ephemeral states.
- `.denied` must block notification delivery.
- `.notDetermined` must be represented as permission not yet requested, not as failure.
- `.restricted` and `.unknown` must be treated as unavailable/blocked for confident delivery.

### 12.2 AlarmKit permission

Represent AlarmKit authorization separately:

```swift
enum AlarmKitPermissionState {
    case authorized
    case denied
    case notDetermined
    case unavailableOS
    case unavailableEntitlement
    case unavailableRuntime
    case unknown
}
```

Rules:

- AlarmKit permission must not be inferred from notification permission.
- A denied AlarmKit permission does not necessarily deny notification fallback.
- If AlarmKit is unavailable because of OS, entitlement, simulator, or runtime state, diagnostics must distinguish that from user denial when possible.

### 12.3 Combined delivery permission state

Use a combined model for planning:

```swift
struct DeliveryPermissionSnapshot {
    let generatedAt: Date
    let notification: NotificationPermissionState
    let alarmKit: AlarmKitPermissionState
    let selectedMode: DeliveryMode
    let effectiveMode: DeliveryMode
    let fallbackPolicy: DeliveryFallbackPolicy
}
```

### 12.4 Permission-to-status mapping

| Morning activation | Effective mode | Permission state | Delivery status | Must not display as |
|---|---|---|---|---|
| active | AlarmKit | AlarmKit authorized | scheduled / pending verification | Quiet |
| active | AlarmKit | AlarmKit denied + notification fallback allowed | degraded notification fallback or permission warning | Quiet |
| active | AlarmKit | AlarmKit denied + fallback disabled | permissionBlocked | Quiet / no alarm |
| active | notifications | notification authorized | scheduled / pending verification | AlarmKit scheduled |
| active | notifications | notification denied | permissionBlocked | Quiet / off |
| quietSuppressed | any | any | notScheduledBecauseQuiet | permission failure |
| noAnchor | any | any | notScheduledBecauseNoAnchor | permission failure |
| unavailable timing | any | any | notScheduledBecauseUnavailable | Quiet |

---

## 13. Materialized event contract

### 13.1 Event fields required by delivery

Every deliverable event must provide or allow deterministic derivation of:

```swift
struct DeliveryEventInput {
    let dateKey: String
    let eventID: String
    let type: ScheduledEventType
    let fireDate: Date
    let localTimeZone: TimeZone
    let deliveryKinds: [ScheduleEventKind]
    let soundRole: MorningSoundRole?
    let soundSelection: SoundChoice?
    let wakeSessionID: String?
    let wakeSessionRole: WakeSessionEventRole?
    let fajrStartBehavior: FajrStartBehavior
    let deliveryEligibility: DeliveryEligibility
    let scheduleSignature: String
}
```

If a current `ScheduledEvent` lacks any of these fields, the delivery planner may derive them from existing nearby models, but the target state is to make delivery inputs explicit and testable.

### 13.2 No event recomputation

The delivery layer SHALL NOT compute:

```text
Fajr begin
Fajr end
Maghrib
finalThirdStart
wake offset
Ramadan default wake
tag-derived fasting state
Qada/Tahajjud intention
```

It may only filter events by:

```text
future/past
scope/horizon
permission/channel availability
delivery eligibility
resolved Quiet/no-anchor/unavailable status supplied by parent state
```

### 13.3 Past-event handling

Rules:

- Events with `fireDate <= now` must not be scheduled.
- Past events should be excluded from expected future deliveries.
- Stale pending platform requests for past events within the known identifier universe should be cancelled opportunistically.
- A past event must not be rescheduled by shifting to the next day unless the morning resolver produces a new event.

### 13.4 Event equality for reconciliation

Two planned deliveries are equal only if these match:

```text
planID
channel
fireDate after minute rounding policy
schedule signature
sound role if platform can distinguish it
wake session role if platform can distinguish it
```

At minimum, reconciliation must compare identifier and fire date within tolerance.

---

## 14. Identifier contract

### 14.1 Canonical identifier rule

All platform identifiers must be generated through a shared scheduling identifier service.

Forbidden:

```swift
"wake-\(dateKey)"       // ad hoc inside view or scheduler
UUID()                  // non-deterministic platform alarm ID for a stable event
"boundary." + dateKey   // legacy strings outside migration code
```

Required:

```swift
SchedulingIdentifiers.identifier(for: event, deliveryKind: deliveryKind)
SchedulingIdentifiers.alarmID(for: event, deliveryKind: deliveryKind)
SchedulingIdentifierSet.forSchedule(...)
```

or equivalent canonical API.

### 14.2 Identifier properties

Identifiers must be:

- deterministic for the same resolved event and delivery kind
- unique across date, event type, and delivery kind
- stable across app launches
- migration-aware for current and legacy naming schemes
- privacy-preserving; no raw coordinates, free-form location names, or religious-intention prose
- usable by scheduling, cancellation, diagnostics, and tests

### 14.3 Legacy cancellation universe

For each affected date/schedule scope, stale cancellation must include:

```text
current event identifiers
current daily identifiers
legacy dot identifiers
legacy V1 identifiers
legacy AlarmKit UUID derivations, where deterministic
```

Unknown prior state is stale-risky. If the app cannot prove what it previously scheduled for a date, it must cancel every known current and legacy identifier for that date before scheduling the new resolved events.

### 14.4 Duplicate detection

Before scheduling, the delivery planner must verify:

- no two expected notification deliveries share the same notification identifier with different fire dates;
- no two expected AlarmKit deliveries share the same alarm UUID with different fire dates;
- no event has duplicate delivery kinds;
- no current identifier collides with a legacy identifier for a different event in the same scope.

If duplicates exist, scheduling must fail or degrade with a structured diagnostic. It must not silently keep one delivery and drop another.

---

## 15. Scheduling horizon and scope

### 15.1 Horizon source

The delivery layer does not decide the product planning horizon. It consumes the active scheduled handoff from the parent morning-resolution / active-window path.

Conceptual source:

```swift
struct ActiveAlarmWindowSnapshot {
    let generatedAt: Date
    let visibleDays: [ActiveAlarmDay]      // display/planning rows, not automatically scheduled
    let scheduledDays: [ActiveAlarmDay]    // only these may produce expected platform deliveries
    let scheduledHorizonDays: Int
    let productActiveAlarmID: String?
    let planningPolicyVersion: String?
    let calendarVersionID: String?
}
```

Existing names may differ. The contract is that `scheduledDays` and `visibleDays` are not the same thing.

### 15.2 Product-active alarm versus technical scheduled horizon

Rules:

- The product-active alarm is normally the next immediate alarm the user understands as operational.
- The technical scheduled horizon is the explicit set of resolver-materialized events the delivery layer is allowed to schedule and verify.
- MVP may set the technical scheduled horizon to the next immediate alarm only.
- A small safety buffer is allowed only when the Active Window Builder explicitly includes those events in `scheduledDays`.
- The delivery layer must not expand scope by reading calendar browsing data or Next 10 visible rows.

### 15.3 Display horizons are not schedule horizons

Forbidden:

```text
Schedule all Next 10 rows because Next 10 is visible.
Schedule all days in a browsed Gregorian/Hijri month.
Schedule future observance plans before the active scheduled window includes them.
Treat cached month rows as platform delivery inputs.
```

Required:

```text
Build expected deliveries only from scheduledDays.scheduledEvents.
Use visibleDays only for display/status aggregation if needed.
Cancel stale platform state only inside the explicit refresh scope.
```

### 15.4 Horizon rules

- The delivery layer schedules only future events inside `scheduledDays` and the requested refresh scope.
- The delivery layer may cancel stale identifiers across the same explicit scope.
- Per-day edits should cancel/reschedule only the affected date unless a parent invalidation requires a wider refresh.
- Anchor movement after Hijri/calendar adjustment must include both old and new resolved date keys in the refresh scope when either date is inside the active scheduled horizon or stale identifier universe.
- Global settings/location/timezone/prayer-method/Hijri-calendar changes require a parent re-resolution followed by a wider horizon refresh if materialized scheduled events changed.
- Debug-install reset may clear a wider identifier universe, but that must be a deliberate reset path.

### 15.5 Scope types

```swift
enum DeliveryRefreshScope {
    case day(dateKey: String)
    case activeAlarm(alarmID: String?)
    case dates(dateKeys: Set<String>, reason: DeliveryRefreshReason)
    case horizon(startDateKey: String, days: Int)
    case allKnownUpcoming(days: Int)
    case debugReset
}

enum DeliveryRefreshReason {
    case singleDayEdit
    case immediateAlarmOverride
    case anchorMovement
    case hijriAdjustment
    case prayerSettingsChange
    case timezoneOrLocationChange
    case activeHorizonRollover
    case permissionOrModeChange
    case manualRepair
}
```

Rules:

- `activeAlarm` scope cancels/repairs only the currently relevant product-active alarm event(s).
- `day` scope must not cancel unrelated future dates.
- `dates` scope is required when an anchored intention moves from old date(s) to new date(s).
- `horizon` scope may cancel all current/legacy identifiers inside the active scheduled horizon or explicit repair horizon.
- `allKnownUpcoming` must be used cautiously and only when the parent invalidation truly affects all upcoming scheduled events.
- `debugReset` may be broader but must be explicitly user/developer initiated.

### 15.6 Hijri/calendar adjustment behavior

Hijri adjustment is a lifecycle reason for delivery refresh, but delivery does not decide what moved.

Required flow:

```text
1. Parent calendar/planning state changes.
2. Morning resolver re-resolves affected future days and anchored intentions.
3. Active Window Builder emits new scheduledDays/materialized events.
4. Delivery cancels stale identifiers inside refresh scope.
5. Delivery schedules/verifies the new expected deliveries.
6. Delivery reports status without changing anchors or intentions.
```

### 15.7 Anchor movement delivery behavior

When upstream resolution reports that an anchored intention moved:

1. Cancel stale identifiers for old affected date keys inside the Subh identifier universe.
2. Build expected deliveries for new affected date keys only if their events are inside the active scheduled horizon.
3. Do not create deliveries for new dates that are merely visible or planned outside the active scheduled horizon.
4. Record the refresh reason as `anchorMovement` or `hijriAdjustment`.
5. Report delivery status only for operational events; do not rewrite the underlying intention if platform scheduling fails.

### 15.8 Immediate-alarm override behavior

If the user turns off only the next immediate alarm, the parent resolver should express that as activation/suppression for the relevant active event. Delivery behavior is then:

- cancel/suppress expected delivery for that active event;
- cancel stale identifiers for the relevant active alarm/day scope;
- publish not-scheduled/suppressed status as supplied by parent activation semantics;
- do not cancel unrelated future observance plans or date-specific intentions.

---

## 16. Delivery transaction lifecycle

### 16.1 Transaction inputs

```swift
struct DeliveryTransactionInput {
    let snapshot: ActiveAlarmWindowSnapshot
    let settings: AppSettings
    let requestedMode: DeliveryMode
    let lifecycleReason: DeliveryLifecycleReason
    let refreshScope: DeliveryRefreshScope
    let activeScheduledDateKeys: Set<String>
    let affectedDateKeys: Set<String>
    let now: Date
    let permissionSnapshot: DeliveryPermissionSnapshot
}
```

### 16.2 Lifecycle reasons

```swift
enum DeliveryLifecycleReason {
    case appLaunch
    case foregroundRefresh
    case dayRollover
    case significantTimeChange
    case timezoneChange
    case locationChange
    case prayerSettingsChange
    case hijriAdjustmentChange
    case intentionAnchorMoved
    case planningHorizonChanged
    case monthBrowsingRangeChanged
    case wakeIntentChange
    case wakeTimeCommit
    case quietToggle
    case audioToggle
    case permissionChange
    case manualRefresh
    case debugInstallReset
    case testHarness
}
```

### 16.3 Transaction outputs

```swift
struct DeliveryTransactionResult {
    let generatedAt: Date
    let requestedMode: DeliveryMode
    let effectiveMode: DeliveryMode
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let scheduledDeliveries: [ExpectedAlarmDelivery]
    let failedDeliveries: [DeliveryFailure]
    let reconciliationReport: DeliveryReconciliationReport
    let aggregateStatus: DeliveryAggregateStatus
    let perDateStatus: [String: DeliveryDateStatus]
    let ledgerEntryIDs: [String]
}
```

### 16.4 Required transaction steps

1. Build expected deliveries from resolved events.
2. Preflight permission and platform availability.
3. Preflight identifiers and duplicate collisions.
4. Cancel stale identifiers in scope.
5. Schedule expected deliveries through appropriate adapters.
6. Query pending notification and AlarmKit state.
7. Reconcile expected vs pending.
8. Record ledger entries.
9. Publish status to schedule service / morning-resolution adapter.

### 16.5 Idempotency

Running the same transaction twice with the same resolved events and same platform pending state should not create duplicates.

The second run may:

- no-op because deliveries already match;
- verify and refresh diagnostics;
- repair missing/mismatched deliveries;
- cancel stale extras;
- record a verification ledger entry.

It must not produce duplicate audible alerts for the same event.

---

## 17. Platform scheduling adapters

### 17.1 Shared adapter contract

Platform adapters should expose structured outcomes:

```swift
protocol PlatformDeliveryScheduling {
    associatedtype Identifier

    func schedule(_ delivery: ExpectedAlarmDelivery) async -> PlatformScheduleResult
    func cancel(identifier: Identifier) async -> PlatformCancelResult
    func pendingDeliveries() async -> [PlatformPendingDelivery]
    func authorizationState() async -> PlatformAuthorizationState
}
```

Existing concrete adapters may keep their current names. The important requirement is structured, testable behavior.

### 17.2 Notification scheduler requirements

The notification scheduler SHALL:

- request notification authorization only from explicit permission flows, not opportunistically during every schedule run;
- schedule local notifications from resolved event fire dates;
- use calendar/date components in the event’s resolved timezone where possible;
- preserve sound role selection without changing activation state;
- expose pending notification requests for reconciliation;
- return structured failure reasons for `center.add` failures;
- cancel by canonical identifier sets;
- avoid broad `removeAllPendingNotificationRequests()` except explicit debug reset or full app reset policy.

### 17.3 AlarmKit scheduler requirements

The AlarmKit scheduler SHALL:

- check AlarmKit platform availability and authorization separately from notification authorization;
- schedule eligible alarm-style events through AlarmKit when effective mode requires it;
- preserve resolved event labels, sound role, snooze behavior if platform-supported, and wake session metadata when available;
- expose pending/scheduled AlarmKit alarms if the platform API supports inspection;
- return structured failure reasons;
- cancel by canonical deterministic alarm identifiers;
- degrade to notification fallback only according to explicit fallback policy.

### 17.4 Routine scheduler requirements

The routine scheduler SHALL:

- be the only layer that talks to both platform adapters for normal delivery operations;
- accept expected/resolved delivery inputs;
- return structured outcomes;
- not recompute event fire dates;
- not decide user wake mode;
- not emit surface copy directly.

---

## 18. Reconciliation contract

### 18.1 Expected vs pending comparison

Reconciliation compares:

```text
expected notification deliveries -> pending UNNotificationRequests
expected AlarmKit deliveries -> pending AlarmKit alarms
```

It must produce a deterministic report, independent of UI.

### 18.2 Required discrepancy categories

```swift
enum DeliveryDiscrepancyKind {
    case missingExpectedDelivery
    case fireDateMismatch
    case unexpectedExtraDelivery
    case duplicateIdentifier
    case wrongChannel
    case platformStateUnavailable
    case pendingTriggerDateUnavailable
    case expiredPendingDelivery
}
```

### 18.3 Fire-date tolerance

Default tolerance:

```text
60 seconds
```

Reason: platform trigger date reconstruction may lose seconds or use minute-level date components.

Rules:

- Tolerance must be configurable in tests.
- A mismatch outside tolerance must produce a warning.
- If the app’s future rounding policy becomes stricter, update this tolerance deliberately.

### 18.4 Missing expected delivery

If an expected delivery is missing:

- record the identifier and event metadata;
- mark the date/event as verification warning or failed depending on policy;
- attempt repair if the transaction is in repair mode;
- do not mark user intent as Quiet/off.

### 18.5 Fire-date mismatch

If an identifier exists but the fire date differs:

- mark `fireDateMismatch`;
- cancel and reschedule the delivery when in repair mode;
- record both expected and actual fire dates in local diagnostics;
- avoid exposing confusing raw technical details in compact surfaces.

### 18.6 Unexpected extra delivery

If a pending delivery exists inside the Subh identifier universe but is not expected:

- mark `unexpectedExtraDelivery`;
- cancel it when safe and in scope;
- record stale cancellation in the ledger;
- include it in diagnostics.

### 18.7 Platform-state unavailable

If pending AlarmKit state cannot be inspected:

- do not falsely claim verification success;
- report `pendingVerificationUnavailable` or equivalent degraded status;
- keep the schedule attempt result separate from the verification result;
- require device QA for confidence.

### 18.8 Aggregation

Reconciliation report should support:

```text
per-delivery status
per-date status
per-channel status
aggregate transaction status
human-readable diagnostic summary
machine-testable discrepancy arrays
```

---

## 19. Status model

### 19.1 Internal delivery aggregate status

```swift
enum DeliveryAggregateStatus {
    case noDeliverableEvents
    case scheduledAndVerified
    case scheduledPendingVerification
    case partiallyScheduled
    case permissionBlocked
    case channelUnavailable
    case verificationWarning
    case repairAttempted
    case failed
    case notScheduledBecauseQuiet
    case notScheduledBecauseNoAnchor
    case notScheduledBecauseUnavailable
}
```

### 19.2 Per-date status

```swift
struct DeliveryDateStatus {
    let dateKey: String
    let activation: AlarmActivation
    let expectedCount: Int
    let scheduledCount: Int
    let verifiedCount: Int
    let warningCount: Int
    let failureCount: Int
    let status: DeliveryAggregateStatus
    let userFacingSummary: String
    let diagnosticsSummary: String
}
```

### 19.3 Mapping back to morning schedule status

| Delivery aggregate status | Parent schedule status | Notes |
|---|---|---|
| scheduledAndVerified | scheduled | confident delivery |
| scheduledPendingVerification | pending | used when platform inspection unavailable |
| partiallyScheduled | partiallyScheduled or warning | do not claim full success |
| permissionBlocked | permissionBlocked | active intent remains active |
| channelUnavailable | failed or unavailable | channel-specific diagnostics needed |
| verificationWarning | warning / failed depending severity | active intent remains active |
| failed | failed | active intent remains active |
| notScheduledBecauseQuiet | notScheduledBecauseQuiet | only when parent activation is quiet |
| notScheduledBecauseNoAnchor | notScheduledBecauseNoAnchor | no wake time/event |
| notScheduledBecauseUnavailable | notScheduledBecauseUnavailable | missing required timing/data |

### 19.4 Compact user-facing copy

The delivery layer may provide short status strings. Layout specs decide where they appear.

Examples:

```text
Scheduled
Scheduled with notification fallback
Alarm permission needed
Notification permission needed
Delivery could not be verified
Delivery mismatch repaired
No wake alarm because Quiet Mode is on
No wake time available
```

Forbidden copy:

```text
Quiet Mode
```

when the true state is permission blocked, channel unavailable, or failed scheduling.

---

## 20. Sound role and audio delivery contract

### 20.1 Sound role is not activation

Sound role controls audio selection. It does not decide whether an event is active.

Required rule:

```text
Alarm off = Quiet/no-anchor/unavailable parent activation, not a sound choice.
```

### 20.2 Sound-role examples

```swift
enum MorningSoundRole {
    case preFajrWake
    case inFajrWake
    case fajrStart
    case reminder
    case iftar
    case fixedWake
}
```

### 20.3 Fajr mode using adhan audio

When Fajr mode wakes the user with Fajr adhan audio:

- the wake event remains active;
- delivery status is active/scheduled or active/blocked;
- the event uses an adhan sound role or sound selection;
- the system must not interpret adhan audio as “alarm off.”

### 20.4 Early + Fast with later Fajr adhan toggle

For eligible non-Ramadan Early + Fast days:

- the pre-Fajr wake event remains active when the later Fajr adhan cue is toggled off;
- toggling off the later Fajr adhan must cancel only the Fajr-start boundary/cue event for that date;
- it must not cancel the wake event;
- it must not switch the day to Quiet;
- it must not change the selected fast purpose.

### 20.5 Ramadan locked Fajr adhan behavior

For Ramadan days where the product policy locks the Fajr adhan behavior:

- delivery layer follows the resolver-materialized events;
- if the resolver materializes both pre-Fajr wake and Fajr-start adhan, both are expected deliveries unless duplicate policy suppresses one;
- delivery layer must not expose a Ramadan audio setting.

### 20.6 Duplicate audible cue policy

If two materialized events have the same fire date and same audible role, the delivery layer must not silently schedule duplicate audible alerts unless the resolver marks them as intentionally distinct.

Recommended behavior:

```text
same dateKey + same fireDate + same deliveryKind + same soundRole
    -> require unique event IDs and explicit duplicateAllowed flag, or fail preflight
```

---

## 21. Quiet, off, no-anchor, and unavailable states

### 21.1 Quiet Mode

Quiet Mode is a parent activation state. Delivery behavior:

- cancel/suppress expected wake deliveries for that date;
- cancel stale wake/reminder/Fajr-start identifiers in date scope unless parent events explicitly remain;
- record ledger reason `quietSuppressed`;
- publish `notScheduledBecauseQuiet`;
- preserve underlying morning intent and schedule data outside delivery.

### 21.2 Off with anchor

If the parent model supports “off with anchor”:

- preserve planned anchor for display;
- do not schedule audible delivery;
- cancel stale platform deliveries;
- publish off/no-delivery status distinct from permission failure.

### 21.3 No anchor

If no wake anchor exists:

- do not schedule wake delivery;
- cancel stale wake delivery for that date;
- publish `notScheduledBecauseNoAnchor`.

### 21.4 Unavailable timing/data

If required event timing is unavailable:

- do not schedule guessed deliveries;
- cancel stale deliveries for affected date/scope;
- publish `notScheduledBecauseUnavailable`;
- include missing-data reason in diagnostics if available.

---

## 22. Cache, lifecycle, and refresh triggers

### 22.1 Cache reuse rule

Schedule-window cache reuse is allowed only for calculation efficiency.

Required rule:

```text
Using a cached resolved window SHALL NOT skip platform delivery reconciliation.
```

### 22.2 Required reconciliation triggers

Run delivery reconciliation after:

- app launch;
- app enters foreground;
- day rollover;
- significant device time change;
- timezone change;
- location change affecting prayer windows;
- prayer calculation method/source/adjustment change;
- Hijri adjustment affecting Ramadan/observance materialized events;
- anchored intention movement with old/new affected date keys;
- active scheduled horizon rollover or planning-horizon policy change;
- user wake mode change;
- wake-time commit;
- Quiet toggle;
- later Fajr adhan toggle;
- alarm/notification permission change;
- scheduling mode change;
- debug-install reset;
- manual diagnostics refresh.

### 22.3 Repair policy

A reconciliation trigger may run in one of these modes:

```swift
enum DeliveryReconciliationMode {
    case verifyOnly
    case verifyAndRepair
    case cancelStaleAndRepair
}
```

Recommended policy:

| Trigger | Mode |
|---|---|
| app launch | verifyAndRepair |
| foreground refresh | verifyAndRepair |
| significant time change | cancelStaleAndRepair |
| timezone change | cancelStaleAndRepair |
| schedule-affecting settings change | cancelStaleAndRepair |
| Hijri adjustment / anchor movement | cancelStaleAndRepair for affected old/new date keys |
| active scheduled horizon rollover | cancelStaleAndRepair |
| permission status check | verifyOnly unless permission was restored |
| manual diagnostics refresh | verifyOnly |
| debug reset | cancelStaleAndRepair or full reset |

---

## 23. Ledger and diagnostics

### 23.1 Ledger purpose

The delivery ledger exists to answer:

```text
What did Subh think should be scheduled?
Which platform channel did it use?
Was permission available?
Did scheduling succeed?
Did pending-state verification pass?
What identifiers were cancelled or repaired?
What lifecycle event triggered the action?
```

### 23.2 Privacy rules

Ledger entries SHALL NOT include:

- raw latitude/longitude;
- free-form location name;
- full prayer-time source payloads;
- personal notes;
- remote analytics identifiers;
- cloud user identifiers;
- unnecessary religious-intention prose.

Allowed fields:

```text
dateKey
fireDate
event type
delivery kind
channel
permission snapshot summary
schedule signature / wake-rule hash
identifier hash or identifier where needed for local support
result status
error domain/code/message summary
lifecycle reason
generatedAt
```

### 23.3 Retention

Recommended retention:

```text
maxEntries = 500
maxAge = 90 days
```

Trim on write and on diagnostics export.

### 23.4 Diagnostics summary

Settings diagnostics may show:

```text
Delivery mode
Permission summary
Last schedule refresh
Expected future deliveries
Pending notification count
Pending AlarmKit count
Missing delivery count
Mismatch count
Last repair result
Local ledger summary
```

It should not show broad delivery diagnostics in Alarm Detail or compact Home cards by default.

### 23.5 Export

If diagnostics export exists:

- include reconciliation summary and ledger summary;
- exclude raw location;
- exclude remote analytics transmission;
- label notification fallback as fallback/degraded;
- include app version/build and OS version where useful.

---

## 24. User-facing surfaces and non-overlap

### 24.1 Morning Hero

The hero may consume a summarized schedule status:

```text
Scheduled
Alarm permission needed
Delivery could not be verified
Notification fallback
```

The hero must not:

- run reconciliation itself;
- call `scheduleAlarm`, `cancel`, or `removePendingNotificationRequests`;
- display full identifier diagnostics;
- change Quiet/Fajr/Fast state because delivery failed.

### 24.2 Alarm Detailed View

Alarm Detail may show a minimal date-specific warning if the selected date has blocked delivery.

It must not become:

- a broad delivery-status page;
- an AlarmKit diagnostics page;
- a source/provenance page;
- a reliability debug view.

### 24.3 Weekly Fajrcast

Weekly Fajrcast may render marker states from resolved snapshots.

It must not:

- inspect pending platform deliveries;
- schedule/cancel events;
- treat chart scrubbing as persistent scheduling;
- infer delivery status from visual marker color.

### 24.4 Next 10 Mornings

Next 10 may use concise status if a wake time is unavailable or quiet.

It must not:

- show row-level delivery diagnostics;
- add explanatory prose about AlarmKit or fallback;
- infer intention from delivery failure.

### 24.5 Settings / diagnostics

Settings or a dedicated reliability diagnostics surface is the correct place for:

- delivery mode selection;
- permission repair instructions;
- pending delivery counts;
- reconciliation summary;
- local ledger export;
- manual delivery refresh;
- debug reset.

---

## 25. Failure modes

| Failure | Detection | Required behavior | User-facing status |
|---|---|---|---|
| notification permission denied | permission preflight | do not schedule notification; record blocked | Notification permission needed |
| AlarmKit permission denied | permission preflight | fallback if policy allows; otherwise blocked | Alarm permission needed |
| AlarmKit unavailable OS/runtime | platform preflight | fallback if allowed; otherwise unavailable | Alarm delivery unavailable |
| event fire date in past | preflight | do not schedule; exclude or mark stale | not shown unless diagnostic |
| duplicate identifier | preflight | fail transaction or repair model; do not silently drop | Delivery configuration error |
| notification add failure | schedule result | record failure; retry only by policy | Delivery failed |
| AlarmKit schedule failure | schedule result | fallback only if policy allows; record failure | Delivery failed / fallback used |
| pending notification missing | reconciliation | repair if allowed; warn | Delivery repaired / could not verify |
| pending AlarmKit alarm missing | reconciliation | repair if allowed; warn | Delivery repaired / could not verify |
| pending fire date mismatch | reconciliation | cancel/reschedule if allowed | Delivery repaired |
| unexpected stale delivery | reconciliation | cancel stale in scope | hidden; diagnostic only |
| sound asset missing | preflight/platform | fallback to default sound; record warning | not usually shown |
| Quiet date with stale alarm | reconciliation | cancel stale; record repair | Quiet Mode remains quiet |
| no anchor with stale alarm | reconciliation | cancel stale | No wake time available |

---

## 26. Platform and environment expectations

### 26.1 AlarmKit

AlarmKit is the preferred channel for high-confidence wake events when supported and authorized.

Rules:

- AlarmKit use requires platform support and authorization.
- AlarmKit authorization must be tracked separately from notification authorization.
- If AlarmKit is unavailable in a simulator or OS version, tests must use fakes and device QA must cover real behavior.
- AlarmKit scheduling failures must be structured and reported.

### 26.2 UserNotifications

UserNotifications is the local notification fallback and may also handle event types that are notification-only by product policy.

Rules:

- Notification permission is required for actual notification delivery.
- Pending notification requests must be queried for reconciliation.
- Notifications must be treated as degraded for wake reliability when compared to AlarmKit.
- Notification fallback must not imply app-level snooze behavior.

### 26.3 Simulator vs physical device

Simulator can validate:

- expected-delivery construction;
- identifier generation;
- stale cancellation sets;
- notification request scheduling shape;
- fake pending-state reconciliation;
- ledger writing;
- status aggregation.

Physical device is required to validate:

- audible wake behavior;
- AlarmKit authorization prompt and settings behavior;
- AlarmKit scheduled alarm lifecycle;
- lock-screen / system alarm presentation where relevant;
- Focus/Silent/StandBy behavior where relevant;
- behavior after app termination, reboot, and time change.

---

## 27. Data contracts

### 27.1 DeliveryPlan

```swift
struct DeliveryPlan: Sendable, Equatable {
    let generatedAt: Date
    let lifecycleReason: DeliveryLifecycleReason
    let scope: DeliveryRefreshScope
    let requestedMode: DeliveryMode
    let effectiveMode: DeliveryMode
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let staleCancellationIdentifiers: SchedulingIdentifierSet
    let permissionSnapshot: DeliveryPermissionSnapshot
}
```

### 27.2 DeliveryFailure

```swift
struct DeliveryFailure: Sendable, Equatable {
    let dateKey: String?
    let eventID: String?
    let deliveryKind: ScheduleEventKind?
    let channel: AlarmDeliveryChannel?
    let reason: DeliveryFailureReason
    let errorDomain: String?
    let errorCode: String?
    let message: String?
}
```

```swift
enum DeliveryFailureReason: String, Sendable, Codable {
    case permissionDenied
    case permissionNotDetermined
    case channelUnavailable
    case platformSchedulingError
    case identifierCollision
    case fireDateInPast
    case missingRequiredEventField
    case verificationMissing
    case verificationMismatch
    case pendingStateUnavailable
    case staleCancellationFailed
    case unknown
}
```

### 27.3 DeliveryReconciliationReport

```swift
struct DeliveryReconciliationReport: Sendable, Equatable {
    let mode: DeliveryMode
    let generatedAt: Date
    let expectedDeliveries: [ExpectedAlarmDelivery]
    let pendingNotificationCount: Int
    let pendingAlarmCount: Int
    let missingNotificationIdentifiers: [String]
    let mismatchedNotificationIdentifiers: [String]
    let extraNotificationIdentifiers: [String]
    let missingAlarmIdentifiers: [UUID]
    let mismatchedAlarmIdentifiers: [UUID]
    let extraAlarmIdentifiers: [UUID]
    let duplicateIdentifiers: [String]
    let platformUnavailableNotes: [String]
    let perDateStatuses: [String: DeliveryDateStatus]
}
```

Existing code may evolve toward this model gradually.

### 27.4 Delivery ledger entry

```swift
struct AlarmDeliveryLedgerEntry: Codable, Sendable, Identifiable {
    let id: String
    let createdAt: Date
    let lifecycleReason: DeliveryLifecycleReason
    let dateKey: String?
    let eventType: ScheduledEventType?
    let deliveryKind: ScheduleEventKind?
    let channel: AlarmDeliveryChannel?
    let fireDate: Date?
    let permissionSummary: String
    let scheduleSignature: String?
    let action: DeliveryLedgerAction
    let result: DeliveryLedgerResult
    let diagnosticMessage: String?
}
```

---

## 28. OpenSpec requirements

This section can be used as the basis for `openspec/changes/alarm-delivery-schedule-reliability/specs/alarm-delivery-reliability/spec.md`.

## ADDED Requirements

### Requirement: Delivery schedules resolver-materialized events only

The system SHALL schedule platform deliveries only from resolver-materialized `ScheduledEvent`s or equivalent resolved delivery inputs.

#### Scenario: Delivery receives a wake event

- GIVEN the morning resolver has materialized a wake event with a fire date
- WHEN the delivery planner builds expected deliveries
- THEN it SHALL use the resolved event fire date
- AND it SHALL NOT recompute the wake time from Fajr offsets, tags, or UI state

#### Scenario: Delivery receives no wake event because the date is Quiet

- GIVEN the parent morning state marks the date as Quiet-suppressed
- WHEN the delivery planner builds expected deliveries
- THEN it SHALL NOT create a wake delivery for that date
- AND it SHALL cancel stale wake identifiers for that date according to scope
- AND it SHALL report `notScheduledBecauseQuiet`

---

### Requirement: Delivery failure does not rewrite morning intent

The system SHALL keep user intent and alarm activation separate from platform delivery outcome.

#### Scenario: Active Fajr wake is permission-blocked

- GIVEN the user has selected an active Fajr wake
- AND the resolved wake event has a valid fire date
- AND notification or AlarmKit permission is denied for the effective channel
- WHEN delivery planning runs
- THEN the delivery status SHALL be `permissionBlocked`
- AND the morning state SHALL remain active Fajr
- AND the system SHALL NOT persist or display the date as Quiet Mode

#### Scenario: Active Fast wake fails platform scheduling

- GIVEN the user has selected an active Fast wake
- AND the delivery adapter fails to schedule the platform alarm
- WHEN delivery status is published
- THEN the delivery status SHALL be `failed` or `verificationWarning`
- AND the underlying Fast intention SHALL remain unchanged

---

### Requirement: Cache reuse still reconciles delivery state

The system SHALL verify and repair platform delivery state on lifecycle refreshes even when the resolved schedule window cache is reusable.

#### Scenario: Launch reuses cached resolved window

- GIVEN the active schedule window cache is valid
- WHEN the app launch refresh runs
- THEN the system SHALL run delivery reconciliation for the cached scheduled events
- AND it SHALL NOT skip pending-state verification solely because calculation was reused

#### Scenario: Foreground refresh finds missing pending delivery

- GIVEN the cached window is reused on foreground refresh
- AND an expected pending notification is missing
- WHEN reconciliation runs
- THEN the system SHALL report the missing delivery
- AND it SHALL attempt repair when the refresh mode allows repair

---

### Requirement: Platform permissions are modeled separately

The system SHALL model notification permission and AlarmKit permission independently.

#### Scenario: AlarmKit denied but notifications authorized

- GIVEN AlarmKit permission is denied
- AND notification permission is authorized
- AND fallback policy allows notification fallback
- WHEN a wake event is scheduled
- THEN the system MAY schedule the wake through notifications
- AND it SHALL mark the delivery as degraded fallback
- AND it SHALL NOT claim AlarmKit delivery

#### Scenario: Notifications denied but AlarmKit authorized

- GIVEN notification permission is denied
- AND AlarmKit permission is authorized
- WHEN an AlarmKit-eligible wake event is scheduled in AlarmKit mode
- THEN the wake event MAY still be scheduled through AlarmKit
- AND notification-only events SHALL be blocked or unavailable according to policy

---

### Requirement: Notification fallback is degraded delivery

The system SHALL represent notification fallback as degraded delivery for wake events.

#### Scenario: Wake event uses notification fallback

- GIVEN AlarmKit is unavailable or not selected
- AND notification permission is authorized
- WHEN the system schedules a wake event through notifications
- THEN diagnostics SHALL identify the channel as `notification`
- AND the user-facing status MAY say notification fallback is active
- AND the system SHALL NOT expose or imply app-level snooze behavior

---

### Requirement: Identifiers are canonical and shared

The system SHALL generate all notification and AlarmKit identifiers through a shared identifier service.

#### Scenario: Scheduling, cancellation, and diagnostics use the same event

- GIVEN a resolved event and delivery kind
- WHEN scheduling, cancellation, and diagnostics each need the platform identifier
- THEN each layer SHALL call the shared identifier service
- AND they SHALL produce the same identifier

#### Scenario: Ad-hoc identifier collision is detected

- GIVEN two expected deliveries produce the same platform identifier with different fire dates
- WHEN preflight runs
- THEN the system SHALL flag an identifier collision
- AND it SHALL NOT silently drop either delivery

---

### Requirement: Unknown prior state cancels stale current and legacy identifiers

The system SHALL cancel every known current and legacy identifier for an affected date before scheduling when prior in-memory plan state is unknown.

#### Scenario: Per-day reschedule has no prior plan

- GIVEN a resolved active day has no prior in-memory scheduled plan
- WHEN the system schedules that day
- THEN it SHALL cancel current event identifiers, current daily identifiers, legacy dot identifiers, and legacy V1 identifiers for that date
- AND it SHALL cancel both notification identifiers and AlarmKit alarm identifiers before scheduling the resolved events

---

### Requirement: Reconciliation compares every expected notification

The system SHALL compare every expected notification delivery against pending notification requests.

#### Scenario: One of two expected notifications is missing

- GIVEN two future notification deliveries are expected
- AND only one matching pending notification request exists
- WHEN delivery reconciliation runs
- THEN the report SHALL flag the missing notification
- AND the aggregate status SHALL NOT be `scheduledAndVerified`

#### Scenario: Pending notification has wrong fire date

- GIVEN a future notification delivery is expected at a resolved fire date
- AND a pending notification with the same identifier exists at a different fire date outside tolerance
- WHEN reconciliation runs
- THEN the report SHALL flag a fire-date mismatch

---

### Requirement: Reconciliation compares every expected AlarmKit alarm

The system SHALL compare every expected AlarmKit delivery against pending AlarmKit state when AlarmKit inspection is available.

#### Scenario: AlarmKit alarm is missing

- GIVEN AlarmKit delivery mode is active
- AND an expected AlarmKit wake delivery exists
- AND no pending AlarmKit alarm exists with its identifier
- WHEN reconciliation runs
- THEN the report SHALL flag the missing alarm

#### Scenario: AlarmKit state cannot be inspected

- GIVEN AlarmKit delivery mode is active
- AND the platform adapter cannot expose pending AlarmKit state
- WHEN reconciliation runs
- THEN the system SHALL report verification as unavailable or pending
- AND it SHALL NOT falsely claim verified delivery

---

### Requirement: Reconciliation detects unexpected stale deliveries

The system SHALL detect and cancel unexpected pending deliveries inside the known Subh identifier universe.

#### Scenario: Legacy pending notification remains after migration

- GIVEN a pending notification uses a known legacy Subh identifier for a future date
- AND no resolved event expects that identifier
- WHEN reconciliation runs in repair mode
- THEN the system SHALL mark it as an unexpected stale delivery
- AND it SHALL cancel it if it is inside the refresh scope

---

### Requirement: Quiet cancels delivery without deleting underlying mode

The system SHALL treat Quiet as delivery suppression, not as deletion of underlying state.

#### Scenario: Quiet over Fast has stale wake alarm

- GIVEN the user previously had an active Fast wake for a date
- AND the user selects Quiet for that same date
- AND a stale pre-Fajr wake delivery still exists on the platform
- WHEN delivery reconciliation runs
- THEN the stale wake delivery SHALL be cancelled
- AND the underlying Fast state SHALL remain restorable outside the delivery layer
- AND the date SHALL report `notScheduledBecauseQuiet`

---

### Requirement: Audio role does not control activation

The system SHALL keep sound/audio selection separate from alarm activation and delivery eligibility.

#### Scenario: Fajr adhan audio wakes the user

- GIVEN a Fajr-mode wake event uses Fajr adhan audio
- WHEN delivery planning runs
- THEN the event SHALL remain an active expected delivery
- AND the system SHALL NOT treat adhan audio as an off state

#### Scenario: Later Fajr adhan cue is disabled

- GIVEN an Early + Fast non-Ramadan date has a pre-Fajr wake event
- AND a later Fajr-start adhan cue is disabled for that date
- WHEN delivery planning runs
- THEN the pre-Fajr wake delivery SHALL remain expected
- AND only the later Fajr-start cue SHALL be omitted or cancelled

---

### Requirement: Past events are not rescheduled by delivery

The system SHALL NOT shift or recreate past events inside the delivery layer.

#### Scenario: Wake event is already in the past

- GIVEN a resolved wake event fire date is earlier than or equal to `now`
- WHEN delivery planning runs
- THEN the event SHALL be excluded from future expected deliveries
- AND the delivery layer SHALL NOT shift it to tomorrow

---

### Requirement: Delivery ledger remains local and privacy-preserving

The system SHALL record scheduling, cancellation, and reconciliation decisions in a capped local ledger without remote analytics or raw location.

#### Scenario: Wake event scheduled

- WHEN the system records a schedule decision for a wake event
- THEN the ledger entry SHALL include date key, event type, delivery kind, fire date, channel, permission summary, lifecycle reason, and result
- AND it SHALL NOT include raw latitude/longitude or free-form location name
- AND it SHALL NOT send the entry to an external service

#### Scenario: Ledger exceeds retention cap

- GIVEN the ledger exceeds the configured age or entry cap
- WHEN a new ledger entry is saved
- THEN old entries SHALL be trimmed according to retention policy

---

### Requirement: Time and timezone changes force refresh and reconciliation

The system SHALL force schedule refresh and delivery reconciliation after significant time or timezone changes.

#### Scenario: Significant time change

- WHEN the app receives a significant time-change notification
- THEN the system SHALL request forced schedule refresh
- AND it SHALL reconcile platform delivery state for the refreshed schedule

#### Scenario: Timezone change

- WHEN the app receives a timezone-change notification
- THEN the system SHALL request forced schedule refresh
- AND it SHALL cancel stale identifiers and schedule the newly resolved events according to scope

---

### Requirement: Per-day edits are scoped

The system SHALL scope per-day delivery repairs to the affected date unless a parent invalidation requires a wider horizon refresh.

#### Scenario: User changes one date from Fajr to Quiet

- GIVEN the user changes one date to Quiet
- WHEN delivery refresh runs
- THEN stale deliveries for that date SHALL be cancelled
- AND unrelated future dates SHALL remain scheduled unless their identifiers are inside the explicit refresh scope

---

### Requirement: Diagnostics expose verification without becoming analytics

The system SHALL expose delivery diagnostics for support while avoiding remote tracking.

#### Scenario: Settings diagnostics displays report

- GIVEN delivery reconciliation has run
- WHEN the user opens settings diagnostics
- THEN the app MAY show expected delivery count, pending notification count, pending AlarmKit count, missing count, mismatch count, and last refresh reason
- AND it SHALL NOT upload that report automatically


### Requirement: Delivery schedules active scheduled horizon only

The system SHALL schedule only resolver-materialized events inside the active scheduled horizon supplied by the parent resolver/window builder.

#### Scenario: Visible days exceed scheduled horizon

- GIVEN Next 10 shows ten resolved mornings
- AND the active scheduled horizon contains only the next immediate wake event
- WHEN delivery planning runs
- THEN only the next immediate wake event SHALL be scheduled
- AND the other visible rows SHALL NOT be scheduled merely because they are visible

#### Scenario: Month view is browsed

- GIVEN a user opens a future/current month view
- AND the month contains planned or default wake states
- WHEN delivery planning runs
- THEN the month-view dates SHALL NOT be scheduled unless upstream resolution includes their events in the active scheduled horizon

---

### Requirement: Anchor movement refreshes old and new affected dates

The system SHALL support delivery refresh scopes containing multiple affected date keys caused by anchored intention movement.

#### Scenario: Ashura plan moves after Hijri adjustment

- GIVEN an observance-anchored Ashura fast previously resolved to March 12
- AND a Hijri adjustment moves the resolved Ashura date to March 13
- WHEN upstream resolution publishes affected date keys `{March 12, March 13}`
- THEN delivery SHALL cancel stale current and legacy identifiers for March 12 within scope
- AND delivery SHALL schedule March 13 only if its materialized event is inside the active scheduled horizon
- AND delivery SHALL NOT decide whether the Ashura intention should move

#### Scenario: New resolved date is outside active scheduled horizon

- GIVEN an anchored intention moves to a date outside the active scheduled horizon
- WHEN delivery refresh runs
- THEN delivery SHALL cancel stale deliveries on old affected date keys if needed
- AND it SHALL NOT create a platform delivery for the new date until the parent active scheduled horizon includes it

---

### Requirement: Delivery status does not mutate anchors or history

The system SHALL keep platform delivery outcomes separate from planning anchors and completion history.

#### Scenario: Observance wake cannot be scheduled

- GIVEN a future/current observance-anchored intention produces an active wake event inside the active scheduled horizon
- AND platform permission is denied
- WHEN delivery reports `permissionBlocked`
- THEN the intention anchor SHALL remain unchanged
- AND the morning state SHALL remain active with blocked delivery
- AND the app SHALL NOT convert it to Quiet, date-specific, or completed-history state

---

## 29. QA and test matrix

### 29.1 Unit tests

Codex should add or update unit tests for:

- expected delivery construction from scheduled events;
- notification vs AlarmKit channel selection;
- notification fallback degradation;
- permission-to-status mapping;
- deterministic notification identifiers;
- deterministic AlarmKit UUIDs;
- legacy identifier expansion;
- duplicate identifier detection;
- stale cancellation sets;
- missing pending notification detection;
- mismatched pending notification detection;
- missing pending AlarmKit detection through fake adapter;
- unexpected extra delivery detection;
- ledger retention and privacy fields;
- Quiet cancellation without intent mutation;
- Fajr adhan audio preserving activation;
- later Fajr-start cue toggle preserving pre-Fajr wake;
- cache reuse with reconciliation;
- delivery scheduling active scheduled horizon only, not visible range;
- anchor-movement scope cancellation for old/new date keys;
- no scheduling of month-browsed dates outside active scheduled horizon.

### 29.2 Integration tests

Codex should add or update integration tests for:

- `AlarmScheduler.scheduleAll` idempotency;
- per-day reschedule cancellation scope;
- full horizon refresh after settings/timezone change;
- `ScheduleRefreshCoordinator` launch/foreground reconciliation;
- Hijri adjustment / anchored intention movement causing old/new date refresh;
- `DeliveryReconciliationReport` aggregate status;
- settings diagnostics summary generation.

### 29.3 Static/architecture tests

Recommended architecture assertions:

- SwiftUI views do not call `NotificationScheduler`, `AlarmKitScheduler`, `AlarmCoordinator`, or platform cancellation APIs directly.
- SwiftUI views emit intents or call domain services only.
- `NotificationScheduler` and `AlarmKitScheduler` do not import SwiftUI.
- platform adapters do not import or call day-purpose/Hijri/tag resolvers.
- delivery layer does not calculate Fajr end or final-third start;
- delivery layer does not infer schedule scope from visibleDays or month browsing;
- delivery layer does not decide Hijri/observance anchor movement.

### 29.4 Manual physical-device QA

Run on a physical iPhone for:

1. AlarmKit authorization not determined -> request -> authorized -> schedule.
2. AlarmKit denied -> fallback behavior according to policy.
3. Notification permission denied -> active intent shows permission blocked, not Quiet.
4. App launch after manually deleting pending notification state if possible -> repair/reconciliation.
5. Foreground refresh after schedule state changes.
6. Significant time change.
7. Timezone change.
8. Fajr -> Quiet -> Fajr restoration with stale cancellation.
9. Fast -> Quiet -> Fast restoration with stale cancellation.
10. Later Fajr-start adhan toggle off while pre-Fajr wake remains active.
11. App terminated before alarm fires.
12. Reboot or device lock-state test where practical.
13. Silent/Focus behavior according to platform channel capabilities.
14. Hijri adjustment moves an observance inside the active scheduled horizon: old date stale delivery cancels, new date schedules.
15. Hijri adjustment moves an observance outside the active scheduled horizon: old date stale delivery cancels, new date is not scheduled yet.

### 29.5 Simulator QA

Run on simulator for:

- notification pending-request shape;
- fake AlarmKit adapter tests;
- reconciliation report tests;
- ledger tests;
- permission-state fakes;
- lifecycle notification handling.

Do not use simulator-only results to claim final audible AlarmKit reliability.

---

## 30. Codex implementation guidance

### 30.1 Recommended implementation sequence

1. OpenSpec discovery:
   - inspect existing `alarm-delivery-integrity`, `alarm-integrity-audit-and-hardening`, and `harden-alarm-pipeline-diagnostics` changes;
   - decide whether to create new `alarm-delivery-reliability` capability or expand existing `alarm-delivery-integrity`.

2. Write/validate OpenSpec:
   - `proposal.md`
   - `design.md`
   - `tasks.md`
   - `specs/alarm-delivery-reliability/spec.md`
   - run `openspec validate ... --strict`.

3. Audit current code:
   - `AlarmScheduler`
   - `RoutineScheduler`
   - `NotificationScheduler`
   - `AlarmKitScheduler`
   - `DeliveryReconciliationReport`
   - `AlarmDeliveryLedgerStore`
   - `SchedulingIdentifiers`
   - `SchedulingIdentifierSet`
   - `ScheduleRefreshCoordinator`
   - `SchedulingReconciler`.

4. Introduce structured delivery models if missing:
   - `DeliveryMode`
   - `DeliveryPermissionSnapshot`
   - `ExpectedAlarmDelivery`
   - `DeliveryTransactionResult`
   - `DeliveryFailure`
   - expanded `DeliveryReconciliationReport`.

5. Strengthen identifier/cancellation logic:
   - shared current/legacy identifier set;
   - date-scoped stale cancellation;
   - duplicate detection.

6. Strengthen reconciliation:
   - missing;
   - mismatched;
   - extras/stale;
   - platform unavailable;
   - aggregate/per-date statuses.

7. Strengthen ledger and diagnostics:
   - local-only;
   - capped retention;
   - support export summary;
   - no raw location.

8. Feed status back:
   - active intent + blocked delivery remains active intent;
   - Quiet is only parent activation suppression;
   - schedule status is structured.

9. Add tests and run validation.

### 30.2 Implementation non-goals for Codex

Codex must not:

- rewrite the morning resolver;
- change default Fajr wake time;
- change Fast/Fajr/Quiet semantics;
- add broad UI redesign;
- add remote analytics;
- add cloud sync;
- invent new prayer-time calculation;
- implement app-level snooze UX unless a separate spec exists;
- create duplicate platform schedulers instead of improving current adapters.

---

## 31. Acceptance checklist

Implementation is acceptable when all are true:

- [ ] There is a validated OpenSpec change for alarm delivery reliability.
- [ ] Delivery schedules from resolver-materialized events only.
- [ ] Delivery schedules only the active scheduled horizon, not visible/editable dates.
- [ ] No delivery layer recomputes Fajr begin/end, final-third, wake offsets, or religious intention.
- [ ] Notification and AlarmKit permissions are modeled separately.
- [ ] Notification fallback is represented as degraded for wake events.
- [ ] Identifiers are canonical and shared.
- [ ] Current and legacy stale identifiers are cancelled in affected scope.
- [ ] Reconciliation detects missing notification deliveries.
- [ ] Reconciliation detects mismatched notification fire dates.
- [ ] Reconciliation detects missing/mismatched AlarmKit deliveries where inspectable.
- [ ] Reconciliation detects unexpected stale deliveries inside Subh identifier universe.
- [ ] Cache reuse does not skip reconciliation.
- [ ] App launch and foreground refresh run reconciliation.
- [ ] Significant time and timezone changes force refresh and reconciliation.
- [ ] Hijri adjustment / anchored intention movement refreshes old and new affected date keys.
- [ ] Quiet cancels delivery without deleting underlying mode.
- [ ] Fajr adhan audio remains an active event, not off state.
- [ ] Later Fajr adhan toggle does not cancel pre-Fajr wake.
- [ ] Ledger is local-only, capped, and excludes raw location.
- [ ] Settings diagnostics summarize delivery state.
- [ ] Unit tests cover expected delivery, identifiers, reconciliation, permissions, and ledger.
- [ ] Integration tests cover schedule refresh, per-day scope, and cache reuse.
- [ ] Physical-device QA plan exists for AlarmKit and audible wake behavior.

---

## 32. Open questions

1. Should the permanent capability be named `alarm-delivery-reliability` or should the existing `alarm-delivery-integrity` name be retained?
2. Should notification fallback be automatic when AlarmKit is denied, or should the user explicitly choose fallback?
3. Which events are AlarmKit-eligible in MVP beyond wake events?
4. Should reminders use AlarmKit or remain notifications by default?
5. How should the app surface partial success when wake is scheduled but iftar notification is blocked?
6. Should the ledger export include raw platform identifiers or hashed identifiers only?
7. What is the final retention policy: 500 entries / 90 days, or a different product support threshold?
8. What physical-device QA matrix is required before TestFlight/App Store release?
9. Should the active scheduled horizon remain next-immediate-only in MVP, or should it include a safety buffer?
10. What exact handoff type should represent `visibleDateKeys`, `editableDateKeys`, `activeScheduledDateKeys`, and `affectedDateKeys` in the current codebase?

---

## 33. Bottom-line implementation rule

Codex should implement this spec as a reliability layer, not a second morning-resolution layer.

The delivery layer receives:

```text
resolved active days + resolved scheduled events + permission/mode settings
```

It produces:

```text
expected platform deliveries + reconciliation report + delivery status + local diagnostics
```

It must never decide:

```text
what the morning means
why the user is waking
whether a fast is intended
what Fajr begin/end are
whether Quiet deleted the underlying mode
```

That separation is the heart of the architecture.
