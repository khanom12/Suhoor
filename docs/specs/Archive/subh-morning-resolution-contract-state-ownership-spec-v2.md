# Subh Morning Resolution Contract and State Ownership Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-resolution-contract-state-ownership-spec-v2.md` |
| Version | 2 |
| Spec status | Draft; reconciled Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v1.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-quick-wake-mode-intent-mutation-contract-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v2.md`, `subh-fajr-time-calculation-determination-selection-spec-v1.md` |
| Owning domain / surface | Core morning resolution graph and state ownership |
| Implementation audit status | Needs implementation audit |

## Purpose
Define the canonical one-morning object graph and the source-of-truth hierarchy that all surfaces, scheduling, and persistence should consume.

## What This Spec Owns
- Morning resolution inputs, derived outputs, overrides, and observed outcomes.
- State ownership boundaries between core resolution, surfaces, scheduling, storage, and diagnostics.
- Cross-surface consistency rules for resolved morning state.

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

- The canonical exposed quick wake modes are `Suhoor`, `Fajr`, and `Quiet`.
- `Suhoor` is the only MVP before-Fajr user-facing wake mode.
- `Tahajjud only`, `Other early worship`, and generic `Pre-Fajr` are deferred and must not be resolved into active selectable MVP states.
- Legacy persisted or internal values may be normalized into the Suhoor path for compatibility, but they must not create a parallel morning engine.
- Day meaning, fasting opportunity, Suhoor intention, wake boundary, wake time, alarm activation, delivery status, and completion credit remain separate concepts.
- Fasting opportunities alone must not trigger a Suhoor wake. Suhoor intent or a stronger calendar-obligatory fasting state must be present.
- Day Detail saves and resets immediately in MVP.

## 0. One-page summary

Subh already has a clear product doctrine: it is a **Fajr-centered morning system**. Suhoor, fasting, Ramadan, Qada, observance opportunities, Quiet Mode, and one-day edits are not separate engines. They are layered states over the same morning-resolution system.

This specification turns that doctrine into an implementation contract.

For any morning date, Subh must produce one canonical resolved morning object graph. Home Hero, Alarm Detailed View, Weekly Fajrcast, Next 10 Mornings, alarm scheduling, notification copy, completion logic, and analytics must consume that resolved graph instead of independently re-deriving prayer windows, wake modes, day meaning, or alarm state.

The central contract is:

```text
Supported current range / target date
    + calendar version / Hijri context
    + resolved prayer window
    + resolved day meaning / observance opportunities
    + anchored user intention / date-specific override
    + wake boundary regime
    + wake time
    + alarm activation
    + materialized scheduled events inside the active scheduled horizon
    + delivery / schedule status
    + copy and surface snapshots
    = one resolved Subh morning
```

The most important separation is:

```text
Day meaning ≠ user intention ≠ wake boundary ≠ wake time ≠ alarm activation ≠ delivery status ≠ completion credit
```

Examples:

```text
A White Day can be an opportunity without becoming a fasting intention.
A user can intend a Fast wake while alarm delivery is permission-blocked.
Quiet Mode can suppress delivery without deleting the underlying Fast or Fajr mode.
A Fajr adhan audio role can wake the user without meaning the alarm is off.
A manual drag can move a wake time without changing fasting purpose.
```

This spec does not replace the visual specs. It defines the system layer those visual specs must consume.

---


## 0.1 v2 Alignment Summary

This revision explicitly aligns the one-morning resolution contract with the Planning Horizon / Intention Anchoring spec and the Alarm Delivery / Schedule Reliability spec.

The three-spec boundary is:

| Spec | Owns | Must not own |
|---|---|---|
| Planning Horizon / Intention Anchoring | supported current range, display/edit horizons, intention anchors, calendar-context snapshots, Hijri adjustment rebinds, affected-date sets, cache doctrine | platform scheduling, one-off UI-local wake state, delivery verification |
| Morning Resolution Contract | canonical one-morning object graph, day purpose, intention application, wake boundary, wake time, activation, materialized events, surface snapshots, schedule-status feedback | platform pending-state verification, month cache as source of truth, durable generated defaults |
| Alarm Delivery Reliability | channel choice, permission state, platform scheduling, stale cancellation, reconciliation, ledger, diagnostics | day meaning, Hijri observance movement, user intention selection |

The central flow is:

```text
Stored settings + anchored intentions + calendar context + target date
        ↓
Canonical one-morning resolution
        ↓
ResolvedDaySnapshot + ResolvedMorningWakeState + materialized events
        ↓
Active scheduled horizon handoff
        ↓
Alarm delivery scheduling/reconciliation
```

### v2 key clarification

Date-specific overrides are only one kind of stored user meaning. Observance, Hijri-date, weekday, Hijri-month-window, immediate-alarm, and default-setting anchors may all produce or affect a morning. The morning resolver consumes the resulting applicable records for a target date; it does not assume that every persisted user decision is keyed only by Gregorian `dateKey`.

---

## 1. Purpose

This spec defines the canonical Subh morning-resolution contract and state-ownership rules.

It answers:

```text
For a target morning, what object is canonical?
Which service resolves it?
Which stores feed it?
Which services may mutate it?
Which layers may schedule alarms?
Which surfaces consume it?
Which logic is forbidden inside SwiftUI views?
How do date-specific edits persist?
How does Quiet Mode preserve underlying state?
How do prayer windows, day purpose, wake modes, scheduling, and UI snapshots stay synchronized?
```

The objective is to prevent duplicate state machines across:

- Home Hero
- Alarm Detailed View
- Weekly Fajrcast
- Next 10 Mornings
- alarm scheduling
- notification copy
- completion/progress
- analytics credit
- settings and plan logic

This spec is intentionally broader than a component spec and narrower than a full app architecture document. It owns the **morning-resolution system boundary**.

---

## 2. Problem statement

The current product direction is clear, and several existing specs already describe pieces of the system. However, those specs are distributed across surfaces and domains.

Without a single system-layer contract, implementation can drift in these ways:

1. The Home Hero decides one wake mode while Alarm Detail decides another.
2. Weekly Fajrcast plots one wake marker while the scheduler materializes another wake event.
3. Next 10 rows infer `[Fasting]` from tags even though the user has not intended a fast.
4. Quiet Mode deletes the prior mode instead of suppressing delivery as an overlay.
5. A permission failure is displayed as no-alarm or quiet even though the user selected an active wake.
6. SwiftUI views recalculate Fajr end or final-third start locally.
7. Date-specific changes mutate global settings or generated plans.
8. Audio role is confused with alarm activation, especially around Fajr adhan behavior.
9. Completion and analytics credit count an observance merely because it was available on that date.
10. Cache invalidation and rescheduling rules differ between Home, forecast rows, and delivery.

This spec prevents those failures by defining a single source-of-truth pipeline.

---

## 3. Scope

This spec owns:

- canonical morning-resolution object graph
- source-of-truth hierarchy
- resolver pipeline order
- domain/service ownership boundaries
- state and persistence ownership
- date-specific override rules
- user-intent mutation contract
- Quiet Mode overlay semantics
- alarm activation vs schedule/delivery status separation
- scheduler handoff contract
- surface snapshot input/output boundaries
- cache invalidation and reschedule triggers
- cross-surface acceptance criteria

This spec does not own:

- exact Morning Hero layout, typography, spacing, or animation
- exact Alarm Detail visual composition
- Weekly Fajrcast chart geometry
- Next 10 row grid details
- full prayer-time method catalog or provider policy
- full alarm-delivery reliability diagnostics
- full Hijri/observance calendar derivation
- full completion/progress analytics reporting UI

Those remain in child specs. This spec defines how they connect.

---

## 4. Related specs and consolidation map

This spec consolidates the system-layer responsibilities scattered across several specs. It does not erase their surface or domain details.

### 4.1 Specs this consolidates at the architecture layer

| Existing spec | What remains there | What moves into this contract |
|---|---|---|
| Wake State Selection and Alarm Resolution v2 | Wake-state concepts and examples | canonical state ownership, pipeline, mutation contract, scheduler handoff |
| Morning Hero Item v12 | hero layout, copy, interaction, animation | rule that hero consumes resolved state and emits intents only |
| Alarm Detailed View v4 | selected-day UI and context card behavior | rule that detail consumes same resolved state and commits date-specific intents only |
| Weekly Fajrcast v15 | seven-day chart rendering and interaction | rule that chart consumes resolved snapshots and live preview values only |
| Next 10 Mornings v3 | ten-row visual/tag contract | rule that rows consume resolved tags and must not infer intention locally |
| Early Worship Boundary v1 | final-third calculation and boundary semantics | ownership of final-third resolver in the canonical pipeline |
| Fajr Time Calculation v1 | prayer-time method/source policy | rule that all surfaces consume the same `DailyPrayerWindow` |
| Day Purpose / Opportunity Resolution v1 | opportunity/intention/credit model | rule that meaning, intention, execution, and credit are separate layers |

### 4.2 Child specs that remain necessary

The following should remain separate because they own specialized details:

1. **Fajr Time Calculation, Determination, and Selection** — prayer-time methods, provider sources, high-latitude policy, Fajr begin/end, adjustments, diagnostics.
2. **Day Purpose, Observance Opportunity, Intention, Outcome, and Analytics Credit** — Islamic observance semantics, intention links, completion rules, credit rules.
3. **Planning Horizon, Day Resolution, and Intention Anchoring** — supported current range, display/edit horizons, intention anchors, Hijri adjustment movement, month browsing, generated-vs-stored doctrine, affected-date sets.
4. **Alarm Delivery and Schedule Reliability** — AlarmKit, notification fallback, pending request reconciliation, permissions, silent failure diagnostics.
5. **Morning Hero** — top home surface visual and interaction details.
6. **Alarm Detailed View** — selected-day editor visual and control details.
7. **Weekly Fajrcast** — chart component behavior and dynamic layout.
8. **Next 10 Mornings** — ten-row forecast layout, tags, and accessibility.

---

## 5. One-sentence definition

**The Subh Morning Resolution Contract is the domain architecture that turns location, prayer windows, Hijri/observance context, user intention, date-specific overrides, wake rules, alarm activation, and delivery feedback into one resolved morning state consumed by every surface and scheduler.**

---

## 6. Product doctrine

Subh is a Fajr-centered morning system for Muslims.

The product spine is:

```text
default Fajr rhythm
    → date-specific meaning
    → user intention
    → wake execution
    → completion
    → progress reflection
