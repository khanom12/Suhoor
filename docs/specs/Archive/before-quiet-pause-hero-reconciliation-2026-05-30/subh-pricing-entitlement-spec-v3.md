# Subh Pricing and Entitlement Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-pricing-entitlement-spec-v3.md` |
| Version | 3 |
| Spec status | Draft; proposed canonical working spec; replaces multi-paid-tier model with Free + one paid tier; aligned to Wake Sessions and immediate MorningLogs |
| Date | 2026-05-26 |
| Related specs | `00-subh-spec-index-v3.md`, `subh-mvp-interaction-inventory-v4.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md`, `subh-weekly-fajrcast-card-spec-v14.md` |
| Owning domain / surface | Pricing, entitlement, trial access, paywall rules, downgrade/upgrade behavior, paid-feature data preservation |
| Implementation audit status | Needs implementation audit |
| Supersedes | Historical/superseded: `subh-pricing-entitlement-spec-v2.md` |

---

## Purpose

This specification defines Subh's pricing and entitlement model after the strategic shift away from multiple paid tiers.

It answers:

```text
Which tiers exist?
What does each tier promise?
What does each tier allow the user to see, edit, activate, schedule, and log?
Which product capabilities must remain free?
Which product capabilities are appropriate for the single paid tier?
How should price be represented before the Plus price is finalized?
What happens when a user upgrades, downgrades, cancels, expires, restores, or receives temporary promotional access?
What happens to previously created paid-tier data when the current entitlement no longer supports it?
Where should paywalls appear?
Which features are MVP pricing scope, and which are future extensions?
```

This spec is intentionally separated from:

- TestFlight strategy;
- StoreKit configuration;
- final price selection;
- marketing copy;
- detailed worship logging mechanics;
- detailed Wake Session execution mechanics;
- detailed Quiet Mode restoration mechanics;
- detailed alarm-sound asset authoring;
- family/household accountability design.

Those concerns should be handled by separate specs or implementation plans.

---

## Strategic change from v2

Version 2 used a multi-tier model:

```text
Free
Plus
Complete
Complete-family lifetime
```

Version 3 replaces that model with:

```text
Free
Plus
```

`Complete` is removed from the active MVP pricing model.

`Complete-family lifetime` is removed from the active MVP pricing model.

`founder Complete`, `Complete annual`, `Complete monthly`, and `Complete-family lifetime` product concepts are removed from the active MVP pricing model.

Family / household accountability remains a possible future monetization path, but it is not an MVP tier and must not be implemented as a third paid tier without a dedicated future spec.

---

## Pricing doctrine

Subh should be priced as a calm, reliable, faith-centered morning system.

The revised doctrine is:

```text
Subh Free is the complete morning wake utility.
Subh Plus is the personal practice memory, history, insight, and accountability layer.
```

Subh should not charge the user merely to wake for Fajr, plan Suhoor, use Quiet, adjust wake timing, or plan upcoming mornings.

Subh may charge when the product begins preserving, organizing, interpreting, exporting, or coordinating the user's practice over time.

### Core principles

1. **Core morning utility remains free.**
   The user should not feel that they must pay to reliably plan, adjust, or use their Fajr or Suhoor morning.

2. **Paid value begins when Subh becomes a durable record.**
   Plus monetizes history, logs, trends, summaries, Qada ledgers, reflection, export, sync, and advanced accountability.

3. **The user pays for accumulated value, not basic control.**
   The paywall should appear after the user understands Subh's usefulness, especially when their own data has begun to matter.

4. **The app remains one system.**
   Pricing gates advanced surfaces, histories, analytics, and paid-only actions. It must not create separate Free and Plus morning engines.

5. **No guilt-based monetization.**
   Paywall language must not imply that paying improves the user's worship or that non-paying users are deficient.

Short pricing doctrine:

```text
Free helps the user plan and wake.
Plus helps the user remember, review, improve, and stay accountable.
```

---

## Price status

No Plus price is locked in this spec.

### Current decision

```text
The product has one paid tier, named Plus.
The exact Plus monthly, annual, launch, founder, student, family, or regional prices are not finalized.
```

### Out of scope for this spec

This spec does not lock:

- monthly price;
- annual price;
- annual discount ratio;
- trial length;
- launch/founder discount;
- lifetime price;
- family price;
- App Store price-point mapping;
- regional pricing.

A future pricing decision or StoreKit implementation plan may define candidate prices and App Store product identifiers.

### Implementation rule

Until a price is finalized, product copy, paywall copy, and code must avoid hardcoded prices such as:

```text
$4.99/month
$36/year
$49.99/year
$14.99/month
$149.99/year
$365 lifetime
```

If a UI needs to display a price during implementation, it must read the price from the active StoreKit product metadata or use placeholder copy in non-production builds.

---

## Tier names and core promises

| Tier | Core promise | Product meaning |
| --- | --- | --- |
| `Free` | Plan and wake for your Fajr-centered morning. | The complete core morning utility: Fajr, Suhoor, Quiet, adjustments, and planning access. |
| `Plus` | Remember, review, and improve your Fajr, fasting, and morning practice over time. | The durable record and insight layer: logs, history, trends, Qada ledgers, summaries, reflections, backup/export, and advanced accountability. |

### Removed active tiers

| Removed tier | Replacement stance |
| --- | --- |
| `Complete` | Removed from MVP pricing. Its former wake/planning capabilities move mostly into Free; its former logging/history capabilities move into Plus. |
| `Complete-family lifetime` | Removed from MVP pricing. Lifetime may be reconsidered later only through a dedicated pricing decision. |
| `Ramadan Preview` as a pseudo-tier | May exist only as temporary promotional access or temporary Plus feature exposure; it must not become a permanent third tier. |
| `Family` | Future concept only. It must not be built as part of MVP pricing without a dedicated family/household accountability spec. |

---

## Source alignment

This spec is aligned with the current Subh MVP source of truth:

1. Subh is one Fajr-centered morning system, not separate Fajr, fasting, Ramadan, Qada, Free, and Plus engines.
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
10. Surfaces emit intents and consume the resolved morning graph.
11. Pricing must not create parallel state machines.
12. Core wake planning and alarm control should remain free.
13. Plus should primarily attach to logging, history, analytics, Qada ledgers, export/sync, advanced summaries, and accountability.
14. Wake Sessions, core Wake Checks, wake-check cancellation, and active-morning awake confirmation are part of the Free core wake utility.
15. `Alarm stopped` is not `user awake`; pricing must not weaken the Wake Session confirmation model.
16. `I’m awake for Fajr`, `I’m awake for Suhoor`, `I prayed Fajr`, and `I’m fasting today` are immediate MorningLog/check-in actions when shown in the current active morning loop; they must not be treated as paid-only just because their long-term history can later feed Plus.
17. Suhoor confirmation may set `fastingIntentConfirmed`; it must not imply `fastCompletionConfirmed`.
18. Fajr awake confirmation must not imply Fajr prayer completion.
19. Quiet Morning remains a Free intentional-suppression state and must not be priced, logged, or paywalled as missed prayer.
20. Core ramped alarm sound assets and sound-role correctness are Free wake-reliability behavior; future premium sound libraries, if any, require a later spec.

