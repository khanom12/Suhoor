# Subh MVP Interaction Tier Exposure Matrix

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-tier-exposure-matrix-v1.md` |
| Version | 1 |
| Spec status | Draft; companion overlay for MVP interaction inventory and pricing entitlement |
| Date | 2026-05-17 |
| Related specs | `00-subh-spec-index-v1.md`, `subh-mvp-interaction-inventory-v3.md`, `subh-pricing-entitlement-spec-v1.md`, `subh-morning-resolution-contract-state-ownership-spec-v2.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-quick-wake-mode-intent-mutation-contract-v1.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v2.md`, `subh-morning-hero-item-spec-v14.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-10-mornings-wake-forecast-spec-v4.md`, `subh-weekly-fajrcast-card-spec-v13.md` |
| Owning domain / surface | Tier exposure overlay for MVP interaction scenarios, feature access, paywall entry points, downgrade/upgrade interaction traceability |
| Implementation audit status | Needs implementation audit |

---

## Purpose

This specification maps the existing MVP interaction inventory scenarios `S001-S235` to Subh's pricing and entitlement model.

It answers:

```text
Which interaction groups are available in Free, Plus, Complete, Complete Lifetime, Trial Complete, and Ramadan Preview?
Which existing MVP scenarios remain universal regardless of tier?
Which scenarios are visible but locked in lower tiers?
Which scenarios can be viewed, edited, scheduled, logged, or restored only with a higher entitlement?
Which new entitlement/paywall interaction scenarios are required in addition to S001-S235?
How should Codex sequence implementation so pricing seams are not retrofitted dangerously at the end?
```

This document is a companion overlay. It does **not** replace `subh-mvp-interaction-inventory-v3.md`.

---

## Why this is a companion spec instead of rewriting the 235-scenario inventory

The existing interaction inventory already preserves the canonical MVP scenario IDs `S001-S235`. Those IDs are useful because they let later audits trace product behavior, implementation, tests, and regressions without losing scenario identity.

Tier exposure is cross-cutting. It affects nearly every surface, but it should not disturb the scenario catalog itself.

Therefore:

```text
S001-S235 remain the stable interaction IDs.
This spec adds entitlement exposure over those IDs.
Entitlement-specific flows get separate `P` scenario IDs in this document.
```

This avoids three problems:

1. **Scenario churn:** We do not need to rewrite all 235 scenarios every time pricing changes.
2. **Traceability loss:** Existing audits can still use `S001-S235` exactly as before.
3. **Spec bloat:** Pricing logic stays readable as a focused overlay instead of being repeated inside every scenario group.

If Product later wants a single merged inventory, this document can be embedded into `subh-mvp-interaction-inventory-v4.md` as a new tier-exposure section.

---

## Source alignment

This spec assumes the following current product decisions:

1. Subh is one Fajr-centered morning system, not separate Fajr, Suhoor, Ramadan, Qada, and logging engines.
2. The active MVP quick wake modes are:

```text
Suhoor | Fajr | Quiet
```

3. `Suhoor` is the only MVP exposed before-Fajr wake mode.
4. `Tahajjud only`, `Other early worship`, and generic non-fasting `Pre-Fajr` are deferred from active MVP selection.
5. Fasting opportunities are not intentions until the user selects Suhoor or another durable fasting-intention source applies.
6. Display horizon, edit horizon, and active scheduled horizon are distinct.
7. The delivery layer schedules only resolver-materialized events inside the active scheduled horizon.
8. Day Detail edits and resets save immediately in MVP.
9. Opportunity, intention, wake plan, completion, and credit remain separate concepts.
10. Pricing gates access; pricing must not create separate morning-resolution engines.

---

## Pricing doctrine consumed by this spec

This spec consumes the pricing doctrine from `subh-pricing-entitlement-spec-v1.md`:

```text
Free helps the user understand tomorrow.
Plus helps the user control their Fajr week.
Complete helps the user plan and track their Suhoor, fasting, Ramadan, Qada, and Fajr-centered year.
Lifetime grants permanent Complete access for eligible purchased functionality.
```

### Locked working prices

| Tier / product | Working price |
| --- | ---: |
| Free | $0 |
| Plus Monthly | $4.99 / month |
| Plus Annual | $49.99 / year |
| Plus Founder Annual | $39.99 / year |
| Complete Monthly | $14.99 / month |
| Complete Annual | $149.99 / year |
| Complete Founder Annual | $99.99 / year |
| Complete Lifetime target | $365.00 one-time |
| Complete Founder Lifetime | $249.99 one-time |

Founder pricing does not create different features. Lifetime is a non-expiring Complete entitlement, not a fourth feature tier.

---

## Exposure vocabulary

| Term | Meaning |
| --- | --- |
| `All tiers` | Free, Plus, Complete, and Complete Lifetime should all have access. Trial Complete behaves as Complete while active. |
| `Free+` | Available in Free and all higher tiers. |
| `Plus+` | Available in Plus, Complete, and Complete Lifetime. Locked or hidden in Free. |
| `Complete+` | Available in Complete and Complete Lifetime. Also available during Trial Complete. |
| `Trial Complete` | Temporary Complete-equivalent access for eligible trial users. |
| `Ramadan Preview` | Temporary Ramadan-scoped entitlement. It is not full Complete unless Product explicitly chooses that scope. |
| `Locked preview` | The surface may be visible in a lower tier but cannot be used to mutate paid-only state. |
| `Read-only preserved` | Existing paid-tier data may be shown in limited form after downgrade, but new/edit actions remain locked. |
| `No mutation` | The user may see information, but cannot commit a state change through that control. |
| `Entitlement-supported scheduling` | The event may become schedule-eligible only if the current entitlement supports the underlying plan. |

---

## Core entitlement rules

### One-engine rule

Subh has one canonical morning-resolution engine.

Entitlement affects:

```text
visible surfaces
visible controls
display horizon
edit horizon
allowed user mutations
logging availability
progress/history availability
paywall routing
whether a resolved event may become user-scheduled
```

Entitlement must not affect:

```text
Fajr calculation correctness
location correctness
prayer calculation method correctness
reliability warnings
permission warnings
Quiet semantics
underlying stored user meaning
opportunity detection
resolved day meaning
```

### No data hostage rule

Downgrading changes access. It does not delete user meaning.

Previously created paid-tier data should be preserved, locked, made inactive, or shown read-only depending on the feature. It should not be deleted merely because entitlement expired.

### Scheduling safety rule

When entitlement changes, scheduling must refresh.

Paid-only plans that are no longer supported by the current entitlement must not remain scheduled as active alarms. Stale paid-only platform deliveries must be cancelled or suppressed.

### Lower-tier visibility rule

Lower-tier users may be shown:

- honest day context;
- informational fasting opportunities;
- locked previews;
- read-only summaries of their own prior data;
- paywall entry points.

Lower-tier users must not be allowed to commit unsupported paid-only mutations.

---

## Tier summaries

### Free

Promise:

```text
Understand tomorrow's Fajr morning.
```

Free includes:

- onboarding/setup;
- location/manual city;
- prayer calculation method;
- alarm/notification permission setup;
- reliability warnings;
- main Morning Hero;
- tomorrow Fajr wake display;
- fixed default Fajr wake;
- Quiet for the immediate next morning;
- basic immediate context card when implemented;
- no ads.

Free does not include:

- wake-time adjustment;
- weekly Fajr editing;
- Suhoor mode;
- fasting-purpose controls;
- month/year planning;
- logging;
- Qada tracking;
- progress/history analytics.

### Plus

Promise:

```text
Control your Fajr week.
```

Plus includes everything in Free, plus:

- adjust tomorrow's Fajr wake time;
- custom Fajr wake delta;
- near-term weekly forecast access;
- Fajr-only editing across the weekly horizon;
- Quiet for any visible weekly morning;
- Fajr-only Day Detail access for weekly dates;
- Weekly Fajrcast access;
- Plus-level Fajr overrides within the weekly edit horizon.

Plus does not include:

- Suhoor mode;
- fasting-purpose selection;
- Ramadan Suhoor planning outside active promo/trial access;
- Qada planning;
- monthly/yearly planning;
- worship logs;
- progress/history analytics.

### Complete

Promise:

```text
Plan and track your Suhoor, fasting, Ramadan, Qada, and Fajr-centered year.
```

Complete includes everything in Plus, plus:

- Suhoor mode;
- before-Fajr Suhoor wake planning;
- fasting-purpose selection where valid;
- Ramadan locked fasting behavior;
- non-Ramadan fasting-purpose overrides where valid;
- Qada fast planning;
- full supported current range / annual planning;
- month browsing once implemented;
- Hijri/Gregorian month browsing once implemented;
- Monthly Fajrcast once implemented;
- Adjusted Days repository once implemented;
- recurring boundary rules / presets once implemented;
- Fajr logging;
- Fajr qada tracking if retained;
- Ramadan fasting tracking;
- fast logs;
- Qada fast ledger/tracking;
- custom fast tabs/categories;
- progress/history.

### Complete Lifetime

Complete Lifetime unlocks the same feature set as Complete with non-expiring entitlement. It does not create a separate product tier.

### Trial Complete

Trial Complete behaves like Complete while active. Trial expiry falls back to the user's paid entitlement if any, otherwise to Free, while preserving trial-created data.

### Ramadan Preview

Ramadan Preview is not a fourth permanent tier. It may unlock selected Ramadan-specific Complete capabilities temporarily, such as Ramadan Suhoor planning and Ramadan fast logging. It should not automatically unlock the full annual Complete system unless Product explicitly decides to do so.

---

## Feature gate map

| Feature gate | Free | Plus | Complete | Complete Lifetime | Trial Complete | Ramadan Preview |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `heroView` | Yes | Yes | Yes | Yes | Yes | Yes |
| `fixedFajrWake` | Yes | Yes | Yes | Yes | Yes | Yes |
| `quietTomorrow` | Yes | Yes | Yes | Yes | Yes | Yes |
| `basicSetup` | Yes | Yes | Yes | Yes | Yes | Yes |
| `locationSettings` | Yes | Yes | Yes | Yes | Yes | Yes |
| `prayerMethodSettings` | Yes | Yes | Yes | Yes | Yes | Yes |
| `reliabilityWarnings` | Yes | Yes | Yes | Yes | Yes | Yes |
| `immediateContextCard` | Yes | Yes | Yes | Yes | Yes | Yes |
| `fajrWakeAdjustment` | No | Yes | Yes | Yes | Yes | No unless scoped |
| `weeklyForecastView` | Locked preview | Yes | Yes | Yes | Yes | Maybe preview |
| `weeklyFajrEditing` | No | Yes | Yes | Yes | Yes | No unless scoped |
| `weeklyQuietEditing` | No | Yes | Yes | Yes | Yes | No unless scoped |
| `weeklyFajrcast` | Locked preview / hidden | Yes | Yes | Yes | Yes | Maybe preview |
| `dayDetailFajrOnly` | Read-only or hidden | Yes within weekly horizon | Yes | Yes | Yes | Maybe scoped |
| `suhoorMode` | No | No | Yes | Yes | Yes | Ramadan-scoped if active |
| `fastingPurposeSelection` | No | No | Yes | Yes | Yes | Ramadan-scoped if active |
| `ramadanPlanning` | Promo/trial only | Promo/trial only | Yes | Yes | Yes | Yes if active |
| `qadaFastPlanning` | No | No | Yes | Yes | Yes | No unless scoped |
| `annualPlanning` | No | No | Yes | Yes | Yes | No |
| `monthBrowsing` | No | No | Yes | Yes | Yes | Limited Ramadan calendar if scoped |
| `monthlyFajrcast` | No | No | Yes | Yes | Yes | No unless scoped |
| `adjustedDaysRepository` | No | No | Yes | Yes | Yes | No |
| `recurringBoundaryRules` | No | No | Yes | Yes | Yes | No |
| `fajrLogging` | No | No | Yes | Yes | Yes | Maybe Ramadan-scoped if active |
| `fajrQadaTracking` | No | No | Yes, if retained | Yes, if retained | Yes, if retained | No unless scoped |
| `fastLogging` | No | No | Yes | Yes | Yes | Ramadan-scoped if active |
| `ramadanFastTracking` | Promo/trial only | Promo/trial only | Yes | Yes | Yes | Yes if active |
| `qadaFastTracking` | No | No | Yes | Yes | Yes | No unless scoped |
| `fastTabs` | No | No | Yes | Yes | Yes | No unless scoped |
| `progressHistory` | Locked/read-only summary at most | Locked/read-only summary at most | Yes | Yes | Yes | Ramadan summary if scoped |
| `subscriptionManagement` | Yes | Yes | Yes | Yes | Yes | Yes |

---

## Scenario group tier exposure matrix

This matrix maps the existing `S001-S235` groups from the MVP interaction inventory to pricing exposure.

| Group | Scenario range | Area | Free exposure | Plus exposure | Complete / Lifetime / Trial exposure | Notes |
| --- | ---: | --- | --- | --- | --- | --- |
| A | S001-S020 | First launch and onboarding | Yes | Yes | Yes | Setup is never paywalled. Trial offer may appear after enough setup is complete to resolve a real morning. |
| B | S021-S027 | Home arrival and hero viewing | Yes | Yes | Yes | Basic hero and immediate day context are universal. Paid modes/controls may be locked or hidden. |
| C | S028-S034 | Home hero: Fajr mode | Yes, immediate default Fajr only | Yes, Fajr control within weekly horizon | Yes, full supported horizon | Fajr mode is the baseline. Free cannot adjust wake time. |
| D | S035-S045 | Home hero: Suhoor mode and intention | Locked / paywall only | Locked / paywall only | Yes | Suhoor is Complete+. Deferred non-Suhoor before-Fajr scenarios remain deferred. |
| E | S046-S055 | Suhoor fasting behavior | Informational opportunity only; no Suhoor commit | Informational opportunity only; no Suhoor commit | Yes | Lower tiers may see day meaning but cannot activate Suhoor/fasting-purpose mutations. |
| F | S056-S062 | Quiet mode | Quiet tomorrow | Quiet any weekly visible morning | Quiet any supported editable morning | Quiet is not a payment failure; scope changes by tier horizon. |
| G | S063-S070 | Wake-time adjustment | Locked / Plus paywall | Fajr-only weekly adjustment | Full supported adjustment, including Suhoor where valid | Free may view default wake only. Paid adjustments must schedule only if entitlement-supported. |
| H | S071-S073 | Adhan exposure | Home hides adhan; detail access limited | Fajr-only adhan/detail controls where allowed | Full detail controls where allowed | Adhan is separate from alarm activation. Paywall should not obscure reliability. |
| I | S074-S080 | Near-term forecast / legacy Next 10 | Locked preview or hidden | Yes | Yes | Target product direction is weekly / 7 mornings, but current forecast spec still says Next 10 until updated. |
| J | S081-S088 | Day Detail entry and viewing | Read-only immediate detail optional; no paid mutations | Fajr-only detail within weekly horizon | Full detail within supported horizon | If Free has no detail route, context card should still provide basic day meaning. |
| K | S089-S109 | Day Detail editing | No editing except immediate Quiet if surfaced | Fajr-only weekly editing | Full Suhoor/Fajr/Quiet editing and fasting-purpose controls | Reset and edits save immediately. Suhoor controls are Complete+. |
| L | S110-S115 | Browse by Month entry | Locked/hidden | Locked/hidden | Yes | Complete owns month browsing. |
| M | S116-S122 | Gregorian month browsing | No | No | Yes | Complete-only planning surface. |
| N | S123-S129 | Hijri month browsing | No | No | Yes | Basic Hijri settings may be universal, but browsing/editing is Complete. |
| O | S130-S134 | Monthly Fajrcast | No | No | Yes | Complete-only when implemented. |
| P | S135-S143 | Monthly day list and future edits | No | No | Yes | Complete-only annual/month planning and future override hydration. |
| Q | S144-S154 | Adjusted Days repository | No | No | Yes | Complete-only once implemented. |
| R | S155-S159 | Weekly Fajrcast | Locked preview or hidden | Yes | Yes | Weekly context supports Plus value. Scrubbing is UI-only but the surface itself is Plus+. |
| S | S160-S167 | Settings entry and visible sections | Yes, with paid sections locked | Yes, with Complete sections locked | Yes | Settings hub is universal; sections/actions are gated. |
| T | S168-S175 | Location settings | Yes | Yes | Yes | Correctness settings are never paywalled. |
| U | S176-S182 | Prayer time settings | Yes | Yes | Yes | Calculation correctness and manual prayer-time correction should not be paywalled. |
| V | S183-S189 | Hijri calendar settings | Yes for correctness/review basics | Yes for correctness/review basics | Yes, plus planning consequences | Hijri correctness is not premium; Complete owns broad planning surfaces affected by Hijri changes. |
| W | S190-S199 | Recurring boundary rules / presets | No | Maybe simple Plus default only if specified | Yes | Treat as Complete-only unless a later simple Plus default setting spec narrows scope. |
| X | S200-S204 | About and feedback | Yes | Yes | Yes | Universal. No state changes. |
| Y | S205-S211 | Permissions after onboarding | Yes | Yes | Yes | Permission/reliability warnings are universal and must not be paywalled. |
| Z | S212-S219 | Alarm execution and post-alarm behavior | Free Fajr baseline events | Plus-supported Fajr events | Complete-supported Suhoor/Fajr events | Delivery must respect entitlement-supported scheduling. |
| AA | S220-S225 | Cross-surface consistency | Yes within Free scope | Yes within Plus scope | Yes within Complete scope | Same resolver; tier gates affect surfaces and mutations only. |
| AB | S226-S235 | Rapid and repeated interactions | Only exposed Free controls | Exposed Plus controls | All exposed Complete controls | Stress tests must include locked/paywalled interactions and entitlement changes. |

---

## Scenario-level exposure notes for high-risk groups

### C. Fajr mode, S028-S034

Free users may view and use the default immediate Fajr mode. They cannot adjust wake time.

Plus users may adjust Fajr wake behavior across the weekly horizon.

Complete users inherit Plus Fajr control and may combine Fajr behavior with broader planning, logging, and annual surfaces.

### D. Suhoor mode, S035-S045

Suhoor is Complete+.

Lower tiers may expose Suhoor as:

- hidden;
- visible but locked;
- visible in a context card with a Complete paywall prompt;
- temporarily enabled through Trial Complete or Ramadan Preview.

Lower tiers must not commit:

```text
selectQuickWakeMode(.suhoor)
selectFastingIntention(...)
```

unless an active Complete-equivalent or Ramadan-scoped entitlement exists.

Deferred scenarios remain deferred:

```text
S037: non-fasting Tahajjud-only before-Fajr selection
S038: Other early worship before-Fajr selection
S040: Tahajjud-only -> Fasting switching
S041: Fasting -> Tahajjud-only switching
S042: Fasting -> Other early worship switching
S092: Other early worship in Day Detail
S227: rapid Other early worship interaction
```

### E. Suhoor fasting behavior, S046-S055

Day meaning and opportunities may be visible below Complete, but intention activation is Complete+.

Example:

```text
A Free or Plus user may see that tomorrow is a White Day opportunity.
Only Complete/Trial/Ramadan Preview where scoped may activate Suhoor or select a fasting purpose.
```

Ramadan locked fasting behavior should be Complete+ by default, with optional Ramadan Preview as a temporary entitlement.

### F. Quiet mode, S056-S062

Quiet must remain available at least for the immediate next morning in Free.

Tier-specific scope:

| Tier | Quiet scope |
| --- | --- |
| Free | Immediate next morning only. |
| Plus | Any weekly/near-term visible morning. |
| Complete | Any supported editable date within Complete planning horizon. |

Quiet must never represent permission failure, delivery failure, expired subscription, missing pending delivery, or unavailable schedule state.

### G. Wake-time adjustment, S063-S070

Free cannot adjust wake time.

Plus can adjust Fajr wake times only within the weekly horizon.

Complete can adjust supported modes and dates across the Complete edit horizon, including Suhoor where valid.

Mode-switch clearing still applies regardless of tier.

### I. Near-term forecast / legacy Next 10, S074-S080

The current inventory and forecast spec still use `Next 10 Mornings`. The pricing model targets a weekly horizon.

Required transition rule:

```text
Until the forecast spec is updated, Codex should not silently change the row count from 10 to 7 just because pricing says Plus controls the week.
```

Implementation may use a neutral internal term such as `nearTermForecast` while the visible spec is finalized.

### J/K. Day Detail, S081-S109

Day Detail exposure is tiered:

| Tier | Day Detail behavior |
| --- | --- |
| Free | Optional read-only detail for immediate morning; otherwise rely on context card. No paid mutations. |
| Plus | Fajr-only edit/detail within weekly horizon. |
| Complete | Full Suhoor/Fajr/Quiet edit/detail across supported horizon. |

If the detail screen contains controls the user cannot use, those controls must be hidden, locked, or replaced with a contextual paywall entry.

### L-P. Month browsing and monthly planning, S110-S143

Month browsing, Gregorian/Hijri browsing, Monthly Fajrcast, monthly day list, and far-future edits are Complete-only.

Lower tiers may show a locked preview if Home Composition wants a paywall entry point, but lower-tier users must not commit month-level or annual planning mutations.

### Q. Adjusted Days, S144-S154

Adjusted Days is Complete-only because it is only valuable when long-range plans, Suhoor plans, recurring rules, and logs can accumulate.

After downgrade, existing adjusted-day data should be preserved and may be summarized read-only if the user previously had Complete.

### R. Weekly Fajrcast, S155-S159

Weekly Fajrcast is Plus+.

Free may show a locked preview or hide it entirely. If visible, it should not compete with the Morning Hero.

Scrubbing is UI-only, but access to the surface itself remains Plus+ unless Product later decides Free should get a limited passive trend.

### S-W. Settings, S160-S199

Settings should be split by type:

| Settings area | Tier exposure |
| --- | --- |
| Subscription/account | All tiers. |
| Location/manual city | All tiers. |
| Prayer calculation method | All tiers. |
| Hijri correctness/review basics | All tiers. |
| Alarm/notification permission | All tiers. |
| Default fixed Fajr wake baseline | All tiers. |
| Custom Fajr wake defaults | Plus+. |
| Suhoor defaults | Complete+. |
| Recurring boundary rules / presets | Complete+, unless a narrower Plus default-setting spec is approved. |
| Logs/Qada/progress settings | Complete+. |

### Z. Alarm execution, S212-S219

Scheduling must respect entitlement.

| Event / plan | Schedule eligibility |
| --- | --- |
| Default Free Fajr wake | Free+. |
| Plus-adjusted Fajr wake | Plus+. |
| Weekly Plus Fajr override | Plus+. |
| Suhoor wake | Complete+ / Trial Complete / Ramadan Preview where scoped. |
| Qada fast Suhoor wake | Complete+ / Trial Complete. |
| Ramadan Suhoor wake | Complete+ / Trial Complete / Ramadan Preview where scoped. |
| Logging reminder | Complete+ / Trial Complete / Ramadan Preview where scoped. |

Expired paid-only events must not keep firing.

---

## New entitlement interaction scenarios

The original inventory remains `S001-S235`. This spec adds pricing/entitlement scenarios under `P001-P064`.

These scenarios should be audited separately from the original interaction inventory, but they should be considered MVP pricing scope once pricing is implemented.

### P. Trial, paywall, and entitlement entry

P001. User completes onboarding and is offered a 30-day Complete trial after enough setup exists to resolve a real morning.
P002. User starts the 30-day Complete trial. Complete features unlock while the trial is active.
P003. User declines or skips the 30-day Complete trial. User remains Free and may be offered the trial later if still eligible.
P004. User opens the app while Trial Complete is active. The app resolves effective entitlement as Complete-equivalent.
P005. Trial Complete expires without paid entitlement. Effective entitlement becomes Free.
P006. Trial Complete expires while the user has purchased Plus. Effective entitlement becomes Plus.
P007. Trial Complete expires while the user has purchased Complete. Effective entitlement remains Complete.
P008. Trial expiry shows a calm explanation that plans/logs stay saved but paid controls are locked.
P009. User opens subscription/settings screen from any tier. The app shows current effective entitlement and available plans.
P010. User restores purchases. Effective entitlement updates without deleting local user data.

### Q. Locked feature and paywall entry scenarios

P011. Free user taps wake-time adjustment. A Plus-focused paywall appears.
P012. Free user taps weekly forecast editing. A Plus-focused paywall appears.
P013. Free user taps Weekly Fajrcast preview. A Plus-focused paywall appears unless Product makes the card Free.
P014. Free or Plus user taps Suhoor. A Complete-focused paywall appears unless Trial Complete or Ramadan Preview applies.
P015. Free or Plus user taps fasting-purpose controls. A Complete-focused paywall appears.
P016. Free or Plus user opens Qada fast planning. A Complete-focused paywall appears.
P017. Free or Plus user opens logging. A Complete-focused paywall appears.
P018. Free or Plus user opens month/year planning. A Complete-focused paywall appears.
P019. Free or Plus user opens progress/history. A Complete-focused paywall or read-only summary appears depending on prior data.
P020. User sees locked paid feature copy. Copy is calm, practical, and non-guilt-based.

### R. Upgrade scenarios

P021. Free user purchases Plus monthly. Plus features unlock.
P022. Free user purchases Plus annual/founder annual. Plus features unlock.
P023. Free user purchases Complete monthly. Complete features unlock.
P024. Free user purchases Complete annual/founder annual. Complete features unlock.
P025. Free user purchases Complete Lifetime/founder lifetime. Complete Lifetime entitlement unlocks.
P026. Plus user upgrades to Complete. Preserved Complete data rehydrates where valid.
P027. Plus user purchases Complete Lifetime. Complete Lifetime entitlement unlocks and Plus subscription state is handled by StoreKit/account logic.
P028. Trial Complete user purchases paid Complete before expiry. Trial data continues as paid Complete data.
P029. Trial Complete user purchases Plus. Complete data is preserved but only Plus-supported features remain active after trial expiry.
P030. Ramadan Preview user upgrades to Complete. Ramadan data remains and full Complete features unlock.
P031. User upgrades after previously downgrading. Preserved paid-tier data rehydrates where valid.
P032. Upgrade triggers re-resolution and schedule refresh without duplicate records or duplicate scheduled events.

### S. Downgrade, cancellation, and expiry scenarios

P033. Plus subscription expires. Effective entitlement becomes Free unless another valid entitlement exists.
P034. Complete subscription expires. Effective entitlement becomes Free or Plus depending on remaining entitlement.
P035. Complete user downgrades to Plus. Complete-only data remains stored but locked/inactive/read-only as appropriate.
P036. Plus user downgrades to Free. Plus weekly overrides remain stored but locked/inactive.
P037. Complete user downgrades to Free. Complete data remains stored but locked/read-only.
P038. Complete Lifetime user has no expiry. Complete access remains active unless refunded/revoked according to StoreKit/account rules.
P039. Entitlement verification is temporarily unavailable. App uses approved grace behavior or falls back conservatively without deleting data.
P040. Entitlement is revoked/refunded. App removes access but preserves user-created religious/planning/log data unless deletion is explicitly required.
P041. Downgrade triggers re-resolution and schedule refresh.
P042. Downgrade cancels/suppresses unsupported paid-only scheduled events.

### T. Data preservation scenarios

P043. User creates Suhoor plan during Complete trial, then downgrades to Free. Suhoor plan remains stored but inactive/locked.
P044. User creates Qada fast record during Complete, then downgrades. Qada record remains stored and may show as read-only/summary.
P045. User creates Fajr logs during Complete, then downgrades. Logs remain stored and may show read-only/summary.
P046. User creates fast tabs/categories during Complete, then downgrades. Tabs/categories remain stored and locked/read-only.
P047. User re-upgrades to Complete after downgrade. Valid preserved data rehydrates.
P048. User edits a date in Plus that previously had locked Complete Suhoor data. App uses archive-and-replace or equivalent conflict-safe behavior.
P049. User explicitly deletes a record. Deletion follows the relevant feature spec and is not confused with downgrade.
P050. App migration encounters legacy paid-tier data. Migration preserves valid user meaning and records safe diagnostics.

### U. Scheduling and reliability scenarios

P051. Free default Fajr wake is scheduled when permissions allow.
P052. Plus-adjusted Fajr wake is schedule-eligible only while Plus+ entitlement is active.
P053. Complete Suhoor wake is schedule-eligible only while Complete+, Trial Complete, or scoped Ramadan Preview is active.
P054. Entitlement expiry cancels stale paid-only platform deliveries.
P055. Quiet remains intentional suppression, not entitlement failure.
P056. Permission failure remains reliability failure, not entitlement failure.
P057. Entitlement failure remains access failure, not Quiet.
P058. Schedule/delivery status remains visible as required even when the plan is from a lower tier.

### V. Ramadan Preview scenarios

P059. Ramadan Preview activates. The app exposes only the Ramadan-scoped features Product approved.
P060. Ramadan Preview allows Ramadan Suhoor wake planning if scoped.
P061. Ramadan Preview allows Ramadan fast logging if scoped.
P062. Ramadan Preview expires. Ramadan data remains stored and basic read-only history may remain visible.
P063. After Ramadan Preview expiry, non-Ramadan Qada, annual planning, and full progress remain Complete-only.
P064. User upgrades from Ramadan Preview to Complete. Ramadan data remains and full Complete unlocks.

---

## Context card exposure

The user has identified a missing immediate context card: a Home-adjacent card that explains the relevant day for the immediate next alarm/morning.

This card should be treated as universal for basic information.

### Proposed name

```text
Immediate Morning Context Card
```

or

```text
Tomorrow Context Card
```

The final name belongs to a future Home Composition / Context Card spec.

### Tier exposure

| Content / action | Free | Plus | Complete |
| --- | ---: | ---: | ---: |
| Basic day meaning | Yes | Yes | Yes |
| Fajr begin/end context | Yes | Yes | Yes |
| Ramadan/Eid/opportunity explanation | Yes, informational | Yes, informational | Yes, actionable where valid |
| Suggested next step copy | Yes, non-paywalled for basics | Yes | Yes |
| Activate Suhoor | Locked / Complete prompt | Locked / Complete prompt | Yes |
| Select fasting purpose | No | No | Yes |
| Log Fajr/fast | No | No | Yes |
| Open Qada workflow | No | No | Yes |

The context card must not turn every opportunity into pressure. It should explain meaning without making lower-tier users feel they failed to act.

---

## Settings exposure detail

Settings should not be treated as one paid/unpaid area. Each section should declare its own entitlement.

| Settings section | Free | Plus | Complete | Notes |
| --- | ---: | ---: | ---: | --- |
| Location | Yes | Yes | Yes | Correctness, not premium. |
| Prayer method | Yes | Yes | Yes | Correctness, not premium. |
| Fajr begin adjustment | Yes | Yes | Yes | Treat as calculation correction, not wake customization. |
| Fajr end/sunrise adjustment if implemented | Yes | Yes | Yes | Treat as calculation correction. |
| Notification/alarm permission | Yes | Yes | Yes | Reliability, not premium. |
| Subscription | Yes | Yes | Yes | Required for plan management. |
| Basic default Fajr wake behavior | Yes, fixed default | Yes, editable Fajr default | Yes, editable Fajr default | Exact UI split belongs to Settings spec. |
| Custom wake delta | No | Yes | Yes | Plus control feature. |
| Suhoor defaults | No | No | Yes | Complete feature. |
| Ramadan defaults | Promo/trial only | Promo/trial only | Yes | Complete feature. |
| Recurring boundary rules / presets | No | Maybe if simple | Yes | Default Complete unless separately narrowed. |
| Logging/Qada settings | No | No | Yes | Complete. |
| Data export/delete | Yes where privacy requires | Yes | Yes | Privacy/deletion should not be paywalled. |

---

## Onboarding and tips exposure

Onboarding is universal.

However, onboarding may adapt by entitlement and season.

### Universal onboarding must cover

- Subh's purpose;
- location/manual city;
- prayer calculation method;
- notification/alarm permission;
- fixed default Fajr wake baseline;
- Quiet as intentional suppression;
- reliability limitations and warnings.

### Complete trial onboarding may cover

- Suhoor;
- Ramadan if relevant;
- Qada fast tracking;
- Fajr/fast logs;
- progress/history;
- what happens when the trial ends.

### Seasonal onboarding

If the user joins during Ramadan or near Ramadan, onboarding may prioritize:

- Suhoor planning;
- Ramadan locked fasting behavior;
- Ramadan fast logging;
- post-Ramadan Qada continuation.

Seasonal onboarding must not create a separate Ramadan product lane. It should remain part of the Fajr-centered morning system.

### Tips / coach marks

Tips should be tier-aware:

| Tip type | Exposure |
| --- | --- |
| How to read the Hero | All tiers. |
| How to use Quiet | All tiers within available horizon. |
| How to adjust Fajr wake | Plus+. |
| How to plan Suhoor | Complete+ or Ramadan Preview. |
| How to log Fajr/fasts | Complete+. |
| How to review progress | Complete+. |

---

## Strategy: when to introduce pricing in Codex work

Do **not** wait until every feature is fully built and polished before introducing entitlement seams.

Also do **not** implement StoreKit/payments immediately.

The recommended approach is:

```text
Introduce local entitlement architecture early.
Implement feature surfaces against entitlement gates as they are built.
Delay StoreKit/payment wiring until the app has enough feature value and stable local entitlement behavior.
```

### Why not wait until the end?

If all features are built as universally available and pricing is retrofitted later, the app may need risky rework around:

- hidden controls;
- schedule eligibility;
- paid-only Suhoor alarms;
- downgrade behavior;
- saved Complete data;
- read-only logs;
- lower-tier fallbacks;
- paywall entry points;
- conflict handling when lower-tier edits interact with preserved higher-tier data.

These are not just visual seams. They affect persistence, resolution, and delivery.

### What to do now

Implement a non-StoreKit local entitlement model early, such as:

```text
Free
Plus
Complete
TrialComplete
RamadanPreview
CompleteLifetime
```

Use it to drive feature gates while building features.

### What to delay

Delay these until later:

- App Store Connect product configuration;
- real StoreKit subscriptions;
- receipt/transaction verification;
- real restore purchase flow;
- public paywall polish;
- TestFlight StoreKit sandbox validation.

---

## Recommended Codex work-session sequence

This is a practical sequencing plan. It separates spec stabilization, local entitlement architecture, feature buildout, StoreKit, and TestFlight.

### Session 1 — Spec ingestion and entitlement map alignment

Goal:

```text
Add this tier exposure matrix to the spec corpus and update the index references.
```

Codex work:

- Add `subh-mvp-interaction-tier-exposure-matrix-v1.md`.
- Add `subh-pricing-entitlement-spec-v1.md` if not already present in the repo/spec folder.
- Update `00-subh-spec-index-v1.md` to reference both specs.
- Do not implement code.

### Session 2 — Local entitlement model, no StoreKit

Goal:

```text
Create central entitlement state and feature gates without real payments.
```

Codex work:

- Add `SubhEntitlementState` or equivalent.
- Add centralized feature-gate resolver.
- Add debug/dev override for Free/Plus/Complete/Trial/Ramadan Preview/Lifetime.
- Ensure feature gates are not hardcoded separately in each view.
- No App Store / StoreKit implementation yet.

### Session 3 — Home composition and immediate context card spec/build

Goal:

```text
Define and implement the Home-level supporting cards and immediate day context.
```

Codex work:

- Create/update Home Composition spec.
- Create Immediate Morning Context Card spec or section.
- Implement card as universal information with paid actions locked where needed.
- Add tier-aware paywall entry placeholders, not real StoreKit.

### Session 4 — Near-term forecast: Next 10 to Next Week decision

Goal:

```text
Finalize whether the near-term forecast becomes 7 mornings / Next Week.
```

Codex work:

- If locked, create `subh-next-week-wake-forecast-spec-v1.md` or update v4 to v5.
- Update scenario language from Next 10 to Near-term / Next Week where approved.
- Implement Plus+ weekly forecast/editing gates.
- Keep one resolver.

### Session 5 — Planning horizon entitlement update

Goal:

```text
Make display/edit horizons tier-aware.
```

Codex work:

- Update Planning Horizon spec.
- Add Free/Plus/Complete display and edit horizon rules.
- Implement entitlement-aware display/edit horizon if code is ready.
- Ensure active scheduled horizon stays separate from display horizon.

### Session 6 — Settings and onboarding specs/buildout

Goal:

```text
Stabilize settings, onboarding, and tips as tier-aware but universal for correctness.
```

Codex work:

- Create Onboarding and Initial Setup Spec.
- Create Settings Hub Spec.
- Create Location and Prayer Time Settings specs if needed.
- Implement basic settings and onboarding polish.
- Keep location/prayer/reliability settings universal.

### Session 7 — Month browsing and Monthly Fajrcast, Complete-only

Goal:

```text
Build Complete-only month/year planning surfaces.
```

Codex work:

- Create Month Browsing spec.
- Create Monthly Fajrcast spec.
- Implement Complete gates and locked previews.
- Ensure future edits hydrate into weekly/Home surfaces only when date approaches.

### Session 8 — Worship logging and Qada tracking spec/build

Goal:

```text
Define and implement Complete-tier logging and Qada capabilities.
```

Codex work:

- Create `subh-worship-logging-qada-tracking-spec-v1.md`.
- Implement Fajr logs, fast logs, Ramadan fast tracking, Qada fast, Qada Fajr if retained, fast tabs, and read-only downgrade behavior.
- Avoid guilt-based copy.

### Session 9 — Paywall surface spec and plan management UI

Goal:

```text
Create paywall and subscription-management surfaces, still using local/mock entitlements.
```

Codex work:

- Create Home Composition / Paywall Surface spec or Subscription UI spec.
- Implement plan cards, locked-feature prompts, trial expiry state, and read-only data messaging.
- Use mock entitlement changes to test upgrade/downgrade combinations.

### Session 10 — StoreKit implementation plan and sandbox implementation

Goal:

```text
Connect real StoreKit only after local entitlement behavior is stable.
```

Codex work:

- Create StoreKit / Subscription Implementation Plan.
- Add StoreKit products.
- Add purchase, upgrade/downgrade, restore, transaction updates, entitlement verification, and sandbox tests.
- Preserve all local data across entitlement changes.

### Session 11 — TestFlight beta strategy spec

Goal:

```text
Keep TestFlight separate from pricing entitlement.
```

Codex work:

- Create `subh-testflight-beta-strategy-spec-v1.md`.
- Define internal beta, friends/family beta, StoreKit sandbox beta, feedback forms, cohorts, and App Store readiness checks.

### Session 12 — Implementation audit against S001-S235 and P001-P064

Goal:

```text
Audit coverage after the major specs and local gates exist.
```

Codex work:

- Classify each `S` scenario and each `P` scenario as Implemented / Partial / Missing / Risky / Not Testable.
- Produce gap matrix and next implementation queue.

---

## Minimum recommended implementation order

If the team needs a shorter plan, use this order:

1. Add pricing entitlement spec and tier exposure matrix to the spec corpus.
2. Implement local entitlement state and feature gates.
3. Build universal Home/context/onboarding/settings foundations.
4. Build Plus Fajr weekly control.
5. Build Complete Suhoor/Ramadan/Qada/logging surfaces.
6. Implement paywalls with mock/local entitlement.
7. Implement StoreKit.
8. Run TestFlight.

This avoids the two main risks:

- implementing all features as free and trying to cut them apart later;
- implementing StoreKit before the product value and entitlement behavior are stable.

---

## Required updates to existing specs

This matrix creates follow-up updates.

| Spec | Required update |
| --- | --- |
| `00-subh-spec-index-v1.md` | Add `subh-pricing-entitlement-spec-v1.md` and this tier exposure matrix to the canonical spec list. |
| `subh-mvp-interaction-inventory-v3.md` | Reference this companion matrix as the tier-exposure overlay. Optionally promote to v4 later. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md` | Add entitlement-aware display/edit horizon rules. |
| `subh-next-10-mornings-wake-forecast-spec-v4.md` | Decide and update Next 10 vs Next Week / 7 mornings. |
| `subh-morning-hero-item-spec-v14.md` | Add entitlement exposure notes for locked Suhoor and locked adjustment controls. |
| `subh-alarm-detail-view-screen-spec-v7.md` | Add tier-aware editing availability. |
| `subh-weekly-fajrcast-card-spec-v13.md` | Mark Weekly Fajrcast as Plus+ unless Product decides otherwise. |
| New Home Composition / Context Card spec | Define universal context card and locked paid action prompts. |
| New Settings Hub spec | Define universal correctness settings vs paid defaults/rules/log settings. |
| New Onboarding spec | Define trial offer, seasonal onboarding, and tier-aware tips. |
| New Worship Logging/Qada spec | Define Complete logging and downgrade read-only behavior. |
| New StoreKit implementation plan | Define products, subscription group, restore, verification, sandbox tests. |
| New TestFlight strategy spec | Define beta strategy separately from pricing. |

