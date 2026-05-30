# Subh Context and Tags Integration Addendum

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-tags-integration-addendum-v1.md` |
| Version | 1 |
| Spec status | Draft; surgical integration addendum for existing working specs |
| Date | 2026-05-17 |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-primary-morning-context-presentation-spec-v1.md`, `subh-shared-day-tag-presentation-contract-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md`, `subh-weekly-fajrcast-card-spec-v14.md` |
| Owning domain / surface | Cross-spec integration and no-drift patch guidance |
| Implementation audit status | Needs implementation audit |

## Purpose

Provide a controlled, additive integration path for the new Primary Morning Context and Shared Day Tag Presentation specs without rewriting unrelated behavior or weakening the existing source-of-truth spine.

This addendum is intentionally surgical. It does not replace the current Morning Resolution, Day Purpose, Hero, Alarm Detail, Next 7 Mornings, or Weekly Fajrcast specs. It adds the missing presentation layer and tells each existing spec how to consume it.

---

## Integrity rules for this pass

1. Do not create a second morning resolver.
2. Do not create a second opportunity resolver.
3. Do not derive observances from SwiftUI views.
4. Do not remove existing opportunity/intention/outcome/credit separation.
5. Do not remove Next 7 Mornings row-layout requirements.
6. Do not remove Weekly Fajrcast chart behavior.
7. Do not remove Hero wake-boundary, slider, relation/status, or quick-mode rules.
8. Do not remove Alarm Detail editing controls; only route its context copy through the shared presentation module.
9. Do not collapse Qada, Vow, Kaffarah, Other fast, Ramadan, and optional Sunnah opportunities into one generic `fasting` state.
10. Do not let opportunity-only dates become Suhoor or completion requirements.
11. Do not let Quiet erase underlying day meaning.
12. Do not let tags become analytics truth.

---

## New specs to add

Add these two specs to the active Desktop working-spec corpus:

```text
subh-primary-morning-context-presentation-spec-v1.md
subh-shared-day-tag-presentation-contract-v1.md
```

Recommended reading order insertion:

```text
1. 00-subh-spec-index-v3.md
2. subh-morning-resolution-contract-state-ownership-spec-v3.md
3. subh-day-purpose-opportunity-resolution-spec-v1.md
4. subh-shared-day-tag-presentation-contract-v1.md
5. subh-primary-morning-context-presentation-spec-v1.md
6. surface specs: Hero, Alarm Detail, Next 7 Mornings, Weekly Fajrcast
```

---

## Patch A — Specification Index

Add the two new specs to the canonical spec list.

Suggested rows:

```md
| `subh-shared-day-tag-presentation-contract-v1.md` | 1 | Shared tag/chip presentation across Home, Day Detail, Next 7 Mornings, Weekly Fajrcast, and future calendar surfaces | Needs implementation audit |
| `subh-primary-morning-context-presentation-spec-v1.md` | 1 | Shared Home and Day Detail day-meaning context presentation | Needs implementation audit |
```

Add this source-of-truth note:

```md
## Primary Morning Context / Shared Tag Alignment Decision

The active MVP spec set now treats day context presentation as a shared presentation layer rather than a separate resolver.

Rules:
1. `ResolvedDayPurpose` remains the source for opportunity, intention, required action, and credit separation.
2. Shared tag presentation consumes resolved opportunity/intention outputs and does not create analytics truth.
3. The Primary Morning Context module consumes the same resolved payload on Home and Day Detail.
4. The Hero owns wake execution copy. The Primary Morning Context owns day meaning and selected-purpose explanation.
5. Alarm Detail must not maintain a separate opportunity/context-copy engine.
```

Do not change pricing, Fajr calculation, alarm delivery, or early-worship boundary entries as part of this patch.

---

## Patch B — Day Purpose / Opportunity Resolution

Add the following addendum after the existing MVP Suhoor Alignment Addendum.

```md
## Primary Context and Shared Tag Presentation Addendum

This addendum is normative for presentation integration and supersedes lower UI-representation prose only where it implies that each surface should independently assemble context copy or tag meaning.

- `ResolvedDayPurpose` remains the domain source for day meaning, observance opportunities, resolved intention, wake classification, required actions, and analytics credits.
- Presentation surfaces must not use raw `DayTag` values as the sole source of user-facing meaning.
- A presentation adapter may derive `SharedDayTagPresentation` and `PrimaryMorningContextPresentation` from `ResolvedDayPurpose`, but it must not change the resolved day purpose.
- Opportunity-only dates remain opportunities. They do not become Suhoor, planned fasts, fast-completion requirements, or completed credits unless the resolved intention says so.
- Quiet remains an overlay. It may suppress delivery and prompts, but it must not erase the underlying day meaning in expanded/detail context.
- If `ResolvedDayContext` remains for compatibility, it should increasingly derive from `ResolvedDayPurpose` rather than competing with it.
```

