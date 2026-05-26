# Subh Pricing and Entitlement Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-pricing-entitlement-spec-v1.md` |
| Version | 1 |
| Spec status | Draft; proposed canonical working spec |
| Date | 2026-05-17 |
| Related specs | `00-subh-spec-index-v1.md`, `subh-mvp-interaction-inventory-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v2.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-quick-wake-mode-intent-mutation-contract-v1.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v2.md`, `subh-morning-hero-item-spec-v14.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-10-mornings-wake-forecast-spec-v4.md`, `subh-weekly-fajrcast-card-spec-v13.md` |
| Owning domain / surface | Pricing, entitlement, trial access, paywall rules, downgrade/upgrade behavior, paid-feature data preservation |
| Implementation audit status | Needs implementation audit |

---

## Purpose

This specification defines Subh's pricing and entitlement model.

It answers:

```text
Which tiers exist?
What does each tier promise?
What does each tier allow the user to see, edit, activate, schedule, and log?
What prices are currently locked as the working product decision?
What happens during the 30-day Complete trial?
What happens when a user upgrades, downgrades, cancels, expires, restores, or buys lifetime access?
What happens to previously created paid-tier data when the current entitlement no longer supports it?
Where should paywalls appear?
Which features are MVP pricing scope, and which are future/fantasy extensions?
```

This spec is intentionally separated from the TestFlight strategy. A future TestFlight / beta strategy spec should own beta cohorts, testing phases, tester feedback loops, StoreKit sandbox validation, and App Store launch readiness. This pricing spec owns product access rules and entitlement behavior only.

---

## Source alignment

This spec is aligned with the current Subh MVP source of truth:

1. Subh is one Fajr-centered morning system, not separate Fajr, fasting, Ramadan, and Qada engines.
2. The exposed MVP quick wake modes are:

```text
Suhoor | Fajr | Quiet
```

3. `Suhoor` is the only exposed before-Fajr MVP wake mode.
4. `Tahajjud only`, `Other early worship`, and generic non-fasting `Pre-Fajr` choices are deferred from active MVP UI and active MVP resolution.
5. Fasting opportunities are not intentions until the user selects Suhoor or another durable fasting-intention source applies.
6. Display horizon, edit horizon, and active scheduled horizon are distinct.
7. The delivery layer schedules only resolver-materialized events inside the active scheduled horizon, not everything visible in a forecast or calendar.
8. Day Detail edits and reset actions save immediately in MVP.
9. Opportunity, intention, wake plan, completion, and credit are separate concepts.
10. Surfaces emit intents and consume the resolved morning graph; pricing must not create parallel state machines.

---

## Out of scope

This spec does **not** define:

- TestFlight beta strategy.
- StoreKit implementation details beyond draft product identities and entitlement implications.
- Exact App Store Connect configuration steps.
- Taxes, regional price equalization, foreign-currency localization, or App Store price-point availability.
- Refund policy.
- Legal terms of service.
- Privacy policy.
- Marketing site copy.
- Detailed UI layout for paywalls.
- Full onboarding spec.
- Full worship logging implementation spec.
- Full TestFlight, sandbox, or App Review strategy.

Those should be handled by separate specs or implementation plans.

---

## Pricing doctrine

Subh should be priced as a premium, calm, reliable, faith-centered morning system.

The pricing model should preserve three principles:

1. **Basic Fajr orientation remains accessible.**
   The user should not feel that they must pay merely to understand tomorrow's Fajr morning.

2. **Paid tiers monetize control, planning, logging, and long-term organization.**
   Payment unlocks the ability to shape, plan, track, and preserve the user's Fajr-centered worship routine.

3. **The app remains one system.**
   Pricing gates surfaces, horizons, mutations, and logs. It must not create separate Free, Plus, Complete, or Lifetime engines.

Short pricing doctrine:

```text
Free helps the user understand tomorrow.
Plus helps the user control their Fajr week.
Complete helps the user plan and track their Suhoor, fasting, Ramadan, Qada, and Fajr-centered year.
Lifetime grants permanent Complete access for eligible purchased functionality.
```

---

## Tier names and core promises

| Tier | Core promise | Product meaning |
| --- | --- | --- |
| `Free` | Understand tomorrow's Fajr morning. | The app remains useful as a simple Fajr orientation and basic wake companion. |
| `Plus` | Control your Fajr week. | The user can adjust and plan Fajr-mode wake behavior across the near-term weekly horizon. |
| `Complete` | Plan and track your Suhoor, fasting, Ramadan, Qada, and Fajr-centered year. | The user receives the full planning, fasting, logging, and progress system. |
| `Complete Lifetime` | Permanent Complete access. | The user receives non-expiring Complete entitlement, subject to future external-service exceptions defined below. |

---

## Locked working prices

Currency assumption for this working spec:

```text
CAD unless product explicitly localizes pricing in a later App Store pricing plan.
```

### Standard pricing

| Product | Price | Notes |
| --- | ---: | --- |
| Free | $0 | No ads. |
| Plus Monthly | $4.99 / month | Conversational shorthand may be "$5/month." |
| Plus Annual | $49.99 / year | Annual discount versus monthly total. |
| Complete Monthly | $14.99 / month | Conversational shorthand may be "$15/month." |
| Complete Annual | $149.99 / year | Working standard annual Complete price. |
| Complete Lifetime | $365.00 target | Standard symbolic lifetime target; exact App Store price point may be adjusted later. |

