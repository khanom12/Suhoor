# Subh Specification Reconciliation Report — Quiet / Pause / Hero / Wake Flow

| Field | Value |
| --- | --- |
| Date | 2026-05-30 |
| Scope | Specs-only reconciliation of uploaded `Archive.zip` |
| Output package | `subh_specs_may30_reconciled.zip` |
| Active specs updated | 25 markdown files |
| Originals preserved | `Archive/originals-before-may30-reconciliation/` |

## May 30 correction: Suhoor-to-Fajr handoff

After the first reconciliation draft, the Suhoor-to-Fajr CTA sequence was tightened so that Suhoor acknowledgement and Fajr acknowledgement remain separate. The active specs now require this order for a Suhoor morning:

```text
I’m awake          = Suhoor wake acknowledged
I’m fasting today  = fasting intention/status before Fajr, when eligible
I’m awake for Fajr = Fajr wake/check acknowledged after Fajr begins
I prayed Fajr      = Fajr prayer logged after Fajr wake acknowledgement and delay
```

This correction avoids treating a pre-Fajr Suhoor wake as automatic confirmation that the user is awake for Fajr.

Additional affected files for this correction: Hero, Alignment, Wake Sessions/Logs, Quick Mutation, Morning Resolution, Alarm Detail, Interaction Inventory, and Testing Harness.

## Executive summary

The uploaded archive already contained the correct May 29 direction in several addenda, but many lower sections still looked active and contradicted the final Quiet/Pause/Hero model. I reconciled the active root-level specs so Codex can consume them without needing to interpret stale lower-body exceptions. The original files were not discarded; they are preserved under the archive folder for traceability.

## Canonical decisions now enforced

- Wake purpose is only `Fajr | Suhoor`.
- Quiet is `DateAlarmOverride.quiet`, not a wake purpose.
- Pause is `GlobalWakeAlarmPolicy.pausedIndefinitely`, not a wake purpose.
- Suhoor is the only exposed MVP before-Fajr wake purpose and is fasting/suhoor-oriented.
- Non-fasting Pre-Fajr / Early / Tahajjud-only / Other early worship flows are deferred from active MVP UI/resolution.
- Quiet is available before the first alarm begins and unavailable after wake execution starts.
- Active wake execution exposes `I’m awake`, not `Stop checks` or Quiet; after Suhoor, the Fajr phase can expose `I’m awake for Fajr`.
- Explicit system/AlarmKit dismissal counts as awake acknowledgement for MVP, with source preserved internally.
- Next 7, Month, and Weekly Fajrcast are display/navigation surfaces; edits route to Day Detail.
- Middle-lane row tags are opportunity/context only; Quiet/Paused/Rings once are trailing statuses.
- Core wake utility, Quiet, Pause, ring-once, acknowledgement, Wake Sessions, basic Wake Checks, and current-morning logs remain Free.

## File-by-file update report

### `00-subh-spec-index-v3.md`

Rewritten as the active source-of-truth map. Added canonical model, terminology rules, conflict rule, active spec map, and implementation acceptance checks.

### `subh-alarm-delivery-schedule-reliability-spec-v3.md`

Rewritten to focus delivery around resolver output, Quiet/Pause/ring-once scheduling, cancellation reasons, follow-up boundaries, and issue states.

### `subh-alarm-detail-view-screen-spec-v7.md`

Rewritten to mirror Home with Fajr/Suhoor selector plus separate alarm-state control. Removed active Tahajjud-only/Other early worship controls and clarified reset/save behavior.

### `subh-context-spec-integrity-review-v1.md`

Rewritten as a future drift-prevention checklist capturing the conflicts resolved in this pass.

### `subh-context-tags-integration-addendum-v1.md`

Rewritten to integrate context tags without reintroducing purpose/status tags.

### `subh-day-purpose-opportunity-resolution-spec-v1.md`

Rewritten to preserve opportunity/intention/execution/outcome/analytics separation while aligning Suhoor and deferred non-fasting before-Fajr behavior.

### `subh-early-worship-boundary-spec-v2.md`

Rewritten as Suhoor boundary spec while retaining filename for compatibility. Final-third semantics now apply to Suhoor/fasting, not active Tahajjud-only MVP flows.

### `subh-fajr-time-calculation-determination-selection-spec-v1.md`

Reviewed and rewritten only as a timing-source contract for reconciled MVP. It now explicitly does not own Quiet/Pause logic.

### `subh-month-planning-gregorian-hijri-spec-v2.md`

Rewritten to align Month/list planning with Next 7 and Day Detail routing. Clarified generated-vs-stored behavior and row doctrine.

### `subh-morning-hero-item-spec-v15.md`

Rewritten as a clean six-slot fixed-height Hero spec. Removed stale three-segment selector and non-fasting Pre-Fajr examples. Preserved liquid-glass, slider/timeline, CTA sequencing, and state table behavior.

