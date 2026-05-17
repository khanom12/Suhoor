# Subh Shared Day Tag Presentation Contract

| Field | Value |
| --- | --- |
| Canonical filename | `subh-shared-day-tag-presentation-contract-v1.md` |
| Version | 1 |
| Spec status | Draft; proposed canonical shared presentation contract |
| Date | 2026-05-17 |
| Supersedes | None |
| Related specs | `00-subh-spec-index-v2.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-primary-morning-context-presentation-spec-v1.md`, `subh-next-7-days-wake-forecast-spec-v1.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-weekly-fajrcast-card-spec-v14.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md` |
| Owning domain / surface | Shared tag/chip presentation across Home, Next 7 Days, Day Detail, Primary Morning Context, and supporting forecast surfaces |
| Implementation audit status | Needs implementation audit |

## Purpose

Define one shared presentation contract for Subh day tags and chips so that surfaces do not independently invent labels, infer intention from strings, duplicate opportunity compatibility logic, or drift from the canonical day-purpose layer.

This contract stabilizes how Subh presents:

- wake-mode state chips;
- fasting-opportunity chips;
- selected fasting-purpose chips;
- quiet / locked / unavailable modifiers;
- surface-specific suppression rules.

## What This Spec Owns

- Shared tag family definitions.
- Tag labels for MVP presentation.
- Tag source-of-truth rules.
- Surface-specific tag behavior for Primary Morning Context, Next 7 Days, Alarm Detail, and Weekly Fajrcast support text.
- Tag precedence and suppression rules.
- Rules for opportunity-only versus intended Suhoor / fasting-purpose states.
- Accessibility behavior for visible and hidden tags.

## What This Spec Does Not Own

- Observance opportunity derivation.
- Fasting-purpose compatibility logic.
- Fiqh/observance overlap rules.
- Analytics credit.
- Completion counting.
- Wake-time calculation.
- Alarm scheduling.
- Exact visual styling for every chip surface.

## Normative Requirements

The normative requirements in this spec are the explicit MUST, SHALL, MUST NOT, SHOULD, and acceptance criteria below.

---

## 1. One-sentence definition

**Shared Day Tags are presentation metadata derived from canonical day-purpose and wake-state outputs; they summarize day meaning, selected purpose, and surface state without becoming the source of truth for intention, compatibility, scheduling, or analytics.**

---

## 2. Integrity guardrail

Tags are presentation.

Tags MUST NOT be used as the authoritative source for:

- whether a fast is intended;
- whether Suhoor is active;
- whether a day is scheduled;
- whether a fast was completed;
- whether a completion receives observance credit;
- whether an opportunity can coexist with another opportunity;
- whether Ramadan suppresses alternatives;
- whether a day is forbidden for fasting.

Those decisions belong to:

```text
ResolvedDayPurpose
ResolvedMorningWakeState
DayPurposeResolver
MorningFastDomain / compatibility engine
Completion and credit resolvers
Quick Wake Mode and Intent Mutation Contract
```

A visible tag is never a resolver input. It is a resolver output.

---

## 3. Input contract

Conceptual input:

```swift
struct SharedDayTagInput: Equatable, Sendable {
    let dateKey: String
    let resolvedDayPurpose: ResolvedDayPurpose
    let resolvedMorningWakeState: ResolvedMorningWakeState
    let completionContext: CompletionPresentationContext?
    let surface: SharedDayTagSurface
    let entitlementContext: EntitlementPresentationContext?
    let locale: Locale
}
```

Surface controls what is visible, not what exists:

```swift
enum SharedDayTagSurface: Equatable, Sendable {
    case nextSevenDaysCompactRow
    case primaryMorningContextCompact
    case primaryMorningContextExpanded
    case alarmDetailContext
    case weeklyFajrcastFooterContext
    case accessibilityOnly
}
```

---

## 4. Output contract

Conceptual output:

```swift
struct SharedDayTagPresentationSnapshot: Equatable, Sendable {
    let dateKey: String
    let surface: SharedDayTagSurface
    let visibleTags: [SharedDayTagPresentation]
    let hiddenTags: [SharedDayTagPresentation]
    let suppressedTags: [SuppressedSharedDayTag]
    let accessibilitySummary: String
}
```