---

## Wake Sessions and immediate MorningLogs entitlement alignment

This section is normative and supersedes any lower wording that could accidentally make the active-morning wake loop a Plus-only logging feature.

### Core rule

```text
Wake Sessions and immediate MorningLogs are Free core utility.
Durable history, review, analytics, ledgers, export, and advanced accountability are Plus.
```

Pricing must preserve the product distinction:

```text
Execution now ≠ historical memory layer
```

### Free immediate actions

The following actions are Free when they occur inside the current or active morning loop:

| Action | Free meaning | Plus relationship |
| --- | --- | --- |
| `I’m awake for Fajr` | Confirms the Fajr Wake Session and cancels remaining wake checks. | May later appear in Plus history, trends, or analytics. |
| `I’m awake for Suhoor` | Confirms the Suhoor Wake Session and cancels remaining wake checks. | May later appear in Plus history, trends, or analytics. |
| `I prayed Fajr` | Current-morning prayer check-in / immediate MorningLog. | Full prayer history, historical editing, Qada ledgers, summaries, and analytics are Plus. |
| `I’m fasting today` / automatic Suhoor fasting intent | Current-day fasting intent check-in. | Fast history, Ramadan summaries, Qada ledgers, fast tabs, and analytics are Plus. |
| `Quiet for this morning` | Cancels/suppresses wake execution for the active morning and records `quietMorning`. | Quiet patterns may later appear in Plus insight surfaces. |

### Operational records for all users

Subh may store local operational records for all users because the wake system requires them:

```text
WakeSession created
primary alarm scheduled/fired/stopped
wake check scheduled/fired/stopped/cancelled
awake confirmation recorded
current-morning prayer check-in recorded
current-day fasting intent recorded
quietMorning recorded
WakeSession expired unconfirmed
```

These records are not automatically the same as the full paid logging/history product. Free can use them for current/recent status, reliability, cancellation, reconciliation, and immediate user feedback. Plus can expose them over time as history, trends, summaries, Qada context, export, or accountability where supported by dedicated logging specs.

### Paywall boundary

Do not show a paywall before allowing the user to:

- confirm awake;
- cancel remaining wake checks by confirming awake;
- mark the active morning as Quiet;
- acknowledge the current Fajr prayer check-in when that CTA is shown;
- acknowledge current-day fasting intent when that CTA is shown;
- keep core alarm delivery reliable.

A paywall may appear when the user tries to open durable historical surfaces, edit historical logs, use Qada ledgers, generate summaries/trends, export/sync records, or use advanced accountability.

---

## Out of scope

This spec does **not** define:

- TestFlight beta strategy.
- Final Plus price.
- StoreKit implementation details beyond draft entitlement implications.
- Exact App Store Connect configuration steps.
- Taxes, regional price equalization, foreign-currency localization, or App Store price-point availability.
- Refund policy.
- Legal terms of service.
- Privacy policy.
- Marketing site copy.
- Detailed UI layout for paywalls.
- Full onboarding spec.
- Full worship logging implementation spec.
- Full Qada tracking implementation spec.
- Detailed Wake Session scheduling, wake-check, confirmation, and MorningLog mechanics.
- Detailed Quiet Mode active-session confirmation and restoration mechanics.
- Detailed sound-asset authoring or audio waveform production.
- Family/household accountability design.
- Full TestFlight, sandbox, or App Review strategy.

Those should be handled by separate specs or implementation plans.

---

## Product IDs / entitlement keys — draft

These are draft internal identifiers. Exact App Store product IDs may change during implementation.

```text
Entitlement keys:
- subh.free
- subh.plus
- subh.trial_plus
- subh.ramadan_promo
```

Draft subscription / purchase product IDs:

```text
Subscription / purchase product IDs:
- com.subh.plus.monthly
- com.subh.plus.annual
```

Potential future promotional products or offers:

```text
Potential promotional mechanisms:
- introductory offer for com.subh.plus.monthly
- introductory offer for com.subh.plus.annual
- offer code for Plus
- temporary Plus trial entitlement
- Ramadan promotional access entitlement
```

Rules:

1. Founder pricing, if used later, must not create a separate feature tier.
2. A trial, if used later, must not create a separate feature tier.
3. Ramadan promotional access, if used later, must not create a separate permanent feature tier.
4. Family / household pricing must not be added to these identifiers without a dedicated future spec.

---

## Entitlement rank

Effective access should resolve by rank:

```text
Plus Subscription
    > Plus Trial
    > Ramadan Promo, for explicitly scoped promotional features only
    > Free
```

Rules:

1. Plus includes Free access.
2. A temporary entitlement, such as a Plus trial or Ramadan Promo, must be marked temporary in state so expiry behavior can be handled explicitly.
3. If multiple entitlements exist, the highest currently valid entitlement wins.
4. If entitlement cannot be verified, the app should use the last known valid entitlement for a short grace period only if the implementation supports safe grace handling.
5. If safe grace handling is not available, the app should fall back conservatively while preserving all user data.
6. Entitlement failure must not corrupt wake plans, location settings, prayer calculation settings, or alarm reliability behavior.

---

## Entitlement must not create separate engines

Subh has one morning-resolution engine.

Entitlement affects:

```text
visible paid surfaces
visible paid controls
long-term logging availability
history availability
progress/analytics availability
backup/export availability
advanced accountability availability
adaptive wake support if later scoped as paid
advanced wake-check personalization if later scoped as paid
paywall routing
read/write access to paid-only data
```

Entitlement must **not** affect:

```text
Fajr calculation correctness
location correctness
prayer calculation method correctness
reliability warnings
permission warnings
Quiet semantics
Suhoor semantics
wake adjustment semantics
Wake Session creation and core Wake Checks
immediate awake confirmation and current-morning check-ins
core wake-check cancellation after confirmation
core ramped sound asset access
underlying stored user meaning
base data preservation
resolved day meaning
opportunity detection
core wake plan scheduling
```

The resolver may know that a date has a Ramadan, Sunnah, Qada, or fasting opportunity even when the current tier cannot expose advanced paid history, summaries, or ledgers.

---

## Tier feature definitions

### Free

#### Promise

```text
Plan and wake for your Fajr-centered morning.
```

#### Included

Free includes the full core morning utility:

- first launch and onboarding access;
- automatic or manual location setup;
- prayer calculation method setup;
- alarm / notification permission setup;
- reliability and missing-permission warnings;
- the main Morning Hero for the next relevant morning;
- Fajr begin/end context where the hero exposes it;
- Fajr mode;
- Suhoor mode;
- Quiet mode;
- wake-time adjustment;
- custom wake delta where supported by the wake planning specs;
- adjustment within the valid Fajr or Suhoor wake window;
- Next 7 Mornings forecast display;
- Next 7 Mornings editing for supported wake-plan controls;
- Quiet for any editable morning in the supported planning horizon;
- Weekly Fajrcast display;
- Fajr-only Day Detail controls where implemented;
- Suhoor Day Detail controls where implemented;
- fasting intention / purpose selection where needed to create a clear wake plan;
- Ramadan Suhoor planning where implemented;
- Qada / voluntary / Sunnah fasting wake planning where implemented;
- month browsing and planning where implemented;
- broader supported wake-planning horizon where implemented;
- basic alarm delivery for resolver-supported wake plans, when permissions allow;
- Wake Sessions for the active/current morning;
- core Wake Checks for resolver-supported Fajr and Suhoor wake plans;
- in-app awake confirmation for Fajr and Suhoor;
- current-morning Fajr prayer check-in when implemented in the active morning loop;
- current-day fasting-intent check-in when implemented in the active morning loop;
- basic current-day or recent check-in display if implemented;
- no ads.

#### Free behavior principle

Free should feel generous and complete for the core job:

```text
I can use Subh to plan and wake for Fajr or Suhoor without paying.
```

Free should not feel like:

```text
I have to pay to make the alarm useful.
```

#### Free limits

Free may limit or lock:

- long-term Fajr prayer logging history;
- long-term fast logging history;
- detailed Ramadan history;
- Qada fast ledgers;
- Qada Fajr ledgers, if retained;
- fast tabs and custom categories;
- streaks;
- trends;
- summaries;
- advanced progress/history analytics;
- export;
- cloud backup/sync, if implemented as a paid value layer;
- advanced accountability;
- future household/family coordination;
- AI or insight features if added later.

#### Basic check-in and immediate MorningLog rule

If the app includes lightweight completion or check-in interactions in Free, they must be positioned as immediate current-morning touchpoints, not as the full paid logging/history system.

Recommended distinction:

| Capability | Free | Plus |
| --- | --- | --- |
| Wake Session operational record | Yes | Yes |
| Primary alarm / wake-check event record | Yes | Yes |
| `I’m awake for Fajr` / `I’m awake for Suhoor` | Yes | Yes |
| Cancel remaining wake checks after awake confirmation | Yes | Yes |
| `I prayed Fajr` for the active/current morning | Yes, basic check-in if implemented | Yes |
| `I’m fasting today` / fasting intent for the active/current morning | Yes, basic check-in if implemented | Yes |
| See current or very recent status | Limited/basic | Full where supported |
| Maintain and browse durable history | Limited/locked | Full |
| Edit historical logs | Limited/locked | Full where supported |
| Qada ledgers | No or read-only if prior data exists | Full where supported |
| Generate summaries/trends/streaks | Locked/preview | Full where supported |

This allows the user to complete the morning loop without paying while preserving Plus as the durable practice-memory layer.

Free may store the operational and immediate check-in records needed to make the wake system work. The entitlement limit applies to historical surfacing, historical editing, analytics, export, ledgers, and advanced accountability, not to the existence of the current-morning record.

---

### Plus

#### Promise

```text
Remember, review, and improve your Fajr, fasting, and morning practice over time.
```

#### Included

Plus includes everything in Free, plus the durable practice layer:

- full Fajr prayer logging history;
- full fast logging history;
- historical review of awake confirmations and Wake Session outcomes;
- historical review of current-morning check-ins recorded while on Free;
- Ramadan fast tracking history;
- Ramadan summaries;
- Qada fast ledger and tracking;
- Qada Fajr ledger and tracking, if retained as a product feature;
- fast tabs / fast categories where implemented;
- historical editing where supported by the logging specs;
- monthly summaries;
- Ramadan summaries;
- streaks;
- consistency trends;
- progress/history analytics;
- personal notes/reflections, if implemented;
- advanced insights, if implemented;
- backup/sync/export, if implemented as a paid feature;
- advanced reminders based on history, if implemented;
- advanced accountability features that are individual-only;
- selected Ramadan promotional and retention surfaces.

#### MVP Plus durable logging scope

Plus MVP should support or prepare the data model for:

| Area | Minimum Plus expectation |
| --- | --- |
| Fajr log | User can view, edit, and review full Fajr prayer history. Active/current-morning `I prayed Fajr` check-in may exist in Free. |
| Fajr qada | User can record Qada Fajr owed/completed if the product keeps this feature. Copy must avoid giving legal/religious rulings. |
| Fast log | User can view, edit, and review full fast history, including completion states when implemented. Active/current-day fasting intent may exist in Free. |
| Ramadan fast tracking | Ramadan days can be tracked distinctly from voluntary/Qada fasts. |
| Qada fast | User can track owed/planned/completed Qada fasts. |
| Fast tabs | User can group/filter fasts by meaningful categories, such as Ramadan, Qada, voluntary, Sunnah, or custom tabs if implemented. |
| Progress/history | User can review meaningful progress without guilt-based design. |
| Summaries | User can review weekly, monthly, or Ramadan summaries where implemented. |

#### Plus behavior principle

Plus should feel like:

```text
Subh is helping me preserve and understand my practice over time.
```

It should not feel like:

```text
I paid to make the alarm work.
```

---

## Future family / household accountability

Family / household accountability is a promising future monetization direction, but it is not part of MVP pricing.

Potential future features include:

- household wake coordination;
- spouse/family Suhoor planning;
- parent-child Fajr support;
- shared fasting intentions;
- “who woke who” accountability;
- household Ramadan planning;
- gentle family nudges;
- family-level summaries.

Rules:

1. Family must not be introduced as an MVP tier in this spec.
2. Family must not be implemented through ad hoc feature flags inside the current Plus model.
3. Family requires a dedicated product, privacy, consent, notification, and household-accountability spec before implementation.
4. Family may eventually justify a separate plan or add-on, but that decision is explicitly deferred.

---

## Entitlement access matrix

