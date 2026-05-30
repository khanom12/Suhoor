# Subh Day Purpose, Observance Opportunity, Intention, Outcome, and Analytics Credit Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-day-purpose-opportunity-resolution-spec-v1.md` |
| Version | 1 |
| Spec status | Draft; canonical Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-mvp-interaction-inventory-v4.md` |
| Owning domain / surface | Day purpose, observance opportunity, intention, outcome, and credit resolution |
| Implementation audit status | Needs implementation audit |

## Purpose
Define how Subh separates date meaning, user intention, wake classification, required actions, outcomes, and future credit without turning opportunities into pressure.

## What This Spec Owns
- Observance opportunity and intention vocabulary.
- Resolver rules for Ramadan, Sunnah opportunities, qada, Suhoor fasting intention, Quiet, forbidden fast days, and credit.
- Analytics-credit guardrails without adding tracking implementation.

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


## May 29 Day Purpose / Alarm State Separation Addendum

This May 29 alignment is normative for MVP and supersedes conflicting lower/historical wording in this file.

- `Fajr` and `Suhoor` are the only exposed MVP wake purposes.
- `Quiet` is a one-morning alarm/sound override, not a wake purpose.
- `Pause` is an indefinite app-wide wake-alarm policy, not a wake purpose.
- User-facing MVP copy must not expose `Pre-Fajr`, `Early`, `Fast mode`, `Fasting mode`, `Quiet mode`, or `Pause mode` as visible wake purposes.
- Internal/code terms may remain where required for compatibility, but visible surfaces must use `Fajr`, `Suhoor`, `Quiet`, `Alarms paused`, `Time to wake`, `I’m awake`, `I’m fasting today`, and `I prayed Fajr` according to `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`.

Day purpose/opportunity resolution must not treat Quiet or Pause as day purpose.

- `Fajr` and `Suhoor` are wake purposes.
- Observance opportunities remain calendar/context meanings.
- Quiet is a date-level alarm override.
- Pause is a global wake-alarm policy.
- Permission/setup/delivery issues are reliability states.

Do not infer a missed prayer, failed fast, or absence of worship from Quiet/Pause.

For MVP, Suhoor is fasting-oriented. Generic non-fasting before-Fajr/Tahajjud-only wake purposes remain deferred unless a future spec reintroduces them.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- The only active before-Fajr user intention in MVP is Suhoor, which is a fasting/suhoor intention.
- `Tahajjud only`, `Other early worship`, and combined fasting-plus-Tahajjud planning are deferred and must not create MVP required actions, completion requirements, analytics credit, or selectable UI states.
- Legacy Tahajjud or other-early-worship records may be decoded for compatibility, but MVP resolution should normalize them away from active selectable user-facing behavior.
- Sunnah fasting opportunities remain opportunities, not intentions, until the user selects Suhoor or another durable fasting-intention source applies.
- When Suhoor is selected, fasting-purpose resolution defaults to applicable Sunnah opportunities when present; otherwise it defaults to `Voluntary fast`.
- Existing opportunity/intention/outcome/credit separation remains correct and should be preserved.

## 0. One-page summary

Subh should not treat each calendar date as one exclusive state. A date can be meaningful without becoming an active fast, wake plan, or completion requirement.

The canonical model is:

1. **Observance Opportunity / Day Meaning** — what the date objectively is.
2. **User Intention / Day Plan** — what the user chose to do with that date.
3. **Wake Plan** — what Subh schedules because of that intention.
4. **Outcome / Completion** — what the user actually logged or completed.
5. **Analytics Credit** — what the app is allowed to count in future reports.

The most important product rule is:

> **Meaning is not intention. Intention is not execution. Execution is not automatically credited to every meaning on the date.**

Example: a Monday is a Monday/Thursday Sunnah fast opportunity even if the user keeps the usual Fajr wake. That date should count as an **available opportunity**, but not as a **planned** or **missed** fast. If the user plans and completes a voluntary fast on that Monday, then it counts as available, planned, and completed. If the user completes qada on a White Day, the White Day opportunity still exists, but the completion should credit qada, not automatically credit the White Day voluntary observance.

---

## 1. Current repository context

The current codebase already contains much of the lower-level infrastructure. This spec should extend it rather than replace it.

### 1.1 Existing OpenSpec pattern

The repository uses OpenSpec-style changes under `openspec/changes/<change-name>/` with:

- `.openspec.yaml`
- `proposal.md`
- `design.md`
- `specs/<capability>/spec.md`
- `tasks.md`

Recent example: `openspec/changes/morning-hero-v4-location-order/`.

The archived specification style uses `SHALL` requirements with explicit `GIVEN / WHEN / THEN` scenarios. The canonical home capability currently exists at `openspec/specs/single-screen-morning-home/spec.md`.

### 1.2 Existing domain anchors

The implementation should be framed around the following current files and responsibilities:

| Current file | Current role | How this spec should use it |
|---|---|---|
| `Subh/Core/Scheduling/MorningResolver.swift` | Central morning resolution pipeline. Computes prayer window, selected plan, wake anchor/time, behavior profile, events, decision log, completion, and returns `ResolvedDaySnapshot`. | Add day-purpose/opportunity resolution near the existing context/plan/completion flow. Do not duplicate prayer-time or event materialization logic. |
| `Subh/Core/Morning/Models/ResolvedDaySnapshot.swift` | Current resolved day aggregate. | Extend with observance opportunities, resolved intention/purpose, wake classification, and analytics credits. |
| `Subh/Core/Morning/Models/MorningContextModels.swift` | Current `MorningContextType`, `DayTag`, `ResolvedDayContext`. | Keep as UI/context compatibility layer. Do not use `DayTag` alone as the analytics source of truth. |
| `Subh/Core/Morning/Context/MorningFastDomain.swift` | Current fast intent, virtue tags, warnings, strict/permissive normalization, Ramadan/forbidden-day derivation. | Reuse as the basis for `ObservanceOpportunity` derivation and fast-intention normalization. |
| `Subh/Core/Morning/Context/MorningTagComputationDomain.swift` | Computes primary fast intent, computed/suppressed secondary tags, and details. | Continue using for fast tag derivation, but add a higher-level resolver that distinguishes opportunity from intention. |
| `Subh/Core/Morning/Context/ResolvedDayContextResolver.swift` | Resolves primary/secondary context and supporting tags for presentation. | Feed it from the new resolved purpose layer, or keep it as compatibility output derived from the new layer. |
| `Subh/Core/Morning/Planning/MorningPlanResolver.swift` | Selects the effective morning plan using override/qada/observance/default precedence. | Extend with day intention/purpose inputs so opportunities alone do not force early wake. |
| `Subh/Core/Morning/Models/MorningPlanModels.swift` | Defines wake anchors, wake states, wake rules, plans, behavior profile. | Reuse `preFajr`, `inFajr`, `fixedWake`, etc. The new model should classify, not replace, wake rules. |
| `Subh/Core/Scheduling/ScheduledDateSourceModels.swift` | Defines date sources and provenances, including default Ramadan, manual days/ranges, quick adds, and recurring Islamic rules. | Use as source/provenance input for opportunities and user-intended plan series. |
| `Subh/Core/Morning/State/MorningStateSnapshot.swift` | Current aggregate state passed into morning resolution, including `fastTagSelections`, overrides, completions, qada ledger, location, and time zone. | Extend with unified intention selections later; for MVP, adapt existing `fastTagSelections` into fast intentions. |
| `Subh/Core/Morning/Models/CompletionModels.swift` | Defines completion records, fast states, qada ledger/effect, outstanding actions. | Add or derive observance credits from completion records and resolved intention. |
| `Subh/Core/Morning/Completion/DailyCompletionResolver.swift` | Resolves prayer/fast completion and qada effect from context + records. | Ensure fast completion is required only for intended or auto-obligatory fasts, not for mere opportunities. |

---

## 2. Problem statement

Today, several concepts risk being collapsed into one “state”:

- a date has a Sunnah fast meaning;
- the user chooses to fast on that date;
- the app wakes them earlier;
- the user completes the fast;
- the app credits that completion toward a specific observance.

These are related, but they are not the same.

The app needs to support future questions such as:

- How many Monday/Thursday opportunities existed this month/year?
- How many did the user plan?
- How many did the user complete?
- How many White Days were available?
- How many White Days were completed as voluntary fasts?
- How many qada fasts were completed?
- Did the user complete six Shawwal fasts?
- How many meaningful observance days did the user keep as default Fajr days?
- Did the user log a fast on a forbidden day, and how should that be represented?

These cannot be answered correctly if Subh only stores a single `dayState` or only uses visual tags.

---

## 3. Core vocabulary

### 3.1 Observance Opportunity / Day Meaning

An **Observance Opportunity** is what the date objectively or calendar-contextually means.

Examples:

- Ramadan day.
- Monday/Thursday recommended fast opportunity.
- White Day.
- Arafah.
- Ashura.
- Dhul Hijjah first nine.
- Shawwal Six potential day.
- Eid or Tashreeq forbidden fast day.
- Ordinary day.

An opportunity does **not** schedule an alarm by itself.

### 3.2 User Intention / Day Plan

A **User Intention** is what the user chooses to do with the date.

Examples:

- Keep usual/default Fajr wake.
- Plan a Ramadan fast.
- Plan a qada fast.
- Plan a voluntary fast because of Monday/Thursday.
- Plan a voluntary fast because of White Days.
- Plan Tahajjud wake only.
- Make the day quiet.

Intention is what should drive wake behavior and completion expectations.

### 3.3 Wake Plan

A **Wake Plan** is the schedule consequence of the intention.

Examples:

- Default in-Fajr wake.
- Early before-Fajr wake.
- Fixed-clock wake.
- Suppressed/disabled wake.

Existing `MorningWakeRuleState` and `ResolvedWakeState` should remain the low-level wake purposel. The new layer should expose user/product-facing wake classification.

### 3.4 Outcome / Completion

An **Outcome** is what the user actually did.

Examples:

- Fajr completed.
- Fajr missed.
- Fast completed.
- Fast not completed.
- Fast in progress.
- Tahajjud completed in future scope.
- No log.

Current `CompletionRecord`, `DailyCompletionSnapshot`, and `FastCompletionState` should remain the persistence/summary backbone.

### 3.5 Analytics Credit

An **Analytics Credit** is what reports are allowed to count.

Examples:

- Monday/Thursday opportunity available.
- Monday/Thursday fast planned.
- Monday/Thursday fast completed.
- White Day opportunity available.
- Qada fast completed.
- Ramadan fast completed.
- Fast attempted on forbidden day.

Credits must be explicit and derived from the resolved opportunity + intention + outcome combination.

---

## 4. Product principles

### Principle 1: Meaning does not imply pressure

A Sunnah opportunity should be visible, but not treated as a missed fast unless the user intended it.

### Principle 2: Optional observance opportunities are availability, not obligation

Monday/Thursday, White Days, Arafah, Ashura, Shawwal Six, and Dhul Hijjah opportunities can appear as “available” or “suggested” without becoming required actions.

### Principle 3: Ramadan is different

Ramadan is an auto-obligatory fasting context. Ramadan should generally resolve to a fasting intention by default, unless a quiet/suppression mode is active or future exception handling is introduced.

### Principle 4: Qada is a primary intention, not a secondary virtue credit

If a user performs qada on a White Day or Monday, the date’s Sunnah opportunity remains visible, but the completed fast credits qada unless the product later implements a consciously chosen coexistence policy. In strict mode, obligatory primary intents suppress secondary virtue credit.

### Principle 5: Quiet is an overlay

Quiet days suppress prompts and completion pressure. They do not erase the date’s underlying meaning.

### Principle 6: Tags are not analytics truth

`DayTag` is useful for UI labels, chips, and detail pages. Analytics must use explicit opportunity IDs, intention links, and credit records.

---

## 5. Proposed domain model

### 5.1 New top-level aggregate

Add a resolved product-purpose aggregate to the day snapshot.

```swift
struct ResolvedDayPurpose: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let opportunities: [ObservanceOpportunity]
    let intention: ResolvedDayIntention
    let wakeClassification: DayWakeClassification
    let requiredActions: [DayRequiredAction]
    let analyticsCredits: [ObservanceCredit]
    let explanation: DayPurposeExplanation
}
```

Extend current `ResolvedDaySnapshot`:

```swift
struct ResolvedDaySnapshot: Sendable {
    let date: Date
    let dateKey: String
    let prayerWindow: DailyPrayerWindow
    let resolvedDayContext: ResolvedDayContext
    let selectedPlan: MorningPlan
    let resolvedBehaviorProfile: MorningBehaviorProfile
    let materializedEvents: [ScheduledEvent]
    let decisionLog: RuleDecisionLog
    let completionRecords: [CompletionRecord]
    let dailyCompletion: DailyCompletionSnapshot
    let completionSummary: String?

