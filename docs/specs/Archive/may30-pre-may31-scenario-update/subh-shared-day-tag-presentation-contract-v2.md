# Subh Shared Day Tag Presentation Contract v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-shared-day-tag-presentation-contract-v2.md` |
| Version | 2 |
| Spec status | Active shared tag/status presentation contract |
| Date | 2026-05-30 |
| Related specs | Index, Day Purpose, Next 7, Month, Weekly Fajrcast, Primary Context, Hero, Detail |
| Owning domain / surface | Shared row/card tag semantics |

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

This spec prevents Subh’s compact row/card surfaces from mixing three different ideas:

```text
Opportunity/context tag
Wake purpose
Alarm state/status
```

The final rule for MVP is:

```text
Middle lane = opportunity/context tags only.
Trailing/right status = alarm state or saved wake time.
Purpose = implied by saved time/detail or shown in detail, not as routine middle-lane tag.
```

## 2. Opportunity/context tags

Allowed middle-lane tags include calendar/date meanings such as:

```text
Ramadan
White Days
Arafah
Ashura
Dhul Hijjah
Shawwal Six
Eid
Tashreeq
Travel / local context if later supported
```

These tags mean the date has context or an opportunity. They do not by themselves mean the user selected Suhoor, planned a fast, completed a fast, or changed the wake alarm.

## 3. Not middle-lane tags in MVP

Do not show these as routine middle-lane opportunity tags:

```text
Fajr
Suhoor
Quiet
Paused
Rings once
Fasting
Tahajjud only
Other early worship
Pre-Fajr
Early
Fast
```

Rationale:

- Fajr/Suhoor are wake purposes.
- Quiet/Paused/Rings once are alarm states.
- Fasting can be an intention/outcome, but compact row tags should not blur it with opportunity context.
- Non-fasting before-Fajr concepts are deferred.

## 4. Trailing/right status

Compact rows may use trailing/right status text or icons for alarm state:

```text
5:42 AM
4:51 AM
Quiet
Paused
Rings once
Turn on alarms
Set location
Alarm issue
```

`Paused` is approved as a compact-row status. Hero should use `Alarms paused`.

## 5. Surface rules

| Surface | Middle lane | Trailing/right status | Mutation |
| --- | --- | --- | --- |
| Next 7 Mornings | Opportunity/context tags only | Wake time or alarm state | Row navigates to Detail |
| Month/list rows | Opportunity/context tags only | Wake time or alarm state | Row navigates to Detail |
| Weekly Fajrcast | Opportunity/context summary only | Inspection status if needed | No mutation |
| Day Detail | Full context card may explain purpose/status separately | Detail controls | Mutates through shared contract |
| Home Hero | Does not use compact middle-lane tag model | Slot 3/5 state copy | Mutates through Slot 3/6 |

## 6. Tag priority

When space is limited:

1. Show high-significance calendar context first: Ramadan, Eid/forbidden fast, Arafah/Ashura.
2. Then show specific Sunnah opportunities such as White Days.
3. Omit routine Monday/Thursday in compact rows unless the product explicitly promotes them for a given context.
4. Never add Fajr/Suhoor/Quiet/Paused as middle tags to fill space.

## 7. Accessibility

Tags should be read as context, for example:

```text
Context: Ramadan, White Days. Alarm: Quiet.
```

Do not announce:

```text
Selected mode: Quiet tag.
```

## 8. Acceptance criteria

1. Next 7 and Month middle lanes do not show Fajr/Suhoor/Quiet/Paused routine tags.
2. Quiet appears only as trailing status or Detail/Hero alarm state.
3. Paused appears only as trailing status or Detail/Hero alarm state.
4. Opportunity tags do not create wake-intention, fasting-intention, or completion records.
5. Weekly Fajrcast remains inspection-only.
6. Row surfaces navigate to Detail for edits.
