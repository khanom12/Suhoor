# Subh CTA, Logging, Early-Awake, Wake-Check Display, and Historical Logging Specification v2

**File name:** `subh-cta-logging-and-wake-action-spec-v2.md`  
**Spec version:** v2.0  
**Status:** Active implementation-facing specification  
**Date:** June 1, 2026  
**Product:** Subh  
**Scope:** Home hero wake actions, context-card logging actions, early-awake confirmation, wake-session display updates, post-Suhoor Fajr behaviour, Fajr prayer logging, fast completion logging, historical logging foundations, Qada candidate foundations, analytics, and testing requirements.  
**Relationship to existing specs:** This spec is a focused feature specification that should be reconciled with the broader Subh Morning State Framework, wake-session spec, home hero spec, context-card spec, AlarmKit spec, logging/data model specs, testing harness spec, and relevant UX/copy/accessibility specs.

**June 1 reconciliation note:** This v2 file is the canonical CTA/logging source for the June 1 spec package. Where older May 31 wording conflicts with this file, v2 governs: active wake CTAs live in the hero; logging and early-awake actions live inside the context-card action area; explicit awake confirmation, not ordinary system dismissal, resolves wake success; early-awake confirmation differs for Suhoor versus Fajr; and post-Suhoor Fajr behaviour is slider-driven rather than a separate “Set Fajr” CTA.

---

# 1. Executive Summary

Subh needs a formal action framework for the consequential user actions that appear across morning planning, wake execution, Fajr prayer completion, fasting completion, late logging, and future historical/Qada workflows.

This specification defines:

1. where actions appear;
2. when actions appear;
3. what actions log;
4. what actions cancel or silence;
5. how the hero displays the next wake attempt;
6. how early-awake actions are confirmed;
7. how post-Suhoor Fajr behaviour works;
8. how compact check/X prompts work;
9. how Fajr and fast historical logs should eventually sync;
10. how Qada candidate data should be preserved without overbuilding the future Qada engine;
11. what tests and simulation states are required.

The core design decision is:

> **Active wake actions live in the hero. Logging and early-awake actions live in the context card.**

The second core design decision is:

> **Wake confirmation and worship completion are separate actions.**

The third core design decision is:

> **The app must never infer “No” from silence.**

A user ignoring a prompt is not the same as the user saying they did not pray or did not complete a fast.

---

# 2. Product Principles

## 2.1 Subh is a Fajr-centered morning system

Subh is a unified Fajr-centered morning system for Muslims. It is not a generic alarm app, not a Ramadan-only app, and not a collection of disconnected religious tools.

All related behaviours should layer onto the daily Fajr-centered morning model:

- Fajr wake planning;
- Suhoor wake planning;
- Ramadan intensification;
- optional fasting opportunities;
- Qada relevance;
- Tahajjud future refinements;
- Quiet and Pause delivery states;
- wake execution;
- completion logging;
- progress reflection.

## 2.2 User-facing simplicity over internal correctness exposure

The system may be internally complex, but the user should not see internal implementation language.

Avoid user-facing terms such as:

- scheduler;
- anchor;
- event line;
- state resolver;
- session object;
- wake-check generator;
- execution boundary;
- calculation boundary.

Use human language:

- **Today Morning**;
- **Tomorrow Morning**;
- **I’m Awake for Fajr**;
- **I’m Awake for Suhoor**;
- **I Prayed Fajr**;
- **I completed my fast today?**;
- **No alarm or wake checks will ring.**

## 2.3 Separate wake purpose from wake delivery

Wake purpose answers:

> Why is the user waking?

Allowed primary values:

- `suhoor`
- `fajr`

Wake delivery answers:

> Will Subh actually ring or notify the user?

Possible delivery states include:

- `alarm_on`
- `quiet`
- `pause`
- `permission_blocked`
- `alarmkit_unavailable`
- `notification_unavailable`

A morning can be “for Fajr” even when delivery is Quiet. Quiet is not a wake purpose.

## 2.4 Hero and context card have different jobs

The hero is for immediate wake-state control and next wake delivery.

The context card is for explanation and compact logging actions.

| Surface | Primary job | Examples |
|---|---|---|
| Hero | Immediate wake action and next wake/alarm time | **I’m Awake for Suhoor**, **I’m Awake for Fajr**, next wake check time |
| Context card | Morning explanation and logging actions | early-awake confirmation entry, **I Prayed Fajr**, check/X logs |

## 2.5 Active wake actions must be easy to use while groggy

During an active wake session, the user should see a large, prominent, low-cognitive-load action in the hero:

- **I’m Awake for Suhoor**
- **I’m Awake for Fajr**

These actions should be easy to tap, visually primary, and not buried in a lower card.

## 2.6 Logging actions should be compact

Late Fajr logging and fast completion logging should use compact prompt rows with check/X controls.

Example:

```text
I prayed Fajr earlier today?      ✓   ✕
I completed my fast today?        ✓   ✕
```

The prompt text carries the meaning. The check/X controls capture the response.

## 2.7 Silence is not no

Every binary prompt has three possible states:

| State | Meaning |
|---|---|
| ✓ | User explicitly said yes/completed |
| ✕ | User explicitly said no/not completed |
| Unrecorded | User has not answered |

The app must not infer ✕ from silence.

---

# 3. Scope

## 3.1 In scope for this specification

This spec covers:

- hero active wake CTAs;
- context-card action area;
- early-awake CTAs;
- confirmation popups for early-awake actions;
- sequential Fajr wake/prayer flow;
- post-awake cooldown;
- compact check/X logging prompts;
- fast completion logging after Maghrib;
- Ramadan fast prompt exception;
- historical logging foundations;
- Qada candidate foundations;
- hero wake time updates after wake attempts;
- Suhoor-to-Fajr transition;
- Fajr adhan/default event after Suhoor;
- slider conversion to Fajr wake session;
- data model fields;
- analytics events;
- accessibility;
- testing and simulation scenarios;
- OpenSpec/Codex implementation guidance.

## 3.2 Out of scope for this implementation pass unless explicitly requested

The following should be preserved as future design/implementation areas unless an existing implementation already supports them and only needs small alignment:

- full Qada engine UI;
- full made-up Qada Fajr workflow;
- full made-up Ramadan/Qada fast workflow;
- exemption/reason handling for Ramadan non-completion;
- full historical logging UI if no existing navigation or card surface exists;
- complete Pause and indefinite Pause redesign;
- full high-latitude prayer-time policy engine;
- full religious jurisprudence decision logic.

However, the data model should not block these future systems. It should preserve explicit ✕ responses and distinguish them from silence.

---

# 4. Definitions

## 4.1 Morning

A **morning** is the focused religious wake period associated with a local date and Fajr cycle.

A morning may include:

- Suhoor window;
- Fajr window;
- wake session;
- Fajr-start event;
- Fajr prayer logging;
- fast completion logging;
- Quiet/Pause delivery state;
- prior unresolved logs.

## 4.2 Focused morning

The focused morning is the morning currently being displayed and controlled by the hero.

Before midnight, it is usually shown as:

> **Tomorrow Morning**

After midnight, the same focused morning becomes:

> **Today Morning**

After Fajr ends, the hero rolls forward to the next upcoming morning.

## 4.3 Suhoor window

The Suhoor window begins at the start of the last third of the night, calculated for the user’s location/date.

The Suhoor window ends when Fajr begins.

## 4.4 Fajr window

The Fajr window begins when Fajr begins and ends at the prayer-time engine’s Fajr-end/sunrise boundary.

## 4.5 Wake session

A wake session is a scheduled sequence of wake attempts.

A wake session may include:

1. initial alarm;
2. follow-up wake checks at 5-minute intervals;
3. completion, cancellation, expiry, or missed/unresolved result.

Wake sessions can be for:

- Suhoor;
- Fajr.

## 4.6 Wake attempt

A wake attempt is one scheduled delivery within a wake session.

Types:

- `initial_alarm`
- `wake_check`

## 4.7 Fajr-start event

A Fajr-start event is a single Fajr-beginning adhan/event. It is not a full wake session and does not generate follow-up wake checks by default.

## 4.8 Active wake CTA

An active wake CTA appears in the hero during a live/active wake window.

Examples:

- **I’m Awake for Suhoor**
- **I’m Awake for Fajr**

## 4.9 Early-awake CTA

An early-awake CTA appears before the active window begins when the user is already awake and wants to silence the future wake session.

Examples:

- **I’m Already Awake for Suhoor**
- **I’m Already Awake for Fajr**

## 4.10 Prayer logging CTA

A prayer logging CTA records whether Fajr was prayed.

Examples:

- **I Prayed Fajr** during the Fajr window, after wake is marked;
- **I prayed Fajr earlier today?** ✓ ✕ after Fajr has ended;
- **I prayed Fajr yesterday morning?** ✓ ✕ after midnight.

## 4.11 Fast completion CTA

A fast completion CTA records whether a fast was completed.

Examples:

- **I completed my fast today?** ✓ ✕ after Maghrib;
- **I completed my fast yesterday?** ✓ ✕ after midnight.

---

# 5. Action Surface Architecture

## 5.1 Hero surface

The hero owns active wake control.

Hero responsibilities:

- show location;
- show Today/Tomorrow Morning label;
- show current or next wake attempt time;
- show Quiet/Pause when delivery is suppressed;
- show slider where valid;
- show Suhoor/Fajr selector during planning states;
- show **I’m Awake for Suhoor** during active Suhoor wake states;
- show **I’m Awake for Fajr** during active Fajr wake states.

The hero must not become a general logging surface.

The hero must not show:

- late Fajr check/X;
- fast completion check/X;
- historical logging rows;
- Qada counters;
- general analytics/progress prompts.

## 5.2 Context-card action area

The context card owns explanation and non-hero actions.

Context-card responsibilities:

- explain the current morning in human language;
- show early-awake action entry points;
- show **I Prayed Fajr** after the user is marked awake during the Fajr window;
- show late Fajr compact check/X prompt;
- show fast completion compact check/X prompt;
- show one highest-priority context action by default when collapsed;
- allow expansion when multiple context actions are pending.

## 5.3 Historical logging surfaces

Historical logging lives outside the home hero/context card flow.

Future surfaces:

- Fajr Logging card/screen;
- Fasting Logging card/screen.

Each historical row should support:

- unrecorded;
- ✓ completed;
- ✕ not completed.

---

# 6. CTA Registry

## 6.1 CTA summary table

| CTA | Surface | Time availability | Primary consequence |
|---|---|---|---|
| **I’m Awake for Suhoor** | Hero | Active Suhoor window | Cancels remaining Suhoor wake checks; transitions toward Fajr |
| **I’m Awake for Fajr** | Hero | Fajr window | Cancels remaining Fajr wake checks; unlocks Fajr prayer CTA after cooldown |
| **I’m Already Awake for Suhoor** | Context card | Midnight to Suhoor window start, MVP | Opens confirmation; if confirmed, silences Suhoor wake session and keeps Fajr adhan/event |
| **I’m Already Awake for Fajr** | Context card | Midnight to Fajr begin, MVP | Opens confirmation; if confirmed, silences Fajr adhan/wake session/checks |
| **I Prayed Fajr** | Context card | Fajr window after wake is marked | Logs Fajr prayer completion |
| **I prayed Fajr earlier today?** ✓ ✕ | Context card | After Fajr ends, same calendar day | Logs prayed/not prayed/unrecorded state |
| **I prayed Fajr yesterday morning?** ✓ ✕ | Context card | After midnight, until next wake window expiry | Logs prayed/not prayed/unrecorded state |
| **I completed my fast today?** ✓ ✕ | Context card | After Maghrib, same calendar day | Logs fast completed/not completed/unrecorded state |
| **I completed my fast yesterday?** ✓ ✕ | Context card | After midnight, until next wake window expiry | Logs fast completed/not completed/unrecorded state |

---

# 7. Active Hero Wake CTAs

## 7.1 I’m Awake for Suhoor

### 7.1.1 User-facing copy

```text
I’m Awake for Suhoor
```

### 7.1.2 Placement

Hero only.

During the active Suhoor wake state, this CTA may replace the normal Suhoor/Fajr selector row or become the primary hero action.

### 7.1.3 Availability

Show when all conditions are true:

| Condition | Rule |
|---|---|
| Focused morning | Today Morning |
| Wake purpose | Suhoor |
| Current time | Within Suhoor window |
| Suhoor window start | Last third of the night |
| Suhoor window end | Fajr begins |
| Suhoor wake status | Not resolved as awake/awake_early |
| Delivery state | Alarm on, active, or wake session still relevant |

### 7.1.4 Tap behaviour

When tapped:

1. log Suhoor wake success;
2. set `suhoorWakeStatus = awake`;
3. set `awakeForSuhoorAt = now`;
4. set `suhoorWakeSource = hero_cta`;
5. cancel all remaining Suhoor wake attempts;
6. set cancelled attempt results to `cancelled_by_awake_confirmation` or equivalent;
7. record `cancelledSuhoorChecksCount`;
8. transition hero toward Fajr for the same morning;
9. display Fajr beginning as the next default Fajr adhan/event time;
10. expose Fajr slider if Fajr time remains configurable;
11. keep Fajr relevant because the user still needs Fajr.

### 7.1.5 Must not do

This action must not:

- log Fajr wake success;
- log Fajr prayer completion;
- log fast completion;
- create a Qada item;
- create a full Fajr wake-check session by default.

### 7.1.6 Post-action hero behaviour

After **I’m Awake for Suhoor**:

- hero switches to same-morning Fajr focus;
- hero wake/alarm time becomes the Fajr-beginning default adhan/event time;
- Fajr adhan/event is still scheduled by default;
- Fajr wake checks are not scheduled by default;
- if the user adjusts the Fajr slider and commits a later valid time, Subh converts the Fajr delivery into a Fajr wake session with wake checks.

---

## 7.2 I’m Awake for Fajr

### 7.2.1 User-facing copy

```text
I’m Awake for Fajr
```

### 7.2.2 Placement

Hero only.

### 7.2.3 Availability

Show when all conditions are true:

| Condition | Rule |
|---|---|
| Focused morning | Today Morning |
| Current time | Within Fajr window |
| Fajr awake status | Not resolved as awake/awake_early |
| Wake purpose/state | Fajr mode or transitioned from Suhoor into same-morning Fajr |
| Wake session | May have active checks, single Fajr event, or no checks depending on configuration |

### 7.2.4 Tap behaviour

When tapped:

1. log Fajr wake success;
2. set `fajrWakeStatus = awake`;
3. set `awakeForFajrAt = now`;
4. set `fajrWakeSource = hero_cta`;
5. cancel remaining Fajr wake checks, if any;
6. record `cancelledFajrChecksCount`;
7. prevent **I’m Awake for Fajr** from showing again for that morning;
8. start post-awake cooldown;
9. after cooldown, allow **I Prayed Fajr** in the context-card action area.

### 7.2.5 Must not do

This action must not:

- log Fajr prayer completion;
- log fast completion;
- create Qada records;
- answer late prompts.

---

# 8. Sequential Fajr Wake and Prayer Flow

## 8.1 No simultaneous Fajr wake/prayer CTAs

Subh must never show these simultaneously:

- **I’m Awake for Fajr**
- **I Prayed Fajr**

Correct sequence:

1. Fajr window begins.
2. Hero shows **I’m Awake for Fajr**.
3. User taps **I’m Awake for Fajr**.
4. Remaining wake checks stop.
5. App shows a brief acknowledgement.
6. Post-awake cooldown completes.
7. Context card shows **I Prayed Fajr**.
8. User taps **I Prayed Fajr** after praying.

## 8.2 Post-awake cooldown

### 8.2.1 Requirement

After **I’m Awake for Fajr**, Subh must enforce a short cooldown before showing **I Prayed Fajr**.

### 8.2.2 Recommended starting duration

```text
1.5 seconds
```

This can be adjusted after testing.

### 8.2.3 Purpose

The cooldown prevents accidental double-tap where the user taps **I’m Awake for Fajr** and immediately taps **I Prayed Fajr** because the UI changed under their finger.

### 8.2.4 Visual acknowledgement

During cooldown, show a brief acknowledgement such as:

```text
Awake marked
```

or:

```text
Wake checks stopped
```

The acknowledgement should be calm, brief, and non-disruptive.

## 8.3 In-window I Prayed Fajr

### 8.3.1 Copy

```text
I Prayed Fajr
```

### 8.3.2 Placement

Context-card action area only.

### 8.3.3 Availability

Show when all conditions are true:

| Condition | Rule |
|---|---|
| Current time | Within Fajr window |
| Fajr awake status | `awake` or `awake_early` |
| Fajr prayer status | Unrecorded |
| Cooldown | Complete, if wake was just marked |

### 8.3.4 Control type

During the Fajr window, **I Prayed Fajr** is a single positive button/action.

Do not show check/X during the live Fajr window.

Reason: the prayer window is still open and the user may still pray.

### 8.3.5 Tap behaviour

When tapped:

1. set `fajrPrayerStatus = prayed`;
2. set `prayedFajrAt = now`, or prompt for time only if such UI already exists;
3. set `fajrPrayerLoggedAt = now`;
4. set `fajrPrayerLogSource = in_window_cta`;
5. set `fajrPrayerLogTiming = in_window`;
6. remove **I Prayed Fajr** from the context-card action area;
7. update historical Fajr log row if present;
8. clear any pending late Fajr prompt for the same morning.

---

# 9. Early-Awake Actions

## 9.1 Purpose

Early-awake actions are for users who are already awake before their active wake window or scheduled wake session begins.

Examples:

- user woke naturally;
- user never slept;
- user woke before Suhoor window;
- user woke before Fajr;
- user wants to silence upcoming alarms without waiting for the active hero CTA.

## 9.2 Placement

Early-awake actions live in the context-card action area, not the hero.

Reason:

- the hero active wake CTA is reserved for the actual active wake window;
- early-awake actions are consequential but not yet active-session actions;
- they may share space with previous Fajr/fast logging prompts.

## 9.3 Copy

Use:

```text
I’m Already Awake for Suhoor
I’m Already Awake for Fajr
```

Avoid awkward variants such as:

- “I have woken up earlier for Suhoor”;
- “I am awake earlier for Fajr.”

## 9.4 Availability

### 9.4.1 MVP rule

Early-awake actions become available from midnight for the focused Today Morning.

| Wake purpose | Availability |
|---|---|
| Suhoor | Midnight until Suhoor window begins |
| Fajr | Midnight until Fajr begins |

### 9.4.2 Future robust rule

