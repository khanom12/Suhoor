# Subh Spec Index and Source-of-Truth Map

| Field | Value |
| --- | --- |
| Canonical filename | `00-subh-spec-index-v3.md` |
| Version | 3 |
| Spec status | Canonical Desktop working-spec index after wake-session and pricing reconciliation |
| Date | 2026-05-26 |
| Supersedes | Historical/superseded: `00-subh-spec-index-v2.md` |
| Related specs | All active Subh MVP specs listed below |
| Owning domain / surface | Spec registry, source-of-truth ownership, cross-spec routing |
| Implementation audit status | Needs implementation audit |

## Purpose

This index is the active source-of-truth map for the Subh working specification folder.

It records which document owns each MVP decision after the wake-session and Pricing v3 reconciliation. It does not replace the detailed specs and does not change app code.

## Non-Removal Rule

A feature, scenario, domain rule, or UI behavior remains in scope if it exists in an active spec, unless a later approved spec explicitly marks it deferred or removed by name and scenario/section reference.

Allowed spec changes:

```text
clarify
rename
move ownership
split overloaded concepts
merge duplicates
add traceability
supersede conflicting older wording with a targeted addendum
```

Forbidden spec changes:

```text
silently delete behavior
rewrite unrelated sections
collapse separate outcomes into one field
turn delivery failure into Quiet
turn awake confirmation into prayer confirmation
turn opportunity into intention
schedule all visible forecast days by implication
make core wake execution paid-only
```

## Active Product Decisions

### MVP wake modes

The exposed MVP quick modes are:

```text
Suhoor | Fajr | Quiet
```

`Suhoor` is the only exposed before-Fajr MVP wake mode. Tahajjud-only, Other early worship, and generic non-fasting Pre-Fajr flows are deferred from active MVP UI and active MVP resolution unless a future approved spec reintroduces them.

### Pricing v3

The active MVP pricing model is:

```text
Free
Plus
```

Free owns the complete core morning utility: Fajr, Suhoor, Quiet, wake adjustment, Wake Sessions, core Wake Checks, current-morning confirmations, current-day fasting intent, Next 7 Mornings, Weekly Fajrcast, core setup, and reliability warnings.

Plus owns the durable memory layer: history, historical editing, Qada ledgers, summaries, trends, streaks, analytics, export/sync where paid, advanced accountability, and future adaptive support if explicitly scoped.

Archived Complete-family pricing concepts and hardcoded prices are not active MVP pricing concepts.

### Wake Sessions

Wake Sessions, primary wake alarms, core Wake Checks, awake confirmation, immediate MorningLogs, Quiet cancellation, and delivery reconciliation are core/free utility. Long-term surfacing of those records as history, analytics, summaries, or accountability can belong to Plus.

### Quiet

Quiet means intentional delivery suppression for a resolved morning. Quiet must not hide permission failure, delivery failure, stale scheduling, missing data, or missed-prayer assumptions. Quiet may log `quietMorning`, cancel active wake deliveries after confirmation where required, and preserve underlying Fajr/Suhoor meaning for restoration.

### Sound and alarm settings

Gentle alarm ramping is an audio waveform/asset policy. Subh must not promise unsupported runtime control of system alarm volume.

### Forecast horizon

The active near-term forecast spec is `subh-next-7-mornings-wake-forecast-spec-v2.md`.

`subh-next-7-mornings-wake-forecast-spec-v2.md` explicitly supersedes `subh-next-7-days-wake-forecast-spec-v1.md` and the archived historical Next 10 forecast. Weekly Fajrcast uses the same seven visible date keys as Next 7 Mornings.

Display horizon, edit horizon, and active scheduled horizon remain distinct.

## Active Canonical Specs

