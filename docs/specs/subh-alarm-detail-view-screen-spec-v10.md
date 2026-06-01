# Subh Alarm Detail View Screen Specification v10 — June 1 CTA and Context Action Reconciliation

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-detail-view-screen-spec-v10.md` |
| Version | 10 |
| Spec status | Active Day Detail specification |
| Date | 2026-06-01 |
| Related specs | Index, May 31 Scenario Walkthrough, Alignment, Morning Resolution, Quick Mutation, Hero, Quiet/Pause, Shared Tags, Day Purpose |
| Owning domain / surface | Selected morning / day-detail editor |

## May 31, 2026 update status

Version 9 aligns Detail with the May 31 morning-state framework: visible selector order is `Suhoor | Fajr`, context copy is sentence-based, wake-check boundaries use the 5-minute algorithm, and Fajr wake acknowledgement remains separate from Fajr prayer completion.

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

The Detail screen lets the user inspect and edit one selected morning without overloading the Home Hero.

It is the primary destination from:

- tapping a Next 7 Mornings row body;
- tapping a Month/list day row;
- using deeper planning affordances from Home;
- reviewing a specific morning’s context, saved alarm, Quiet/Paused/ring-once state, and fasting-purpose details.

Next 7 now includes a narrow inline Quiet toggle, but Detail remains the primary editor for purpose, time, fasting-purpose, reset, and deeper review.

## 2. What Detail owns

Day Detail owns:

- selected-date header;
- selected morning resolved snapshot;
- Suhoor/Fajr purpose selector;
- alarm-state control for the selected morning;
- selected-purpose alarm-time slider;
- context/opportunity card;
- Suhoor fasting-purpose controls;
- reset-to-defaults for the selected date;
- late Fajr logging when routed from a log/history prompt;
- navigation back to the source surface.

It does not own global Pause settings except to display inherited Pause and offer one-morning exception/resume actions where approved.

## 3. Header / selected-date line

The detail hero shows the selected date instead of the Home Hero’s relative-morning/location emphasis.

Preferred format:

```text
Friday, May 1 · 14 Dhul Qi’dah
```

Rules:

- Use Gregorian date + centered dot + Hijri date.
- Place the date directly above the primary alarm-state/wake-time row.
- Do not show `Today`, `Tomorrow`, `Today Morning`, or `Tomorrow Morning` as the primary detail header.
- Do not show location in the detail hero unless needed in a subordinate troubleshooting context.
- Allow Dynamic Type wrapping without pushing the primary row downward unexpectedly.

## 4. Purpose selector

The Detail purpose selector must match Home visible order:

```text
[ Suhoor | Fajr ]
```

This selector mutates `WakePurpose` only.

It must not include:

```text
Quiet
Pause
Pre-Fajr
Early
Fast mode
Tahajjud only
Other early worship
```

## 5. Alarm-state control

Day Detail uses a separate alarm-state control/button/sheet for whether Subh rings.

Possible resolved states:

```text
Active alarm time
Quiet
Alarms paused
Rings this morning only / Rings tomorrow only
Turn on alarms
Set location
Alarm issue
```

State actions:

| Current state | Allowed Detail actions |
| --- | --- |
| Active | Set Quiet for this morning; change time; reset defaults |
| Quiet | Turn alarm on; change preserved purpose/time; reset defaults |
| Alarms paused | Ring this morning/tomorrow only; resume alarms; keep paused |
| Rings once while paused | Return to paused for this morning; resume all alarms; change time |
| Blocked/setup | Open relevant setup path; preserve saved plan |
| Issue | Review issue; preserve saved plan |
| Active execution | Primary action remains `I’m Awake`; approved Quiet cancellation may be exposed only with explicit confirmation |

## 6. Alarm-time slider

The slider is required when the selected morning has enough timing data to show it truthfully.

Rules:

- It is active for active Fajr/Suhoor states.
- It updates the current purpose-specific alarm config only.
- It is ghosted/read-only for Quiet and inherited Pause.
- It becomes active for ring-once while paused.
- It should use the same visual language and boundary behavior as Home.
- Releasing the slider commits immediately through the shared mutation contract.
- While dragging, the primary wake time and helper copy update live and in sync.

Boundary rules:

```text
Earliest newly scheduled wake time = current time + 1 minute
Latest wake time = relevant window end - 5 minutes
Latest new session creation time = relevant window end - 6 minutes
```

## 7. Fajr purpose behavior

Fajr is the default year-round wake purpose unless Suhoor/Ramadan/explicit user plan overrides it.

Typical Fajr behavior:

```text
Wake purpose: Fajr
Relevant window: Fajr begins → Fajr ends
Default example: 30 min before Fajr ends
Wake acknowledgement CTA: I’m Awake / I’m Awake for Fajr
Prayer completion CTA after delay: I Prayed Fajr
```

Fajr wake acknowledgement does not log prayer completion. Fasting opportunities may still be shown as context, but they are not active fast intentions unless the user selects Suhoor or another durable fasting-intention source applies.

## 8. Suhoor purpose behavior

Suhoor means before-Fajr wake for suhoor/fasting.

Typical Suhoor behavior:

```text
Wake purpose: Suhoor
Relevant window: last-third-of-night start → Fajr begins
Default example: 30 min before Fajr begins
Fasting-purpose context: visible when applicable
```

Default fasting-purpose resolution:

| Context | Detail behavior |
| --- | --- |
| Ramadan | Lock/default to Ramadan fast where Ramadan support applies. |
| Sunnah opportunity exists | Default to applicable opportunity/ies unless user selects a different fasting purpose. |
| No specific opportunity | Default to Voluntary fast. |
| Qada/Vow/Kaffarah/Other fast selected | Show selected explicit fasting purpose. |
| Eid/forbidden fast day | Do not silently allow fasting; show appropriate unavailability/warning behavior. |

Do not expose non-fasting before-Fajr options in MVP.

## 9. Suhoor-to-Fajr handoff status

For a Suhoor-selected morning, Detail must not collapse Suhoor wake, Fajr wake, fasting intention, and Fajr prayer into one completion flag.

Display or expose these separately when relevant:

```text
Suhoor wake: acknowledged | no response | not started | issue
Fast completion: not eligible yet | prompt pending after Maghrib | completed | not completed | unrecorded | expired unresolved
Fajr-start event: scheduled | fired | dismissed | not applicable
post-Suhoor Fajr slider activation wake: not requested | scheduled | acknowledged | no response | issue
Fajr prayer: prayed | not logged | late logged | prompt expired
```

After Suhoor acknowledgement, Subh does not automatically create a Fajr wake-check session. A single Fajr-start event may occur at Fajr begins. A post-Suhoor Fajr wake session is created only if the user commits a later Fajr slider value.

If a post-Suhoor Fajr slider activation wake session is active, Detail follows the same action order as Home:

```text
I’m Awake for Fajr
→ anti-double-tap delay
→ I Prayed Fajr
```

`I Prayed Fajr` should not be the first Fajr-phase CTA if the Fajr wake check is still unconfirmed.

## 10. Context and opportunity card

The context card explains day meaning separately from wake purpose and alarm state.

It uses sentence-based copy, not tags as the primary explanation.

It may explain:

- Ramadan context;
- Eid/forbidden-fast context;
- White Days;
- Monday/Thursday opportunity;
- Arafah/Ashura/Dhul Hijjah/Shawwal context where supported;
- whether the user has planned to fast;
- selected wake purpose;
- Quiet/Pause state;
- no-opportunity explanatory copy.

It must not use opportunity tags to imply that the user has planned or completed a fast.

Example patterns:

```text
Tomorrow Morning is a Monday fasting opportunity.
You have planned to fast, so your alarm is set for 5:19 AM for Suhoor.