In a future pass, availability should be derived from whether a future wake session exists and is not yet active, rather than hard midnight.

This matters for high-latitude or unusual-night cases where windows may start before midnight.

## 9.5 Early-awake confirmation requirement

Early-awake actions must not immediately silence alarms/checks on first tap.

Tapping an early-awake action must open a confirmation popup/sheet/modal because the consequence is substantial:

- future alarms may be silenced;
- wake checks may be cancelled;
- Fajr adhan behaviour differs depending on Suhoor versus Fajr mode.

## 9.6 I’m Already Awake for Suhoor

### 9.6.1 User-facing copy

```text
I’m Already Awake for Suhoor
```

### 9.6.2 Placement

Context-card action area.

### 9.6.3 Availability

Show when:

| Condition | Rule |
|---|---|
| Current time | From midnight until Suhoor window begins, MVP |
| Focused morning | Today Morning |
| Wake purpose | Suhoor |
| Suhoor wake status | Unresolved |
| Suhoor wake session | Scheduled or expected |
| Active Suhoor window | Not yet active |

### 9.6.4 Confirmation copy

Recommended confirmation:

**You’re already awake for Suhoor?**  
This will silence your upcoming Suhoor alarms and wake checks. The Fajr adhan will still sound when Fajr begins.

Buttons:

- **Keep Suhoor Alarm**
- **Yes, I’m Awake**

Optional alternate copy if the design needs shorter text:

**Mark awake for Suhoor?**  
Your Suhoor wake checks will be silenced. Fajr adhan will still sound when Fajr begins.

Buttons:

- **Cancel**
- **Mark Awake**

### 9.6.5 Confirm behaviour

If user confirms:

1. set `suhoorWakeStatus = awake_early`;
2. set `awakeForSuhoorAt = now`;
3. set `suhoorWakeSource = early_context_cta`;
4. cancel/silence all upcoming Suhoor wake attempts/checks;
5. set cancelled Suhoor attempt reason to `early_awake_confirmed`;
6. prevent **I’m Awake for Suhoor** from appearing later for that same morning;
7. transition hero toward same-morning Fajr;
8. hero displayed alarm time becomes Fajr beginning by default;
9. preserve the Fajr-beginning adhan/event;
10. expose Fajr slider where valid;
11. do not log Fajr wake;
12. do not log Fajr prayer;
13. do not log fast completion.

### 9.6.6 Cancel behaviour

If user cancels:

- leave Suhoor wake session unchanged;
- leave upcoming Suhoor wake attempts scheduled;
- keep context-card action available if still within availability window;
- record analytics event `early_awake_suhoor_confirmation_cancelled` if analytics layer exists.

### 9.6.7 Fajr adhan remains after early Suhoor

If the user confirms they are already awake for Suhoor, the Suhoor wake session is silenced, but the Fajr adhan/event remains scheduled by default.

This is intentional because the user still needs to be aware when Fajr begins.

### 9.6.8 Fajr slider after early Suhoor

After early Suhoor is confirmed:

- hero should show Fajr as the next relevant same-morning focus;
- default Fajr time is Fajr beginning;
- if the user does nothing, only the Fajr-beginning adhan/event fires;
- if the user commits a later Fajr slider value, Subh activates a Fajr wake session with wake checks according to normal Fajr wake rules.

Unless a future explicit setting supports dual delivery, moving the Fajr slider should replace the Fajr-beginning delivery target as the wake delivery target. Do not silently fire both a Fajr-beginning event and a later wake session by default.

## 9.7 I’m Already Awake for Fajr

### 9.7.1 User-facing copy

```text
I’m Already Awake for Fajr
```

### 9.7.2 Placement

Context-card action area.

### 9.7.3 Availability

Show when:

| Condition | Rule |
|---|---|
| Current time | From midnight until Fajr begins, MVP |
| Focused morning | Today Morning |
| Wake purpose | Fajr |
| Fajr wake status | Unresolved |
| Fajr wake session/event | Scheduled or expected |
| Active Fajr window | Not yet active |

### 9.7.4 Confirmation copy

Recommended confirmation:

**You’re already awake for Fajr?**  
This will silence your Fajr adhan, alarm, and wake checks for Today Morning.

Buttons:

- **Keep Fajr Alarm**
- **Yes, I’m Awake**

Optional alternate copy:

**Mark awake for Fajr?**  
Your Fajr adhan, alarm, and wake checks will be silenced for Today Morning.

Buttons:

- **Cancel**
- **Mark Awake**

### 9.7.5 Confirm behaviour

If user confirms:

1. set `fajrWakeStatus = awake_early`;
2. set `awakeForFajrAt = now`;
3. set `fajrWakeSource = early_context_cta`;
4. cancel/silence upcoming Fajr adhan/alarm/checks for that morning;
5. set cancelled Fajr attempt reason to `early_awake_confirmed`;
6. prevent **I’m Awake for Fajr** from appearing later for that same morning;
7. do not show **I Prayed Fajr** until Fajr begins;
8. do not log Fajr prayer completion;
9. do not log fast completion.

### 9.7.6 Cancel behaviour

If user cancels:

- leave Fajr adhan/alarm/wake session unchanged;
- keep context-card action available if still within availability window;
- record analytics event `early_awake_fajr_confirmation_cancelled` if analytics layer exists.

### 9.7.7 When Fajr begins after early Fajr confirmation

When Fajr begins after the user has confirmed **I’m Already Awake for Fajr**:

- do not show **I’m Awake for Fajr** in the hero;
- do not run Fajr wake checks;
- context card may show **I Prayed Fajr**;
- if the early-awake confirmation occurred within 2 seconds of Fajr beginning, apply the same cooldown before showing **I Prayed Fajr**.

---

# 10. Context-Card Action Area

## 10.1 Layout model

The context card should be one combined surface:

1. explanatory context text;
2. optional action area below the text.

There should not be a separate standalone CTA card for this feature set.

## 10.2 Action area collapsed state

When multiple context actions exist, show one highest-priority action by default and provide an expansion affordance.

Example collapsed state:

```text
Today Morning is for Fajr.
Your alarm is set for 5:19 AM.

I’m Already Awake for Fajr        [button]
Show 2 more check-ins ˅
```

## 10.3 Action area expanded state

Example expanded state:

```text
Today Morning is for Fajr.
Your alarm is set for 5:19 AM.

I’m Already Awake for Fajr        [button]
I prayed Fajr yesterday morning?  ✓   ✕
I completed my fast yesterday?    ✓   ✕
Show fewer ˄
```

## 10.4 Context action priority

When collapsed, use this priority order:

| Priority | Action type | Reason |
|---|---|---|
| 1 | Early-awake action for current morning | Silences future wake attempts; time-sensitive |
| 2 | In-window **I Prayed Fajr** after wake confirmed | Current worship completion |
| 3 | Late Fajr logging | Important but no longer live |
| 4 | Fast completion logging | Important after Maghrib; can coexist with late logs |
| 5 | Other unresolved check-ins | Useful but less immediate |

Hero active wake CTAs are not included in this priority table because they live in the hero.

## 10.5 Active hero state and context actions

When an active hero wake CTA is visible, it should remain visually dominant.

The context-card action area may still contain previous unresolved logs, but it should avoid competing visually with the active wake CTA. If the card becomes cluttered, show previous unresolved logs behind the “Show more check-ins” affordance.

---

# 11. Compact Check/X Prompts

## 11.1 Prompt pattern

Use compact prompt rows rather than large paired sentence buttons.

Preferred:

```text
I prayed Fajr earlier today?      ✓   ✕
I completed my fast today?        ✓   ✕
```

Potential accessible/clear variant:

```text
I prayed Fajr earlier today?      ✓ Yes   ✕ No
I completed my fast today?        ✓ Yes   ✕ No
```

## 11.2 Three-state logic

Each row supports:

| State | Meaning |
|---|---|
| `unrecorded` | No answer yet |
| `yes` | User tapped ✓ |
| `no` | User tapped ✕ |

## 11.3 Undo

Tapping ✓ or ✕ should preferably show a short undo snackbar/toast if the app already has this pattern.

Example:

```text
Fajr log updated. Undo
```

or:

```text
Fast log updated. Undo
```

A confirmation is not required for ✕ in the MVP, but undo is recommended.

## 11.4 Accessibility labels

If visible controls use only icons, accessibility labels are mandatory.

For Fajr:

| Visible control | Accessibility label |
|---|---|
| ✓ | Yes, I prayed Fajr |
| ✕ | No, I did not pray Fajr |

For fasting:

| Visible control | Accessibility label |
|---|---|
| ✓ | Yes, I completed my fast |
| ✕ | No, I did not complete my fast |

## 11.5 Hit target

Each check/X control must meet the platform’s minimum touch target guidance.

The user should not need precision tapping in an early morning context.

---

# 12. Late Fajr Logging

## 12.1 Same-day prompt

After Fajr ends, if Fajr prayer is unresolved, show:

```text
I prayed Fajr earlier today?      ✓   ✕
```

## 12.2 Yesterday prompt

After midnight, if the previous morning’s Fajr prayer remains unresolved and has not expired from the main prompt flow, show:

```text
I prayed Fajr yesterday morning?  ✓   ✕
```

## 12.3 Prompt placement

Late Fajr logging appears in the context-card action area under the current context text.

It must not appear in the hero.