```

This implies:

- Fajr is the base morning anchor.
- Fasting modifies the base morning when intended or obligatory.
- Ramadan is a seasonal intensification of the same system, not a separate engine.
- Qada is a fast designation inside the same morning system.
- Tahajjud is an early-worship refinement, not a separate alarm engine.
- Observances may create opportunities without creating obligations.
- Quiet Mode suppresses wake delivery without deleting the underlying morning meaning.
- Date-specific edits modify one morning, not the global plan unless explicitly performed from global settings.

Forbidden product interpretations:

```text
separate Fajr engine
separate fasting engine
separate Ramadan engine
separate Tahajjud engine
separate UI-local alarm state machines
separate chart/list/detail prayer-boundary calculations
```

---

## 7. Current implementation anchors

The current codebase already contains many of the right building blocks. This spec stabilizes the boundaries between them.

### 7.1 Existing central scheduling resolver

`MorningScheduleResolver` currently resolves the prayer window, selected plan, wake anchor, wake time, resolved day context, behavior profile, materialized events, decision log, completion state, and `ResolvedDayPurpose`, then returns `ResolvedDaySnapshot`.

This spec treats `ResolvedDaySnapshot` as the canonical day aggregate for schedule/planning resolution.

### 7.2 Existing wake-resolution service

`MorningWakeResolutionService` currently resolves from `ActiveAlarmDay` into `ResolvedMorningWakeState`, including:

- selected quick wake mode
- underlying mode
- day context
- wake boundary resolution
- wake time resolution
- alarm activation
- schedule status
- visual mode
- boundary regime
- copy state
- accessibility summary

This spec treats `ResolvedMorningWakeState` as the canonical wake-state aggregate for UI and scheduler handoff.

### 7.3 Existing wake-state selection resolver

`WakeStateSelectionResolver` currently owns selection of quick mode, underlying mode, day-context kind, and applying quick modes into `DailyAlarmOverride`.

This spec requires that all quick wake-state mutations go through one intent-handling path, not direct SwiftUI mutation.

### 7.4 Existing early-worship boundary resolver

`EarlyWorshipBoundaryResolver` currently calculates final-third start from the target Fajr start and Maghrib. This spec makes that resolver the canonical owner of final-third calculation.

### 7.5 Existing day-purpose layer

The codebase already has a `ResolvedDayPurpose` concept and a `DayPurposeResolver` integration. This spec uses that layer as the canonical way to distinguish:

```text
meaning → intention → wake classification → required actions → analytics credits
```

---

## 8. Canonical source-of-truth graph

### 8.1 Required dependency direction

```text
Location + timezone + prayer settings
        + supported current range / target date
        + stored anchored intentions and overrides
        + calendar context / Hijri adjustment state
        ↓
Prayer-time resolver
        ↓
DailyPrayerWindow
        ↓
Hijri / observance / date-source / fast-domain resolvers
        ↓
ResolvedDayPurpose
        ↓
Plan resolver + anchored-intention/date-specific override resolver
        ↓
MorningScheduleResolver
        ↓
ResolvedDaySnapshot
        ↓
ActiveDayResolver / ActiveAlarmDay builder
        ↓
MorningWakeResolutionService
        ↓
ResolvedMorningWakeState
        ↓
Surface snapshots + active scheduled horizon + scheduler commands
        ↓