### Founder / launch promotional pricing

| Product | Founder / launch price | Notes |
| --- | ---: | --- |
| Plus Founder Annual | $39.99 / year | Same Plus entitlement; discounted launch price. |
| Complete Founder Annual | $99.99 / year | Same Complete entitlement; discounted launch price. |
| Complete Founder Lifetime | $249.99 one-time | Same Complete Lifetime entitlement; limited promotional price. |

### Pricing math notes

- Plus Monthly at $4.99 for 12 months equals $59.88/year.
- Plus Annual at $49.99 saves $9.89/year versus monthly, about 16.5%.
- Complete Monthly at $14.99 for 12 months equals $179.88/year.
- Complete Annual at $149.99 saves $29.89/year versus monthly, about 16.6%.
- Complete Founder Annual at $99.99 is a major founder discount and should be explicitly time-limited, cohort-limited, or launch-window-limited.
- Complete Founder Lifetime at $249.99 is aggressive relative to the Complete Annual price and should not be shown as an ordinary permanent public price unless the product deliberately chooses that strategy.

---

## Product IDs / entitlement keys — draft

These are draft internal identifiers. Exact App Store product IDs may change during implementation.

```text
Entitlement keys:
- subh.free
- subh.plus
- subh.complete
- subh.complete_lifetime
- subh.trial_complete
- subh.ramadan_preview

Subscription / purchase product IDs:
- com.subh.plus.monthly
- com.subh.plus.annual
- com.subh.plus.annual.founder
- com.subh.complete.monthly
- com.subh.complete.annual
- com.subh.complete.annual.founder
- com.subh.complete.lifetime
- com.subh.complete.lifetime.founder
```

Founder annual products may be represented either as separate products, introductory offers, promotional offers, offer codes, or store configuration rules. This spec owns the product meaning, not the StoreKit mechanism.

---

## Entitlement rank

Effective access should resolve by rank:

```text
Complete Lifetime
    > Complete Subscription
    > Complete Trial
    > Ramadan Preview, for Ramadan-scoped features only
    > Plus Subscription
    > Free
```

Rules:

1. A higher entitlement includes lower-tier access unless explicitly limited.
2. Founder pricing does not create a different feature tier.
3. Lifetime pricing does not create a different feature tier; it creates a non-expiring Complete entitlement.
4. A temporary entitlement, such as a Complete trial or Ramadan Preview, must be marked temporary in state so expiry behavior can be handled explicitly.
5. If multiple entitlements exist, the highest currently valid entitlement wins.
6. If entitlement cannot be verified, the app should use the last known valid entitlement for a short grace period only if the implementation supports safe grace handling; otherwise it should fall back conservatively while preserving all user data.

---

## Entitlement must not create separate engines

Subh has one morning-resolution engine.

Entitlement affects:

```text
visible surfaces
visible controls
display horizon
edit horizon
allowed user mutations
logging availability
progress/history availability
whether paid-only resolved events are allowed to become active/scheduled
paywall routing
```

Entitlement must **not** affect:

```text
Fajr calculation correctness
location correctness
prayer calculation method correctness
reliability warnings
permission warnings
Quiet semantics
underlying stored user meaning
base data preservation
resolved day meaning
opportunity detection
```

The resolver may know that a date has a Ramadan, Sunnah, Qada, or fasting opportunity even when the current tier cannot expose or activate the full paid workflow.

---

## Tier feature definitions

### Free

#### Promise

```text
Understand tomorrow's Fajr morning.
```

#### Included

Free includes:

- first launch and onboarding access;
- automatic or manual location setup;
- prayer calculation method setup;
- alarm / notification permission setup;
- reliability and missing-permission warnings;
- the main Morning Hero for the next relevant morning;
- Fajr begin/end context where the hero exposes it;
- fixed default Fajr wake behavior;
- Fajr mode for the immediate next morning;
- Quiet mode for the immediate next morning;
- basic alarm delivery for the fixed default Fajr wake, when permissions allow;
- no ads.

#### Not included

Free does not include:

- user-adjustable wake delta;
- wake-time drag/adjustment;
- expanded weekly planning controls;
- future-day editing beyond immediate Quiet where allowed;
- Suhoor mode;
- fasting-purpose selection;
- Qada fast planning;
- Ramadan planning controls beyond any temporary promotional access;
- monthly or annual planning;
- Adjusted Days repository;
- recurring boundary rules / presets;
- worship logs;
- Qada Fajr tracking;
- Qada fast tracking;
- custom fast tabs;
- progress/history analytics.

#### Free behavior principle

Free should be limited but dignified. It should not feel like the user is being charged for the existence of Fajr. The paid boundary is control, future planning, Suhoor/fasting planning, and tracking.

---

### Plus

#### Promise

```text
Control your Fajr week.
```

#### Included

Plus includes everything in Free, plus:

- adjust tomorrow's Fajr wake time;
- custom Fajr wake delta;
- wake adjustment within the Fajr window;
- near-term forecast surface access, targeted as `Next Week` / 7 mornings once the forecast spec is updated;
- Fajr-only editing for the weekly horizon;
- Quiet for any morning in the weekly horizon;
- Fajr-only Day Detail access for supported weekly dates;
- Weekly Fajrcast access;
- saved Plus-level Fajr overrides within the weekly edit horizon;
- locked previews or gentle prompts for Complete features.

#### Not included

Plus does not include:

- Suhoor mode;
- before-Fajr fasting wake planning;
- fasting-purpose override controls;
- Ramadan-specific Suhoor planning outside any active promotional entitlement;
- Qada fast planning;
- monthly browsing/editing;
- annual planning;
- Adjusted Days repository;
- recurring boundary rules / presets beyond any Plus-specific simple default setting;
- worship logs;
- Qada Fajr tracking;
- Qada fast tracking;
- custom fast tabs;
- progress/history analytics.

#### Plus behavior principle

Plus is a control tier, not the full worship-planning tier.

Plus should feel like:

```text
I can shape my Fajr wake routine for the week.
```

It should not feel like:

```text
I now have the full Suhoor, Ramadan, Qada, and tracking system.
```

---

### Complete

#### Promise

```text
Plan and track your Suhoor, fasting, Ramadan, Qada, and Fajr-centered year.
```

#### Included

Complete includes everything in Plus, plus:

- Suhoor mode;
- before-Fajr Suhoor wake planning;
- fasting-purpose selection where valid;
- automatic Suhoor fasting intention defaults;
- Ramadan locked fasting behavior;
- non-Ramadan fasting-purpose overrides where valid, including Qada, voluntary, Sunnah opportunity, vow/nadhr, kaffarah, and Other fast where supported by the fasting taxonomy;
- full supported current range / annual planning access;
- month browsing once implemented;
- Hijri/Gregorian month browsing once implemented;
- Monthly Fajrcast once implemented;
- Adjusted Days repository once implemented;
- recurring boundary rules / presets once implemented;
- Fajr prayer logging and tracking;
- Fajr qada logging/tracking, if retained as a product feature;
- Ramadan fasting tracking;
- fast logs;
- Qada fast ledger and tracking;
- custom fast tabs / fast categories;
- progress/history views;
- read/edit access to Complete-level planning and logging data;
- selected Ramadan promotional and retention surfaces.

#### MVP Complete logging scope

Complete MVP should support or prepare the data model for:

| Area | Minimum Complete expectation |
| --- | --- |
| Fajr log | User can log Fajr as prayed, missed, or not logged. |
| Fajr qada | User can record qada Fajr owed/completed if the product keeps this feature. Copy must avoid giving legal/religious rulings. |
| Fast log | User can log fast completed, not completed/missed, in progress, or not logged. |
| Ramadan fast tracking | Ramadan days can be tracked distinctly from voluntary/Qada fasts. |
| Qada fast | User can track owed/planned/completed Qada fasts. |
| Fast tabs | User can group/filter fasts by meaningful categories, such as Ramadan, Qada, voluntary, Sunnah, or custom tabs if implemented. |
| Progress/history | User can review meaningful progress without guilt-based design. |

#### Future Complete extensions

The following may belong to Complete later but are not required for the initial pricing MVP unless separately specified:

- masjid prayer alignment wake modes;
- mosque timetable source selection;
- community/mosque integrations;
- prayer in masjid tracking;
- advanced family/shared plans;
- Apple Watch-specific features;
- cloud sync;
- AI coaching or insight features;
- external-provider dependent services.

These must not be promised publicly until their own specs and implementation plans exist.

---

### Complete Lifetime

Complete Lifetime grants non-expiring access to the Complete entitlement as defined by the product at the time of purchase and ordinary future Complete improvements.

Rules:

1. Complete Lifetime is a purchase entitlement, not a separate feature tier.
2. Complete Lifetime should unlock the same features as Complete Subscription.
3. Complete Lifetime should not be the default main paywall option at launch unless Product intentionally wants a founder/patron model.
4. Complete Lifetime must not promise unlimited access to future costly external-service modules unless Product explicitly decides those are included.
5. Examples of possible future exceptions include cloud-heavy services, paid mosque-network integrations, AI features, family/team plans, or third-party provider costs.
6. If any future exception exists, the product copy must be transparent before purchase.

---

## Entitlement access matrix

| Capability | Free | Plus | Complete | Complete Lifetime |
| --- | ---: | ---: | ---: | ---: |
| Onboarding/setup | Yes | Yes | Yes | Yes |
| Location/manual city | Yes | Yes | Yes | Yes |
| Prayer calculation method | Yes | Yes | Yes | Yes |
| Reliability warnings | Yes | Yes | Yes | Yes |
| Morning Hero | Yes | Yes | Yes | Yes |
| Tomorrow Fajr wake display | Yes | Yes | Yes | Yes |
| Fixed default Fajr wake | Yes | Yes | Yes | Yes |
| Quiet tomorrow | Yes | Yes | Yes | Yes |
| Adjust tomorrow Fajr wake | No | Yes | Yes | Yes |
| Weekly forecast display | Locked/preview | Yes | Yes | Yes |
| Weekly Fajr editing | No | Yes | Yes | Yes |
| Quiet any weekly morning | No | Yes | Yes | Yes |
| Weekly Fajrcast | Locked/preview or hidden | Yes | Yes | Yes |
| Suhoor mode | No | No | Yes | Yes |
| Fasting-purpose selection | No | No | Yes | Yes |
| Ramadan Suhoor planning | Promo/trial only | Promo/trial only | Yes | Yes |
| Qada fast planning | No | No | Yes | Yes |
| Full supported range/year planning | No | No | Yes | Yes |
| Month browsing/editing | No | No | Yes | Yes |
| Monthly Fajrcast | No | No | Yes | Yes |
| Adjusted Days repository | No | No | Yes | Yes |
| Recurring boundary rules | No | No | Yes | Yes |
| Fajr logging | No | No | Yes | Yes |
| Fajr qada tracking | No | No | Yes | Yes |
| Fast logging | No | No | Yes | Yes |
| Ramadan fasting tracking | Promo/trial only | Promo/trial only | Yes | Yes |
| Qada fast tracking | No | No | Yes | Yes |
| Fast tabs | No | No | Yes | Yes |
| Progress/history analytics | Locked/read-only summary at most | Locked/read-only summary at most | Yes | Yes |