## 12.4 Yes behaviour

If user taps ✓:

1. set `fajrPrayerStatus = prayed`;
2. set `fajrPrayerLogTiming = same_day_late` or `yesterday_late`;
3. set `fajrPrayerLogSource = late_prompt`;
4. set `fajrPrayerLoggedAt = now`;
5. update Fajr historical row;
6. clear any Qada Fajr candidate for that date if one exists and this correction is allowed;
7. remove the prompt from context card.

## 12.5 No behaviour

If user taps ✕:

1. set `fajrPrayerStatus = not_prayed`;
2. set `fajrPrayerLogTiming = same_day_late` or `yesterday_late`;
3. set `fajrPrayerLogSource = late_prompt`;
4. set `fajrPrayerLoggedAt = now`;
5. create or mark `qadaFajrCandidate = true` or `review_needed`, depending on current data model maturity;
6. update Fajr historical row;
7. remove the prompt from context card.

## 12.6 No response

If the user does not answer:

- status remains `unrecorded` or `unresolved` while prompt is active;
- do not create Qada;
- do not count as missed.

## 12.7 Expiry

The late Fajr prompt expires when the next relevant wake window begins.

| Next morning purpose | Expiry time |
|---|---|
| Suhoor | Next Suhoor window begins |
| Fajr | Next Fajr begins |

When expired without response:

- set prompt status to `expired_unresolved`;
- keep prayer record unrecorded/unresolved;
- do not create Qada;
- allow future historical logging to resolve the date.

---

# 13. Fast Completion Logging

## 13.1 Eligibility

Show fast completion prompt after Maghrib/sunset when either:

1. the user selected Suhoor for that morning; or
2. the date is in Ramadan.

Do not show the prompt merely because the date is an optional fasting opportunity unless the user selected Suhoor.

## 13.2 Eligibility table

| Situation | Show after Maghrib? |
|---|---|
| User selected Suhoor | Yes |
| User selected Suhoor but missed waking | Yes |
| User selected Suhoor and marked awake early | Yes |
| User selected Fajr only | No |
| Monday opportunity but Suhoor not selected | No |
| Thursday opportunity but Suhoor not selected | No |
| White Day opportunity but Suhoor not selected | No |
| Ramadan day | Yes |
| Ramadan day with Fajr mode selected | Yes |
| Ramadan day with Quiet | Yes, unless a later Ramadan-exemption design says otherwise |

## 13.3 Same-day prompt

After Maghrib, same calendar day:

```text
I completed my fast today?        ✓   ✕
```

## 13.4 Yesterday prompt

After midnight, before expiry:

```text
I completed my fast yesterday?    ✓   ✕
```

## 13.5 Yes behaviour

If user taps ✓:

1. set `fastCompletionStatus = completed`;
2. set `fastLoggedAt = now`;
3. set `fastLogSource = home_prompt`;
4. set `fastLogTiming = same_day_after_maghrib` or `yesterday_late`;
5. update historical fast row;
6. clear any Qada fast candidate for the same date if correction is allowed;
7. remove prompt from context card.

## 13.6 No behaviour for Ramadan

If user taps ✕ on a Ramadan date:

1. set `fastCompletionStatus = not_completed`;
2. set `fastType = ramadan`;
3. set `fastLoggedAt = now`;
4. set `fastLogSource = home_prompt`;
5. set `qadaFastCandidate = true` or `review_needed`, depending on current data model maturity;
6. update historical fast row;
7. remove prompt from context card.

The app should use careful wording such as “make-up item” or “to review” until the future Qada engine and religious rule handling are fully specified.

## 13.7 No behaviour for optional fasts

If user taps ✕ on a non-Ramadan optional fast:

1. set `fastCompletionStatus = not_completed`;
2. set `fastType = optional` or appropriate optional opportunity type;
3. do not create the same Qada fast requirement;
4. use the record for statistics and encouragement;
5. update historical fast row;
6. remove prompt from context card.

## 13.8 No response

If the user ignores the prompt:

- keep status unresolved/unrecorded while active;
- do not create Qada;
- do not count as completed or not completed.

## 13.9 Expiry

Fast completion prompt remains after Maghrib and after midnight until the next relevant wake window begins.

Important consecutive-fasting rule:

> The prompt must not disappear merely because tomorrow is planned for Suhoor. It disappears when the next Suhoor window actually begins.

If expired unanswered:

- set prompt status to `expired_unresolved`;
- keep fast record unrecorded/unresolved;
- do not create Qada;
- allow historical logging to resolve later.

---

# 14. Hero Wake Time and Next Wake Check Display

## 14.1 Core rule

The hero’s main wake/alarm time must reflect the next pending wake attempt, not only the initial alarm time.

During active wake sessions:

- before the initial alarm fires, show the initial alarm time;
- after the initial alarm fires/dismisses without the user tapping **I’m Awake**, update the hero to the next wake check time;
- after each wake check fires/dismisses without wake confirmation, update the hero to the following wake check time;
- after the final wake check fires, do not show stale previous times or “No time available.”

## 14.2 Data resolver

The hero should derive its visible wake time from:

```text
nextPendingWakeAttempt.scheduledTime
```

where `nextPendingWakeAttempt` is the earliest future attempt in the active/scheduled wake session with status:

- `scheduled`
- `pending`

If an attempt is actively firing/ringing, the hero may show either:

- the active attempt’s scheduled time;
- “Now”; or
- an active ringing state if such UI already exists.

After dismissal without wake confirmation, the resolver must recompute.

## 14.3 Suhoor wake-check display example

Given a Suhoor wake session with:

- initial alarm at 2:30 AM;
- checks every 5 minutes;
- Fajr begins at 3:00 AM;
- final check no later than 2:55 AM.

The hero main time should progress:

| Moment | Hero time/state |
|---|---|
| Before 2:30 | 2:30 AM |
| Initial alarm fired/dismissed, not awake | 2:35 AM |
| 2:35 check fired/dismissed, not awake | 2:40 AM |
| 2:40 check fired/dismissed, not awake | 2:45 AM |
| 2:45 check fired/dismissed, not awake | 2:50 AM |
| 2:50 check fired/dismissed, not awake | 2:55 AM |
| 2:55 final check fired/dismissed, not awake | Final-check-complete or window-ending state, not stale time |
| User taps **I’m Awake for Suhoor** at any point | Hero jumps to Fajr beginning/default Fajr adhan time |

## 14.4 Fajr wake-check display example

Given a Fajr wake session with:

- initial alarm at 5:00 AM;
- checks every 5 minutes;
- Fajr ends at 5:30 AM;
- final check no later than 5:25 AM.

The hero main time should progress:

| Moment | Hero time/state |
|---|---|
| Before 5:00 | 5:00 AM |
| Initial alarm fired/dismissed, not awake | 5:05 AM |
| 5:05 check fired/dismissed, not awake | 5:10 AM |
| 5:10 check fired/dismissed, not awake | 5:15 AM |
| 5:15 check fired/dismissed, not awake | 5:20 AM |
| 5:20 check fired/dismissed, not awake | 5:25 AM |
| User taps **I’m Awake for Fajr** | Wake checks stop; post-awake cooldown starts |

## 14.5 No stale times

The hero must not keep showing the first alarm time after later wake checks have become the next relevant wake attempts.

The hero must not show “No time available” when prayer-time and wake-session data are valid.

## 14.6 After active session is resolved

When a user taps **I’m Awake for Suhoor**:

- current Suhoor session is resolved;
- hero moves to Fajr same-morning state;
- hero time becomes Fajr beginning/default adhan time.

When a user taps **I’m Awake for Fajr**:

- current Fajr wake session is resolved;
- hero should no longer show pending Fajr wake-check times;
- context card shows **I Prayed Fajr** after cooldown.

When a user confirms **I’m Already Awake for Suhoor**:

- Suhoor session is silenced;
- hero moves to same-morning Fajr;
- hero time becomes Fajr beginning/default adhan time.

When a user confirms **I’m Already Awake for Fajr**:

- Fajr adhan/alarm/checks are silenced for that morning;
- hero should not present Fajr wake delivery as active;
- context card waits until Fajr begins to show **I Prayed Fajr**.

---

# 15. Wake Session Generation Rules

## 15.1 Relevant window end

| Session type | Relevant window end |
|---|---|
| Suhoor | Fajr begins |
| Fajr | Fajr ends |

## 15.2 Earliest new alarm

The earliest newly scheduled alarm is:

```text
current time + 1 minute
```

## 15.3 Latest wake attempt

The latest allowed wake attempt is:

```text
relevant window end - 5 minutes
```

## 15.4 Latest new session creation

The latest time to create a new wake session is:

```text
relevant window end - 6 minutes
```

Reason:

- earliest new alarm can be current time + 1 minute;
- latest valid alarm must be at least 5 minutes before the window ends.

## 15.5 Wake-check interval

Wake checks occur every:

```text
5 minutes
```

## 15.6 Attempt generation algorithm

Given:

- selected wake time;
- relevant window end;
- 5-minute interval;
- final allowed attempt at `end - 5 minutes`;

Generate:

1. initial alarm at selected wake time;
2. follow-up checks every 5 minutes;
3. stop once next check would be later than `end - 5 minutes`;
4. never schedule a check at exact window end.

## 15.7 Default full session

If selected wake time is 30 minutes before relevant window end:

| Attempt | Timing |
|---|---|
| Initial alarm | end - 30 min |
| Wake check 1 | end - 25 min |
| Wake check 2 | end - 20 min |
| Wake check 3 | end - 15 min |
| Wake check 4 | end - 10 min |
| Final wake check | end - 5 min |

Total:

```text
6 wake attempts
```

## 15.8 Compressed sessions

If selected wake time is later, attempts compress naturally.

Example: selected time at `end - 15 min`:

| Attempt | Timing |
|---|---|
| Initial alarm | end - 15 min |
| Wake check 1 | end - 10 min |
| Final wake check | end - 5 min |

Total:

```text
3 wake attempts
```

Example: selected time at `end - 5 min`:

| Attempt | Timing |
|---|---|
| Initial alarm | end - 5 min |

Total:

```text
1 wake attempt
```

---

# 16. Post-Suhoor Fajr Behaviour

## 16.1 Fajr remains necessary after Suhoor

After the user wakes for Suhoor, Fajr remains necessary and valid.

This is true whether the user:

- stays awake until Fajr;
- goes back to sleep;
- fasts;
- does not fast after all.

## 16.2 After active Suhoor wake confirmation

When user taps **I’m Awake for Suhoor** during the Suhoor window:

1. stop remaining Suhoor wake checks;
2. mark Suhoor wake as complete;
3. transition hero to same-morning Fajr;
4. show Fajr beginning as the default next event;
5. keep Fajr adhan/event scheduled by default;
6. allow Fajr slider adjustment.

## 16.3 After early Suhoor wake confirmation

When user confirms **I’m Already Awake for Suhoor** before the Suhoor window begins:

1. silence upcoming Suhoor wake attempts;
2. mark Suhoor as `awake_early`;
3. transition hero to same-morning Fajr;
4. show Fajr beginning as the default next event;
5. keep Fajr adhan/event scheduled by default;
6. allow Fajr slider adjustment.

## 16.4 No separate Set Fajr Wake Alarm CTA

Do not introduce a separate CTA such as:

- **Set Fajr Wake Alarm**
- **Wake Me for Fajr**

for the post-Suhoor default flow.

The Fajr transition should be built into the hero and slider flow.

## 16.5 Fajr slider after Suhoor

After Suhoor wake is resolved:

| User action | Behaviour |
|---|---|
| Does nothing | Fajr-beginning adhan/event remains default |
| Moves/commits Fajr slider to a later valid time | Convert/create Fajr wake session with wake checks |
| Confirms already awake for Fajr later, before Fajr begins | Silence Fajr adhan/alarm/checks for Today Morning |
| Taps **I’m Awake for Fajr** during Fajr window | Resolve Fajr wake and allow prayer logging after cooldown |

## 16.6 Slider conversion detail

When the user commits a Fajr slider adjustment after Suhoor:

- create or update a Fajr wake session;
- generate wake attempts using normal Fajr wake rules;
- use selected slider time as the Fajr wake target;
- unless future settings explicitly support dual delivery, do not silently fire both a Fajr-beginning adhan and later wake checks.

---

# 17. Historical Logging Foundations

## 17.1 Purpose

Historical logging allows the user to correct or complete prior records.

This is needed for:

- Fajr prayer tracking;
- fasting tracking;
- future Qada Fajr tracking;
- future Qada fast tracking;
- user trust and correction.

## 17.2 Fajr historical logging surface

Future/simple model:

- scrollable list;
- one row per date;
- up to one year back initially;
- each row supports unrecorded, ✓, ✕;
- home CTAs and historical rows sync to the same record.

Example:

```text
Mon, Jun 1      Fajr      —   ✓   ✕
Sun, May 31     Fajr      —   ✓   ✕
Sat, May 30     Fajr      —   ✓   ✕
```

## 17.3 Fasting historical logging surface

Future/simple model:

- scrollable list;
- one row per date;
- up to one year back initially;
- each row supports unrecorded, ✓, ✕;
- rows may include context such as Ramadan, Monday, Thursday, White Days;
- home CTAs and historical rows sync to the same record.

Example:

```text
Mon, Jun 1      Ramadan   —   ✓   ✕
Thu, Jun 4      Thursday  —   ✓   ✕
Sat, Jun 6      Fast      —   ✓   ✕
```

## 17.4 Availability recommendation

MVP recommendation:

- Fajr historical logging begins with dates whose home-screen live/late prompt has expired.
- Fasting historical logging begins with yesterday and earlier to avoid duplicating the home prompt.

Future more integrated design:

- allow today after Maghrib in the fasting log;
- allow same-day post-Fajr entries;
- keep all records unified so history and home never conflict.

## 17.5 Sync requirement

There must be one underlying record per date/action.

| User action | Required sync |
|---|---|
| Home late Fajr ✓ | Fajr history row shows ✓ |
| Home late Fajr ✕ | Fajr history row shows ✕ and Qada Fajr candidate |
| History Fajr row changed ✕ → ✓ | Qada Fajr candidate removed/resolved/reviewed |
| Home fast ✓ | Fast history row shows ✓ |
| Home fast ✕ on Ramadan | Fast history row shows ✕ and Qada fast candidate |
| History fast row changed ✓ → ✕ on Ramadan | Qada fast candidate created/reopened |
| History row changed to unrecorded | Related Qada state becomes review_needed rather than silently deleted |

---

# 18. Qada Candidate Foundations

## 18.1 Qada Fajr candidate

A Qada Fajr candidate may be created when the user explicitly records ✕ for Fajr.

Sources:

- late Fajr prompt ✕;
- historical Fajr row ✕.

Do not create Qada Fajr from:

- ignored prompt;
- expired unresolved prompt;
- missed wake checks alone;
- no app open.

## 18.2 Qada fast candidate

A Qada fast candidate may be created when the user explicitly records ✕ for a Ramadan fast.

Sources:

- Ramadan fast prompt ✕;
- historical Ramadan fast row ✕.

Do not create Qada fast from:

- ignored prompt;
- expired unresolved prompt;
- optional fast ✕;
- missed Suhoor wake alone.

## 18.3 Optional fast non-completion

Optional fast ✕ supports:

- statistics;
- intention versus completion tracking;
- encouragement;
- behavioural insights.

It does not create the same Qada fast requirement.

## 18.4 Careful wording

Until the full Qada engine and fiqh-sensitive states are specified, user-facing language should avoid overclaiming.

Prefer:

- “make-up item”;
- “to review”;
- “recorded for make-up tracking.”

Avoid:

- absolute rulings for all circumstances;
- guilt-heavy messaging;
- exposing complex religious/legal logic prematurely.

---

# 19. Data Model Requirements

## 19.1 Morning plan fields

| Field | Type/example | Purpose |
|---|---|---|
| `morningDate` | local date | Associated morning |
| `locationId` | string | Prayer-time location |
| `timeZone` | IANA timezone | Local time calculations |
| `fajrBegin` | timestamp | Fajr start |
| `fajrEnd` | timestamp | Fajr end/sunrise boundary |
| `suhoorWindowStart` | timestamp | Start of last third of night |
| `wakePurpose` | `suhoor` / `fajr` | Reason for waking |
| `wakeDelivery` | `alarm_on` / `quiet` / `pause` / etc. | Whether delivery occurs |
| `wakeTime` | timestamp | Selected wake time |
| `fastingContext` | enum/list | Ramadan, Monday, Thursday, White Days, etc. |
| `suhoorSelected` | bool | User selected Suhoor for the morning |
| `isRamadanDate` | bool | Ramadan prompt eligibility |

## 19.2 Wake session fields

| Field | Type/example | Purpose |
|---|---|---|
| `sessionId` | UUID | Session identity |
| `morningDate` | local date | Associated morning |
| `sessionType` | `suhoor` / `fajr` | Wake purpose |
| `status` | scheduled / active / completed / cancelled / expired | Session lifecycle |
| `relevantWindowEnd` | timestamp | Fajr begins for Suhoor; Fajr ends for Fajr |
| `initialWakeTime` | timestamp | First alarm |
| `nextPendingAttemptId` | UUID/null | Drives hero display |
| `createdAt` | timestamp | Session creation |
| `completedAt` | timestamp/null | Awake confirmation time |
| `cancelledAt` | timestamp/null | Cancellation time |
| `cancelledReason` | enum | quiet, pause, early_awake_confirmed, awake_cta, switch, invalidated |
| `checksRemaining` | int | Remaining follow-up checks |

## 19.3 Wake attempt fields

| Field | Type/example | Purpose |
|---|---|---|
| `attemptId` | UUID | Attempt identity |
| `sessionId` | UUID | Associated wake session |
| `attemptType` | initial_alarm / wake_check / fajr_start_event | Delivery type |
| `scheduledTime` | timestamp | Planned delivery |
| `firedAt` | timestamp/null | Actual fire time |
| `dismissedAt` | timestamp/null | Dismissal time |
| `result` | scheduled / fired / dismissed / cancelled / skipped / expired | Attempt status |
| `sequenceIndex` | int | Attempt order |
| `cancelledReason` | enum/null | Why cancelled |

## 19.4 Suhoor wake outcome fields

