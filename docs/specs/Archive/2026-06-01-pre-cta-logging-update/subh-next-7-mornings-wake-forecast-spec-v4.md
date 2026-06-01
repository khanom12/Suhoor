# Subh Next 7 Mornings Wake Forecast Specification v4 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-next-7-mornings-wake-forecast-spec-v4.md` |
| Version | 4 |
| Spec status | Active Home planning/forecast card spec |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Hero, Detail, Morning Resolution, Shared Tags, Month, Weekly Fajrcast |
| Owning domain / surface | Home / Plan ahead / Next 7 Mornings |

## May 31, 2026 update status

Version 4 supersedes the May 30 rule that Next 7 Mornings had no inline mutation. The May 31 walkthrough approves one narrow inline mutation: a right-column per-morning Quiet toggle. All other edits still navigate to Day Detail.

This spec must not be used to reintroduce Quiet as a wake purpose. Quiet remains alarm delivery suppression for one morning.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible purpose selector order elsewhere: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

## 1. Purpose

Next 7 Mornings gives the user a compact forecast of upcoming resolved mornings and a lightweight way to quiet or re-enable a specific morning.

It answers:

```text
What are the next seven mornings, when will Subh ring, why am I waking, and can I make a morning quiet?
```

## 2. Placement and collapse behavior

- The section label should use `Plan ahead`.
- The card/list label is `Next 7 Mornings`.
- It is collapsed by default unless the app has a product-approved reason to expand it.
- It should appear below the primary Hero and supporting planning context.
- Do not use `Next 10` in active MVP copy.

## 3. Seven-morning horizon

The list contains:

```text
Immediate/current relevant morning + following six mornings
```

The same seven visible dates should be available to Weekly Fajrcast for inspection-only summary.

## 4. Row composition

Each row has three zones:

| Zone | Content | Notes |
| --- | --- | --- |
| Left | Wake time or `Quiet`; date underneath | Wake time/Quiet is primary. Date is secondary. |
| Middle | `Awake for Fajr` or `Awake for Suhoor`; opportunity tags underneath | Purpose line is not a tag. Tags are specific opportunity/context labels. |
| Right | Quiet toggle | Toggle on = alarm will ring. Toggle off = morning is Quiet. |

## 5. Left zone: wake time / Quiet + date

When the alarm is active:

```text
5:19 AM
Mon, Jun 1
```

When the morning is Quiet:

```text
Quiet
Mon, Jun 1
```

Typography requirements:

- The wake time remains the most prominent value in the row and should keep the same font/style/size as the previous time treatment.
- The date appears below the time and is visually secondary.
- The date treatment should be similar in prominence to the AM/PM portion of the time: smaller, lighter, and less dominant.
- If Quiet is on, show `Quiet` instead of showing the wake time as if an alarm will ring.

## 6. Middle zone: purpose line and opportunity tags

Top line:

```text
Awake for Fajr
Awake for Suhoor
```

This line communicates wake purpose and is not an opportunity tag.

Below the purpose line, show specific opportunity/context tags only, such as:

```text
Monday
Thursday
White Days
Ramadan
Arafah
Ashura
Eid
```

Do not show generic tags such as:

```text
Fasting Opportunity
```

Do not show these as opportunity tags:

```text
Fajr
Suhoor
Quiet
Paused
Rings once
Fasting
```

## 7. Right zone: Quiet toggle

The right column contains the per-row Quiet toggle.

Rules:

- Toggle on means the row’s resolved delivery is active and Subh will ring if permissions/setup allow it.
- Toggle off means the row is Quiet and Subh will not ring for that specific morning.
- Toggling off emits the shared `setQuiet(targetMorning)` mutation.
- Toggling on emits the shared `clearQuiet(targetMorning)` mutation.
- The toggle must not change wake purpose, fasting purpose, global Pause, or alarm time.
- The toggle should be designed to prevent accidental changes through adequate spacing, hit target clarity, and readable state feedback.