---

## 30-day Complete trial

### Trial decision

First-time users should receive a 30-day Complete trial.

Product intent:

```text
Let the user experience the full value of Subh before deciding what level of access they need.
```

### Trial entitlement

During the trial, the user receives:

```text
subh.trial_complete
```

`subh.trial_complete` behaves like Complete for feature access while active.

### Trial eligibility

Product-level eligibility:

```text
one 30-day Complete trial per first-time user / account / purchase identity
```

Implementation may use Apple ID, app account, local install state, or another mechanism depending on the final StoreKit/account architecture. The product should not promise unlimited repeat trials on reinstall.

### Trial start options

Preferred product behavior:

1. User completes onboarding enough for Subh to resolve a real morning.
2. The app offers the 30-day Complete trial.
3. The user may start the trial or continue as Free.
4. If the user skips the trial, locked Complete features may re-offer it later if still eligible.

Alternative behavior:

- Automatically start the 30-day Complete trial for every first-time user after onboarding.

Recommendation:

```text
Offer the trial clearly rather than silently activating it, unless App Store mechanics or product testing prove automatic activation is better.
```

### Trial expiry

When the trial expires and no paid entitlement exists:

1. Effective entitlement becomes Free.
2. All Complete-created data remains stored.
3. Complete-only controls become locked.
4. Complete-only future plans become inactive/locked rather than deleted.
5. Scheduling refresh must run so paid-only events are not left scheduled without entitlement.
6. The user is shown a calm expiry message and can choose Free, Plus, Complete, or Lifetime where available.

### Trial expiry warning

The app should warn the user before expiry if feasible:

```text
Your Complete trial ends soon. Your plans and logs will stay saved, but Suhoor, fasting, Qada, and full-year controls require Complete after the trial.
```

### No data hostage principle

Trial data must not be deleted when the trial ends. Users should not feel punished for trying the product.

---

## Ramadan promotional entitlement

Ramadan promotional access should be modeled as a temporary entitlement rather than as a fourth permanent tier.

Draft entitlement:

```text
subh.ramadan_preview
```

### Purpose

Ramadan Preview lets Subh be generous during Ramadan while still preserving the long-term value of Complete.

### Possible Ramadan Preview scope

Ramadan Preview may include:

- Ramadan Suhoor wake planning;
- Ramadan locked fasting purpose;
- Ramadan fast logging;
- Ramadan daily progress;
- limited Ramadan calendar view;
- limited Ramadan retention flow after expiry.

Ramadan Preview should not automatically include:

- full-year planning;
- non-Ramadan Qada planning;
- full historical analytics;
- custom fast tabs beyond Ramadan;
- all Complete advanced tools.

### Ramadan Preview expiry

After Ramadan Preview expires:

1. Ramadan logs remain stored.
2. The user may retain read-only access to basic Ramadan history.
3. Continuing Qada, full progress, annual planning, and editing should require Complete.
4. The app may show a post-Ramadan retention message:

```text
Keep your Ramadan record and continue Qada planning with Subh Complete.
```

### Strategic note

Because Complete Monthly is $14.99, users who want only Ramadan access can also use one month of Complete. Ramadan Preview should be used deliberately, not as a permanent replacement for the Complete monthly plan.

---

## Paywall entry points

Paywalls should be calm, contextual, and non-guilt-based.

### Allowed paywall triggers

| Trigger | Paywall type |
| --- | --- |
| User taps locked wake adjustment in Free | Plus-focused paywall. |
| User taps weekly forecast/editing in Free | Plus-focused paywall. |
| User taps Suhoor in Free or Plus | Complete-focused paywall. |
| User selects fasting-purpose controls in Free or Plus | Complete-focused paywall. |
| User opens Qada fast planning | Complete-focused paywall. |
| User opens Fajr/qada/fast logging | Complete-focused paywall. |
| User opens annual/month browsing if Complete-only | Complete-focused paywall. |
| User opens progress/history analytics | Complete-focused paywall. |
| Trial expires | Choice paywall: Free / Plus / Complete / Lifetime if available. |
| User opens Settings > Subscription | Neutral plan-management screen. |
| Ramadan promotional period | Ramadan-specific Complete / Ramadan Preview paywall. |

### Forbidden paywall behavior

Do not:

- hide reliability warnings behind a paywall;
- hide location setup behind a paywall;
- hide prayer calculation setup behind a paywall;
- use guilt language around missed prayers or fasting;
- imply that paying makes the user's worship better;
- create a confusing fourth permanent tier;
- delete data as a pressure tactic;
- schedule paid-only alarms after entitlement expiry without clear active entitlement.

---

## Paywall copy framework

### Tier card copy

#### Free

```text
Subh Free
Understand tomorrow's Fajr morning.

Includes:
- Tomorrow's Fajr wake plan
- Fixed Fajr wake
- Quiet for tomorrow
- Location and prayer-time setup
```