```swift
struct SharedDayTagPresentation: Equatable, Identifiable, Sendable {
    let id: String
    let family: SharedDayTagFamily
    let semanticKind: SharedDayTagSemanticKind
    let label: String
    let shortLabel: String?
    let prominence: SharedDayTagProminence
    let sourceOpportunityIDs: [String]
    let sourceIntentionIDs: [String]
    let isUserSelected: Bool
    let isOpportunityOnly: Bool
    let accessibilityLabel: String
}
```

```swift
enum SharedDayTagFamily: String, Sendable {
    case wakeMode
    case opportunity
    case fastingPurpose
    case calendarContext
    case statusModifier
}
```

```swift
enum SharedDayTagProminence: String, Sendable {
    case primary
    case secondary
    case quiet
    case subdued
}
```

---

## 5. Tag families

### 5.1 Wake-mode tags

Wake-mode tags describe the resolved top-level user wake mode.

MVP wake-mode labels:

```text
[Suhoor]
[Fajr]
[Quiet]
```

Rules:

- `Suhoor` is the only exposed before-Fajr wake-mode tag in MVP.
- Do not show `Pre-Fajr`, `Fast`, `Early`, `Tahajjud only`, or `Other early worship` as active MVP wake-mode tags.
- Wake-mode tags are useful in compact list/forecast rows.
- Wake-mode tags may be omitted from the Primary Morning Context when the Hero selector directly above already shows the selected mode.

### 5.2 Opportunity tags

Opportunity tags describe date meaning that exists whether or not the user selected it.

Supported opportunity labels include:

```text
[Arafah]
[Ashura]
[Dhul Hijjah]
[White Days]
[Shawwal 6]
[Monday fast]
[Thursday fast]
```

Surface-specific short labels may be used where approved:

```text
[Mon/Thu]
[Shawwal 6]
```

Rules:

- Opportunity tags do not imply Suhoor.
- Opportunity tags do not imply fasting intention.
- Opportunity tags do not imply missed fasts.
- Opportunity tags do not imply analytics credit beyond opportunity availability.
- Opportunity-only dates may still be ordinary Fajr wake days.

### 5.3 Fasting-purpose tags

Fasting-purpose tags describe what the user selected or what the resolved domain layer locked.

Supported labels include:

```text
[Ramadan]
[Qada]
[Vow]
[Kaffarah]
[Voluntary]
[Other fast]
```

If the selected purpose is a Sunnah opportunity, the purpose may be represented by the opportunity tag plus a selected-state source. For example:

```text
[Suhoor] [Arafah]
```

means the user is in Suhoor and the selected purpose links to Arafah.

### 5.4 Calendar-context / forbidden tags

Forbidden or unavailable context may use:

```text
[Eid]
[Fasting unavailable]
```

Rules:

- Eid / forbidden fasting state suppresses normal fast-planning chips.
- It may coexist with `Fajr` in compact contexts only if the surface needs to show the wake anchor.
- The Primary Morning Context should usually explain forbidden state in text rather than relying on chips alone.

### 5.5 Status modifier tags

Status tags describe modifiers rather than day meaning.

Possible labels:

```text
[Locked]
[Override]
[Quiet]
[Unavailable]
[Completed]
```

Rules:

- Use status tags sparingly.
- Do not use `[Override]` without explanatory copy.
- Do not use `[Completed]` for future planning rows unless the surface is explicitly historical or progress-oriented.
- Do not use status tags as a substitute for domain state.

---

## 6. MVP vocabulary alignment

The active MVP wake-mode vocabulary is:

```text
Suhoor | Fajr | Quiet
```

This contract supersedes lower inherited examples that present these as active MVP user-selectable tag/state labels:

```text
Pre-Fajr
Fast as top-level wake mode
Early
Tahajjud only
Other early worship
Fasting + Tahajjud
```

Legacy values may remain in decoding, migration, archived examples, or post-MVP deferred sections, but active MVP tag output should normalize them away from user-facing presentation.

---

## 7. Opportunity versus intention rules

### 7.1 Opportunity-only

