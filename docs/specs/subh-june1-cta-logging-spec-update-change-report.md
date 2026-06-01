# Subh June 1 CTA/Logging Spec Update Change Report

## 1. Summary

The June 1 package was updated to reconcile the May 31 spec set with the new CTA/logging source of truth. The update focused on explicit awake confirmation, early-awake confirmation, next wake-check display, context-card logging, fast completion prompts, historical logging foundations, and Qada-candidate foundations.

## 2. Files updated

| File | Why updated |
| --- | --- |
| `00-subh-spec-index-v6.md` | New active index, conflict hierarchy, and active file map. |
| `subh-cta-logging-and-wake-action-spec-v2.md` | New canonical CTA/logging feature specification. |
| `subh-alarm-delivery-schedule-reliability-spec-v6.md` | Early-awake delivery consequences, dismissal vs awake, post-Suhoor Fajr delivery. |
| `subh-alarm-detail-view-screen-spec-v10.md` | Detail view alignment with Home/context CTA rules. |
| `subh-context-spec-integrity-review-v4.md` | New drift traps and audit rules. |
| `subh-day-purpose-opportunity-resolution-spec-v4.md` | Fast prompt eligibility, compact check/X outcomes, Qada-candidate logic. |
| `subh-early-worship-boundary-spec-v5.md` | Early-awake availability and confirmation. |
| `subh-morning-hero-item-spec-v18.md` | Hero active CTAs and next pending wake-check time display. |
| `subh-morning-resolution-contract-state-ownership-spec-v6.md` | New resolved outputs for action rows, early awake, next pending attempt, prompts. |
| `subh-morning-state-framework-scenario-walkthrough-spec-v2.md` | Scenario addenda for early awake, dismissal, check/X, post-Suhoor slider. |
| `subh-mvp-interaction-inventory-v7.md` | Added/updated interactions. |
| `subh-mvp-interaction-tier-exposure-matrix-v4.md` | Free/core alignment for current and near-current check-ins. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v5.md` | Clarified historical logs are separate durable records from planning records. |
| `subh-pricing-entitlement-spec-v5.md` | Pricing alignment for current/late CTA/logging. |
| `subh-primary-morning-context-presentation-spec-v4.md` | Context-card action area and compact prompts. |
| `subh-quick-wake-mode-intent-mutation-contract-v5.md` | New mutation commands and changed dismissal behaviour. |
| `subh-quiet-mode-quiet-morning-contract-spec-v4.md` | Quiet vs early-awake distinction. |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v4.md` | Cross-surface alignment with CTA v2. |
| `subh-sound-alarm-settings-spec-v3.md` | Fajr adhan/event preservation/suppression rules. |
| `subh-wake-session-testing-and-simulation-harness-spec-v6.md` | New test coverage for early awake, dismissal, wake-check display, compact prompts, Qada candidates. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v4.md` | Wake execution and logging lifecycle reconciliation. |
| `subh-spec-release-manifest-2026-06-01.md` | New release manifest for this spec package. |

## 3. Files carried forward without material change

The following specs were inspected and carried forward because the June 1 CTA/logging changes do not materially alter their current responsibilities:

- `subh-context-tags-integration-addendum-v3.md`
- `subh-fajr-time-calculation-determination-selection-spec-v2.md`
- `subh-month-planning-gregorian-hijri-spec-v4.md`
- `subh-next-7-mornings-wake-forecast-spec-v4.md`
- `subh-shared-day-tag-presentation-contract-v3.md`
- `subh-weekly-fajrcast-card-spec-v15.md`

## 4. Main contradictions corrected

- Removed/overrode the older assumption that ordinary system dismissal equals **I’m Awake**.
- Replaced the old **I’m fasting today** active-flow concept with after-Maghrib fast completion check/X prompts.
- Replaced the separate post-Suhoor **Set Fajr Wake Alarm** concept with Hero/Fajr slider activation.
- Moved late Fajr logging from a separate below-context prompt into the context-card action area.
- Added early-awake confirmation requirements and different Suhoor/Fajr consequences.
- Added Hero next-wake-check display behaviour.

## 5. Remaining intentionally future-scoped areas

- Full Qada engine.
- Full historical Fajr/Fasting logging card UI.
- Religious/fiqh detail for Ramadan exemptions and make-up categories.
- Final visual design of compact check/X controls.
- Final high-latitude early-awake availability beyond the MVP midnight rule.

## 6. Validation performed

The folder was scanned for known conflicting phrases and updated/overridden where they appeared in active implementation-facing specs. A final Codex prompt is included separately to instruct Codex to perform an additional repository-level OpenSpec verification before changing code.