#### Plus

```text
Subh Plus
Control your Fajr week.

$4.99/month or $49.99/year

Includes:
- Adjust your Fajr wake time
- Plan your Fajr week
- Weekly Fajrcast
- Quiet any weekly morning
```

#### Complete

```text
Subh Complete
Plan and track your Suhoor, fasting, Ramadan, Qada, and Fajr-centered year.

$14.99/month or $149.99/year

Includes:
- Suhoor mode
- Ramadan and fasting planning
- Qada fast tracking
- Fajr and fast logs
- Full-year planning
- Progress and history
```

#### Complete Lifetime

```text
Complete Lifetime
One purchase for permanent Complete access.

Founder price: $249.99
Standard target: $365
```

### Tone rules

Paywall language should feel:

- calm;
- premium;
- direct;
- respectful;
- non-guilt-based;
- clear about the practical benefit.

Avoid:

```text
Don't miss out on rewards!
Real Muslims track their fasts.
Upgrade or lose your plans.
You failed this month.
```

Prefer:

```text
Your plans and logs stay saved.
Upgrade when you want to continue planning and tracking with Complete.
```

---

## Data ownership and preservation

### Core principle

```text
Downgrading changes access. It does not delete user meaning.
```

Subh should preserve user-created data unless the user explicitly deletes it or requests account/data deletion.

### Data categories

| Data category | Created by | Stored after downgrade? | Active after downgrade? | Notes |
| --- | --- | ---: | ---: | --- |
| Location settings | All tiers | Yes | Yes | Required for correctness. |
| Prayer method settings | All tiers | Yes | Yes | Required for correctness. |
| Default fixed Fajr wake | All tiers | Yes | Yes | Free baseline. |
| Free Quiet tomorrow | Free+ | Yes | Yes if date applies | Free-safe. |
| Plus Fajr weekly override | Plus+ | Yes | Plus/Complete only | Locked/inactive in Free. |
| Complete Suhoor plan | Complete/trial | Yes | Complete/lifetime/trial only | Locked/inactive in Free/Plus. |
| Complete fasting-purpose selection | Complete/trial | Yes | Complete/lifetime/trial only | Preserved for restoration. |
| Ramadan logs | Complete/trial/Ramadan Preview | Yes | Read-only or Complete editable | Do not delete after expiry. |
| Fajr logs | Complete/trial | Yes | Read-only summary or Complete editable | Avoid data hostage. |
| Qada fast ledger | Complete/trial | Yes | Read-only summary or Complete editable | Preserve owed/completed state. |
| Qada Fajr tracking | Complete/trial | Yes | Read-only summary or Complete editable | If retained. |
| Fast tabs/categories | Complete/trial | Yes | Complete editable; locked/read-only otherwise | Preserve custom organization. |
| Progress/history analytics | Complete/trial | Yes | Complete active; lower tiers locked/limited | Derived analytics may regenerate. |
| Delivery ledger | System | Yes per retention policy | Internal | Privacy-preserving diagnostics. |
| Purchase/entitlement cache | System | Yes | Depends on verification | Must not be the source of truth for religious data. |

---

## Downgrade behavior

A downgrade occurs when the effective entitlement decreases, such as:

```text
Complete -> Plus
Complete -> Free
Plus -> Free
Trial Complete -> Free
Trial Complete -> Plus
Trial Complete -> Complete paid
Ramadan Preview -> Free/Plus
```

### Required downgrade behavior

When entitlement decreases:

1. Preserve all data.
2. Recompute effective entitlement.
3. Re-resolve visible mornings.
4. Recompute display horizon.
5. Recompute edit horizon.
6. Lock unsupported controls.
7. Mark unsupported paid-only plans as inactive/locked.
8. Cancel or suppress paid-only scheduled events that are no longer entitlement-supported.
9. Keep lower-tier-supported plans active where allowed.
10. Show a calm explanation of what changed.

### Complete to Plus

When the user moves from Complete to Plus:

- Plus Fajr-week controls remain available.
- Complete Suhoor plans remain stored but locked/inactive.
- Complete fasting-purpose selections remain stored but locked/inactive.
- Complete logs remain stored.
- New log creation and editing are locked unless a read-only/lite behavior is explicitly allowed.
- Annual/month planning is locked.
- Qada tracking is locked/read-only.
- The effective active wake for a date with a locked Suhoor plan should fall back to the best supported lower-tier behavior, usually default or Plus Fajr, unless the user upgrades again.

### Plus to Free

When the user moves from Plus to Free:

- Plus weekly Fajr overrides remain stored but locked/inactive.
- Tomorrow's fixed default Fajr wake remains available.
- Quiet tomorrow remains available.
- Weekly forecast/editing becomes locked/preview.
- Paid Plus edits should not continue controlling alarms while Free unless Product explicitly allows grandfathering.

### Complete to Free

When the user moves from Complete to Free:

- Complete plans/logs remain stored.
- Suhoor and fasting controls are locked.
- Qada and logs are locked/read-only.
- Plus controls are also locked unless the user has Plus.
- Effective active behavior returns to Free baseline unless an active promotional entitlement applies.

---

## Upgrade behavior

An upgrade occurs when the effective entitlement increases, such as:

```text
Free -> Plus
Free -> Complete
Plus -> Complete
Free/Plus -> Complete Lifetime
Trial -> paid Complete
```

