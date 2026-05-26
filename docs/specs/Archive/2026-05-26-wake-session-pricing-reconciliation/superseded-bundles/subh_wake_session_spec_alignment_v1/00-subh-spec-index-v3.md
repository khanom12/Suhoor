# Subh Spec Index and Source-of-Truth Map

| Field | Value |
| --- | --- |
| Canonical filename | `00-subh-spec-index-v3.md` |
| Version | 3 |
| Spec status | Canonical working index for this aligned bundle |
| Supersedes | `00-subh-spec-index-v2.md`, if present in the repository |
| Related specs | All active Subh MVP specs listed below |
| Owning domain / surface | Spec registry, source-of-truth ownership, cross-spec routing |
| Implementation audit status | Needs implementation audit |

## Purpose

Define the active spec map for Subh so Codex, implementation audits, and future spec work know which document owns each decision. This index prevents accidental feature removal, duplicate state machines, and cross-spec drift.

This file is a routing map. It does not replace the detailed specs.

## Non-removal rule

A feature, scenario, domain rule, or UI behavior remains in scope if it exists in an active spec, unless a later approved spec explicitly marks it as deferred or removed by name and scenario/section reference.

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
```

## Active canonical specs in this bundle

| Spec | Canonical ownership |
|---|---|
| `00-subh-spec-index-v3.md` | Registry and source-of-truth map. |
| `subh-morning-resolution-contract-state-ownership-spec-v3.md` | Core one-morning resolver, state ownership, canonical object graph, mode/boundary/wake-state doctrine. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md` | Display/edit/schedule/history horizons, anchored intentions, generated-vs-stored doctrine, Hijri/calendar movement. |
| `subh-alarm-delivery-schedule-reliability-spec-v3.md` | Platform delivery, AlarmKit/UserNotifications, identifiers, stale cancellation, reconciliation, delivery ledger, diagnostics. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md` | Wake Session execution, primary alarm + wake checks, awake confirmation, immediate MorningLogs, prayer/fasting outcome separation. |
| `subh-quiet-mode-quiet-morning-contract-spec-v1.md` | Quiet Mode overlay, Quiet Morning semantics, active-session confirmation, underlying state restoration, quiet cancellation behavior. |
| `subh-sound-alarm-settings-spec-v1.md` | Alarm sound roles, ramped audio asset policy, sound-setting boundaries, wake-check sound behavior. |
| `subh-morning-hero-item-spec-v15.md` | Home hero layout, visible state hierarchy, hero action slot, selector presentation, wake-boundary visual, hero CTAs. |
| `subh-mvp-interaction-inventory-v4.md` | MVP scenario inventory and traceability IDs. |
| `subh-pricing-entitlement-spec-v2.md` | Pricing, entitlement, paywall doctrine, downgrade/data-preservation rules; amended by Wake Sessions entitlement addendum for core/free logs. |

## Referenced specs not included in this upload bundle

The uploaded bundle references several repository specs that may already exist elsewhere. Do not create duplicates unless a later audit confirms they are missing.

| Referenced spec/domain | Expected ownership |
|---|---|
| Quick Wake Mode and Intent Mutation Contract | Mode mutation, idempotency, restoration, final-state commit ordering. |
| Day Purpose / Opportunity / Intention Spec | Observance opportunities, fasting taxonomy, intention vs opportunity vs credit. |
| Fajr Time Calculation, Determination, and Selection | Prayer-time methods, Fajr begin/end, adjustments, provider policy. |
| Early Worship Boundary Spec | Final-third calculation and early-worship boundary semantics. |
| Alarm Detail View Spec | Selected-day editing surface and detail controls. |
| Next 7 Days Wake Forecast Spec | Seven-row near-term forecast card. |
| Weekly Fajrcast Card Spec | Weekly chart/card behavior. |
| Home Screen Composition Spec | Overall Home layout and card placement. |
| Settings Hub / Location / Prayer Time / Hijri Settings specs | Settings surfaces and setup flows. |
| Onboarding and Initial Setup Spec | First launch, permission/location/method setup. |

## Source-of-truth hierarchy

When specs overlap, use this hierarchy:

```text
1. This index for ownership routing only.
2. Domain owner spec for the specific rule.
3. Parent system contract where a child spec conflicts with architecture.
4. Surface spec for UI/layout/copy once domain state is resolved.
5. Interaction inventory for traceability, not as the only rule definition.
6. Historical examples only when not superseded by a newer addendum.
```

## Domain ownership map

| Concern | Owning spec | Must not be owned by |
|---|---|---|
| Fajr begin/end, Maghrib | Fajr Time Calculation spec | Hero, Delivery, Wake Sessions |
| Final-third start | Early Worship Boundary spec | Hero, Delivery |
| Day meaning/opportunities | Day Purpose spec | Hero tags, Delivery events |
| User intention anchors | Planning Horizon spec | Delivery, Hero local state |
| One resolved morning graph | Morning Resolution Contract | Separate UI-local engines |
| Wake Session execution | Wake Sessions spec | Pricing, Hero, Delivery alone |
| Wake-check platform scheduling | Alarm Delivery spec + Wake Sessions spec | Hero, Pricing |
| Quiet suppression/restoration | Quiet Mode spec | Permission warnings, delivery failure states |
| Sound role/asset policy | Sound and Alarm Settings spec | Wake mode activation |
| Hero layout/CTA placement | Morning Hero spec | Delivery or pricing specs |
| Scenario traceability | MVP Interaction Inventory | Ad hoc implementation notes |
| Entitlement/paywalls | Pricing spec | Resolver correctness or delivery reliability |

## Critical separations

Subh must preserve these separations across implementation:

```text
opportunity ≠ intention
intention ≠ wake execution
wake execution ≠ prayer completion
Suhoor wake ≠ Fajr prayer
planned fast ≠ completed fast
Quiet ≠ missed prayer
Quiet ≠ permission failure
sound role ≠ alarm activation
display horizon ≠ active scheduled horizon
Alarm stopped ≠ user awake
```

## Wake Session routing

The canonical flow is:

```text
Planning / settings / anchored intentions
        ↓