| Capability | Free | Plus |
| --- | ---: | ---: |
| Onboarding/setup | Yes | Yes |
| Location/manual city | Yes | Yes |
| Prayer calculation method | Yes | Yes |
| Reliability warnings | Yes | Yes |
| Morning Hero | Yes | Yes |
| Tomorrow Fajr wake display | Yes | Yes |
| Fixed/default Fajr wake | Yes | Yes |
| Wake-time adjustment | Yes | Yes |
| Custom wake delta | Yes | Yes |
| Quiet tomorrow | Yes | Yes |
| Quiet any editable morning | Yes | Yes |
| Next 7 Mornings forecast display | Yes | Yes |
| Next 7 Mornings editing | Yes | Yes |
| Weekly Fajrcast | Yes | Yes |
| Fajr Day Detail wake planning | Yes | Yes |
| Suhoor mode | Yes | Yes |
| Suhoor wake planning | Yes | Yes |
| Fasting-purpose selection for wake planning | Yes | Yes |
| Ramadan Suhoor planning | Yes | Yes |
| Qada/voluntary fasting wake planning | Yes | Yes |
| Month browsing/planning once implemented | Yes | Yes |
| Full supported wake-planning range once implemented | Yes | Yes |
| Adjusted Days repository for wake-plan review once implemented | Yes, if core wake planning requires it | Yes |
| Recurring boundary rules / presets once implemented | Yes, if treated as core wake planning | Yes |
| Wake Session execution | Yes | Yes |
| Core Wake Checks | Yes | Yes |
| Awake confirmation | Yes | Yes |
| Basic current-day check-in | Yes, if implemented | Yes |
| Current Fajr prayer check-in | Yes, if implemented in the active morning loop | Yes |
| Current fasting-intent check-in | Yes, if implemented in the active morning loop | Yes |
| Recent/basic status display | Limited | Yes |
| Full Fajr logging history | Limited/locked | Yes |
| Fajr Qada tracking | No or read-only if prior data exists | Yes |
| Full fast logging history | Limited/locked | Yes |
| Ramadan fasting history | Limited/read-only summary | Yes |
| Qada fast tracking | No or read-only if prior data exists | Yes |
| Fast tabs/categories | No or read-only if prior data exists | Yes |
| Progress/history analytics | Locked/preview | Yes |
| Streaks/trends/summaries | Locked/preview | Yes |
| Reflection notes | Locked/preview | Yes |
| Backup/sync/export if paid | Locked | Yes |
| Individual advanced accountability | Locked | Yes |
| Household/family accountability | Future, not MVP | Future, not MVP |

---

## Trial strategy

### Trial decision

No fixed trial length is locked in this spec.

The product may later choose:

- no trial;
- Plus free trial;
- introductory offer;
- launch/founder discount;
- Ramadan-specific promotional access;
- limited-time full Plus access during beta.

### Trial entitlement

If a Plus trial is implemented, the entitlement should be:

```text
subh.trial_plus
```

`subh.trial_plus` behaves like Plus for feature access while active.

### Trial eligibility

Product-level eligibility should be defined in the StoreKit / Subscription Implementation Plan.

Potential eligibility approaches include:

- one trial per Apple ID;
- one trial per app account;
- one trial per local install, only for internal testing;
- offer-code-based access.

The product should not promise unlimited repeat trials on reinstall.

### Trial start options

Possible behavior:

1. User completes onboarding enough for Subh to resolve a real morning.
2. The app offers Plus when the user reaches a meaningful paid surface.
3. If eligible, the paywall may include a Plus trial option.
4. The user may start the trial or continue using Free.

Recommendation:

```text
Do not force a trial at first launch.
Let the user experience the core morning utility first, then introduce Plus when history, logs, summaries, or accountability become relevant.
```

### Trial expiry

When a Plus trial expires and no paid entitlement exists:

1. Effective entitlement becomes Free.
2. All Plus-created data remains stored.
3. Plus-only controls become locked.
4. Plus-only reminders, analytics, exports, and history actions become locked or read-only.
5. Core wake planning remains active because it is Free.
6. Scheduling refresh must run only for Plus-only scheduled reminders or notifications.
7. The user is shown a calm expiry message and can continue on Free or upgrade to Plus.

### No data hostage principle

Trial data must not be deleted when the trial ends.

Users should not feel punished for trying the product.

---

## Ramadan promotional access

Ramadan promotional access should be modeled as a temporary entitlement rather than as a permanent tier.

Draft entitlement:

```text
subh.ramadan_promo
```

### Purpose

Ramadan Promo lets Subh be generous during Ramadan while preserving the long-term value of Plus.

Because core Suhoor, Ramadan wake planning, Wake Sessions, Wake Checks, and immediate active-morning check-ins are Free, Ramadan Promo should not be used to unlock basic Suhoor wake functionality or the current morning loop. It should only affect explicitly scoped paid-layer features.

### Possible Ramadan Promo scope

Ramadan Promo may include:

- temporary access to Ramadan fasting logs;
- temporary access to Ramadan daily progress;
- temporary access to Ramadan summaries;
- temporary access to Ramadan reflection prompts;
- temporary access to selected Plus features during Ramadan;
- post-Ramadan retention flow.

Ramadan Promo should not automatically include:

- all Plus historical analytics outside Ramadan;
- non-Ramadan Qada ledger editing;
- all advanced progress tools;
- all future accountability features;
- future family/household features.

### Ramadan Promo expiry

After Ramadan Promo expires:

1. Ramadan logs remain stored.
2. The user may retain read-only access to a basic Ramadan summary.
3. Continuing full history, detailed analytics, Qada ledgers, and editing should require Plus if they are paid-layer features.
4. The app may show a post-Ramadan retention message:

```text
Your Ramadan record stays saved. Upgrade when you want full history, summaries, and Qada tracking.
```

---

## Paywall entry points

Paywalls should be calm, contextual, and non-guilt-based.

### Allowed paywall triggers

| Trigger | Paywall type |
| --- | --- |
| User opens full Fajr logging history from Free | Plus-focused paywall. |
| User opens full fast logging history from Free | Plus-focused paywall. |
| User opens Qada fast ledger | Plus-focused paywall. |
| User opens Qada Fajr ledger, if retained | Plus-focused paywall. |
| User opens progress/history analytics | Plus-focused paywall. |
| User opens streaks/trends/summaries | Plus-focused paywall. |
| User opens Ramadan summary beyond Free preview | Plus-focused paywall. |
| User opens export/backup/sync if paid | Plus-focused paywall. |
| User opens advanced accountability | Plus-focused paywall. |
| Plus trial expires | Plus renewal/upgrade paywall with Free fallback. |
| User opens Settings > Subscription | Neutral plan-management screen. |
| Ramadan promotional period | Ramadan-specific Plus or Ramadan Promo paywall. |

### Forbidden paywall triggers

Do not show a paywall merely because the user:

- needs reliability warnings;
- needs location setup;
- needs prayer calculation setup;
- wants to use the Morning Hero;
- wants to use Fajr mode;
- wants to use Suhoor mode;
- wants to use Quiet mode;
- wants to adjust the wake time;
- wants to plan the Next 7 Mornings;
- wants to open Weekly Fajrcast;
- wants to plan Ramadan Suhoor;
- wants to use Wake Checks;
- wants to confirm awake for Fajr or Suhoor;
- wants to cancel remaining wake checks by confirming awake;
- wants to mark the active morning as Quiet;
- wants to use an active/current-morning `I prayed Fajr` check-in when that CTA is shown;
- wants to use an active/current-day `I’m fasting today` check-in when that CTA is shown;
- wants to set a wake plan for an upcoming morning;
- needs basic alarm delivery;
- needs permission warnings;
- needs to understand Fajr begin/end.

