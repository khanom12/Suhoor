# Subh Active Specification Index v5 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `00-subh-spec-index-v5.md` |
| Version | 5 |
| Spec status | Active index and source-of-truth map |
| Date | 2026-05-31 |
| Owning domain / surface | Entire active Subh spec library |

## 1. Purpose

This index defines the active implementation-facing specification set after the May 31 Morning State Framework update.

The May 31 pass is a controlled update to the May 30 reconciled specification set. It incorporates the morning-state walkthrough that began from the live Toronto app state on May 31, 2026 after approximately 10:30 AM and later around 12:19 PM, then mentally simulated the app through evening, midnight, Suhoor window, Fajr begins, Fajr window, Fajr end, and post-Fajr next-morning rollover.

This pass is not a broad redesign. It updates only the areas affected by the May 31 walkthrough:

- Hero labels, alarm icon affordance, Quiet confirmation, and live slider feedback;
- context card sentence-based explanation;
- Next 7 Mornings row layout and per-row Quiet toggle;
- Suhoor/Fajr timing, cutoff, and switching rules;
- wake-check generation and compression rules;
- Suhoor completion plus optional Fajr follow-up;
- Fajr prayer logging separation and late logging below the context card;
- testing harness minute-by-minute / 24-48 hour simulation needs;
- compatibility cleanup where May 30 specs explicitly contradicted the May 31 decisions.

Archived May 30 root files are preserved under:

```text
Archive/may30-pre-may31-scenario-update/
```

Codex and implementation work should use the active files at the root of this package, not the archived May 30 files.

## 2. Canonical product model

Subh is a Fajr-centered morning system.

Every editable morning resolves through separate layers:

```text
Morning context
Wake purpose
Purpose-specific alarm configuration
Date-specific alarm override
Global wake-alarm policy
Resolved alarm state
Wake execution state
Logs / outcomes / analytics
```

The exposed MVP wake-purpose values are:

```text
Fajr
Suhoor
```

The visible planning selector order is:

```text
Suhoor | Fajr
```

Quiet and Pause must not be implemented as siblings of Fajr and Suhoor.

```text
Correct model: WakePurpose = Fajr | Suhoor
Visible selector: Suhoor | Fajr
AlarmState = active | quiet | paused | rings-once | blocked | issue

Incorrect: Mode = Fajr | Suhoor | Quiet | Pause
Incorrect: Purpose selector includes Quiet or Pause
```

The alarm / sound states are:

```text
active
quiet for this morning
paused by app-wide pause
rings once despite pause
blocked / setup needed
issue / failed delivery
```

## 3. Naming and copy rules

Use these visible MVP terms:

```text
Fajr
Suhoor
Quiet
Alarms paused
Today Morning
Tomorrow Morning
Time to wake
Next alarm soon
I’m awake
I’m awake for Fajr
I’m fasting today
I prayed Fajr
I Prayed Fajr Earlier Today
I Prayed Fajr Yesterday Morning
Fajr complete
Alarm saved for 5:42 AM
No response recorded
Alarm ended
Alarm issue
Turn on alarms
Set location
Awake for Fajr
Awake for Suhoor
```

Do not use these as visible MVP wake-purpose, hero, row-status, or action labels:

```text
Pre-Fajr
Early
Early worship
Fast mode
Fasting mode
Quiet mode
Pause mode
Wake checks active
Wake confirmed
Wake ended
Saved wake
Saved Fajr wake
Saved Suhoor wake
No wake confirmed
Stop checks
Delivery suppressed
Active despite pause
Permission blocked
anchor
event line
scheduler state
wake-check generator
```

Internal implementation names may remain where code compatibility requires them, but active user-facing copy and active specs must normalize them to the vocabulary above.

## 4. Final resolved behavioral decisions

### 4.1 Suhoor

`Suhoor` is the only exposed MVP before-Fajr wake purpose. It is fasting/suhoor-oriented.

The Suhoor window begins at the start of the last third of the night, calculated daily from the user’s location and date. Example times from the May 31 Toronto walkthrough, such as 1:32 AM, are examples only and must not be hard-coded.

The following are not active MVP user-selectable wake purposes or intention paths:

```text
Pre-Fajr
Early
Fast mode
Tahajjud only
Other early worship
Fasting + Tahajjud
Generic non-fasting before-Fajr wake
```

Supported fasting-purpose choices such as `Voluntary fast`, `Qada`, `Vow/Nadhr`, `Kaffarah`, `Other fast`, Ramadan fasts, and Sunnah opportunity-based defaults remain fasting-purpose data under Suhoor or the fasting domain. They are not separate wake purposes.