SwiftUI views + AlarmCoordinator / notification layer
```

### 8.2 Forbidden reverse dependencies

The following must not happen:

```text
SwiftUI view → calculates finalThirdStart
SwiftUI view → derives Fajr end
SwiftUI view → schedules or cancels alarms directly
SwiftUI view → writes DailyAlarmOverride directly
Weekly Fajrcast → searches for its own next alarm outside snapshot
Next 10 row → infers fasting intention from tag text
Alarm Detail → creates a separate resolver or persistence model
Notification builder → redefines morning intention
Delivery failure → rewrites user quick wake selection
Completion analytics → counts every available opportunity as completed
```

---

## 9. Canonical object model

### 9.1 `DailyPrayerWindow`

Owns resolved prayer boundaries for a local morning.

Required fields, conceptually:

```text
DailyPrayerWindow
- date
- dateKey
- timeZone
- locationResolution
- fajrStart / fajrBegins
- fajrEnd / sunrise boundary
- maghrib
- method/source metadata
- adjustment metadata
- high-latitude metadata
- rounding policy metadata
- availability / diagnostics state
```

Ownership rules:

- Fajr begin comes from the prayer-time resolver.
- Fajr end is first-class, normally sunrise-derived.
- Maghrib is resolved by the prayer-time resolver and consumed by final-third calculation.
- Surfaces must not invent missing Fajr end.
- Surfaces must not apply separate manual adjustments.
- A prayer-window change invalidates resolved morning snapshots and scheduled events.

### 9.2 `ResolvedDayPurpose`

Owns what the date means and what the user intends.

Required fields, conceptually:

```text
ResolvedDayPurpose
- dateKey
- opportunities
- intention
- wakeClassification
- requiredActions
- analyticsCredits
- explanation
```

Ownership rules:

- Observance opportunities are not intentions.
- Intentions can select or link to opportunities.
- Required actions depend on intention, not mere opportunity.
- Analytics credit depends on opportunity + intention + outcome, not visible tags alone.
- Quiet suppresses prompts without deleting opportunities.

### 9.3 `ResolvedDaySnapshot`

Owns the canonical resolved day aggregate.

Required fields, conceptually:

```text
ResolvedDaySnapshot
- date
- dateKey
- prayerWindow
- resolvedDayContext
- resolvedDayPurpose
- selectedPlan
- resolvedBehaviorProfile
- wakeAnchor
- wakeResolution
- materializedEvents
- decisionLog
- completionRecords
- dailyCompletion
- completionSummary
```

Ownership rules:

- This is the canonical day-level aggregate for schedule/planning.
- It is allowed to include rich decision logs and diagnostics.
- It must not be replaced by a surface-specific aggregate as a source of truth.

### 9.4 `ResolvedMorningWakeState`

Owns the canonical user-facing wake state for one morning.

Required fields, conceptually:

```text
ResolvedMorningWakeState
- dateKey
- morningDate
- dayContext
- quickWakeSelection
- underlyingWakeMode
- boundaryRegime
- wakeBoundaryResolution
- wakeTimeResolution
- alarmActivation
- scheduleStatus
- visualMode
- copyState
- persistenceState
- accessibilitySummary
```

Ownership rules:

- It is derived from `ResolvedDaySnapshot` / `ActiveAlarmDay`.
- It is the canonical input for hero/detail/list/chart wake-state presentation.
- It separates activation from delivery status.
- It preserves underlying mode under Quiet.
- It carries copy state so surfaces do not recompute relation strings independently.

### 9.5 Surface snapshots

Surface snapshots are layout-ready values only.

Examples:

```text
MorningHeroSnapshot
AlarmDetailSnapshot
WeeklyFajrcastSnapshot
NextTenMorningsSnapshot
NotificationCopySnapshot
```

Surface snapshots may own:

- preformatted labels
- visual-mode flags
- display times
- relation copy
- accessibility strings
- row/chart/card-specific layout payloads
- live preview values supplied by the parent/data layer

Surface snapshots must not own:

- prayer-time calculation
- final-third calculation
- intention inference
- schedule materialization
- completion credit rules
- alarm delivery state transitions

### 9.6 `ScheduledEvent` and scheduler commands

`ScheduledEvent` owns materialized schedule intentions.

Required conceptual separation:

```text
ResolvedMorningWakeState.alarmActivation = what the user/app intends
ScheduledEvent = what should be scheduled
Alarm delivery state = what the platform actually has pending or delivered
```

Scheduler commands must be derived from resolved snapshots. They must not redefine wake intent.


### 9.7 `UserIntentionRecord`, `IntentionAnchor`, and planning records

The morning resolver must support applicable stored user meaning that is not always keyed only by Gregorian date.

Conceptual model:

```text
UserIntentionRecord
- intentionID
- anchor
- intentionKind
- wakeRule, if any
- fastPurpose, if any
- selectedOpportunityIDs, if any
- createdFromDateKey
- calendarContextAtCreation
- currentResolvedDateKeys
- reviewState
```

Conceptual anchor types:

```text
IntentionAnchor
- gregorianDate(dateKey)
- gregorianRange(startDateKey, endDateKey)
- hijriDate(year/month/day or recurring month/day rule)
- observance(observanceID, occurrenceRule)
- weekdayPattern(weekdays)
- hijriMonthWindow(monthID, windowRule)
- immediateAlarm(alarmInstanceID or nextActiveAlarmToken)
- defaultSetting(scope)
- completionHistory(dateKey, historicalCalendarSnapshot)
```

Ownership rules:

- The Planning Horizon / Intention Anchoring spec owns anchor semantics, rebind behavior, and affected-date sets.
- The Morning Resolution Contract consumes all anchored records applicable to the target morning.
- A Gregorian `MorningDateOverride` remains valid for date-specific edits, but it is not sufficient for observance-based or recurring anchored plans.
- The resolver must distinguish passive opportunity tags from stored intention records.
- Completion-history anchors are read for historical display/credit and must not be moved by future calendar changes.

### 9.8 `PlanningWindowSnapshot` and horizon roles

When resolving multiple mornings for a surface or scheduler, the parent/window builder should expose role-specific date sets.

Conceptual model:

```text
PlanningWindowSnapshot
- generatedAt
- targetTimeZone
- knowledgeRange
- visibleDateKeys
- editableDateKeys
- activeScheduledDateKeys
- affectedDateKeys, when caused by a change
- resolvedDaySnapshots
```

Rules:

- `visibleDateKeys` powers surfaces such as Next 10 and month browsing.
- `editableDateKeys` identifies dates where user changes are allowed by product policy.
- `activeScheduledDateKeys` identifies dates/events that may be handed to alarm delivery.
- The delivery layer must not infer `activeScheduledDateKeys` from `visibleDateKeys`.
- Current MVP may make `activeScheduledDateKeys` contain only the next immediate wake event/date; future releases may include a small safety buffer without changing surface logic.

---

## 10. Ownership matrix

| Concern | Canonical owner | Consumers | Forbidden duplication |
|---|---|---|---|
| Local date key | date/time utility using resolved timezone | all stores, resolvers, surfaces | system timezone shortcuts for target location dates |
| Supported current/planning range | Planning Horizon / window builder | resolvers, surfaces, scheduler handoff | views hard-coding Next 10 as full product range |
| Intention anchors | Planning Horizon / intention store | DayPurposeResolver, MorningScheduleResolver, detail surfaces | dateKey-only persistence for observance-based plans |
| Calendar context at creation | Planning Horizon / intention store | explanations, review banners, audit/debug | treating old context as current truth |
| Affected date set after anchor movement | Planning Horizon / rebind service | resolver cache invalidation, delivery refresh | delivery guessing old/new dates from tag text |
| Location display used for Fajr | location resolver / prayer-time input | Morning Hero, settings, diagnostics | UI geocoding inside hero |
| Fajr begins | prayer-time resolver | all surfaces, schedule resolver | chart/detail/row local calculation |
| Fajr ends | prayer-time resolver | Hero, Fajrcast, Next 10, scheduler | renderer-invented offset |
| Maghrib | prayer-time resolver | final-third, iftar, Ramadan/fasting | separate sunset calculation in UI |
| Final-third start | EarlyWorshipBoundaryResolver | wake resolver, hero/detail | SwiftUI or chart calculation |
| Observance opportunities | ObservanceOpportunityResolver / DayPurposeResolver | tags, detail, analytics | string parsing from UI tags |
| Day intention | DayIntentionResolver / date-specific intention store | plan resolver, wake resolver, completion | visual tag heuristics |
| Quick wake selection | WakeStateSelectionResolver / intent mutation service | hero, detail, rows | direct `DailyAlarmOverride` writes by views |
| Underlying mode under Quiet | wake-state resolver + date-specific override | hero/detail/list/chart | losing mode when quieted |
| Wake boundary regime | MorningWakeResolutionService | hero/detail/Fajrcast | surface-specific boundary state machines |
| Wake time | MorningScheduleResolver + MorningWakeResolutionService | scheduler, surfaces | independent Fajr offset math in views |
| Wake-time origin | wake resolver | detail copy, diagnostics, tests | guessing from current time only |
| Alarm activation | MorningWakeResolutionService | surfaces, scheduler handoff | audio-role logic or delivery status |
| Scheduled events | MorningScheduleResolver | AlarmCoordinator, notifications | SwiftUI event creation |
| Schedule/delivery status | alarm pipeline | warning surfaces, detail/status | wake-intent resolver rewriting selection |
| Fajr adhan audio role | behavior profile / event sound role | scheduler, detail controls | treating adhan as alarm off |
| Completion outcome | completion resolvers | progress, day detail | tag-based completion inference |
| Analytics credit | DayPurpose / credit resolver | progress reports | visible tags as analytics truth |

---

## 11. Canonical resolution pipeline

Resolution must happen in this order.

```text
1. Resolve target morning date and dateKey.
2. Resolve location and timezone.
3. Resolve DailyPrayerWindow:
   - Fajr begins
   - Fajr ends
   - Maghrib
   - source/method/adjustment metadata
4. Resolve Hijri/date-source/observance context.
5. Resolve observance opportunities.
6. Resolve applicable user intention records:
   - default Fajr
   - Fast
   - Tahajjud
   - Quiet
   - Ramadan auto-fast
   - Qada or other assigned fast
   - observance-anchored intentions
   - Hijri-date or Hijri-window intentions
   - weekday-pattern intentions
   - Gregorian-date/range overrides
   - immediate-alarm scoped overrides
7. Resolve effective plan and anchored/date-specific overrides.
8. Resolve wake anchor and preliminary wake time.
9. Resolve wake boundary regime:
   - Fajr begins → Fajr ends
   - finalThirdStart → Fajr begins
   - quiet-preserved variant
   - unavailable/out-of-range variant