---

## Acceptance criteria

### Inventory overlay acceptance

- [ ] The original `S001-S235` scenario IDs remain preserved.
- [ ] This tier exposure matrix maps every scenario group A-AB to Free, Plus, Complete, and temporary entitlements.
- [ ] No original scenario is silently removed by tier gating.
- [ ] Paid feature locking is treated as access control, not behavior deletion.
- [ ] Lower-tier users cannot commit unsupported paid-only mutations.
- [ ] Correctness, location, calculation method, and reliability warnings remain universal.
- [ ] Suhoor remains Complete+ except where Trial Complete or Ramadan Preview explicitly applies.
- [ ] Plus remains Fajr-week control, not Suhoor/Ramadan/Qada/logging.
- [ ] Complete owns Suhoor, Ramadan, Qada, logs, monthly/yearly planning, and progress.
- [ ] Complete Lifetime is Complete entitlement, not a separate feature tier.

### Data and downgrade acceptance

- [ ] Downgrade preserves paid-tier user data.
- [ ] Downgrade locks/inactivates unsupported paid plans.
- [ ] Downgrade cancels or suppresses unsupported paid-only scheduled events.
- [ ] Lower-tier edit conflicts with preserved higher-tier data are handled without silent overwrite.
- [ ] Re-upgrade rehydrates valid preserved data.