Add this implementation task under Presentation:

```md
- [ ] Expose or derive `SharedDayTagPresentation` for compact and expanded surfaces.
- [ ] Expose or derive `PrimaryMorningContextPresentation` for Home and Day Detail.
- [ ] Add tests proving that opportunity-only, Qada-on-opportunity, Ramadan, forbidden-day, and Quiet-overlay cases produce consistent context presentation across surfaces.
```

Do not rewrite the domain model unless implementation proves a missing field is required.

---

## Patch C — Morning Hero

Add the following addendum after the existing MVP Suhoor Alignment Addendum or v15 alignment section.

```md
## Primary Morning Context Boundary Addendum

This addendum is normative for Home composition.

- The Morning Hero owns wake execution presentation: wake time, boundary visual, relation/status line, quick mode selector, and wake-time adjustment.
- The Primary Morning Context module owns day meaning and selected-purpose explanation below the Hero.
- The Hero must not absorb the Primary Morning Context module's role by adding long observance explanations or tag clusters into the hero stack.
- The Primary Morning Context module must not repeat the Hero relation/status line such as `Wake up {X} min before Fajr ends`, `Wake up {X} min before Fajr begins`, or `No alarm will ring for tomorrow`.
- Home order is: Hero, Primary Morning Context, Next 7 Mornings, Weekly Fajrcast.
- Hero quick-mode changes still emit shared mutation commands and then consume the re-resolved snapshot. The context module updates from that same snapshot.
```

Do not alter the hero slider, boundary visual, selector animation, red-warning threshold, location line, hidden date-line doctrine, or wake relation/status copy in this patch.

---

## Patch D — Alarm Detail View

Add the following addendum after the existing MVP Suhoor Alignment Addendum.

```md
## Primary Morning Context Reuse Addendum

This addendum is normative for v8-style alignment and supersedes lower context-card sections where they describe a separate Alarm Detail-only context-copy engine or legacy non-MVP Pre-Fajr/Tahajjud/Other early worship controls.

- Alarm Detail must reuse the same `PrimaryMorningContextPresentation` payload as Home, usually in expanded density.
- Alarm Detail must not independently derive Sunnah opportunities, Ramadan, Eid/forbidden days, Qada, Quiet, or selected-purpose copy from raw dates or local tags.
- The existing liquid-glass context card may remain as the visual container, but its informational header/content should be produced by the Primary Morning Context module.
- Detail-specific controls, such as fasting-purpose selection and eligible Fajr-at-Fajr-begins audio, may sit below the shared context summary inside the same card.
- The context summary must preserve opportunity versus intention: a White Day opportunity with Qada selected must show Qada as the user's plan and White Days as day meaning, not as completion credit.
- The context summary must not repeat hero wake-offset or no-alarm copy.
- The context summary must use `Suhoor | Fajr | Quiet` MVP vocabulary. Legacy `Pre-Fajr`, `Tahajjud only`, and `Other early worship` examples remain historical/deferred where contradicted by the MVP Suhoor addendum.
```

Do not remove Alarm Detail hero parity, immediate save/reset behavior, fasting-purpose override support, Ramadan lock, Eid/forbidden handling, adhan toggle semantics, or accessibility requirements.

---

## Patch E — Next 7 Mornings

Add the following addendum after the MVP Suhoor Alignment Addendum.

