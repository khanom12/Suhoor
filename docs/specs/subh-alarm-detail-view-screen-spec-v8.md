# Subh Alarm Detail View Screen Specification v8 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-detail-view-screen-spec-v8.md` |
| Version | 8 |
| Spec status | Active Day Detail specification |
| Date | 2026-05-30 |
| Related specs | Index, Alignment, Morning Resolution, Quick Mutation, Hero, Quiet/Pause, Shared Tags, Day Purpose |
| Owning domain / surface | Selected morning / day-detail editor |

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

The Detail screen lets the user inspect and edit one selected morning without overloading the Home Hero.

It is the primary destination from:

- tapping a Next 7 Mornings row;
- tapping a Month/list day row;
- using deeper planning affordances from Home;
- reviewing a specific morning’s context, saved alarm, Quiet/Paused/ring-once state, and fasting-purpose details.

## 2. What Detail owns

Day Detail owns:

- selected-date header;
- selected morning resolved snapshot;
- Fajr/Suhoor purpose selector;
- alarm-state control for the selected morning;
- selected-purpose alarm-time slider;
- context/opportunity card;
- Suhoor fasting-purpose controls;
- reset-to-defaults for the selected date;
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
- Do not show `Today`, `Tomorrow`, or the Home Hero relative-day label as the primary detail header.
- Do not show location in the detail hero unless needed in a subordinate troubleshooting context.
- Allow Dynamic Type wrapping without pushing the primary row downward unexpectedly.

## 4. Purpose selector

The Detail purpose selector must match Home:

```text
[ Fajr | Suhoor ]
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

After the first alarm begins for the selected morning, Detail must not expose Quiet for that executing wake.

## 6. Alarm-time slider

The slider is required when the selected morning has enough timing data to show it truthfully.

Rules:

- It is active for active Fajr/Suhoor states.
- It updates the current purpose-specific alarm config only.
- It is ghosted/read-only for Quiet and inherited Pause.
- It becomes active for ring-once while paused.
- It should use the same visual language and boundary behavior as Home.
- Releasing the slider commits immediately through the shared mutation contract.

## 7. Fajr purpose behavior

Fajr is the default year-round wake purpose unless Suhoor/Ramadan/explicit user plan overrides it.

Typical Fajr behavior:

```text
Wake purpose: Fajr
Wake anchor: relative to Fajr end
Default example: 30 min before Fajr ends
Primary completion CTA after Fajr wake acknowledgement: I prayed Fajr
```

Fajr purpose does not require fasting-purpose controls. Fasting opportunities may still be shown as context, but they are not active fast intentions unless the user selects Suhoor or another durable fasting-intention source applies.

## 8. Suhoor purpose behavior

Suhoor means before-Fajr wake for suhoor/fasting.

Typical Suhoor behavior:

```text
Wake purpose: Suhoor
Wake anchor: relative to Fajr begins
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
Fasting today: logged | not logged | unavailable | future completion pending
Fajr wake: acknowledged | unconfirmed | no response | issue
Fajr prayer: prayed | not logged | window ended
```

After Fajr begins, Detail follows the same action order as Home:

```text
I’m awake for Fajr
→ anti-double-tap delay
→ I prayed Fajr
```

`I prayed Fajr` should not be the first Fajr-phase CTA if the Fajr wake check is still unconfirmed.

## 10. Context and opportunity card

The context card explains day meaning separately from wake purpose and alarm state.

It may show:

- Ramadan context;
- Eid/forbidden-fast context;
- White Days;
- Monday/Thursday opportunity;
- Arafah/Ashura/Dhul Hijjah/Shawwal context where supported;
- no-opportunity explanatory copy.

It must not use opportunity tags to imply that the user has planned or completed a fast.

Example patterns:

```text
This morning has Sunnah fasting opportunities: White Days.
No special fasting opportunity is scheduled for this morning.
Quiet is on. Subh won’t ring, but your Fajr/Suhoor plan is saved.
Alarms are paused. Subh won’t ring unless you choose Rings this morning only.
```

## 11. Reset to Defaults

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

## 12. Persistence

Expected date-specific persistence may include:

```text
selected wake purpose: Fajr | Suhoor
Fajr alarm config override
Suhoor alarm config override
DateAlarmOverride.quiet
DateAlarmOverride.ringDespitePause
fasting-purpose override
reset/default state marker if needed for reconciliation
```

Opening a generated/default day and leaving without changes should not create unnecessary durable records.

## 13. Accessibility

- Announce the screen as Detail for the selected morning/date.
- Announce Gregorian and Hijri date.
- Announce selected purpose as Fajr or Suhoor.
- Announce alarm state separately: active time, Quiet, Alarms paused, rings once, setup, or issue.
- The purpose selector exposes only Fajr/Suhoor selected state.
- The alarm-state button exposes its current state and action.
- Opportunity chips are read as context, not selected purpose.
- Dynamic Type must not clip date, primary state, selector, slider labels, or context card copy.

## 14. Acceptance criteria

1. Detail uses `Fajr | Suhoor`, matching Home.
2. Quiet is not a purpose segment.
3. Pause is not a purpose segment.
4. Non-fasting before-Fajr options are not exposed in MVP.
5. Quiet/Paused/ring-once are alarm-state controls separate from purpose.
6. The slider mutates only the current purpose-specific alarm config.
7. Switching purpose preserves the other purpose’s alarm config.
8. Quiet preserves purpose, alarm settings, context, and logs.
9. Inherited Pause can show ring-once/resume options without creating manual Quiet.
10. Reset applies immediately and does not change global Pause.
11. Next 7 and Month rows navigate here for editing instead of exposing inline Quiet/Pause controls.
12. For Suhoor mornings, Detail shows `I’m awake for Fajr` before `I prayed Fajr` when Fajr wake is unconfirmed.