    // New
    let resolvedDayPurpose: ResolvedDayPurpose
}
```

If adding directly is too invasive, add it first as optional or as a parallel lookup from the active-window builder, but the target state is for each resolved day to carry this aggregate.

---

### 5.2 ObservanceOpportunity

```swift
struct ObservanceOpportunity: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let kind: ObservanceKind
    let eligibility: ObservanceEligibility
    let source: ObservanceSource
    let priority: Int
    let isActionable: Bool
    let title: String
    let detail: String?
}
```

```swift
enum ObservanceKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordinary
    case ramadan
    case qadaAssignable
    case voluntaryGeneral
    case mondayThursday
    case whiteDays
    case arafah
    case ashura
    case dhulHijjahFirstNine
    case shawwalSixPotential
    case eidAlFitr
    case eidAlAdha
    case tashreeq
    case tahajjudEligible

    var id: String { rawValue }
}
```

```swift
enum ObservanceEligibility: String, Codable, Sendable {
    case obligatory
    case recommended
    case permissible
    case forbidden
    case neutral
    case notApplicable
}
```

```swift
enum ObservanceSource: Codable, Equatable, Hashable, Sendable {
    case hijriCalendar
    case gregorianWeekday
    case scheduledDateSource(ScheduledDateSourceOrigin)
    case userSelection
    case defaultDailyPlan
    case derivedFallback
}
```

#### Opportunity ID rule

Opportunity IDs must be stable per date and kind.

Recommended format:

```swift
"\(dateKey).opportunity.\(kind.rawValue)"
```

Examples:

- `2026-05-04.opportunity.mondayThursday`
- `2026-05-06.opportunity.whiteDays`
- `2026-03-01.opportunity.ramadan`

This makes intention and credit links stable without requiring global persistence of every opportunity.

---

### 5.3 ResolvedDayIntention

```swift
struct ResolvedDayIntention: Codable, Equatable, Hashable, Sendable {
    let kind: DayIntentionKind
    let source: DayIntentionSource
    let selectedOpportunityIDs: Set<String>
    let fastIntent: FastIntentSelection?
    let suppressesPrompts: Bool
    let explanation: String
}
```

```swift
enum DayIntentionKind: Codable, Equatable, Hashable, Sendable {
    case defaultFajr
    case fast
    case tahajjud
    case quiet
}
```

```swift
enum DayIntentionSource: Codable, Equatable, Hashable, Sendable {
    case defaultDailyPlan
    case autoRamadan
    case userSelected
    case userDateOverride
    case migratedFastTagSelection
    case quietOverlay
    case derivedFallback
}
```

#### MVP adaptation

The current `MorningStateSnapshot.fastTagSelections: [String: FastIntentSelection]` can act as the MVP fast-intention store.

Target long-term store:

```swift
struct DayIntentionSelection: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let kind: DayIntentionSelectionKind
    let selectedOpportunityIDs: Set<String>
    let createdAt: Date
    let updatedAt: Date
}
```

```swift
enum DayIntentionSelectionKind: Codable, Equatable, Hashable, Sendable {
    case defaultFajr
    case fast(FastIntentSelection)
    case tahajjud
    case quiet
}
```

For MVP, `fastTagSelections[dateKey]` maps to:

```swift
ResolvedDayIntention(
    kind: .fast,
    source: .migratedFastTagSelection,
    selectedOpportunityIDs: resolvedSelectedOpportunityIDs(...),
    fastIntent: selection,
    suppressesPrompts: false,
    explanation: ...
)
```

---

### 5.4 DayWakeClassification

This is product-facing and should sit above current wake rules.

```swift
struct DayWakeClassification: Codable, Equatable, Hashable, Sendable {
    let kind: DayWakeClassificationKind
    let plannedWakeState: MorningWakeRuleState
    let resolvedWakeState: ResolvedWakeState
    let anchorType: WakeAnchorType
    let explanation: String
}
```

```swift
enum DayWakeClassificationKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultInFajr
    case earlyPreFajr
    case fixedClock
    case disabled
    case overridden

    var id: String { rawValue }
}
```

Mapping:

| Intention | Wake classification | Low-level rule |
|---|---|---|
| Default Fajr | `defaultInFajr` | Existing default daily wake rule. |
| Ramadan fast | `earlyPreFajr` | Pre-Fajr wake rule. |
| Qada fast | `earlyPreFajr` | Pre-Fajr wake rule. |
| Voluntary fast | `earlyPreFajr` | Pre-Fajr wake rule. |
| Tahajjud | `earlyPreFajr` | Pre-Fajr wake rule, no fast/iftar completion logic. |
| Quiet | `disabled` | Suppress delivery and required actions. |
| Fixed date override | `fixedClock` or `overridden` | Existing override wake rule. |

---

### 5.5 Required actions

```swift
enum DayRequiredAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrCheckIn
    case fastStatus
    case fastCompletion
    case qadaCompletionCredit
    case tahajjudCheckIn

    var id: String { rawValue }
}
```

Rules:

- Default Fajr: may require `fajrCheckIn` only.
- Ramadan fast: may require `fajrCheckIn`, `fastStatus`, `fastCompletion`.
- Qada fast: may require `fajrCheckIn`, `fastStatus`, `fastCompletion`, `qadaCompletionCredit`.
- Voluntary fast: may require `fajrCheckIn`, `fastStatus`, `fastCompletion` only if the user intended the fast.
- Mere opportunity: no fast required action.
- Tahajjud: no fast required action.
- Quiet: no required action by default.

---

### 5.6 Analytics credits

```swift
struct ObservanceCredit: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let dateKey: String
    let opportunityID: String?
    let kind: ObservanceKind
    let creditType: ObservanceCreditType
    let source: ObservanceCreditSource
    let explanation: String?
}
```

```swift
enum ObservanceCreditType: String, Codable, CaseIterable, Identifiable, Sendable {
    case opportunityAvailable
    case planned
    case completed
    case missedAfterPlanning
    case keptDefault
    case suppressedByQuiet
    case invalidForbiddenFast