| Field | Type/example | Purpose |
|---|---|---|
| `morningDate` | local date | Morning being tracked |
| `suhoorWakeStatus` | pending / awake / awake_early / cancelled / expired_unresolved | Outcome |
| `awakeForSuhoorAt` | timestamp/null | User wake confirmation |
| `suhoorWakeSource` | hero_cta / early_context_cta / alarm / quiet_manual / history_edit | Source |
| `cancelledSuhoorChecksCount` | int | Cancelled remaining checks |
| `suhoorWakeResolvedAt` | timestamp/null | Resolution time |

## 19.5 Fajr wake outcome fields

| Field | Type/example | Purpose |
|---|---|---|
| `morningDate` | local date | Morning being tracked |
| `fajrWakeStatus` | pending / awake / awake_early / expired_unresolved | Outcome |
| `awakeForFajrAt` | timestamp/null | User wake confirmation |
| `fajrWakeSource` | hero_cta / early_context_cta / post_suhoor / quiet_manual / history_edit | Source |
| `cancelledFajrChecksCount` | int | Cancelled remaining checks |
| `fajrWakeResolvedAt` | timestamp/null | Resolution time |

## 19.6 Fajr prayer fields

| Field | Type/example | Purpose |
|---|---|---|
| `morningDate` | local date | Morning being tracked |
| `fajrPrayerStatus` | unrecorded / prayed / not_prayed / expired_unresolved | Prayer outcome |
| `prayedFajrAt` | timestamp/null | Prayer time if known/logged |
| `fajrPrayerLoggedAt` | timestamp/null | Actual logging time |
| `fajrPrayerLogSource` | in_window_cta / late_prompt / historical_log | Source |
| `fajrPrayerLogTiming` | in_window / same_day_late / yesterday_late / historical | Timing |
| `qadaFajrCandidate` | false / true / review_needed | Qada relevance |

## 19.7 Fast fields

| Field | Type/example | Purpose |
|---|---|---|
| `fastDate` | local date | Calendar date of fast |
| `fastPromptEligible` | bool | Whether prompt appears |
| `fastPromptEligibilityReason` | suhoor_selected / ramadan | Why eligible |
| `fastType` | ramadan / optional / unknown | Fast category |
| `fastCompletionStatus` | unrecorded / completed / not_completed / expired_unresolved | Outcome |
| `fastLoggedAt` | timestamp/null | Logging time |
| `fastLogSource` | home_prompt / historical_log | Source |
| `fastLogTiming` | same_day_after_maghrib / yesterday_late / historical | Timing |
| `qadaFastCandidate` | false / true / review_needed | Qada relevance |

## 19.8 Historical edit fields

| Field | Type/example | Purpose |
|---|---|---|
| `editedAt` | timestamp | Edit time |
| `editedFrom` | enum | Previous value |
| `editedTo` | enum | New value |
| `editSource` | historical_fajr_card / historical_fast_card | Where edited |
| `qadaImpact` | created / removed / resolved / review_needed / none | Qada effect |
| `syncStatus` | synced / pending / conflict | Sync state |

---

# 20. Analytics Events

## 20.1 Wake and early-awake events

| Event | Meaning |
|---|---|
| `awake_suhoor_cta_shown` | Hero showed active Suhoor wake CTA |
| `awake_suhoor_tapped` | User tapped active Suhoor awake CTA |
| `awake_fajr_cta_shown` | Hero showed active Fajr wake CTA |
| `awake_fajr_tapped` | User tapped active Fajr awake CTA |
| `early_awake_suhoor_shown` | Context showed early Suhoor action |
| `early_awake_suhoor_confirmation_shown` | Confirmation shown |
| `early_awake_suhoor_confirmed` | User confirmed early Suhoor awake |
| `early_awake_suhoor_confirmation_cancelled` | User cancelled early Suhoor confirmation |
| `early_awake_fajr_shown` | Context showed early Fajr action |
| `early_awake_fajr_confirmation_shown` | Confirmation shown |
| `early_awake_fajr_confirmed` | User confirmed early Fajr awake |
| `early_awake_fajr_confirmation_cancelled` | User cancelled early Fajr confirmation |

## 20.2 Wake-check display events

| Event | Meaning |
|---|---|
| `wake_attempt_fired` | Initial alarm/check fired |
| `wake_attempt_dismissed_without_awake` | Attempt dismissed but user did not mark awake |
| `hero_next_wake_time_updated` | Hero updated to next pending wake/check time |
| `wake_checks_cancelled_by_awake_cta` | Checks cancelled by active awake CTA |
| `wake_checks_cancelled_by_early_awake` | Checks cancelled by early-awake confirmation |

## 20.3 Fajr prayer events

| Event | Meaning |
|---|---|
| `post_awake_cooldown_started` | Cooldown began after Fajr wake confirmation |
| `fajr_prayed_cta_shown` | In-window prayer CTA shown |
| `fajr_prayed_cta_tapped` | In-window prayer logged |
| `late_fajr_prompt_shown` | Late check/X prompt shown |
| `late_fajr_answered_yes` | User tapped ✓ |
| `late_fajr_answered_no` | User tapped ✕ |
| `late_fajr_expired_unresolved` | Prompt expired unanswered |

## 20.4 Fast events

| Event | Meaning |
|---|---|
| `fast_prompt_shown` | Fast completion prompt shown |
| `fast_answered_yes` | User tapped ✓ |
| `fast_answered_no` | User tapped ✕ |
| `fast_expired_unresolved` | Prompt expired unanswered |

## 20.5 Historical and Qada events

| Event | Meaning |
|---|---|
| `historical_fajr_updated` | Fajr history changed |
| `historical_fast_updated` | Fast history changed |
| `qada_fajr_candidate_created` | Fajr ✕ created Qada relevance |
| `qada_fajr_candidate_resolved` | Candidate removed/resolved after correction |
| `qada_fast_candidate_created` | Ramadan fast ✕ created Qada relevance |
| `qada_fast_candidate_resolved` | Candidate removed/resolved after correction |

## 20.6 Analytics context payload

Where possible, include:

- `morningDate`;
- `fastDate` where relevant;
- `currentLocalTime`;
- `wakePurpose`;
- `wakeDelivery`;
- `isRamadanDate`;
- `suhoorSelected`;
- `sessionType`;
- `attemptSequenceIndex`;
- `minutesUntilFajrBegin`;
- `minutesUntilFajrEnd`;
- `actionSurface` (`hero`, `context_card`, `history`);
- `collapsedActionRank` if applicable.

Do not store noisy slider micro-movements. Store committed slider changes.

---

# 21. Accessibility Requirements

## 21.1 Button labels

All icon-only controls must have explicit accessibility labels.

## 21.2 Modal accessibility

Early-awake confirmation modals must:

- announce title;
- announce consequence text;
- focus the safest/default option first if platform conventions support it;
- support VoiceOver/TalkBack;
- close cleanly with cancel;
- not trap focus.

## 21.3 Dynamic hero time updates

When the hero wake time changes from one wake check to the next, screen readers should not be spammed repeatedly.

Recommended:

- update visual UI immediately;
- announce only meaningful state changes, such as “Next wake check at 2:35 AM,” if the app already announces alarm state changes;
- avoid excessive repeated announcements every second.

## 21.4 Hit targets

Active hero wake CTA and check/X buttons must meet platform minimum touch sizes.

Active hero wake CTA should be large enough for groggy use.

---

# 22. Copy Requirements

## 22.1 Active wake copy

Use:

- **I’m Awake for Suhoor**
- **I’m Awake for Fajr**

## 22.2 Early-awake copy

Use:

- **I’m Already Awake for Suhoor**
- **I’m Already Awake for Fajr**

## 22.3 Early-awake confirmation copy

### Suhoor

**You’re already awake for Suhoor?**  
This will silence your upcoming Suhoor alarms and wake checks. The Fajr adhan will still sound when Fajr begins.

Buttons:

- **Keep Suhoor Alarm**
- **Yes, I’m Awake**

### Fajr

**You’re already awake for Fajr?**  
This will silence your Fajr adhan, alarm, and wake checks for Today Morning.

Buttons:

- **Keep Fajr Alarm**
- **Yes, I’m Awake**

## 22.4 Prayer copy

During Fajr window after awake:

```text
I Prayed Fajr
```

Late same day:

```text
I prayed Fajr earlier today?
```

Late after midnight:

```text
I prayed Fajr yesterday morning?
```

## 22.5 Fast copy

Same day after Maghrib:

```text
I completed my fast today?
```

After midnight:

```text
I completed my fast yesterday?
```

## 22.6 Tone

Use calm, direct, non-shaming copy.

Avoid:

- “failed”;
- “neglected”;
- guilt-heavy messaging;
- overconfident Qada rulings before the Qada engine is specified.

---

# 23. State Scenarios

## 23.1 Early Suhoor confirmation before Suhoor window

Given:

- current time is after midnight;
- Today Morning wake purpose is Suhoor;
- Suhoor wake session is scheduled;
- Suhoor window has not begun.

When:

- user taps **I’m Already Awake for Suhoor**.

Then:

- confirmation appears;
- if cancelled, nothing changes;
- if confirmed, Suhoor alarms/checks are silenced;
- hero transitions to same-morning Fajr;
- Fajr adhan/event remains scheduled at Fajr beginning;
- Fajr slider becomes available if valid;
- later active **I’m Awake for Suhoor** does not appear.

## 23.2 Early Fajr confirmation before Fajr begins

Given:

- current time is after midnight;
- Today Morning wake purpose is Fajr;
- Fajr adhan/alarm/wake session is scheduled;
- Fajr has not begun.

When:

- user taps **I’m Already Awake for Fajr**.

Then:

- confirmation appears;
- if cancelled, nothing changes;
- if confirmed, Fajr adhan/alarm/checks are silenced for Today Morning;
- Fajr wake status is `awake_early`;
- later hero **I’m Awake for Fajr** does not appear;
- **I Prayed Fajr** appears only after Fajr begins.

## 23.3 Active Suhoor wake checks update hero time

Given:

- active Suhoor wake session;
- initial alarm and multiple checks scheduled.

When:

- each attempt fires and is dismissed without **I’m Awake for Suhoor**.

Then:

- hero wake time updates to the next pending wake check;
- no stale first alarm time remains;
- no “No time available” appears while valid attempts exist.

## 23.4 Active Fajr wake checks update hero time

Given:

- active Fajr wake session;
- initial alarm and multiple checks scheduled.

When:

- each attempt fires and is dismissed without **I’m Awake for Fajr**.

Then:

- hero wake time updates to the next pending wake check;
- after **I’m Awake for Fajr**, remaining checks cancel;
- after cooldown, context card shows **I Prayed Fajr**.

## 23.5 Post-Suhoor Fajr slider

Given:

- user tapped **I’m Awake for Suhoor** or confirmed **I’m Already Awake for Suhoor**.

Then:

- hero shows Fajr as next same-morning state;
- default time is Fajr beginning;
- if user does nothing, single Fajr adhan/event fires;
- if user commits slider adjustment, Fajr wake session with checks is created.

## 23.6 Consecutive Ramadan fasts

Given:

- Monday is Ramadan;
- user has unresolved Monday fast completion prompt;
- Tuesday Suhoor is planned.

Then:

- Monday fast prompt remains after Maghrib and after midnight;
- prompt says **I completed my fast yesterday?** after midnight;
- prompt expires only when Tuesday Suhoor window begins;
- prompt does not disappear merely because Tuesday Suhoor is planned.

---

# 24. Testing Requirements

## 24.1 Unit tests

Add/update tests for:

- wake-attempt generation;
- latest scheduling cutoff;
- next-pending-wake-attempt resolver;
- active hero wake CTA visibility;
- early-awake action visibility;
- early-awake confirmation outcomes;
- sequential Fajr CTA visibility;
- post-awake cooldown;
- compact check/X three-state logic;
- prompt expiry;
- fast prompt eligibility;
- Qada candidate creation only on explicit ✕;
- history/home sync if history exists.

## 24.2 UI tests

Add/update tests for:

- **I’m Awake for Suhoor** in hero;
- **I’m Awake for Fajr** in hero;
- **I’m Already Awake for Suhoor** in context card;
- **I’m Already Awake for Fajr** in context card;
- early-awake confirmation modal copy;
- no simultaneous **I’m Awake for Fajr** and **I Prayed Fajr**;
- check/X rows accessible labels;
- collapsed/expanded context actions;
- hero time updates after wake attempt dismissal.

## 24.3 Simulation harness tests

Add scenarios for:

| ID | Scenario |
|---|---|
| CTA-SIM-001 | Midnight Fajr mode, early-awake Fajr visible |
| CTA-SIM-002 | Early Fajr confirmation cancelled |
| CTA-SIM-003 | Early Fajr confirmation confirmed, Fajr adhan/checks silenced |
| CTA-SIM-004 | Midnight Suhoor mode, early-awake Suhoor visible |
| CTA-SIM-005 | Early Suhoor confirmation cancelled |
| CTA-SIM-006 | Early Suhoor confirmation confirmed, Suhoor silenced, Fajr adhan remains |
| CTA-SIM-007 | Active Suhoor wake session, next wake check time updates after each attempt |
| CTA-SIM-008 | Active Fajr wake session, next wake check time updates after each attempt |
| CTA-SIM-009 | Active Fajr awake tap triggers cooldown then **I Prayed Fajr** |
| CTA-SIM-010 | Late Fajr check/X same day |
| CTA-SIM-011 | Late Fajr check/X yesterday |
| CTA-SIM-012 | Fast completion after Maghrib on Suhoor-selected day |
| CTA-SIM-013 | Fast completion after Maghrib on Ramadan day without Suhoor selected |
| CTA-SIM-014 | Optional fasting opportunity without Suhoor selected does not show fast prompt |
| CTA-SIM-015 | Multiple context actions collapsed and expanded |
| CTA-SIM-016 | Previous Fajr unresolved + early Fajr awake action priority |
| CTA-SIM-017 | Previous fast unresolved + early Suhoor awake action priority |
| CTA-SIM-018 | Consecutive Ramadan fast prompt survives until next Suhoor window begins |
| CTA-SIM-019 | Fajr slider after Suhoor creates Fajr wake session with checks |
| CTA-SIM-020 | Valid prayer-time data never displays “No time available” |

## 24.4 Regression tests

Ensure this implementation does not break:

- regular Fajr planning;
- Suhoor/Fajr selector order;
- Quiet confirmation;
- Next Seven Mornings row display;
- wake-check generation;
- AlarmKit scheduling;
- Ramadan context display;
- late Fajr logging;
- testing harness existing scenarios.

---

# 25. Traceable Requirements

## 25.1 Hero active wake requirements

| ID | Requirement |
|---|---|
| CTA-HERO-001 | **I’m Awake for Suhoor** must appear in the hero during the active Suhoor window when Suhoor is selected and Suhoor wake status is unresolved. |
| CTA-HERO-002 | **I’m Awake for Fajr** must appear in the hero during the Fajr window when Fajr wake status is unresolved. |
| CTA-HERO-003 | Active wake CTAs must cancel remaining wake checks for their respective session. |
| CTA-HERO-004 | Active wake CTAs must not log Fajr prayer or fast completion. |
| CTA-HERO-005 | **I’m Awake for Fajr** and **I Prayed Fajr** must not appear simultaneously. |
| CTA-HERO-006 | After **I’m Awake for Fajr**, a short cooldown must occur before **I Prayed Fajr** appears. |
| CTA-HERO-007 | Hero wake time must update to the next pending wake attempt after each fired/dismissed attempt if the user has not marked awake. |
| CTA-HERO-008 | Hero must not show stale initial alarm time after the next wake check becomes the next relevant attempt. |
| CTA-HERO-009 | Hero must not show “No time available” when valid prayer-time/wake-session data exists. |

## 25.2 Context action requirements

| ID | Requirement |
|---|---|
| CTA-CONTEXT-001 | Logging and early-awake actions must live in the context-card action area. |
| CTA-CONTEXT-002 | The context-card action area must support compact check/X prompts. |
| CTA-CONTEXT-003 | The context-card action area must support collapsed and expanded states when multiple actions exist. |
| CTA-CONTEXT-004 | The collapsed state must show the highest-priority available context action. |
| CTA-CONTEXT-005 | Check/X prompts must support yes, no, and unrecorded states. |
| CTA-CONTEXT-006 | Silence/unanswered must not be interpreted as no. |

## 25.3 Early-awake requirements

| ID | Requirement |
|---|---|
| CTA-EARLY-001 | **I’m Already Awake for Fajr** must be available before Fajr begins when Fajr mode is selected and wake status is unresolved. |
| CTA-EARLY-002 | **I’m Already Awake for Suhoor** must be available before the Suhoor window begins when Suhoor mode is selected and wake status is unresolved. |
| CTA-EARLY-003 | Initial draft availability begins at midnight. |
| CTA-EARLY-004 | Early-awake actions must open confirmation before silencing/cancelling alarms/checks. |
| CTA-EARLY-005 | Early Suhoor confirmation must silence Suhoor wake alarms/checks but preserve the Fajr-beginning adhan/event by default. |
| CTA-EARLY-006 | Early Fajr confirmation must silence Fajr adhan/alarm/wake checks for Today Morning. |
| CTA-EARLY-007 | Early-awake confirmation must prevent the later active hero wake CTA from appearing for the same purpose. |
| CTA-EARLY-008 | Early-awake actions must not log Fajr prayer or fast completion. |
| CTA-EARLY-009 | Cancelling the early-awake confirmation must leave the wake session unchanged. |

## 25.4 Fajr prayer requirements

| ID | Requirement |
|---|---|
| CTA-FAJR-001 | **I Prayed Fajr** must appear only in the context card. |
| CTA-FAJR-002 | During the Fajr window, **I Prayed Fajr** must be a single positive action, not check/X. |
| CTA-FAJR-003 | During the Fajr window, **I Prayed Fajr** must appear only after Fajr wake has been marked awake/awake_early and cooldown has passed if applicable. |
| CTA-FAJR-004 | After Fajr ends, unresolved Fajr prayer must become a compact check/X prompt. |
| CTA-FAJR-005 | Fajr ✕ must create Qada Fajr candidate/relevance for the future Qada engine. |
| CTA-FAJR-006 | Expired unresolved Fajr must not automatically create Qada Fajr. |

## 25.5 Fast completion requirements

| ID | Requirement |
|---|---|
| CTA-FAST-001 | Fast completion prompt must appear after Maghrib when Suhoor was selected. |
| CTA-FAST-002 | Fast completion prompt must appear after Maghrib every day in Ramadan. |
| CTA-FAST-003 | Fast completion prompt must not appear for mere optional fasting opportunities unless Suhoor was selected. |
| CTA-FAST-004 | Fast completion prompt must use compact check/X controls. |
| CTA-FAST-005 | Ramadan ✕ must create Qada fast candidate/relevance. |
| CTA-FAST-006 | Optional fast ✕ must not create the same Qada fast requirement. |
| CTA-FAST-007 | Fast prompt must remain through same evening and after midnight until the next relevant wake window begins. |
| CTA-FAST-008 | Fast prompt must not disappear merely because tomorrow is planned for Suhoor. |