When a date has an opportunity and the user has not selected Suhoor or a fasting purpose:

- The opportunity may be shown as an opportunity tag.
- The wake mode remains Fajr unless another resolved state applies.
- The app must not show a selected fasting-purpose tag.

Examples:

```text
[Fajr] [Arafah]
[Fajr] [Dhul Hijjah]
[Fajr] [White Days]
[Fajr] [Shawwal 6]
```

### 7.2 Suhoor selected for opportunity

When the user selects Suhoor and the purpose links to one or more applicable opportunities:

```text
[Suhoor] [Arafah]
[Suhoor] [Dhul Hijjah]
[Suhoor] [White Days]
[Suhoor] [Shawwal 6]
```

The tag output must show that the day is no longer merely opportunity-only.

### 7.3 Suhoor selected without specific opportunity

When Suhoor is selected and no specific opportunity exists:

```text
[Suhoor] [Voluntary]
```

### 7.4 Selected Qada or other purpose on opportunity day

When the selected purpose differs from the available opportunity:

```text
[Suhoor] [Qada] [White Days]
[Suhoor] [Vow] [Arafah]
[Suhoor] [Other fast] [Dhul Hijjah]
```

Surface-specific rules may suppress the secondary opportunity chip in compact layouts, but accessibility and expanded context should preserve it.

### 7.5 Ramadan

When the date resolves to Ramadan:

```text
[Ramadan]
```

Rules:

- Ramadan normally replaces other opportunity tags.
- Do not show `[Suhoor] [Ramadan]` in compact rows unless a later surface-specific design requires both.
- Do not show other Sunnah opportunity tags as alternatives during Ramadan.
- The locked nature of Ramadan may be conveyed through text or `[Locked]` in expanded contexts.

### 7.6 Quiet

Quiet behavior is surface-specific.

Compact forecast rows may show only:

```text
[Quiet]
```

Primary Morning Context should preserve meaning in text and may omit or include `[Quiet]` depending on space.

Rules:

- Quiet does not delete underlying opportunity or selected purpose.
- Compact rows may suppress other tags to keep the state clear.
- Expanded context and accessibility should preserve underlying meaning when relevant.

---

## 8. Surface-specific behavior

### 8.1 Next 7 Days compact row

Purpose:

```text
Date label | compact tag cluster | wake time/status
```

Rules:

- Use compact tags.
- Cap visible tags according to the Next 7 Days spec.
- Do not wrap tags.
- Do not show explanatory prose.
- Do not infer tags locally in the SwiftUI row.
- Use `[Suhoor]`, `[Fajr]`, and `[Quiet]` as MVP wake-mode state chips unless the existing implementation is intentionally retained under a migration compatibility note.
- Opportunity-only rows show `[Fajr]` plus approved opportunity tags.
- Selected Suhoor rows show `[Suhoor]` plus selected purpose/opportunity tags.
- Quiet rows may show `[Quiet]` only in compact mode.
- Ramadan compact rows show `[Ramadan]` only unless a later revision approves `[Suhoor] [Ramadan]`.

Migration note:

Older Next 7 prose used `[Fasting]` as a compact planned-fast tag. For MVP Suhoor alignment, `[Fasting]` should be interpreted as a legacy planned-fasting presentation label and should not be used as the top-level wake-mode tag. The preferred MVP compact wake-mode tag is `[Suhoor]`.

### 8.2 Primary Morning Context compact

Rules:

- The context module may omit wake-mode chips if the Hero selector already shows the mode.
- Prefer opportunity and selected-purpose chips over repeating `[Suhoor]` / `[Fajr]`.
- Show chips only when they add meaning to the title/body.
- Allow the text to carry most of the meaning.

Examples:

```text
Title: Qada fast planned
Body: This day also has a White Days opportunity.
Chips: [Qada] [White Days]
```

```text
Title: Arafah recognized
Body: You have not planned Suhoor for this morning.
Chips: [Arafah]
```

### 8.3 Primary Morning Context expanded / Alarm Detail context

Rules:

- Show more complete opportunity and selected-purpose chips.
- Monday/Thursday opportunity may appear when applicable.
- Chips may wrap naturally if the layout supports it.
- Use inline chips integrated into the sentence when possible.
- Do not show empty chip rows.
- Do not show source/provenance/diagnostic chips.

### 8.4 Weekly Fajrcast footer/context

Rules:

- Weekly Fajrcast may surface week-level opportunity context if the chart spec allows it.
- It should not become a tag-heavy surface.
- It must not imply a planned Suhoor wake from opportunity-only dates.
- It must use the same resolved opportunity/tag payload as Next 7 Days for the same visible date set.

---

## 9. Suppression rules

### 9.1 Ramadan suppression

Ramadan suppresses alternative opportunity tags in active MVP surfaces.

Visible compact:

```text
[Ramadan]
```

Expanded text may explain Ramadan is locked.

### 9.2 Forbidden fasting suppression

Eid / Tashreeq / app-supported forbidden fasting states suppress normal fasting-purpose controls and normal opportunity selection.

Recommended visible labels:

```text
[Eid]
[Fasting unavailable]
```

### 9.3 Qada / obligatory purpose suppression

Qada, Kaffarah, and Vow are primary selected purposes.

They do not erase secondary opportunity context, but they suppress automatic secondary credit unless the Day Purpose layer explicitly supports that credit.

### 9.4 Shawwal 6 completion-aware suppression

Do not show `[Shawwal 6]` when the completion-aware resolver says the six Shawwal fasts are complete.

Do not infer Shawwal completion from fasts completed during Shawwal unless they were intended/tracked as Shawwal 6.

### 9.5 Monday/Thursday compact suppression

Monday/Thursday should not appear as a mere opportunity-only tag in compact Next 7 Days rows.

It may appear:

- when intended;
- in expanded Primary Morning Context;
- in Alarm Detail context;
- in accessibility if useful and not misleading.

### 9.6 Quiet compact suppression

Compact row surfaces may show `[Quiet]` only and hide all other tags.

Expanded context must preserve underlying meaning in text when meaningful.

---

## 10. Priority rules

Default shared priority for visible tags:

1. Quiet compact override, for compact row surfaces only.
2. Ramadan.
3. Eid / fasting unavailable.
4. Suhoor selected state.
5. Selected obligatory/makeup purpose: Qada, Kaffarah, Vow.
6. Selected Sunnah opportunity purpose: Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6, Monday/Thursday.
7. Selected Voluntary / Other fast purpose.
8. Fajr anchor with opportunity-only context.
9. Opportunity-only tags.
10. Fajr fallback.
11. Status modifiers, only if space and context require them.

Surface-specific specs may adjust visibility but must not alter domain meaning.

---

## 11. Accessibility

The shared tag snapshot SHALL expose an accessibility summary that includes:

- visible tags;
- suppressed but meaningful tags when they are relevant to the user;
- distinction between opportunity-only and selected purpose;
- quiet overlay meaning where applicable;
- Ramadan locked context where applicable.

Examples:

```text
Fajr morning with Arafah opportunity. Fast not planned.
```

```text
Suhoor planned for Qada. This day also has a White Days opportunity.
```

```text
Ramadan day. Ramadan fasting purpose is locked.
```

Accessibility must not require parsing chip order to understand intention.

---

## 12. Visual treatment principles

This contract does not define exact chip geometry for every surface. However, all chips should generally be:

- compact;
- text-first;
- calm;
- premium;
- restrained;
- readable in light/dark mode;
- non-bouncy;
- not icon-dependent;
- consistent with the liquid-glass direction.

Compact rows should use compact chip padding and avoid excessive capsule padding that causes valid two-tag rows to collapse.

---

## 13. QA scenarios

### Scenario SDT-001: Opportunity-only Arafah

- **GIVEN** the date has an Arafah opportunity
- **AND** the user has not selected Suhoor
- **WHEN** tags are resolved for Next 7 Days
- **THEN** the row may show `[Fajr] [Arafah]`
- **AND** it SHALL NOT show `[Suhoor]`
- **AND** it SHALL NOT show `[Fasting]` as a selected intent.

### Scenario SDT-002: Suhoor selected for Arafah