    var id: String { rawValue }
}
```

```swift
enum ObservanceCreditSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case opportunityResolver
    case intentionResolver
    case completionRecord
    case qadaLedger
    case quietOverlay
    case forbiddenPolicy

    var id: String { rawValue }
}
```

#### Credit ID rule

```swift
"\(dateKey).credit.\(kind.rawValue).\(creditType.rawValue)"
```

Examples:

- `2026-05-04.credit.mondayThursday.opportunityAvailable`
- `2026-05-04.credit.mondayThursday.planned`
- `2026-05-04.credit.mondayThursday.completed`
- `2026-05-06.credit.whiteDays.keptDefault`
- `2026-05-06.credit.qadaAssignable.completed`

---

## 6. Resolver architecture

### 6.1 New resolver stack

Add these focused resolvers:

```swift
enum ObservanceOpportunityResolver { ... }
enum DayIntentionResolver { ... }
enum DayWakeClassificationResolver { ... }
enum DayRequiredActionResolver { ... }
enum ObservanceCreditResolver { ... }
enum DayPurposeResolver { ... }
```

The top-level resolver:

```swift
enum DayPurposeResolver {
    static func resolve(
        date: Date,
        dateKey: String,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        effectiveConfig: EffectiveDailyConfig,
        defaultConfig: DefaultAlarmConfig,
        stateSnapshot: MorningStateSnapshot,
        selectedPlan: MorningPlan,
        wakeResolution: WakeResolutionResult,
        completionRecords: [CompletionRecord],
        dailyCompletion: DailyCompletionSnapshot
    ) -> ResolvedDayPurpose
}
```

### 6.2 Current pipeline integration

In `MorningScheduleResolver.resolve(...)`, the target ordering should become:

1. Resolve prayer window.
2. Resolve tag result and opportunity meanings.
3. Resolve user intention.
4. Resolve selected plan.
5. Resolve wake anchor and wake time.
6. Resolve context from day purpose/intention.
7. Resolve behavior profile.
8. Materialize events.
9. Resolve completion.
10. Resolve analytics credits.
11. Return `ResolvedDaySnapshot` with `resolvedDayPurpose`.

A practical first implementation can keep the existing plan/context order and compute `ResolvedDayPurpose` after daily completion, but the long-term target is for intention to influence plan selection before event materialization.

---

## 7. Detailed resolver rules

### 7.1 Opportunity resolver

Input:

- `date`
- `dateKey`
- `provenances`
- `tagResult`
- `FastIntentEngine.warnings(...)`
- `FastIntentEngine.dateDerivedObservanceTags(...)`
- `FastIntentEngine.isRamadan(...)`

Output:

- `[ObservanceOpportunity]`

Rules:

1. Always derive forbidden-day opportunities first.
   - Eid al-Fitr -> `.eidAlFitr`, `.forbidden`, not normally actionable.
   - Eid al-Adha -> `.eidAlAdha`, `.forbidden`, not normally actionable.
   - Tashreeq -> `.tashreeq`, `.forbidden`, not normally actionable.

2. Derive Ramadan.
   - If the adjusted Hijri calendar says Ramadan, emit `.ramadan` with `.obligatory`.
   - If provenance includes `.defaultRamadan`, also emit/confirm `.ramadan`.

3. Derive Sunnah/recommended opportunities.
   - Monday/Thursday -> `.mondayThursday`, `.recommended`.
   - White Days -> `.whiteDays`, `.recommended`.
   - Arafah -> `.arafah`, `.recommended`.
   - Ashura -> `.ashura`, `.recommended`.
   - Dhul Hijjah first nine -> `.dhulHijjahFirstNine`, `.recommended`.
   - Shawwal potential -> `.shawwalSixPotential`, `.recommended`, with later first-six tracking.

4. Derive user/scheduled source opportunities.
   - Manual date/range fast source can emit `.voluntaryGeneral`, `.qadaAssignable`, or specific kind depending on stored selection.
   - Existing recurring sources such as White Days and Monday/Thursday should emit corresponding opportunity kinds.

5. If no meaningful opportunity exists, emit `.ordinary` with `.neutral` only if useful for debug/analytics. For UI, ordinary can be omitted.

6. Do not make an opportunity an active intention.

---

### 7.2 Intention resolver

Input:

- Opportunities.
- Existing `fastTagSelections[dateKey]`.
- Future `DayIntentionSelection`.
- Effective date override.
- Quiet selection.
- Tahajjud selection.
- Ramadan opportunity.

Output:

- `ResolvedDayIntention`

Precedence:

1. **Quiet overlay**
   - If quiet is selected, resolve intention `.quiet` with `suppressesPrompts = true`.
   - Preserve opportunities.
   - Do not delete Ramadan/Sunnah meaning.

2. **Explicit user-selected intention**
   - Fast selection -> `.fast`.
   - Tahajjud selection -> `.tahajjud`.
   - Default Fajr selection -> `.defaultFajr`.

3. **Auto-Ramadan**
   - If `.ramadan` opportunity exists and the date is not quiet/forbidden, resolve `.fast` with `FastPrimaryIntent.ramadanObligatory`.

4. **Existing migrated fast tag selection**
   - If `fastTagSelections[dateKey]` exists, resolve `.fast` with that selection.

5. **Default daily plan**
   - Resolve `.defaultFajr`.

Important:

- Sunnah opportunities alone must not resolve `.fast`.
- Monday/Thursday alone must not trigger early wake.
- White Day alone must not trigger fast completion requirement.
- Qada must be user-selected or explicitly assigned; it is not calendar-derived.

---

### 7.3 Selected opportunity matching

For fast intentions, selected opportunities should be linked like this:

| Intention | Selected opportunity IDs |
|---|---|
| Ramadan obligatory | Ramadan opportunity ID. |
| Qada makeup | Qada assignment/opportunity ID if present; otherwise none or synthetic qada credit kind. |
| Voluntary with Monday/Thursday present | Monday/Thursday opportunity ID if user selected/accepted it. |
| Voluntary with White Day present | White Day opportunity ID if user selected/accepted it. |
| Voluntary general | No specific opportunity ID, or `.voluntaryGeneral` if explicitly created. |
| Tahajjud | Tahajjud opportunity/selection ID if modeled; otherwise none. |
| Default Fajr | Empty set. |
| Quiet | Empty set for action, but credits can mark opportunities as suppressed by quiet. |

MVP behavior:

- If user chooses voluntary fast on a date with exactly one recommended opportunity, auto-link that opportunity.
- If multiple recommended opportunities coexist, link all compatible ones only when strict rules allow coexistence.
- If user chooses qada, do not auto-link Sunnah opportunities for completion credit.

---

### 7.4 Wake classification resolver

Input:

- `ResolvedDayIntention`
- `selectedPlan`
- `wakeResolution`
- `effectiveConfig`

Rules:

1. Quiet -> `.disabled`.
2. Fast -> `.earlyPreFajr` unless explicit override/fixed clock says otherwise.
3. Tahajjud -> `.earlyPreFajr` unless explicit override/fixed clock says otherwise.
4. Default Fajr -> `.defaultInFajr` for in-Fajr rule, `.earlyPreFajr` only if the user’s default daily plan is before-Fajr.
5. Fixed wake compatibility -> `.fixedClock`.
6. Explicit date override -> `.overridden` or more precise classification with `source = userDateOverride` in explanation.

---

### 7.5 Required action resolver

Input:

- `ResolvedDayIntention`
- `DailyCompletionSnapshot`
- `ObservanceEligibility`

Rules:

1. Default Fajr:
   - `fajrCheckIn` may be required depending on existing completion policy.
   - No `fastStatus` or `fastCompletion`.

2. Ramadan:
   - `fastStatus` and `fastCompletion` are relevant.
   - Iftar reminder may be enabled.

3. Qada:
   - `fastStatus`, `fastCompletion`, and `qadaCompletionCredit` are relevant.

4. Voluntary fast:
   - `fastStatus` and `fastCompletion` are relevant only if user intended the fast.

5. Opportunity only:
   - No fast required action.

6. Quiet:
   - No required action by default.

7. Forbidden:
   - No fast planning action.
   - If logged, mark as warning/invalid-forbidden credit; do not treat as completed Sunnah.

---

### 7.6 Credit resolver

Input:

- Opportunities.
- Resolved intention.
- Completion records.
- `DailyCompletionSnapshot`.
- Qada effect.

Rules:

1. Emit `opportunityAvailable` for every meaningful opportunity, including opportunities that the user did not act on.

2. Emit `planned` only when intention explicitly selected or auto-selected that opportunity.

3. Emit `completed` only when:
   - The action was completed; and
   - The completed action is compatible with the opportunity; and
   - The intention selected that opportunity or the observance is auto-obligatory Ramadan.

4. Emit `missedAfterPlanning` only when:
   - The opportunity was planned; and
   - The action was not completed or is explicitly logged as not completed.

5. Emit `keptDefault` when:
   - A recommended opportunity existed; and
   - The user resolved `.defaultFajr`; and
   - No fast completion was logged for that opportunity.

6. Emit `suppressedByQuiet` when:
   - A meaningful opportunity existed; and
   - The user resolved `.quiet`.

7. Emit `invalidForbiddenFast` when:
   - A forbidden opportunity exists; and
   - A fast completion record is logged as completed/in progress.

8. Qada:
   - Completed qada emits qada completion credit.
   - Qada completion does not automatically emit completed White Day/Monday/etc. credit.

9. Ramadan:
   - Ramadan auto-intention can emit planned without explicit user selection.
   - Completed Ramadan fast credits Ramadan.

10. Do not infer completed credits from tags alone.

---

## 8. Event materialization rules

The new purpose layer should affect scheduling as follows:

| Resolved intention | Wake alarm | Fajr boundary | Iftar | Completion pressure |
|---|---:|---:|---:|---:|
| Default Fajr | Yes, default | As existing | No | Fajr only |
| Ramadan fast | Yes, early | Yes | Yes | Fajr + fast |
| Qada fast | Yes, early | Yes | Optional/Yes based config | Fajr + fast + qada |
| Voluntary fast | Yes, early | Yes | Optional/Yes based config | Fajr + fast |
| Tahajjud | Yes, early | Optional/Yes | No | No fast |
| Quiet | No or minimized | No or silent only | No | None |
| Opportunity only | Default only | As default | No | Fajr only |
| Forbidden fast day | Default only | As default | No | No fast planning |

Implementation note:

- Existing `materializeEvents(...)` already emits wake reminder, wake alarm, wake follow-up, Fajr boundary notice, and iftar reminder. The new layer should control booleans such as `wakeAlarmEnabled`, `iftarReminderEnabled`, and `suppressDefaultPrayerPrompt`, not create a second notification engine.

---

## 9. UI representation

### 9.1 Day detail page

Use three explicit sections:

1. **This day**
   - Shows opportunities/meanings.
   - Example: “Monday/Thursday — recommended fasting opportunity.”

2. **Your plan**
   - Shows intention.
   - Example: “Usual Fajr wake.” / “Voluntary fast planned.” / “Qada fast planned.” / “Quiet day.”

3. **Your log**
   - Shows completion/outcome.
   - Example: “Fast completed.” / “Not logged yet.” / “Kept as default Fajr day.”

### 9.2 Home hero

The hero should show the dominant plan/purpose, not all opportunities.

Examples:

- Opportunity only: “Usual Fajr wake” with small secondary chip “Monday/Thursday opportunity”.
- Planned voluntary fast: “Voluntary fast planned”.
- Ramadan: “Ramadan fast”.
- Quiet: “Quiet day”.
- Tahajjud: “Tahajjud wake planned”.

### 9.3 Weekly Fajrcast / Morningcast

Rows may show both:

- purpose pill: Default / Fast / Qada / Tahajjud / Quiet;
- opportunity tags: White Days / Mon-Thu / Arafah / Ashura.

Do not visually imply that opportunity tags are planned unless the intention says so.

Suggested chip hierarchy:

1. Primary intention chip.
2. One highest-priority opportunity chip if not already represented.
3. Warning chip for forbidden days.

---

## 10. Analytics model

Future analytics should aggregate credits, not raw tags.

### 10.1 Example queries

“How many Monday/Thursday opportunities existed this year?”

```swift
credits.filter {
    $0.kind == .mondayThursday && $0.creditType == .opportunityAvailable
}.count
```

“How many Monday/Thursday fasts did the user complete?”

```swift
credits.filter {
    $0.kind == .mondayThursday && $0.creditType == .completed
}.count
```

“How many Monday/Thursday opportunities did the user keep as default?”

```swift
credits.filter {
    $0.kind == .mondayThursday && $0.creditType == .keptDefault
}.count
```

“How many qada fasts were completed?”

```swift
credits.filter {
    $0.kind == .qadaAssignable && $0.creditType == .completed
}.count
```

### 10.2 Analytics must distinguish

| Metric | Source |
|---|---|
| Opportunity count | `ObservanceCreditType.opportunityAvailable` |
| Planned count | `ObservanceCreditType.planned` |
| Completed count | `ObservanceCreditType.completed` |
| Missed planned count | `ObservanceCreditType.missedAfterPlanning` |
| Meaningful but default count | `ObservanceCreditType.keptDefault` |
| Quiet-suppressed count | `ObservanceCreditType.suppressedByQuiet` |
| Forbidden logged count | `ObservanceCreditType.invalidForbiddenFast` |

---

## 11. OpenSpec proposal content

If this is turned into a repository OpenSpec change, use the following structure.

### `openspec/changes/day-purpose-opportunity-resolution/proposal.md`

```md
## Why