### Required upgrade behavior

When entitlement increases:

1. Recompute effective entitlement.
2. Unlock newly supported surfaces and controls.
3. Rehydrate preserved paid-tier data relevant to the new entitlement.
4. Re-resolve affected mornings.
5. Refresh schedules for eligible near-term events inside the active scheduled horizon.
6. Avoid duplicating old override records or scheduled events.
7. Explain restored features only when useful.

### Free to Plus

Unlock:

- Fajr wake adjustment;
- weekly horizon controls;
- Plus-level Fajr overrides;
- Weekly Fajrcast;
- Fajr-only Day Detail edits.

Do not unlock:

- Suhoor;
- fasting-purpose selection;
- Qada/logs;
- full-year planning.

### Plus to Complete

Unlock:

- Suhoor;
- fasting-purpose controls;
- Ramadan/Qada planning;
- full supported range;
- logs;
- progress/history.

If the user had preserved Complete data from a prior subscription/trial, that data should become active again where valid.

### Free to Complete

Unlock all Complete features.

If no prior paid data exists, defaults should be clean and not cluttered. Do not create future Suhoor plans merely because the user upgraded.

---

## Conflict handling after downgrade and later edits

A conflict can occur when a user has preserved Complete data but edits the same date while on Plus or Free.

Example:

```text
User planned Suhoor for a future Monday while on Complete.
User downgrades to Plus.
The Suhoor plan is locked/inactive.
User edits the same date as a Fajr wake in Plus.
User later re-upgrades to Complete.
```

### Required conflict rule

The app must not silently overwrite preserved higher-tier user meaning.

Allowed approaches:

1. **Archive-and-replace:** lower-tier edit becomes the active lower-tier plan, while the old Complete plan remains archived and can be restored after re-upgrade.
2. **Prompt-before-replace:** when the user edits a date with locked higher-tier data, show a message explaining that the lower-tier edit will replace the active behavior while the previous paid plan is preserved.
3. **Restore-choice on re-upgrade:** when the user re-upgrades, if both lower-tier and preserved higher-tier data exist for the same date, ask whether to keep the current plan or restore the previous Complete plan.

MVP recommendation:

```text
Use archive-and-replace with a clear banner, and defer restore-choice UI until needed.
```

---

## Scheduling after entitlement changes

Entitlement changes must trigger schedule refresh.

### Required behavior

When entitlement changes:

1. Active scheduled window is rebuilt.
2. Paid-only events outside the user's current entitlement are not schedule-eligible.
3. Stale paid-only platform deliveries are cancelled if they are no longer allowed.
4. Lower-tier events that remain valid are scheduled or verified normally.
5. Quiet remains intentional suppression, not a payment failure.
6. Delivery failure must not become entitlement failure.
7. Entitlement failure must not become Quiet.

### Paid-only event examples

| Event / plan | Required entitlement |
| --- | --- |
| Default Fajr wake | Free+ |
| Plus-adjusted Fajr wake | Plus+ |
| Weekly Plus Fajr override | Plus+ |
| Suhoor wake | Complete / Complete Trial / Complete Lifetime / applicable Ramadan Preview |
| Qada fast Suhoor wake | Complete / Complete Trial / Complete Lifetime |
| Ramadan Suhoor wake | Complete / Complete Trial / Complete Lifetime / applicable Ramadan Preview |
| Fasting log reminder | Complete / Complete Trial / Complete Lifetime / applicable Ramadan Preview if scoped |

---

## Locked feature behavior

A locked feature may be:

1. hidden;
2. visible but disabled;
3. visible as a locked preview;
4. visible read-only;
5. available through trial/promo.

### Preferred locking rules

| Feature | Lower-tier lock behavior |
| --- | --- |
| Suhoor selector | Visible locked option or hidden depending on surface clarity. If visible, tapping opens Complete paywall. |
| Weekly forecast in Free | Locked preview or collapsed locked card. Do not show dense rows that compete with Hero. |
| Fajr wake adjustment in Free | Disabled with Plus prompt. |
| Fasting-purpose controls | Locked Complete prompt. |
| Qada ledger | Read-only locked summary if data exists; otherwise Complete prompt. |
| Logs | Existing logs read-only or summary-visible; new/edit actions Complete-only. |
| Progress/history | Preview/summary; detailed analytics Complete-only. |
| Month/year planning | Complete prompt. |

---

## Read-only access after downgrade

To avoid data hostage behavior, previously created logs and ledgers should not disappear completely after downgrade.

Recommended lower-tier behavior for previously created Complete data:

| Data | Free/Plus after downgrade |
| --- | --- |
| Fajr logs | Show read-only summary or locked list preview. Editing/new logs require Complete. |
| Fast logs | Show read-only summary or locked list preview. Editing/new logs require Complete. |
| Ramadan record | Show basic read-only Ramadan summary. Detailed analytics require Complete. |
| Qada fast ledger | Show remaining count/read-only summary if available. Editing requires Complete. |
| Fast tabs | Show tab names/counts read-only if data exists. Editing requires Complete. |

User trust rule:

```text
Do not make the user feel that their own past record was confiscated.
```

---

## Account deletion and explicit data deletion

Downgrade must not delete data.

Data may be deleted only when:

1. the user explicitly deletes a record;
2. the user resets a relevant feature according to spec;
3. the user requests account/app data deletion;
4. retention/privacy policy requires deletion;
5. a migration removes invalid corrupted data and records a safe migration diagnostic.

