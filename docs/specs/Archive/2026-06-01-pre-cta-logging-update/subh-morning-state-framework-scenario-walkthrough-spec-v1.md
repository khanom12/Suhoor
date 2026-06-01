# Subh Morning State Framework Scenario Walkthrough Specification v1 — May 31 Source Document

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-state-framework-scenario-walkthrough-spec-v1.md` |
| Version | 1 |
| Spec status | Active May 31 source document for hero, context card, Next 7 Mornings, wake sessions, late logging, and simulation updates |
| Date | 2026-05-31 |
| Related specs | Index, Alignment, Hero, Detail, Context, Next 7, Quiet/Pause, Wake Sessions, Alarm Delivery, Suhoor Boundary, Mutation Contract, Testing Harness |
| Owning domain / surface | Cross-surface daily morning-state framework |

## 1. Purpose

This specification captures the May 31, 2026 Subh morning-state walkthrough and translates it into implementation-facing product requirements.

The source conversation began from a live review of the app in Toronto on Sunday, May 31, 2026 after approximately 10:30 AM, and later around 12:19 PM. The app was showing the next morning’s default Fajr wake configuration: location detected, next morning visible, Fajr selected, and the wake time shown as a default offset before Fajr ends. The discussion then mentally simulated the next 24+ hours: current daytime, evening, midnight, Suhoor window start, within Suhoor, Fajr begins, within Fajr, Fajr end, and after Fajr when the hero rolls to the next morning.

This file is a source document for the May 31 update pass. Domain specs still own their implementation areas, but if an older active spec conflicts with this May 31 framework, update the domain spec or follow the May 31 update section added to that domain spec.

## 2. Non-negotiable distinctions

Subh must preserve the following distinctions:

| Distinction | Rule |
| --- | --- |
| Wake purpose vs wake delivery | `Suhoor` and `Fajr` answer why the user is waking. `Quiet` and `Pause` answer whether Subh will ring. |
| Hero vs context card | Hero stays minimal. Context card explains. |
| Context copy vs compact tags | Context card uses sentence-based copy. Next 7 uses compact opportunity tags. |
| Suhoor wake session vs Fajr-start event | A Fajr-start event after Suhoor is a single AlarmKit event and has no wake checks by default. |
| Fajr-start event vs optional Fajr wake session | Optional Fajr follow-up is user-initiated and then uses normal wake checks. |
| Wake acknowledgement vs prayer completion | `I’m Awake for Fajr` confirms wake success. `I Prayed Fajr` logs prayer completion. |
| Current/previous morning logging vs next-morning hero | Late Fajr logging appears below the context card, not inside the hero after the hero has rolled forward. |

## 3. Vocabulary and visible copy doctrine

Use visible, public-friendly copy. Avoid technical terms such as `anchor`, `event line`, `scheduler state`, `wake-check generator`, `calculation boundary`, or `delivery suppressed` in user-facing UI.

The visible purpose selector order is:

```text
Suhoor | Fajr
```

Do not show Quiet or Pause inside this selector.

Hero relative labels use title case:

```text
Today Morning
Tomorrow Morning
```

Before midnight, the next relevant morning is `Tomorrow Morning`. After midnight, that same morning becomes `Today Morning`. At Fajr end, the hero rolls to the next relevant morning and generally returns to `Tomorrow Morning`.

## 4. Hero requirements

The Home Hero and Detail hero-like alarm panel use a six-slot model:

```text
Slot 1 — Location
Slot 2 — Morning label
Slot 3 — Primary alarm-state button / status
Slot 4 — Alarm slider / timeline surface
Slot 5 — One-line supporting copy
Slot 6 — Primary action row
```

### 4.1 Location

Show the resolved location plainly, such as `Toronto`. Do not replace it with calendar context, Quiet, or Pause.

### 4.2 Morning label

Use `Today Morning` or `Tomorrow Morning` in title case. Do not use only `Today` or `Tomorrow` in the hero label.

### 4.3 Primary alarm-state row

The primary row should remain minimal:

```text
[alarm icon] 5:19 AM
```

Do not add explanatory text below the wake time in the hero. Explanatory copy belongs in the context card.

The alarm icon and adjacent wake time are an interactive alarm-state control. The alarm icon must look tappable using the same subtle translucent/liquid-glass affordance language as the settings icon. The tap target should include both icon and wake time where practical.

When the focused morning is Quiet, the hero primary alarm-state should show `Quiet` as the primary state rather than presenting a normal active alarm time as though delivery will occur.

### 4.4 Quiet popover / confirmation from hero

Tapping the alarm icon/wake time opens a deliberate Quiet confirmation. The pointer must point to the alarm icon/wake-time control, not vaguely to the whole hero.

For an alarm-on future or same-morning target:

```text
Title: Make Tomorrow Morning Quiet?
Body: No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.
Actions: Keep Alarm On / Make Quiet
```

Use `Make Today Morning Quiet?` for same-morning targets.

If Quiet is already on:

```text
Title: Tomorrow Morning is Quiet
Body: No alarm or wake checks will ring, but your Suhoor/Fajr plan is saved.
Actions: Turn Alarm On / Keep Quiet
```

Use `Today Morning is Quiet` for same-morning targets.

### 4.5 Slider behaviour

The slider remains active for valid active Fajr/Suhoor planning and ring-once states. It is ghosted/read-only for Quiet, inherited Pause, and post-execution states.

While dragging, all visible feedback must update together:

- primary wake time;
- slider thumb;
- supporting helper text such as `30 min before Fajr ends` or `30 min before Fajr begins`.

The UI must not show a lag where the top time changes but the supporting timing copy remains hidden, stale, or delayed.

### 4.6 Purpose selector

Planning states show:

```text
[ Suhoor | Fajr ]
```

The selector changes only wake purpose. It does not Quiet a morning, pause alarms, log completion, or mark the user awake.

## 5. Context card requirements

The context card is the explanatory surface below the hero. It should be simple, sentence-based, and non-technical. It should not become tag-heavy or visually noisy.

The context card must communicate, when relevant:

- which morning is being discussed;
- what specific opportunity exists;
- whether the user has planned to fast;
- whether the user is waking for Suhoor or Fajr;
- whether an alarm will ring;
- the wake time when alarm delivery is active;
- Quiet/Pause state when relevant.

Do not use visual opportunity tags as the main explanation in the context card.

Example copy patterns:

```text
Tomorrow Morning is a regular Fajr morning.
You are waking for Fajr, and your alarm is set for 5:19 AM.
```

```text
Tomorrow Morning is a Monday fasting opportunity.
You have not planned to fast tomorrow. Your alarm is set for 5:19 AM for Fajr.
```

```text
Tomorrow Morning is a Monday fasting opportunity.
You have planned to fast, so your alarm is set for 5:19 AM for Suhoor.
```

```text
Tomorrow Morning is quiet.
No alarm will ring tomorrow morning. You can turn the alarm back on if you want Subh to wake you.
```

## 6. Late Fajr logging prompt below the context card

After Fajr ends, the hero rolls to the next morning and must not continue to appear as though it owns the previous Fajr state.

If the user has not logged Fajr prayer completion for the just-ended morning, show a separate late-logging prompt below the context card. This prompt is not part of the hero and must not confuse the next-morning plan.

CTA copy:

| Time context | CTA copy |
| --- | --- |
| After Fajr ends, same calendar day | `I Prayed Fajr Earlier Today` |
| After midnight / next calendar day, before expiry | `I Prayed Fajr Yesterday Morning` |

Once tapped, the prompt logs Fajr prayer completion for the previous relevant morning and disappears.

If the user does not interact with the prompt, it expires when the next relevant wake window begins:

| Current/next selected wake purpose | Expiry boundary |
| --- | --- |
| Fajr | next Fajr window begins |
| Suhoor | next Suhoor window begins |

The prompt may also disappear earlier if the user logs Fajr from Detail/history/log surfaces.

## 7. Next 7 Mornings card requirements

Next 7 Mornings is a compact planning overview with per-morning Quiet control.

Each row uses three zones:

| Zone | Content |
| --- | --- |
| Left | Wake time or Quiet, with date underneath |
| Middle | `Awake for Fajr` or `Awake for Suhoor`, with opportunity tags underneath |
| Right | Quiet toggle |

### 7.1 Left zone

When alarm is on:

```text
5:19 AM
Mon, Jun 1
```

When Quiet is on:

```text
Quiet
Mon, Jun 1
```

The wake time remains the most prominent text in the row. The date is secondary and should use a smaller/lighter treatment similar to the AM/PM portion of the wake time.

### 7.2 Middle zone

The first line states the planned wake purpose:

```text
Awake for Fajr
Awake for Suhoor
```

Below that, show specific opportunity/context tags only:

```text
Monday
Thursday
White Days
Ramadan
Arafah
Ashura
```

Do not show generic `Fasting Opportunity` tags. Do not use `Fajr`, `Suhoor`, `Quiet`, or `Paused` as opportunity tags. `Awake for Fajr/Suhoor` is a purpose line, not a tag.

### 7.3 Right zone

The right zone contains a Quiet toggle for that row.

- Toggle on = alarm will ring.
- Toggle off = that morning is Quiet.

The toggle may mutate only the row’s one-morning Quiet state. It must not change purpose, pause all alarms, or change fasting purpose. Other edits still navigate to Detail.

## 8. Daily timeline rules

The daily cycle is:

| Period | Required behaviour |
| --- | --- |
| Daytime before midnight | Hero shows next relevant morning as `Tomorrow Morning`. |
| Evening before midnight | Same planning state unless user changes something. |
| Midnight | `Tomorrow Morning` becomes `Today Morning`; no plan reset. |
| After midnight before Suhoor window | Same morning remains configurable. |
| Suhoor window begins | Suhoor-sensitive state begins; `I’m Awake for Suhoor` may appear if relevant. |
| Suhoor window | Switching between Suhoor/Fajr is allowed only within valid timing rules and may require confirmation. |
| Latest Suhoor scheduling cutoff | New Suhoor scheduling blocked after Fajr begins minus 6 minutes. |
| Fajr begins | Suhoor window closes; Fajr window begins. |
| Fajr window | Fajr wake session may run; user may acknowledge wake and log prayer. |
| Final wake-check boundary | Last wake attempt/check is no later than Fajr ends minus 5 minutes. |
| Fajr ends | Current morning closes and hero rolls to next relevant morning. |
| After Fajr end | Next-morning hero appears; unresolved Fajr prayer logging appears below context card if eligible. |

## 9. Suhoor window start

Suhoor window start is not a fixed clock time. It is calculated daily as the start of the last third of the night:

```text
nightStart = Maghrib/sunset on D - 1
nightEnd = Fajr begins on D
suhoorWindowStart = nightEnd - ((nightEnd - nightStart) / 3)
```

Example times from the Toronto walkthrough, such as 1:32 AM, are examples only and must not be hard-coded.

## 10. Wake-session generation rules

Relevant window end:

| Purpose | Relevant window end |
| --- | --- |
| Suhoor | Fajr begins |
| Fajr | Fajr ends |

Rules:

- earliest newly scheduled wake time = current time + 1 minute;
- latest wake time = relevant window end - 5 minutes;
- latest new session creation time = relevant window end - 6 minutes;
- wake checks occur at 5-minute intervals;
- no wake check occurs at the exact end boundary.

Default 30-minute session:

| Attempt | Timing |
| --- | --- |
| Initial alarm | 30 minutes before end |
| Wake check 1 | 25 minutes before end |
| Wake check 2 | 20 minutes before end |
| Wake check 3 | 15 minutes before end |
| Wake check 4 | 10 minutes before end |
| Final wake check | 5 minutes before end |

Later wake times compress naturally. A wake time 10 minutes before end produces two attempts: the initial alarm and the final 5-minute check. A wake time 5 minutes before end produces one attempt and no follow-up.

`I’m Awake for Suhoor` cancels remaining Suhoor checks. `I’m Awake for Fajr` cancels remaining Fajr checks. Neither action logs Fajr prayer completion.

## 11. Suhoor completion and optional Fajr follow-up

After `I’m Awake for Suhoor`:

1. remaining Suhoor wake checks are cancelled;
2. the Suhoor wake acknowledgement is logged;
3. Subh does not automatically create a Fajr wake-check session;
4. at Fajr begins, Subh may issue a single Fajr-start AlarmKit event;
5. that Fajr-start event has no wake checks by default.

The user may intentionally choose an optional Fajr follow-up action from the main hero, such as `Wake Me for Fajr` or `Set Fajr Wake Alarm`. If selected, the user switches/configures a Fajr wake session and normal wake-check rules apply.

## 12. Mode switching during sensitive windows

Before Suhoor window starts, switching between Suhoor and Fajr is normal.

During the Suhoor window:

- switching from Suhoor to Fajr may cancel an active/pending Suhoor session and therefore requires confirmation;
- switching into Suhoor is allowed only until Fajr begins minus 6 minutes;
- after that cutoff, explain that it is too close to Fajr to schedule Suhoor for Today Morning.

Suggested confirmation:

```text
Title: Switch to Fajr for Today Morning?
Body: This will cancel your Suhoor wake session for this morning.
Actions: Keep Suhoor / Switch to Fajr
```

After Fajr begins, Suhoor is no longer newly schedulable for Today Morning.

## 13. Pause working direction

Indefinite Pause remains a separate app-wide wake-alarm policy. When Pause is active:

- hero primary state may show `Alarms paused`;
- slider is ghosted/read-only unless a one-morning ring exception is active;
- context card explains that Subh will not ring until the user resumes or creates a one-morning exception;
- Next 7 rows may show `Paused` or saved time according to row design, but Pause is not an opportunity tag;
- the row Quiet toggle should be disabled or replaced by the paused state where inherited Pause owns delivery, unless a later detailed design chooses a safe override model;
- `Ring Tomorrow Only` / `Ring This Morning Only` remains the approved one-morning exception while global Pause stays active.

Pause is intentionally not fully redesigned in the May 31 walkthrough. Treat the above as a best-judgment compatibility direction and avoid broad Pause redesign beyond conflicts needed for the May 31 changes.

## 14. Testing and simulation requirements

The testing harness must support the May 31 state walkthrough without waiting for real mornings.

Required capabilities:

- load a scenario with fixed date, location, timezone, and prayer times;
- scrub minute-by-minute across the next 24 hours and preferably 48 hours;
- jump to boundary presets: daytime, evening, before midnight, midnight, before Suhoor window, Suhoor window start, Suhoor cutoff, Fajr begins, Fajr window, default Fajr wake, final check, Fajr ends, after Fajr;
- interact with the real hero/context/Next 7 surfaces while simulated time is active;
- branch the simulation based on user actions such as changing purpose, dragging the slider, toggling Quiet, acknowledging Suhoor/Fajr, opting into Fajr follow-up, and logging Fajr;
- compare expected and actual hero/context/Next 7 states;
- keep labels readable and prevent text from running off screen;
- never show `No time available` in standard scenarios with valid prayer-time data.

Edge-case simulation backlog remains active for DST changes, high-latitude locations, Ramadan, Eid/fasting-unavailable days, location changes, and prayer-time calculation changes.

## 15. Traceability IDs

The May 31 update introduces or confirms these traceable requirements:

| ID | Requirement |
| --- | --- |
| MSF-HERO-001 | Hero Slot 2 uses `Today Morning` / `Tomorrow Morning` in title case. |
| MSF-HERO-002 | Hero primary alarm row remains icon + wake time/Quiet only; no explanatory line under it. |
| MSF-HERO-003 | Alarm icon/wake time is a tappable Quiet-related control with glass affordance. |
| MSF-HERO-004 | Quiet confirmation uses master-copywriter plain-language copy and explicit confirmation. |
| MSF-CONTEXT-001 | Context card uses sentence-based explanation, not tags. |
| MSF-N7-001 | Next 7 rows place wake time/Quiet on the left and date beneath it. |
| MSF-N7-002 | Next 7 middle zone shows `Awake for Fajr/Suhoor` above specific opportunity tags. |
| MSF-N7-003 | Next 7 right zone has a per-morning Quiet toggle. |
| MSF-WAKE-001 | Wake checks occur every 5 minutes and stop no later than window end minus 5 minutes. |
| MSF-WAKE-002 | Latest new wake-session creation time is window end minus 6 minutes. |
| MSF-SF-001 | Suhoor window starts at the last third of the night, calculated daily. |
| MSF-SF-002 | Suhoor completion does not automatically create a Fajr wake-check session. |
| MSF-SF-003 | Fajr-start event after Suhoor is single-shot and has no wake checks. |
| MSF-SF-004 | Optional Fajr follow-up is user-initiated and then uses normal wake checks. |
| MSF-LOG-001 | `I’m Awake for Fajr` does not log Fajr prayer completion. |
| MSF-LOG-002 | `I Prayed Fajr` logs Fajr prayer completion separately. |
| MSF-LOG-003 | Late Fajr logging appears below context card, not in the hero after Fajr end. |
| MSF-TEST-001 | Harness supports 24/48-hour scrubbing and action-branching. |