### 4.2 Quiet

Quiet is a date-level alarm override:

```text
Quiet = Subh will not ring for this specific morning.
```

Quiet preserves the selected Fajr/Suhoor purpose and saved purpose-specific alarm settings.

The Home Hero alarm icon/wake-time control opens a deliberate Quiet confirmation. The confirmed copy is:

```text
Title: Make Tomorrow Morning Quiet?
Body: No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.
Actions: Keep Alarm On / Make Quiet
```

Use `Make Today Morning Quiet?` for same-morning targets.

If Quiet is enabled before execution, Subh does not start that wake session. If Quiet is explicitly applied during an active wake session from an approved alarm-state control, it cancels remaining alarms/checks and logs a user-requested quiet cancellation. This must remain deliberate and must not replace the primary active wake CTA, which remains `I’m awake`.

### 4.3 Pause

Pause is an app-wide wake-alarm policy:

```text
Alarms paused = Subh wake alarms stay off until the user resumes them.
```

MVP Pause is indefinite only. Date-range pause, recurring pause, pause reasons, and timed pause are not MVP.

While Pause is active, the user may create a one-morning exception:

```text
Ring tomorrow only
Ring this morning only
```

That exception does not resume all alarms.

The May 31 walkthrough did not fully redesign indefinite Pause. Maintain May 30 Pause doctrine except where specific May 31 UI surfaces require compatibility with the new hero/context/Next 7 layout.

### 4.4 Hero / context / Next 7

- Hero Slot 2 uses `Today Morning` / `Tomorrow Morning` in title case.
- Hero Slot 3 remains minimal: alarm icon + wake time, or `Quiet` / `Alarms paused` / setup/issue state.
- The alarm icon must look tappable using a glass/translucent treatment.
- The context card uses sentence-based explanatory copy, not tags.
- Next 7 row layout is left = wake time/Quiet + date, middle = `Awake for Fajr/Suhoor` + specific opportunity tags, right = Quiet toggle.
- Opportunity tags must be specific: `Monday`, `Thursday`, `White Days`, `Ramadan`, `Arafah`, `Ashura`, etc. Do not use generic `Fasting Opportunity` tags.

### 4.5 Wake sessions and checks

Wake checks occur every 5 minutes.

Relevant boundaries:

```text
Suhoor relevant window end = Fajr begins
Fajr relevant window end = Fajr ends
```

Scheduling rules:

```text
Earliest new alarm = current time + 1 minute
Latest wake time = relevant window end - 5 minutes
Latest new session creation time = relevant window end - 6 minutes
No wake check at the exact end boundary
```

A default 30-minute session produces six total wake attempts: 30, 25, 20, 15, 10, and 5 minutes before the relevant window end. Later wake times compress naturally.

### 4.6 Suhoor after acknowledgement and Fajr handoff

After a Suhoor alarm is acknowledged:

- remaining Suhoor checks are cancelled;
- Suhoor wake acknowledgement is logged;
- Subh does not automatically create a full Fajr wake-check session;
- at Fajr begins, Subh may issue a single Fajr-start AlarmKit event;
- that Fajr-start event has no wake checks by default;
- the user may intentionally opt into a Fajr follow-up wake session from the hero, after which normal Fajr wake-check rules apply.

`I’m Awake for Fajr` confirms wake success and cancels remaining Fajr checks. It does not log Fajr prayer completion.

`I Prayed Fajr` logs Fajr prayer completion separately.

### 4.7 Late Fajr logging after hero rollover

At Fajr end, the Hero rolls to the next relevant morning.

If Fajr prayer completion was not logged, show a separate prompt below the context card, not inside the hero:

| Time context | CTA copy |
| --- | --- |
| After Fajr ends, same calendar day | `I Prayed Fajr Earlier Today` |
| After midnight / next calendar day, before expiry | `I Prayed Fajr Yesterday Morning` |

Once tapped, the prompt logs the previous relevant morning and disappears. If ignored, it expires when the next relevant wake window begins: next Fajr window for Fajr-selected next morning; next Suhoor window for Suhoor-selected next morning.

### 4.8 Testing and simulation

The testing harness must allow a human tester to simulate the next 24 hours and preferably 48 hours from a chosen starting day. It must support minute-by-minute scrubbing, boundary presets, and action-branching on the real hero/context/Next 7 surfaces while simulated time is active.

DST, high-latitude, Ramadan, Eid/fasting-unavailable, travel/location-change, and prayer-time-calculation-change cases remain explicit simulation/backlog items.

