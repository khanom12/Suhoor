# Subh Primary Morning Context Presentation Specification v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-primary-morning-context-presentation-spec-v2.md` |
| Version | 2 |
| Spec status | Active context presentation contract |
| Date | 2026-05-30 |
| Related specs | Index, Day Purpose, Shared Tags, Hero, Detail, Next 7, Month |
| Owning domain / surface | Context explanation across morning surfaces |

## May 30, 2026 reconciliation status

This active spec has been reconciled against the finalized Quiet / Pause / Hero / Wake Flow direction. It is implementation-facing. Older wording preserved in `Archive/originals-before-may30-reconciliation/` is historical only and must not be implemented when it conflicts with this active file.

Canonical MVP doctrine used across the active spec set:

```text
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes. `Suhoor` is the only exposed MVP before-Fajr wake purpose and is fasting/suhoor-oriented. Generic non-fasting `Pre-Fajr`, `Early`, `Tahajjud only`, and `Other early worship` flows are deferred unless a later approved spec explicitly reintroduces them.


## 1. Purpose

Context presentation explains why a morning matters without confusing that context with wake purpose, alarm state, or completion.

## 2. Context categories

Context may include:

```text
ordinary morning
Ramadan
Eid / forbidden fast
White Days
Monday/Thursday
Arafah
Ashura
Dhul Hijjah
Shawwal Six
location/prayer-time context
```

## 3. Presentation rules

- Hero prioritizes alarm state and action; context should stay concise.
- Detail may show fuller context explanation.
- Next 7/Month use compact opportunity/context tags only.
- Weekly Fajrcast may summarize context across seven mornings.

## 4. Separation rules

Do not let context presentation imply:

- user selected Suhoor;
- user planned a fast;
- user completed a fast;
- user missed Fajr;
- alarm is Quiet/Paused;
- delivery failed.

Those meanings come from separate resolver/log layers.

## 5. Acceptance criteria

1. Context is displayed separately from purpose and alarm state.
2. Opportunity tags do not mutate state.
3. Compact rows do not use Fajr/Suhoor/Quiet/Paused as context tags.
4. Detail can explain context more fully without changing the selected plan.
