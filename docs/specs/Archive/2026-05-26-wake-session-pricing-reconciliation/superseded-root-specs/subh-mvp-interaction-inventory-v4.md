# Subh MVP Interaction Inventory

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-inventory-v4.md` |
| Version | 4 |
| Spec status | Source-of-truth stabilized MVP inventory; pre-implementation-audit draft; aligned to Next 7 Days horizon |
| Supersedes | `subh-mvp-interaction-inventory-v3.md`; Archive/subh_mvp_interaction_inventory_v2.md |
| Related specs | `00-subh-spec-index-v2.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md` |
| Owning domain / surface | MVP interaction coverage and traceability |
| Implementation audit status | Needs implementation audit |

## Purpose
Inventory MVP user scenarios and preserve scenario IDs so later audits can trace specs, code, tests, and product coverage without losing behavior.

## What This Spec Owns
- Scenario ID catalog and coverage status vocabulary.
- Spec ownership map across MVP interactions.
- Later implementation-audit prompt and traceability queue.

## Normative Requirements
The normative requirements in this spec are the explicit MUST, SHALL, required, acceptance, and scenario statements below. Recommendations, implementation guidance, examples, and future-direction notes are advisory unless this spec or a later canonical spec promotes them to requirements.

## Out of Scope / Deferred
- Code/spec divergence classification is deferred to a later implementation audit.
- App code, tests, and OpenSpec library artifacts are out of scope for this docs-only cleanup.
- Historical archive filenames are kept only as historical references and are not promoted back into the active spec set.

## Open Questions and Deferred Work
Open questions, TODO-style notes, future ideas, and implementation audit prompts below are retained as the working queue for later spec improvement. This cleanup standardizes them as deferred work rather than claiming they are resolved.

## Cleanup Notes
- This file was renamed and header-normalized in the Desktop working-spec cleanup pass.
- The Desktop folder remains the canonical working-spec location.
- Implementation completeness claims in older prose should be treated as historical context until the later audit updates this field.

## MVP Suhoor Alignment Addendum

This addendum supersedes older inventory language that treated `Pre-Fajr`, `Tahajjud only`, or `Other early worship` as active MVP choices.

The active MVP mode set is:

```text
Suhoor | Fajr | Quiet
```

For MVP:
- Suhoor is the only user-selectable before-Fajr wake mode.
- Tahajjud-only and Other early worship are deferred from active MVP UI and active MVP resolution.
- Legacy `Early`, `Fast`, and `Pre-Fajr` saved values may be decoded as compatibility aliases, but they must normalize into Suhoor-compatible behavior.
- Suhoor owns fasting-intention selection. It defaults to the best supported Sunnah fasting opportunity when one exists; otherwise it defaults to voluntary fasting, with supported fasting-intention overrides preserved where valid.
- Alarm Detail saves wake-mode changes and reset-to-default immediately. It does not require a staged Done-only save box.

Scenario impact:
- S035-S045 are renamed from Pre-Fajr intention scenarios to Suhoor quick-mode scenarios. Non-Suhoor before-Fajr intention scenarios in that range are deferred for MVP.
- S054 and S096 no longer land on Tahajjud-only as an MVP fallback. Eid / fasting-forbidden handling remains owned by the day-purpose and opportunity resolver.
- S038, S042, S092, and S227 are explicitly deferred from active MVP because they depend on Other early worship.


## Next 7 Days / Weekly Fajrcast Alignment Addendum

This v4 addendum supersedes older inventory language that treated `Next 10 Mornings` as the active Home forecast surface.

The active near-term Home forecast is:

```text
Next 7 Days
```

For MVP:
- The expanded forecast shows seven rows, not ten.
- Row 1 is the next immediate alarm or next relevant morning.
- Rows 2–7 are the following six mornings.
- Weekly Fajrcast uses the same seven visible dates in the same order.
- Expanding, collapsing, scrolling, or inspecting the forecast remains UI-only.
- Displaying seven days must not imply all seven are operationally scheduled.

Scenario impact:
- S074–S080 are renamed from collapsed `Next 10 Mornings` scenarios to collapsed `Next 7 Days` scenarios.
- S075 now expects seven upcoming days.
- Scenario IDs are preserved.

## 0. v4 purpose

This v4 inventory preserves the complete MVP interaction universe from v2 while stabilizing terminology, ownership, and spec-coverage status.

The goal is not to shrink scope. The goal is to make the inventory precise enough to drive spec updates, Codex implementation, QA, and traceability without losing any behavior.

### v4 invariants

```text
Scenario IDs preserved: S001–S235
Scenario count preserved: 235
No scenario removed: true
No behavior deferred or removed by implication: true
Implementation status: not audited in this document
Spec coverage status: classified by scenario group
```

---

## 1. Authority and non-removal rule

Every scenario listed in this inventory remains MVP scope unless a later product-approved inventory explicitly marks the scenario ID as `Deferred` or `Removed`.

A wording cleanup is not a scope reduction. A surface hiding a control is not enough to remove the underlying domain behavior. A shared-contract move is not a feature deletion.

Allowed change states are:

| Change state | Meaning |
|---|---|
| `Preserved` | Behavior remains MVP and must be represented in specs/code/tests. |
| `Renamed` | Behavior remains MVP but wording changes. |
| `Moved` | Ownership changes to a better spec; behavior remains MVP. |
| `Split` | One overloaded concept becomes multiple explicit concepts. |
| `Merged` | Duplicate descriptions become one canonical rule. |
| `Deferred` | Behavior is intentionally not in MVP; requires scenario IDs and approval. |
| `Removed` | Behavior is intentionally deleted; requires scenario IDs and approval. |

---

## 2. Canonical terminology

| v2 / legacy term | v3 canonical term | Change state | Required handling |
|---|---|---|---|
| `Early` | `Suhoor` | MVP alias / compatibility | Keep only as a legacy decode/migration alias. New UI and specs use Suhoor. |
| `Pre-Fajr` | `Suhoor` | MVP alias / compatibility | Keep only as a legacy decode/migration alias unless a later post-MVP spec reintroduces non-Suhoor before-Fajr waking. |
| `Early reason` / `Pre-Fajr intention` | `Suhoor intention` | Replaced for MVP | Suhoor owns the before-Fajr fasting intention path. |
| `Tahajjud` / `Tahajjud only` as non-fasting before-Fajr reason | Deferred | Deferred | Not active MVP. Requires a later product decision to reintroduce. |
| `Fast` as quick mode | `Suhoor` | Replaced for MVP | Fasting is carried by Suhoor intention, not by a separate top-level Fast mode. |
| `Fasting` | `Suhoor fasting intention` | Preserved | May carry a fasting intention/subtype when Suhoor is active. |
| `Other` under Early / Pre-Fajr | `Other early worship` | Deferred | Deferred from active MVP for S038, S042, S092, and S227. |
| `Other` under fasting type | `Other fast` | Preserved where supported | A fasting intention outside the named fast taxonomy. Distinct from deferred Other early worship. |
| `Quiet` | `Quiet` | Preserved | Intentional date-specific suppression; not a permission failure. |
| `Adhan off` | Audio preference only | Split | Does not mean alarm off. Alarm off is Quiet only. |

### 2.1 Canonical interaction model

```text
Quick wake mode:
- Suhoor
- Fajr
- Quiet