### Codex sequencing acceptance

- [ ] Pricing specs are added before StoreKit implementation.
- [ ] Local/mock entitlement gates are implemented before StoreKit.
- [ ] StoreKit is delayed until feature value and local entitlement behavior are stable.
- [ ] TestFlight strategy remains a separate spec.

---

## Codex audit prompt update

Use this prompt after the local entitlement layer or paywall surfaces exist:

```text
Review the current Subh codebase against:
- subh-mvp-interaction-inventory-v3.md
- subh-mvp-interaction-tier-exposure-matrix-v1.md
- subh-pricing-entitlement-spec-v1.md
- 00-subh-spec-index-v1.md

For each original scenario ID S001-S235, classify:
1. Implementation status: Implemented, Partially Implemented, Missing, Risky, or Not Testable Yet.
2. Tier exposure status: Universal, Free-only, Plus+, Complete+, Trial-only, Ramadan-preview-only, Locked Preview, Read-only Preserved, or Not Applicable.
3. Entitlement risk: Does the code allow a lower-tier user to commit unsupported paid-only state? Does it delete or hide preserved user data incorrectly? Does it leave unsupported paid-only alarms scheduled after downgrade?

For each pricing scenario P001-P064 in the tier exposure matrix, classify implementation status and identify relevant files.

Do not create separate Free, Plus, and Complete morning engines. Feature gates must consume a central normalized entitlement state. The resolver must remain canonical. Entitlement must not affect prayer-time correctness, location correctness, reliability warnings, permission warnings, Quiet semantics, or base opportunity detection.
```