10. Resolve final wake time and wake-time origin.
11. Resolve alarm activation.
12. Materialize scheduled events.
13. Mark whether materialized events are inside the active scheduled horizon.
14. Resolve schedule/delivery status from the alarm pipeline.
15. Resolve visual mode.
16. Resolve copy state and accessibility summary.
17. Resolve completion requirements and analytics credits.
18. Emit surface snapshots.
19. Persist committed anchored/date-specific changes and invalidate dependent caches.
```

### 11.1 Required layering principle

Later layers may depend on earlier layers. Earlier layers must not depend on later layers.

For example:

- Day intention may choose early-worship boundary.
- Boundary may constrain wake time.
- Wake time may materialize a wake alarm event.
- Alarm delivery may report `permissionBlocked`.
- `permissionBlocked` must not rewrite the day intention to Quiet.

---

## 12. State model

### 12.1 Quick wake mode

User-facing quick choices:

```text
Fast | Fajr | Quiet
```

Conceptual enum:

```swift
enum QuickWakeMode {
    case fast
    case fajr
    case quiet
}
```

Rules:

| Quick mode | Meaning | Default wake effect | Boundary |
|---|---|---|---|
| `fajr` | ordinary Fajr-centered wake | 30 min before Fajr ends | Fajr begins → Fajr ends |
| `fast` | user intends fasting / pre-Fajr wake | 30 min before Fajr begins | finalThirdStart → Fajr begins |
| `quiet` | suppress wake delivery for this date | preserve underlying wake anchor | same as underlying mode, static |

Important:

- `Fast` is a quick wake state and may initially create a generic fast intention.
- Detail surfaces may refine Fast into Ramadan, Qada, Vow, Kaffarah, Other, etc.
- `Quiet` is an overlay, not a deleted state.

### 12.2 Day intention kind

Conceptual enum:

```swift
enum DayIntentionKind {
    case defaultFajr
    case fast
    case tahajjud
    case quiet
}
```

Rules:

- `defaultFajr` is the fallback intention for ordinary mornings.
- `fast` can be auto-Ramadan, user-selected, qada-assigned, generated from a plan, or migrated from old fast tag selections.
- `tahajjud` is early-worship without fast-purpose controls.
- `quiet` suppresses prompts/delivery but preserves opportunities and underlying mode.

### 12.3 Day context kind

Conceptual taxonomy:

```swift
enum MorningWakeDayContextKind {
    case ordinary
    case fajrIntendedOnly
    case fastingOpportunity
    case fastingIntended
    case ramadanFasting
    case qadaFastIntended
    case sunnahFastIntended
    case customFastIntended
    case tahajjudIntended
    case fastingAndTahajjudIntended
    case observanceOnly
    case adjusted
    case unknown
}
```

Rules:

- Opportunity-only contexts do not shift the boundary to early-worship.
- Intended fasting, Ramadan, Qada, custom fast, Sunnah fast, and Tahajjud use early-worship.
- Manual adjustment alone does not create religious intention.

### 12.4 Boundary regime

Conceptual enum:

```swift
enum WakeBoundaryRegime {
    case defaultFajrWindow
    case earlyWorshipWindow
    case quietDefaultFajrWindow
    case quietEarlyWorshipWindow
    case customOutOfRange
    case unavailable
}
```

Rules:

- `defaultFajrWindow` uses `fajrBegins → fajrEnds`.
- `earlyWorshipWindow` uses `finalThirdStart → fajrBegins`.
- Quiet variants preserve the underlying boundary but remove interactivity.
- `customOutOfRange` preserves saved value but must not render a misleading adjuster.
- `unavailable` must not guess missing boundaries.

### 12.5 Wake-time origin

Conceptual enum:

```swift
enum WakeTimeOrigin {
    case globalDefaultFajrOffset
    case globalDefaultFastOffset
    case quickSelectorDefault
    case manualDragOverride
    case dateSpecificOverride
    case planGenerated
    case restoredPersistedValue
    case clampedToBoundary
    case noWakeAnchor
    case unavailable
}
```

Rules:

- Wake time must carry origin.
- Dragging stores a date-specific wake-time override or mode-specific date override.
- Generated Ramadan/Qada/Sunnah plans should not be confused with manual drag.
- Restoring from Quiet should prefer prior mode-specific date value over global default.

### 12.6 Alarm activation

Conceptual enum:

```swift
enum AlarmActivation {
    case active
    case quietSuppressed
    case offWithAnchor
    case noAnchor
    case unavailable
}
```

Rules:

- Activation describes the user's/app's intended wake behavior.
- Activation does not prove the platform has successfully scheduled anything.
- `active` can coexist with `permissionBlocked` schedule status.
- `quietSuppressed` means the user selected Quiet for the date.
- `offWithAnchor` preserves a planned wake anchor while suppressing active delivery.

### 12.7 Schedule status

Conceptual enum:

```swift
enum MorningWakeScheduleStatus {
    case scheduled
    case pending
    case failed
    case permissionBlocked
    case notScheduledBecauseQuiet
    case notScheduledBecauseNoAnchor
    case notScheduledBecauseUnavailable
    case unavailable
}
```

Rules:

- Schedule status describes the delivery pipeline result.
- It must not rewrite quick wake selection, day intention, or underlying mode.
- It may produce warning copy.
- The alarm-delivery reliability spec owns deeper platform semantics.

### 12.8 Visual mode

Conceptual enum:

```swift
enum MorningWakeVisualMode {
    case interactiveDefaultFajr
    case staticDefaultFajrQuiet
    case interactiveEarlyWorship
    case staticEarlyWorshipQuiet
    case staticNoAlarmWithBoundaries
    case hiddenUnavailable
    case hiddenOutOfRange
}
```

Rules:

- Visual mode is derived from boundary, wake time, and activation.
- Visual mode does not mutate state.
- Surface renderers consume visual mode instead of inventing their own eligibility rules.

---

## 13. Day meaning, intention, execution, and credit

This contract adopts the Day Purpose rule:

```text
Meaning is not intention.
Intention is not execution.
Execution is not automatically credited to every meaning on the date.
```

### 13.1 Opportunity-only morning

Example:

```text
Date: White Day
User selection: Fajr
```

Resolved behavior:

```text
opportunities = [White Days]
intention = defaultFajr
quickWakeSelection = fajr
boundaryRegime = defaultFajrWindow
wake target = Fajr end - default offset
tags may show [Fajr] [White Days]
fast required actions = none
fast completion credit = none unless user later intends/logs appropriately
```

### 13.2 Intended fast morning

Example:

```text
Date: White Day
User selection: Fast
```

Resolved behavior:

```text
opportunities = [White Days]
intention = fast
selectedOpportunityIDs may include White Days
quickWakeSelection = fast
boundaryRegime = earlyWorshipWindow
wake target = Fajr begins - default fast offset
tags may show [Fasting] [White Days]
fast required actions = yes
analytics planned credit = yes
completion credit = only if outcome supports it
```

### 13.3 Ramadan morning

Resolved behavior:

```text
opportunities includes Ramadan
intention = fast by default unless future exception policy applies
quickWakeSelection = fast / Early by default
boundaryRegime = earlyWorshipWindow
fast purpose = Ramadan fast, locked
Fajr adhan-at-Fajr-begins behavior = locked according to Ramadan policy
other fasting opportunities suppressed as alternatives
```

Changing Ramadan to Fajr or Quiet changes wake execution, not the underlying Ramadan day context.

### 13.4 Qada morning

Resolved behavior:

```text
intention = fast only when user selected or assigned Qada
boundaryRegime = earlyWorshipWindow
primary analytics credit = Qada
Sunnah opportunity may remain visible but must not auto-credit completion
```

### 13.5 Tahajjud morning

Resolved behavior:

```text
intention = tahajjud
boundaryRegime = earlyWorshipWindow
fast-purpose selector hidden
fast required actions = none
Fajr/observance tags may remain informational where appropriate
```

### 13.6 Quiet morning

Resolved behavior:

```text
intention or activation overlay = quiet
underlying mode preserved
opportunities preserved
alarmActivation = quietSuppressed
scheduleStatus = notScheduledBecauseQuiet
visualMode = static quiet variant
required actions suppressed by default
analytics may record suppressedByQuiet, not missed
```

---

## 14. User intent mutation contract

SwiftUI views may emit user intents. They must not mutate stores or schedule alarms directly.

### 14.1 Required intent API

The app should expose one intent-handling service, conceptually:

```swift
protocol MorningWakeIntentHandling {
    func selectWakeMode(dateKey: String, mode: QuickWakeMode) async throws -> ResolvedMorningWakeState
    func previewWakeAdjustment(dateKey: String, proposedWakeTime: Date) -> ResolvedMorningWakeState
    func commitWakeAdjustment(dateKey: String, finalWakeTime: Date) async throws -> ResolvedMorningWakeState
    func selectEarlyPurpose(dateKey: String, purpose: EarlyWakePurpose) async throws -> ResolvedMorningWakeState
    func selectFastPurpose(dateKey: String, purpose: FastIntentSelection) async throws -> ResolvedMorningWakeState
    func createAnchoredIntention(anchor: IntentionAnchor, intention: UserIntentionDraft) async throws -> PlanningMutationResult
    func updateAnchoredIntention(intentionID: String, update: UserIntentionUpdate) async throws -> PlanningMutationResult
    func deleteAnchoredIntention(intentionID: String) async throws -> PlanningMutationResult
    func applyHijriCalendarAdjustment(_ adjustment: HijriCalendarAdjustment) async throws -> PlanningMutationResult
    func toggleFajrAdhanAtFajrBegins(dateKey: String, enabled: Bool) async throws -> ResolvedMorningWakeState
    func restoreDefaultWake(dateKey: String) async throws -> ResolvedMorningWakeState
}
```

Names may differ in implementation. The ownership boundary must not differ.

### 14.2 Allowed user intents

```text
SelectWakeMode(dateKey, .fajr)
SelectWakeMode(dateKey, .fast)
SelectWakeMode(dateKey, .quiet)
PreviewWakeTimeAdjustment(dateKey, proposedWakeTime)
CommitWakeTimeAdjustment(dateKey, finalWakeTime)
SelectEarlyPurpose(dateKey, .fast)
SelectEarlyPurpose(dateKey, .tahajjud)
SelectFastPurpose(dateKey, fastType)
CreateAnchoredIntention(anchor, intention)
UpdateAnchoredIntention(intentionID, update)
DeleteAnchoredIntention(intentionID)
ApplyHijriCalendarAdjustment(adjustment)
ToggleFajrAdhanAtFajrBegins(dateKey, enabled)
RestoreDefaultWake(dateKey)
```

### 14.3 Forbidden view behavior

SwiftUI views must not:

```text
calculateFinalThirdStart(...)
deriveFajrEnd(...)
createAlarm(...)
cancelAlarm(...)
writeDailyAlarmOverrideDirectly(...)
inferFastingFromDraggedWakeTime(...)
inferTahajjudFromDraggedWakeTime(...)
treatFajrAdhanAudioAsAlarmOff(...)
compose independent schedule status
create separate detail-screen persistence model
parse visible tags to infer observance compatibility
```

### 14.4 Intent result rule

Every committed intent must:

1. Persist only the appropriate state.
2. Rebuild the resolved day/wake snapshot.
3. Trigger schedule refresh if materialized events changed.
4. Return the updated resolved state to the calling surface.
5. Leave global defaults untouched unless the intent is explicitly global.

### 14.5 Preview vs commit

Drag interactions may produce live provisional state.

Preview rules:

```text
Preview may update UI snapshots immediately.
Preview may update Weekly Fajrcast live marker if visible.
Preview must not persist until commit.
Preview must not schedule/cancel alarms.
Preview must not infer religious intention.
Preview must not mutate global defaults.
```

Commit rules:

```text
Commit stores a date-specific wake-time override.
Commit rebuilds resolved snapshots.
Commit triggers schedule refresh for affected events.
Commit may fail; failure restores last resolved state and shows non-disruptive error.
```

---

## 15. Date-specific and Anchor-Aware Persistence Contract


### 15.0 Anchor-aware persistence rule

The app must persist two related but different kinds of user meaning:

| Persistence type | Example | Storage principle |
|---|---|---|
| Anchored intention | “Fast Ashura”, “Fast Mondays”, “Six days of Shawwal”, “Wake for Arafah” | Store anchor + intention meaning; re-resolve date keys when calendar/rules change |
| Date-specific override | “Wake at 4:30 on March 12”, “Quiet this date” | Store Gregorian date key or date range; do not move when Hijri labels change unless explicitly tied to another anchor |

A `MorningDateOverride` is appropriate for date-specific changes. It should not be stretched to represent every observance, weekday, or Hijri-window plan. Those should use an anchor-aware intention record that can produce date-specific effects during resolution.


### 15.1 Persistence layers

Use three persistence categories:

```text
Global settings
    - default calculation method
    - prayer adjustments
    - default wake offsets/rules
    - default reminders
    - default audio preferences

