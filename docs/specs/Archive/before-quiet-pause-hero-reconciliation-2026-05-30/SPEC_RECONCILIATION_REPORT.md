# Subh Working Spec Reconciliation Report

Date of cleanup: 2026-05-26

## Scope

This was a docs-only cleanup of the Subh working specification folder. No app code was changed and no content was permanently deleted.

The cleanup reconciled the active root specs, the older wake-session alignment bundle, the newer wake-pricing alignment bundle, the existing Archive folder, and the repo-mirror context/tag specs.

## Source Priority Used

1. `subh_wake_pricing_alignment_v2/` was preferred for overlapping wake-session files because it includes the newer Pricing v3 alignment.
2. `subh_wake_session_spec_alignment_v1/` was treated as superseded where files overlapped.
3. Active root specs were compared before replacement; prior root versions were moved into the reconciliation archive.
4. Repo-mirror context/tag specs were preserved because they contained substantive presentation-layer decisions not present in the desktop bundle.

## Files Promoted

| Promoted file | Source |
| --- | --- |
| `00-subh-spec-index-v3.md` | Promoted from `subh_wake_pricing_alignment_v2/`, then expanded to cover the full active root set. |
| `subh-pricing-entitlement-spec-v3.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-quiet-mode-quiet-morning-contract-spec-v1.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-sound-alarm-settings-spec-v1.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-alarm-delivery-schedule-reliability-spec-v3.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-morning-hero-item-spec-v15.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-morning-resolution-contract-state-ownership-spec-v3.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-mvp-interaction-inventory-v4.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md` | Promoted from `subh_wake_pricing_alignment_v2/`. |
| `subh-primary-morning-context-presentation-spec-v1.md` | Preserved from repo mirror into the active desktop spec set. |
| `subh-shared-day-tag-presentation-contract-v1.md` | Preserved from repo mirror into the active desktop spec set. |
| `subh-context-tags-integration-addendum-v1.md` | Preserved from repo mirror into the active desktop spec set. |
| `subh-context-spec-integrity-review-v1.md` | Preserved from repo mirror into the active desktop spec set. |

## Files Archived

| Archived file or folder | Archive location |
| --- | --- |
| Historical/superseded `00-subh-spec-index-v2.md` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` |
| Historical/superseded `subh-pricing-entitlement-spec-v2.md` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` |
| Historical/superseded `subh-mvp-interaction-tier-exposure-matrix-v1.md` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` |
| Historical/superseded `subh-next-7-days-wake-forecast-spec-v1.md` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` |
| Prior root copies of promoted wake-session-aligned specs | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` |
| `subh_wake_session_spec_alignment_v1/` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/` |
| `subh_wake_pricing_alignment_v2/` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/` |
| `alignment_targeted_addenda.diff` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-diffs/` |
| `pricing_v3_wake_session_alignment.diff` | `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-diffs/` |

No superseded spec zip was present. `subh_ai_weather_cloud_assets_top_hero_v1.zip` remains active because it is an asset bundle, not a reconciliation artifact.

## Files Left Unchanged

These active root specs remained active and were not replaced by bundle copies:

- `subh-alarm-detail-view-screen-spec-v7.md`
- `subh-day-purpose-opportunity-resolution-spec-v1.md`
- `subh-early-worship-boundary-spec-v2.md`
- `subh-fajr-time-calculation-determination-selection-spec-v1.md`
- `subh-month-planning-gregorian-hijri-spec-v2.md`
- `subh-next-7-mornings-wake-forecast-spec-v2.md`
- `subh-quick-wake-mode-intent-mutation-contract-v2.md`
- `subh-weekly-fajrcast-card-spec-v14.md`
- `subh_ai_weather_cloud_assets_top_hero_v1.zip`

Some references in these files were mechanically updated to point at index v3, Pricing v3, and Next 7 Mornings.

## Files Merged Or Reconciled

| File | Reconciliation |
| --- | --- |
| `00-subh-spec-index-v3.md` | Expanded from bundle index to include the full active spec set, Pricing v3, Next 7 Mornings, context/tag specs, and archive routing. |
| `subh-mvp-interaction-tier-exposure-matrix-v2.md` | New Free / Plus successor created from the archived v1 matrix concept and Pricing v3 doctrine. |
| `subh-next-7-mornings-wake-forecast-spec-v2.md` | Kept active over `subh-next-7-days-wake-forecast-spec-v1.md` because it explicitly supersedes v1 and contains newer substantive decisions. |

## Unresolved Conflicts Or Open Decisions

- No blocking reconciliation conflicts remain.
- Future implementation audits still need to verify app conformance to the active specs.
- Exact Plus price remains intentionally unresolved and must not be hardcoded.
- Advanced adaptive wake support, family/household accountability, premium sound libraries, and full logging implementation details remain future/deferred unless a later spec promotes them.

## Old Path To New Path

| Old path | New path / status |
| --- | --- |
| `00-subh-spec-index-v2.md` | Historical/superseded: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/00-subh-spec-index-v2.md`; active index is `00-subh-spec-index-v3.md`. |
| `subh-pricing-entitlement-spec-v2.md` | Historical/superseded: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-pricing-entitlement-spec-v2.md`; active pricing is `subh-pricing-entitlement-spec-v3.md`. |
| `subh-mvp-interaction-tier-exposure-matrix-v1.md` | Historical/superseded: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-mvp-interaction-tier-exposure-matrix-v1.md`; active matrix is `subh-mvp-interaction-tier-exposure-matrix-v2.md`. |
| `subh-next-7-days-wake-forecast-spec-v1.md` | Historical/superseded: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/subh-next-7-days-wake-forecast-spec-v1.md`; active forecast is `subh-next-7-mornings-wake-forecast-spec-v2.md`. |
| `subh_wake_session_spec_alignment_v1/` | Historical/superseded bundle: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/subh_wake_session_spec_alignment_v1/`. |
| `subh_wake_pricing_alignment_v2/` | Historical promotion source: `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-bundles/subh_wake_pricing_alignment_v2/`. |

## Pricing v3 Rationale

Pricing v3 replaces v2 because it removes the old multi-paid-tier model and aligns pricing with the product truth:

```text
Free = complete core morning wake/planning/execution utility
Plus = durable practice memory, history, insights, ledgers, summaries, export/sync, and accountability
```

This avoids charging for the core Fajr/Suhoor wake loop while preserving a clear paid layer for durable value over time.

## Confirmations

- Active docs now use `00-subh-spec-index-v3.md` as the source-of-truth map, except for historical/superseded notes.
- No active spec depends on historical/superseded `subh-pricing-entitlement-spec-v2.md`; it appears only as a superseded reference or in Archive/report notes.
- The active MVP pricing model is Free + Plus.
- Wake Sessions, core Wake Checks, current-morning awake confirmations, active/current-morning prayer check-ins, active/current-day fasting-intent check-ins, Suhoor mode, Fajr mode, Quiet mode, wake adjustment, Next 7 Mornings, and Weekly Fajrcast are Free/core.
- Complete is archived/deferred and is not an active MVP pricing tier.
- Complete-family lifetime, founder, monthly, annual, and hardcoded-price concepts are historical/deferred, not active MVP pricing concepts.
- Quiet means intentional delivery suppression / `quietMorning`, not missed prayer, permission failure, or delivery failure.
- Sound ramping is documented as an audio waveform/asset property, not an unsupported runtime system-volume promise.
- No permanent deletion occurred.