---

## MVP feature scope for pricing

### MVP pricing-covered features

The pricing spec should cover these MVP or MVP-near features:

- Free Fajr orientation;
- Free fixed default wake;
- Free immediate Quiet;
- Plus Fajr adjustment;
- Plus weekly planning horizon;
- Complete Suhoor mode;
- Complete fasting-purpose selection;
- Complete Ramadan tracking;
- Complete Qada fast tracking;
- Complete Qada Fajr tracking if retained;
- Complete Fajr logs;
- Complete fast logs;
- Complete fast tabs;
- Complete progress/history;
- Complete trial;
- founder annual pricing;
- founder lifetime pricing;
- downgrade preservation.

### Deferred / future features

The pricing spec may mention but must not promise these until separate specs exist:

- masjid connection;
- mosque timetable integration;
- masjid-aligned wake modes;
- prayer in masjid tracking;
- AI insights;
- cloud sync;
- family/shared plans;
- Apple Watch;
- separate Ramadan app/pass;
- paid external provider sources.

---

## Forecast horizon note: Next 10 vs Next Week

The active uploaded forecast spec still defines `Next 10 Mornings` as a ten-row surface. This pricing spec records the intended pricing direction:

```text
Plus should control the near-term Fajr week.
Target near-term horizon: 7 mornings / Next Week.
```

Required follow-up:

- Update `subh-next-10-mornings-wake-forecast-spec-v4.md` into a `Next Week` / 7-morning forecast spec if Product locks the 7-day decision.
- Until that follow-up spec is created, implementation must not assume pricing alone has rewritten the Next 10 visual contract.

---

## Paywall transition matrix

| From | To | User action / event | Data behavior | Schedule behavior |
| --- | --- | --- | --- | --- |
| Free | Plus | Purchase Plus monthly/annual/founder | Existing Free data preserved; Plus features unlock. | Rebuild active window; Plus-supported Fajr edits schedule if created. |
| Free | Complete | Purchase Complete monthly/annual/founder | Existing data preserved; Complete data rehydrates if previously stored. | Rebuild active window; Complete-supported events become eligible. |
| Free | Trial Complete | Start 30-day trial | Existing data preserved; trial Complete features unlock. | Rebuild active window; Complete events eligible while trial active. |
| Free | Lifetime | Buy Complete Lifetime | Existing data preserved; Complete features permanently unlock. | Rebuild active window; Complete-supported events eligible. |
| Plus | Complete | Upgrade | Plus data preserved; Complete data rehydrates. | Rebuild active window; Suhoor/fasting events eligible. |
| Plus | Free | Cancel/expire/downgrade | Plus data preserved but locked/inactive. | Cancel paid-only Plus scheduled events; Free Fajr baseline remains. |
| Complete | Plus | Downgrade | Complete data preserved, locked/read-only; Plus subset remains active. | Cancel/suppress Complete-only scheduled events; Plus events remain eligible. |
| Complete | Free | Cancel/expire/downgrade | Complete data preserved, locked/read-only. | Cancel/suppress paid-only events; Free Fajr baseline remains. |
| Trial Complete | Complete | Purchase Complete | Trial data becomes paid Complete data. | Continue eligible scheduling; avoid duplicate events. |
| Trial Complete | Plus | Purchase Plus after trial | Complete data preserved but locked; Plus unlocks. | Complete-only events cancelled; Plus events eligible. |
| Trial Complete | Free | Trial expires | Trial data preserved but locked/read-only. | Complete-only events cancelled; Free baseline remains. |
| Ramadan Preview | Complete | Upgrade | Ramadan data remains; all Complete features unlock. | Complete events eligible. |
| Ramadan Preview | Free/Plus | Promo expires | Ramadan data preserved read-only/basic; non-entitled controls locked. | Promo-only events cancelled unless lower tier supports them. |
| Any | Lifetime | Buy lifetime | Existing data preserved; Complete permanently unlocks. | Complete-supported events eligible. |

---

## Entitlement state model — conceptual

Recommended conceptual model:

```swift
enum SubhEntitlementLevel: String, Codable, Comparable {
    case free
    case plus
    case complete
    case completeLifetime
}

struct SubhEntitlementState: Codable, Equatable {
    let effectiveLevel: SubhEntitlementLevel
    let activeProducts: [String]
    let isTrialActive: Bool
    let trialEndsAt: Date?
    let isRamadanPreviewActive: Bool
    let ramadanPreviewEndsAt: Date?
    let isFounderPlan: Bool
    let verifiedAt: Date?
    let verificationState: EntitlementVerificationState
}

enum EntitlementVerificationState: String, Codable {
    case verified
    case gracePeriod
    case expired
    case unavailable
    case revoked
}
```

The exact Swift implementation may differ. The important requirement is that feature gates consume a single normalized entitlement state.

---

## Feature gate model — conceptual

Recommended conceptual gates:

```swift
enum SubhFeatureGate: String, Codable {
    case heroView
    case fixedFajrWake
    case quietTomorrow
    case fajrWakeAdjustment
    case weeklyForecastView
    case weeklyFajrEditing
    case weeklyQuietEditing
    case suhoorMode
    case fastingPurposeSelection
    case ramadanPlanning
    case qadaFastPlanning
    case annualPlanning
    case monthBrowsing
    case adjustedDaysRepository
    case recurringBoundaryRules
    case fajrLogging
    case fajrQadaTracking
    case fastLogging
    case ramadanFastTracking
    case qadaFastTracking
    case fastTabs
    case progressHistory
    case lifetimePurchase
}
```

