# Subh Primary Morning Context Presentation Specification v4 — June 1 Context Action Area Reconciliation

| Field | Value |
| --- | --- |
| Canonical filename | `subh-primary-morning-context-presentation-spec-v4.md` |
| Version | 4 |
| Spec status | Active context presentation contract |
| Date | 2026-06-01 |
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

## June 1, 2026 CTA/logging reconciliation

This version is reconciled with `subh-cta-logging-and-wake-action-spec-v2.md`. If earlier text in this file conflicts with the CTA spec, use the June 1 rules below:

- Active wake CTAs live in the Hero: **I’m Awake for Suhoor** and **I’m Awake for Fajr**.
- Logging and early-awake actions live in the context-card action area, not in the Hero and not as a separate standalone CTA card.
- Ordinary system/AlarmKit dismissal does not by itself mean the user is awake. It dismisses the current alarm attempt and the Hero must advance to the next pending wake-check time when one exists.
- Only explicit awake confirmation, confirmed early-awake action, or an explicitly supported platform action mapped to awake confirmation cancels remaining wake checks as wake success.
- **I’m Awake for Fajr** and **I Prayed Fajr** must not appear simultaneously.
- Late Fajr and fast completion use compact check/X prompt rows and must distinguish ✓, ✕, and unrecorded.
- Silence/unanswered is never treated as no.

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

If Fajr prayer completion has not been logged after Fajr ends, show a compact prompt inside the context-card action area.

CTA copy:

| Time context | CTA copy |
| --- | --- |
| After Fajr ends, same calendar day | `I prayed Fajr earlier today? ✓ ✕` |
| After midnight / next calendar day, before expiry | `I prayed Fajr yesterday morning? ✓ ✕` |

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
6. Late Fajr logging appears inside the context-card action area after Hero rollover, not inside the Hero.
7. The late logging prompt expires at the next relevant wake window if not used.

---

## June 1 Addendum: Context-Card Action Area

The context card now owns logging and early-awake actions beneath its explanatory copy.

Supported context-card actions include:

- **I’m Already Awake for Suhoor** with confirmation;
- **I’m Already Awake for Fajr** with confirmation;
- **I Prayed Fajr** after the Fajr wake state has been resolved and the cooldown has passed;
- `I prayed Fajr earlier today? ✓ ✕`;
- `I prayed Fajr yesterday morning? ✓ ✕`;
- `I completed my fast today? ✓ ✕`;
- `I completed my fast yesterday? ✓ ✕`.

If several actions are available, show the highest-priority action in collapsed state and expose remaining check-ins through an expansion affordance such as **Show more check-ins**.

