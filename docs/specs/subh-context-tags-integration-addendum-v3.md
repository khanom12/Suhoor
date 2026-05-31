# Subh Context Tags Integration Addendum v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-tags-integration-addendum-v3.md` |
| Version | 3 |
| Spec status | Active context-tag integration addendum |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Shared Tags, Day Purpose, Next 7, Month, Weekly Fajrcast |
| Owning domain / surface | Cross-surface context-tag integration |

## May 31, 2026 update status

Version 3 aligns context tags with the redesigned Next 7 Mornings row and the sentence-based context card.

## 1. Purpose

This addendum defines how context tags integrate into the reconciled MVP without reintroducing old mode/tag drift.

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

Use specific context/opportunity tags only:

```text
Monday
Thursday
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
Fasting Opportunity
Pre-Fajr
Tahajjud only
Other early worship
```

`Awake for Fajr` and `Awake for Suhoor` may appear in Next 7 as a purpose line above the tag lane. They are not tags.

## 4. Surface integration

- Context card uses sentence-based explanatory copy and should not become chip-heavy.
- Next 7 uses a purpose line plus compact opportunity tags underneath.
- Month uses compact opportunity/context tags unless a later Month redesign adds a separate purpose line.
- Weekly Fajrcast may aggregate tags.
- Detail may show explanatory copy and/or chips as long as it does not imply intent/completion without resolver data.
- Hero should not become chip-heavy; it prioritizes state/action.

## 5. Acceptance criteria

1. Context tags are read-only metadata.
2. Tag rendering is consistent in meaning across Next 7, Month, and Weekly Fajrcast.
3. Quiet/Pause appear as status/control, not context tags.
4. Fajr/Suhoor appear as wake purpose, not context tags.
5. The context card uses sentences, not tags, as its main explanation.