Generated / plan-derived state
    - Ramadan schedule defaults
    - Qada assignments
    - recurring observance sources
    - scheduled date source outputs

Date-specific user overrides
    - one-day quick wake mode
    - one-day wake time/rule
    - one-day early purpose
    - one-day fast purpose
    - one-day quiet overlay
    - one-day Fajr adhan-at-Fajr-begins toggle
```

Date-specific edits must not mutate global settings.

### 15.2 Recommended date-specific override model

Conceptual model:

```swift
struct MorningDateOverride: Codable, Equatable, Sendable {
    let dateKey: String

    var quickWakeModeOverride: QuickWakeMode?
    var underlyingWakeModeBeforeQuiet: MorningWakeUnderlyingMode?

    var wakeRuleOverride: MorningWakeRule?
    var wakeTimeOverrideMinutesFromMidnight: Int?
    var wakeTimeOriginOverride: WakeTimeOrigin?

    var earlyWakePurposeOverride: EarlyWakePurpose?
    var fastPurposeOverride: FastIntentSelection?
    var selectedOpportunityIDs: Set<String>?
    var linkedIntentionID: String?
    var localAnchorOverride: IntentionAnchor?

    var fajrAdhanAtFajrBeginsOverride: Bool?
    var quietOverlay: Bool?