Subh needs to distinguish what a date means from what the user intends and what the user completes. Sunnah observance opportunities such as Monday/Thursday, White Days, Arafah, Ashura, Dhul Hijjah, and Shawwal Six may exist even when the user keeps the default Fajr wake. Future analytics require separate counts for available opportunities, planned observances, completed observances, missed-after-planning observances, quiet-suppressed observances, and qada/Ramadan completions.

## What Changes

- Add a resolved day-purpose layer that separates observance opportunities, user intention, wake classification, required actions, outcomes, and analytics credits.
- Keep existing Fajr/prayer-time and event materialization logic, but feed it from a clearer intention model.
- Treat optional Sunnah meanings as opportunities unless the user selects a fast intention.
- Treat Ramadan as an auto-obligatory fast context unless quiet/suppression handling applies.
- Treat qada as a primary user-selected intention that does not automatically credit secondary Sunnah opportunities.
- Add credit plumbing so future progress views can count opportunity, planned, completed, missed-after-planning, kept-default, quiet-suppressed, and forbidden-fast cases.

## Capabilities

### Added Capabilities

- `morning-day-purpose-resolution`: Resolves each date into observance opportunities, user intention, wake classification, required actions, and analytics credits.

### Modified Capabilities

- `single-screen-morning-home`: May show dominant purpose plus opportunity tags without implying that mere opportunity means planned fast.