### Forbidden paywall behavior

Do not:

- hide reliability warnings behind a paywall;
- hide location setup behind a paywall;
- hide prayer calculation setup behind a paywall;
- use guilt language around missed prayers or fasting;
- imply that paying makes the user's worship better;
- create a confusing third permanent tier;
- delete data as a pressure tactic;
- schedule paid-only reminders after entitlement expiry without clear active entitlement;
- block core wake alarms because a paid entitlement expired.

---

## Paywall copy framework

### Tier card copy

#### Free

```text
Subh Free
Plan and wake for your Fajr-centered morning.

Includes:
- Fajr, Suhoor, and Quiet modes
- Wake-time adjustment
- Next 7 mornings
- Weekly Fajrcast
- Location and prayer-time setup
```

#### Plus

```text
Subh Plus
Remember, review, and improve your mornings over time.

Includes:
- Fajr and fast logging history
- Ramadan summaries
- Qada tracking
- Streaks, trends, and progress
- Reflection notes
- Backup, sync, or export where available
```

### Price copy rule

Until price is finalized, do not hardcode price copy in the spec or implementation.

Allowed placeholder copy:

```text
Price shown in App Store checkout.
```

Allowed developer placeholder copy in non-production builds:

```text
Plus price not finalized.
```

Production paywalls must use App Store product metadata once products exist.

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
Your records stay saved.
Upgrade when you want full history, summaries, and Qada tracking.
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
| Location settings | All users | Yes | Yes | Required for correctness. |
| Prayer method settings | All users | Yes | Yes | Required for correctness. |
| Wake plan settings | All users | Yes | Yes | Core Free utility. |
| Fajr wake adjustments | All users | Yes | Yes | Core Free utility. |
| Suhoor plans | All users | Yes | Yes | Core Free utility. |
| Quiet plans | All users | Yes | Yes | Core Free utility. |
| Fasting-purpose selection for wake planning | All users | Yes | Yes | Core Free utility if implemented. |
| Wake Session operational records | System / all users | Yes per retention policy | Current/recent operational use; historical surfacing may be limited in Free | Required for wake checks, cancellation, reconciliation, and trust. |
| Awake confirmations | All users | Yes | Current/recent operational use; historical surfacing may be limited in Free | `I’m awake` is not the same as prayer completion. |
| Basic current-day check-in | Free+ | Yes | Yes, if Free supports it | Keep distinction from full logs. |
| Current Fajr prayer check-in | Free+ | Yes | Current/recent basic status in Free; full history/editing in Plus | `I prayed Fajr` for the active morning should not be paywalled when shown. |
| Current fasting-intent check-in | Free+ | Yes | Current/recent basic status in Free; full history/editing in Plus | Suhoor may auto-confirm fasting intent; fast completion remains separate. |
| Fajr logs | Plus/trial/promo where scoped | Yes | Read-only/limited in Free; editable in Plus | Avoid data hostage. |
| Fast logs | Plus/trial/promo where scoped | Yes | Read-only/limited in Free; editable in Plus | Avoid data hostage. |
| Ramadan logs | Plus/trial/Ramadan Promo where scoped | Yes | Basic read-only summary in Free; editable in Plus | Preserve after expiry. |
| Qada fast ledger | Plus/trial | Yes | Read-only summary in Free; editable in Plus | Preserve owed/completed state. |
| Qada Fajr tracking | Plus/trial | Yes | Read-only summary in Free; editable in Plus | If retained. |
| Fast tabs/categories | Plus/trial | Yes | Read-only in Free; editable in Plus | Preserve custom organization. |
| Progress/history analytics | Derived from user data | Regenerable | Plus active; Free locked/preview | Derived analytics may regenerate. |
| Backup/export records | Plus/system | Per privacy policy | Plus | External storage rules may apply. |
| Delivery ledger | System | Yes per retention policy | Internal | Privacy-preserving diagnostics. |
| Purchase/entitlement cache | System | Yes | Depends on verification | Must not be the source of truth for religious data. |

---

## Downgrade behavior

A downgrade occurs when the effective entitlement decreases, such as:

```text
Plus -> Free
Trial Plus -> Free
Ramadan Promo -> Free
```

### Required downgrade behavior

When entitlement decreases:

1. Preserve all data.
2. Recompute effective entitlement.
3. Re-resolve visible mornings.
4. Preserve all core wake planning because it remains Free.
5. Lock unsupported paid-layer controls.
6. Convert unsupported paid-layer data to read-only or preview access where appropriate.
7. Cancel or suppress paid-only scheduled reminders that are no longer entitlement-supported.
8. Keep core wake alarms active.
9. Show a calm explanation of what changed.

### Plus to Free

When the user moves from Plus to Free:

- Fajr/Suhoor/Quiet planning remains available.
- Wake adjustment remains available.
- Next 7 Mornings remains available.
- Weekly Fajrcast remains available.
- Month or broader wake planning remains available if implemented as core wake planning.
- Plus logs remain stored.
- Plus ledgers remain stored.
- Plus summaries remain stored or regenerable.
- New historical log creation and historical editing are locked unless a Free-lite behavior is explicitly allowed.
- Active/current-morning check-ins remain available where the Free morning loop exposes them.
- Qada ledgers are locked/read-only.
- Progress/history analytics are locked/preview.
- Export/backup/sync paid surfaces are locked.
- Core alarm scheduling continues normally.

### Trial Plus to Free

When a Plus trial expires:

- Trial-created Plus data remains stored.
- Core wake planning remains active.
- Plus-only data becomes read-only/limited.
- Plus-only reminders are cancelled or suppressed.
- Core wake alarms remain active.
- A calm expiry message explains that Free remains usable.

### Ramadan Promo to Free

When Ramadan promotional access expires:

- Core Fajr/Suhoor/Quiet wake planning remains active.
- Ramadan logs remain stored.
- A basic Ramadan summary may remain read-only.
- Detailed history, Qada ledgers, advanced summaries, and editing require Plus if they are scoped as Plus features.
- Promo-only reminders are cancelled or suppressed.

---

## Upgrade behavior

An upgrade occurs when the effective entitlement increases, such as:

```text
Free -> Plus
Free -> Trial Plus
Ramadan Promo -> Plus
Trial Plus -> Plus
```

### Required upgrade behavior

When entitlement increases:

1. Recompute effective entitlement.
2. Unlock newly supported Plus surfaces and controls.
3. Rehydrate preserved Plus data relevant to the new entitlement.
4. Re-resolve affected history, summaries, and paid-layer views.
5. Refresh Plus-only reminders or notifications inside the active scheduled horizon if implemented.
6. Avoid duplicating old log records, override records, or scheduled events.
7. Explain restored features only when useful.

### Free to Plus

Unlock:

- full Fajr logging history;
- full fast logging history;
- Ramadan tracking history;
- Qada fast ledger;
- Qada Fajr ledger, if retained;
- fast tabs/categories;
- progress/history analytics;
- streaks/trends/summaries;
- reflection notes, if implemented;
- backup/sync/export, if implemented;
- advanced individual accountability, if implemented.

Do not unlock:

- family/household accountability unless separately implemented and entitled;
- future mosque/community integrations unless separately implemented and entitled;
- AI or external-provider features unless explicitly included.

---

## Conflict handling after downgrade and later edits

A conflict can occur when a user has preserved Plus data but edits the same period while on Free.

Example:

```text
User logs Ramadan fasts while on Plus.
User downgrades to Free.
The detailed Ramadan log history becomes locked/read-only.
User later records basic Free check-ins for overlapping mornings.
User later re-upgrades to Plus.
```

### Required conflict rule

The app must not silently overwrite preserved higher-detail user meaning.

Allowed approaches:

1. **Merge when safe:** Free check-ins can enrich or coexist with preserved Plus logs when the fields do not conflict.
2. **Archive-and-replace:** lower-detail Free record becomes the active lower-detail record, while the old Plus record remains archived and can be restored after re-upgrade.
3. **Prompt-before-replace:** when the user edits a period with locked higher-detail data, show a message explaining that the Free edit will update the visible record while the previous Plus detail remains preserved.
4. **Restore-choice on re-upgrade:** when the user re-upgrades, if both Free and Plus data exist for the same morning, ask whether to keep the current record or restore the previous detailed record.

MVP recommendation:

```text
Use merge-when-safe for non-conflicting check-in fields.
Use archive-and-replace for conflicting fields.
Defer restore-choice UI until needed.
```

---

## Scheduling after entitlement changes

Entitlement changes must trigger schedule refresh, but core wake alarms remain Free.

### Required behavior

When entitlement changes:

1. Active scheduled window is rebuilt or verified.
2. Core Fajr, Suhoor, and Quiet wake plans remain schedule-eligible.
3. Paid-only reminders outside the user's current entitlement are not schedule-eligible.
4. Stale paid-only platform deliveries are cancelled if they are no longer allowed.
5. Lower-tier events that remain valid are scheduled or verified normally.
6. Quiet remains intentional suppression, not a payment failure.
7. Delivery failure must not become entitlement failure.
8. Entitlement failure must not become Quiet.

### Event examples

| Event / plan | Required entitlement |
| --- | --- |
| Default Fajr wake | Free+ |
| Adjusted Fajr wake | Free+ |
| Suhoor wake | Free+ |
| Ramadan Suhoor wake | Free+ |
| Qada/voluntary fasting wake plan | Free+, if feature is implemented as wake planning |
| Quiet suppression | Free+ |
| Wake Session primary alarm | Free+ |
| Wake Check alarms | Free+ |
| Active-morning awake confirmation flow | Free+ |
| Active/current-morning check-in CTA | Free+, if implemented in the morning loop |
| Basic reminder to review tomorrow's plan | Free+, if implemented |
| Logging reminder outside the active morning loop | Plus / Plus Trial / scoped Ramadan Promo |
| Qada ledger reminder | Plus / Plus Trial |
| Reflection prompt | Plus / Plus Trial / scoped Ramadan Promo |
| Progress summary notification | Plus / Plus Trial / scoped Ramadan Promo |
| Backup/export reminder | Plus / Plus Trial |

---

## Locked feature behavior

A locked feature may be:

1. hidden;
2. visible but disabled;
3. visible as a locked preview;
4. visible read-only;
5. available through trial/promo.

### Preferred locking rules

| Feature | Free lock behavior |
| --- | --- |
| Full Fajr log history | Locked preview or read-only limited view. |
| Full fast log history | Locked preview or read-only limited view. |
| Ramadan record | Basic read-only summary if data exists; detailed analytics Plus-only. |
| Qada ledger | Read-only locked summary if data exists; otherwise Plus prompt. |
| Fast tabs | Show tab names/counts read-only if data exists; editing Plus-only. |
| Progress/history | Preview/summary; detailed analytics Plus-only. |
| Streaks/trends/summaries | Locked preview. |
| Reflection notes | Locked preview or hidden until implemented. |
| Backup/sync/export | Plus prompt. |
| Advanced accountability | Plus prompt. |
| Household/family surfaces | Hidden unless future family spec exists. |

### Features that should not be locked

| Feature | Rule |
| --- | --- |
| Fajr mode | Free. |
| Suhoor mode | Free. |
| Quiet mode | Free. |
| Wake-time adjustment | Free. |
| Next 7 Mornings | Free. |
| Weekly Fajrcast | Free. |
| Prayer calculation setup | Free. |
| Location setup | Free. |
| Reliability warnings | Free. |
| Core alarm delivery | Free. |
| Wake Sessions | Free. |
| Core Wake Checks | Free. |
| Awake confirmation | Free. |
| Active/current-morning prayer or fasting-intent check-ins | Free when exposed in the morning loop. |

---

## Read-only access after downgrade

To avoid data hostage behavior, previously created logs and ledgers should not disappear completely after downgrade.

Recommended Free behavior for previously created Plus data:

| Data | Free after downgrade |
| --- | --- |
| Fajr logs | Show read-only summary or locked list preview. Editing/new historical logs require Plus. |
| Fast logs | Show read-only summary or locked list preview. Editing/new historical logs require Plus. |
| Ramadan record | Show basic read-only Ramadan summary. Detailed analytics require Plus. |
| Qada fast ledger | Show remaining count/read-only summary if available. Editing requires Plus. |
| Qada Fajr ledger | Show remaining count/read-only summary if available. Editing requires Plus. |
| Fast tabs | Show tab names/counts read-only if data exists. Editing requires Plus. |
| Progress/history | Show limited preview. Detailed analytics require Plus. |

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
- Free Fajr wake planning;
- Free Suhoor wake planning;
- Free Quiet mode;
- Free wake adjustment;
- Free Next 7 Mornings;
- Free Weekly Fajrcast;
- Free supported wake-planning horizon;
- Free Wake Sessions;
- Free core Wake Checks;
- Free active-morning awake confirmation;
- Free active/current-morning prayer and fasting-intent check-ins where implemented;
- Plus full Fajr logging history;
- Plus full fast logging history;
- Plus Ramadan tracking/history;
- Plus Qada fast tracking;
- Plus Qada Fajr tracking if retained;
- Plus fast tabs/categories;
- Plus progress/history;
- Plus summaries/trends/streaks;
- Plus trial if implemented;
- Ramadan promotional access if implemented;
- downgrade preservation;
- paywall routing.