Feature gates should be resolved centrally, not separately in every view.

---

## Acceptance criteria

### Pricing acceptance

- [ ] Free is $0.
- [ ] Plus Monthly is $4.99.
- [ ] Plus Annual is $49.99.
- [ ] Plus Founder Annual is $39.99.
- [ ] Complete Monthly is $14.99.
- [ ] Complete Annual is $149.99.
- [ ] Complete Founder Annual is $99.99.
- [ ] Complete Lifetime standard target is $365.00.
- [ ] Complete Founder Lifetime is $249.99.
- [ ] Founder pricing does not create separate features.
- [ ] Lifetime pricing grants Complete-level entitlement, not a fourth feature system.

### Entitlement acceptance

- [ ] One normalized entitlement state is available to all feature gates.
- [ ] Free can use core setup, hero, fixed Fajr wake, and Quiet tomorrow.
- [ ] Plus can control Fajr wake behavior across the near-term weekly horizon.
- [ ] Complete can use Suhoor, fasting, Ramadan, Qada, logs, and full supported planning.
- [ ] Lower tiers cannot commit unsupported paid-only mutations.
- [ ] Entitlement does not affect Fajr calculation correctness or reliability warnings.
- [ ] Entitlement changes trigger re-resolution and schedule refresh.

### Data preservation acceptance

- [ ] Downgrade does not delete paid-tier data.
- [ ] Paid-tier plans become locked/inactive when unsupported by current entitlement.
- [ ] Paid-tier scheduled events are cancelled/suppressed after entitlement expiry.
- [ ] Logs and ledgers are preserved after downgrade.
- [ ] Previously created data rehydrates when the user re-upgrades.
- [ ] Explicit deletion remains available where feature specs support it.

### Trial acceptance

- [ ] First-time users can receive a 30-day Complete trial.
- [ ] Trial access behaves like Complete while active.
- [ ] Trial data is preserved after expiry.
- [ ] Trial expiry falls back to Free unless a paid entitlement exists.
- [ ] Trial expiry cancels/suppresses unsupported Complete-only events.

### Paywall acceptance

- [ ] Paywalls are contextual and non-guilt-based.
- [ ] Tapping Plus features from Free opens a Plus-focused paywall.
- [ ] Tapping Complete features from Free/Plus opens a Complete-focused paywall.
- [ ] Trial expiry opens a plan-choice paywall.
- [ ] Existing user data is never threatened in paywall copy.

---

## Required follow-up specs

This pricing spec creates work, but it should not absorb all related work.

Required separate specs / updates:

1. `subh-testflight-beta-strategy-spec-v1.md`
   Owns TestFlight phases, cohorts, beta feedback, sandbox purchase testing, and App Store launch readiness.

2. `subh-worship-logging-qada-tracking-spec-v1.md`
   Owns Fajr logs, fast logs, Ramadan tracking, Qada Fajr, Qada fast, fast tabs, history, and progress details.

3. `subh-next-week-wake-forecast-spec-v1.md` or updated `subh-next-10-mornings-wake-forecast-spec-v5.md`
   Owns the 7-morning / Next Week change if Product locks it.

4. Planning Horizon update
   Adds entitlement-aware display and edit horizons.

5. `subh-mvp-interaction-tier-exposure-matrix-v1.md`
   Owns tier exposure for scenario groups and entitlement-specific `P` scenario IDs while preserving `subh-mvp-interaction-inventory-v3.md` as the authority for `S001-S235`.

6. Home Composition / Paywall Surface Spec
   Owns where paywall cards, locked previews, and subscription entry points appear visually.

7. StoreKit / Subscription Implementation Plan
   Owns App Store product setup, sandbox tests, purchase restoration, receipt/transaction verification, and exact product IDs.

---

## Open decisions

These are not blockers for this spec, but they should be resolved before implementation is considered complete.

| Decision | Current working stance |
| --- | --- |
| Should Complete Annual be $149.99 or lower? | Locked for this spec at $149.99 to mirror the Plus annual discount ratio. |
| Should Lifetime be public at launch? | Prefer limited founder/patron availability, not default main paywall. |
| Should Free show a locked weekly preview? | Recommended, but visual details belong to Home Composition / Paywall Surface spec. |
| Should existing logs be fully viewable after downgrade? | Recommend read-only or summary access to avoid data-hostage behavior. |
| Should Ramadan Preview be free for all users or offer-code based? | Product decision deferred; entitlement model supports it. |
| Should Qada Fajr tracking remain in MVP Complete? | Current user direction includes it; dedicated logging spec must define carefully. |
| Should masjid tracking be MVP? | No; keep future unless separately promoted. |

---

## Codex implementation guardrails

When implementing this spec, Codex must not:

- implement TestFlight strategy in this pricing spec;
- create separate Free/Plus/Complete morning engines;
- change Fajr calculation behavior because of entitlement;
- hide reliability warnings behind payment;
- delete paid-tier data on downgrade;
- leave paid-only alarms scheduled after entitlement expiry;
- expose Tahajjud-only or Other early worship as MVP paid features;
- rename Suhoor back to Pre-Fajr, Fast, or Early;
- convert opportunities into intentions merely because Complete is active;
- create logging/progress features without a dedicated logging/Qada spec.
