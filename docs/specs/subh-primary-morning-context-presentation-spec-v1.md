# Subh Primary Morning Context Presentation Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-primary-morning-context-presentation-spec-v1.md` |
| Version | 1 |
| Spec status | Draft; proposed canonical working spec |
| Date | 2026-05-17 |
| Supersedes | None |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-shared-day-tag-presentation-contract-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md`, `subh-weekly-fajrcast-card-spec-v14.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md` |
| Owning domain / surface | Shared Home and Day Detail primary day-context presentation |
| Implementation audit status | Needs implementation audit |

## Purpose

Define the reusable **Primary Morning Context** presentation module that explains the meaning of the selected or immediate morning without creating a second day resolver, duplicating Hero wake-time copy, or re-deriving fasting-opportunity logic in views.

The module exists because Subh has multiple surfaces that need the same day-context understanding:

- Home, immediately below the Morning Hero;
- Day Detail, immediately below the shared hero / mode selector;
- future selected-day surfaces that need a compact explanation of day meaning, opportunity, user-selected purpose, and quiet/override state.

The module must answer:

```text
What kind of morning is this?
Is there a recognized fasting opportunity?
What has the user selected, if anything?
Did the user select a different fast purpose than the available opportunity?
Is this Ramadan, Eid, Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6, Monday/Thursday, Qada, Voluntary, or ordinary Fajr?
```

It must not answer what the Hero already answers:

```text
What exact wake time is shown?
How many minutes before Fajr begins or Fajr ends is the wake?
Where is the wake handle on the boundary visual?
Will the alarm ring / not ring as the primary wake-execution state?
```

## What This Spec Owns

- Home placement and density for the Primary Morning Context module.
- Day Detail reuse of the same context module.
- The boundary between Hero wake-execution copy and day-context copy.
- The layout-ready presentation payload consumed by Home and Day Detail.
- Copy precedence for ordinary, opportunity-only, selected Suhoor, selected fasting purpose, override, Ramadan, forbidden/Eid, Quiet, and unavailable states.
- Compact and expanded presentation modes.
- Shared component behavior when opportunities and user intention differ.
- Accessibility requirements for context summary and chips.
- QA scenarios for cross-surface consistency.

## What This Spec Does Not Own

- Prayer-time calculation.
- Fajr begin/end source selection.
- Final-third calculation.
- Observance compatibility / fiqh logic.
- Day-purpose opportunity and credit derivation.
- Quick wake-mode mutation rules.
- Alarm scheduling or delivery reliability.
- Next 7 Mornings row geometry.
- Weekly Fajrcast chart geometry.
- Full fasting-program education or Islamic-learning content.
- Progress/analytics reporting.

## Normative Requirements

The normative requirements in this spec are the explicit MUST, SHALL, MUST NOT, SHOULD, and acceptance criteria below. Examples are advisory unless a requirement says the exact text is required.

## Integrity Guardrail

This spec is a **presentation contract**, not a new domain resolver.

The Primary Morning Context module SHALL consume resolved data from the existing Subh morning spine:

```text
ResolvedDayPurpose
ResolvedMorningWakeState
ResolvedDaySnapshot
SharedDayTagPresentationSnapshot
```

The module MUST NOT:

- calculate Hijri dates;
- calculate Fajr begin, Fajr end, Maghrib, or final-third start;
- derive Sunnah opportunities from calendar dates locally;
- decide which opportunities can coexist;
- infer user intention from visible tags;
- infer alarm activation from chip labels;
- rewrite Quiet, Suhoor, or Fajr state;
- schedule or cancel alarms;
- create date-specific overrides;
- duplicate Hero wake relation text.

If the Primary Morning Context output disagrees with Next 7 Mornings, Alarm Detail, Weekly Fajrcast, or the Hero for the same date, the defect is a source-of-truth / resolver consumption defect, not a reason to add local presentation logic.

---

## 1. One-sentence definition

**Primary Morning Context is a quiet, reusable Home and Day Detail module that summarizes the selected morning's day meaning, fasting opportunity, user-selected purpose, and meaningful overrides using the canonical resolved day-purpose and wake-state outputs.**

---

## 2. Product mental model

Subh is a Fajr-centered morning system. The Hero gives the immediate wake-execution answer. The Primary Morning Context gives the immediate day-meaning answer.

```text
Hero = wake execution
Primary Morning Context = day meaning + user purpose
Next 7 Mornings = compact weekly preview
Weekly Fajrcast = weekly Fajr-window trend
Day Detail = editable selected-day explanation and controls
```

The module should feel like a short morning brief, not a second Hero, not an educational article, and not a diagnostic panel.

### 2.1 The user-facing job

The module should help the user understand the selected morning quickly:

```text
Arafah is recognized.
I have not planned Suhoor for it.