### `subh-morning-resolution-contract-state-ownership-spec-v3.md`

Rewritten around separated resolver layers and ownership matrix. Added precedence, snapshot requirements, surface consumption rules, and active execution behavior.

### `subh-mvp-interaction-inventory-v4.md`

Rewritten as active scenario-group inventory. Historical scenario IDs are preserved in archived original; active file now marks stale scenario families deferred.

### `subh-mvp-interaction-tier-exposure-matrix-v2.md`

Rewritten to map reconciled interactions to Free/Plus and prevent paywalling basic wake safety.

### `subh-next-7-mornings-wake-forecast-spec-v2.md`

Rewritten to enforce Next 7, row navigation to Detail, no inline edits, and compact row status/tag rules.

### `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`

Rewritten to clarify generated vs durable future mornings, anchors, hydration, Quiet date-specificity, and global Pause.

### `subh-pricing-entitlement-spec-v3.md`

Rewritten to align pricing language and entitlement seams with reconciled core utility.

### `subh-primary-morning-context-presentation-spec-v1.md`

Rewritten to keep context explanation separate from wake purpose, alarm state, and completion.

### `subh-quick-wake-mode-intent-mutation-contract-v2.md`

Rewritten around commands instead of quick modes. Replaced Quiet-as-selector and Pre-Fajr/Early/Fast language with explicit Fajr/Suhoor, Quiet, Pause, ring-once, reset, fasting-purpose, and acknowledgement mutations.

### `subh-quiet-mode-quiet-morning-contract-spec-v1.md`

Rewritten as Quiet + indefinite Pause contract. Removed active-session Quiet confirmation flow and clarified entry points, restoration, delivery, logging, and copy.

### `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`

Promoted from May 29 addendum to May 30 implementation source of truth. Preserved the detailed state table and flow rules while clarifying that active specs have now been reconciled.

### `subh-shared-day-tag-presentation-contract-v1.md`

Rewritten to enforce middle-lane opportunity/context tags only and trailing status for Quiet/Paused/Rings once.

### `subh-sound-alarm-settings-spec-v1.md`

Rewritten to keep sound roles separate from alarm activation and clarify Quiet/Pause interaction with wake-alarm family.

### `subh-wake-session-testing-and-simulation-harness-spec-v3.md`

Rewritten around a usable debug Scenario Launcher, simulated time, Home/Detail live preview, and reconciled wake-session scenarios.

### `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`

Rewritten to settle wake execution: I’m awake is the active action, system dismissal counts as acknowledgement, follow-ups respect purpose boundaries, and Quiet is unavailable after execution starts.

### `subh-weekly-fajrcast-card-spec-v14.md`

Rewritten as inspection-only seven-morning summary. Clarified it uses the same seven dates as Next 7 and mutates nothing.

## Why originals were archived

The original files contained many valid historical details, but also many stale active-looking examples. Rather than silently deleting the history, this package preserves the originals in an archive folder and makes the root-level files implementation-facing. This avoids accidental feature removal while preventing Codex from implementing superseded requirements.

## Deliberate decisions made during reconciliation

1. I adopted the latest alignment-spec rule that explicit system/AlarmKit dismissal counts as `I’m awake` for MVP, with acknowledgement source preserved. This resolves the older contradictory “alarm stop does not confirm awake” scenarios.
2. I adopted the latest alignment-spec rule that Quiet is unavailable after first alarm begins. This removes the older active-session Quiet confirmation sheet.
3. I treated Suhoor as fasting-oriented for MVP and deferred non-fasting before-Fajr flows. This follows the newer project direction and removes active Tahajjud-only / Other early worship controls.
4. I separated Suhoor wake acknowledgement from Fajr wake acknowledgement, so a Suhoor user can still confirm `I’m awake for Fajr` after Fajr begins before logging `I prayed Fajr`.
5. I kept `Paused` as approved compact row copy while retaining `Alarms paused` for Hero/Detail primary copy.
6. I kept all basic wake and safety controls Free/core and reserved Plus for insight/history/advanced behavior-shaping features.

## Follow-up implementation audit focus

- Verify Home Hero Slot 3 action sheets exist and Slot 6 selector is only `Fajr | Suhoor`.
- Verify active wake execution hides Quiet and purpose switching.
- Verify `I’m awake` cancels follow-ups and system dismissal produces the same acknowledgement state.
- Verify Quiet/Pause preserve separate Fajr/Suhoor alarm configs.
- Verify Next 7 and Month rows navigate to Day Detail and do not expose inline toggles.
- Verify pricing gates do not block core wake actions.

## Automated term audit note

The active specs still mention deprecated terms only inside explicit “do not expose,” “legacy,” “deferred,” or compatibility sections. They should not appear as active user-facing labels or active selectable MVP states.