| Spec | Version | Canonical ownership |
| --- | ---: | --- |
| `00-subh-spec-index-v3.md` | 3 | Registry and source-of-truth map. |
| `subh-pricing-entitlement-spec-v3.md` | 3 | Free / Plus pricing, entitlement, paywalls, downgrade/data preservation, paid-layer boundaries. |
| `subh-mvp-interaction-tier-exposure-matrix-v2.md` | 2 | Free / Plus exposure overlay for MVP interaction scenario groups. |
| `subh-morning-resolution-contract-state-ownership-spec-v3.md` | 3 | Core one-morning resolver, state ownership, canonical object graph, mode/boundary/wake-state doctrine. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md` | 3 | Display/edit/schedule/history horizons, anchored intentions, generated-vs-stored doctrine. |
| `subh-quick-wake-mode-intent-mutation-contract-v2.md` | 2 | Shared quick-mode mutation, idempotency, restoration, and final-state commit ordering. |
| `subh-day-purpose-opportunity-resolution-spec-v1.md` | 1 | Day purpose, observance opportunity, intention, outcome, and credit resolution. |
| `subh-fajr-time-calculation-determination-selection-spec-v1.md` | 1 | Prayer-time calculation, method/source selection, and Fajr begin/end assumptions. |
| `subh-early-worship-boundary-spec-v2.md` | 2 | Suhoor before-Fajr boundary model; legacy early-worship terminology is internal/deferred. |
| `subh-alarm-delivery-schedule-reliability-spec-v3.md` | 3 | Platform delivery, identifiers, stale cancellation, reconciliation, delivery ledger, diagnostics. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md` | 1 | Wake Session execution, primary alarm + wake checks, awake confirmation, immediate MorningLogs. |
| `subh-wake-session-testing-and-simulation-harness-spec-v2.md` | 2 | Debug/internal Wake Session testing harness, State Explorer, Home Simulation Mode, fake scheduling, real AlarmKit mapped playback with five-minute Wake Check spacing, release guardrails. |
| `subh-quiet-mode-quiet-morning-contract-spec-v1.md` | 1 | Quiet Mode overlay, Quiet Morning semantics, active-session confirmation, restoration, quiet cancellation. |
| `subh-sound-alarm-settings-spec-v1.md` | 1 | Alarm sound roles, ramped audio asset policy, sound-setting boundaries. |
| `subh-morning-hero-item-spec-v15.md` | 15 | Home hero layout, visible state hierarchy, Hero Action Slot, selector presentation, hero CTAs. |
| `subh-alarm-detail-view-screen-spec-v7.md` | 7 | Selected-morning detail editor. |
| `subh-next-7-mornings-wake-forecast-spec-v2.md` | 2 | Home / Plan ahead seven-morning forecast surface. |
| `subh-weekly-fajrcast-card-spec-v14.md` | 14 | Weekly Fajrcast chart/card behavior over the same seven visible mornings. |
| `subh-month-planning-gregorian-hijri-spec-v2.md` | 2 | Gregorian/Hijri month planning and longer-range planning entry points. |
| `subh-shared-day-tag-presentation-contract-v1.md` | 1 | Shared tag/chip presentation across Home, forecast, detail, and supporting surfaces. |
| `subh-primary-morning-context-presentation-spec-v1.md` | 1 | Shared Home and Day Detail primary morning-context presentation. |
| `subh-context-tags-integration-addendum-v1.md` | 1 | Cross-spec integration guidance for primary context and shared tags. |
| `subh-context-spec-integrity-review-v1.md` | 1 | Context/tag presentation integrity review and implementation guardrails. |
| `subh-mvp-interaction-inventory-v4.md` | 4 | MVP scenario coverage, scenario IDs, and traceability. |

## Archived And Superseded Material