## 25.6 Post-Suhoor Fajr requirements

| ID | Requirement |
|---|---|
| CTA-PSF-001 | After **I’m Awake for Suhoor**, remaining Suhoor wake checks must be cancelled. |
| CTA-PSF-002 | After active or early Suhoor wake resolution, hero must transition to same-morning Fajr. |
| CTA-PSF-003 | Fajr adhan/event must remain scheduled by default after Suhoor wake resolution. |
| CTA-PSF-004 | Fajr wake checks must not be created automatically after Suhoor wake resolution. |
| CTA-PSF-005 | Fajr slider must allow the user to activate/adjust Fajr wake-session behaviour when valid. |
| CTA-PSF-006 | Committing the Fajr slider after Suhoor must create/update a Fajr wake session with normal wake checks. |
| CTA-PSF-007 | Do not introduce a separate **Set Fajr Wake Alarm** CTA for the default post-Suhoor flow. |

## 25.7 Historical/Qada requirements

| ID | Requirement |
|---|---|
| CTA-HIST-001 | Subh should eventually support a Fajr historical logging card/surface. |
| CTA-HIST-002 | Subh should eventually support a fasting historical logging card/surface. |
| CTA-HIST-003 | Historical rows must support unrecorded, ✓, and ✕ states. |
| CTA-HIST-004 | Home CTA logs and historical rows must sync to the same underlying record. |
| CTA-HIST-005 | Historical edits must update Qada relevance where applicable. |
| CTA-QADA-001 | Fajr ✕ should feed future Qada Fajr tracking. |
| CTA-QADA-002 | Ramadan fast ✕ should feed future Qada fast tracking. |
| CTA-QADA-003 | Optional fast ✕ supports stats/encouragement but not the same Qada fast requirement. |

---

# 26. Impacted Specs

The following existing specs are affected or likely affected.

## 26.1 Must update in this pass if present

| Spec area | Reason |
|---|---|
| Home hero spec | Active wake CTAs, next wake-check time display, post-Suhoor Fajr hero transition |
| Detailed morning view spec | Must mirror hero behaviour if detailed view reuses hero |
| Context card spec | Context action area, compact check/X rows, collapsed/expanded actions |
| Wake session spec | Next pending wake attempt display, wake-check cancellation, early-awake cancellation |
| AlarmKit/alarm delivery spec | Suhoor vs Fajr cancellation differences, Fajr adhan after Suhoor, Fajr slider conversion |
| Fajr/Suhoor mode spec | Post-Suhoor transition, early-awake availability, slider behaviour |
| Fajr logging/prayer logging spec | Sequential Fajr wake/prayer flow, late logging check/X, Qada candidate |
| Fasting/Ramadan logging spec | Fast prompt eligibility, Ramadan exception, optional fast behaviour |
| Data model spec | New fields for wake outcomes, fast outcomes, historical edits, Qada candidates |
| Analytics spec | New CTA, early-awake, wake-check display, Qada candidate events |
| Testing harness spec | Scenarios for early-awake confirmation, hero wake-check time updates, post-Suhoor Fajr |
| Accessibility spec | Check/X labels, modal focus/labels, active hero CTA touch targets |
| Localization/copy spec | Exact copy for CTAs, confirmations, prompts |

## 26.2 Should update in a follow-up pass or add placeholders

| Spec area | Reason |
|---|---|
| Historical logging spec | Future Fajr/Fasting list surfaces need dedicated UI design |
| Qada engine spec | Future separate engine; this spec only defines candidate feed |
| Pause/indefinite Pause spec | Broader suppression logic remains not fully designed |
| Ramadan exemption/reason spec | Needed before detailed Qada fast religious-state handling |
| High-latitude/time calculation spec | Early-awake midnight rule may need robust future replacement |
| Design system/component spec | If buttons, cards, modals, or check/X controls need reusable component definitions |

---

# 27. Open Decisions and Recommendations

## 27.1 Early-awake availability beyond midnight

Decision for MVP:

> Early-awake starts at midnight.

Future recommendation:

> Show early-awake whenever a future wake session exists and is not yet active.

Reason: this handles high-latitude cases better.

## 27.2 Check/X versus Yes/No

Decision for now:

> Use ✓/✕ visually, with accessibility labels.

Possible future improvement:

> Add small Yes/No text if testing shows ambiguity.

## 27.3 Confirming ✕ responses

Decision for now:

> No confirmation required for ✕.

Recommendation:

> Use undo snackbar/toast if available.

## 27.4 Slider after Suhoor and Fajr-beginning adhan

Decision for now:

> Default after Suhoor is Fajr-beginning adhan/event only. If the user commits a later Fajr slider time, create/update a Fajr wake session with checks and do not silently fire both default Fajr-beginning delivery and later wake delivery unless a future explicit dual-delivery setting exists.

## 27.5 Historical logging entry timing

Decision for MVP:

> Let home handle live/late prompts. Historical logging can start from records whose home prompt has expired, or yesterday-and-earlier for fasting.

Future recommendation:

> Unify records so today’s after-Maghrib or post-Fajr state can be reflected both at home and in history without conflict.

## 27.6 Qada wording

Decision for now:

> Preserve Qada candidate data but use careful “make-up/review” wording until a full Qada engine is specified.

---

# 28. Implementation Notes

## 28.1 Resolver-first implementation

Prefer a resolver that computes:

- hero state;
- hero next wake attempt time;
- active hero CTA;
- context text;
- context action rows;
- collapsed/expanded priority;
- prompt expiry;
- logging side effects.

Avoid hard-coding independent screen conditions in multiple components.

## 28.2 Suggested resolver output shape

Example conceptual output:

```ts
type MorningActionResolution = {
  hero: {
    label: 'Today Morning' | 'Tomorrow Morning'
    primaryTimeState: {
      kind: 'wakeTime' | 'quiet' | 'paused' | 'awakeMarked' | 'windowEnding' | 'none'
      time?: Date
      text?: string
      source?: 'initial_alarm' | 'wake_check' | 'fajr_start_event' | 'slider_target'
    }
    activeWakeAction?: {
      kind: 'awake_suhoor' | 'awake_fajr'
      label: string
    }
  }
  contextCard: {
    text: string
    actions: ContextAction[]
    collapsedPrimaryActionId?: string
    expandable: boolean
  }
}
```

## 28.3 Side effects

Keep UI resolution separate from side effects.

Tapping an action should call explicit handlers, such as:

- `confirmEarlyAwakeSuhoor()`;
- `confirmEarlyAwakeFajr()`;
- `markAwakeForSuhoor()`;
- `markAwakeForFajr()`;
- `logFajrPrayed()`;
- `answerLateFajrPrompt(answer)`;
- `answerFastPrompt(answer)`;
- `commitFajrSliderAfterSuhoor(time)`.

## 28.4 Migration

If current data lacks separate wake/prayer/fast outcomes:

- add fields conservatively;
- do not infer missed from missing records;
- treat absent prior records as `unrecorded`;
- do not backfill Qada candidates from old missing data.

---

# 29. Acceptance Criteria

The implementation is acceptable when:

1. Active wake CTAs appear in the hero, not the context card.
2. Early-awake CTAs appear in the context card and require confirmation.
3. Early Suhoor confirmation silences Suhoor wake session but preserves default Fajr adhan/event.
4. Early Fajr confirmation silences Fajr adhan/alarm/wake checks.
5. Hero shows the next pending wake check time after each dismissed attempt.
6. Hero never shows stale initial alarm time after a later check becomes next.
7. Hero never shows “No time available” when valid data exists.
8. **I’m Awake for Fajr** and **I Prayed Fajr** never appear at the same time.
9. **I Prayed Fajr** appears only after Fajr wake has been marked and cooldown has passed if applicable.
10. Late Fajr logging uses compact check/X.
11. Fast completion uses compact check/X.
12. Fast prompt appears after Maghrib on Suhoor-selected days and every Ramadan day.
13. Fast prompt does not appear for optional opportunities unless Suhoor was selected.
14. ✓, ✕, and unrecorded remain distinct.
15. Qada candidates are created only from explicit ✕ where applicable.
16. Prompt expiry does not create Qada.
17. Post-Suhoor Fajr slider can create/update Fajr wake session with wake checks.
18. Tests cover major state transitions and edge cases.
19. Existing unrelated features are not removed or drifted.
20. Updated specs validate under OpenSpec if the repo uses OpenSpec.

---

# 30. Codex Implementation Guardrails

When implementing this spec, Codex must:

- use existing project conventions;
- inspect existing specs and code before modifying;
- avoid renaming unrelated files/components;
- avoid removing existing features unless explicitly superseded;
- preserve Suhoor/Fajr terminology;
- avoid reintroducing old “pre-Fajr” language;
- keep Quiet/Pause separate from wake purpose;
- keep wake success separate from prayer completion;
- keep Fajr-start event separate from Fajr wake session;
- update tests and simulation harness;
- provide a detailed report;
- commit only after validation.