Tomorrow Morning is quiet.
No alarm will ring tomorrow morning, but your Fajr/Suhoor plan is saved.

Alarms are paused.
Subh won’t ring unless you choose Rings this morning only.
```

## 11. Late Fajr logging

After Fajr end, the Home Hero rolls to the next morning. If the user has not logged Fajr prayer completion, the late prompt appears inside the context-card action area and may route to Detail/logging state.

CTA copy:

```text
I prayed Fajr earlier today? ✓ ✕
I prayed Fajr yesterday morning? ✓ ✕
```

The prompt disappears when logged, when dismissed by expiry, or when the next relevant wake window begins.

## 12. Reset to Defaults

`Reset to Defaults` applies immediately for the selected date.

It should clear date-specific overrides for:

- selected purpose override;
- selected-purpose alarm-time override;
- date Quiet;
- ring-once exception;
- explicit fasting-purpose override, if date-specific;
- other date-specific planning overrides owned by this detail editor.

It must not change global Pause.

`Done` is a navigation/exit action, not a save boundary for MVP.

## 13. Persistence

Expected date-specific persistence may include:

```text
selected wake purpose: Fajr | Suhoor
visible selector order: Suhoor | Fajr
Fajr alarm config override
Suhoor alarm config override
DateAlarmOverride.quiet
DateAlarmOverride.ringDespitePause
fasting-purpose override
fajrWakeAcknowledgedAt
fajrPrayerLoggedAt
lateFajrPromptState
reset/default state marker if needed for reconciliation
```

Opening a generated/default day and leaving without changes should not create unnecessary durable records.

## 14. Accessibility

- Announce the screen as Detail for the selected morning/date.
- Announce Gregorian and Hijri date.
- Announce alarm state separately: active time, Quiet, Alarms paused, rings once, setup, or issue.
- The purpose selector exposes only Suhoor/Fajr selected state.
- Dynamic Type must not clip date, primary state, selector, slider labels, or context card copy.

## 15. Acceptance criteria

1. Detail uses `Suhoor | Fajr`, matching Home visible selector order.
2. Quiet is not a purpose segment.
3. Pause is not a purpose segment.
4. Detail edits selected morning only unless explicitly invoking global Pause/resume.
5. Quiet/Paused/ring-once are alarm-state controls separate from purpose.
6. Fajr and Suhoor alarm settings remain independently stored.
7. Suhoor fasting-purpose choices remain under Suhoor, not top-level wake modes.
8. Quiet preserves purpose, alarm settings, context, and logs.
9. Inherited Pause can show ring-once/resume options without creating manual Quiet.
10. Reset applies immediately and does not change global Pause.
11. Next 7 row body navigates here for full editing, while the Next 7 Quiet toggle may mutate one-morning Quiet inline.
12. For Suhoor mornings, Detail distinguishes Suhoor wake, Fajr-start event, slider-activated Fajr wake checks after Suhoor, and Fajr prayer completion.
13. `I’m Awake for Fajr` does not log Fajr prayer completion.
14. Late Fajr logging uses the approved context-card action-area prompt copy.

---

## June 1 Addendum: Detail View CTA Alignment

Day Detail must mirror the Home resolution rules:

- active wake acknowledgement remains purpose-specific and belongs to the wake execution surface;
- context-card/action-area logging uses compact check/X rows;
- early-awake actions require confirmation;
- ordinary dismissal does not resolve wake success;
- post-Suhoor Fajr behaviour is shown through the Fajr state and slider, not through a separate **Set Fajr Wake Alarm** CTA.

If the Detail view shows active wake state, it must use the same next-pending-attempt time as the Home Hero.

