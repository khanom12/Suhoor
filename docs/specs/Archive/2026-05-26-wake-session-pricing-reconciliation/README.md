# Wake Session And Pricing Reconciliation Archive

Date: 2026-05-26

This archive preserves all material superseded during the docs-only reconciliation of the Subh working specification folder.

No content was permanently deleted.

## Why This Archive Exists

The active spec root had older root specs, an older wake-session alignment bundle, a newer wake-pricing alignment bundle, historical pricing concepts, and a Next 7 forecast naming conflict.

The active root now uses:

- `00-subh-spec-index-v3.md`
- `subh-pricing-entitlement-spec-v3.md`
- `subh-mvp-interaction-tier-exposure-matrix-v2.md`
- `subh-next-7-mornings-wake-forecast-spec-v2.md`
- the promoted Wake Sessions, Quiet Mode, Sound, Hero, Morning Resolution, Alarm Delivery, Planning Horizon, and Interaction Inventory specs

## Folder Contents

| Folder | Contents |
| --- | --- |
| `superseded-root-specs/` | Prior active-root files replaced or archived during reconciliation. |
| `superseded-bundles/` | The old wake-session alignment bundle and the newer wake-pricing alignment bundle after promotion to root. |
| `superseded-diffs/` | Standalone copies of the alignment diff files. |
| `superseded-zips/` | Reserved for superseded spec zips. No spec zip was moved in this pass. |
| `conflict-review/` | Notes on conflicts that required explicit reconciliation decisions. |
| `notes/` | Reserved for follow-up notes. |

## Key Decisions

- Pricing v3 is active because it replaces the old multi-paid-tier model with Free + Plus.
- Wake Sessions, core Wake Checks, immediate awake confirmations, current-morning check-ins, Quiet, and core alarm settings are Free/core utility.
- Plus owns durable memory/history/insights, ledgers, summaries, export/sync, advanced accountability, and future adaptive support if explicitly scoped.
- `subh-next-7-mornings-wake-forecast-spec-v2.md` is active because it explicitly supersedes `subh-next-7-days-wake-forecast-spec-v1.md` and contains newer substantive decisions.
- `subh_ai_weather_cloud_assets_top_hero_v1.zip` was not archived because it is an active asset bundle, not a spec reconciliation artifact.

## Historical Material

Historical/superseded references to `00-subh-spec-index-v2.md`, `subh-pricing-entitlement-spec-v2.md`, Next 10, and archived Complete-family pricing concepts are preserved here for auditability. They are not active MVP guidance.