or

Qada fast planned.
This day also has a White Days opportunity.

or

Ramadan day 8.
The fasting purpose is Ramadan and is locked.
```

### 2.2 Product tone

Copy should be:

- calm;
- short;
- plain English;
- respectful;
- non-pressuring;
- free of developer terms;
- free of lengthy religious education;
- free of duplicate wake-time mechanics.

The module should support the product philosophy:

```text
Minimal screen time. Maximum execution.
```

---

## 3. Placement

### 3.1 Home placement

On Home, the module appears below the Morning Hero and above Next 7 Mornings:

```text
1. Morning Hero
2. Primary Morning Context, compact
3. Next 7 Mornings
4. Weekly Fajrcast
```

Rules:

- The module is compact on Home.
- The module should not visually compete with the Hero.
- The module should not push the Hero down.
- The module should use the existing liquid-glass surface language or a visually compatible quiet strip treatment.
- The module may be hidden on Home for a fully ordinary default Fajr morning with no selected user override, no recognized opportunity, no Ramadan/forbidden context, and no unavailable-data warning.

### 3.2 Day Detail placement

On Day Detail, the same module appears below the shared Hero / selector region.

Recommended Day Detail structure:

```text
1. Navigation title: Detailed View for the Day
2. Shared selected-day Hero
3. Primary Morning Context, expanded
4. Day-specific controls allowed by current entitlement and mode
```

The expanded Day Detail version may sit inside the same glass card as additional controls, but the shared context summary zone must remain reusable and must not be re-authored separately.

### 3.3 Future selected-day surfaces

Future surfaces may reuse the compact or expanded module if they can consume the same presentation payload. They must not create their own day-meaning resolver.

---

## 4. Presentation modes

### 4.1 Compact mode

Used on Home.

Compact mode contains, at most:

```text
primary title
one short body line
optional inline chips, usually 0-3 visible chips
optional subtle chevron or tap target if the module routes to Day Detail
```

Compact mode should avoid multi-paragraph text.

Recommended examples:

```text
Dhul Hijjah opportunity
You have not planned Suhoor for this morning.
```

```text
Qada fast planned
This day also has a White Days opportunity.
```

```text
Ramadan day 8
The fasting purpose is Ramadan and is locked.
```

### 4.2 Expanded mode

Used on Day Detail.

Expanded mode may contain:

```text
primary title
body line
supporting line, when useful
inline opportunity / purpose chips
contextual note, when an override or forbidden state needs clarity
optional control zone supplied by the Day Detail spec
```

Expanded mode may show more chips than compact mode, but should still avoid an educational article.

### 4.3 Same data, different density

Compact and expanded mode MUST consume the same underlying `PrimaryMorningContextPresentation` payload.

Expanded mode may reveal additional fields that are hidden in compact mode, but it must not change the meaning of the selected date.

---

## 5. Source data contract

### 5.1 Required inputs

The presentation builder SHALL receive a resolved date and wake context from the canonical morning spine.

Conceptual input:

```swift
struct PrimaryMorningContextInput: Equatable, Sendable {
    let dateKey: String
    let resolvedDayPurpose: ResolvedDayPurpose
    let resolvedMorningWakeState: ResolvedMorningWakeState
    let sharedTagPresentation: SharedDayTagPresentationSnapshot
    let datePresentation: DayDatePresentation?
    let entitlementContext: EntitlementPresentationContext?
    let locale: Locale
    let calendarDisplayContext: CalendarDisplayContext
}
```

`EntitlementPresentationContext` may affect whether a control or call-to-action is available, but it must not change the underlying day meaning.

### 5.2 Presentation output

Conceptual output:

```swift
struct PrimaryMorningContextPresentation: Equatable, Sendable {
    let dateKey: String
    let displayModeAvailability: DisplayModeAvailability
    let primaryKind: PrimaryMorningContextKind
    let title: String
    let body: String?
    let supportingLine: String?
    let compactChips: [SharedDayTagPresentation]
    let expandedChips: [SharedDayTagPresentation]
    let quietOverlayText: String?
    let overrideText: String?
    let unavailableReasonText: String?
    let actionHint: String?
    let accessibilityLabel: String
    let accessibilityValue: String?
}
```

### 5.3 Display mode availability

```swift
enum DisplayModeAvailability: Equatable, Sendable {
    case visible
    case hiddenBecauseOrdinaryDefault
    case hiddenBecauseHostSurfaceUnavailable
}
```

Home may use `hiddenBecauseOrdinaryDefault`. Day Detail should normally show the module for every selected date.

### 5.4 Primary context kind

```swift
enum PrimaryMorningContextKind: Equatable, Sendable {
    case unavailable
    case forbiddenFastingDay
    case ramadan
    case selectedFastingPurpose
    case selectedSunnahOpportunity
    case selectedVoluntaryFast
    case selectedQadaOrObligatoryMakeup
    case opportunityOnly
    case quietMeaningfulDay
    case quietOrdinaryDay
    case ordinaryFajr
}
```

The exact Swift enum may differ, but the presentation layer must preserve these distinctions.

---

## 6. Ownership boundary with the Hero

### 6.1 Hero owns wake execution

The Hero owns:

- wake time;
- primary wake/quiet state;
- wake relation/status line;
- boundary visual;
- quick selector;
- relation copy such as `Wake up 30 min before Fajr ends`;
- quiet primary state copy such as `Quiet mode` and the Hero's no-alarm relation/status line.

### 6.2 Primary Morning Context owns day meaning

The Primary Morning Context owns:

- Ramadan / Eid / forbidden-day meaning;
- Sunnah opportunity meaning;
- selected fasting-purpose meaning;
- override meaning;
- quiet overlay on a meaningful day;
- opportunity-only explanation;
- no-opportunity explanation in Day Detail;
- selected fast purpose versus available opportunity distinction.

### 6.3 Anti-redundancy rules

The Primary Morning Context MUST NOT duplicate Hero mechanics.

Do not show these lines in the context module:

```text
Wake up 30 min before Fajr ends
Wake up 30 min before Fajr begins
Wake up as Fajr begins
Wake up as Fajr ends
No alarm will ring for tomorrow
No alarm will ring for today
```

Allowed quiet context copy is meaning-oriented, not wake-mechanic-oriented:

```text
This morning is kept quiet.
This day is still recognized as Arafah.
You kept this meaningful morning quiet.
```

Do not use `No alarm will ring...` in the context module when the Hero already says it nearby.

---

## 7. Copy precedence

The presentation builder SHALL choose a primary context in this order:

1. **Unavailable / conflict state** — when day meaning cannot be resolved confidently.
2. **Forbidden fasting day** — Eid or Tashreeq / app-supported fasting-forbidden state.
3. **Ramadan** — Ramadan governs over other fasting opportunities.
4. **User-selected fasting purpose** — Qada, Kaffarah, Vow, Other fast, Voluntary fast, or selected Sunnah purpose.
5. **Selected Suhoor with recognized opportunity** — user selected Suhoor and accepted one or more opportunity-based purposes.
6. **Opportunity-only meaningful day** — opportunity exists, but user has not selected Suhoor / fast purpose.
7. **Quiet overlay** — modifies the selected meaning but does not erase it.
8. **Ordinary default Fajr** — no recognized opportunity or selected user meaning.

Quiet is a modifier over meaning. If a date is both meaningful and Quiet, the module should preserve the day meaning and mention quiet secondarily.

Bad:

```text
Quiet morning
```

Better:

```text
Arafah recognized
You kept this morning quiet.
```

---

## 8. Visibility rules

### 8.1 Home compact visibility

Home compact mode SHOULD be visible when at least one of the following is true:

- the date has a recognized non-ordinary opportunity that should be surfaced;
- the date is Ramadan;
- the date is forbidden for fasting / Eid;
- the user selected Suhoor;
- the user selected a specific fasting purpose;
- the user selected Quiet;
- the user overrode the suggested/available opportunity;
- day-context data is unavailable or conflicting in a way the user should know.

Home compact mode MAY be hidden when:

- the date is an ordinary default Fajr morning;
- there is no selected override;
- there is no special opportunity;
- there is no relevant unavailable-data state;
- the Hero already sufficiently explains the ordinary wake execution.

### 8.2 Day Detail expanded visibility

Day Detail expanded mode SHOULD be visible for every selected date, including ordinary dates.

For ordinary dates, it may say:

```text
Regular Fajr morning
No special fasting opportunity is recognized for this day.
```

This is useful in Day Detail because the user intentionally opened a selected day and expects explanation.

---

## 9. Copy library

The examples below define approved direction. Exact copy may be polished later, but implementation should preserve the meaning and avoid Hero wake-mechanic duplication.

### 9.1 Ordinary default Fajr

Home compact:

```text
Hidden by default.
```

Day Detail expanded:

```text
Regular Fajr morning
No special fasting opportunity is recognized for this day.
```

### 9.2 Opportunity-only day

Generic:

```text
Fasting opportunity
You have not planned Suhoor for this morning.
```

Arafah:

```text
Arafah recognized
You have not planned Suhoor for this morning.
```

Ashura:

```text
Ashura recognized
You have not planned Suhoor for this morning.
```

Dhul Hijjah:

```text
Dhul Hijjah opportunity
You have not planned Suhoor for this morning.
```

White Days:

```text
White Days opportunity
This is one of the middle days of the Hijri month.
```

Shawwal 6:

```text
Shawwal 6 opportunity
This day can count toward your six fasts of Shawwal if you plan it that way.
```

Monday / Thursday in Day Detail:

```text
Monday fast opportunity
You have not planned Suhoor for this morning.
```

Monday / Thursday may be omitted from compact Next 7 opportunity-only rows by that surface's tag rules, but the Primary Morning Context may show it when the context module is expanded or when the date is the immediate selected morning.

### 9.3 User selected Suhoor for an opportunity

Arafah:

```text
Arafah fast planned
This morning is marked for Suhoor.
```

Dhul Hijjah:

```text
Dhul Hijjah fast planned
This morning is marked for Suhoor.
```

White Days:

```text
White Days fast planned
This morning is marked for Suhoor.
```

Shawwal 6:

```text
Shawwal fast planned
This can count toward your Shawwal fasts.
```

If progress tracking is available:

```text
Shawwal fast planned
This would be fast {n} of 6.
```

### 9.4 User selected Suhoor without a specific opportunity

```text
Voluntary fast planned
This morning is marked for Suhoor.
```

### 9.5 User selected Qada on an opportunity day

```text
Qada fast planned
This day also has a White Days opportunity.
```

If explicit override language is needed:

```text
Qada fast planned
This day also has a White Days opportunity, but this fast is marked as Qada.
```

### 9.6 User selected Kaffarah / Vow / Other fast

```text
Kaffarah fast planned
This day also has a Sunnah fasting opportunity.
```

```text
Vow fast planned
This morning is marked for Suhoor.
```

```text
Other fast planned
This day also has a Dhul Hijjah opportunity.
```

### 9.7 User selected personal/voluntary override on an opportunity day

```text
Voluntary fast planned
This day also has an Arafah opportunity.
```

or, when the UI needs to emphasize the user's classification:

```text
Personal fast planned
This day has an Arafah opportunity, but you marked this as a personal fast.
```

Use `Personal fast` only if the product taxonomy supports that visible label. Otherwise use `Voluntary fast` or `Other fast` consistently with the fasting taxonomy.

### 9.8 Ramadan

```text
Ramadan day {n}
The fasting purpose is Ramadan and is locked.
```

Alternative when Hijri day is preferred:

```text
{n} Ramadan
The fasting purpose is Ramadan and is locked.
```

If the user selected Quiet during Ramadan:

```text
Ramadan day {n}
This morning is kept quiet, but the Ramadan context remains locked.
```

Do not present other Sunnah opportunity alternatives during Ramadan.

### 9.9 Eid / forbidden fasting day

```text
Eid morning
Fasting is not offered for this day.
```

Tashreeq / other supported forbidden days:

```text
Fasting unavailable
Fasting is not offered for this day.
```

If the user has an invalid legacy or restored fast selection on a forbidden day:

```text
Fasting unavailable
This saved fast cannot be used on this day.
```

The exact handling of legacy invalid state belongs to Day Purpose and mutation contracts; this module only displays the resolved result.

### 9.10 Quiet overlay

Ordinary quiet:

```text
Quiet morning
This morning is kept quiet.
```

Meaningful quiet:

```text
Dhul Hijjah opportunity
This morning is kept quiet, but the opportunity is still recognized.
```

Ramadan quiet:

```text
Ramadan day {n}
This morning is kept quiet, but the Ramadan context remains locked.
```

Do not say `No alarm will ring...` in the context module when the Hero already owns that nearby.

### 9.11 Missing or uncertain context

If prayer data exists but day-context data is unavailable:

```text
Fajr morning
Additional day context is unavailable right now.
```

If the date cannot be resolved enough to know whether opportunities exist:

```text
Day context unavailable
Subh cannot confirm fasting opportunities for this morning yet.
```

Do not say there are no opportunities when the opportunity resolver failed.

---

## 10. Chips and tags

### 10.1 Shared tag contract

All chips rendered by this module SHALL come from `subh-shared-day-tag-presentation-contract-v1.md` or the implementation equivalent of that shared contract.

The Primary Morning Context module MUST NOT create its own tag vocabulary or compatibility rules.

### 10.2 Compact chip rules

Home compact mode SHOULD show 0-3 chips when they add value.

Recommended compact chips:

```text
[Arafah]
[Dhul Hijjah]
[White Days]
[Shawwal 6]
[Qada]
[Ramadan]
[Voluntary]
[Quiet]
```

Compact mode SHOULD NOT show redundant mode chips when the Hero selector directly above already shows the selected mode clearly.

For example, below a Hero with `Suhoor` selected, the context module may show:

```text
[Qada] [White Days]
```

instead of:

```text
[Suhoor] [Qada] [White Days]
```

### 10.3 Expanded chip rules

Day Detail expanded mode may show more chips and may group them visually or semantically.

Recommended group names for accessibility or hidden structure:

```text
Day meaning
Selected purpose
Status
```

Visible group headings are optional and should not make the module feel like a settings list.

### 10.4 Tags are not analytics truth

The presentation module's chips are UI metadata only. Analytics, completion, and credit must use `ResolvedDayPurpose.analyticsCredits` or equivalent domain outputs.

---

## 11. Ramadan rules

Ramadan is the governing context.

Rules:

- Ramadan suppresses alternative Sunnah opportunity copy on the same date.
- Ramadan fast purpose is locked unless a future exception-handling spec defines valid non-fasting cases.
- The module may show Ramadan day number if available.
- The module must not invite the user to choose Arafah, White Days, Monday/Thursday, Shawwal 6, Voluntary, Qada, Vow, Kaffarah, or Other fast as an alternative Ramadan purpose.
- Quiet can suppress the morning wake, but it must not unlock or erase the Ramadan context.

---

## 12. Multiple opportunity rules

When multiple opportunities exist, the module SHALL choose a primary opportunity from the resolved opportunity priority supplied by Day Purpose / the shared tag contract.

The module MUST NOT recompute compatibility.

Recommended primary ordering for copy, assuming the engine marks all as valid:

1. Ramadan
2. Eid / forbidden fasting state
3. Arafah
4. Ashura
5. Dhul Hijjah first nine
6. Shawwal 6
7. White Days
8. Monday / Thursday
9. General voluntary / permissible fast

Secondary opportunities may appear in supporting copy:

```text
This also falls on a Monday.
```

```text
This day also has a White Days opportunity.
```

Avoid dumping every opportunity into the title.

---

## 13. Override and classification rules

### 13.1 User-selected purpose wins for purpose copy

If the user selects Qada, Vow, Kaffarah, Other fast, or Voluntary fast, the module title should use the selected purpose, not the highest available opportunity.

Example:

```text
Qada fast planned
This day also has an Arafah opportunity.
```

Not:

```text
Arafah fast planned
```

unless the selected fast is actually linked to Arafah.

### 13.2 Opportunities remain visible as context

A user-selected purpose does not erase day meaning.

If a selected Qada fast falls on a White Day, the White Day opportunity may still be mentioned as contextual information, but the selected fast remains Qada.

### 13.3 Credits are separate

The module must not imply analytics credit unless the resolved purpose explicitly credits it.

Bad:

```text
Qada fast planned — also counts as White Days.
```

Allowed only if a future domain rule explicitly supports secondary credit.

Better:

```text
Qada fast planned
This day also has a White Days opportunity.
```

---

## 14. Entitlement and paywall boundary

Entitlement may affect controls and routing, but it must not change resolved day meaning.

Rules:

- A Free or Plus user may still have underlying recognized opportunities in the resolver.
- If a Plus-only durable history, insight, Qada, export/sync, or advanced accountability action is selected, the module may show a paid-layer affordance according to the pricing spec.
- The module must not pretend an opportunity does not exist simply because the user cannot activate it under the current tier.
- The module must not create a paid-tier-only day resolver.

Suggested compact informational copy, if needed:

```text
Arafah recognized
Suhoor is available for this morning.
```

Only use paywall-oriented copy when the pricing spec explicitly allows it for this surface.

---

## 15. Accessibility

The module SHALL expose an accessibility label that combines:

1. primary title;
2. body text;
3. selected purpose, if any;
4. relevant opportunities;
5. quiet overlay, if any;
6. unavailable/forbidden state, if any.

Accessibility MUST NOT require the user to inspect visible chips individually to understand the meaning.

Example:

```text
Qada fast planned. This day also has a White Days opportunity.
```

For compact mode with hidden extra chips, accessibility should include hidden supported details when they are relevant:

```text
Dhul Hijjah opportunity. This day also falls on Monday. You have not planned Suhoor for this morning.
```

Dynamic Type must not clip title, body, or chips. If compact mode cannot preserve readable chips, it should hide less important chips before clipping text.

---

## 16. Interaction behavior

### 16.1 Home compact module

The Home compact module may be tappable. If tappable, it should route to the same selected-day Day Detail as tapping the immediate morning / row route.

Home compact tap MUST NOT directly mutate wake mode, fasting purpose, or Quiet state.

### 16.2 Day Detail expanded module

Day Detail expanded mode may include or sit above controls that mutate:

- quick wake mode;
- fasting purpose;
- valid override classification;
- eligible adhan toggle;
- reset.

Those mutations must use the shared Quick Wake Mode and Intent Mutation Contract. The context summary itself remains read-only presentation.

### 16.3 No surprise navigation from chips

Inline chips should not independently navigate unless a later spec deliberately defines chip-specific education or filtering behavior. The MVP chip behavior is display-only.

---

## 17. QA scenarios

### Scenario PMC-001: Ordinary Home default hides context

- **GIVEN** the target morning is ordinary Fajr
- **AND** there is no recognized opportunity
- **AND** the user has not selected Suhoor, Quiet, or a custom purpose
- **WHEN** Home renders
- **THEN** the Primary Morning Context module MAY be hidden
- **AND** the Hero remains the immediate wake-execution answer.

### Scenario PMC-002: Ordinary Day Detail explains absence of opportunity

- **GIVEN** the selected date is ordinary Fajr
- **AND** the user opens Day Detail
- **WHEN** the expanded Primary Morning Context renders
- **THEN** it SHALL indicate that no special fasting opportunity is recognized for this day.

### Scenario PMC-003: Dhul Hijjah opportunity agrees across surfaces

- **GIVEN** a date is within the supported first nine days of Dhul Hijjah
- **AND** the user has not selected Suhoor
- **WHEN** Home, Next 7 Mornings, and Day Detail render the same date
- **THEN** each surface SHALL consume the same resolved opportunity
- **AND** none of them SHALL infer a planned fast from the opportunity alone
- **AND** Day Detail SHALL not omit the opportunity if Next 7 Mornings shows it.

### Scenario PMC-004: Opportunity-only does not duplicate Hero mechanics

- **GIVEN** the Hero relation line says `Wake up 30 min before Fajr ends`
- **AND** the date has an Arafah opportunity
- **WHEN** the Primary Morning Context renders
- **THEN** it SHALL explain Arafah / opportunity meaning
- **AND** it SHALL NOT repeat the Hero wake relation line.

### Scenario PMC-005: Suhoor selected for opportunity

- **GIVEN** the date has an Arafah opportunity
- **AND** the user selects Suhoor for Arafah
- **WHEN** the Primary Morning Context renders
- **THEN** it SHOULD say `Arafah fast planned` or equivalent
- **AND** it SHOULD say the morning is marked for Suhoor
- **AND** it SHALL NOT calculate wake timing locally.

### Scenario PMC-006: Qada selected on White Day

- **GIVEN** the date is a White Day
- **AND** the user selected Qada
- **WHEN** the module renders
- **THEN** the title SHALL prioritize Qada
- **AND** the White Day opportunity may appear as secondary context
- **AND** the module SHALL NOT imply White Day completion credit unless the domain layer explicitly emits it.

### Scenario PMC-007: Ramadan suppresses alternative opportunity presentation

- **GIVEN** the date is Ramadan
- **WHEN** the module renders
- **THEN** the module SHALL present Ramadan as the governing context
- **AND** it SHALL not present other Sunnah opportunities as selectable alternatives.

### Scenario PMC-008: Quiet preserves meaning

- **GIVEN** the date has a Dhul Hijjah opportunity
- **AND** the user selects Quiet
- **WHEN** the module renders
- **THEN** the module SHALL preserve Dhul Hijjah meaning
- **AND** it MAY say the morning is kept quiet
- **AND** it SHALL NOT erase the opportunity.

### Scenario PMC-009: Unknown context does not become no-opportunity

- **GIVEN** prayer time exists
- **AND** day-purpose / Hijri context cannot be resolved
- **WHEN** the module renders
- **THEN** it SHALL say context is unavailable
- **AND** it SHALL NOT say there are no fasting opportunities.

### Scenario PMC-010: Chips are not source of truth

- **GIVEN** chips fail to render due to compact layout
- **WHEN** accessibility and detail presentation are inspected
- **THEN** full day meaning SHALL still be available from the underlying presentation payload
- **AND** analytics SHALL not depend on visible chips.

---

## 18. Implementation guidance

Recommended first implementation slice:

1. Add a `PrimaryMorningContextPresentationBuilder` that consumes `ResolvedDayPurpose`, `ResolvedMorningWakeState`, and the shared tag presentation snapshot.
2. Add a compact Home module below the Hero.
3. Replace the Day Detail context summary with the same shared component in expanded mode.
4. Preserve existing Day Detail controls, but move control-specific copy beneath the shared summary zone.
5. Add regression tests for Dhul Hijjah, White Days, Arafah, Ashura, Ramadan, Qada override, Quiet overlay, and unavailable context.
6. Do not modify prayer-time, delivery, final-third, or observance compatibility logic.

---

## 19. Final acceptance checklist

- [ ] Home can render the compact Primary Morning Context below the Hero.
- [ ] Day Detail can render the expanded Primary Morning Context from the same payload.
- [ ] The module does not duplicate Hero wake relation copy.
- [ ] The module does not create or infer observance opportunities locally.
- [ ] The module does not infer user intention from visible tags.
- [ ] Ordinary Home default may hide the module.
- [ ] Ordinary Day Detail still explains the absence of recognized opportunity.
- [ ] Ramadan is governing and locked.
- [ ] Eid / forbidden fasting days do not offer normal fasting planning.
- [ ] Qada/obligatory makeup purpose wins title copy over secondary opportunities.
- [ ] Quiet modifies but does not erase underlying meaning.
- [ ] Dhul Hijjah / Arafah / Ashura / White Days / Shawwal 6 opportunities appear consistently where the resolved day-purpose layer says they exist.
- [ ] Monday/Thursday can appear in Day Detail / expanded context even when compact Next 7 suppresses opportunity-only Monday/Thursday tags.
- [ ] Chips use the shared tag presentation contract.
- [ ] Accessibility exposes the full meaning even when compact chips are suppressed.
