# Subh Active Specification Index v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `00-subh-spec-index-v4.md` |
| Version | 4 |
| Spec status | Active index and source-of-truth map |
| Date | 2026-05-30 |
| Owning domain / surface | Entire active Subh spec library |

## 1. Purpose

This index defines the active implementation-facing specification set after the Quiet / Pause / Hero / Wake Flow reconciliation pass.

The May 30 pass exists because the earlier active files contained correct May 29 addenda but still had lower-body historical requirements that looked active. Those lower-body conflicts are no longer active. The original versions are preserved under:

```text
Archive/originals-before-may30-reconciliation/
```

Codex and implementation work should use the active files at the root of this package, not the archived originals.

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

The exposed MVP wake purposes are:

```text
Fajr
Suhoor
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

Quiet and Pause must not be implemented as siblings of Fajr and Suhoor.

```text
Correct:    WakePurpose = Fajr | Suhoor
            AlarmState = active | quiet | paused | rings-once | blocked | issue

Incorrect:  Mode = Fajr | Suhoor | Quiet | Pause
```

## 3. Naming and copy rules

Use these visible MVP terms:

```text
Fajr
Suhoor
Quiet
Alarms paused
Time to wake
Next alarm soon
I’m awake
I’m fasting today
I prayed Fajr
Fajr complete
Alarm saved for 5:42 AM
No response recorded
Alarm ended
Alarm issue
Turn on alarms
Set location
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
```

Internal implementation names may remain where code compatibility requires them, but active user-facing copy and active specs must normalize them to the vocabulary above.

## 4. Final resolved behavioral decisions

### 4.1 Suhoor

`Suhoor` is the only exposed MVP before-Fajr wake purpose. It is fasting/suhoor-oriented.

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

Quiet preserves the selected Fajr/Suhoor purpose and saved purpose-specific alarm settings. Quiet is available before the first alarm begins. Once the first alarm has begun, Quiet is no longer a user-facing action for that wake.

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

### 4.4 Active wake sessions

When an alarm execution has begun:

- Hide/lock Fajr/Suhoor switching for that executing wake.
- Do not expose Quiet for that executing wake.
- Do not show `Stop checks`.
- Slot 6 / primary action shows only `I’m awake`.
- `I’m awake` cancels remaining follow-up alarms for that morning.
- For MVP, explicit system/AlarmKit dismissal is treated as equivalent to `I’m awake`; store the acknowledgement source separately.

### 4.5 Suhoor after acknowledgement and Fajr handoff

After a Suhoor alarm is acknowledged:

- before Fajr begins, the Home Hero may show `I’m fasting today` after the anti-double-tap delay;
- at Fajr begins, the morning enters the Fajr phase even though the earlier Suhoor wake was acknowledged;
- if the Fajr-specific wake check has not yet been acknowledged, the primary CTA becomes `I’m awake for Fajr` before prayer logging;
- after `I’m awake for Fajr` and the anti-double-tap delay, the hero may show `I prayed Fajr` while Fajr is still open;
- if `I’m fasting today` was not tapped before Fajr begins, fasting can be logged later through an appropriate log/detail surface if supported.

The Suhoor wake acknowledgement and the Fajr wake acknowledgement are separate outcome facts. A user who woke for Suhoor may still need a lightweight Fajr-specific confirmation after Fajr begins.

## 5. Active spec map

| File | Active responsibility |
| --- | --- |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v2.md` | 2 |
| `subh-morning-resolution-contract-state-ownership-spec-v4.md` | 4 |
| `subh-quick-wake-mode-intent-mutation-contract-v3.md` | 3 |
| `subh-morning-hero-item-spec-v16.md` | 16 |
| `subh-alarm-detail-view-screen-spec-v8.md` | 8 |
| `subh-quiet-mode-quiet-morning-contract-spec-v2.md` | 2 |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v2.md` | 2 |
| `subh-alarm-delivery-schedule-reliability-spec-v4.md` | 4 |
| `subh-next-7-mornings-wake-forecast-spec-v3.md` | 3 |
| `subh-month-planning-gregorian-hijri-spec-v3.md` | 3 |
| `subh-weekly-fajrcast-card-spec-v15.md` | 15 |
| `subh-shared-day-tag-presentation-contract-v2.md` | 2 |
| `subh-day-purpose-opportunity-resolution-spec-v2.md` | 2 |
| `subh-early-worship-boundary-spec-v3.md` | 3 |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v4.md` | 4 |
| `subh-primary-morning-context-presentation-spec-v2.md` | 2 |
| `subh-context-tags-integration-addendum-v2.md` | 2 |
| `subh-context-spec-integrity-review-v2.md` | 2 |
| `subh-sound-alarm-settings-spec-v2.md` | 2 |
| `subh-fajr-time-calculation-determination-selection-spec-v2.md` | 2 |
| `subh-mvp-interaction-inventory-v5.md` | 5 |
| `subh-mvp-interaction-tier-exposure-matrix-v3.md` | 3 |
| `subh-pricing-entitlement-spec-v4.md` | 4 |
| `subh-wake-session-testing-and-simulation-harness-spec-v4.md` | 4 |

## 6. Conflict rule

If any active file appears to conflict with this index or `subh-quiet-pause-hero-wake-flow-alignment-spec-v2.md`, use the more specific reconciled active file first, then the alignment spec, then this index.

Archived originals are for traceability only.

## 7. Implementation acceptance checks

The active spec set is implementation-safe only if all of the following remain true:

1. No active MVP selector contains Quiet as a third wake purpose.
2. Home and Detail expose the same purpose selector: `Fajr | Suhoor`.
3. Quiet is available before alarm execution and unavailable after first alarm begins.
4. Pause is indefinite and app-wide for Subh wake alarms.
5. `Ring tomorrow only` / `Ring this morning only` works as a date exception while Pause stays active.
6. Next 7, Month, and Weekly Fajrcast do not mutate Quiet/Pause inline.
7. Middle-lane tags remain opportunity/context tags only.
8. Alarm delivery distinguishes Quiet/Pause from blocked permissions and delivery failure.
9. System alarm dismissal is recorded as awake acknowledgement with source preserved.
10. Basic wake utility, Quiet, Pause, acknowledgement, and current-morning logs remain Free/core.