- **GIVEN** the date has an Arafah opportunity
- **AND** the user selected Suhoor for Arafah
- **WHEN** tags are resolved
- **THEN** selected-state surfaces SHOULD show `[Suhoor] [Arafah]` or equivalent
- **AND** accessibility SHALL say Arafah fast is planned.

### Scenario SDT-003: Qada on White Day

- **GIVEN** the date is a White Day
- **AND** the user selected Qada
- **WHEN** tags are resolved
- **THEN** compact surfaces may show `[Suhoor] [Qada] [White Days]` or suppress `[White Days]` if space constrained
- **AND** expanded context SHALL preserve the White Days opportunity
- **AND** analytics SHALL not infer White Days completion credit from the chip.

### Scenario SDT-004: Ramadan

- **GIVEN** the date is Ramadan
- **WHEN** tags are resolved
- **THEN** compact row surfaces SHALL show `[Ramadan]` only unless a later approved surface spec says otherwise
- **AND** no alternative Sunnah opportunity tags SHALL be presented as selectable alternatives.

### Scenario SDT-005: Quiet on meaningful day

- **GIVEN** the date has a Dhul Hijjah opportunity
- **AND** the user selects Quiet
- **WHEN** tags are resolved for compact Next 7 Days
- **THEN** the row may show `[Quiet]` only
- **WHEN** Primary Morning Context renders expanded
- **THEN** it SHALL still explain the Dhul Hijjah opportunity in text or accessibility.

### Scenario SDT-006: Monday opportunity in compact row

- **GIVEN** the date is Monday
- **AND** no fast is intended
- **WHEN** Next 7 Days compact row tags are resolved
- **THEN** the row SHALL NOT show `[Mon/Thu]` merely as an opportunity
- **AND** it may fall back to `[Fajr]`
- **WHEN** Day Detail context renders
- **THEN** it may show a Monday fast opportunity.

### Scenario SDT-007: No string parsing

- **GIVEN** visible label localization changes from `[Dhul Hijjah]` to another localized label
- **WHEN** compatibility and intention are resolved
- **THEN** behavior SHALL remain unchanged
- **AND** the resolver SHALL use semantic IDs, not visible strings.

### Scenario SDT-008: Hidden chip still accessible

- **GIVEN** compact layout hides a secondary opportunity chip
- **WHEN** VoiceOver reads the row or context
- **THEN** the accessibility summary SHALL preserve the hidden meaningful opportunity when relevant.

---

## 14. Implementation guidance

Recommended first implementation slice:

1. Add a shared `SharedDayTagPresentationBuilder`.
2. Feed it from `ResolvedDayPurpose` and `ResolvedMorningWakeState`.
3. Replace local tag-building logic in Next 7 Days with the shared builder.
4. Use the same builder in the Primary Morning Context module.
5. Keep existing `DayTag` and fast-domain types as inputs/compatibility layers where useful.
6. Add tests for opportunity-only, selected Suhoor, Qada override, Ramadan, Quiet, Shawwal completion, and Monday/Thursday surface-specific suppression.

Do not change prayer-time, final-third, delivery, or completion-credit logic as part of this presentation pass.

---

## 15. Final acceptance checklist

- [ ] Tags are generated from semantic resolved outputs, not strings.
- [ ] Tags do not determine intention.
- [ ] Tags do not determine compatibility.
- [ ] Tags do not determine analytics credit.
- [ ] MVP active wake-mode tags are `Suhoor`, `Fajr`, and `Quiet`.
- [ ] Legacy `Pre-Fajr`, `Fast`, `Early`, `Tahajjud only`, and `Other early worship` are not active MVP tag outputs.
- [ ] Opportunity-only days remain Fajr unless intention says otherwise.
- [ ] Selected Suhoor days visibly differ from opportunity-only days.
- [ ] Qada / Vow / Kaffarah / Other fast override opportunities without erasing opportunity context.
- [ ] Ramadan suppresses alternative opportunity presentation.
- [ ] Forbidden fasting states suppress normal fast-planning presentation.
- [ ] Compact and expanded surfaces can show different density without changing meaning.
- [ ] Accessibility preserves hidden meaningful tags.