```md
## Shared Day Tag Presentation Addendum

This addendum is normative for semantic tag meaning and supersedes lower tag examples only where they conflict with MVP `Suhoor | Fajr | Quiet` vocabulary.

- Next 7 Mornings continues to own row anatomy, row grid, lane measurement, collapsed/expanded behavior, row height, dividers, and no-wrap compact tag layout.
- Next 7 Mornings must consume `SharedDayTagPresentation` or an equivalent presentation payload derived from `ResolvedDayPurpose` and `ResolvedMorningWakeState`.
- Next 7 Mornings must not infer opportunity, fasting intention, Quiet, Ramadan, or forbidden-day status locally.
- Generic compact `[Fasting]` examples should be treated as legacy unless a later product decision deliberately keeps them. MVP compact mode should prefer `[Suhoor]` for the before-Fajr wake mode and specific purpose/opportunity chips such as `[Arafah]`, `[Qada]`, `[Ramadan]`, or `[White Days]`.
- Opportunity-only dates may show `[Fajr]` plus an opportunity chip where the surface allows it, but they must not show `[Suhoor]`.
- Compact density may suppress lower-priority tags for layout, but suppression must not change the resolved context available to Day Detail or accessibility.
```

Do not change the seven-row horizon, row 1 rule, Weekly Fajrcast visible-date alignment, card collapsed default, or row-grid layout as part of this patch.

---

## Patch F — Weekly Fajrcast

Add the following addendum after the MVP Suhoor Alignment Addendum.

```md
## Shared Context and Tag Consumption Addendum

This addendum is normative for context/tag consistency.

- Weekly Fajrcast consumes resolved snapshots and shared tag/context presentation. It must not create a separate observance or intention resolver.
- Opportunity-only dates may be surfaced as weekly context only when the resolved day-purpose payload says they exist.
- The weekly footer must not imply a planned Suhoor wake from an opportunity-only date.
- Scrubbing/inspection changes temporary focus only. It must not mutate context, tags, intention, or wake mode.
- The chart must remain aligned to the same seven visible date keys as Next 7 Mornings.
```

Do not change chart geometry, snap-back behavior, seven-day window, footer trend model, or interaction model as part of this patch.

---

## Patch G — Morning Resolution Contract

No rewrite is required.

Optional note to add under child specs or surface snapshot boundaries:

```md
Primary Morning Context and Shared Day Tag Presentation are presentation adapters. They consume the canonical resolved morning graph. They do not create a second morning resolver, opportunity resolver, scheduler, or analytics source.
```

This is optional because the existing Morning Resolution Contract already owns the one-morning object graph and source-of-truth hierarchy.

---

## Patch H — Quick Wake Mode / Intent Mutation Contract

No rewrite is required for this pass.

The existing contract already owns `Suhoor | Fajr | Quiet`, immediate mutation, Quiet preservation, and shared mutation routing. The new presentation specs consume the resolved result after this contract applies user intent.

Do not reopen legacy `Pre-Fajr`, `Tahajjud only`, or `Other early worship` as MVP UI states through this patch.

---

## Patch I — Early Worship Boundary, Fajr Calculation, Alarm Delivery, Pricing

No changes required.

Reason:

- Early Worship Boundary already owns final-third / before-Fajr boundary semantics for Suhoor.
- Fajr Calculation already owns prayer-window data.
- Alarm Delivery already owns scheduling and diagnostics.
- Pricing already states entitlement must not create separate engines or erase resolved day meaning.

The new context/tag specs are presentation consumers only.

---

## Final cross-spec acceptance checklist

- [ ] Home shows Hero, then Primary Morning Context, then Next 7 Mornings, then Weekly Fajrcast.
- [ ] The context module does not repeat the Hero wake relation/status line.
- [ ] Alarm Detail and Home consume the same Primary Morning Context payload.
- [ ] Tags are derived from shared presentation payload, not local surface logic.
- [ ] Opportunity-only dates do not become Suhoor or planned fasts.
- [ ] Qada/Vow/Kaffarah/Other fast remain selected purposes, not secondary observance credits.
- [ ] Ramadan is locked and suppresses optional alternatives.
- [ ] Eid/Tashreeq do not show ordinary fasting controls.
- [ ] Quiet preserves underlying day meaning.
- [ ] Next 7 Mornings still has exactly seven rows and keeps its row-grid rules.
- [ ] Weekly Fajrcast still has exactly the same visible date keys as Next 7 Mornings.
- [ ] No delivery, Fajr calculation, final-third, pricing, or analytics source-of-truth behavior is changed by presentation specs.

---

## Recommended Codex instruction

Use the two new presentation specs as additive specs. Then apply only the patches in this addendum to the existing specs. Do not rewrite unrelated sections. Do not delete domain logic. Do not create a new resolver. Wire presentation through existing `ResolvedDaySnapshot`, `ResolvedDayPurpose`, `ResolvedMorningWakeState`, and existing fast/tag domain outputs.