Suhoor intention:
- Fasting / suhoor intention

Fasting intention, when Suhoor is active:
- Ramadan fast
- Opportunity-based Sunnah fast
- Voluntary fast
- Qada
- Vow
- Kaffarah
- Other fast, if supported by the fasting taxonomy
```

---

## 3. Core MVP decisions now locked

1. All scenarios in this inventory are MVP scope unless explicitly marked otherwise by scenario ID in a later approved inventory.
2. The Home screen is hero-first.
3. The immediate next morning is controlled from the Home hero.
4. Main wake modes are: `Suhoor | Fajr | Quiet`.
5. Selecting `Suhoor` exposes the supported Suhoor / fasting intention path.
6. Tahajjud-only and Other early worship are deferred from active MVP selection.
7. If `Suhoor` is selected but no specific fasting opportunity exists, the app resolves the intention to `Voluntary fast`.
8. If `Suhoor` is selected on a day with a supported fasting opportunity, fasting defaults to that opportunity.
9. Legacy `Pre-Fajr`, `Early`, or `Fast` values are compatibility aliases that normalize into Suhoor behavior.
10. Users can override fasting intention/subtype on all non-Ramadan days where fasting is available.
11. Ramadan fasting is locked to Ramadan only. The user cannot override Ramadan into Qada, voluntary, Sunnah opportunity, or another fasting intention.
12. On Eid days, fasting is unavailable; Eid / fasting-forbidden behavior remains owned by the day-purpose and opportunity resolver rather than falling back to Tahajjud-only.
13. Switching away from `Suhoor` preserves the Suhoor intention for that date where valid.
14. Switching away from `Suhoor` does not preserve manual wake-time adjustment. Wake time returns to the selected mode default.
15. Quiet suppresses alarm, notification, and adhan behavior for that date only.
16. Quiet does not erase underlying day meaning or the preserved Suhoor intention.
17. Permission failure, platform delivery failure, or missing pending state must not be displayed as Quiet.
18. Adhan controls are available only in Day Detail, not on Home.
19. Fajr adhan audio state is separate from alarm activation. Turning adhan off does not turn the wake alarm off.
20. Monthly graphs show the baseline trend and use dots/markers for user modifications or schedule exceptions.
21. Date-specific Day Detail overrides beat recurring boundary rules.
22. Day Detail wake-mode edits save immediately.
23. Day Detail has a prominent Reset to Defaults action that applies immediately.
24. Past months are hidden in MVP. They are not browsable and not view-only.
25. Current month plus roughly the next 12 months are browsable and editable.
26. Future edits are saved and later hydrate Home, Next 7 Days, and Weekly Fajrcast when the date approaches.
27. Display horizon, edit horizon, and active scheduled horizon are distinct.
28. The delivery layer schedules only resolver-materialized events inside the active scheduled horizon.
29. Opportunity, intention, wake plan, completion, and analytics credit are separate concepts.
30. Surfaces render resolved snapshots and emit intents; they must not re-derive Fajr end, final-third start, day meaning, or delivery status locally.

---

## 4. Resolution model

The app should resolve each morning in this order:

1. Calculate base prayer times, location/timezone context, and calendar context.
2. Resolve observance opportunities, including Ramadan, Eid, Sunnah fasting opportunities, and other day meanings.
3. Apply global default wake behavior.
4. Apply recurring boundary rules / presets.
5. Apply anchored intentions and date-specific overrides from Home, Day Detail, Next 7 Days, Month browsing, or Adjusted Days.
6. Resolve `Suhoor`, `Fajr`, or `Quiet` mode.
7. Resolve Suhoor intention through the supported fasting-intention path.
8. Treat legacy `Pre-Fajr`, `Early`, or `Fast` values as compatibility aliases for Suhoor.
9. Apply Quiet suppression as an overlay, without deleting underlying day meaning or preserved intention.
10. Resolve final wake boundary, wake time, adhan behavior, tags, materialized events, and schedule/delivery status.
11. Persist only durable user meaning, settings, overrides, completions, and delivery/audit state. Do not persist generated defaults merely because they were displayed.
12. Schedule only what needs to be operationally scheduled inside the active scheduled horizon.

---

## 5. Coverage and ownership legend

`Spec coverage status` means whether the current spec set sufficiently defines the interaction. It does **not** mean the code implements the scenario. Code implementation remains `Not audited` until a repo audit is performed.

| Status | Meaning |
|---|---|
| `Covered` | Existing specs are likely sufficient to implement/audit the scenario. |
| `Partially covered` | Existing specs cover part of the scenario, but a shared contract, host spec, or clarification is still needed. |
| `Missing dedicated spec` | The scenario is MVP but does not yet have a clear owning spec. |
| `Conflict` | Current specs or wording disagree. Preserve scenario scope until explicitly reconciled. |
| `Needs code audit` | Implementation status is unknown and should be classified by Codex/repo audit. |

---

## 6. Scenario group ownership matrix

| Group | Scenario range | Area | Primary owning spec | Supporting specs | Spec coverage | Completion needed |
|---|---:|---|---|---|---|---|
| A | S001–S020 | First launch and onboarding | New Onboarding and Initial Setup Spec | Location Settings; Fajr Time Calculation; Alarm Delivery Reliability; Settings Hub | Missing dedicated spec | Create onboarding spec with first launch, incomplete setup, permissions, location, method, and default wake behavior. |
| B | S021–S027 | Home arrival and hero viewing | Morning Hero Item Spec; Home Screen Composition Spec | Morning Resolution; Day Purpose; Alarm Delivery; Permission Warning Presentation | Partially covered — update required | Hero is specified; Home composition and reliability warning presentation still need dedicated ownership. |
| C | S028–S034 | Home hero: Fajr mode | New Quick Wake Mode and Intent Mutation Contract | Morning Hero; Morning Resolution; Alarm Delivery | Partially covered — shared contract needed | Normalize Suhoor/Fajr/Quiet idempotency, restoration, manual-adjustment clearing, and delivery handoff. |
| D | S035–S045 | Home hero: Suhoor mode and intentions | New Quick Wake Mode and Intent Mutation Contract | Morning Hero; Alarm Detail; Morning Resolution; Early Worship Boundary | Updated by MVP Suhoor addendum | Rename Pre-Fajr scenarios to Suhoor where they describe before-Fajr fasting. Defer Tahajjud-only and Other early worship scenarios by scenario ID. |
| E | S046–S055 | Home hero: Suhoor fasting behavior | Day Purpose / Opportunity / Intention Spec | Morning Hero; Alarm Detail; Quick Wake Contract; Morning Resolution | Partially covered — UI/domain reconciliation needed | Keep fasting opportunity separate from fasting intention; preserve non-Ramadan overrides and Ramadan/Eid locks. |
| F | S056–S062 | Home hero: Quiet mode | New Quiet Overlay and Restore Contract | Morning Resolution; Alarm Delivery; Morning Hero; Alarm Detail | Partially covered — shared contract needed | Define Quiet as intentional suppression that preserves underlying meaning and Suhoor intention. |
| G | S063–S070 | Home hero: wake-time adjustment | New Wake Adjustment Preview / Commit / Reset Contract | Morning Hero; Alarm Detail; Morning Resolution; Alarm Delivery | Partially covered — shared contract needed | Define drag, save, reset, mode-switch clearing, and displayed/scheduled wake matching. |
| H | S071–S073 | Home hero: adhan exposure | Alarm Detailed View Spec | Morning Hero; Alarm Delivery; Morning Resolution | Mostly covered — confirm through code audit | Keep adhan controls out of Home and keep audio role separate from alarm activation. |
| I | S074–S080 | Collapsed Next 7 Days | Next 7 Days Spec; New Home Screen Composition Spec | Alarm Detail; Morning Resolution; Planning Horizon; Day Purpose; Weekly Fajrcast | Partially covered — Home composition missing | Next 7 Days card behavior exists; Home composition must own placement/collapse/routing and alignment with Weekly Fajrcast. |
| J | S081–S088 | Day Detail entry and viewing | Alarm Detailed View Spec | Home Composition; Next 7 Days; Month Browsing; Adjusted Days; Day Purpose | Partially covered — entry routes missing | Alarm Detail exists; missing surfaces must define routes into it. |
| K | S089–S109 | Day Detail editing | Alarm Detailed View Spec; New Quick Wake Mode Contract | Day Purpose; Alarm Delivery; Wake Adjustment Contract; Quiet Contract | Updated by MVP Suhoor addendum | Use Suhoor/Fajr/Quiet, defer Other early worship, and treat Reset to Defaults plus wake-mode changes as immediate-save behavior. |
| L | S110–S115 | Browse by Month entry | New Home Screen Composition Spec; New Month Browsing Spec | Planning Horizon; Alarm Detail | Missing dedicated spec | Define Browse by Month card, expansion, full browser entry, and Gregorian/Hijri switch behavior. |
| M | S116–S122 | Gregorian month browsing | New Month Browsing Spec | Planning Horizon; Alarm Detail; Fajr Time Calculation | Missing dedicated spec | Define current-month lower bound, future horizon, day-list behavior, and routing. |
| N | S123–S129 | Hijri month browsing | New Month Browsing Spec; New Hijri Calendar Settings / Review State Spec | Planning Horizon; Day Purpose; Alarm Detail | Missing / partially covered | Planning policy exists; browsing UI and Hijri mapping/review interactions need specification. |
| O | S130–S134 | Monthly Fajrcast | New Monthly Fajrcast Spec | Planning Horizon; Morning Resolution; Fajr Time Calculation; Month Browsing | Missing dedicated spec | Define monthly graph, markers, scrubbing, highlighting, and no-persist inspection behavior. |
| P | S135–S143 | Monthly day list and future edits | New Month Browsing and Monthly Day List Spec | Planning Horizon; Morning Resolution; Alarm Detail; Alarm Delivery Reliability | Missing / partially covered | Define future override persistence, hydration into Home/Next 7 Days, and active scheduled horizon handoff. |
| Q | S144–S154 | Adjusted Days repository | New Adjusted Days Repository Spec | Planning Horizon; Alarm Detail; Morning Resolution; Home Composition | Missing dedicated spec | Define adjusted-day criteria, filters, reset one/all, and refresh propagation. |
| R | S155–S159 | Weekly Fajrcast | Weekly Fajrcast Spec; New Home Screen Composition Spec | Morning Resolution; Fajr Time Calculation; Planning Horizon | Conflict / partially covered | Weekly chart spec exists; Home card shell must decide collapsed/expanded behavior without changing chart logic. |
| S | S160–S167 | Settings: entry and visible sections | New Settings Hub Spec | Location; Prayer Time; Hijri Settings; Boundary Rules; About/Feedback | Missing dedicated spec | Define settings sections and explicitly hidden/removed technical settings. |
| T | S168–S175 | Settings: location | New Location Settings and Manual City Spec | Fajr Time Calculation; Planning Horizon; Alarm Delivery Reliability | Missing / partially covered | Define automatic/manual location, permission fallback, city search, recomputation, and override preservation. |
| U | S176–S182 | Settings: prayer time | Fajr Time Calculation Spec; New Prayer Time Settings Spec | Morning Resolution; Alarm Delivery; Settings Hub | Partially covered — settings surface needed | Prayer-time domain exists; settings UI and Fajr-end adjustment behavior need finalization. |
| V | S183–S189 | Settings: Hijri calendar | New Hijri Calendar Settings / Review State Spec | Planning Horizon; Day Purpose; Morning Resolution; Month Browsing | Missing / partially covered | Planning policy exists; UI, invalid-intention review, and user explanation states need specification. |
| W | S190–S199 | Settings: recurring boundary rules | New Recurring Boundary Rules / Presets Spec | Morning Resolution; Planning Horizon; Alarm Detail | Missing dedicated spec | Define rule creation/editing/disablement, priority, and conflicts with date-specific overrides and Quiet. |
| X | S200–S204 | About and feedback | New About and Feedback Spec | Settings Hub | Missing dedicated spec | Define About content, feedback composer, fallback path, and no-state-change guarantees. |
| Y | S205–S211 | Permissions after onboarding | New Permission and Reliability Warning Presentation Spec | Alarm Delivery Reliability; Location Settings; Home Hero; Alarm Detail | Missing / partially covered | Delivery domain exists; user-facing warning surfaces and restore flows need specification. |
| Z | S212–S219 | Alarm execution and post-alarm behavior | New Alarm Execution and Post-Alarm Behavior Spec | Alarm Delivery Reliability; Morning Resolution; Planning Horizon | Missing / partially covered | Define ring/dismiss/open, post-wake advancement, time changes, travel, and Quiet/failure interpretation. |
| AA | S220–S225 | Cross-surface consistency | Morning Resolution Contract | Planning Horizon; Alarm Delivery Reliability; all surface specs | Partially covered — needs traceability/code audit | Use one resolved morning graph; verify all surfaces, persistence, scheduling, and resets align by scenario ID. |
| AB | S226–S235 | Rapid and repeated interactions | New Quick Wake Mode Contract; Morning Resolution Contract | Morning Hero; Alarm Detail; Next 7 Days; Home Composition; Alarm Delivery Reliability | Partially covered — needs interaction stress tests | Define idempotency, rapid mutation ordering, final-state persistence, and no duplicate scheduling/state records. |

---

## 7. Scenario inventory

Each scenario below is preserved from v2/v3 and reconciled to current MVP terminology, including the Next 7 Days forecast horizon. Scenario IDs are intentionally unchanged.

### A. First launch and onboarding

Scenario IDs: `S001–S020`
Primary owning spec: New Onboarding and Initial Setup Spec
Supporting specs: Location Settings; Fajr Time Calculation; Alarm Delivery Reliability; Settings Hub
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Create onboarding spec with first launch, incomplete setup, permissions, location, method, and default wake behavior.

S001. User opens Subh for the first time. The onboarding introduction appears.
S002. User exits before completing onboarding. No active alarm should be assumed.
S003. User returns after exiting onboarding. Onboarding resumes or restarts in a clear state.
S004. User reads onboarding introduction and continues.
S005. User chooses automatic location.
S006. User grants automatic location permission. App uses device location for prayer times.
S007. User denies automatic location permission. App prompts for manual city or retry.
S008. User dismisses the location permission prompt. App treats location as unresolved.
S009. User chooses manual city.
S010. User searches for a city.
S011. User selects a city. App uses that city for prayer times.
S012. User cannot find a city. App offers retry, nearby/manual alternative, or automatic location.
S013. User changes selected city during onboarding.
S014. User accepts default prayer calculation method.
S015. User changes prayer calculation method.
S016. User accepts default wake behavior.
S017. User grants alarm/notification permission. App can schedule wake behavior.
S018. User denies alarm/notification permission. App enters limited reliability state.
S019. User completes onboarding with all requirements satisfied. Home opens ready.
S020. User completes onboarding with partial setup. Home opens with visible missing-requirement warning.

### B. Home arrival and hero viewing

Scenario IDs: `S021–S027`
Primary owning spec: Morning Hero Item Spec; Home Screen Composition Spec
Supporting specs: Morning Resolution; Day Purpose; Alarm Delivery; Permission Warning Presentation
Spec coverage status: **Partially covered — update required**
Implementation status: **Not audited**
Completion needed: Hero is specified; Home composition and reliability warning presentation still need dedicated ownership.

S021. User lands on Home after onboarding. Hero is visually dominant.
S022. User views immediate next morning wake time.
S023. User views Fajr start context.
S024. User views current mode: Suhoor, Fajr, or Quiet.
S025. User views current intention only when applicable.
S026. User views permission/reliability state if degraded.
S027. User views Ramadan, Eid, fasting opportunity, Quiet, custom, or Suhoor tags where applicable.

### C. Home hero: Fajr mode

Scenario IDs: `S028–S034`
Primary owning spec: New Quick Wake Mode and Intent Mutation Contract
Supporting specs: Morning Hero; Morning Resolution; Alarm Delivery
Spec coverage status: **Partially covered — shared contract needed**
Implementation status: **Not audited**
Completion needed: Normalize Suhoor/Fajr/Quiet idempotency, restoration, manual-adjustment clearing, and delivery handoff.

S028. User views default Fajr mode. Wake uses the default Fajr-based timing.
S029. User taps Fajr while already in Fajr. State remains stable.
S030. User taps Fajr repeatedly. No duplicate alarms or duplicate state records are created.
S031. User switches from Suhoor to Fajr. Suhoor intention is preserved for that date where valid but inactive.
S032. User switches from Suhoor to Fajr. Manual wake-time adjustment is cleared/reset to the selected mode default.
S033. User switches from Quiet to Fajr. Quiet suppression is removed.
S034. User switches from Quiet to Fajr. Alarm is active again if permissions allow.

### D. Home hero: Suhoor mode and intentions

Scenario IDs: `S035–S045`
Primary owning spec: New Quick Wake Mode and Intent Mutation Contract
Supporting specs: Morning Hero; Alarm Detail; Morning Resolution; Early Worship Boundary
Spec coverage status: **Updated by MVP Suhoor addendum**
Implementation status: **Not audited**
Completion needed: Keep Suhoor as the only active MVP before-Fajr mode. Deferred scenarios require later product approval before implementation.

S035. User selects Suhoor. Suhoor / fasting intention state becomes active.
S036. User selects Suhoor but has no specific fasting opportunity. App resolves to voluntary fasting.
S037. Deferred for MVP: non-fasting Tahajjud-only before-Fajr selection.
S038. Deferred for MVP: Other early worship before-Fajr selection.
S039. User selects Suhoor. Fasting intention controls appear where the surface supports detailed selection.
S040. Deferred for MVP: switching from Tahajjud-only to Fasting.
S041. Deferred for MVP: switching from Fasting to Tahajjud-only.
S042. Deferred for MVP: switching from Fasting to Other early worship.
S043. User taps Suhoor repeatedly. State remains stable and intention is not duplicated.
S044. User switches Fajr -> Suhoor -> Fajr -> Suhoor. Preserved Suhoor intention returns where valid, but time adjustment does not.
S045. User switches Suhoor -> Quiet -> Suhoor. Preserved Suhoor intention returns where valid, but time adjustment does not.

### E. Home hero: Suhoor fasting behavior

Scenario IDs: `S046–S055`
Primary owning spec: Day Purpose / Opportunity / Intention Spec
Supporting specs: Morning Hero; Alarm Detail; Quick Wake Contract; Morning Resolution
Spec coverage status: **Partially covered — UI/domain reconciliation needed**
Implementation status: **Not audited**
Completion needed: Keep fasting opportunity separate from fasting intention; preserve non-Ramadan overrides and Ramadan/Eid locks.

S046. User selects Suhoor on a day with a fasting opportunity. App defaults to that opportunity-based voluntary fast.
S047. User selects Suhoor on a day without a fasting opportunity. App defaults to general voluntary fast.
S048. User overrides opportunity-based fast to Qada on a non-Ramadan day.
S049. User overrides opportunity-based fast to general voluntary fast on a non-Ramadan day.
S050. User overrides opportunity-based fast to another available personal fasting intention on a non-Ramadan day.
S051. User returns from override to the default fasting opportunity.
S052. User selects Suhoor during Ramadan. Fasting intention is locked to Ramadan where Ramadan context is resolved.
S053. User attempts to select Qada, voluntary, Sunnah opportunity, or other fasting intention during Ramadan. App prevents or hides those options.
S054. User selects Suhoor on an Eid day. App follows the day-purpose / fasting-forbidden resolver rather than falling back to Tahajjud-only.
S055. User attempts to select Fasting on an Eid day. Fasting is unavailable.

### F. Home hero: Quiet mode

Scenario IDs: `S056–S062`
Primary owning spec: New Quiet Overlay and Restore Contract
Supporting specs: Morning Resolution; Alarm Delivery; Morning Hero; Alarm Detail
Spec coverage status: **Partially covered — shared contract needed**
Implementation status: **Not audited**
Completion needed: Define Quiet as intentional suppression that preserves underlying meaning and Suhoor intention.

S056. User selects Quiet from Fajr. Alarm, notification, and adhan are suppressed for that date.
S057. User selects Quiet from Suhoor. Underlying Suhoor intention is preserved for that date where valid.
S058. User selects Quiet during Ramadan. Ramadan meaning remains; alarm/adhan are suppressed.
S059. User exits Quiet to Fajr. Quiet suppression is removed.
S060. User exits Quiet to Suhoor. Preserved Suhoor intention returns where valid.
S061. User taps Quiet repeatedly. State remains stable; no duplicate suppression records.
S062. User selects Quiet for one date. Next day remains normal unless separately modified.

### G. Home hero: wake-time adjustment

Scenario IDs: `S063–S070`
Primary owning spec: New Wake Adjustment Preview / Commit / Reset Contract
Supporting specs: Morning Hero; Alarm Detail; Morning Resolution; Alarm Delivery
Spec coverage status: **Partially covered — shared contract needed**
Implementation status: **Not audited**
Completion needed: Define drag, save, reset, mode-switch clearing, and displayed/scheduled wake matching.

S063. User adjusts immediate wake time from Home in Fajr mode. A date-specific time adjustment is saved for the immediate morning.
S064. User adjusts immediate wake time from Home in Suhoor mode. A date-specific Suhoor adjustment is saved for the immediate morning.
S065. User resets immediate wake time to default. The date-specific time adjustment is removed.
S066. User adjusts time and then switches to Fajr. Manual time adjustment is not preserved; selected mode default applies.
S067. User adjusts time and then switches to Suhoor. Manual time adjustment is not preserved; selected mode default applies.
S068. User adjusts time and then switches to Quiet. Quiet suppresses execution; manual adjustment is not preserved across mode change.
S069. User tries to adjust time while Quiet is active. App should disable or clearly suppress the control.
S070. User drags slider repeatedly. Final displayed wake time and scheduled wake time match.

### H. Home hero: adhan exposure

Scenario IDs: `S071–S073`
Primary owning spec: Alarm Detailed View Spec
Supporting specs: Morning Hero; Alarm Delivery; Morning Resolution
Spec coverage status: **Mostly covered — confirm through code audit**
Implementation status: **Not audited**
Completion needed: Keep adhan controls out of Home and keep audio role separate from alarm activation.

S071. User looks for adhan controls on Home. They are not shown.
S072. User wants to edit adhan for a date. User must open Day Detail.
S073. Quiet is active for a date. Adhan is inactive/suppressed for that date.

### I. Collapsed Next 7 Days

Scenario IDs: `S074–S080`
Primary owning spec: Next 7 Days Spec; New Home Screen Composition Spec
Supporting specs: Alarm Detail; Morning Resolution; Planning Horizon; Day Purpose
Spec coverage status: **Partially covered — Home composition missing**
Implementation status: **Not audited**
Completion needed: Next 7 Days card behavior exists; Home composition must own placement/collapse/routing.

S074. User sees collapsed Next 7 Days. It does not visually compete with the hero.
S075. User expands Next 7 Days. Seven upcoming days appear.
S076. User collapses Next 7 Days. No wake state changes.
S077. User scrolls/inspects expanded Next 7 Days. UI-only interaction.
S078. User taps a day in Next 7 Days. Day Detail opens for that date.
S079. User returns from edited Day Detail. The corresponding row updates.
S080. A visible day is edited from Next 7 Days. Home hero updates too when the edited day is the hero target.

### J. Day Detail entry and viewing

Scenario IDs: `S081–S088`
Primary owning spec: Alarm Detailed View Spec
Supporting specs: Home Composition; Next 7 Days; Month Browsing; Adjusted Days; Day Purpose
Spec coverage status: **Partially covered — entry routes missing**
Implementation status: **Not audited**
Completion needed: Alarm Detail exists; missing surfaces must define routes into it.

S081. User opens Day Detail from Home hero.
S082. User opens Day Detail from Next 7 Days.
S083. User opens Day Detail from monthly day list.
S084. User opens Day Detail from Adjusted Days repository.
S085. User views a default ordinary day. Default state is shown.
S086. User views a modified day. Saved override is shown.
S087. User views a Ramadan day. Ramadan context is shown and fasting is locked.
S088. User views an Eid day. Fasting is unavailable.

### K. Day Detail editing

Scenario IDs: `S089–S109`
Primary owning spec: Alarm Detailed View Spec; New Quick Wake Mode Contract
Supporting specs: Day Purpose; Alarm Delivery; Wake Adjustment Contract; Quiet Contract
Spec coverage status: **Conflict / partially covered**
Implementation status: **Not audited**
Completion needed: Use Suhoor/Fajr/Quiet, defer Other early worship, and keep Reset-to-Defaults plus wake-mode edits immediate-save.

S089. User selects Fajr in Day Detail. Selected date becomes Fajr mode.
S090. User selects Suhoor in Day Detail. Suhoor / fasting intention state becomes active.
S091. Deferred for MVP: Tahajjud-only before-Fajr selection in Day Detail.
S092. Deferred for MVP: Other early worship selection in Day Detail.
S093. User selects Suhoor in Day Detail and fasting intention controls appear where supported.
S094. User changes fasting intention in Day Detail on a non-Ramadan day.
S095. User attempts to change fasting intention in Day Detail on Ramadan. App prevents or hides other options.
S096. User selects Suhoor on Eid in Day Detail. App follows the day-purpose / fasting-forbidden resolver rather than falling back to Tahajjud-only.
S097. User selects Quiet in Day Detail. Alarm/notification/adhan are suppressed for that date.
S098. User switches repeatedly among Suhoor, Fajr, and Quiet in Day Detail. Final visible state is the saved state.
S099. User adjusts selected date wake time in Day Detail. Date-specific override is saved if Done is pressed.
S100. User toggles adhan on in Day Detail. Adhan preference is saved for that date if Done is pressed.
S101. User toggles adhan off in Day Detail. Adhan preference is saved for that date if Done is pressed.
S102. User toggles adhan while Quiet is active. Adhan is shown as inactive or suppressed.
S103. User presses Done. Changes are saved and previous screen refreshes.
S104. User expects Back navigation. Intended UI has no Back option.
S105. Platform back/swipe gesture occurs. Implementation should disable it or guard against unsaved changes.
S106. User presses Reset to Defaults. Date returns to calendar/default behavior.
S107. Reset to Defaults on ordinary day returns to Fajr default.
S108. Reset to Defaults on Ramadan day returns to the resolved Ramadan Suhoor / fasting state where Ramadan context is supported.
S109. Reset to Defaults on Eid returns to the app-defined Eid default where fasting is unavailable.

### L. Browse by Month entry

Scenario IDs: `S110–S115`
Primary owning spec: New Home Screen Composition Spec; New Month Browsing Spec
Supporting specs: Planning Horizon; Alarm Detail
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define Browse by Month card, expansion, full browser entry, and Gregorian/Hijri switch behavior.

S110. User sees collapsed Browse by Month card.
S111. User expands Browse by Month card.
S112. User opens full month browsing.
S113. User chooses Gregorian month browsing.
S114. User chooses Hijri month browsing.
S115. User switches between Gregorian and Hijri browsing. Date-specific overrides remain attached to civil dates.

### M. Gregorian month browsing

Scenario IDs: `S116–S122`
Primary owning spec: New Month Browsing Spec
Supporting specs: Planning Horizon; Alarm Detail; Fajr Time Calculation
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define current-month lower bound, future horizon, day-list behavior, and routing.

S116. User views current Gregorian month.
S117. User selects a future Gregorian month within horizon.
S118. User advances to next Gregorian month.
S119. User attempts to go before current month. Past months are hidden.
S120. User attempts to go beyond supported future horizon. App prevents or disables further navigation.
S121. User scrolls the Gregorian month day list. UI-only interaction.
S122. User taps a Gregorian month day. Day Detail opens for that civil date.

### N. Hijri month browsing

Scenario IDs: `S123–S129`
Primary owning spec: New Month Browsing Spec; New Hijri Calendar Settings / Review State Spec
Supporting specs: Planning Horizon; Day Purpose; Alarm Detail
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Planning policy exists; browsing UI and Hijri mapping/review interactions need specification.

S123. User views current Hijri month.
S124. User selects a future Hijri month within horizon.
S125. User browses Ramadan. Ramadan days show locked Ramadan fasting context.
S126. User browses a Hijri month with fasting opportunities. Opportunity tags are shown where applicable.
S127. User browses a Hijri month containing Eid. Fasting is unavailable on Eid days.
S128. User taps a Hijri month day. Day Detail opens for the mapped civil date.
S129. User changes Hijri/Gregorian view while a date is selected. App preserves context where possible.

### O. Monthly Fajrcast

Scenario IDs: `S130–S134`
Primary owning spec: New Monthly Fajrcast Spec
Supporting specs: Planning Horizon; Morning Resolution; Fajr Time Calculation; Month Browsing
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define monthly graph, markers, scrubbing, highlighting, and no-persist inspection behavior.

S130. User views monthly Fajrcast trend. It shows the baseline Fajr/wake trend.
S131. User scrubs monthly graph. Selected day info appears; no persisted state changes.
S132. User taps a graph point. Corresponding day can be highlighted or previewed.
S133. User has modified days in the month. Graph displays dots/markers for exceptions.
S134. User sees graph baseline and row-specific override. UI should make the distinction understandable.

### P. Monthly day list and future edits

Scenario IDs: `S135–S143`
Primary owning spec: New Month Browsing and Monthly Day List Spec
Supporting specs: Planning Horizon; Morning Resolution; Alarm Detail; Alarm Delivery Reliability
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Define future override persistence, hydration into Home/Next 7 Days, and active scheduled horizon handoff.

S135. User views monthly day list. Rows show date, wake time, and tags.
S136. User taps a monthly day. Day Detail opens.
S137. User modifies a day months ahead. Future override is saved after Done.
S138. User revisits a modified future day. Saved override loads.
S139. User resets a modified future day. Override is deleted.
S140. Future override later enters Next 7 Days. Next 7 Days row hydrates saved override.
S141. Future override later becomes immediate next morning. Home hero hydrates saved override.
S142. Future override affects a date within scheduling window. Alarm scheduling uses it.
S143. Future override is outside scheduling window. App saves it without necessarily scheduling immediately.

### Q. Adjusted Days repository

Scenario IDs: `S144–S154`
Primary owning spec: New Adjusted Days Repository Spec
Supporting specs: Planning Horizon; Alarm Detail; Morning Resolution; Home Composition
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define adjusted-day criteria, filters, reset one/all, and refresh propagation.

S144. User opens Adjusted Days repository.
S145. User views future days that differ from default.
S146. User filters adjusted days by Quiet.
S147. User filters adjusted days by Suhoor.
S148. User filters adjusted days by Fasting.
S149. Deferred for MVP: User filters adjusted days by Tahajjud only.
S150. User filters adjusted days by custom wake time.
S151. User taps an adjusted day. Day Detail opens.
S152. User resets one adjusted day. One override is removed.
S153. User resets all adjusted days. Confirmation is required.
S154. Reset all affects immediate or near-term dates. Home, Next 7 Days, and scheduling refresh.

### R. Weekly Fajrcast

Scenario IDs: `S155–S159`
Primary owning spec: Weekly Fajrcast Spec; New Home Screen Composition Spec
Supporting specs: Morning Resolution; Fajr Time Calculation; Planning Horizon
Spec coverage status: **Conflict / partially covered**
Implementation status: **Not audited**
Completion needed: Weekly chart spec exists; Home card shell must decide collapsed/expanded behavior without changing chart logic.

S155. User sees collapsed Weekly Fajrcast.
S156. User expands Weekly Fajrcast.
S157. User scrubs Weekly Fajrcast. UI-only interaction.
S158. User collapses Weekly Fajrcast.
S159. User taps Weekly Fajrcast expecting legacy detail. Legacy detail should not open.

### S. Settings: entry and visible sections

Scenario IDs: `S160–S167`
Primary owning spec: New Settings Hub Spec
Supporting specs: Location; Prayer Time; Hijri Settings; Boundary Rules; About/Feedback
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define settings sections and explicitly hidden/removed technical settings.

S160. User opens Settings.
S161. User opens Location settings.
S162. User opens Prayer Time settings.
S163. User opens Hijri Calendar settings.
S164. User opens Presets/Boundary Rules.
S165. User opens About.
S166. User opens Send Feedback.
S167. User looks for removed technical settings. Morning Rules, Reliability Basic, Quiet Period, and Copy Diagnostics should not appear unless intentionally retained.

### T. Settings: location

Scenario IDs: `S168–S175`
Primary owning spec: New Location Settings and Manual City Spec
Supporting specs: Fajr Time Calculation; Planning Horizon; Alarm Delivery Reliability
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Define automatic/manual location, permission fallback, city search, recomputation, and override preservation.

S168. User views current location mode.
S169. User switches from manual city to automatic location with permission already granted.
S170. User switches from manual city to automatic location and grants permission.
S171. User switches to automatic location and denies permission. App remains unresolved or falls back to manual city.
S172. User switches from automatic to manual city.
S173. User changes manual city.
S174. Location change causes prayer times, Home, Next 7 Days, month views, and scheduling to recompute.
S175. Date-specific overrides remain attached to civil dates after location change.

### U. Settings: prayer time

Scenario IDs: `S176–S182`
Primary owning spec: Fajr Time Calculation Spec; New Prayer Time Settings Spec
Supporting specs: Morning Resolution; Alarm Delivery; Settings Hub
Spec coverage status: **Partially covered — settings surface needed**
Implementation status: **Not audited**
Completion needed: Prayer-time domain exists; settings UI and Fajr-end adjustment behavior need finalization.

S176. User changes calculation method.
S177. User adjusts Fajr start offset.
S178. User adjusts Fajr end offset.
S179. User adjusts Maghrib offset.
S180. User resets prayer-time adjustments.
S181. Prayer-time changes recompute defaults and reschedule affected near-term alarms.
S182. Date-specific overrides remain but resolve against the new base times where applicable.

### V. Settings: Hijri calendar

Scenario IDs: `S183–S189`
Primary owning spec: New Hijri Calendar Settings / Review State Spec
Supporting specs: Planning Horizon; Day Purpose; Morning Resolution; Month Browsing
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Planning policy exists; UI, invalid-intention review, and user explanation states need specification.

S183. User views Hijri month adjustments.
S184. User adds +1 day to a Hijri month.
S185. User subtracts -1 day from a Hijri month.
S186. User resets a Hijri month adjustment.
S187. Hijri adjustment shifts Ramadan, Eid, and fasting opportunity tags.
S188. User changes Hijri adjustment after future Ramadan override exists. Civil-date override remains attached to the civil date.
S189. A saved Ramadan-specific intention becomes invalid after Hijri adjustment. App preserves wake plan and marks/re-resolves calendar meaning safely.

### W. Settings: recurring boundary rules

Scenario IDs: `S190–S199`
Primary owning spec: New Recurring Boundary Rules / Presets Spec
Supporting specs: Morning Resolution; Planning Horizon; Alarm Detail
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define rule creation/editing/disablement, priority, and conflicts with date-specific overrides and Quiet.

S190. User opens boundary-rule settings.
S191. User creates a latest-wake boundary, such as wake no later than 5:30 AM.
S192. User selects weekdays for the boundary rule.
S193. User saves boundary rule. Future defaults recompute.
S194. User edits boundary time. Future defaults recompute.
S195. User disables boundary rule. Lower-priority defaults return unless date-specific overrides exist.
S196. Boundary says 5:30 but default Fajr wake is 5:50. Resolved wake becomes 5:30.
S197. Boundary says 5:30 but Suhoor wake is 4:40. Resolved wake remains 4:40.
S198. Boundary conflicts with date-specific custom time. Date-specific override wins.
S199. Boundary conflicts with Quiet. Quiet wins.

### X. About and feedback

Scenario IDs: `S200–S204`
Primary owning spec: New About and Feedback Spec
Supporting specs: Settings Hub
Spec coverage status: **Missing dedicated spec**
Implementation status: **Not audited**
Completion needed: Define About content, feedback composer, fallback path, and no-state-change guarantees.

S200. User opens About. App info, version, and methodology are readable.
S201. User opens Send Feedback. Email composer opens.
S202. User sends feedback. App state remains unchanged.
S203. User cancels feedback. App state remains unchanged.
S204. Email composer cannot open. App shows an alternate recovery path if available.

### Y. Permissions after onboarding

Scenario IDs: `S205–S211`
Primary owning spec: New Permission and Reliability Warning Presentation Spec
Supporting specs: Alarm Delivery Reliability; Location Settings; Home Hero; Alarm Detail
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Delivery domain exists; user-facing warning surfaces and restore flows need specification.

S205. User revokes alarm/notification permission outside app.
S206. User returns to app after revoking alarm/notification permission. Home shows degraded reliability.
S207. User plans a Suhoor day while alarm permission is missing. Plan is saved but app warns it cannot reliably wake user.
S208. User restores alarm/notification permission. Scheduling resumes.
S209. User revokes location permission while automatic location is active.
S210. User returns to app after location permission is revoked. App prompts for permission restore or manual city.
S211. User restores location permission. Prayer times recompute.

### Z. Alarm execution and post-alarm behavior

Scenario IDs: `S212–S219`
Primary owning spec: New Alarm Execution and Post-Alarm Behavior Spec
Supporting specs: Alarm Delivery Reliability; Morning Resolution; Planning Horizon
Spec coverage status: **Missing / partially covered**
Implementation status: **Not audited**
Completion needed: Define ring/dismiss/open, post-wake advancement, time changes, travel, and Quiet/failure interpretation.

S212. Alarm rings normally. User dismisses or opens app, depending on platform support.
S213. Alarm does not ring because Quiet was selected. This is intentional.
S214. Alarm cannot ring because permission is missing. App treats this as reliability failure, not Quiet.
S215. User opens app after scheduled wake time has passed. Home advances to the next relevant morning.
S216. Day changes at midnight. Home and Next 7 Days refresh to the new date context.
S217. User changes system time zone. App verifies/recomputes relevant local time behavior.
S218. User travels while automatic location is active. App updates location and prayer times.
S219. User travels while manual city is active. App continues using manual city.

### AA. Cross-surface consistency

Scenario IDs: `S220–S225`
Primary owning spec: Morning Resolution Contract
Supporting specs: Planning Horizon; Alarm Delivery Reliability; all surface specs
Spec coverage status: **Partially covered — needs traceability/code audit**
Implementation status: **Not audited**
Completion needed: Use one resolved morning graph; verify all surfaces, persistence, scheduling, and resets align by scenario ID.

S220. User edits tomorrow from Home. Home, Next 7 Days, Weekly Fajrcast, monthly row, and scheduling align.
S221. User edits tomorrow from Next 7 Days. Home hero, Next 7 Days, Weekly Fajrcast, monthly row, and scheduling align.
S222. User edits tomorrow from monthly browsing. Home hero, Next 7 Days, Weekly Fajrcast, monthly row, and scheduling align.
S223. User edits a far-future day from monthly browsing. Monthly row and Adjusted Days update; Home/Next 7 Days/Weekly Fajrcast update later when the date enters their visible horizon.
S224. User resets a day from Adjusted Days. All surfaces return to default for that date.
S225. User changes Settings after editing days. Defaults recompute while date-specific overrides persist.

### AB. Rapid and repeated interactions

Scenario IDs: `S226–S235`
Primary owning spec: New Quick Wake Mode Contract; Morning Resolution Contract
Supporting specs: Morning Hero; Alarm Detail; Next 7 Days; Home Composition; Alarm Delivery Reliability
Spec coverage status: **Partially covered — needs interaction stress tests**
Implementation status: **Not audited**
Completion needed: Define idempotency, rapid mutation ordering, final-state persistence, and no duplicate scheduling/state records.

S226. User rapidly switches Fajr -> Suhoor -> Quiet -> Fajr -> Suhoor.
S227. Deferred for MVP: User rapidly changes non-Suhoor before-Fajr intentions.
S228. User rapidly changes fasting intention on a non-Ramadan day.
S229. User rapidly drags slider and then changes mode.
S230. User opens Day Detail, changes state, presses Done, reopens. Saved state persists.
S231. User opens Day Detail, resets defaults, presses Done, reopens. Default state persists.
S232. User modifies a future day, changes settings, revisits the day. Stored override and recomputed default are coherent.
S233. User repeatedly expands/collapses Next 7 Days, Browse by Month, and Weekly Fajrcast. No product state changes.
S234. Final displayed wake time always matches the scheduled alarm for active, permitted, non-Quiet dates.
S235. Quiet dates never schedule wake alarm, notification, or adhan for that date.

---

## 8. Explicit unresolved decisions

These are **not** removals. They are explicit decisions that must be resolved before implementation is called complete.

| Decision | Affected scenarios | Current v3 stance | Owning next spec/action |
|---|---|---|---|
| Should `Other early worship` be visibly exposed in Home Hero and Day Detail, or preserved internally and explicitly deferred from visible MVP? | S038, S042, S092, S227 and related before-Fajr preservation scenarios | Decided for MVP: deferred from active MVP. Suhoor is the only before-Fajr wake mode. | Quick Wake Mode Contract; Morning Hero update; Alarm Detail update |
| Should Weekly Fajrcast be collapsed on Home by default? | S155–S158, S233 | Inventory preserves collapsed/expanded MVP behavior. Weekly chart spec remains standalone; Home card shell owns collapse policy. | Home Screen Composition Spec |
| Should early-worship wake adjustment hard-clamp to final-third → Fajr begins, or allow later Fajr-window wakes with warnings? | S063–S070, S099, S229 | Preserve adjustment scenarios; boundary validation needs canonical rule. | Wake Adjustment Contract; Early Worship Boundary update |
| Is technical scheduled horizon next-immediate-only or next-immediate plus safety buffer? | S142–S143, S181, S208, S234 | Display horizon is not scheduled horizon; active scheduled horizon needs final implementation policy. | Planning Horizon; Alarm Delivery Reliability; Active Window Builder |
| Does `Reset to Defaults` in Day Detail commit immediately or stage until `Done`? | S103, S106–S109, S231 | Day Detail is Done-only; reset behavior should be staged unless explicitly specified otherwise. | Alarm Detail update; Wake Adjustment/Commit Contract |

---

## 9. Required new or updated specs

### Highest-priority shared contracts

- Quick Wake Mode and Intent Mutation Contract
- Quiet Overlay and Restore Contract
- Wake Adjustment Preview / Commit / Reset Contract
- Home Screen Composition and Supporting Cards Spec

### Missing MVP surface/system specs

- Onboarding and Initial Setup Spec
- Location Settings and Manual City Selection Spec
- Settings Hub Spec
- Prayer Time Settings Spec
- Hijri Calendar Settings and Review State Spec
- Month Browsing and Monthly Day List Spec
- Monthly Fajrcast Spec
- Adjusted Days Repository Spec
- Recurring Boundary Rules / Presets Spec
- Permission and Reliability Warning Presentation Spec
- Alarm Execution and Post-Alarm Behavior Spec
- About and Feedback Spec
- MVP Interaction Traceability Matrix

### Existing specs requiring terminology or scope updates

| Spec | Required update |
|---|---|
| Morning Resolution Contract | Replace remaining `Fast` / `Early` / `Pre-Fajr` top-level mode language with `Suhoor / Fajr / Quiet`; represent fasting as Suhoor intention; defer Other early worship. |
| Morning Hero | Use Suhoor/Fajr/Quiet; defer `Other early worship`; reference shared Quick Wake Contract; keep reliability distinct from Quiet. |
| Alarm Detailed View | Use Suhoor/Fajr/Quiet; defer `Other early worship`; document immediate Reset-to-Defaults behavior; keep adhan audio separate from alarm activation. |
| Next 7 Days | Reference Home Composition for placement/collapse context; keep compact tag suppression separate from domain meaning. |
| Weekly Fajrcast | Keep chart standalone; move collapsed/expanded host behavior to Home Composition. |
| Early Worship Boundary | Preserve early-boundary time geometry for Suhoor only in MVP; do not expose Other early worship unless a later Product decision reintroduces it. |
| Alarm Delivery Reliability | Ensure permission failure, fallback, stale platform state, and missing pending state are never shown as Quiet. |
| Day Purpose | Preserve opportunity vs intention vs completion vs credit separation; define Other fast separately from deferred Other early worship. |

---

## 10. Updated Codex audit prompt

```text
Review the current Subh codebase against `subh-mvp-interaction-inventory-v4.md` and `00-subh-spec-index-v2.md`. For each scenario ID S001-S235, classify implementation status as Implemented, Partially Implemented, Missing, Risky, or Not Testable Yet.

