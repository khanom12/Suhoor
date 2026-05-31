# Subh Context Tags Integration Addendum v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-tags-integration-addendum-v2.md` |
| Version | 2 |
| Spec status | Active context-tag integration addendum |
| Date | 2026-05-30 |
| Related specs | Index, Shared Tags, Day Purpose, Next 7, Month, Weekly Fajrcast |
| Owning domain / surface | Cross-surface context-tag integration |

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

This addendum defines how context tags integrate into the reconciled MVP without reintroducing the old mode/tag drift.

## 2. Integration rule

Context tags integrate with resolved morning snapshots as read-only presentation metadata.

They do not own:

- wake purpose;
- alarm state;
- wake execution state;
- completion state;
- pricing entitlement;
- schedule delivery.

## 3. Approved compact-tag lane

Use context/opportunity tags only:

```text
Ramadan
White Days
Eid
Arafah
Ashura
Dhul Hijjah
Shawwal
```

Avoid routine or state tags:

```text
Fajr
Suhoor
Quiet
Paused
Rings once
Fasting
Pre-Fajr
Tahajjud only
Other early worship
```

## 4. Surface integration

- Next 7 and Month use middle-lane tags.
- Weekly Fajrcast may aggregate tags.
- Detail may show chips plus explanatory copy.
- Hero should not become chip-heavy; it should prioritize state/action.

## 5. Acceptance criteria

1. Context tags are read-only metadata.
2. Tag rendering is consistent across Next 7, Month, and Weekly Fajrcast.
3. Quiet/Pause appear as status, not context tags.
4. Fajr/Suhoor appear as purpose, not context tags.
