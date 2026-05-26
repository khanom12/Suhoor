# Subh Planning Horizon, Day Resolution, and Intention Anchoring Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md` |
| Version | 3 |
| Spec status | Product / design / engineering draft; aligned Desktop working spec; aligned to Next 7 Days horizon |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v2.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md` |
| Owning domain / surface | Planning horizon, browsable days, and future intention anchoring |
| Implementation audit status | Needs implementation audit |

## Purpose
Define how Subh displays, stores, re-resolves, and explains current/future mornings without permanently storing every generated day as durable state.

## What This Spec Owns
- Planning horizon and active scheduled horizon distinctions.
- Future/current intention anchoring and movement under calendar changes.
- Generated-vs-stored doctrine for browsed months, Next 7 Days, and future edits.

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

- Future and current anchored before-Fajr intentions use the MVP Suhoor model.
- `Suhoor` is the only exposed before-Fajr intent that can be anchored in MVP.
- Tahajjud-only, other-early-worship, and generic Pre-Fajr anchors are deferred and should not be created by MVP surfaces.
- Display horizons such as Next 7 Days and month browsing may show fasting opportunities, but opportunity-only dates must not become durable Suhoor intentions.
- Day Detail edits and resets save immediately in MVP; older staged-Done behavior is superseded.

## v3 Next 7 Days / Weekly Fajrcast Alignment Addendum

This addendum is normative for v3 and supersedes lower references to `Next 10` as the active Home forecast horizon.

- The Home near-term display horizon is `Next 7 Days`.
- `Next 7 Days` shows the next immediate alarm / next relevant morning plus the following six mornings.
- Weekly Fajrcast uses the same seven visible dates, in the same order.
- The near-term display horizon remains separate from the active scheduled horizon.
- Displaying seven days does not create durable day records and does not schedule all seven days.
- Future saved intentions hydrate into Home, Next 7 Days, Weekly Fajrcast, and delivery only when the canonical resolver/window builder brings the date into the relevant surface or active scheduled scope.

**Scope:** Subh's planning horizons, intention anchoring, Hijri/calendar adjustment behavior, month browsing, next-morning cards, and the product policy that feeds canonical morning resolution and alarm delivery.

---

## 0. Executive Summary

Subh is a Fajr-centered morning system. Its core job is not merely to ring an alarm. Its core job is to help the user understand and shape what the next meaningful morning looks like.

The central product doctrine for this specification is:

> **Subh generates days when needed, stores user meaning rather than default data, schedules only the near-term active alarm, and preserves completed history.**

In simpler language:

> **Plans can move. Alarms act. History stays.**

This specification defines the durable center of the application: how Subh knows dates, displays mornings, remembers user choices, handles Hijri calendar adjustments, resolves day states, and decides what is actually active for the user.

The core design principle is that Subh should not permanently store every future day as a fully resolved object. Instead, Subh should store:

- the user's settings,
- the calendar and prayer-time rules being used,
- any user-created intentions or overrides,
- any calendar adjustments,
- any completion or history records,
- and the active alarm state.

Everything else can be generated or re-generated from those source ingredients.

This prevents future bugs when the Hijri calendar changes, prayer calculation settings change, location changes, or the user edits a future observance-based intention.

---


## 0.1 Cross-Spec Alignment and Ownership

This version is aligned with two system contracts:

1. **Subh Morning Resolution Contract and State Ownership** — owns the canonical resolved morning object graph, resolver pipeline, state ownership, date-specific override semantics, surface snapshot boundaries, and the rule that all surfaces consume one resolved state.
2. **Subh Alarm Delivery and Schedule Reliability** — owns platform delivery after the resolver has materialized events: AlarmKit/UserNotifications, permissions, identifiers, stale cancellation, pending-state reconciliation, delivery ledger, and schedule-status feedback.

This planning-horizon specification does **not** create a third resolver or a second scheduler. It owns the product policy around:

- how far Subh can know, show, let the user edit, and remember;
- which generated data should remain temporary;
- which user decisions become durable anchored intentions;
- how Hijri/calendar changes affect future plans;
- how month browsing and Next 7 Days views relate to the active schedule;
- and how completed history is preserved.

### Ownership boundary

| Concern | Owning spec | Rule in this aligned version |
|---|---|---|
| Canonical resolved morning graph | Morning Resolution Contract | Planning policy feeds this graph; it does not replace it. |
| Day meaning, intention, wake boundary, wake time, activation | Morning Resolution Contract | Anchored intentions are applied by the canonical resolver. |
| Knowledge/display/edit/history horizons | Planning Horizon and Intention Anchoring | These are product horizons, not platform scheduling instructions. |
| Month browsing and Next 7 Days generation policy | Planning Horizon and Intention Anchoring | Views are generated from the canonical resolver and may be cached temporarily. |
| Active scheduled window | Morning Resolution + Active Window Builder, consumed by Alarm Delivery | Displayed days are not automatically scheduled days. |
| Platform scheduling, permission, verification, ledger | Alarm Delivery Reliability | Delivery schedules only resolver-materialized events inside the active scheduled scope. |
| Delivery failure meaning | Alarm Delivery Reliability + Morning Resolution Contract | Delivery failure must not rewrite user intention, mode, or anchors. |

### Resolved doctrine after alignment

The durable product doctrine is:

> **Know broadly. Show relevantly. Remember meaning. Resolve canonically. Schedule narrowly. Verify delivery. Preserve history.**

A shorter operating rule is:

> **Generated days are temporary. User meaning is durable. Platform alarms are derivative. History is fixed.**

### Product-active alarm versus technical scheduled horizon

Earlier drafts used the phrase “only the next immediate alarm is active.” This remains true as a **product concept**, but the delivery system may maintain a small **technical scheduled horizon** or safety buffer when required by platform policy or implementation reliability.

Therefore:

- **Product-active alarm** means the next immediate alarm the user understands as operational.
- **Technical scheduled horizon** means the finite set of resolver-materialized events that the delivery layer is allowed to schedule and verify.
- **Display horizon** means what the user can see, such as Next 7 Days or a month view.
- **Display horizon does not become technical scheduled horizon unless the Active Window Builder explicitly includes those events in `scheduledDays`.**

This prevents a hidden contradiction between product simplicity and delivery reliability.

## 1. Product Doctrine

### 1.1 Core product truth

Subh is a **Fajr-centered morning system for Muslims**.

It is not primarily:

- a generic alarm app,
- a generic prayer-time calendar,
- a Ramadan-only utility,
- a fasting-only tracker,
- or a collection of unrelated Islamic features.

The daily spine of the product is:

> **Default Fajr morning rhythm → date-specific meaning → user intention → wake execution → completion/history.**

Every major feature should attach to that spine.

### 1.2 Core system model

Subh should treat each morning as a layered result:

1. A Gregorian date exists.
2. A Hijri date is resolved for that morning.
3. Prayer/Fajr times are resolved for that date and location.
4. The user's default morning plan is applied.
5. Observance opportunities are identified.
6. User intentions and overrides are applied.
7. Conflicts and warnings are resolved.
8. The final morning state is displayed.
9. Only the next immediate alarm becomes operational.
10. Completed actions become fixed history.

### 1.3 Core doctrine statements

These doctrine statements should guide future product and engineering decisions:

1. **Subh can know more than it needs to show.**
   Subh may be able to calculate or retrieve many future dates, but it should not force all of them into active user-facing state.

2. **Subh can show more than it needs to schedule.**
   The Next 7 Days forecast or a future month can be visible without all of those days being active alarms.

3. **Subh should remember user meaning, not generated defaults.**
   A default day does not need to be permanently stored. A user intention or override does.

4. **Subh should anchor intentions to the thing the user meant.**
   If the user intends to fast Arafah, that intention is attached to Arafah, not merely to the Gregorian date that temporarily displayed Arafah.

5. **Subh should preserve history.**
   Future plans may move when calendars or settings change. Completed actions should not move retroactively.

6. **Subh should treat active alarms as outputs of resolution, not the source of truth.**
   The active alarm should be generated from the latest resolved morning state.

7. **Subh should explain material changes.**
   If a Hijri adjustment moves a planned fast, the app should tell the user clearly.

---

## 2. Key Terms

| Term | Plain-language meaning |
|---|---|
| **Morning** | The user-facing pre-Fajr / Fajr-centered experience for a given civil date. |
| **Gregorian date** | The normal civil calendar date, such as March 12. |
| **Hijri date** | The Islamic calendar date associated with the morning, such as 10 Muharram. |
| **Hijri date at Fajr** | The Hijri date that Subh treats as active for that morning's Fajr-centered experience. |
| **Default morning plan** | The user's normal behavior when no special intention or override exists. |
| **Opportunity** | A passive date meaning surfaced by Subh, such as White Days, Arafah, Ashura, Ramadan, or a weekday fasting opportunity. |
| **Intention** | A meaningful user decision, such as intending to fast, wake earlier, perform Tahajjud, pause an alarm, or mark a Qada fast. |
| **Override** | A user decision that changes the default behavior for a particular scope. |
| **Anchor** | The thing an intention is attached to: a Gregorian date, Hijri date, observance, weekday, month window, or immediate alarm. |
| **Resolved morning** | The final computed state for a morning after calendar, prayer-time, default, opportunity, intention, and conflict rules are applied. |
| **Display horizon** | The range of days Subh currently shows to the user. |
| **Edit horizon** | The range of days or alarms the user is allowed to change. |
| **Operational scheduling horizon** | The range of alarms that Subh actually schedules or activates. |
| **Knowledge range** | The range of dates Subh can calculate or retrieve information for. |
| **Cache** | Temporary stored generated data used for speed or display, not a durable user decision. |
| **Completion record** | A fixed historical record that something happened, such as a completed fast or alarm outcome. |
| **Calendar adjustment** | A user or system change to the effective Hijri calendar mapping. |
| **Calendar version** | A conceptual version of the calendar mapping after adjustments or source changes. Useful for explaining what changed. |

---

## 3. Horizon Model

Subh needs several distinct horizons. These should not be collapsed into one concept.

### 3.1 Knowledge range

The knowledge range is how far Subh can calculate, retrieve, or derive date information.

Subh may be able to know:

- Gregorian dates,
- Hijri dates,
- weekday patterns,
- prayer/Fajr times,
- observance opportunities,
- default wake behavior,
- and candidate future months.

This does **not** mean all known dates are active, stored, or scheduled.

#### Current-range framing

This should be described as the **supported current range**, not merely the “future range.”

The app may currently support browsing a limited number of calendar months based on default/precalculated date data. That current range can be expanded later without changing the core model.

Recommended architecture:

- Treat the supported range as a configurable product setting.
- Do not hard-code the assumption that Subh only ever supports the current Home forecast horizon.
- Do not hard-code the assumption that Subh must always support 365+ days.
- The resolver should work for any date within the supported range.

Possible range settings:

| Range type | MVP / current interpretation | Future scalable interpretation |
|---|---|---|
| Home display range | Next 7 Days | Configurable, likely still a weekly / seven-day horizon |
| Month browsing range | Current supported months, possibly next few months | Current month plus 12 future months |
| Knowledge range | Whatever the prayer/calendar provider can reliably support | 365-400 days or more |
| Operational alarm range | Next immediate alarm | Next immediate alarm, possibly with a small safety buffer |

### 3.2 Display horizon

The display horizon is what the user can see.

Current major display surfaces:

1. **Home / Next 7 Days**
   Shows the near-term morning window.

2. **Weekly Fajrcast**
   Shows short-term Fajr trend behavior.

3. **Calendar month browsing**
   Allows the user to view Gregorian or Hijri month-based morning information within the supported range.

4. **Day detail view**
   Shows a deeper explanation of one selected morning.

Display does not equal scheduling.

A day can be visible without being an active alarm.

### 3.3 Edit horizon

The edit horizon is where user decisions can be made.

There are several types of edits:

| Edit type | Example | Recommended scope |
|---|---|---|
| Active alarm control | Turn off the next alarm | Next immediate alarm only |
| Near-term day adjustment | Change tomorrow's wake behavior | Near-term morning or selected detail view |
| Future intention | Plan Arafah, White Days, Qada, or a future fast | Any allowed browsable date or observance, if product permits |
| Default setting change | Change normal wake offset | Applies broadly to future default days |
| Calendar adjustment | Adjust Hijri date by source/month/offset | Applies based on chosen adjustment scope |

The important rule is:

> **Whenever the user edits a day, Subh must store what the edit is anchored to.**

For example:

- “Fast this White Day” is not the same as “fast this Gregorian date.”
- “Wake for Arafah” is not the same as “wake at 4:30 on March 12.”
- “Turn off next alarm” is not the same as “turn off every alarm for the next seven days.”

### 3.4 Operational scheduling horizon

The operational scheduling horizon is what Subh actually makes eligible for platform delivery.

Aligned doctrine:

> **Only the next immediate alarm is product-active, but the delivery layer may schedule and verify a small technical safety horizon when explicitly supplied by the Active Window Builder.**

This means:

- the user should experience one clear next operational alarm;
- the app may still prepare a narrow set of upcoming resolver-materialized events if the platform or reliability model requires it;
- Next 7 Days rows are not automatically scheduled just because they are visible;
- month browsing never schedules platform alarms by itself;
- future observance plans become platform-deliverable only when the canonical active window includes them.

The active scheduled horizon must be produced by the canonical resolution/window-building path and consumed by the Alarm Delivery Reliability layer. The planning layer must not call platform alarm APIs directly.

### 3.5 History horizon

History is different from future planning.

Completed records should remain fixed.

Examples:

- A completed fast on March 12 remains a completed fast on March 12.
- An alarm that rang or was dismissed should not move because the Hijri calendar was later adjusted.
- If the original label was based on a previous calendar mapping, the app can preserve that context rather than rewriting history.

---

## 4. What Subh Knows, Shows, Remembers, and Schedules

### 4.1 Knows

Subh may know or derive:

- today's Gregorian date,
- future Gregorian dates within supported range,
- effective Hijri dates,
- weekday identity,
- Fajr begin and end times,
- last-third/night-related windows if supported,
- Islamic observance opportunities,
- the user's default morning plan,
- the user's saved intentions,
- and the user's calendar adjustments.

This knowledge may be generated dynamically.

### 4.2 Shows

Subh shows only what is relevant to the current surface:

- the next immediate morning/alarm,
- the Next 7 Days forecast,
- a weekly Fajrcast,
- a selected Gregorian month,
- a selected Hijri month,
- a day detail view,
- review banners when plans move or need user attention.

### 4.3 Remembers

Subh should permanently remember:

- user settings,
- location/prayer calculation preferences,
- default morning plan,
- calendar source or adjustment choices,
- user-created intentions,
- user-created overrides,
- completion records,
- skipped/cancelled history if product supports it,
- and review state for important changes.

Subh should not permanently remember ordinary generated default days unless there is a specific reason.

### 4.4 Schedules

Subh should schedule or activate only events that the canonical active window marks as schedule-eligible.

In product language, this is normally:

- the next immediate alarm the user cares about,
- plus any deliberately configured technical safety buffer used by the delivery layer.

The product concept remains:

> **Future plans are not active alarms until they enter the active scheduled window.**

A browsed month, a displayed Next 7 Days row, or a stored future observance intention is not platform-scheduled merely because it exists.

---

## 5. What “Load Up” Means

The phrase “load up” should be broken into separate meanings.

| Layer | Meaning | Durable? |
|---|---|---|
| **Know** | Subh can calculate or retrieve information for a date. | Not necessarily |
| **Generate** | Subh creates a candidate day from date/calendar/prayer/default rules. | Usually no |
| **Resolve** | Subh applies user settings, opportunities, intentions, and conflicts. | Usually no |
| **Display** | Subh shows the resolved day in a card, month view, or detail page. | No, unless user changes something |
| **Cache** | Subh temporarily stores generated data for speed. | No, it can be invalidated |
| **Remember** | Subh stores a user decision or historical fact. | Yes |
| **Schedule** | Subh activates an alarm/notification. | Only near-term |
| **Complete** | Subh records what happened. | Yes |

This distinction prevents confusion.

Subh does not need to “load up” 365 fully resolved day records. It only needs to be able to resolve a day when the user views it or when it becomes operationally relevant.

---

## 6. Day Resolution Model

### 6.1 Purpose

The day-resolution model answers:

> “What does this morning mean for this user, and what should Subh show or do?”

### 6.2 Inputs to resolution

A resolved morning is generated from these inputs:

1. **Gregorian date**
2. **User time zone / location context**
3. **Prayer-time source and calculation settings**
4. **Fajr begin/end times**
5. **Hijri calendar source and adjustments**
6. **Hijri date at Fajr**
7. **Weekday**
8. **Observance/opportunity rules**
9. **Default morning plan**
10. **Recurring user intentions**
11. **Date-specific user overrides**
12. **Observance-based user intentions**
13. **Immediate alarm override state**
14. **Conflict and validation rules**
15. **Completion/history records, if the date is past or current**
16. **Current time, if active scheduling is being considered**

### 6.3 Outputs of resolution

The output should be a resolved morning state containing:

- Gregorian date label,
- Hijri date label,
- weekday,
- Fajr begin/end times,
- default wake recommendation,
- final wake recommendation,
- fasting state,
- Tahajjud/refinement state if applicable,
- observance tags,
- user intention labels,
- warning/review flags,
- active alarm eligibility,
- current scheduling status,
- and a human-readable explanation of why the morning looks that way.

### 6.4 Recommended resolution order

The resolver should apply layers in a predictable order.

1. **Resolve the Gregorian morning**
   Identify the civil date and local context.

2. **Resolve prayer times**
   Determine Fajr begin/end and any related morning windows.

3. **Resolve the effective Hijri date**
   Apply calendar source and user adjustments.

4. **Identify passive opportunities**
   Determine whether this day appears to be Ramadan, Arafah, Ashura, White Days, a weekday fasting opportunity, etc.

5. **Apply the user's default morning plan**
   Determine what would happen if nothing special were present.

6. **Load applicable user intentions**
   Pull in intentions that match this date by anchor: Gregorian, Hijri, observance, weekday, month window, or immediate alarm.

7. **Apply user overrides**
   Specific user decisions modify or replace default behavior.

8. **Resolve conflicts**
   Detect incompatible plans, religious/calendar conflicts, duplicate intentions, or expired assumptions.

9. **Compute final wake behavior**
   Decide whether there is a wake plan, what time it should target, and whether it is active.

10. **Determine schedule eligibility**
   Determine whether the morning belongs to the canonical active scheduled window. If it does, materialized events can be handed to the delivery layer. The planning layer does not schedule platform alarms directly.

11. **Generate explanation**
   Produce a simple “why this morning looks this way” explanation.

### 6.5 Default days are not decisions

A default day is a generated result, not a stored user decision.

Example:

> March 12 follows the normal Fajr wake plan.

This does not need a durable per-day record.

A record is needed only when something meaningful is stored, such as:

- user intends to fast,
- user changes the wake time,
- user turns off an alarm,
- user marks Qada,
- user sets Tahajjud,
- user completes or skips a fast,
- user creates a calendar adjustment.

---

## 7. Core Data Concepts in Plain Language

This section describes the recommended data concepts without requiring technical implementation details.

### 7.1 User settings

Stores the user's broad preferences:

- location or prayer-time location,
- prayer calculation method,
- Hijri calendar source/adjustment preference,
- default wake offset,
- default alarm behavior,
- notification preferences,
- default fasting/wake behavior if supported.

### 7.2 Default morning plan

Stores what Subh should normally do on an ordinary morning.

Examples:

- wake at Fajr,
- wake 20 minutes before Fajr,
- show Fajr but do not alarm by default,
- use a certain sound/vibration pattern,
- treat fasting days differently by default.

### 7.3 Calendar source state

Stores the source and current adjustments used to determine the effective Hijri date.

It should include enough information to answer:

- what default source was used,
- whether the user manually adjusted the Hijri date,
- what the adjustment scope was,
- when the adjustment was made,
- which future/past dates it applies to,
- and what calendar version was active when a user created an intention.

### 7.4 Observance rule

An observance rule defines an Islamic opportunity or calendar meaning.

Examples:

- White Days,
- Arafah,
- Ashura,
- Ramadan,
- Shawwal fasting window,
- Monday/Thursday fasting pattern,
- Dhul Hijjah first days,
- Qada planning state, if treated as a user-selected fasting category.

Each observance rule should define:

- its label,
- its anchor type,
- how candidate dates are determined,
- whether it is passive or user-selectable,
- whether it can create a fasting intention,
- whether it affects wake behavior,
- whether it has conflict rules,
- and what user-facing explanation should appear.

### 7.5 User intention

A user intention is a durable user decision.

A user intention should include:

- what the user intended,
- why or for what purpose,
- what it is anchored to,
- when it was created,
- what calendar mapping existed when it was created,
- whether it repeats,
- whether it is still planned, completed, cancelled, or needs review,
- and what wake behavior is attached to it.

Examples:

- “Fast Arafah.”
- “Fast this White Day.”
- “Fast on March 12.”
- “Do a Qada fast on this date.”
- “Wake 45 minutes before Fajr for this observance.”
- “Turn off tomorrow's alarm.”

#### 7.5.1 Minimum durable fields for an anchored intention

Codex should treat a future user decision as more than `dateKey + mode` when the decision can move or recur.

Conceptual durable model:

```swift
struct MorningPlanningIntent: Codable, Equatable, Sendable {
    let id: String
    var kind: MorningPlanningIntentKind
    var anchor: MorningIntentAnchor
    var wakeRule: MorningWakeRule?
    var linkedOpportunityIDs: Set<String>
    var status: MorningPlanningIntentStatus
    var calendarSnapshotAtCreation: CalendarVersionSnapshot?
    var createdFromSurface: PlanningIntentSource
    var createdAt: Date
    var updatedAt: Date
    var reviewState: PlanningReviewState?
}
```

Conceptual anchor model:

```swift
enum MorningIntentAnchor: Codable, Equatable, Sendable {
    case gregorianDate(dateKey: String)
    case hijriDate(month: Int, day: Int, year: Int?)
    case observance(observanceID: String, occurrenceID: String?)
    case weekdayPattern(weekdays: Set<Int>)
    case hijriMonthWindow(month: Int, year: Int?, ruleID: String?)
    case gregorianRange(startDateKey: String, endDateKey: String)
    case immediateAlarm(activeAlarmID: String?)
    case defaultSetting(ruleID: String)
    case completionHistory(historyID: String)
}
```

Conceptual calendar snapshot:

```swift
struct CalendarVersionSnapshot: Codable, Equatable, Sendable {
    let calendarVersionID: String
    let sourceID: String
    let adjustmentScope: HijriAdjustmentScope
    let adjustmentValueDays: Int
    let effectiveFromDateKey: String?
    let createdAt: Date
    let displayedGregorianDateKeyAtCreation: String?
    let displayedHijriLabelAtCreation: String?
}
```

The exact Swift names can differ. The required behavior is that a user-created future plan must carry enough information to answer:

- what the user intended;
- what the intention follows;
- whether it should move after a Hijri/calendar adjustment;
- what calendar context existed when the user created it;
- whether it needs review after a later change.


### 7.6 Wake rule

A wake rule describes how the wake time is calculated.

Wake rules may be:

| Wake rule type | Example | Behavior when Fajr changes |
|---|---|---|
| **Relative to Fajr** | Wake 45 minutes before Fajr | Moves when Fajr time changes |
| **Exact clock time** | Wake at 4:30 AM | Stays at 4:30 unless invalid/conflicting |
| **Default offset** | Use normal default | Updates when default changes |
| **No alarm** | Do not alarm | No alarm is scheduled |
| **Immediate alarm override** | Turn off next alarm only | Applies only to next active alarm |

Wake rules need anchors too.

A wake change should follow the thing it was made for.

- Wake for Arafah should move with Arafah.
- Wake for March 12 should stay on March 12.
- Wake for Monday fasts should follow Mondays.
- Turning off the next alarm should affect only the next active alarm.

### 7.7 Resolved morning

A resolved morning is not usually a durable record.

It is the generated answer to:

> “Given all current settings, calendars, intentions, and rules, what does this morning look like?”

It can be displayed and cached, but it should be regenerated when important inputs change.

### 7.8 Active alarm

The active alarm is the operational alarm for the next immediate morning.

It should store enough information to manage the device/platform behavior, but it should not become the permanent truth of the user's plan.

The source of truth remains:

- settings,
- calendar state,
- intentions,
- and resolution rules.

### 7.9 Completion record

A completion record stores what happened.

Examples:

- the user completed a fast,
- the user skipped a planned fast,
- the alarm rang,
- the alarm was dismissed,
- the user marked Tahajjud completed,
- the user cancelled a plan.

Completion records should remain tied to the Gregorian date/time when the action actually occurred, while preserving the calendar/observance context that was active at the time.

---

## 8. Intention Anchoring Model

### 8.1 Why anchors matter

A future user plan must answer:

> “If the calendar changes, should this plan move?”

That depends on what the user meant.

If the user meant:

- “I want to fast Arafah,” the plan should follow Arafah.
- “I want to fast March 12,” the plan should stay on March 12.
- “I want to fast Mondays,” the plan should follow Mondays.
- “I want to turn off the next alarm,” it should affect only the next active alarm.

### 8.2 Anchor types

| Anchor type | Example | Behavior when Hijri calendar changes |
|---|---|---|
| **Gregorian-date anchor** | Fast March 12; wake at 4:30 on this date | Stays on that Gregorian date |
| **Hijri-date anchor** | Fast 10 Muharram; fast 13 Ramadan | Moves to the Gregorian date that now corresponds to that Hijri date |
| **Observance anchor** | Fast Arafah; Fast Ashura; Fast White Days | Moves with the observance |
| **Weekday anchor** | Fast Mondays and Thursdays | Stays with weekdays, not Hijri dates |
| **Hijri-month window anchor** | Six days of Shawwal; Ramadan mornings | Remains inside that Hijri month/window and may need review after adjustment |
| **Gregorian-range anchor** | Wake differently during a work trip | Stays with the civil date range |
| **Immediate-alarm anchor** | Turn off next alarm | Applies only to the next active alarm |
| **Completion-history anchor** | I fasted that day | Does not move after completion |
| **Default-setting anchor** | My normal wake is 30 minutes before Fajr | Applies to all future default days unless overridden |

### 8.3 Anchor selection principles

1. **Use the user's explicit wording when available.**
   If the button says “Fast Arafah,” use an observance anchor.

2. **Use the surface context.**
   If the user taps a White Day tag and selects “fast this White Day,” use an observance anchor. If they tap a generic date and select “fast this date,” use a Gregorian anchor.

3. **When ambiguity matters, ask simply.**
   Present two choices:
   - “Fast this White Day — moves if your Hijri calendar is adjusted.”
   - “Fast this date — stays on March 12.”

4. **Wake behavior inherits the parent anchor unless the user says otherwise.**
   If a custom wake is attached to Arafah, it moves with Arafah. If it is attached to March 12, it stays on March 12.

5. **Completed records do not inherit future movement.**
   Once completed, history stays fixed.

### 8.4 User-facing anchor labels

Subh should expose the anchor in plain language only when useful.

Recommended labels:

| Internal meaning | User-facing phrase |
|---|---|
| Gregorian-date anchor | “Stays on this date” |
| Hijri-date / observance anchor | “Moves with Hijri date” or “Follows this observance” |
| Weekday anchor | “Follows Mondays/Thursdays” |
| Immediate-alarm anchor | “Only affects next alarm” |
| Completion-history anchor | “Saved as history” |
| Needs review | “Review needed after calendar change” |

---

## 9. Hijri Calendar Adjustment Model

### 9.1 Core problem

The Hijri date associated with a Gregorian morning may change because:

- the app's default calendar source changes,
- the user manually adjusts the Hijri date,
- a local community/moon-sighting decision differs from the calculated date,
- a future month is later confirmed differently,
- the user chooses a different authority/source,
- or the user corrects the displayed date.

When this happens, future observance-based plans may need to move.

### 9.2 Calendar adjustment principle

> **A Hijri calendar adjustment changes future calendar meaning. It should not rewrite completed history.**

### 9.3 Possible adjustment scopes

Subh should distinguish adjustment scope. These may not all be MVP features, but the model should allow them.

| Adjustment scope | Meaning | Product implication |
|---|---|---|
| **Global offset** | Shift all Hijri dates by +1/-1 | Simple, but may be too broad |
| **Current-month adjustment** | Correct the current Hijri month | Better matches month-specific moon-sighting reality |
| **Future-month confirmation** | Confirm a specific future Hijri month start | Useful for Ramadan, Shawwal, Dhul Hijjah |
| **Source/authority change** | Use a different calendar provider or community authority | Re-resolve future observances |
| **Single-day correction** | Correct one displayed day | Risky if it creates inconsistency; should be limited |
| **Effective-from adjustment** | Apply adjustment from a date forward | Useful during transition periods |

### 9.4 Recommended MVP approach

For early versions, Subh can use a simple Hijri adjustment mechanism, but it should still store enough context to avoid future confusion.

Minimum recommended fields conceptually:

- adjustment value, such as +1 or -1,
- date/time the adjustment was made,
- scope of the adjustment,
- whether it applies to future unresolved days,
- calendar source before and after,
- and the calendar version created by the adjustment.

Even if implementation is simple, the product should treat it as a versioned calendar state.

### 9.5 What happens after a Hijri adjustment

When the user adjusts the Hijri calendar, Subh should:

1. Save the new calendar adjustment.
2. Create or update the effective calendar version.
3. Re-resolve affected future mornings.
4. Move future observance/Hijri-anchored intentions when appropriate.
5. Keep Gregorian-date intentions on their original dates.
6. Preserve completed history.
7. Re-check conflicts, especially fasting conflicts.
8. Refresh the next immediate alarm if affected.
9. Show a concise review summary to the user.

### 9.6 Hijri adjustment behavior by anchor type

| Anchor type | After Hijri adjustment |
|---|---|
| Gregorian-date anchor | Stays on the same Gregorian date; observance label may change |
| Hijri-date anchor | Moves to the new Gregorian date for that Hijri date |
| Observance anchor | Moves with the observance |
| Weekday anchor | Stays on same weekday pattern; re-check conflicts |
| Hijri-month window anchor | Revalidates within the new month/window; may need review |
| Immediate-alarm anchor | Applies only if the next active alarm is still the relevant one |
| Completion-history anchor | Does not move |
| Default-setting anchor | Re-resolves future default days |

### 9.7 User-facing review after adjustment

Subh should avoid silent calendar-driven movement.

Example summary:

> “Your Hijri calendar was adjusted. 2 observance-based plans moved. 1 date-specific plan stayed where it was. Your next alarm was updated.”

Example detailed messages:

- “Your Ashura fast moved from March 12 to March 13 because your Hijri calendar was adjusted.”
- “Your March 12 fast stayed on March 12 because it was saved as a date-specific fast.”
- “One Shawwal fast may now fall outside Shawwal. Please review.”
- “Your next alarm changed because tomorrow's morning state changed.”

### 9.8 Calendar snapshot at creation

When a user creates a future intention, Subh should remember the calendar context at creation.

This is useful for explanation.

Example:

- User created an Ashura fast when March 12 was displayed as 10 Muharram.
- Later, the calendar changes and 10 Muharram moves to March 13.
- Subh can explain: “This was originally shown on March 12, but now follows Ashura on March 13.”

This is not about storing stale data as truth. It is about preserving user trust.

---

## 10. Observance and Fasting Intention Rules

### 10.1 Observances should be configuration-driven

Observance rules should be treated as configuration or domain rules, not scattered one-off logic.

Each observance should have:

- a stable identity,
- a label,
- an anchor type,
- candidate dates,
- user actions available,
- default display behavior,
- possible wake behavior,
- conflict rules,
- and review behavior after calendar changes.

### 10.2 Observance examples

The following examples are product modeling examples and should be validated with the religious/content authority chosen for the app.

| Observance / pattern | Likely anchor | Behavior |
|---|---|---|
| Arafah | Observance / Hijri date | Moves with the effective Hijri calendar or chosen authority |
| Ashura | Observance / Hijri date | Moves with Muharram date mapping; paired fast patterns need to move together |
| White Days | Hijri date range / observance | Moves with the 13th-15th Hijri dates of the selected month |
| Monday/Thursday | Weekday | Stays on weekday pattern; re-check if conflicts arise |
| Ramadan | Hijri-month window | Moves with Ramadan calendar mapping |
| First days of Dhul Hijjah | Hijri-month range | Moves with Dhul Hijjah mapping |
| Six days of Shawwal | Hijri-month window | Planned dates must remain inside Shawwal or need review |
| Qada fast | Usually user-selected/date-specific unless tied to a window | Should follow the user's selected date unless explicitly attached to a broader plan |
| Tahajjud refinement | Usually wake-rule modifier | Follows whatever day/intention it is attached to |

### 10.3 Observance intent versus date intent

Subh must distinguish:

- “Fast this observance.”
- “Fast this date.”

Example:

Before adjustment:

- March 12 displays as a White Day.
- User chooses to fast.

If the user selected “Fast this White Day,” the plan moves if the White Day moves.

If the user selected “Fast this date,” the plan stays on March 12.

### 10.4 Weekday fasting

Monday/Thursday fasting should be modeled as a weekday pattern, not a Hijri-date pattern.

If the Hijri calendar shifts, Monday remains Monday.

However, the resolved day may now have a conflict or higher-priority meaning.

Example:

- A Monday fast remains on Monday.
- If that Monday now appears to be Eid or another conflict day under the adjusted calendar, Subh should mark it for review instead of silently promoting the fast.

### 10.5 Shawwal window

Six days of Shawwal are best modeled as a Hijri-month window rather than a single fixed observance date.

If the user selects six specific dates and the Hijri calendar later shifts, Subh should re-check whether the selected dates remain inside Shawwal.

If not, the app should create a review item.

### 10.6 Arafah authority issue

Arafah can be sensitive because users may follow different authorities or communities.

Subh should not try to decide that debate silently.

Recommended product stance:

> “Arafah follows your selected Hijri calendar setting.”

Possible future setting:

- Follow local Hijri calendar.
- Follow Makkah/Hajj-based date.
- Manually select Arafah date.

This does not need to be MVP, but the model should not block it.

---

## 11. Active Alarm and Scheduling Doctrine

### 11.1 Active alarm versus planned morning

A planned morning is not necessarily an active alarm.

| Concept | Meaning |
|---|---|
| Planned morning | The user or default rules indicate what should happen when the date arrives |
| Visible morning | The morning appears on a card or calendar view |
| Resolved morning | Subh has computed the current state for display or decision-making |
| Active alarm | The next alarm actually scheduled/activated on the device |
| Completed morning | A past morning with recorded outcome/history |

### 11.2 Core scheduling rule

> **The next immediate alarm is the product-operational object.**

The Next 7 Days forecast can be resolved and shown. A future month can be browsed. But Subh should only activate events inside the canonical active scheduled window.

For MVP, that active scheduled window may be the next immediate alarm only. If engineering chooses a small technical safety buffer, the user-facing product model should still distinguish the next immediate alarm from additional background scheduled events used for reliability.

### 11.3 Refresh triggers

Subh should refresh the active alarm when any of these occur:

- the app launches,
- the day rolls over,
- the next active alarm is dismissed, completed, or cancelled,
- the user changes the default morning plan,
- the user changes a relevant intention,
- the user adjusts the Hijri calendar,
- the user changes prayer-time calculation settings,
- the user changes location/time zone,
- the user changes an alarm setting,
- the prayer-time data is updated,
- the currently active resolved morning becomes stale.

### 11.4 Turning off an alarm

Turning off an alarm must be scoped clearly.

Possible meanings:

| User action | Meaning |
|---|---|
| Turn off next alarm | Immediate-alarm anchor only |
| Turn off alarm for this date | Gregorian-date or selected-day anchor |
| Turn off alarm for this observance | Observance anchor |
| Change default to no alarm | Default-setting anchor |

MVP should prefer the safest interpretation:

> **Turning off from the active alarm surface affects only the next immediate alarm unless the user explicitly chooses a broader scope.**

### 11.5 Alarm after calendar/settings change

If a Hijri adjustment or setting change affects the next morning before the alarm has fired, Subh should update the active alarm.

If the alarm has already fired or the morning is already historical, Subh should not retroactively change it. Future state should update normally.

### 11.6 Alarm record should explain its source

The active alarm should be explainable.

Example explanation:

> “Alarm set for 4:42 AM because you are fasting Arafah and your fasting wake is 45 minutes before Fajr.”

This explanation helps detect incorrect states and supports the user interface.

---

## 12. Next 7 Days Behavior

### 12.1 Purpose

The Next 7 Days card is a near-term view of the user's upcoming Fajr-centered days.

It should answer:

- What is coming up across the next week?
- Which days are ordinary Fajr days?
- Which days have observance opportunities?
- Which days have user intentions?
- Which day is operationally next?
- Which day needs review?

### 12.2 Rolling weekly window

The Next 7 Days view should behave like a rolling weekly window.

Each day:

- the completed/past morning drops out,
- the remaining visible days shift forward,
- a new morning enters at the end of the seven-day window,
- and all displayed days are re-resolved using current settings.

The first visible row is the next immediate alarm or next relevant morning supplied by the canonical resolver. If today's relevant wake/alarm moment is still upcoming, the first row may be today. If it has passed, the first row is normally tomorrow.

### 12.3 Weekly Fajrcast alignment

Next 7 Days and Weekly Fajrcast must describe the same seven visible dates.

Rules:

- `Next7.visibleDateKeys` and `WeeklyFajrcast.visibleDateKeys` must match exactly.
- The first visible date is the forecast start date.
- The remaining six dates are the following six calendar mornings.
- Neither surface should include previous mornings in this aligned MVP behavior.
- Neither surface should silently skip Quiet, no-alarm, unavailable, or opportunity-only days.

### 12.4 What each card should show

Each card may show:

- Gregorian date,
- weekday,
- Hijri date,
- Fajr begin/end,
- default wake or final wake,
- fasting intention if present,
- observance/opportunity tag,
- warning/review state,
- active alarm state if it is the next immediate alarm.

### 12.5 User changes in Next 7 Days

If the user changes a day reached from Next 7 Days, Subh must store the change as an anchored intention or override.

Examples:

- “Fast this date” → Gregorian anchor.
- “Fast this White Day” → observance/Hijri anchor.
- “Wake earlier for this fast” → follows the fast's anchor.
- “Turn off next alarm” → immediate-alarm anchor.

### 12.6 Default cards are generated, not stored

A day appearing in the Next 7 Days card does not mean Subh has permanently stored a record for that day.

If the user does not modify the card, no durable day-specific record is needed.

---

## 13. Future / Current Month Browsing Behavior

### 13.1 Purpose

Month browsing allows the user to look beyond the near-term morning window.

It may support:

- Gregorian month browsing,
- Hijri month browsing,
- selected future months within the supported current range,
- monthly Fajrcast trend lines,
- and day detail access.

### 13.2 Current implementation framing

The app may currently allow the user to view a limited number of calendar months based on default/precalculated data.

This specification treats that as:

> **A display and planning surface, not an active scheduling surface.**

### 13.3 Generating a month

When the user opens a month, Subh should generate the month from current rules:

- Gregorian dates,
- Hijri dates,
- weekdays,
- Fajr begin/end times,
- default wake line,
- observance opportunities,
- saved user intentions,
- review flags.

The generated month can be cached temporarily.

### 13.4 Cache behavior

Month-view cache should be invalidated when relevant inputs change:

- Hijri calendar adjustment,
- prayer-time method change,
- location/time-zone change,
- default wake setting change,
- user creates/changes/deletes an intention,
- observance rule data changes,
- supported range changes.

The month view should never be treated as the durable source of truth.

### 13.5 Editing from month view

If the user opens a day detail view from a month and changes something, Subh should store an anchored intention or override.

If the user merely browses and exits, nothing durable should be stored.

### 13.6 Monthly Fajrcast

The monthly Fajrcast should provide trend-level understanding rather than dense day-level icons.

Recommended lines:

- Fajr begins,
- Fajr ends,
- default wake time,
- possibly user-specific wake trend if not too noisy.

Optional markers:

- planned fasts,
- review-needed dates,
- major observances.

The monthly Fajrcast should not imply that every day is actively scheduled.

---

## 14. State Precedence and Merge Rules

### 14.1 Why precedence matters

Multiple rules may apply to the same morning.

Example:

- The day is Monday.
- It is also a White Day.
- The user planned a Qada fast.
- The user turned off the next alarm.
- The default plan says wake 30 minutes before Fajr.

Subh needs predictable merge rules.

### 14.2 Recommended layer order

A useful order is:

1. **Input validity and current-time boundary**
   Is the required date/prayer/calendar data available, and has the relevant morning or alarm already passed? Platform delivery failure is handled later and must not rewrite intent.

2. **Immediate user command**
   Example: turn off the next active alarm.

3. **Date-specific user override**
   Example: March 12 no alarm.

4. **Observance-specific user intention**
   Example: fast Arafah, wake 45 minutes before Fajr.

5. **Recurring user intention**
   Example: fast Mondays and Thursdays.

6. **Seasonal/month mode**
   Example: Ramadan wake behavior.

7. **Default morning plan**
   The ordinary behavior.

8. **Passive opportunity tags**
   Display-only meanings that do not become user decisions unless selected.

### 14.3 Specificity rule

More specific user decisions usually beat broader defaults.

Examples:

- A March 12 custom wake beats the general default wake.
- A date-specific no-alarm override beats a recurring Monday fast wake alarm.
- An Arafah-specific wake can beat the normal fasting wake.

### 14.4 Compatibility rule

Some states can combine.

Examples:

| Combination | Behavior |
|---|---|
| Fast + Tahajjud | Compatible; wake may be adjusted earlier |
| Fast + Qada label | Compatible if user chose Qada as fast type |
| White Day + Monday | Both tags can show; one user intention may cover both or user can choose meaning |
| Fast + no alarm | Compatible if user intends to fast but not be woken |
| Date-specific wake + observance tag | Compatible; wake follows date unless tied to observance |

### 14.5 Conflict rule

Some states require review.

Examples:

- planned voluntary fast appears to fall on a day where fasting should not be recommended,
- Shawwal fast moved outside Shawwal after adjustment,
- two different wake times compete at the same specificity level,
- user has both “no alarm” and “wake me” for the same anchor,
- active alarm time is already in the past,
- calendar mapping changed after the user created an observance plan.

Conflict handling should avoid silent overwrites.

### 14.6 Last-action rule

When two decisions are equal in scope and cannot both apply, the most recent explicit user decision should usually win, but Subh should make the change visible if it materially alters the morning.

Example:

- User first sets wake 45 minutes before Fajr for March 12.
- Later, user sets no alarm for March 12.
- No alarm wins, and the day detail should show that it replaced the custom wake.

---

## 15. History and Completion Model

### 15.1 Core rule

> **Completed history stays fixed.**

Future plans may move. Completed records should not.

### 15.2 What history should preserve

A completion record should preserve:

- the Gregorian date/time of the action,
- the user action or outcome,
- the intention it was associated with,
- the Hijri date label shown at the time,
- the calendar version/source used at the time,
- the wake/alarm outcome if relevant,
- and any user-entered label such as Qada or fast type.

### 15.3 What happens after calendar adjustment

If the calendar changes after completion:

- do not move the completed fast,
- do not erase the user's history,
- do not relabel the action as invalid,
- optionally show a note if current calendar mapping differs.

Example wording:

> “You completed a fast on March 12. Your current Hijri calendar now places this observance on March 13.”

### 15.4 Future plan becomes past

If a future plan passes without completion or cancellation, Subh needs a product policy.

Possible statuses:

- completed,
- skipped,
- missed,
- expired without outcome,
- cancelled before date,
- unknown.

This can be refined later, but the system should not leave old planned intentions pretending they are still future plans.

---

## 16. Change Scenario Matrix

| Change scenario | What should move? | What should stay? | Required action |
|---|---|---|---|
| User adjusts Hijri calendar | Future Hijri/observance-anchored plans | Gregorian-date plans and completed history | Re-resolve, refresh active alarm, show review summary |
| User changes prayer calculation method | Wake times based on Fajr | User intentions and anchors | Recalculate Fajr/wake times, refresh active alarm |
| User changes location | Prayer times and possibly time zone | Intention anchors | Recalculate affected days, refresh active alarm |
| User changes default wake offset | Default days and default-based wake rules | Specific custom wake overrides | Re-resolve future days |
| User changes exact custom wake time | That specific anchored wake rule | Other default behavior | Update related resolved days/alarm |
| User turns off next alarm | Next immediate alarm only | Future plans unless explicitly changed | Mark immediate-alarm override, update active alarm |
| User plans Arafah | Future observance plan | Date-specific plans | Store observance anchor |
| User plans March 12 fast | March 12 date-specific plan | Observance mapping | Store Gregorian anchor |
| User opens a month and exits | Nothing durable | Existing settings/intentions | No permanent record needed |
| User opens a month and edits day | Stored user intention/override | Generated month cache | Store anchored intention |
| Calendar source updates from provider | Future generated calendar meanings | Completed history | Re-resolve future; review plans if changes matter |
| Daylight saving/time-zone shift | Clock times may change | Intention anchors | Recalculate and refresh active alarm |
| Prayer times unavailable | Cannot fully resolve wake time | Stored intentions | Show degraded/needs data state |
| User changes Hijri after alarm fired | Future meanings | Alarm history/current completion | Do not retroactively reschedule past alarm |
| User deletes intention | That stored intention | Passive observance tag | Re-resolve affected days |

---

## 17. Edge Case Catalogue

### 17.1 White Day planned as observance, then Hijri shifts

Scenario:

1. March 12 displays as a White Day.
2. User selects “Fast this White Day.”
3. User later adjusts Hijri calendar.
4. White Day now falls on March 13.

Expected behavior:

- Move the planned fast to March 13.
- Remove the planned White Day fast from March 12 unless another intention exists there.
- Show a review message explaining the movement.

### 17.2 White Day planned as date-specific fast, then Hijri shifts

Scenario:

1. March 12 displays as a White Day.
2. User selects “Fast this date.”
3. User later adjusts Hijri calendar.
4. March 12 is no longer a White Day.

Expected behavior:

- Keep the fast on March 12.
- Remove or update the White Day tag.
- Optionally show that the fast is no longer tied to the White Day under the current calendar.

### 17.3 Ashura plan moves

Scenario:

1. User plans Ashura when 10 Muharram maps to March 12.
2. Hijri adjustment moves 10 Muharram to March 13.

Expected behavior:

- Move the Ashura plan to March 13.
- If paired Ashura pattern is selected, move the paired dates together.
- Show clear explanation.

### 17.4 Arafah authority changes

Scenario:

1. User plans Arafah according to one calendar source.
2. User changes Arafah/Hijri authority.

Expected behavior:

- Move Arafah plan according to the selected authority.
- Preserve original creation context.
- Show review notice.

### 17.5 Monday fast falls on a conflict day after Hijri adjustment

Scenario:

1. User has recurring Monday fasts.
2. Hijri adjustment makes an upcoming Monday fall on a day where voluntary fasting should not be promoted.

Expected behavior:

- Keep the Monday pattern.
- Mark that specific date as review-needed.
- Do not silently schedule/promote the fast as ordinary.

### 17.6 Shawwal fast falls outside Shawwal after adjustment

Scenario:

1. User chooses six Shawwal fast dates.
2. Calendar adjustment shifts Shawwal boundary.
3. One selected date is now outside Shawwal.

Expected behavior:

- Keep the user's selected date record if it was date-specific.
- Mark the Shawwal plan as needing review.
- Offer to move/replace the affected date.

### 17.7 Ramadan shifts after future defaults are displayed

Scenario:

1. User browses Ramadan month view.
2. App displays Ramadan wake behavior.
3. Hijri adjustment shifts Ramadan start.

Expected behavior:

- Regenerate Ramadan month view.
- Move Ramadan-anchored behavior.
- Keep date-specific user overrides where they are.
- Refresh active alarm if near-term.

### 17.8 Completed fast no longer matches current observance mapping

Scenario:

1. User completed a fast on March 12 when it displayed as Ashura.
2. Later, Hijri calendar shifts and Ashura displays on March 13.

Expected behavior:

- Keep March 12 completion record.
- Preserve original label/context.
- Optionally show that current calendar mapping differs.
- Do not move history.

### 17.9 User changes default wake after creating an observance wake

Scenario:

1. Default wake is 30 minutes before Fajr.
2. User sets Arafah wake to 45 minutes before Fajr.
3. User changes default wake to 20 minutes before Fajr.

Expected behavior:

- Ordinary default days now use 20 minutes.
- Arafah remains 45 minutes unless it was explicitly set to “use default.”

### 17.10 User changes calculation method after setting relative wake

Scenario:

1. User sets wake 45 minutes before Fajr.
2. Fajr time changes due to calculation method update.

Expected behavior:

- Preserve “45 minutes before Fajr.”
- Recalculate actual clock time.

### 17.11 User changes calculation method after setting exact clock wake

Scenario:

1. User sets March 12 wake at 4:30 AM.
2. Fajr time changes.

Expected behavior:

- Keep 4:30 AM unless it becomes invalid or conflicts with the intended purpose.
- Show warning if 4:30 is no longer sensible relative to Fajr.

### 17.12 User turns off next alarm while future fast remains planned

Scenario:

1. Tomorrow is a planned fasting day.
2. User turns off next alarm from the active alarm surface.

Expected behavior:

- Turn off only the next active alarm.
- Preserve the fasting intention unless user explicitly cancels it.
- Day card can show “fast planned, alarm off.”

### 17.13 User opens a future month but does not edit

Expected behavior:

- Generate and display the month.
- Cache if useful.
- Store nothing permanent.

### 17.14 User opens a future month and edits a detail day

Expected behavior:

- Store anchored intention/override.
- Re-resolve the month view with the saved change.
- Ensure the change appears later in Next 7 Days when the date approaches.

### 17.15 User changes Hijri calendar after Fajr

Scenario:

1. A morning has effectively passed.
2. User adjusts Hijri calendar.

Expected behavior:

- Do not retroactively reschedule the passed alarm.
- Preserve any completion/outcome records.
- Apply calendar change to future unresolved mornings.
- For the current day, product should define whether the day is still editable or historical.

### 17.16 Date begins at sunset, but Subh is a morning app

Subh needs a consistent operational definition.

Recommended rule:

> **For morning planning, Subh uses the Hijri date that is active at Fajr for that morning.**

Night-based features may need separate logic later.

Example:

- A Ramadan night or odd-night flow may belong to the previous Gregorian evening and the next morning.
- A Fajr-centered fast should resolve according to the Islamic day active at Fajr.

### 17.17 Stale cache after settings change

Scenario:

1. User browses a month.
2. The month is cached.
3. User changes Hijri adjustment or calculation method.

Expected behavior:

- Invalidate the cached month.
- Regenerate from current settings.
- Do not show stale observance/wake labels.

### 17.18 Prayer times unavailable

Scenario:

1. Calendar date can be displayed.
2. Prayer times are missing or fail to load.

Expected behavior:

- Show date and intention information if available.
- Mark wake/alarm resolution as unavailable or needs data.
- Do not schedule an alarm from incomplete/uncertain data unless a fallback policy exists.

### 17.19 Offline mode

Scenario:

1. User is offline.
2. App needs to show/schedule near-term morning.

Expected behavior:

- Use locally available trusted data if present.
- Indicate if data may be stale.
- Do not lose saved intentions.
- Refresh when connection returns.

### 17.20 Multiple overlapping intentions

Scenario:

A day is Monday, a White Day, and the user also planned Qada.

Expected behavior:

- Show compatible labels if appropriate.
- The user intention should be explicit: for example, “Qada fast” may be the main fast purpose while White Day remains an opportunity tag.
- Avoid double-counting one fast as multiple completed purposes unless the product intentionally supports that interpretation.

---

## 18. User Experience Requirements

### 18.1 Explain why a morning looks different

Subh should help the user understand:

- why the wake time changed,
- why a fast appears,
- why a plan moved,
- why an alarm is off,
- why review is needed.

A “Why this morning?” explanation can be simple:

> “This is Arafah according to your Hijri calendar. You planned to fast Arafah, so your wake is 45 minutes before Fajr.”

### 18.2 Make anchor behavior understandable

Plain labels:

- “Follows this observance.”
- “Moves with Hijri date.”
- “Stays on this date.”
- “Follows Mondays.”
- “Only affects next alarm.”

These labels should appear at decision points, not everywhere.

### 18.3 Calendar adjustment review

When Hijri calendar changes affect future plans, show a review summary.

Recommended design pattern:

- small banner after change,
- list of affected plans,
- clear moved/stayed distinction,
- action to review if needed,
- no alarming language.

### 18.4 Do not overload the user

Most users should not need to think about anchors.

Use obvious defaults:

- Button says “Fast Arafah” → observance anchor.
- Button says “Fast this date” → date anchor.
- Button says “Turn off next alarm” → immediate-alarm anchor.

Ask only when the choice is genuinely ambiguous.

### 18.5 Use compassionate language around religious uncertainty

Subh should not overstate authority.

Recommended tone:

- “Based on your Hijri calendar...”
- “This may need review...”
- “Your current calendar now places...”
- “Would you like to adjust this plan?”

Avoid:

- declaring a user's completed worship invalid,
- silently rewriting history,
- implying the app is the final religious authority.

---

## 19. Acceptance Criteria

### 19.1 Default generation

Given a user opens Next 7 Days and makes no edits, Subh should not create durable day-specific records for each default day.

### 19.2 Anchored future intention

Given a user selects “Fast Arafah,” Subh stores an observance-anchored intention, not only a Gregorian date.

### 19.3 Gregorian date intention

Given a user selects “Fast this date,” Subh keeps that plan on the selected Gregorian date even if the Hijri calendar changes.

### 19.4 Hijri adjustment movement

Given a user adjusts the Hijri calendar and a future observance-based intention is affected, Subh moves that intention with the observance and explains the movement.

### 19.5 Hijri adjustment does not move history

Given a completed fast exists and the Hijri calendar later changes, Subh preserves the completed fast on its actual date.

### 19.6 Active alarm refresh

Given a settings or calendar change affects the next immediate alarm before it fires, Subh refreshes the active alarm.

### 19.7 Turn off next alarm

Given the user turns off the next alarm from the active alarm surface, only the next immediate alarm is disabled unless the user explicitly chooses a broader scope.

### 19.8 Month browsing without edits

Given the user opens a future month and exits without edits, Subh stores no durable day-specific records.

### 19.9 Month browsing with edits

Given the user edits a day from month view, Subh stores the edit as an anchored user intention or override.

### 19.10 Cache invalidation

Given the user changes Hijri adjustment, prayer calculation method, location, or default wake settings, Subh invalidates affected generated views and re-resolves them.

### 19.11 Conflict review

Given a future plan becomes questionable after a calendar change, Subh marks it for review rather than silently applying an unsafe or contradictory state.


### 19.12 Display horizon does not schedule

Given a day appears in Next 7 Days or month browsing, Subh should not schedule a platform delivery for that day unless the canonical active window explicitly includes a resolver-materialized event for that date.

### 19.13 Active scheduled window handoff

Given the canonical resolver/window builder produces `scheduledDays`, the delivery layer should schedule and verify only those events, not all visible or cached days.

### 19.14 Delivery failure does not rewrite anchor

Given a planned observance fast is active but alarm delivery is permission-blocked, the intention anchor remains unchanged and the date must not become Quiet or date-specific merely because delivery failed.

### 19.15 Hijri adjustment creates review state

Given a calendar adjustment moves any future observance/Hijri-anchored intention, Subh should create a review summary or review state that can be surfaced to the user.

### 19.16 Month cache is not source of truth

Given a cached month exists and a user creates or changes an anchored intention, Subh should invalidate or refresh affected month snapshots from source settings and intentions.

### 19.17 Date-specific override versus anchored intention

Given a user selects “Fast this date,” Subh may store a date-specific override. Given a user selects “Fast this observance,” Subh must store an observance/Hijri anchor rather than only a date-specific override.

### 19.18 Immediate alarm override expires or resolves

Given the user turns off only the next alarm, that immediate-alarm override should not continue suppressing future mornings after the relevant alarm/morning has passed.

---

## 20. Implementation Guidance in Plain English

This section is intentionally non-technical, but should still be useful to engineering.

### 20.1 Build around a resolver

Subh should have a central day resolver.

The resolver answers:

> “For this date and this user, what is the morning state right now?”

The resolver should use current settings and stored intentions. It should not depend on permanently stored generated days.

### 20.2 Store source ingredients, not cooked days

Store:

- settings,
- calendar adjustments,
- intentions,
- overrides,
- completions.

Generate:

- ordinary day cards,
- month rows,
- opportunity tags,
- default wake results,
- Fajrcast trend lines.

### 20.3 Version calendar context

Whenever Hijri settings change materially, the app should be able to know that the calendar context changed.

This supports:

- plan movement,
- review summaries,
- historical explanations,
- debugging,
- user trust.

### 20.4 Keep active alarm derivative

The active alarm should be created from the current resolved morning.

Do not let the active alarm become the only record of user intention.

### 20.5 Test scenarios, not just functions

The most important tests should be scenario-based:

- White Day shifts after plan.
- Arafah plan moves.
- Date-specific fast stays.
- Completed fast stays.
- Monday fast conflict appears.
- Shawwal window needs review.
- Default wake changes but custom wake remains.
- Exact wake behaves differently from Fajr-relative wake.
- Next alarm off does not cancel future fast.

---

## 21. Open Product Decisions

These decisions should be resolved or deliberately postponed.

1. **Exact current month browsing range**
   Is the supported range two months, current plus next few months, or current plus 12 months?

2. **Future edit policy**
   Can users edit any browsed future day, or only near-term days? If future edits are allowed, all must be anchored.

3. **Hijri adjustment scope**
   Is the adjustment global, month-specific, source-specific, or effective-from a date?

4. **Arafah authority**
   Does Arafah follow local Hijri date, Makkah/Hajj calendar, or user-selected authority?

5. **Review wording for fasting conflict days**
   What exact language should Subh use for days where voluntary fasting should not be promoted?

6. **Current-day lock boundary**
   After what point is the current morning considered historical rather than editable?

7. **Completion statuses**
   Should the system distinguish completed, skipped, missed, cancelled, unknown, and expired?

8. **Whether default fasting behavior exists**
   Does the user have default behavior for all fasting days, or only explicit fasting intentions?

9. **How much explanation appears on cards versus detail views**
   Cards should remain simple; detail views can explain anchors and movement.

10. **Whether one fast can satisfy multiple labels in the app**
   For example, Qada plus Monday or White Day tagging. This may require religious/content guidance and careful wording.

---

## 22. Recommended MVP Rules

The following rules are a strong MVP foundation.

1. The next immediate alarm is the user-facing product-active alarm; delivery may use only an explicit technical safety buffer supplied by the active window.
2. Next 7 Days is generated for display from current rules.
3. Month browsing is generated on demand or from temporary cache.
4. Browsing alone does not create permanent records.
5. Any user edit creates an anchored intention or override.
6. Observance-based intentions move with Hijri adjustments.
7. Gregorian-date intentions stay on their Gregorian date.
8. Weekday intentions stay with weekday patterns.
9. Hijri-month window intentions are revalidated after Hijri adjustment.
10. Completed history never moves.
11. Active alarm refreshes after relevant settings/calendar changes.
12. Calendar-driven plan movement is explained to the user.
13. Conflicts create review states rather than silent decisions.
14. Defaults are generated; user meaning is remembered.
15. The day resolver is the center of the product.

---


## 23. OpenSpec Requirements for Codex

These requirements can be copied into an OpenSpec capability such as `planning-horizon-intention-anchoring` or included as an amendment to `morning-resolution-contract`.

### ADDED Requirement: Planning horizons are separate concepts

The system SHALL distinguish knowledge range, display horizon, edit horizon, active scheduled horizon, and history horizon.

#### Scenario: Month browsing is visible but not scheduled

- GIVEN the user opens a future month
- WHEN the month is generated for display
- THEN the system SHALL NOT schedule platform alarms for every displayed day
- AND only events inside the canonical active scheduled window may be handed to the delivery layer

#### Scenario: Next 7 Days shows future days

- GIVEN Next 7 Days displays seven days
- WHEN the active scheduled window contains only the next immediate alarm
- THEN the other visible rows SHALL remain display/planning rows
- AND they SHALL NOT be treated as pending platform deliveries

### ADDED Requirement: Generated default days are not durable decisions

The system SHALL NOT persist ordinary generated default days merely because they were displayed.

#### Scenario: User browses without editing

- GIVEN the user opens Next 7 Days or a calendar month
- AND makes no changes
- WHEN the user leaves the surface
- THEN the app SHALL NOT create durable date-specific records for ordinary generated days

### ADDED Requirement: Future user decisions are anchored

The system SHALL persist user-created future intentions with an explicit anchor.

#### Scenario: User chooses Fast Arafah

- GIVEN a day is displayed as Arafah
- WHEN the user chooses “Fast Arafah”
- THEN the stored intention SHALL use an observance/Hijri anchor
- AND it SHALL NOT be stored only as a Gregorian date override

#### Scenario: User chooses Fast this date

- GIVEN a day is displayed with a Hijri observance tag
- WHEN the user chooses “Fast this date”
- THEN the stored intention SHALL use a Gregorian-date anchor

### ADDED Requirement: Hijri adjustment re-resolves future anchored intentions

The system SHALL re-resolve future intentions after a Hijri calendar adjustment according to their anchors.

#### Scenario: Observance plan moves

- GIVEN a future Ashura fast is anchored to Ashura
- WHEN the Hijri calendar adjustment moves 10 Muharram to another Gregorian date
- THEN the future Ashura fast SHALL move with Ashura
- AND the system SHALL create review/explanation state for the movement

#### Scenario: Date-specific plan stays

- GIVEN a future fast is anchored to March 12
- WHEN the Hijri calendar adjustment changes March 12's Hijri label
- THEN the fast SHALL remain on March 12

### ADDED Requirement: Completed history does not move

The system SHALL preserve completed records on the actual date/time of completion even when later calendar settings change.

#### Scenario: Completed Ashura-labeled fast after calendar change

- GIVEN the user completed a fast on March 12 when that date was displayed as Ashura
- WHEN the current Hijri calendar later places Ashura on March 13
- THEN the completion record SHALL remain on March 12
- AND the system MAY show the prior calendar context and current mapping difference

### ADDED Requirement: Immediate alarm override is narrowly scoped

The system SHALL distinguish turning off the next alarm from cancelling a future plan.

#### Scenario: User turns off next alarm on a planned fast

- GIVEN tomorrow has a planned fast and active wake event
- WHEN the user turns off only the next alarm
- THEN the fasting intention SHALL remain planned
- AND only the immediate active alarm delivery SHALL be suppressed or cancelled

### ADDED Requirement: Planning changes feed the canonical resolver

The system SHALL apply planning horizons and anchored intentions through the canonical morning resolver, not through surface-local state machines.

#### Scenario: Future observance enters Next 7 Days

- GIVEN a user planned an observance fast from month browsing
- WHEN that date later enters Next 7 Days
- THEN the canonical resolver SHALL apply the stored anchor and show the intended fast
- AND Next 7 Days SHALL NOT infer the fast from tag text alone

---
## 24. Appendix A — Example Flows

### 23.1 Flow: User plans an observance fast

1. User opens a month view.
2. March 12 displays as Ashura.
3. User taps “Fast Ashura.”
4. Subh stores an observance-anchored intention.
5. Wake behavior is attached to the Ashura intention.
6. Later, Hijri calendar changes.
7. Ashura moves to March 13.
8. Subh moves the future plan to March 13.
9. Subh shows: “Your Ashura fast moved because your Hijri calendar was adjusted.”

### 23.2 Flow: User plans a date-specific fast

1. User opens March 12.
2. User taps “Fast this date.”
3. Subh stores a Gregorian-date anchored intention.
4. Later, Hijri calendar changes.
5. March 12 no longer displays the same observance.
6. The fast remains on March 12.
7. Subh may show: “This fast stayed on March 12. The Hijri label for this date changed.”

### 23.3 Flow: User turns off next alarm

1. Tomorrow has an active alarm.
2. User turns off the alarm from active alarm control.
3. Subh stores an immediate-alarm override.
4. The next active alarm is disabled.
5. Other future plans remain unchanged.
6. When the next morning passes, the immediate override expires.

### 23.4 Flow: User changes default wake offset

1. User default is 30 minutes before Fajr.
2. User has a custom Arafah wake of 45 minutes before Fajr.
3. User changes default to 20 minutes before Fajr.
4. Ordinary days now use 20 minutes.
5. Arafah remains 45 minutes because it has a specific wake rule.

### 23.5 Flow: User completes a fast, then calendar changes

1. User completes a fast on March 12.
2. Subh records completion with the calendar context at that time.
3. Later, user adjusts Hijri calendar.
4. The observance now maps to March 13.
5. Completion remains on March 12.
6. Subh may offer to plan March 13 if relevant and still future/current.

---

## 25. Appendix B — Future Feature Extensions Supported by This Model

This model supports future features without requiring a new core architecture:

- current month plus 12 future months browsing,
- Hijri month selector,
- Gregorian month selector,
- monthly Fajrcast,
- Ramadan mode,
- Qada planning,
- six days of Shawwal planning,
- Arafah authority setting,
- recurring Monday/Thursday routines,
- White Days monthly routines,
- Tahajjud wake refinement,
- pre-Fajr completion logging,
- review center for moved plans,
- calendar confidence/provisional labels,
- historical reflection and progress views,
- and richer explanation of why a morning is scheduled the way it is.

The reason this model scales is that it separates:

- generated days from stored decisions,
- observance meaning from Gregorian date,
- planned mornings from active alarms,
- and future movement from completed history.

---

## 26. Final Principle

The durable center of Subh should be this:

> **Subh resolves meaningful mornings around Fajr. It generates what can be derived, remembers what the user meant, activates only what is operationally next, and preserves what already happened.**

Or in the shortest possible form:

> **Know broadly. Show relevantly. Remember meaning. Schedule narrowly. Preserve history.**
