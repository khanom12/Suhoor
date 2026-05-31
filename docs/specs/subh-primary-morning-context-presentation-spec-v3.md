# Subh Primary Morning Context Presentation Specification v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-primary-morning-context-presentation-spec-v3.md` |
| Version | 3 |
| Spec status | Active context presentation contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Day Purpose, Shared Tags, Hero, Detail, Next 7, Month |
| Owning domain / surface | Context explanation across morning surfaces |

## May 31, 2026 update status

Version 3 updates the context card based on the May 31 morning-state walkthrough. The context card is now explicitly the explanatory layer below the Hero. It uses sentence-based copy, not tag-heavy presentation.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible planning selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes.

## 1. Purpose

Context presentation explains why a morning matters and what the user has planned without confusing context with wake purpose, alarm state, or completion.

The Hero remains minimal. The context card carries the fuller explanation.

## 2. Context categories

Context may include:

```text
ordinary morning
Ramadan
Eid / forbidden fast
White Days
Monday
Thursday
Arafah
Ashura
Dhul Hijjah
Shawwal Six
location/prayer-time context
```

## 3. Presentation rules

- Hero prioritizes alarm state and action; it should not add explanatory text under the wake time.
- Context card uses simple, user-friendly sentences.
- Context card must not become tag-heavy.
- Next 7/Month use compact opportunity/context tags only.
- Weekly Fajrcast may summarize context across seven mornings.
- Detail may show fuller context explanation using the same semantics.

## 4. Context card content requirements

The context card should communicate, when relevant:

| Item | Required? |
| --- | --- |
| Which morning is being discussed | Yes |
| Whether there is a fasting opportunity | Yes, if applicable |
| What specific opportunity exists | Yes |
| Whether the user has planned/intends to fast | Yes, if relevant |
| Whether the user is waking for Suhoor or Fajr | Yes |
| Whether an alarm will ring | Yes |
| Wake time | Yes, if alarm is on |
| Quiet/Pause state | Yes, if applicable |

## 5. Example copy patterns

### Normal Fajr morning

```text
Tomorrow Morning is a regular Fajr morning.
You are waking for Fajr, and your alarm is set for 5:19 AM.
```

### Monday fasting opportunity, not planned to fast

```text
Tomorrow Morning is a Monday fasting opportunity.
You have not planned to fast tomorrow. Your alarm is set for 5:19 AM for Fajr.
```

### Monday fasting opportunity, planned to fast

```text
Tomorrow Morning is a Monday fasting opportunity.
You have planned to fast, so your alarm is set for 5:19 AM for Suhoor.
```

### Ramadan morning

```text
Tomorrow Morning is in Ramadan.
You are waking for Suhoor, and your alarm is set for 5:19 AM.
```

### Quiet morning

```text
Tomorrow Morning is quiet.
No alarm will ring tomorrow morning. You can turn the alarm back on if you want Subh to wake you.
```

### Alarms paused

```text
Alarms are paused.
Subh will not ring until you resume alarms or choose a one-morning exception.
```

### Active Suhoor window

```text
Today Morning is planned for Suhoor.
Your Suhoor wake session is active. Tap I’m Awake for Suhoor when you are up.
```

### Active Fajr window

```text
Today Morning is for Fajr.
Your Fajr wake session is active. Tap I’m Awake for Fajr once you are up.
```

## 6. Late Fajr logging prompt placement

Late Fajr logging does not belong inside the Hero once the Hero has rolled forward to the next morning.

If Fajr prayer completion has not been logged after Fajr ends, show a separate prompt below the context card.

CTA copy:

| Time context | CTA copy |
| --- | --- |
| After Fajr ends, same calendar day | `I Prayed Fajr Earlier Today` |
| After midnight / next calendar day, before expiry | `I Prayed Fajr Yesterday Morning` |

The prompt disappears when:

- the user taps the CTA;
- Fajr prayer is logged from another valid surface;
- the next relevant wake window begins.

Expiry boundary:

| Next selected purpose | Prompt expires when |
| --- | --- |
| Fajr | next Fajr window begins |
| Suhoor | next Suhoor window begins |

## 7. Separation rules

Do not let context presentation imply:

- user selected Suhoor;
- user planned a fast;
- user completed a fast;
- user prayed Fajr;
- user missed Fajr;
- alarm is Quiet/Paused;
- delivery failed.

Those meanings come from separate resolver/log layers. The context card may state those facts only when the resolved snapshot or log state supplies them.

## 8. Acceptance criteria

1. Context is displayed separately from purpose and alarm state.
2. Context card copy is sentence-based and non-technical.
3. Context card does not use chips/tags as its primary explanation.
4. Opportunity tags do not mutate state.
5. Compact rows do not use Fajr/Suhoor/Quiet/Paused as context tags.
6. Late Fajr logging appears below the context card after Hero rollover, not inside the Hero.
7. The late logging prompt expires at the next relevant wake window if not used.