### Deferred / future features

The pricing spec may mention but must not promise these until separate specs exist:

- family/shared plans;
- household wake accountability;
- parent-child Fajr support;
- masjid connection;
- mosque timetable integration;
- masjid-aligned wake modes;
- prayer in masjid tracking;
- AI insights;
- cloud sync if external/service-heavy;
- Apple Watch;
- separate Ramadan app/pass;
- paid external provider sources.

---

## Forecast horizon note: Next 7 Mornings

The near-term forecast horizon is locked as a seven-day surface:

```text
Visible forecast surface: Next 7 Mornings.
Target near-term horizon: the next immediate alarm / next relevant morning plus the following six mornings.
Weekly Fajrcast alignment: same seven visible dates, in the same order.
```

Pricing implication:

- Next 7 Mornings is Free.
- Weekly Fajrcast is Free.
- Entitlement must not reintroduce a ten-day forecast entitlement.
- Entitlement must not treat Weekly Fajrcast as a different date horizon from Next 7 Mornings.
- Plus may enrich the horizon with history, completion status, trends, or summaries where those are paid-layer features.

Implementation implication:

- Entitlement must not gate access to the weekly forecast/edit horizon.
- Entitlement must not change Fajr calculation correctness or create separate Free/Plus forecast engines.
- Delivery still schedules only the active scheduled horizon, not every visible Next 7 Mornings row.

---

## Paywall transition matrix

| From | To | User action / event | Data behavior | Schedule behavior |
| --- | --- | --- | --- | --- |
| Free | Plus | Purchase Plus | Existing Free data preserved; Plus features unlock. | Core wake scheduling unchanged; Plus reminders eligible if implemented. |
| Free | Trial Plus | Start Plus trial | Existing data preserved; trial Plus features unlock. | Core wake scheduling unchanged; Plus reminders eligible while trial active. |
| Trial Plus | Plus | Purchase Plus | Trial data becomes paid Plus data. | Continue eligible Plus reminders; avoid duplicate events. |
| Trial Plus | Free | Trial expires | Trial data preserved but locked/read-only/limited. | Plus-only reminders cancelled; core wake alarms remain. |
| Plus | Free | Cancel/expire/downgrade | Plus data preserved, locked/read-only/limited. | Plus-only reminders cancelled; core wake alarms remain. |
| Ramadan Promo | Plus | Upgrade | Ramadan data remains; full Plus features unlock. | Plus reminders eligible. |
| Ramadan Promo | Free | Promo expires | Ramadan data preserved read-only/basic; non-entitled controls locked. | Promo-only reminders cancelled; core wake alarms remain. |

---

## Entitlement state model — conceptual

Recommended conceptual model:

```swift
enum SubhEntitlementLevel: String, Codable, Comparable {
    case free
    case plus
}

struct SubhEntitlementState: Codable, Equatable {
    let effectiveLevel: SubhEntitlementLevel
    let activeProducts: [String]
    let isTrialActive: Bool
    let trialEndsAt: Date?
    let isRamadanPromoActive: Bool
    let ramadanPromoEndsAt: Date?
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
    // Core morning utility — Free
    case heroView
    case fixedFajrWake
    case fajrWakeAdjustment
    case suhoorMode
    case quietMode
    case quietTomorrow
    case wakeSessionExecution
    case coreWakeChecks
    case awakeConfirmation
    case currentMorningCheckIn
    case weeklyForecastView
    case weeklyWakeEditing
    case weeklyQuietEditing
    case weeklyFajrcast
    case monthWakePlanning
    case fastingPurposeForWakePlanning

    // Plus memory and insight layer
    case fajrLoggingHistory
    case fajrQadaTracking
    case fastLoggingHistory
    case ramadanFastTrackingHistory
    case qadaFastTracking
    case fastTabs
    case progressHistory
    case streaksTrendsSummaries
    case reflectionNotes
    case backupSyncExport
    case advancedAccountability

    // Future, not MVP
    case familyHouseholdAccountability
}
```

Feature gates should be resolved centrally, not separately in every view.

---

## Acceptance criteria

### Pricing acceptance

- [ ] Free is the full core morning utility.
- [ ] There is only one active paid tier.
- [ ] The active paid tier is named Plus unless Product later renames it.
- [ ] No Complete tier exists in MVP pricing.
- [ ] No Complete-family lifetime tier exists in MVP pricing.
- [ ] No final Plus price is hardcoded in this spec.
- [ ] No final Plus price is hardcoded in production UI.
- [ ] Any future price display comes from StoreKit product metadata.
- [ ] Trial, promotional, or founder offers do not create separate feature tiers.
- [ ] Family/household accountability is future scope, not MVP pricing.

### Entitlement acceptance

- [ ] One normalized entitlement state is available to all feature gates.
- [ ] Free can use core setup, hero, Fajr mode, Suhoor mode, Quiet mode, wake adjustment, and supported planning horizons.
- [ ] Free can use Wake Sessions, core Wake Checks, awake confirmation, and active/current-morning check-ins where implemented.
- [ ] Free can use Next 7 Mornings and Weekly Fajrcast.
- [ ] Plus can use durable logging, history, analytics, Qada tracking, summaries, and paid accountability features.
- [ ] Lower tiers cannot commit unsupported paid-layer mutations.
- [ ] Entitlement does not affect Fajr calculation correctness or reliability warnings.
- [ ] Entitlement does not affect core wake plan scheduling.
- [ ] Entitlement changes trigger re-resolution and schedule refresh for paid-only reminders where applicable.

### Data preservation acceptance

- [ ] Downgrade does not delete paid-tier data.
- [ ] Paid-tier logs and ledgers become locked/read-only/limited when unsupported by current entitlement.
- [ ] Paid-tier reminders are cancelled/suppressed after entitlement expiry.
- [ ] Core wake alarms remain active after entitlement expiry.
- [ ] Logs and ledgers are preserved after downgrade.
- [ ] Previously created data rehydrates when the user re-upgrades.
- [ ] Explicit deletion remains available where feature specs support it.

### Trial / promo acceptance

- [ ] Plus trial is optional and not price-locked.
- [ ] Plus trial access behaves like Plus while active.
- [ ] Trial data is preserved after expiry.
- [ ] Trial expiry falls back to Free unless a paid entitlement exists.
- [ ] Trial expiry cancels/suppresses unsupported Plus-only reminders.
- [ ] Ramadan Promo, if implemented, is temporary and scoped.
- [ ] Ramadan Promo does not become a permanent third tier.

### Paywall acceptance