## Impact

- Affected code:
  - `Subh/Core/Scheduling/MorningResolver.swift`
  - `Subh/Core/Morning/Models/ResolvedDaySnapshot.swift`
  - `Subh/Core/Morning/Models/MorningContextModels.swift`
  - `Subh/Core/Morning/Context/MorningFastDomain.swift`
  - `Subh/Core/Morning/Context/MorningTagComputationDomain.swift`
  - `Subh/Core/Morning/Context/ResolvedDayContextResolver.swift`
  - `Subh/Core/Morning/Planning/MorningPlanResolver.swift`
  - `Subh/Core/Morning/Models/CompletionModels.swift`
  - `Subh/Core/Morning/Completion/DailyCompletionResolver.swift`
  - Future/optional: home, day detail, weekly Fajrcast, Morningcast presentation files.
- No prayer-time calculation behavior changes.
- No immediate requirement to redesign notifications.
- Existing `fastTagSelections` may be adapted as MVP fast intentions.
```

---

## 12. OpenSpec design content

### `openspec/changes/day-purpose-opportunity-resolution/design.md`

```md
## Context

The current morning resolver already produces a `ResolvedDaySnapshot` with prayer window, resolved context, selected plan, behavior profile, materialized events, completion records, and daily completion. The fast domain already understands Ramadan, forbidden days, qada, kaffarah, vow, voluntary fasts, and secondary virtue tags. However, the current model risks using context/tags as if they were user intention or completion credit.

