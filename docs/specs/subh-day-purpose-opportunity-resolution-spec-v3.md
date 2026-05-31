# Subh Day Purpose, Opportunity, Intention, Outcome, and Analytics Credit Specification v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-day-purpose-opportunity-resolution-spec-v3.md` |
| Version | 3 |
| Spec status | Active day-purpose/opportunity specification |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Morning Resolution, Shared Tags, Detail, Next 7, Month, Pricing |
| Owning domain / surface | Day meaning, user intention, outcome, and analytics credit |

## May 31, 2026 update status

Version 3 adds the May 31 context-card and Next 7 implications: opportunity tags must be specific, context-card explanations must be sentence-based, and Fajr wake acknowledgement remains separate from Fajr prayer completion.

## 1. Purpose

A date can have religious/calendar meaning without becoming an active wake plan or completion requirement.

This spec preserves the distinction between:

```text
Observance opportunity / day meaning
User intention / day plan
Wake purpose
Alarm state
Wake acknowledgement
Prayer completion
Analytics credit
```

## 2. Core rule

```text
Meaning is not intention.
Intention is not execution.
Wake acknowledgement is not prayer completion.
Execution is not automatically credited to every meaning on the date.
```

Example: A Monday is a Sunnah fasting opportunity. It does not become a planned fast unless the user selects Suhoor or another durable fasting-intention source applies.

## 3. Observance opportunity

An opportunity is calendar/date context.

Examples:

```text
Ramadan
Monday
Thursday
White Days
Arafah
Ashura
Dhul Hijjah first nine
Shawwal Six possibility
Eid / forbidden fast day
ordinary day
```

Opportunities may appear as specific context tags or explanatory copy. They do not schedule alarms by themselves.

Do not use generic compact tags such as `Fasting Opportunity`; use the specific opportunity name instead.

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

Wake purpose values:

```text
Fajr
Suhoor
```

Visible selector order where shown:

```text
Suhoor | Fajr
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
suhoorWakeAcknowledged
fajrWakeAcknowledged
fastingTodayLogged
fajrPrayerLogged
lateFajrPrayerLogged
fastCompleted
fastNotCompleted
quietMorning
endedNoResponse
alarmIssue
```

Quiet/Pause/no-response must not automatically create missed-prayer or missed-fast records.

`I’m Awake for Fajr` / Fajr wake acknowledgement must not create `fajrPrayerLogged`. The separate `I Prayed Fajr` CTA logs prayer completion.

## 7. Late Fajr logging credit

If Fajr prayer completion is logged after Fajr end through the prompt below the context card, analytics should credit it as late Fajr logging for the previous relevant morning.

CTA copy:

```text
I Prayed Fajr Earlier Today
I Prayed Fajr Yesterday Morning
```

The prompt expires at the next relevant wake window if unused.

## 8. Analytics credit

Analytics should distinguish:

- opportunity available;
- opportunity seen/shown;
- user planned/intended;
- alarm scheduled;
- alarm acknowledged;
- Fajr wake acknowledged;
- Fajr prayer logged;
- late Fajr prayer logged;
- fasting status logged;
- fast completed;
- no response;
- Quiet/Pause affected the date.

A Qada fast completed on a White Day should credit Qada completion and may separately record that a White Day opportunity existed. It should not automatically credit White Day voluntary completion unless the user intention supports that.

## 9. Tag implications

Shared tags show opportunity/context only. They do not imply intention or outcome.

Compact rows must not use Fajr/Suhoor/Quiet/Paused as opportunity tags. Next 7 may show `Awake for Fajr/Suhoor` as a separate purpose line above the tag lane.

## 10. Acceptance criteria

1. Opportunities alone do not change wake purpose.
2. Selecting Suhoor creates fasting/suhoor wake intent.
3. Fasting-purpose choices remain under Suhoor/fasting domain.
4. Quiet/Pause do not erase day meaning or intention.
5. Quiet/Pause/no-response do not automatically create missed outcomes.
6. `I’m Awake for Fajr` does not log Fajr prayer completion.
7. `I Prayed Fajr` logs Fajr prayer completion separately, including late logging when applicable.
8. Analytics credit can distinguish opportunity, intention, execution, wake acknowledgement, prayer completion, and late completion.