Use MVP Suhoor terminology: Early, Fast, and Pre-Fajr are legacy aliases that normalize to Suhoor; Tahajjud-only and Other early worship are deferred from active MVP; Other fast is a separate fasting intention concept.

Do not treat terminology changes as accidental feature removals. In this MVP pass, Other early worship is explicitly deferred by scenario ID: S038, S042, S092, and S227.

For every Missing, Partial, Risky, or Not Testable scenario, identify relevant files, state models, resolver logic, persistence logic, scheduling/delivery logic, UI components, and tests. Pay special attention to Suhoor intention preservation, manual wake adjustment reset on mode switch, Ramadan lock, Eid fasting unavailability, Quiet suppression, permission failure not becoming Quiet, adhan audio not cancelling the wake alarm, immediate-save Day Detail, Reset to Defaults behavior, date-specific override priority, future override hydration, display/edit horizon vs technical scheduled horizon, and cross-surface consistency.
```

---

## 11. Integrity checklist

- [x] 235 scenarios are present.
- [x] Scenario IDs S001–S235 are preserved.
- [x] No scenarios are marked Deferred.
- [x] No scenarios are marked Removed.
- [x] `Early` is retained only as legacy terminology, not canonical wording.
- [x] `Pre-Fajr` is retained only as legacy terminology, not canonical MVP wording.
- [x] `Other early worship` is explicitly deferred from active MVP by scenario ID.
- [x] `Other early worship` and `Other fast` are distinct.
- [x] Quiet is intentional suppression, not a reliability failure.
- [x] Implementation status is not asserted in this document.
