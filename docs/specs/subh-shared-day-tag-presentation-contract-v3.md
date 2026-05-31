# Subh Shared Day Tag Presentation Contract v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-shared-day-tag-presentation-contract-v3.md` |
| Version | 3 |
| Spec status | Active shared tag/status presentation contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Day Purpose, Next 7, Month, Weekly Fajrcast, Primary Context, Hero, Detail |
| Owning domain / surface | Shared row/card tag semantics |

## May 31, 2026 update status

Version 3 updates compact row semantics for the redesigned Next 7 Mornings row. `Awake for Fajr` / `Awake for Suhoor` may appear as a purpose line above tags in Next 7. This does not make Fajr/Suhoor opportunity tags.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible planning selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
```

## 1. Purpose

This spec prevents Subh’s compact row/card surfaces from mixing three different ideas:

```text
Opportunity/context tag
Wake purpose line
Alarm state/status
```

The May 31 rule for Next 7 Mornings is:

```text
Left zone = wake time or Quiet + date
Middle top line = Awake for Fajr / Awake for Suhoor
Middle tag lane = specific opportunity/context tags only
Right zone = Quiet toggle or truthful disabled/replaced state
```

For Month/list and Weekly Fajrcast surfaces, the earlier compact model remains: opportunity/context tags stay separate from status and mutation.

## 2. Opportunity/context tags

Allowed opportunity/context tags include specific calendar/date meanings such as:

```text
Monday
Thursday
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

Do not use generic tags such as:

```text
Fasting Opportunity
```

Instead, show the specific opportunity such as `Monday`, `Thursday`, `White Days`, or `Ramadan`.

## 3. Not opportunity tags in MVP

Do not show these as routine opportunity tags:

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

- Fajr/Suhoor are wake purposes and may be shown as a purpose line, not as tags.
- Quiet/Paused/Rings once are alarm states.
- Fasting can be an intention/outcome, but compact row tags should not blur it with opportunity context.
- Non-fasting before-Fajr concepts are deferred.

## 4. Alarm state / status presentation

Compact rows may use status text, icons, or controls for alarm state:

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

In Next 7 Mornings, Quiet appears in the left zone when enabled and the right zone toggle appears off. This is not a tag.

## 5. Surface rules

| Surface | Purpose presentation | Tag lane | Status/control | Mutation |
| --- | --- | --- | --- | --- |
| Next 7 Mornings | `Awake for Fajr/Suhoor` line | Specific opportunity/context tags underneath | Left wake time/Quiet; right Quiet toggle | Quiet toggle only; row body opens Detail |
| Month/list rows | Not routine inline purpose unless later specified | Opportunity/context tags only | Wake time or alarm state | Row navigates to Detail |
| Weekly Fajrcast | Summary only | Opportunity/context summary only | Inspection status if needed | No mutation |
| Day Detail | Purpose selector/control | Context card may explain fully | Detail controls | Mutates through shared contract |
| Home Hero | Purpose selector in Slot 6 | Does not use compact tag model | Slot 3/5 state copy | Mutates through Slot 3/6 |

## 6. Tag priority

When space is limited:

1. Show high-significance calendar context first: Ramadan, Eid/forbidden fast, Arafah/Ashura.
2. Then show specific Sunnah opportunities such as White Days.
3. Then show Monday/Thursday if product wants those visible in the planning row.
4. Never add Fajr/Suhoor/Quiet/Paused as opportunity tags to fill space.

## 7. Accessibility

Tags should be read as context, for example:

```text
Wake purpose: Awake for Suhoor. Context: Monday. Alarm: 4:55 AM.
```

Do not announce:

```text
Selected mode: Quiet tag.
```

## 8. Acceptance criteria

1. Next 7 may show `Awake for Fajr/Suhoor` as a purpose line, not a tag.
2. Next 7, Month, and Weekly middle/tag lanes do not show Fajr/Suhoor/Quiet/Paused as opportunity tags.
3. Quiet appears only as alarm state/status/control, not as context tag.
4. Paused appears only as alarm state/status/control, not as context tag.
5. Opportunity tags do not create wake-intention, fasting-intention, or completion records.
6. Weekly Fajrcast remains inspection-only.
7. Next 7 right-column Quiet toggle is the only approved inline row mutation from the May 31 update.