| Material | Current status |
| --- | --- |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/00-subh-spec-index-v2.md` | Historical/superseded by this index. |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-pricing-entitlement-spec-v2.md` | Historical/superseded by Pricing v3. |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-mvp-interaction-tier-exposure-matrix-v1.md` | Historical/superseded by the Free / Plus matrix v2. |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-next-7-days-wake-forecast-spec-v1.md` | Historical/superseded by Next 7 Mornings v2. |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/subh_wake_session_spec_alignment_v1/` | Historical wake-session alignment bundle; superseded by the pricing v3 alignment bundle. |
| `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/subh_wake_pricing_alignment_v2/` | Historical promotion source; active files have been reconciled into root. |
| `Archive/2026-05-26-wake-session-testing-harness-v1-superseded/subh-wake-session-testing-and-simulation-harness-spec-v1.md` | Historical/superseded by Wake Session Testing Harness v2. |
| `Archive/subh-next-10-mornings-wake-forecast-spec-v4.md` | Historical forecast spec; superseded by seven-morning forecast direction. |

## Source-Of-Truth Hierarchy

When specs overlap, use this hierarchy:

```text
1. This index for ownership routing only.
2. Domain owner spec for the specific rule.
3. Parent system contract where a child spec conflicts with architecture.
4. Surface spec for UI/layout/copy once domain state is resolved.
5. Interaction inventory for traceability, not as the only rule definition.
6. Historical examples only when not superseded by a newer addendum.
```

## Domain Ownership Map

| Concern | Owning spec | Must not be owned by |
| --- | --- | --- |
| Fajr begin/end and calculation assumptions | Fajr Time Calculation spec | Hero, Delivery, Wake Sessions |
| Final-third / before-Fajr boundary semantics | Early Worship Boundary spec | Hero, Delivery |
| Day meaning and opportunities | Day Purpose spec | Hero tags, Delivery events |
| User intention anchors | Planning Horizon spec | Delivery, Hero local state |
| One resolved morning graph | Morning Resolution Contract | Separate UI-local engines |
| Wake Session execution | Wake Sessions spec | Pricing, Hero, Delivery alone |
| Wake Session testing, Home Simulation, and mapped playback harness | Wake Session Testing Harness spec | Production wake rules, Pricing, separate test engines |
| Wake-check platform scheduling | Alarm Delivery spec + Wake Sessions spec | Hero, Pricing |
| Quiet suppression/restoration | Quiet Mode spec | Permission warnings, delivery failure states |
| Sound role/asset policy | Sound and Alarm Settings spec | Wake mode activation |
| Hero layout/CTA placement | Morning Hero spec | Delivery or pricing specs |
| Detail editing controls | Alarm Detail spec | Pricing or forecast rows |
| Forecast row presentation | Next 7 Mornings spec | Delivery scheduling |
| Shared tags and context copy | Shared Tag + Primary Context specs | Local view-specific resolvers |
| Scenario traceability | MVP Interaction Inventory | Ad hoc implementation notes |
| Entitlement/paywalls | Pricing spec + tier matrix | Resolver correctness or delivery reliability |

## Reading Order

1. Start with `subh-morning-resolution-contract-state-ownership-spec-v3.md`.
2. Read `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md` and `subh-day-purpose-opportunity-resolution-spec-v1.md` for date meaning, future edits, and intention ownership.
3. Read `subh-fajr-time-calculation-determination-selection-spec-v1.md` and `subh-early-worship-boundary-spec-v2.md` for prayer-window and Suhoor before-Fajr assumptions.
4. Read `subh-quick-wake-mode-intent-mutation-contract-v2.md` before implementing Home or detail wake-mode edits.
5. Read `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-wake-session-testing-and-simulation-harness-spec-v2.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, and `subh-sound-alarm-settings-spec-v1.md` before making wake-execution, testing-harness, Quiet, or sound claims.
6. Read `subh-alarm-delivery-schedule-reliability-spec-v3.md` before changing scheduling, permission, fallback, or diagnostics behavior.
7. Read surface specs after the contracts they consume: Hero, Detail, Next 7 Mornings, Weekly Fajrcast, Month Planning, Primary Context, and Shared Tags.
8. Read `subh-pricing-entitlement-spec-v3.md` and `subh-mvp-interaction-tier-exposure-matrix-v2.md` before implementing paywalls, trials, feature gates, downgrade behavior, or paid-layer surfaces.
9. Use `subh-mvp-interaction-inventory-v4.md` as the scenario traceability backbone.

## Validation Expectations

- Active specs reference `00-subh-spec-index-v3.md`.
- Active specs do not depend on historical/superseded `subh-pricing-entitlement-spec-v2.md`.
- The active pricing model is Free + Plus only.
- Wake Sessions, core Wake Checks, immediate awake confirmation, Quiet, current-morning check-ins, Next 7 Mornings, and Weekly Fajrcast are Free/core.
- Archived Complete-family pricing concepts and hardcoded prices are not active MVP pricing.
- Historical/superseded references may appear only in archive paths, supersedes fields, old-name mappings, reconciliation reports, or explicitly historical notes.
- No active root-level reconciliation bundle folder remains.
- The asset bundle `subh_ai_weather_cloud_assets_top_hero_v1.zip` remains active and is not treated as a superseded spec artifact.
