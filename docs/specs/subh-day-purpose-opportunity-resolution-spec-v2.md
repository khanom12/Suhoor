# Subh Day Purpose, Opportunity, Intention, Outcome, and Analytics Credit Specification v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-day-purpose-opportunity-resolution-spec-v2.md` |
| Version | 2 |
| Spec status | Active day-purpose/opportunity specification |
| Date | 2026-05-30 |
| Related specs | Index, Morning Resolution, Shared Tags, Detail, Next 7, Month, Pricing |
| Owning domain / surface | Day meaning, user intention, outcome, and analytics credit |

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

A date can have religious/calendar meaning without becoming an active wake plan or completion requirement.

This spec preserves the distinction between:

```text
Observance opportunity / day meaning
User intention / day plan
Wake purpose
Alarm state
Outcome / completion
Analytics credit
```

## 2. Core rule

```text
Meaning is not intention.
Intention is not execution.
Execution is not automatically credited to every meaning on the date.
```

Example: A Monday is a Sunnah fasting opportunity. It does not become a planned fast unless the user selects Suhoor or another durable fasting-intention source applies.

## 3. Observance opportunity

An opportunity is calendar/date context.

Examples:

```text
Ramadan
Monday/Thursday
White Days
Arafah
Ashura
Dhul Hijjah first nine
Shawwal Six possibility
Eid / forbidden fast day
ordinary day
```

Opportunities may appear as context tags or explanatory copy. They do not schedule alarms by themselves.

## 4. User intention

MVP user intentions relevant to wake planning:

```text
Default Fajr morning
Suhoor / fasting morning
Quiet selected morning
Ring once despite Pause
Fasting-purpose selection under Suhoor
```

Deferred from active MVP:

```text
Tahajjud-only before-Fajr planning
Other early worship before-Fajr planning
Fasting + Tahajjud combined planning
Generic non-fasting Pre-Fajr wake
```

## 5. Wake purpose vs fasting purpose

Wake purpose:

```text
Fajr | Suhoor
```

Fasting purpose under Suhoor may include:

```text
Ramadan fast
Sunnah opportunity default
Voluntary fast
Qada
Vow/Nadhr
Kaffarah
Other fast
```

Do not model fasting-purpose choices as top-level wake purposes.

## 6. Outcome and logs

Outcome records should stay specific:

```text
wakeAcknowledged
fastingTodayLogged
fajrPrayerLogged
fastCompleted
fastNotCompleted
quietMorning
endedNoResponse
alarmIssue
```

Quiet/Pause/no-response must not automatically create missed-prayer or missed-fast records.

## 7. Analytics credit

Analytics should distinguish:

- opportunity available;
- opportunity seen/shown;
- user planned/intended;
- alarm scheduled;
- alarm acknowledged;
- fasting status logged;
- fast completed;
- Fajr prayed;
- no response;
- Quiet/Pause affected the date.

A Qada fast completed on a White Day should credit Qada completion and may separately record that a White Day opportunity existed. It should not automatically credit White Day voluntary completion unless the user intention supports that.

## 8. Tag implications

Shared tags show opportunity/context only. They do not imply intention or outcome.

Compact rows must not use Fajr/Suhoor/Quiet/Paused as middle-lane opportunity tags.

## 9. Acceptance criteria

1. Opportunities alone do not change wake purpose.
2. Selecting Suhoor creates fasting/suhoor wake intent.
3. Fasting-purpose choices remain under Suhoor/fasting domain.
4. Quiet/Pause do not erase day meaning or intention.
5. Quiet/Pause/no-response do not automatically create missed outcomes.
6. Analytics credit can distinguish opportunity, intention, execution, and completion.