## 5. Active spec map

| File | Active responsibility / version |
| --- | --- |
| `subh-morning-state-framework-scenario-walkthrough-spec-v1.md` | 1 — May 31 source walkthrough and cross-surface framework |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v3.md` | 3 — cross-spec alignment doctrine |
| `subh-morning-resolution-contract-state-ownership-spec-v5.md` | 5 — resolved state ownership |
| `subh-quick-wake-mode-intent-mutation-contract-v4.md` | 4 — mutation semantics |
| `subh-morning-hero-item-spec-v17.md` | 17 — Home Hero |
| `subh-alarm-detail-view-screen-spec-v9.md` | 9 — Detail view |
| `subh-quiet-mode-quiet-morning-contract-spec-v3.md` | 3 — Quiet/Pause |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v3.md` | 3 — wake sessions, checks, logs |
| `subh-alarm-delivery-schedule-reliability-spec-v5.md` | 5 — delivery / scheduling |
| `subh-next-7-mornings-wake-forecast-spec-v4.md` | 4 — Next 7 Mornings |
| `subh-month-planning-gregorian-hijri-spec-v4.md` | 4 — month planning; cross-reference aligned only; not materially redesigned in this pass |
| `subh-weekly-fajrcast-card-spec-v15.md` | 15 — weekly summary; not materially changed in this pass |
| `subh-shared-day-tag-presentation-contract-v3.md` | 3 — compact tag semantics |
| `subh-day-purpose-opportunity-resolution-spec-v3.md` | 3 — opportunity/intention/outcome distinction |
| `subh-early-worship-boundary-spec-v4.md` | 4 — Suhoor last-third boundary and cutoff rules |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v4.md` | 4 — planning horizon; not materially changed in this pass |
| `subh-primary-morning-context-presentation-spec-v3.md` | 3 — sentence-based context card |
| `subh-context-tags-integration-addendum-v3.md` | 3 — tag integration |
| `subh-context-spec-integrity-review-v3.md` | 3 — drift-control checklist |
| `subh-sound-alarm-settings-spec-v2.md` | 2 — sound settings; not materially changed in this pass |
| `subh-fajr-time-calculation-determination-selection-spec-v2.md` | 2 — Fajr calculations; not materially changed in this pass |
| `subh-mvp-interaction-inventory-v6.md` | 6 — interaction coverage |
| `subh-mvp-interaction-tier-exposure-matrix-v3.md` | 3 — tier exposure; not materially changed in this pass |
| `subh-pricing-entitlement-spec-v4.md` | 4 — pricing; not materially changed in this pass |
| `subh-wake-session-testing-and-simulation-harness-spec-v5.md` | 5 — simulation and testing harness |

## 6. Conflict rule

If any active file appears to conflict with this index or `subh-morning-state-framework-scenario-walkthrough-spec-v1.md`, use the more specific updated domain spec first, then the scenario walkthrough spec, then the alignment spec, then this index.

Archived May 30 files are traceability records only.

## 7. Implementation acceptance checks

The active spec set is implementation-safe only if all of the following remain true:

1. No active MVP selector contains Quiet or Pause as a wake purpose.
2. Home and Detail expose the same visible purpose selector order: `Suhoor | Fajr`.
3. Quiet is alarm delivery suppression, not a wake purpose.
4. Pause is indefinite and app-wide for Subh wake alarms.
5. `Ring tomorrow only` / `Ring this morning only` works as a date exception while Pause stays active.
6. Next 7 Mornings has a right-side per-row Quiet toggle; Month and Weekly Fajrcast remain non-mutating unless later explicitly changed.
7. Next 7 middle-zone opportunity tags remain specific context tags; Fajr/Suhoor appear only as a purpose line (`Awake for Fajr/Suhoor`), not as tags.
8. Alarm delivery distinguishes Quiet/Pause from blocked permissions and delivery failure.
9. System alarm dismissal is recorded as awake acknowledgement with source preserved.
10. `I’m Awake for Fajr` does not log Fajr prayer completion.
11. `I Prayed Fajr` logs Fajr prayer completion separately.
12. Late Fajr logging appears below the context card after hero rollover and uses `I Prayed Fajr Earlier Today` / `I Prayed Fajr Yesterday Morning` copy.
13. Wake checks use the 5-minute interval, window-end-minus-5 final boundary, and window-end-minus-6 latest-new-session rule.
14. Suhoor completion does not automatically create a full Fajr wake-check session.
15. The testing harness can scrub through at least 24 hours, preferably 48 hours, with action-branching and readable expected-state inspection.
