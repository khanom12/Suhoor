

## May 29 Integrity Review Addendum

Additional drift risks introduced by the Quiet/Pause pass:

- Quiet being reintroduced as a third wake purpose.
- Pause being treated as date-range Quiet.
- `Pre-Fajr`, `Early`, or `Fast mode` returning as user-facing labels.
- Active alarm surfaces showing two buttons instead of one `I’m awake` action.
- Fajr prayer logging appearing immediately after `I’m awake` without the anti-double-tap delay.
- `I’m fasting today` being treated as fast completion rather than current-day fasting status/intention.
- Permission/setup issues being displayed as Quiet or Paused.


# Subh Context / Tags Spec Integrity Review

Date: 2026-05-17

## Summary

This pass creates a presentation layer, not a second domain layer.

The existing spec corpus already has the important source-of-truth pieces:

- one canonical morning-resolution graph;
- Day Purpose separation between opportunity, intention, wake classification, required actions, outcome, and credit;
- Suhoor/Fajr/Quiet MVP mode alignment;
- Next 7 Mornings and Weekly Fajrcast seven-day alignment;
- Hero wake execution copy;
- Alarm Detail context-card location and controls.

The drift risk is that different surfaces currently have enough local context/tag copy that they can disagree. The new specs solve that by introducing:

1. `subh-primary-morning-context-presentation-spec-v1.md`
2. `subh-shared-day-tag-presentation-contract-v1.md`
3. `subh-context-tags-integration-addendum-v1.md`

## What changed

### Added

- A reusable Primary Morning Context module for Home and Day Detail.
- A shared tag/chip presentation contract.
- Surgical patch guidance for Index, Day Purpose, Morning Hero, Alarm Detail, Next 7 Mornings, and Weekly Fajrcast.

### Clarified

- Hero owns wake mechanics.
- Context owns day meaning and selected-purpose explanation.
- Tags are presentation metadata, not analytics truth.
- Opportunity-only dates remain informational.
- Quiet is an overlay and must preserve underlying meaning.
- Qada on a Sunnah opportunity day should show Qada as user plan and the opportunity as day meaning.

### Intentionally not changed

- Fajr calculation.
- Final-third calculation.
- Alarm delivery and scheduling.
- Pricing/entitlement logic.
- Seven-day horizon.
- Weekly Fajrcast chart geometry.
- Next 7 Mornings row-grid layout.
- Hero slider, relation/status line, selector animation, red warning threshold, and location/date rules.
- Day Purpose analytics-credit rules.
- FastIntentEngine compatibility rules.

## Main conflict resolved

The existing specs contain some legacy lower sections with `Pre-Fajr`, `Tahajjud only`, and `Other early worship`, but the current MVP addenda supersede those with the `Fajr | Suhoor` wake-purpose selector plus Quiet as an alarm-state override.

This pass does not delete those sections from the uploaded files. Instead, it adds precise superseding language so Codex can update safely without accidentally removing domain history or unrelated requirements.

## Why the specs are split

A single giant spec would blur responsibilities. The clean split is:

| Spec | Responsibility |
| --- | --- |
| Day Purpose | Domain truth: opportunities, intentions, required actions, credit. |
| Shared Day Tag Presentation | UI chip/tag semantics across surfaces. |
| Primary Morning Context Presentation | Human-readable context module for Home and Day Detail. |
| Integration Addendum | Exact cross-spec patch boundaries to avoid drift. |

## Recommended implementation order

1. Add the two new specs to the working corpus.
2. Add the integration addendum to the docs package.
3. Apply the surgical patch blocks to the existing specs only after review.
4. Ask Codex to audit existing code for current `ResolvedDayPurpose`, `ResolvedDayContextResolver`, `MorningFastDomain`, `MorningTagComputationDomain`, and surface-specific tag/context rendering.
5. Implement a presentation adapter rather than a new resolver.

## Red flags for Codex

Codex should be stopped or corrected if it:

- adds observance logic inside SwiftUI views;
- turns tags into analytics truth;
- treats a Sunnah opportunity as a planned Suhoor fast;
- rewrites the alarm scheduler;
- edits Fajr calculation while implementing context copy;
- removes Qada/Vow/Kaffarah/Other fast support;
- removes Next 7 Mornings row geometry;
- reintroduces `Fast`, `Early`, or generic `Pre-Fajr` as top-level MVP labels;
- makes Quiet erase day meaning;
- duplicates the hero's wake-offset line inside the context card.