    var source: DateOverrideSource
    var createdAt: Date
    var updatedAt: Date
}
```

The actual code may continue to use `DailyAlarmOverride` if it represents these fields cleanly. The contract is about ownership and semantics, not naming.

### 15.3 Required fields and ownership

| Field | Owner | Notes |
|---|---|---|
| `quickWakeModeOverride` | wake intent handler | `Fast`, `Fajr`, `Quiet` selected for a date |
| `underlyingWakeModeBeforeQuiet` | wake resolver / intent handler | required for restoring Quiet |
| `wakeRuleOverride` | wake intent handler | date-specific wake rule |
| `wakeTimeOverrideMinutesFromMidnight` | wake intent handler | commit-on-release drag result |
| `earlyWakePurposeOverride` | Alarm Detail / intent handler | `Fast` vs `Tahajjud` when Early/Fast surface supports it |
| `fastPurposeOverride` | Alarm Detail / intent handler | Qada, Vow, Kaffarah, Other, etc. |
| `selectedOpportunityIDs` | Day Intention resolver / detail intent handler | links intention to opportunities |
| `fajrAdhanAtFajrBeginsOverride` | detail audio toggle handler | only later Fajr adhan event, not pre-Fajr wake alarm |
| `quietOverlay` | wake intent handler | suppresses delivery; preserves underlying state |

### 15.4 Anchor movement and date-specific effects

When a non-Gregorian anchored intention changes resolved dates because of a Hijri adjustment or observance-rule change:

1. The anchored intention record remains the durable source of meaning.
2. The old resolved date effect is removed unless another record still applies there.
3. The new resolved date effect is applied.
4. The affected-date set includes both old and new date keys.
5. If either date is inside the active scheduled horizon, schedule refresh is triggered for those dates.
6. If the intention is historical/completed, it does not move; history keeps the original date and may store prior calendar context.

### 15.5 Quiet restoration

Quiet must preserve underlying mode.

Required examples:

```text
Fajr → Quiet → Fajr
```

Restores:

```text
underlyingWakeMode = fajr
wake boundary = Fajr begins → Fajr ends
wake target = prior Fajr date-specific value if available, otherwise global/default Fajr value
```

```text
Fast → Quiet → Fast
```

Restores:

```text
underlyingWakeMode = earlyWorship
wake boundary = finalThirdStart → Fajr begins
wake target = prior Fast date-specific value if available, otherwise generated/default Fast value
fast purpose = preserved if previously selected
```

Quiet must not delete:

- Ramadan context
- Qada assignment
- Sunnah opportunity
- Tahajjud intention if it is the underlying mode
- selected fast purpose
- prior mode-specific wake time

### 15.6 Restore priority

When switching modes, use this priority:

```text
1. Date-specific override for selected mode
2. Prior restored persisted value for selected mode
3. Plan-generated value for selected mode
4. Global default for selected mode
5. Safe unavailable fallback
```

### 15.7 Migration rules

Existing stores may remain, but their semantics must be explicit.

Migration requirements:

- Existing fast tag selections must map to `ResolvedDayIntention.kind = fast` only when they represent user intent or assigned/generated fast, not mere opportunity.
- Existing one-day skip/suhoor fields must map to activation/quiet/off semantics without losing underlying mode.
- Existing Fajr adhan fields must be audited so adhan audio does not imply alarm disabled.
- Existing fixed wake / manual override values must map to `manualDragOverride` or `dateSpecificOverride`.
- Existing generated Ramadan/Qada plans must map to `planGenerated`, not manual override.

---

## 16. Scheduler handoff contract

### 16.1 Separation of intent and delivery

The morning resolver decides:

```text
Should this morning have a wake event?
What time should it fire?
What role should the event have?
What audio role should it use?
Is it active, quiet, off, no-anchor, or unavailable?
```

The alarm-delivery pipeline decides:

```text
Can the platform schedule it?
Was it scheduled?
Which backend was used?
Is permission blocked?
Did pending request reconciliation succeed?
Was a fallback notification needed?
```

Delivery results must flow back as `scheduleStatus` or delivery diagnostics. They must not rewrite morning intent.

### 16.2 Event materialization

Resolved mornings may produce events such as:

```text
wakeReminder
wakeAlarm
wakeFollowUp
fajrBoundaryNotice
iftarReminder
```

Event materialization rules:

- Events are derived from `ResolvedDaySnapshot` and effective behavior profile.
- `wakeAlarm` appears only when wake alarm is enabled and activation is active.
- `fajrBoundaryNotice` is separate from the pre-Fajr wake alarm.
- `iftarReminder` depends on actual fasting intention/context, not mere fasting opportunity.
- Event sound role is separate from activation.

### 16.3 Audio role vs activation

Required rule:

```text
Alarm off = Quiet/off/no-anchor/unavailable activation states only.
Audio role = how an active event sounds.
```

Therefore:

```text
Fajr mode using Fajr adhan audio = active alarm.
Early + Fast using generic wake alarm + later Fajr adhan = active wake alarm plus optional boundary event.
Turning off later Fajr adhan = does not disable the pre-Fajr wake alarm.
```

### 16.4 Schedule status examples

| User/app state | Delivery result | Required interpretation |
|---|---|---|
| `quickWakeSelection = fajr`, `activation = active` | `scheduled` | active Fajr wake scheduled |
| `quickWakeSelection = fajr`, `activation = active` | `permissionBlocked` | active Fajr wake selected but cannot be scheduled |
| `quickWakeSelection = fast`, `activation = active` | `failed` | active Fast wake selected but schedule failed |
| `quickWakeSelection = quiet`, `activation = quietSuppressed` | `notScheduledBecauseQuiet` | intentionally quiet, not failure |
| missing Fajr data | `notScheduledBecauseUnavailable` | unavailable data, not Quiet |

---

## 17. Surface contracts

### 17.1 Morning Hero

Input:

```text
ResolvedMorningWakeState
DailyPrayerWindow metadata needed for location/date display
live preview wake state when dragging
```

Output intents:

```text
SelectWakeMode(.fast/.fajr/.quiet)
PreviewWakeAdjustment(...)
CommitWakeAdjustment(...)
```

Forbidden:

```text
calculating final-third start
calculating Fajr end
creating/canceling alarms
direct override writes
inferring fasting from dragged time
```

The hero is the immediate orientation surface. It should show the resolved next relevant morning and emit intents only.

### 17.2 Alarm Detailed View

Input:

```text
dateKey
ResolvedDaySnapshot
ResolvedMorningWakeState
ResolvedDayPurpose
allowed date-specific edit metadata
```

Output intents:

```text
SelectWakeMode
CommitWakeAdjustment
SelectEarlyPurpose
SelectFastPurpose
ToggleFajrAdhanAtFajrBegins
RestoreDefaultWake
```

Rules:

- It edits one selected date only.
- It must reuse or mirror the Home Hero model for the hero region.
- It may expose day context and mode-specific controls.
- It must not become delivery diagnostics, source diagnostics, global settings, or a second scheduler.

### 17.3 Weekly Fajrcast

Input:

```text
WeeklyFajrcastSnapshot generated from resolved day/wake states
anchor date
snap-back target
seven visible DailyPrayerWindow values
resolved marker states
live provisional wake override when supplied
```

Rules:

- It does not calculate prayer windows.
- It does not choose a new snap-back target outside the supplied snapshot.
- It may temporarily inspect visible days.
- It must snap back to the supplied resting focus.
- It may update live during hero wake-time preview.
- It must not persist anything from chart scrubbing.

### 17.4 Next 10 Mornings

Input:

```text
NextTenMorningsSnapshot generated from resolved day/wake states
row date labels
resolved tag list
resolved wake time/status
accessibility summaries
```

Rules:

- Rows show date, tags, and wake time/status only.
- Rows must not show visible explanatory prose.
- Tags come from the tag/domain resolver, not row string parsing.
- `[Fajr]` may coexist with opportunity-only tags.
- `[Fajr]` must not coexist with stronger intentional/overriding tags such as Ramadan, Fasting, Tahajjud, or Quiet.
- Quiet owns the row visually when active.

### 17.5 Month browsing and planning surfaces

Input:

```text
PlanningWindowSnapshot or selected-month snapshot
ResolvedDaySnapshot values for visible dates
anchored intention summaries
review-needed flags
```

Rules:

- Month browsing may resolve and display days inside the supported current range.
- Browsing alone must not create durable `MorningDateOverride` or `UserIntentionRecord` records.
- Editing from a day detail view must create/update anchored intention or date-specific override records through the intent handler.
- Month browsing must not schedule platform alarms directly.
- If a Hijri adjustment changes visible dates, month snapshots must be regenerated from source settings and stored intentions.

### 17.6 Notification and alarm copy

Input:

```text
ScheduledEvent
ResolvedMorningWakeState.copyState
sound role
schedule/delivery metadata
```

Rules:

- Notification copy may use resolved copy state.
- It must not recompute day intention.
- It must not turn a delivery failure into Quiet.
- It must not create hidden completion credit.

### 17.7 Completion and progress

Input:

```text
ResolvedDayPurpose
DailyCompletionSnapshot
completion records
qada ledger
```

Rules:

- Completion requirements depend on intention.
- Opportunities alone do not become missed fasts.
- Qada credit remains primary when selected.
- Quiet suppresses pressure by default.
- Analytics uses explicit credits, not visible tags.

---

## 18. Time, date, and boundary rules

### 18.1 Date key and timezone

Required rules:

- `dateKey` must be based on the resolved local timezone for the target location/morning.
- Prayer windows, wake instants, display labels, and stored date-specific overrides must agree on the same date key.
- Daylight saving time transitions must use real `Date` instants and timezone-aware calendars.
- Cross-midnight final-third calculation must use previous evening Maghrib and target morning Fajr.

### 18.2 Hijri date at Fajr and Islamic-night caution

Required rules:

- For Subh's morning surfaces, the effective Hijri date should be the Hijri date active at Fajr for that target morning.
- This morning-based Hijri identity is separate from future night-observance logic, because Islamic dates begin at sunset.
- If a future feature resolves night observances, it must not reuse a morning-only date assumption without explicit night/date handling.
- Hijri adjustment changes may move future/current observance-anchored plans, but must not move completed history.

### 18.3 Fajr begin/end

Required rules:

- Fajr begin and Fajr end must travel together as one resolved prayer-window snapshot.
- Fajr end is normally sunrise-derived but must be represented as a first-class boundary.
- Adjusting Fajr begin does not automatically adjust Fajr end unless a separate Fajr-end adjustment exists.
- Missing Fajr end must produce unavailable or fallback state, not invented geometry.

### 18.4 Final-third start

Required rules:

- Final-third start is calculated only by the early-worship boundary resolver.
- It uses previous evening Maghrib and target morning Fajr begins.
- It is available only when required prayer data is available.
- It opens the early-worship window for intended fasting/Tahajjud, not opportunity-only days.

### 18.5 Rounding and endpoint equality

Required rules:

- Wake boundaries and wake times should be rounded according to the app’s documented rounding policy.
- Endpoint copy must be determined after minute granularity, clamping, and rounding.
- Do not display `Wake up 0 min before Fajr ends`; use `Wake up as Fajr ends`.
- Do not display `Wake up 0 min before Fajr begins`; use `Wake up as Fajr begins`.

---

## 19. Cache invalidation and reschedule rules

### 19.1 Rebuild resolved snapshots when these change

```text
location
location timezone
calculation method
Fajr begin adjustment
Fajr end adjustment
Maghrib adjustment
high-latitude rule
rounding policy
provider/source selection
Hijri adjustment
anchored intention rebind / affected-date-set change
Ramadan detection
scheduled date source
recurring Islamic date source
fast tag / fast intention selection
qada assignment
observance-anchored intention selection or movement
weekday / Hijri-window recurring intention change
Tahajjud selection
daily override
quick wake mode
wake slider commit
Quiet overlay
default alarm config
snooze/follow-up settings
Fajr adhan-at-Fajr-begins toggle
permission state, if scheduleStatus is included in snapshot
```

### 19.2 Reschedule materialized events when these change

```text
prayer window boundary used by any event
wake time
wake activation
sound role
delivery kind
fajr boundary notice enablement
iftar reminder enablement
reminder time
wake follow-up settings
skip/quiet/off state
active scheduled horizon
anchor movement that changes materialized events inside the active scheduled horizon
permission or backend capability that affects scheduling
```

### 19.3 Do not reschedule for these alone

```text
chart scrub inspection
temporary hero drag preview before commit
accessibility focus changes
visual-only card layout changes
copy-only changes that do not alter event payload or timing
```

If notification copy payload is included in scheduled requests, copy changes may require rescheduling according to the alarm-delivery spec.

---

## 20. Required acceptance criteria

Use these as implementation acceptance tests. They may be split into unit, integration, UI, and manual device tests.

### 20.1 Default Fajr morning

```gherkin
GIVEN an ordinary morning with Fajr begin and Fajr end available
AND no explicit fast, Tahajjud, Ramadan, Qada, or Quiet state
WHEN the morning is resolved
THEN quickWakeSelection is fajr
AND boundaryRegime is defaultFajrWindow
AND wakeTime is 30 min before Fajr ends by default
AND alarmActivation is active
AND visualMode is interactiveDefaultFajr
AND relation copy is "Wake up 30 min before Fajr ends"
```

### 20.2 Fast quick selection

```gherkin
GIVEN an ordinary morning with final-third data available
WHEN the user selects Fast
THEN a date-specific fast wake intent is saved
AND quickWakeSelection is fast
AND underlyingWakeMode is earlyWorship
AND boundaryRegime is earlyWorshipWindow
AND wakeTime is 30 min before Fajr begins by default
AND relation copy is "Wake up 30 min before Fajr begins"
AND the scheduler receives an active wake event
```

### 20.3 Fasting opportunity only

```gherkin
GIVEN a morning with a White Days opportunity
AND the user has not intended a fast
WHEN the morning is resolved
THEN ResolvedDayPurpose includes the White Days opportunity
AND intention remains defaultFajr
AND quickWakeSelection remains fajr
AND boundaryRegime remains defaultFajrWindow
AND no fast completion required action is created
AND Next 10 may show [Fajr] [White Days]
```

### 20.4 Quiet over Fajr

```gherkin
GIVEN a Fajr-mode morning
WHEN the user selects Quiet
THEN alarmActivation is quietSuppressed
AND scheduleStatus is notScheduledBecauseQuiet
AND underlyingWakeMode remains fajr
AND boundaryRegime is quietDefaultFajrWindow
AND the hero primary text is Quiet mode
AND no wake alarm event is scheduled
WHEN the user reselects Fajr
THEN the prior Fajr wake behavior is restored
```

### 20.5 Quiet over Fast

```gherkin
GIVEN a Fast-mode morning with a selected fast purpose
WHEN the user selects Quiet
THEN alarmActivation is quietSuppressed
AND underlyingWakeMode remains earlyWorship
AND the selected fast purpose is preserved
AND opportunities remain resolved
WHEN the user reselects Fast
THEN the prior Fast wake time/purpose is restored before falling back to defaults
```

### 20.6 Ramadan

```gherkin
GIVEN a Ramadan morning
WHEN the morning is resolved
THEN ResolvedDayPurpose includes Ramadan
AND intention defaults to fast
AND boundaryRegime is earlyWorshipWindow unless the user selected Fajr or Quiet
AND fast purpose is Ramadan fast
AND Ramadan fast purpose is locked in Alarm Detail
AND other fast-purpose alternatives are not offered
```

### 20.7 Ramadan changed to Fajr

```gherkin
GIVEN a Ramadan morning
WHEN the user selects Fajr
THEN wake execution changes to Fajr mode for that date
AND Ramadan remains the governing day context
AND Ramadan is not deleted from opportunities or day purpose
```

### 20.8 Qada

```gherkin
GIVEN a date with a Qada fast assigned by the user
WHEN the morning is resolved
THEN intention is fast
AND fast purpose is Qada
AND boundaryRegime is earlyWorshipWindow
AND primary analytics credit is Qada
AND overlapping Sunnah opportunities do not automatically receive completion credit
```

### 20.9 Tahajjud

```gherkin
GIVEN a date with Tahajjud intended
WHEN the morning is resolved
THEN boundaryRegime is earlyWorshipWindow
AND fast-purpose selector is not shown
AND fast required actions are not created
AND any fasting opportunities remain informational unless separately selected
```

### 20.10 Manual drag

```gherkin
GIVEN a Fajr-mode morning
WHEN the user drags the wake time earlier
AND commits the change
THEN the wake time is saved as a date-specific/manual override
AND quickWakeSelection remains fajr
AND no fasting intention is inferred
AND no Tahajjud intention is inferred
```

### 20.11 Early-worship drag endpoint

```gherkin
GIVEN an early-worship morning
WHEN the user drags the wake handle to finalThirdStart
THEN relation copy is exactly "Wake up for the last third of the night"
WHEN the user drags the wake handle to Fajr begins
THEN relation copy is exactly "Wake up as Fajr begins"
```

### 20.12 Default Fajr endpoint

```gherkin
GIVEN a default Fajr morning
WHEN the user drags the wake handle to Fajr begins
THEN relation copy is exactly "Wake up as Fajr begins"
WHEN the user drags the wake handle to Fajr ends
THEN relation copy is exactly "Wake up as Fajr ends"
```

### 20.13 Red urgent relation tone

```gherkin
GIVEN a default Fajr wake time 14 min or less before Fajr ends
WHEN relation copy is resolved
THEN relationTone is urgentRed
AND this red tone is not applied merely because the wake time is an endpoint
AND Quiet copy is never red for this reason
```

### 20.14 Fajr adhan audio

```gherkin
GIVEN a Fajr-mode wake using Fajr adhan audio
WHEN the morning is resolved
THEN alarmActivation is active
AND audio role is Fajr adhan
AND the alarm is not considered off
```

### 20.15 Later Fajr adhan toggle

```gherkin
GIVEN a non-Ramadan Early + Fast morning
WHEN the user disables "Fajr adhan at Fajr begins"
THEN the later Fajr boundary event is disabled for that date
AND the pre-Fajr wake alarm remains active
AND quickWakeSelection remains fast
```

### 20.16 Permission blocked

```gherkin
GIVEN a Fajr wake selected by the user
AND the platform cannot schedule because permission is blocked
WHEN the wake state is resolved
THEN quickWakeSelection remains fajr
AND alarmActivation remains active
AND scheduleStatus is permissionBlocked
AND the UI must not display Quiet or no-alarm as the resolved intent
```

### 20.17 Missing Fajr end

```gherkin
GIVEN Fajr begins is available
AND Fajr end is unavailable
WHEN a default Fajr visual is requested
THEN the surface must not invent a Fajr end
AND the visual mode is unavailable or a specified fallback
AND no guessed within-Fajr slider is shown
```

### 20.18 Missing final-third data

```gherkin
GIVEN an intended fast morning
AND Maghrib or Fajr begins is unavailable for final-third calculation
WHEN the wake state is resolved
THEN boundaryRegime is unavailable or safe fallback
AND the UI must not invent finalThirdStart
AND scheduling must avoid guessed alarms if required anchor data is missing
```

### 20.19 DST and timezone

```gherkin
GIVEN a date crossing a daylight-saving transition
WHEN the morning is resolved
THEN dateKey, prayer windows, wake instants, and stored overrides use the resolved location timezone
AND final-third duration is calculated using real Date instants
AND wake time remains correct after schedule refresh
```

### 20.20 Home Hero and Fajrcast live preview

```gherkin
GIVEN the hero wake slider is being dragged
AND the affected date is visible in Weekly Fajrcast
WHEN preview state changes
THEN the Fajrcast marker updates live
AND no persistence occurs until commit
AND no alarm is scheduled until commit
```

### 20.21 Next 10 tag doctrine

```gherkin
GIVEN an opportunity-only Ashura morning
WHEN Next 10 row tags are resolved
THEN the row may show [Fajr] [Ashura]
AND must not show [Fasting] unless the fast is intended
```

### 20.22 Alarm Detail date-specific editing

```gherkin
GIVEN the user opens Alarm Detailed View for a future date
WHEN the user changes mode, purpose, fast type, wake time, or Fajr adhan toggle
THEN only that date's override/intention state changes
AND global defaults do not change
AND the screen receives a rebuilt resolved state
```

### 20.23 No direct scheduling from views

```gherkin
GIVEN code review or automated architecture tests
WHEN scanning SwiftUI view files
THEN views do not call alarm create/cancel/schedule APIs directly
AND views do not calculate final-third or Fajr end
AND views emit domain intents instead
```


### 20.24 Observance-anchored future/current intention moves

```gherkin
GIVEN a user created an observance-anchored Ashura fast while March 12 resolved as 10 Muharram
WHEN a Hijri adjustment changes 10 Muharram to March 13
THEN the anchored intention remains Ashura
AND the effective resolved date changes to March 13
AND the affected-date set includes March 12 and March 13
AND the app can explain that the plan moved because the Hijri calendar was adjusted
```

### 20.25 Gregorian-date intention stays fixed

```gherkin
GIVEN a user created a Gregorian-date fast for March 12
AND March 12 was also displaying a White Days opportunity at creation time
WHEN a Hijri adjustment causes the White Day to move away from March 12
THEN the fast remains on March 12
AND the White Days tag/opportunity re-resolves according to the new calendar
AND the UI does not silently convert the date-specific fast into an observance fast
```

### 20.26 Completed history does not move

```gherkin
GIVEN a user completed a fast on March 12
WHEN the Hijri calendar is adjusted after March 12
THEN the completion record remains attached to March 12
AND historical calendar context may be shown for explanation
AND the completion record is not moved to the newly resolved observance date
```

### 20.27 Month browsing does not create durable default days

```gherkin
GIVEN the user opens a Gregorian or Hijri month view
AND the app resolves default wake lines and opportunities for visible days
WHEN the user exits without editing
THEN no date-specific override is created
AND no anchored intention is created
AND no platform alarm is scheduled merely because the month was viewed
```

### 20.28 Active scheduled horizon is separate from visible range

```gherkin
GIVEN Next 10 and a month view display dates outside the active scheduled horizon
WHEN the scheduler handoff is built
THEN only materialized events inside activeScheduledDateKeys are handed to delivery
AND visibleDateKeys do not determine scheduling scope
```

---

## 21. Required test coverage

### 21.1 Unit tests

Create or verify tests for:

- `WakeStateSelectionResolver.selectedMode`
- `WakeStateSelectionResolver.underlyingMode`
- `WakeStateSelectionResolver.apply`
- `MorningWakeResolutionService.resolve`
- `EarlyWorshipBoundaryResolver.finalThirdStart`
- `MorningScheduleResolver.resolvePrayerWindow`
- `DayPurposeResolver.resolve`
- date-specific override restoration
- Quiet overlay preservation
- audio role vs activation
- schedule status vs activation
- opportunity vs intention
- anchored intention movement after Hijri adjustment
- Gregorian-date intention staying fixed after Hijri adjustment
- affected-date-set construction

### 21.2 Integration tests

Create or verify tests for:

- morning resolution from full `MorningStateSnapshot`
- Home Hero snapshot from resolved state
- Alarm Detail snapshot from selected date
- Weekly Fajrcast snapshot live preview
- Next 10 snapshot tag rules
- schedule refresh after date-specific commit
- schedule refresh after anchored-intention movement
- permission-blocked schedule status feedback

### 21.3 UI tests

Create or verify tests for:

- hero Fast/Fajr/Quiet selector
- hero drag commit and rollback
- detail hero parity and date-specific edits
- detail fast purpose override with no duplicate Voluntary fast option
- Quiet Mode moon icon and stable primary row slot
- Next 10 row tags without explanatory subtitles
- Weekly Fajrcast snap-back after inspection

### 21.4 Manual/device QA

Manual QA must cover:

- real device alarm delivery
- permission-blocked behavior
- notification fallback behavior
- app restart after date-specific edit
- timezone/location change
- DST boundary
- Ramadan date
- Qada date
- White Days opportunity-only date
- observance-anchored fast moved by Hijri adjustment
- Gregorian-date fast not moved by Hijri adjustment
- Quiet restoration after app relaunch

---

## 22. Implementation guardrails for Codex

Codex implementation should follow these guardrails.

### 22.1 Do first

1. Identify current canonical resolver path from state snapshot to active day to resolved wake state.
2. Confirm `ResolvedDaySnapshot` and `ResolvedMorningWakeState` field coverage.
3. Centralize missing intent handling behind one service.
4. Ensure Home Hero and Alarm Detail emit intents only.
5. Ensure date-specific override writes are owned by the intent service.
6. Ensure scheduler handoff consumes materialized resolved events.
7. Add acceptance tests before visual-only refinements.

### 22.2 Do not do first

Do not start by rewriting component UI.

Do not create:

```text
AlarmDetailWakeResolver
HeroWakeResolver
FajrcastWakeResolver
NextTenWakeResolver
RamadanAlarmEngine
FastingAlarmEngine
TahajjudAlarmEngine
```

Component-specific providers may format snapshots, but they must not own domain resolution.

### 22.3 Safe implementation order

Recommended order:

```text
1. Model and field audit
2. Intent-handling service
3. Date-specific override semantics
4. Quiet restoration behavior
5. Alarm activation vs schedule status separation
6. Surface snapshot adapters
7. Component UI wiring
8. Scheduler reconciliation
9. Acceptance tests and architecture tests
```

---

## 23. Non-goals

This spec does not require:

- building a new global architecture framework
- renaming every current type immediately
- replacing `DailyAlarmOverride` if it can satisfy the contract
- implementing a new alarm delivery backend
- redesigning the Home surface
- adding full analytics dashboards
- adding mosque timetable provider integration
- solving all high-latitude edge cases beyond honoring the prayer-time spec

This spec requires clear ownership and consistent behavior, not unnecessary churn.

---

## 24. Open decisions

These are intentionally left for child specs or future revisions.

1. What exact current/planning range should the month picker expose in the current release, and should this be hard-coded or configuration-driven?
2. Should an ambiguous tap on an observance-tagged day default to “Fast this observance” or ask the user to choose between observance and date anchors?
3. Should Arafah follow local Hijri settings, a Makkah/Hajj authority setting, or a user-selectable authority in MVP?
4. Should the active scheduled horizon remain next-immediate-only or include a small safety buffer?
5. Should the app eventually support a custom out-of-range wake visual in the hero/detail surfaces?
6. Should `Fast | Fajr | Quiet` become `Early | Fajr | Quiet` in Home, or should `Fast` remain the user-facing quick label while detail exposes `Fast | Tahajjud` under Early?
7. Should Quiet suppress completion prompts universally, or only wake/delivery prompts while allowing optional later check-ins?
8. How should provider-only prayer-time mode behave if provider data is unavailable but local calculation is possible?
9. Should voluntary fast on a date with multiple compatible opportunities auto-link all opportunities or require explicit selection?
10. How much delivery failure copy belongs in the hero versus a warning/detail surface?
11. Should Fajr adhan-at-Fajr-begins behavior in Ramadan Quiet be locked visible, hidden, or explained only in a policy/detail surface?

---

## 25. Acceptance definition for this system spec

This spec is satisfied when:

1. There is one canonical path from state inputs to `ResolvedDaySnapshot` and `ResolvedMorningWakeState`.
2. Home Hero, Alarm Detail, Weekly Fajrcast, and Next 10 consume resolved snapshots rather than duplicating domain logic.
3. SwiftUI views emit intents and do not schedule alarms or calculate prayer boundaries.
4. Date-specific edits are persisted as date-specific overrides/intention selections.
5. Quiet preserves underlying mode and restores it correctly.
6. Fasting opportunities do not become fasting intentions unless selected or auto-obligatory.
7. Ramadan, Qada, Tahajjud, and custom fasts resolve through the same morning pipeline.
8. Alarm activation and schedule/delivery status remain distinct.
9. Audio roles do not imply alarm activation state.
10. The scheduler receives materialized events derived from resolved state.
11. Completion and analytics credit use Day Purpose, not visible tags alone.
12. The acceptance tests in Section 20 pass.

---

## 26. Short implementation summary

The implementation target is not a new app architecture. It is a disciplined ownership boundary:

```text
Prayer windows are resolved once.
Day meaning is resolved once.
User intention is resolved once.
Wake state is resolved once.
Events are materialized once.
Delivery reports back once.
Surfaces render snapshots and emit intents.
```

That is the missing system layer.