---

## Open decisions

| Decision | Current working stance |
| --- | --- |
| Should the forecast be exactly 7 mornings / Next Week? | Pricing direction says weekly; the existing surface spec still says Next 10 until updated. |
| Should Free see Weekly Fajrcast as locked preview or hidden? | Both are allowed; Home Composition should decide. |
| Should Free have read-only Day Detail for immediate morning? | Optional. If omitted, the universal context card should cover basic explanation. |
| Should Hijri calendar settings be universal? | Recommended yes for correctness, while Complete owns broad planning surfaces. |
| Should recurring boundary rules be partly Plus? | Default Complete-only unless a later spec creates a simple Plus default setting. |
| Should Ramadan Preview unlock all Ramadan logging or only Suhoor wake planning? | Product decision deferred; entitlement model supports either. |
| Should lifetime be visible on main paywall? | Prefer limited founder/patron placement, not ordinary default main paywall. |
| Should Qada Fajr remain in Complete MVP? | User direction includes it; the logging/Qada spec must define copy and boundaries carefully. |

---

## Integrity checklist

- [x] Original interaction inventory scenario IDs remain `S001-S235`.
- [x] No original scenario is removed by this spec.
- [x] Pricing exposure is modeled as an overlay, not a replacement inventory.
- [x] New entitlement scenarios use `P001-P064`.
- [x] Free / Plus / Complete / Complete Lifetime / Trial Complete / Ramadan Preview are represented.
- [x] Suhoor is Complete+ by default.
- [x] Plus is Fajr-week control by default.
- [x] Complete owns Suhoor, Ramadan, Qada, logs, progress, and full planning.
- [x] Correctness and reliability settings remain universal.
- [x] Data preservation after downgrade is explicitly represented.
- [x] StoreKit and TestFlight are kept separate from this tier exposure matrix.