Morning Resolution Contract
        ↓
Resolved morning mode, boundaries, wake time, materialized events
        ↓
Wake Sessions spec
        ↓
Primary alarm + eligible wake checks + immediate MorningLog
        ↓
Alarm Delivery Reliability
        ↓
Platform scheduling, cancellation, reconciliation
        ↓
Morning Hero consumes state and emits confirmation intents
```

## Quiet routing

```text
User selects Quiet
        ↓
Quick Wake Mode mutation path / Quiet Mode contract
        ↓
Preserve underlying Fajr/Suhoor state
        ↓
If active Wake Session: show confirmation sheet
        ↓
If confirmed: cancel primary/wake-check alarms
        ↓
Log quietMorning, not missed prayer
```

## Sound routing

```text
Resolved event carries sound role
        ↓
Sound settings resolve selected asset
        ↓
Delivery schedules event with asset
        ↓
Ramped behavior comes from audio waveform
```

## Implementation pass guidance

For the current wake-session implementation pass, Codex should:

1. Add/consume the new spec files in the repository’s canonical specs location.
2. Preserve existing docs and add targeted addenda only.
3. Implement Wake Session state, wake checks, cancellation, and MorningLog records according to `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`.
4. Implement Quiet active-session confirmation according to `subh-quiet-mode-quiet-morning-contract-spec-v1.md`.
5. Implement or prepare sound asset references according to `subh-sound-alarm-settings-spec-v1.md`.
6. Avoid StoreKit/paywalls, adaptive wake checks, advanced interval settings, long-term analytics, cloud sync, and unrelated UI rewrites.
7. Add tests for Fajr, Suhoor, Quiet, alarm stop, wake-check expiry, confirmation cancellation, and stale alarm reconciliation.

## Acceptance criteria

1. Each active behavior has one owning spec.
2. The Wake Sessions spec is registered as the canonical owner for wake checks and immediate morning logs.
3. The Quiet Mode spec is registered as the canonical owner for Quiet suppression and restoration.
4. The Sound and Alarm Settings spec is registered as the canonical owner for ramped sound assets and sound-role boundaries.
5. No existing scenario ID in `subh-mvp-interaction-inventory-v4.md` is removed or renumbered.
6. Existing spec body text remains intact except for targeted addenda and related-spec references.