- [ ] Paywalls are contextual and non-guilt-based.
- [ ] Tapping history, analytics, Qada ledgers, summaries, export, or paid accountability from Free opens a Plus-focused paywall.
- [ ] Tapping Fajr, Suhoor, Quiet, wake adjustment, Wake Checks, awake confirmation, active/current-morning check-in, Next 7 Mornings, or Weekly Fajrcast does not open a paywall.
- [ ] Trial expiry opens a Plus renewal/upgrade paywall with Free fallback.
- [ ] Existing user data is never threatened in paywall copy.

---

## Migration notes from v2 to v3

### Remove from active pricing model

Remove or deprecate active references to:

```text
Complete
Complete Subscription
Complete Trial
Complete-family lifetime
Complete monthly
Complete annual
Complete Founder Annual
Complete Founder Lifetime
subh.complete
subh.complete_lifetime
subh.trial_complete
com.subh.complete.monthly
com.subh.complete.annual
com.subh.complete.annual.founder
com.subh.complete.lifetime
com.subh.complete.lifetime.founder
```

### Move formerly paid control features to Free

The following v2 paid/control features should become Free core utility:

- user-adjustable wake delta;
- wake-time drag/adjustment;
- expanded weekly planning controls;
- future-day editing within supported planning horizons;
- Suhoor mode;
- before-Fajr Suhoor wake planning;
- fasting-purpose selection where required for wake planning;
- Ramadan Suhoor planning;
- Qada/voluntary fasting wake planning where implemented as wake planning;
- Weekly Fajrcast;
- Next 7 Mornings forecast display and editing;
- month browsing/editing if implemented as wake planning;
- Wake Sessions;
- core Wake Checks;
- awake confirmation;
- active/current-morning prayer and fasting-intent check-ins where implemented.

### Move formerly Complete memory features to Plus

The following v2 Complete features should become Plus:

- Fajr prayer logging and tracking;
- Fajr Qada logging/tracking if retained;
- Ramadan fasting tracking;
- fast logs;
- Qada fast ledger and tracking;
- custom fast tabs / fast categories;
- progress/history views;
- streaks/trends/summaries;
- reflection notes;
- backup/sync/export if paid;
- advanced individual accountability.

### Replace paywall logic

Old model:

```text
Free -> Plus for Fajr control
Plus -> Complete for Suhoor/fasting/logging
Complete -> Lifetime for permanent access
```

New model:

```text
Free -> Plus for durable memory, history, insight, Qada tracking, export, and accountability
```

---

## Required follow-up specs

This pricing spec creates work, but it should not absorb all related work.

Required separate specs / updates:

1. `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`
   Already created as the canonical owner for Wake Sessions, Wake Checks, immediate MorningLogs, and the distinction between current-morning confirmation and durable history.

2. `subh-worship-logging-qada-tracking-spec-v1.md`
   Owns full Fajr logs, full fast logs, Ramadan tracking, Qada Fajr, Qada fast, fast tabs, history, progress, historical editing, and Free-vs-Plus historical access limits.

3. StoreKit / Subscription Implementation Plan
   Owns final Plus price, App Store product setup, sandbox tests, purchase restoration, receipt/transaction verification, trial/offer configuration, and exact product IDs.

4. Interaction Inventory update
   Removes Complete-tier scenario IDs, reclassifies core wake/planning interactions as Free, and adds Plus exposure for logging/history/accountability scenarios.

5. Planning Horizon update
   Removes tier-based gating from core wake-planning horizons and clarifies any remaining Free limits, if any.

6. Home Composition / Paywall Surface Spec
   Owns where locked previews, Plus cards, history prompts, and subscription entry points appear visually.

7. Ramadan / Fasting Logging update
   Clarifies how Free Suhoor planning differs from Plus Ramadan history, summaries, and Qada tracking.

8. Future Family / Household Accountability Spec
   Required before adding household plans, family invitations, shared wake confirmations, parent-child accountability, or household pricing.

9. `subh-testflight-beta-strategy-spec-v1.md`
   Owns TestFlight phases, cohorts, beta feedback, sandbox purchase testing, and App Store launch readiness.

---

## Open decisions

These are not blockers for this spec, but they should be resolved before implementation is considered complete.

| Decision | Current working stance |
| --- | --- |
| What should Plus cost? | Not finalized. Do not hardcode price. |
| Should Plus have monthly, annual, or both? | Likely both, but not locked. |
| Should there be a founder/launch discount? | Deferred to pricing decision / StoreKit plan. |
| Should there be a trial? | Likely useful, but duration and mechanism are deferred. |
| How much logging should Free allow? | Wake Session operational records, awake confirmations, active/current-morning `I prayed Fajr`, and active/current-day fasting-intent check-ins are Free when shown in the morning loop. Full durable history, historical editing, ledgers, analytics, export, and advanced accountability belong to Plus. Dedicated logging specs must define the exact recent-history/free-history limits. |
| Should Qada Fajr tracking remain in MVP? | Current user direction includes it as possible Plus scope; dedicated logging spec must define carefully. |
| Should backup/sync be Plus? | Recommended if it preserves durable history, but implementation cost/privacy constraints must be assessed. |
| Should recurring boundary rules be Free? | If they are core wake planning, yes. If they become advanced automation beyond wake planning, revisit. |
| Should month/year planning be Free? | Current stance: core wake planning should be Free. Exact horizon details belong to planning specs. |
| Should Ramadan Promo exist? | Deferred; entitlement model supports it if needed. |
| Should Lifetime ever return? | Deferred; not MVP. |
| Should Family become a separate future paid plan? | Possible, but requires dedicated future spec. |

---

## Codex implementation guardrails

When implementing this spec, Codex must not:

- implement TestFlight strategy in this pricing spec;
- create separate Free/Plus morning engines;
- create or preserve a Complete pricing tier;
- create or preserve a Complete-family lifetime tier;
- hardcode any Plus price;
- change Fajr calculation behavior because of entitlement;
- hide reliability warnings behind payment;
- hide location setup behind payment;
- hide prayer calculation setup behind payment;
- gate Fajr mode behind payment;
- gate Suhoor mode behind payment;
- gate Quiet mode behind payment;
- gate wake adjustment behind payment;
- gate Wake Sessions behind payment;
- gate core Wake Checks behind payment;
- gate awake confirmation behind payment;
- gate active/current-morning check-ins behind payment;
- gate Next 7 Mornings behind payment;
- gate Weekly Fajrcast behind payment;
- delete paid-tier data on downgrade;
- leave Plus-only reminders scheduled after entitlement expiry;
- cancel core wake alarms after entitlement expiry;
- expose Tahajjud-only or Other early worship as MVP paid features;
- rename Suhoor back to Pre-Fajr, Fast, or Early;
- convert opportunities into intentions merely because Plus is active;
- create logging/progress features without a dedicated logging/Qada spec;
- create family/household pricing without a dedicated family/household accountability spec.