## Decisions

1. **Separate meaning from intention.**
   A date may have one or more `ObservanceOpportunity` values. These are calendar/provenance meanings and do not schedule early wake by themselves.

2. **Use intention to drive wake behavior.**
   `ResolvedDayIntention` determines whether a date is default Fajr, fast, Tahajjud, or quiet. Early wake comes from intention, not from optional opportunity alone.

3. **Keep tags as presentation metadata.**
   Existing `DayTag` remains useful for UI, but analytics must use explicit opportunity IDs and credits.

4. **Introduce analytics credits as derived facts.**
   Reports count `ObservanceCredit` values, not raw dates or UI tags.

5. **Preserve current prayer-time and scheduling logic.**
   `MorningScheduleResolver`, wake rules, and event materialization remain the scheduling source of truth. The new purpose layer feeds those systems and receives their resolved results.

6. **Treat quiet as an overlay.**
   Quiet suppresses prompts/actions but preserves the date’s opportunities for explanation and future analytics.

7. **Treat qada as primary intent.**
   A qada fast on a Sunnah opportunity date counts as qada unless explicit compatibility rules later allow secondary credit.

## Risks / Trade-offs

- Adding a new resolved layer increases model complexity, but prevents future analytics ambiguity.
- Existing UI may initially show only a subset of this information.
- The MVP can adapt `fastTagSelections` instead of immediately migrating persistence to a unified `DayIntentionSelection` store.
```

---

## 13. OpenSpec requirements

### `openspec/changes/day-purpose-opportunity-resolution/specs/morning-day-purpose-resolution/spec.md`

```md
## morning-day-purpose-resolution OpenSpec Requirement Set

## Purpose

Define how Subh resolves each date into observance opportunities, user intention, wake classification, required actions, outcomes, and analytics credits without collapsing them into a single day state.

## ADDED Requirements

### Requirement: Dates expose observance opportunities independent of user intention
The system SHALL derive observance opportunities for a date without requiring the user to plan or complete those observances.

#### Scenario: Monday opportunity remains default Fajr
- **GIVEN** a date falls on Monday or Thursday
- **AND** the user has not selected a fast intention for the date
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a Monday/Thursday observance opportunity
- **AND** the resolved intention SHALL remain default Fajr
- **AND** the wake plan SHALL remain the default Fajr wake plan
- **AND** the system SHALL NOT require fast completion for that date

#### Scenario: White Day opportunity remains default Fajr
- **GIVEN** a date is a White Day
- **AND** the user has not selected a fast intention for the date
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a White Days observance opportunity
- **AND** the resolved intention SHALL remain default Fajr
- **AND** analytics SHALL emit opportunity-available credit but no planned or missed-after-planning credit

### Requirement: User intention drives active wake behavior
The system SHALL use the resolved user intention to decide whether the day uses default Fajr wake, early before-Fajr wake, Tahajjud wake, or quiet suppression.

#### Scenario: User plans voluntary fast on a Monday opportunity
- **GIVEN** a date has a Monday/Thursday opportunity
- **AND** the user selects a voluntary fast intention for that opportunity
- **WHEN** the date is resolved
- **THEN** the resolved intention SHALL be fast
- **AND** the selected opportunity IDs SHALL include the Monday/Thursday opportunity
- **AND** the wake classification SHALL be early before-Fajr unless a date-specific override applies
- **AND** the system SHALL include fast completion as a relevant action

#### Scenario: User chooses Tahajjud on a Sunnah opportunity date
- **GIVEN** a date has a Sunnah fast opportunity
- **AND** the user selects Tahajjud rather than fasting
- **WHEN** the date is resolved
- **THEN** the resolved intention SHALL be Tahajjud
- **AND** the wake classification SHALL be early before-Fajr
- **AND** the system SHALL NOT require fast completion for that date
- **AND** the Sunnah opportunity SHALL remain available but unplanned

### Requirement: Ramadan resolves as an auto-obligatory fast context
The system SHALL treat Ramadan as an auto-obligatory fasting context unless a quiet or future exception policy suppresses prompts.

#### Scenario: Ramadan date has no explicit user selection
- **GIVEN** a date is in Ramadan
- **AND** the user has not selected a quiet day
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a Ramadan opportunity
- **AND** the resolved intention SHALL be fast with Ramadan obligatory intent
- **AND** the wake classification SHALL be early before-Fajr unless an explicit override applies
- **AND** analytics SHALL emit opportunity-available and planned credits for Ramadan

### Requirement: Qada fasts credit qada without automatically crediting Sunnah opportunities
The system SHALL treat qada as a primary fast intention and SHALL NOT automatically credit secondary Sunnah opportunities when qada is completed.

#### Scenario: User completes qada on a White Day
- **GIVEN** a date has a White Days opportunity
- **AND** the user selects qada fast intention
- **AND** the user completes the fast
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit White Days opportunity-available credit
- **AND** it SHALL emit qada planned and completed credit
- **AND** it SHALL NOT emit White Days completed credit

### Requirement: Optional opportunities are not missed unless planned
The system SHALL only emit missed-after-planning credit when the user planned or auto-planned the observance.

#### Scenario: User ignores Arafah opportunity
- **GIVEN** a date has an Arafah opportunity
- **AND** the user keeps the default Fajr intention
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit Arafah opportunity-available credit
- **AND** it SHALL emit kept-default credit if enabled for reporting
- **AND** it SHALL NOT emit Arafah missed-after-planning credit