If global Pause is inherited for a row, the row should show the paused state truthfully. The row Quiet toggle should be disabled or replaced by the paused state unless a later Pause-specific design approves a combined override model. `Ring tomorrow only` / `Ring this morning only` remains the approved Pause exception path.

## 8. Mutation model

Rows are still primarily navigation surfaces. The May 31 update approves only the right-column Quiet toggle as inline mutation.

| Interaction | Behaviour |
| --- | --- |
| Tap row body | Opens Day Detail for that morning. |
| Tap Quiet toggle off | Sets one-morning Quiet. |
| Tap Quiet toggle on | Clears one-morning Quiet and re-resolves active/paused/setup state. |
| Change purpose | Navigate to Day Detail or Hero; not inline here. |
| Change alarm time | Navigate to Day Detail or Hero; not inline here. |
| Change fasting purpose | Navigate to Day Detail; not inline here. |
| Pause/resume globally | Settings / Wake Alarms or approved paused-state action; not inline here. |

The row must not create durable records merely by being displayed. Durable records are created only by explicit user mutation or by execution/logging events.

## 9. Quiet/Pause display

Quiet row:

```text
Left: Quiet + date
Middle: Awake for Fajr/Suhoor + opportunity tags
Right: toggle off
```

Paused row:

```text
Left: Paused or saved time according to the approved paused-row treatment
Middle: Awake for Fajr/Suhoor + opportunity tags
Right: paused-state indicator or disabled Quiet toggle
```

Rings-once row:

```text
Left: wake time + date
Middle: Awake for Fajr/Suhoor + opportunity tags
Right/status: Rings once indicator where space allows
```

## 10. Row examples

### Alarm on, Fajr

```text
Left:   5:19 AM
        Mon, Jun 1
Middle: Awake for Fajr
Right:  Quiet toggle on
```

### Alarm on, Suhoor, Monday opportunity

```text
Left:   4:55 AM
        Mon, Jun 1
Middle: Awake for Suhoor
        Monday
Right:  Quiet toggle on
```

### Quiet, Thursday opportunity

```text
Left:   Quiet
        Thu, Jun 4
Middle: Awake for Fajr
        Thursday
Right:  Quiet toggle off
```

### Ramadan Suhoor

```text
Left:   4:45 AM
        Tue, Mar 3
Middle: Awake for Suhoor
        Ramadan
Right:  Quiet toggle on
```

## 11. Hydration and persistence

Next 7 consumes canonical Morning Resolution output. It must not create durable records for generated/default days just by displaying them.

Future durable edits made in Day Detail should hydrate into Next 7 when their date enters the visible horizon.

Inline Quiet toggle mutations must flow through the shared mutation contract and then re-render from Morning Resolution output. The row must not locally fake state without resolver confirmation.

## 12. Accessibility

- The wake time/Quiet value, date, purpose line, tags, and toggle must have a logical reading order.
- The Quiet toggle label must make the consequence clear, e.g. `Alarm on for Monday, June 1` / `Quiet for Monday, June 1`.
- Dynamic Type must not cause the date, purpose line, or toggle to run off screen.
- When horizontal space is tight, preserve wake time/Quiet and toggle first; tags may truncate or collapse according to the Shared Tags priority rule.

## 13. Acceptance criteria

1. The card is called `Next 7 Mornings`.
2. It shows seven mornings, not ten.
3. Each row places wake time or `Quiet` in the left column with date underneath.
4. Date is visually secondary to wake time/Quiet.
5. Each row shows `Awake for Fajr` or `Awake for Suhoor` above opportunity tags.
6. Opportunity tags are specific context labels such as Monday, Thursday, White Days, Ramadan, Arafah, or Ashura.
7. Rows do not use generic `Fasting Opportunity` tags.
8. Rows do not use Fajr/Suhoor/Quiet/Paused as opportunity tags.
9. Each row includes a right-column Quiet toggle for one-morning Quiet, except where inherited Pause/setup states require a disabled/replaced control.
10. The Quiet toggle mutates only `DateAlarmOverride.quiet` for the target morning.
11. Row-body taps still navigate to Day Detail.
12. Weekly Fajrcast uses the same seven visible dates and remains inspection-only.