#### Scenario: User plans but does not complete voluntary fast
- **GIVEN** a date has a White Days opportunity
- **AND** the user plans a voluntary fast for that opportunity
- **AND** the user logs the fast as not completed
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit White Days opportunity-available credit
- **AND** it SHALL emit White Days planned credit
- **AND** it SHALL emit White Days missed-after-planning credit

### Requirement: Quiet days suppress action without erasing meaning
The system SHALL preserve observance opportunities on quiet days while suppressing prompts and required actions.

#### Scenario: User marks a Ramadan date quiet
- **GIVEN** a date is in Ramadan
- **AND** the user marks the date quiet
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include the Ramadan opportunity
- **AND** the resolved intention SHALL be quiet
- **AND** wake alarms and completion prompts SHALL be suppressed according to quiet policy
- **AND** analytics MAY emit suppressed-by-quiet credit

### Requirement: Forbidden fast days cannot be treated as normal planned fasts
The system SHALL mark forbidden fasting dates as forbidden opportunities and SHALL NOT offer normal fast planning behavior for them.

#### Scenario: Eid date is resolved
- **GIVEN** a date is Eid al-Fitr or Eid al-Adha
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a forbidden observance opportunity
- **AND** the system SHALL NOT auto-plan a fast
- **AND** the default intention SHALL remain default Fajr unless the user has a quiet or other non-fast intention

#### Scenario: User logs completed fast on a forbidden date
- **GIVEN** a date has a forbidden fast opportunity
- **AND** a completed fast record exists for the date
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit invalid-forbidden-fast credit
- **AND** it SHALL NOT emit completed Sunnah or Ramadan fast credit

### Requirement: Analytics count credits rather than visual tags
The system SHALL aggregate future progress metrics from observance credits rather than raw `DayTag` values.

#### Scenario: Annual Monday/Thursday report
- **GIVEN** a date range includes multiple Monday/Thursday opportunities
- **WHEN** the report counts opportunities, planned fasts, and completed fasts
- **THEN** opportunity count SHALL use `opportunityAvailable` credits
- **AND** planned count SHALL use `planned` credits
- **AND** completed count SHALL use `completed` credits
- **AND** unplanned opportunities SHALL NOT count as missed planned fasts
```

---

## 14. Implementation tasks

### `openspec/changes/day-purpose-opportunity-resolution/tasks.md`

```md
## 1. Domain Models

- [ ] 1.1 Add `ObservanceOpportunity`, `ObservanceKind`, `ObservanceEligibility`, and `ObservanceSource`.
- [ ] 1.2 Add `ResolvedDayIntention`, `DayIntentionKind`, and `DayIntentionSource`.
- [ ] 1.3 Add `DayWakeClassification` and `DayWakeClassificationKind`.
- [ ] 1.4 Add `DayRequiredAction`.
- [ ] 1.5 Add `ObservanceCredit`, `ObservanceCreditType`, and `ObservanceCreditSource`.
- [ ] 1.6 Add `ResolvedDayPurpose` and wire it into `ResolvedDaySnapshot`.

## 2. Resolvers

- [ ] 2.1 Add `ObservanceOpportunityResolver` using `FastIntentEngine`, `TagComputationResult`, and scheduled-date provenances.
- [ ] 2.2 Add `DayIntentionResolver` that separates opportunity from default/fast/tahajjud/quiet intention.
- [ ] 2.3 Add `DayWakeClassificationResolver` that maps intention plus existing wake resolution into product-facing wake classes.
- [ ] 2.4 Add `DayRequiredActionResolver` so optional opportunities do not create fast completion pressure.
- [ ] 2.5 Add `ObservanceCreditResolver` for opportunity/planned/completed/missed/kept-default/quiet/forbidden credits.
- [ ] 2.6 Add `DayPurposeResolver` as the orchestration layer.

## 3. Integration

- [ ] 3.1 Wire `DayPurposeResolver` into `MorningScheduleResolver.resolve(...)`.
- [ ] 3.2 Preserve existing `ResolvedDayContext` output as compatibility/presentation data.
- [ ] 3.3 Ensure `MorningPlanResolver` does not treat optional opportunities as active fast plans unless the intention says fast.
- [ ] 3.4 Ensure `DailyCompletionResolver` does not require fast status for opportunity-only days.
- [ ] 3.5 Ensure qada completion credits qada without automatically crediting Sunnah opportunities.

## 4. MVP Persistence Compatibility

- [ ] 4.1 Adapt existing `fastTagSelections` into fast intentions for MVP.
- [ ] 4.2 Do not require immediate migration to a unified `DayIntentionSelection` store.
- [ ] 4.3 Add TODO/future hook for quiet and Tahajjud selections if not yet persisted.
- [ ] 4.4 Ensure existing completion metadata remains readable.

## 5. Presentation

- [ ] 5.1 Expose dominant intention and opportunity chips to day detail presentation.
- [ ] 5.2 Ensure Home hero shows dominant plan/purpose, not every opportunity.
- [ ] 5.3 Ensure Weekly Fajrcast/Morningcast distinguish opportunity chips from planned-fast chips.

## 6. Tests

- [ ] 6.1 Test Monday/Thursday opportunity with default Fajr intention.
- [ ] 6.2 Test White Day opportunity with default Fajr intention.
- [ ] 6.3 Test voluntary fast planned/completed on Monday/Thursday.
- [ ] 6.4 Test voluntary fast planned/not-completed on White Day.
- [ ] 6.5 Test qada completed on White Day does not credit White Day completion.
- [ ] 6.6 Test Ramadan auto-intention.
- [ ] 6.7 Test quiet overlay preserves opportunities but suppresses actions.
- [ ] 6.8 Test Eid/Tashreeq forbidden opportunity and invalid forbidden fast logging.
- [ ] 6.9 Test analytics report counts opportunity/planned/completed/missed separately.

## 7. Validation

- [ ] 7.1 Run OpenSpec strict validation.
- [ ] 7.2 Run focused unit tests for new resolvers.
- [ ] 7.3 Run existing scheduling and completion tests.
- [ ] 7.4 Run snapshot/presentation tests if UI chips are added.
```

---

## 15. Test matrix

| Case | Opportunities | Intention | Completion | Expected credits |
|---|---|---|---|---|
| Ordinary date | None or ordinary | Default Fajr | Fajr completed | No fast credits |
| Monday default | Monday/Thursday | Default Fajr | Fajr completed | Opportunity available; kept default; no missed |
| White Day default | White Days | Default Fajr | None | Opportunity available; no planned; no missed |
| Monday voluntary completed | Monday/Thursday | Fast voluntary linked to Monday/Thursday | Fast completed | Opportunity available; planned; completed |
| White Day planned not completed | White Days | Fast voluntary linked to White Days | Fast not completed | Opportunity available; planned; missed after planning |
| White Day qada completed | White Days | Fast qada | Fast completed | White opportunity available; qada planned/completed; no White completed |
| Ramadan no selection | Ramadan | Fast Ramadan auto | Fast completed | Ramadan opportunity/planned/completed |
| Ramadan quiet | Ramadan | Quiet | No fast prompt | Ramadan opportunity; suppressed by quiet |
| Arafah ignored | Arafah | Default Fajr | No fast | Arafah opportunity; kept default; no missed |
| Tahajjud on Monday | Monday/Thursday | Tahajjud | No fast | Monday opportunity; Tahajjud planned if tracked; no fast planned |
| Eid default | Eid forbidden | Default Fajr | No fast | Forbidden opportunity; no planned fast |
| Eid fast logged | Eid forbidden | Default or invalid user selection | Fast completed | Forbidden opportunity; invalid forbidden fast |

---

## 16. Migration and compatibility

### 16.1 Existing `fastTagSelections`

Current `fastTagSelections` should be treated as an MVP input to the new intention layer. Do not delete it in the first implementation.

Mapping:

| Existing value | New interpretation |
|---|---|
| `FastPrimaryIntent.ramadanObligatory` | Auto or explicit Ramadan fast intention. |
| `FastPrimaryIntent.qadaMakeup` | Qada fast intention. |
| `FastPrimaryIntent.voluntary` | Voluntary fast intention; link to compatible opportunities if present. |
| `FastPrimaryIntent.kaffarahExpiation` | Obligatory fast intention; do not credit Sunnah secondary tags in strict mode. |
| `FastPrimaryIntent.vowNadhr` | Obligatory fast intention; do not credit Sunnah secondary tags in strict mode. |
| `FastPrimaryIntent.forbidden` | Forbidden warning/policy, not a normal plan. |
| `FastPrimaryIntent.other` | No specific fast intention unless paired with explicit source. |

### 16.2 Existing completion metadata

Current completion records support `kind`, `status`, `source`, and metadata. Continue storing fast completion metadata such as `primaryIntent` and qada effect. The credit resolver can derive historical credits from existing metadata when available.

### 16.3 Existing `ResolvedDayContext`

Do not remove `ResolvedDayContext` immediately. It remains useful for UI summaries and compatibility. Over time, it should derive from `ResolvedDayPurpose` instead of being the only semantic layer.

---

## 17. Example resolved outputs

### 17.1 Monday opportunity, user stays default

```swift
ResolvedDayPurpose(
    dateKey: "2026-05-04",
    opportunities: [
        .mondayThursday(dateKey: "2026-05-04", eligibility: .recommended)
    ],
    intention: .defaultFajr(source: .defaultDailyPlan),
    wakeClassification: .defaultInFajr,
    requiredActions: [.fajrCheckIn],
    analyticsCredits: [
        .opportunityAvailable(kind: .mondayThursday),
        .keptDefault(kind: .mondayThursday)
    ],
    explanation: ...
)
```

### 17.2 Monday opportunity, voluntary fast completed

```swift
ResolvedDayPurpose(
    dateKey: "2026-05-04",
    opportunities: [
        .mondayThursday(dateKey: "2026-05-04", eligibility: .recommended)
    ],
    intention: .fast(
        primaryIntent: .voluntary,
        selectedOpportunityIDs: ["2026-05-04.opportunity.mondayThursday"]
    ),
    wakeClassification: .earlyPreFajr,
    requiredActions: [.fajrCheckIn, .fastStatus, .fastCompletion],
    analyticsCredits: [
        .opportunityAvailable(kind: .mondayThursday),
        .planned(kind: .mondayThursday),
        .completed(kind: .mondayThursday)
    ],
    explanation: ...
)
```

### 17.3 White Day, qada completed

```swift
ResolvedDayPurpose(
    dateKey: "2026-05-06",
    opportunities: [
        .whiteDays(dateKey: "2026-05-06", eligibility: .recommended)
    ],
    intention: .fast(
        primaryIntent: .qadaMakeup,
        selectedOpportunityIDs: []
    ),
    wakeClassification: .earlyPreFajr,
    requiredActions: [.fajrCheckIn, .fastStatus, .fastCompletion, .qadaCompletionCredit],
    analyticsCredits: [
        .opportunityAvailable(kind: .whiteDays),
        .planned(kind: .qadaAssignable),
        .completed(kind: .qadaAssignable)
    ],
    explanation: ...
)
```

### 17.4 Ramadan auto-intention

```swift
ResolvedDayPurpose(
    dateKey: "2026-02-19",
    opportunities: [
        .ramadan(dateKey: "2026-02-19", eligibility: .obligatory)
    ],
    intention: .fast(
        primaryIntent: .ramadanObligatory,
        selectedOpportunityIDs: ["2026-02-19.opportunity.ramadan"]
    ),
    wakeClassification: .earlyPreFajr,
    requiredActions: [.fajrCheckIn, .fastStatus, .fastCompletion],
    analyticsCredits: [
        .opportunityAvailable(kind: .ramadan),
        .planned(kind: .ramadan),
        .completed(kind: .ramadan)
    ],
    explanation: ...
)
```

---

## 18. Guardrails for implementation agent

1. Do not replace the prayer-time calculation system.
2. Do not replace existing wake rule enums.
3. Do not use `DayTag` as the sole analytics source.
4. Do not make optional Sunnah opportunities trigger early wake unless the user intended a fast.
5. Do not mark unplanned optional opportunities as missed.
6. Do not credit qada completion to Sunnah opportunities by default.
7. Preserve existing completion record compatibility.
8. Keep the first implementation resolver-focused before adding broad UI changes.
9. Add unit tests for resolver behavior before presentation polish.
10. Keep the code Fajr-centered: fasting, Tahajjud, Ramadan, qada, and quiet days are layered meanings/intents around the morning system.

---

## 19. Recommended first implementation slice

For the first commit, implement only backend plumbing:

1. Add models.
2. Add opportunity resolver.
3. Add intention resolver using existing `fastTagSelections`.
4. Add credit resolver.
5. Add `resolvedDayPurpose` to `ResolvedDaySnapshot`.
6. Add unit tests for the matrix in section 15.

Defer:

- large UI redesign;
- unified persistence migration;
- Tahajjud completion logging;
- advanced annual analytics screens;
- complex multi-opportunity user selection UI.

This keeps the work shippable and creates the source-of-truth layer future surfaces can use.

---

## 20. Final conclusion

The correct infrastructure is not a larger day-state enum. The correct infrastructure is a resolved day-purpose layer with separate opportunity, intention, wake, outcome, and credit concepts.

Subh should be able to say:

- “This day had meaning.”
- “The user did or did not choose to act on that meaning.”
- “The app scheduled accordingly.”
- “The user completed, skipped, missed, or did not log the action.”
- “Only the correct observance receives credit.”

That structure keeps the MVP understandable and gives the app the foundation for accurate future progress reporting across Sunnah fasts, Ramadan, qada, Tahajjud, quiet days, and ordinary default Fajr mornings.
