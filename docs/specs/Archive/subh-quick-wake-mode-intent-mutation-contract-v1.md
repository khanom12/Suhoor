# Subh Quick Wake Mode and Intent Mutation Contract

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quick-wake-mode-intent-mutation-contract-v1.md` |
| Version | 1 |
| Spec status | Persistent shared interaction contract; canonical Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v1.md`, `subh-morning-resolution-contract-state-ownership-spec-v2.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-morning-hero-item-spec-v14.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-10-mornings-wake-forecast-spec-v4.md`, `subh-weekly-fajrcast-card-spec-v13.md` |
| Owning domain / surface | Shared wake-mode and intention mutation behavior |
| Implementation audit status | Needs implementation audit |

## Purpose
Define the shared mutation contract for Suhoor, Fajr, Quiet, fasting intention, wake adjustment, audio, immediate saves, reset behavior, and cross-surface consistency.

## What This Spec Owns
- Quick wake mode semantics and state transitions.
- Date-specific override mutation, immediate save, restoration, and reset rules.
- Shared behavior that prevents Home, Alarm Detail, forecasts, and delivery from diverging.

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
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

The only exposed quick wake modes are:

```text
Suhoor | Fajr | Quiet
```

`Suhoor` replaces the older exposed `Fast`, `Pre-Fajr`, and `Early` labels. It is the only MVP user-facing before-Fajr wake mode. It means: wake before Fajr begins for suhoor/fasting.

The following are not MVP user-selectable before-Fajr intentions:

```text
Tahajjud only
Other early worship
Fasting + Tahajjud
generic Pre-Fajr without suhoor/fasting intent
```

Legacy persisted values or older internal model cases may be decoded for compatibility, but the shared mutation contract must normalize them to the MVP Suhoor path rather than re-exposing them.

Suhoor intention rules:

- Selecting `Suhoor` sets the date-specific wake mode to the before-Fajr wake regime.
- Selecting `Suhoor` sets the before-Fajr purpose to fasting/suhoor.
- The fasting intention defaults to all applicable Sunnah fasting opportunities for that date when they exist.
- If no specific opportunity exists, the fasting intention defaults to `Voluntary fast`.
- Supported explicit fasting-purpose overrides such as Qada, Vow/Nadhr, Kaffarah, and Other fast remain fasting-purpose choices, not separate wake modes.
- `Quiet` suppresses delivery while preserving the underlying Suhoor or Fajr meaning for restoration.

Day Detail persistence rules:

- MVP Day Detail edits save immediately through the shared mutation contract.
- `Reset to Defaults` applies immediately for the selected date.
- Older draft-until-Done and staged-reset requirements are superseded unless a later canonical spec deliberately reintroduces draft editing.

## 0. One-page summary

This specification defines how Subh mutates a user's wake choice for one target morning when the user selects:

```text
Suhoor | Fajr | Quiet
```

It also defines how that quick mode interacts with:

```text
Fasting intention
Quiet suppression
manual wake-time adjustment
immediate Day Detail saves
Reset to Defaults
rapid repeated taps
cross-surface consistency
scheduling handoff
```

This is a **contract**, not a new product subsystem.

It exists to prevent Home Hero, Alarm Detailed View, Next 10, Month Browsing, Adjusted Days, Morning Resolution, and Alarm Delivery from each inventing their own version of the same state transition.

The central rule is:

```text
Surfaces emit user intent commands.
The shared mutation contract normalizes those commands.
Morning Resolution resolves the final canonical morning.
Alarm Delivery schedules only the resolved, active, permitted, non-Quiet events inside the active scheduled horizon.
```

The most important separations are:

```text
Quick wake mode ≠ fasting intention ≠ manual wake adjustment ≠ Quiet suppression ≠ delivery permission.
```

Examples:

```text
Suhoor is the top-level before-Fajr wake mode for MVP.
Its purpose is suhoor/fasting, with fasting-purpose details resolved separately.

Quiet is an intentional user-selected suppression state.
It is not permission failure, missing platform delivery, or stale scheduling.

Turning off an adhan cue does not turn off the wake alarm.
Alarm off is Quiet only.

A manual drag can move wake time without changing fasting purpose.

Switching away from Suhoor preserves the underlying fasting purpose for restoration,
but does not preserve the manual wake-time adjustment.
```

---

## 1. Why this spec is needed

The current spec set already contains the right product direction, but the same interaction rules appear across multiple documents:

- Morning Hero defines the immediate Home selector.
- Alarm Detailed View defines selected-day editing.
- MVP Interaction Inventory defines scenarios for repeated taps, mode switching, Quiet, wake adjustment, Ramadan, Eid, and future edits.
- Morning Resolution owns the canonical resolved morning graph.
- Day Purpose owns opportunity, intention, completion, and credit separation.
- Alarm Delivery owns platform scheduling and reliability.
- Planning Horizon owns generated-vs-stored doctrine and future override hydration.

Without this shared contract, implementation can drift in these ways:

1. Home treats `Fasting` as a mode while Detail treats it as a reason.
2. One surface preserves the Pre-Fajr intention while another deletes it.
3. Quiet is shown as a user mode in one place and as a delivery failure in another.
4. A repeated tap creates duplicate date-specific records or duplicate scheduled events.
5. Day Detail saves immediately even though MVP requires `Done` as the commit action.
6. Reset to Defaults deletes state immediately in one flow and stages it in another.
7. A manual wake adjustment accidentally survives a mode switch.
8. Permission failure is accidentally displayed as Quiet.
9. A far-future edit is saved but does not hydrate Home or Next 10 later.
10. The scheduled alarm no longer matches the final displayed wake time.

This spec reduces complexity by creating **one small transition contract** instead of duplicating transition logic in every screen.

It does **not** require a new architectural layer if existing code can implement these rules inside current resolvers and stores.

---

## 2. What this spec is

This spec is the shared contract for:

```text
User input → normalized wake/intention mutation → date-specific user meaning → canonical morning re-resolution.
```

It owns:

- canonical quick wake mode terminology;
- legacy alias interpretation;
- Pre-Fajr intention behavior;
- fasting-intention activation behavior at the interaction boundary;
- Quiet selection and restoration behavior;
- manual wake adjustment mutation rules;
- Home immediate-commit behavior;
- Day Detail staged-draft and Done-only save behavior;
- Reset to Defaults behavior;
- idempotency and rapid interaction behavior;
- mutation command shape;
- persistence expectations for date-specific wake/intention overrides;
- cross-surface consistency after mutation;
- scheduling handoff expectations.

It does not own:

- prayer-time calculation;
- Fajr begin/end source selection;
- final-third calculation;
- observance opportunity detection;
- fasting taxonomy itself;
- Ramadan/Eid derivation;
- platform scheduling internals;
- Home Hero layout;
- Alarm Detail layout;
- Next 10 row layout;
- Weekly Fajrcast chart behavior;
- Month Browsing layout;
- completion/progress analytics UI.

---

## 3. Complexity guardrail

This spec should **not** make the software larger than necessary.

### 3.1 Do not create a second resolver

This contract should be implemented as part of, or immediately upstream of, the existing canonical morning-resolution pipeline.

Acceptable implementation patterns:

```text
Existing WakeStateSelectionResolver is updated to follow this contract.
Existing MorningWakeResolutionService is updated to follow this contract.
Existing date-specific override store is updated to persist this contract.
A small IntentMutationService is added only if it prevents duplication.
```

Unacceptable implementation patterns:

```text
Home Hero owns its own permanent state machine.
Alarm Detail owns a second permanent state machine.
Next 10 mutates wake state directly from row tags.
Delivery infers intent from scheduled platform requests.
Views calculate final-third or Fajr-end boundaries locally.
```

### 3.2 Do not create separate Quiet and Wake Adjustment specs unless needed

Earlier planning identified possible separate specs:

```text
Quiet Overlay and Restore Contract
Wake Adjustment Preview / Commit / Reset Contract
```

For MVP, this document intentionally absorbs the minimum needed rules for both areas because they are tightly coupled to quick wake mode selection.

Separate specs should be created later only if one of these becomes true:

1. Quiet becomes recurring, multi-day, schedule-based, or profile-based.
2. Wake adjustment gains multiple edit modes, exact fixed times, latest-wake caps, warnings, custom boundaries, or history/audit behavior beyond this contract.
3. Delivery diagnostics require a separate user-facing Quiet/reliability explanation framework.
4. Product wants a dedicated advanced alarm editor beyond Home Hero and Day Detail.

Until then, this single contract is enough.

---

## 4. Source documents and scenario ownership

This contract is aligned with:

| Source | Relationship |
|---|---|
| `00-subh-spec-index-v1.md` | Canonical terminology and no-functionality-loss guardrail. |
| `subh-mvp-interaction-inventory-v3.md` | MVP scenario authority and scenario IDs. |
| `subh-morning-resolution-contract-state-ownership-spec-v2.md` | Parent owner of canonical resolved morning graph. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md` | User meaning, durable future edits, generated-vs-stored doctrine. |
| `subh-day-purpose-opportunity-resolution-spec-v1.md` | Opportunity vs intention vs completion vs credit separation. |
| `subh-early-worship-boundary-spec-v1.md` | Final-third boundary for intended early worship. |
| `subh-fajr-time-calculation-determination-selection-spec-v1.md` | Prayer-window boundaries consumed by this contract. |
| `subh-alarm-delivery-schedule-reliability-spec-v2.md` | Platform scheduling and reliability after resolution. |
| `Archive/Morning_Hero_Item_Specification_v13.md` | Immediate Home quick interaction surface. |
| `Archive/alarm_detailed_view_screen_spec_v6.md` | Selected-day staged editor surface. |
| `subh-next-10-mornings-wake-forecast-spec-v4.md` | Forecast rows that route into Day Detail and hydrate after edits. |
| `subh-weekly-fajrcast-card-spec-v13.md` | Chart surface that consumes resolved wake state only. |

### 4.1 Primary MVP scenario ownership

This contract directly owns or co-owns the following MVP scenario groups:

| Group | Scenario IDs | Ownership by this contract |
|---|---:|---|
| C | S028–S034 | Fajr mode selection, idempotency, Pre-Fajr restoration, Quiet exit, alarm reactivation intent. |
| D | S035–S045 | Pre-Fajr mode and Pre-Fajr intention behavior. |
| F | S056–S062 | Quiet selection, restoration, single-date suppression, idempotency. |
| G | S063–S070 | Manual wake adjustment mutation, reset, mode-switch clearing, final displayed/scheduled matching. |
| K | S089–S109 | Day Detail editing rules at the mutation boundary, including Done-only save and Reset to Defaults. |
| AB | S226–S235 | Rapid/repeated interactions, final-state persistence, no duplicate state/scheduling. |

This contract supports, but does not fully own:

| Group | Scenario IDs | Supporting role |
|---|---:|---|
| E | S046–S055 | Activates/clears fasting intention; Day Purpose owns fasting opportunity and taxonomy rules. |
| H | S071–S073 | Keeps adhan controls out of Home and separates audio role from activation; Alarm Detail and Delivery own details. |
| P | S135–S143 | Uses same mutation contract for future Day Detail edits from Month Browsing. |
| Q | S144–S154 | Reset and adjusted-day interpretation depend on this contract. |
| Y | S205–S211 | Permission failures must not rewrite mutation state to Quiet. |
| AA | S220–S225 | Cross-surface consistency after mutations. |

---

## 5. Canonical terminology

### 5.1 Quick wake modes

Canonical user-facing quick wake modes:

```text
Pre-Fajr
Fajr
Quiet
```

Recommended code model:

```swift
enum QuickWakeMode: String, Codable, Equatable {
    case preFajr
    case fajr
    case quiet
}
```

Legacy aliases:

| Legacy wording | Canonical meaning | Migration rule |
|---|---|---|
| `Early` | `Pre-Fajr` | Load and display as `Pre-Fajr`. |
| `Fast` as a quick mode | `Pre-Fajr + Fasting` | Split into `mode = preFajr`, `preFajrIntention = fasting`. |
| `Off` as ordinary user action | `Quiet` | Use only if it means intentional suppression, not failure. |
| `No alarm` as ordinary user action | `Quiet` | Use only if it means intentional suppression, not failure. |

### 5.2 Pre-Fajr intentions

Canonical Pre-Fajr intention set:

```text
Tahajjud only
Fasting
Other early worship
```

Recommended code model:

```swift
enum PreFajrIntention: String, Codable, Equatable {
    case tahajjudOnly
    case fasting
    case otherEarlyWorship
}
```

Rules:

1. `Tahajjud only` means the user wants a non-fasting Pre-Fajr wake for Tahajjud.
2. `Fasting` means the user wants a Pre-Fajr wake for a fast and must have a fasting intention resolved by Day Purpose.
3. `Other early worship` means the user wants a non-fasting Pre-Fajr wake for another early-worship purpose.
4. `Other early worship` does not create a fasting intention, fast completion requirement, or fasting analytics credit.
5. `Other early worship` uses the early-worship wake-boundary regime unless Product explicitly narrows it later.

### 5.3 Fasting intentions

Fasting intention is active only when:

```text
quickWakeMode = Pre-Fajr
preFajrIntention = Fasting
```

The fasting taxonomy is owned by the Day Purpose / Opportunity / Intention spec.

This contract only requires a normalized representation such as:

```swift
enum FastingIntentionKind: String, Codable, Equatable {
    case ramadanFast
    case opportunityFast
    case voluntaryFast
    case qada
    case vow
    case kaffarah
    case otherFast
}
```

The implementation may use richer existing models if they preserve the same semantics.

### 5.4 Distinguish the two `Other` concepts

Two different concepts must not be collapsed:

| Concept | Meaning | Active when | Completion implication |
|---|---|---|---|
| `Other early worship` | Non-fasting Pre-Fajr worship reason | `Pre-Fajr + Other early worship` | No fast completion requirement. |
| `Other fast` | Fasting intention outside named fast taxonomy | `Pre-Fajr + Fasting + Other fast` | Fast completion may apply. |

---

## 6. Canonical mental model

A target morning can be understood as layers:

```text
Target morning date
    ↓
Prayer window and calendar context
    ↓
Day meaning / opportunity
    ↓
User wake mode
    ↓
Pre-Fajr intention, if applicable
    ↓
Fasting intention, if applicable
    ↓
Manual wake adjustment, if applicable
    ↓
Quiet suppression, if selected
    ↓
Resolved wake time and activation
    ↓
Delivery scheduling / reliability state
```

This contract owns the mutation of the user-controlled layers:

```text
User wake mode
Pre-Fajr intention
Fasting intention activation/deactivation
Manual wake adjustment
Quiet selection/restoration
Reset to Defaults
```

It does not own the upstream calculation layers or downstream platform delivery layers.

---

## 7. State model

### 7.1 Target morning key

All mutations must target exactly one morning.

Recommended key:

```swift
struct MorningDateKey: Hashable, Codable {
    let civilDate: LocalDate
    let timeZoneIdentifierAtResolution: String
}
```

At minimum, the key must identify the civil date on which Fajr occurs.

### 7.2 Committed selection model

Recommended committed model:

```swift
struct MorningWakeIntentOverride: Codable, Equatable {
    let morningDateKey: MorningDateKey

    var quickMode: QuickWakeMode?

    var activePreFajrIntention: PreFajrIntention?
    var preservedPreFajrIntention: PreFajrIntention?

    var activeFastingIntention: FastingIntentionSelection?

    var manualWakeAdjustment: ManualWakeAdjustment?

    var source: WakeIntentMutationSource
    var updatedAt: Date
    var schemaVersion: Int
}
```

Interpretation:

- `quickMode == nil` means no date-specific quick-mode override; use the resolved default.
- `quickMode == .fajr` means the user explicitly selected Fajr for that date.
- `quickMode == .preFajr` means the user explicitly selected Pre-Fajr for that date.
- `quickMode == .quiet` means the user intentionally suppressed wake delivery for that date.
- `activePreFajrIntention` is active only when `quickMode == .preFajr`.
- `preservedPreFajrIntention` may survive while the active mode is `Fajr` or `Quiet` so that returning to Pre-Fajr restores the user's prior reason.
- `activeFastingIntention` is active only when `quickMode == .preFajr` and `activePreFajrIntention == .fasting`.
- `manualWakeAdjustment` is active only when `quickMode` is `Fajr` or `Pre-Fajr` and is cleared on quick-mode changes.

The implementation may use different field names if it preserves these meanings.

### 7.3 Manual wake adjustment model

Recommended model:

```swift
struct ManualWakeAdjustment: Codable, Equatable {
    enum Anchor: String, Codable {
        case fajrModeDefault
        case preFajrModeDefault
    }

    let anchor: Anchor
    let offsetMinutesFromModeDefault: Int
    let displayedLocalTimeAtCommit: LocalTime?
    let committedWithinBoundaryKind: WakeBoundaryKind
}
```

Rules:

1. Store the adjustment as relative to the active mode default where practical.
2. Keep the displayed local time at commit only for audit/debug/explanation, not as the sole source of truth.
3. When prayer settings, location, timezone, or Hijri context changes, the adjustment re-resolves against the new prayer window where applicable.
4. If the re-resolved adjustment would fall outside the valid boundary, the resolver must clamp or mark for review according to Section 13.

This model supports the Planning doctrine:

```text
Remember user meaning, not generated defaults.
```

The user's meaning is “move this date's wake relative to this mode's default,” not “store a stale generated DaySchedule forever.”

### 7.4 Draft model for Day Detail

Alarm Detailed View must use a staged draft:

```swift
struct MorningWakeIntentDraft: Equatable {
    var baseSnapshot: ResolvedDaySnapshot
    var stagedOverride: MorningWakeIntentOverride?
    var hasUnsavedChanges: Bool
    var resetToDefaultsStaged: Bool
}
```

The implementation may use a different draft structure, but the behavior must be:

```text
Day Detail changes do not commit until Done.
Reset to Defaults in Day Detail is staged until Done.
Closing without Done must not commit ordinary edits.
```

The current intended UI has no ordinary Back-save behavior.

---

## 8. Mutation sources and commit modes

### 8.1 Mutation source enum

Recommended model:

```swift
enum WakeIntentMutationSource: String, Codable {
    case homeHero
    case alarmDetail
    case nextTenRoute
    case monthBrowsingDetail
    case adjustedDaysReset
    case settingsRuleRecompute
    case migration
}
```

### 8.2 Commit modes

| Surface / action | Commit mode | Rule |
|---|---|---|
| Home Hero quick mode tap | Immediate commit | Mutates immediate next morning. |
| Home Hero Pre-Fajr intention tap | Immediate commit | Mutates immediate next morning. |
| Home Hero wake drag end | Immediate commit | Saves date-specific adjustment for immediate next morning. |
| Alarm Detailed View quick mode tap | Staged draft | Does not persist until `Done`. |
| Alarm Detailed View Pre-Fajr intention tap | Staged draft | Does not persist until `Done`. |
| Alarm Detailed View fasting intention change | Staged draft | Does not persist until `Done`. |
| Alarm Detailed View wake drag end | Staged draft | Does not persist until `Done`. |
| Alarm Detailed View Reset to Defaults | Staged draft | Deletes override only when `Done` is tapped. |
| Adjusted Days Reset One | Immediate commit after confirmation or explicit action | Removes that date's active override. |
| Adjusted Days Reset All | Immediate commit after confirmation | Removes selected override set. |
| Next 10 row tap | No mutation | Opens Day Detail. |
| Weekly Fajrcast scrub/tap | No mutation | UI-only inspection. |
| Month browsing day tap | No mutation until Day Detail Done | Opens Day Detail for that date. |

---

## 9. Command contract

All surfaces should express user actions as commands instead of mutating state directly.

Recommended command model:

```swift
enum WakeIntentMutationCommand: Equatable {
    case selectQuickMode(QuickWakeMode)
    case selectPreFajrIntention(PreFajrIntention)
    case selectFastingIntention(FastingIntentionSelection)
    case adjustWakeTime(offsetMinutesFromModeDefault: Int)
    case resetWakeTimeToModeDefault
    case resetDateToDefaults
    case commitDraft
    case discardDraft
}
```

Command handler output:

```swift
struct WakeIntentMutationResult {
    let targetDateKey: MorningDateKey
    let committedOverride: MorningWakeIntentOverride?
    let draftOverride: MorningWakeIntentOverride?
    let resolvedSnapshotAfterMutation: ResolvedDaySnapshot
    let scheduleRefreshScope: ScheduleRefreshScope
    let userVisibleWarning: WakeIntentMutationWarning?
    let auditEvents: [WakeIntentMutationAuditEvent]
}
```

The command handler must return a resolved snapshot or trigger one immediately after commit so that the surface does not guess the final state locally.

---

## 10. Core mutation rules

### 10.1 Tapping the currently selected mode

Requirement QW-001:

```text
Tapping the already-selected quick mode SHALL be idempotent.
```

Examples:

- Fajr → Fajr does not create a second override.
- Pre-Fajr → Pre-Fajr does not duplicate the Pre-Fajr intention.
- Quiet → Quiet does not duplicate suppression records.

### 10.2 Selecting Fajr

Requirement QW-002:

```text
Selecting Fajr SHALL set the active quick mode to Fajr for the target morning.
```

Requirement QW-003:

```text
Selecting Fajr SHALL remove Quiet suppression for the target morning.
```

Requirement QW-004:

```text
Selecting Fajr SHALL clear any active manual wake adjustment for the target morning.
```

Requirement QW-005:

```text
Selecting Fajr SHALL preserve the latest known Pre-Fajr intention for that target morning as inactive restoration memory when such memory exists.
```

Requirement QW-006:

```text
Selecting Fajr SHALL deactivate active fasting intention for the target morning.
```

Notes:

- Deactivation means fasting intention must not affect wake boundary, completion requirement, analytics credit, or delivery.
- A transient Day Detail draft may keep the most recent fasting intention for draft restoration, but a committed non-fasting Fajr day must not be counted as a planned fast.

### 10.3 Selecting Pre-Fajr

Requirement QW-007:

```text
Selecting Pre-Fajr SHALL set the active quick mode to Pre-Fajr for the target morning.
```

Requirement QW-008:

```text
Selecting Pre-Fajr SHALL remove Quiet suppression for the target morning.
```

Requirement QW-009:

```text
Selecting Pre-Fajr SHALL clear any active manual wake adjustment for the target morning when the prior quick mode was not Pre-Fajr.
```

Requirement QW-010:

```text
Selecting Pre-Fajr SHALL restore the preserved Pre-Fajr intention for the target morning when one exists.
```

Requirement QW-011:

```text
If no preserved Pre-Fajr intention exists and the date is not Ramadan and not Eid, selecting Pre-Fajr SHALL default to Tahajjud only.
```

Requirement QW-012:

```text
If the date is Ramadan, selecting Pre-Fajr SHALL resolve to Fasting + Ramadan fast and lock the Pre-Fajr and fasting intention while Pre-Fajr remains active.
```

Requirement QW-013:

```text
If the date is Eid or otherwise fasting-forbidden, selecting Pre-Fajr SHALL resolve to a non-fasting Pre-Fajr intention, defaulting to Tahajjud only unless Other early worship is explicitly selected and supported.
```

### 10.4 Selecting Quiet

Requirement QW-014:

```text
Selecting Quiet SHALL set the active quick mode to Quiet for the target morning.
```

Requirement QW-015:

```text
Selecting Quiet SHALL intentionally suppress wake alarm, notification, and adhan delivery for that target morning.
```

Requirement QW-016:

```text
Selecting Quiet SHALL preserve underlying day meaning and any known Pre-Fajr intention for the target morning.
```

Requirement QW-017:

```text
Selecting Quiet SHALL clear active manual wake adjustment for the target morning.
```

Requirement QW-018:

```text
Quiet SHALL be date-specific unless a future recurring Quiet feature is explicitly specified.
```

Requirement QW-019:

```text
Permission failure, platform scheduling failure, stale delivery, or missing pending platform state SHALL NOT mutate quick mode to Quiet.
```

### 10.5 Selecting a Pre-Fajr intention

Requirement QW-020:

```text
Selecting a Pre-Fajr intention SHALL ensure the active quick mode is Pre-Fajr unless the selected intention is unavailable for that date.
```

Requirement QW-021:

```text
Selecting Tahajjud only SHALL deactivate active fasting intention and hide or disable fasting-specific controls.
```

Requirement QW-022:

```text
Selecting Other early worship SHALL deactivate active fasting intention and hide or disable fasting-specific controls.
```

Requirement QW-023:

```text
Selecting Fasting SHALL activate fasting intention resolution through the Day Purpose system.
```

Requirement QW-024:

```text
Changing Pre-Fajr intention while quick mode remains Pre-Fajr SHALL NOT automatically clear manual wake adjustment unless the new intention is unavailable, changes the boundary regime, or the resulting wake time becomes invalid.
```

For MVP, all three Pre-Fajr intentions use the early-worship boundary regime, so ordinary Tahajjud only ↔ Fasting ↔ Other early worship changes should preserve a valid manual Pre-Fajr wake adjustment.

### 10.6 Selecting a fasting intention

Requirement QW-025:

```text
A fasting intention may be selected only when Pre-Fajr + Fasting is active and fasting is available for the date.
```

Requirement QW-026:

```text
On a non-Ramadan date with one or more fasting opportunities, selecting Pre-Fajr + Fasting SHALL default to the best opportunity-based voluntary fast according to Day Purpose rules.
```

Requirement QW-027:

```text
On a non-Ramadan date with no specific fasting opportunity, selecting Pre-Fajr + Fasting SHALL default to Voluntary fast.
```

Requirement QW-028:

```text
On Ramadan dates, fasting intention SHALL be Ramadan fast and SHALL NOT be changed to Qada, voluntary, Sunnah opportunity, or other fast.
```

Requirement QW-029:

```text
On Eid or fasting-forbidden dates, Fasting SHALL be unavailable and SHALL NOT create an active fasting intention.
```

Requirement QW-030:

```text
Changing fasting intention while Pre-Fajr + Fasting remains active SHALL NOT clear manual wake adjustment.
```

---

## 11. Manual wake adjustment rules

### 11.1 Default anchors

Current MVP default anchors:

| Active mode | Default wake anchor |
|---|---|
| Fajr | 30 minutes before Fajr ends. |
| Pre-Fajr | 30 minutes before Fajr begins. |
| Quiet | No wake delivery. |

The exact Fajr begin/end values are owned by the Fajr Time Calculation spec.

The final-third early-worship boundary is owned by the Early Worship Boundary spec.

### 11.2 Valid adjustment windows

For v1 of this contract, committed manual wake adjustments must be legal inside the active boundary window:

| Active mode | Valid committed adjustment window |
|---|---|
| Fajr | Fajr begins → Fajr ends. |
| Pre-Fajr | final-third start → Fajr begins. |
| Quiet | No manual wake adjustment allowed. |

Requirement QW-031:

```text
The mutation layer SHALL not commit a manual wake adjustment outside the active mode's valid boundary window.
```

Requirement QW-032:

```text
If the user drags outside the valid window, the committed value SHALL be clamped to the nearest valid boundary for MVP.
```

This chooses hard clamping for MVP because it prevents invalid scheduled wake states. A future warning-based model can amend this contract if Product wants to allow out-of-window advisory states.

### 11.3 Adjustment persistence

Requirement QW-033:

```text
A manual wake adjustment SHALL be date-specific.
```

Requirement QW-034:

```text
A manual wake adjustment SHALL apply only while its associated quick mode remains active.
```

Requirement QW-035:

```text
Changing quick mode SHALL clear the active manual wake adjustment.
```

Requirement QW-036:

```text
Reset Wake Time to Mode Default SHALL remove only the manual wake adjustment while preserving the current mode and active intention.
```

Requirement QW-037:

```text
Reset Date to Defaults SHALL remove date-specific quick mode, Pre-Fajr intention override, fasting intention override, Quiet suppression, and manual wake adjustment for that date.
```

### 11.4 Quiet and adjustment

Requirement QW-038:

```text
When Quiet is active, the wake adjustment control SHALL be disabled, hidden, or clearly non-interactive.
```

Requirement QW-039:

```text
If an adjustment command is somehow sent while Quiet is active, the mutation layer SHALL reject it or return a no-op warning without creating a scheduled wake.
```

---

## 12. Home Hero behavior

The Home Hero is the immediate next-morning quick-control surface.

Requirement QW-040:

```text
Home Hero quick-mode and intention mutations SHALL commit immediately for the immediate next relevant morning.
```

Requirement QW-041:

```text
Home Hero SHALL emit mutation commands and consume the resolved snapshot after mutation; it SHALL NOT create, cancel, or directly schedule platform alarms.
```

Requirement QW-042:

```text
Home Hero SHALL use canonical labels: Pre-Fajr, Fajr, Quiet.
```

Requirement QW-043:

```text
When Pre-Fajr is active, Home Hero SHALL expose Pre-Fajr intention selection for every MVP-supported Pre-Fajr intention unless Product explicitly defers a scenario by ID.
```

Current MVP-supported Pre-Fajr intentions:

```text
Tahajjud only
Fasting
Other early worship
```

Requirement QW-044:

```text
Home Hero SHALL NOT show adhan controls.
```

Requirement QW-045:

```text
Home Hero SHALL distinguish degraded delivery/reliability from Quiet.
```

Example:

```text
Active Fajr wake + permission denied = Fajr selected with reliability warning.
Quiet selected = Quiet selected with no wake delivery by user choice.
```

---

## 13. Alarm Detailed View behavior

Alarm Detailed View is the staged editor for one selected day.

Requirement QW-046:

```text
Alarm Detailed View SHALL load a draft from the current resolved snapshot and any date-specific override for the selected morning.
```

Requirement QW-047:

```text
Alarm Detailed View SHALL stage all quick-mode, Pre-Fajr intention, fasting intention, wake adjustment, and reset changes until Done.
```

Requirement QW-048:

```text
Tapping Done SHALL commit the staged draft atomically for the selected morning.
```

Requirement QW-049:

```text
Reset to Defaults in Alarm Detailed View SHALL be staged and SHALL become durable only when Done is tapped.
```

Requirement QW-050:

```text
After Done, Alarm Detailed View SHALL trigger canonical morning re-resolution and schedule refresh for the affected date scope.
```

Requirement QW-051:

```text
Reopening Alarm Detailed View after Done SHALL show the committed state.
```

Requirement QW-052:

```text
Reopening Alarm Detailed View after Reset to Defaults + Done SHALL show the default resolved state for that date.
```

Requirement QW-053:

```text
Alarm Detailed View SHALL expose every MVP-supported Pre-Fajr intention unless Product explicitly defers a scenario by ID.
```

Requirement QW-054:

```text
Alarm Detailed View MAY expose date-specific adhan controls when the date and active state are eligible, but adhan controls SHALL NOT change quick mode except through explicit Quiet selection.
```

---

## 14. Reset semantics

There are two reset levels.

### 14.1 Reset Wake Time to Mode Default

This reset removes only manual wake adjustment.

Before:

```text
mode = Pre-Fajr
intention = Fasting
manualWakeAdjustment = -15 minutes from Pre-Fajr default
```

After:

```text
mode = Pre-Fajr
intention = Fasting
manualWakeAdjustment = nil
wake time = current Pre-Fajr default
```

### 14.2 Reset Date to Defaults

This reset removes all date-specific wake/intention changes for the selected morning.

Before:

```text
mode = Quiet
preservedPreFajrIntention = Fasting
fastingIntention = Qada
manualWakeAdjustment = present
```

After:

```text
no date-specific quick-mode override
no active date-specific Pre-Fajr intention override
no active date-specific fasting intention override
no Quiet suppression
no manual wake adjustment
```

The resolved state after reset may still be special because of upstream default rules.

Examples:

- Ramadan may still resolve to `Pre-Fajr + Fasting + Ramadan fast`.
- Eid may still block fasting.
- A recurring boundary rule may still affect wake time.
- A global default may still make the day Pre-Fajr.
- A fasting opportunity may still be shown as an opportunity without becoming an intention.

Reset removes user date-specific changes; it does not erase calendar meaning, prayer-time settings, recurring rules, or history.

---

## 15. Precedence and resolver handoff

This contract sits inside the broader resolution order.

Canonical order for relevant layers:

```text
1. Resolve prayer times and calendar context.
2. Resolve day meaning and observance opportunities.
3. Apply global default wake behavior.
4. Apply recurring boundary rules.
5. Apply date-specific quick wake / intention / manual adjustment overrides.
6. Apply Quiet suppression.
7. Resolve final wake time, activation, adhan behavior, tags, and schedule status.
8. Materialize scheduled events only for active scheduled horizon.
9. Delivery schedules/verifies platform state.
```

Requirement QW-055:

```text
Date-specific quick wake mutations SHALL beat recurring boundary rules for that date.
```

Requirement QW-056:

```text
Quiet SHALL beat active wake delivery for that date.
```

Requirement QW-057:

```text
Delivery status SHALL NOT feed backward into quick wake mode, Pre-Fajr intention, fasting intention, or Quiet state.
```

Requirement QW-058:

```text
After any committed mutation, the app SHALL re-resolve the affected target morning through Morning Resolution before updating surfaces or scheduling.
```

---

## 16. Persistence rules

### 16.1 Store user meaning, not generated defaults

Requirement QW-059:

```text
The app SHALL persist user-created wake/intention meaning, not every generated default morning.
```

Persist when the user creates or changes:

- explicit Fajr mode override;
- explicit Pre-Fajr mode override;
- explicit Pre-Fajr intention;
- explicit fasting intention override;
- Quiet suppression;
- manual wake adjustment;
- Reset-to-default deletion of a prior override.

Do not persist merely because:

- a default ordinary Fajr day exists;
- a fasting opportunity exists;
- a generated Next 10 row is displayed;
- a Weekly Fajrcast point is inspected;
- a month row is generated.

### 16.2 Inactive restoration memory

Requirement QW-060:

```text
When the user switches away from Pre-Fajr, the latest Pre-Fajr intention for that date SHALL be preserved as inactive restoration memory when practical.
```

Requirement QW-061:

```text
Inactive restoration memory SHALL NOT count as an active fast, active Tahajjud requirement, scheduled wake, completion requirement, or analytics credit.
```

Requirement QW-062:

```text
Adjusted Days should list active user-visible differences from default. Inactive restoration memory alone should not make a day appear actively adjusted unless Product explicitly chooses that behavior.
```

This avoids noise while preserving the restoration behavior required by MVP interactions.

### 16.3 Future edits

Requirement QW-063:

```text
The same mutation contract SHALL apply to immediate mornings and future editable mornings.
```

Requirement QW-064:

```text
A future mutation outside the active scheduled horizon SHALL be saved but not necessarily scheduled immediately.
```

Requirement QW-065:

```text
When the future date later enters Next 10, Home, or the active scheduled horizon, the saved mutation SHALL hydrate through canonical Morning Resolution.
```

---

## 17. Scheduling handoff

Requirement QW-066:

```text
Committed active Fajr or Pre-Fajr states SHALL request schedule refresh for affected dates.
```

Requirement QW-067:

```text
Committed Quiet states SHALL request cancellation/suppression of wake alarm, notification, and adhan delivery for that date.
```

Requirement QW-068:

```text
Committed reset-to-default changes SHALL request schedule refresh for affected dates.
```

Requirement QW-069:

```text
The mutation layer SHALL NOT directly schedule AlarmKit alarms or UserNotifications.
```

Requirement QW-070:

```text
The scheduled alarm time for any active, permitted, non-Quiet date SHALL match the wake time in the final resolved snapshot.
```

Requirement QW-071:

```text
If permission is missing, the user's active mode and intention SHALL remain saved and visible; delivery status SHALL report blocked/degraded delivery.
```

---

## 18. Rapid and repeated interaction rules

Requirement QW-072:

```text
All mutations for the same target morning SHALL be serialized or otherwise resolved to a deterministic final state.
```

Requirement QW-073:

```text
For rapid interactions, the final user-selected state SHALL win.
```

Requirement QW-074:

```text
The implementation SHALL coalesce schedule refreshes where practical without losing the final-state guarantee.
```

Requirement QW-075:

```text
Repeated taps SHALL NOT create duplicate date-specific records, duplicate scheduled events, duplicate cancellation requests, or duplicate restoration memories.
```

Requirement QW-076:

```text
If the user drags a wake slider and then changes quick mode, the mode change SHALL clear the manual adjustment and the final selected mode SHALL determine the displayed and scheduled wake time.
```

Requirement QW-077:

```text
Expanding/collapsing Next 10, Browse by Month, or Weekly Fajrcast SHALL NOT mutate wake state.
```

---

## 19. Surface interaction matrix

| Surface | May select mode? | May select Pre-Fajr intention? | May select fasting intention? | May adjust wake time? | May select Quiet? | Commit style | Notes |
|---|---:|---:|---:|---:|---:|---|---|
| Home Hero | Yes | Yes | Limited/simple if exposed | Yes | Yes | Immediate | Immediate next relevant morning only. |
| Alarm Detailed View | Yes | Yes | Yes | Yes | Yes | Staged until Done | Selected date editor. |
| Next 10 | No direct mutation | No | No | No | No | N/A | Tap row opens Day Detail. |
| Weekly Fajrcast | No | No | No | No | No | N/A | Scrub/tap is inspection only. |
| Month Browsing day list | No direct mutation | No | No | No | No | N/A | Tap day opens Day Detail. |
| Adjusted Days | Reset only | No direct selection | No direct selection | Reset only | Reset only | Explicit reset action | Opens Day Detail for editing. |
| Settings Boundary Rules | Not date-specific quick mode | No | No | Rule editing only | No | Settings save | Feeds defaults before date-specific overrides. |

---

## 20. Special calendar states

### 20.1 Ramadan

Requirement QW-078:

```text
During Ramadan, the default resolved wake state SHALL be Pre-Fajr + Fasting + Ramadan fast unless the user selects Fajr or Quiet where product rules allow.
```

Requirement QW-079:

```text
While Pre-Fajr is active during Ramadan, Pre-Fajr intention and fasting intention SHALL be locked to Fasting + Ramadan fast.
```

Requirement QW-080:

```text
If the user switches from Ramadan Pre-Fajr to Fajr or Quiet and later returns to Pre-Fajr, the state SHALL restore to Fasting + Ramadan fast.
```

### 20.2 Eid and fasting-forbidden days

Requirement QW-081:

```text
On Eid or fasting-forbidden days, Fasting SHALL be unavailable as a Pre-Fajr intention.
```

Requirement QW-082:

```text
Selecting Pre-Fajr on Eid SHALL land on Tahajjud only unless Other early worship is explicitly selected and supported.
```

Requirement QW-083:

```text
The app SHALL NOT create an active fasting intention, fast completion requirement, or fasting analytics credit on Eid from a quick wake mutation.
```

### 20.3 Opportunity-only days

Requirement QW-084:

```text
A fasting opportunity SHALL NOT become a fasting intention unless the user selects Pre-Fajr + Fasting or Ramadan/default-obligatory rules require it.
```

Requirement QW-085:

```text
Selecting Fajr on a fasting-opportunity day SHALL keep the opportunity available but inactive.
```

---

## 21. Legacy migration

Requirement QW-086:

```text
Legacy `Early` records SHALL load as `Pre-Fajr`.
```

Requirement QW-087:

```text
Legacy `Fast` quick-mode records SHALL load as `Pre-Fajr + Fasting`.
```

Requirement QW-088:

```text
Legacy non-fasting `Tahajjud` reason records SHALL load as `Tahajjud only`.
```

Requirement QW-089:

```text
Legacy `Other` records under Early/Pre-Fajr SHALL load as `Other early worship`.
```

Requirement QW-090:

```text
Legacy `Other` records under fasting taxonomy SHALL load as `Other fast`.
```

Requirement QW-091:

```text
Migration SHALL preserve user-created date-specific choices and SHALL NOT silently collapse them into defaults.
```

---

## 22. User-visible copy guidance

Canonical labels:

```text
Pre-Fajr
Fajr
Quiet
Tahajjud only
Fasting
Other early worship
Voluntary fast
Ramadan fast
Qada
```

Avoid:

```text
Early
Fast as a mode
Off as ordinary user state
No alarm as ordinary user state
Adhan off as alarm off
```

Permitted explanatory copy patterns:

```text
Quiet mode: No alarm will ring for this morning.
Reliability warning: Alarm permission is missing, so Subh may not be able to wake you.
Pre-Fajr default: Wake up 30 min before Fajr begins.
Fajr default: Wake up 30 min before Fajr ends.
Last-third endpoint: Wake up for the last third of the night.
```

Do not say:

```text
Quiet because permission is denied.
Adhan off, so alarm is off.
Fasting selected as a top-level mode.
Other fast when the user chose non-fasting Other early worship.
```

---

## 23. Accessibility requirements

Requirement QW-092:

```text
Accessible labels SHALL expose the active quick mode and active intention where applicable.
```

Examples:

```text
Fajr mode selected. Wake time 5:43 AM.
Pre-Fajr selected. Tahajjud only. Wake time 4:13 AM.
Pre-Fajr selected. Fasting. Ramadan fast. Wake time 4:13 AM.
Quiet selected. No alarm will ring for tomorrow.
```

Requirement QW-093:

```text
Accessibility labels SHALL distinguish Quiet from permission or delivery failure.
```

Requirement QW-094:

```text
Repeated-tap idempotency SHALL apply equally to assistive technology actions.
```

---

## 24. Diagnostics and audit events

This contract does not require remote telemetry.

Local audit/debug events are useful for implementation and support.

Recommended event shape:

```swift
struct WakeIntentMutationAuditEvent: Codable {
    let targetDateKey: MorningDateKey
    let source: WakeIntentMutationSource
    let command: String
    let beforeSummary: String
    let afterSummary: String
    let scheduleRefreshScope: ScheduleRefreshScope
    let warning: String?
    let createdAt: Date
}
```

Recommended event examples:

```text
selected_fajr
selected_pre_fajr
selected_quiet
selected_pre_fajr_intention
selected_fasting_intention
wake_adjustment_committed
wake_adjustment_reset
reset_date_to_defaults
mutation_rejected_fasting_unavailable
mutation_rejected_quiet_adjustment
legacy_early_migrated_to_pre_fajr
```

Diagnostics must not be used as the source of truth for user state.

---

## 25. Acceptance scenarios

### 25.1 Fajr idempotency

```text
GIVEN the target morning is in Fajr mode
WHEN the user taps Fajr repeatedly
THEN the target morning remains Fajr
AND no duplicate override records are created
AND no duplicate scheduled events are created.
```

### 25.2 Pre-Fajr default intention

```text
GIVEN a non-Ramadan, non-Eid target morning with no preserved Pre-Fajr intention
WHEN the user selects Pre-Fajr
THEN Pre-Fajr becomes active
AND the Pre-Fajr intention defaults to Tahajjud only
AND fasting controls remain inactive.
```

### 25.3 Other early worship

```text
GIVEN Pre-Fajr is active
WHEN the user selects Other early worship
THEN fasting controls become inactive
AND no active fasting intention exists
AND the early-worship boundary is used
AND the state remains representable across Home, Detail, persistence, and resolution.
```

### 25.4 Pre-Fajr + Fasting opportunity

```text
GIVEN a non-Ramadan target morning with a fasting opportunity
WHEN the user selects Pre-Fajr + Fasting
THEN Pre-Fajr is active
AND Fasting is the active Pre-Fajr intention
AND Day Purpose resolves the default fasting intention to the appropriate opportunity-based voluntary fast.
```

### 25.5 Pre-Fajr + Fasting without opportunity

```text
GIVEN a non-Ramadan target morning without a fasting opportunity
WHEN the user selects Pre-Fajr + Fasting
THEN the fasting intention defaults to Voluntary fast.
```

### 25.6 Ramadan lock

```text
GIVEN a Ramadan target morning
WHEN Pre-Fajr is active
THEN Fasting is locked
AND Ramadan fast is locked
AND Qada, voluntary, Sunnah opportunity, and Other fast are unavailable.
```

### 25.7 Eid fasting unavailable

```text
GIVEN an Eid target morning
WHEN the user selects Pre-Fajr
THEN the active Pre-Fajr intention is Tahajjud only by default
AND Fasting is unavailable
AND no active fasting intention is created.
```

### 25.8 Pre-Fajr restoration

```text
GIVEN the user selected Pre-Fajr + Fasting for a target morning
WHEN the user switches to Fajr
THEN Fajr becomes active
AND the Pre-Fajr intention is preserved as inactive restoration memory
AND manual wake adjustment is cleared
WHEN the user switches back to Pre-Fajr
THEN Fasting returns as the Pre-Fajr intention
AND manual wake adjustment does not return.
```

### 25.9 Quiet restoration

```text
GIVEN the user selected Pre-Fajr + Tahajjud only
WHEN the user selects Quiet
THEN wake delivery is suppressed for that date
AND Tahajjud only is preserved as inactive Pre-Fajr restoration memory
WHEN the user exits Quiet to Pre-Fajr
THEN Tahajjud only returns
AND wake delivery becomes active again if permissions allow.
```

### 25.10 Quiet versus permission failure

```text
GIVEN the user selected Fajr
AND alarm permission is denied
WHEN the resolved morning is displayed
THEN Fajr remains selected
AND a reliability warning is shown
AND the state is not rewritten to Quiet.
```

### 25.11 Manual adjustment cleared on mode switch

```text
GIVEN the user adjusted wake time in Fajr mode
WHEN the user switches to Pre-Fajr
THEN the manual Fajr adjustment is cleared
AND the Pre-Fajr default wake time applies unless a new Pre-Fajr adjustment is made.
```

### 25.12 Manual adjustment preserved across Pre-Fajr intention change

```text
GIVEN Pre-Fajr is active
AND the user has a valid manual Pre-Fajr wake adjustment
WHEN the user changes Pre-Fajr intention from Tahajjud only to Fasting
THEN the manual Pre-Fajr wake adjustment remains active
AND fasting intention resolves through Day Purpose.
```

### 25.13 Home immediate commit

```text
GIVEN the user changes the immediate next morning from Home Hero
WHEN the mutation succeeds
THEN the committed override is saved immediately
AND Home consumes the re-resolved snapshot
AND schedule refresh is requested for the affected date if inside the active scheduled horizon.
```

### 25.14 Day Detail staged save

```text
GIVEN the user opens Alarm Detailed View for a future date
WHEN the user changes mode, intention, fasting intention, and wake time
THEN changes remain staged
WHEN the user taps Done
THEN the staged draft commits atomically
AND reopening the same date shows the committed state.
```

### 25.15 Day Detail staged reset

```text
GIVEN the selected date has a date-specific override
WHEN the user taps Reset to Defaults in Alarm Detailed View
THEN the reset is staged
WHEN the user taps Done
THEN the override is removed
AND the selected date resolves from upstream defaults and rules.
```

### 25.16 Rapid final-state guarantee

```text
GIVEN the user rapidly switches Fajr → Pre-Fajr → Quiet → Fajr → Pre-Fajr
WHEN all commands settle
THEN the final state is Pre-Fajr
AND the preserved/default Pre-Fajr intention is active
AND no duplicate overrides or duplicate scheduled events exist.
```

### 25.17 Slider then mode change

```text
GIVEN the user drags the wake slider
WHEN the user changes quick mode before or after the drag commit settles
THEN the final selected quick mode wins
AND the manual adjustment from the previous mode is cleared
AND the final displayed wake time matches the final scheduled wake time when active and permitted.
```

### 25.18 Quiet never schedules

```text
GIVEN Quiet is active for a target morning
WHEN scheduling refresh runs
THEN no wake alarm, notification, or adhan event is scheduled for that target morning
AND the absence of delivery is treated as intentional suppression.
```

---

## 26. Implementation checklist

### 26.1 Models

- [ ] Add or normalize `QuickWakeMode.preFajr`, `.fajr`, `.quiet`.
- [ ] Remove `Fast` as a top-level quick mode from new models.
- [ ] Add or normalize `PreFajrIntention.tahajjudOnly`, `.fasting`, `.otherEarlyWorship`.
- [ ] Distinguish `Other early worship` from `Other fast`.
- [ ] Add or normalize manual wake adjustment representation.
- [ ] Add or normalize inactive Pre-Fajr restoration memory.
- [ ] Add legacy migration for `Early`, `Fast`, `Tahajjud`, and `Other`.

### 26.2 Mutation handling

- [ ] Create or update command handler for quick wake mutations.
- [ ] Ensure idempotent same-mode taps.
- [ ] Ensure mode switch clears manual adjustment.
- [ ] Ensure Pre-Fajr intention is preserved across Fajr/Quiet switches.
- [ ] Ensure Quiet suppresses delivery without deleting day meaning.
- [ ] Ensure permission failure does not mutate to Quiet.
- [ ] Ensure Day Detail edits are staged until Done.
- [ ] Ensure Reset to Defaults in Detail is staged until Done.
- [ ] Ensure rapid interactions are serialized or deterministically resolved.

### 26.3 Resolver integration

- [ ] Re-resolve canonical morning after every committed mutation.
- [ ] Use Day Purpose for fasting default/override resolution.
- [ ] Use Fajr Time Calculation for Fajr begin/end.
- [ ] Use Early Worship Boundary for final-third start.
- [ ] Use Morning Resolution for final wake time, activation, tags, materialized events, and snapshots.
- [ ] Use Alarm Delivery only after materialized scheduled events exist.

### 26.4 Surface integration

- [ ] Home Hero uses this contract for immediate commits.
- [ ] Alarm Detail uses this contract for staged edits and Done commits.
- [ ] Next 10 rows do not mutate directly.
- [ ] Month rows do not mutate directly.
- [ ] Weekly Fajrcast does not mutate.
- [ ] Adjusted Days reset uses this contract.

### 26.5 Tests

- [ ] Unit tests for every transition in Sections 10–11.
- [ ] Unit tests for Ramadan lock and Eid fasting unavailable.
- [ ] Unit tests for `Other early worship` representation.
- [ ] Unit tests for same-mode idempotency.
- [ ] Unit tests for rapid command final-state behavior.
- [ ] Integration tests for Home → Next 10 → Day Detail consistency.
- [ ] Integration tests for Day Detail Done and Reset to Defaults.
- [ ] Scheduling tests verifying displayed wake equals scheduled wake for active permitted non-Quiet dates.
- [ ] Delivery tests verifying Quiet does not schedule and permission failure does not become Quiet.

---

## 27. Open decisions intentionally not hidden

These are not removals. They are explicit items Product may revise later.

| Decision | v1 contract stance | How to change later |
|---|---|---|
| Should `Other early worship` be visible in Home and Detail? | Yes for MVP completeness unless explicitly deferred by scenario ID. | Update inventory, reconciliation, Hero, Detail, and this contract with approved scenario-level deferral. |
| Should wake adjustment allow out-of-window advisory states? | No. MVP committed values hard-clamp to valid window. | Create or expand Wake Adjustment spec if Product wants warning-based out-of-window behavior. |
| Should Reset to Defaults in Day Detail commit immediately? | No. It stages until Done. | Update Alarm Detail and this contract if Product chooses immediate reset. |
| Should inactive Pre-Fajr restoration memory appear in Adjusted Days? | No by default. It preserves restoration without creating active adjusted-day noise. | Adjusted Days spec may choose a separate filter if Product wants it visible. |
| Should Quiet become recurring? | No. Date-specific only for MVP. | Create separate Quiet/recurring suppression spec. |
| Should manual wake adjustment be exact local time instead of offset from mode default? | v1 recommends offset from mode default plus displayed time for audit. | Expand Wake Adjustment spec if exact fixed times become a first-class user choice. |

---

## 28. Minimal Codex implementation prompt

```text
Implement the Subh Quick Wake Mode and Intent Mutation Contract v1.

Do not create a second resolver if existing MorningResolver / WakeStateSelectionResolver / MorningWakeResolutionService can be updated.

Canonical modes are Pre-Fajr, Fajr, Quiet. Early is a legacy alias for Pre-Fajr. Fast as a mode is Pre-Fajr + Fasting. Tahajjud as a non-fasting Pre-Fajr reason is Tahajjud only. Other under Pre-Fajr is Other early worship and must remain distinct from Other fast.

Implement idempotent mode selection, Pre-Fajr intention preservation, Quiet suppression/restoration, manual wake adjustment clearing on mode changes, Home immediate commits, Alarm Detail staged edits until Done, staged Reset to Defaults, Ramadan lock, Eid fasting unavailable, and rapid final-state behavior.

After every committed mutation, re-resolve the canonical morning and request schedule refresh for affected dates. Do not directly schedule platform alarms from views or mutation handlers. Delivery failure and permission failure must not rewrite state to Quiet.

Add tests for S028-S045, S056-S070, S089-S109, and S226-S235 from subh-mvp-interaction-inventory-v3.md, plus supporting tests for S046-S055 and S205-S211 where this contract interacts with Day Purpose and Alarm Delivery.
```

---

## 29. Integrity checklist

- [x] Does not remove any MVP interaction.
- [x] Keeps `Pre-Fajr | Fajr | Quiet` canonical.
- [x] Treats `Early` as legacy alias only.
- [x] Splits `Fast` mode into `Pre-Fajr + Fasting`.
- [x] Preserves `Tahajjud only` as default non-fasting Pre-Fajr intention.
- [x] Preserves `Other early worship` unless explicitly deferred later.
- [x] Distinguishes `Other early worship` from `Other fast`.
- [x] Defines Quiet as intentional suppression, not failure.
- [x] Prevents permission failure from becoming Quiet.
- [x] Defines Home immediate commit.
- [x] Defines Day Detail staged edits and Done-only commit.
- [x] Defines Reset to Defaults as staged in Day Detail.
- [x] Defines manual wake adjustment clearing on quick-mode changes.
- [x] Defines rapid/repeated interaction final-state behavior.
- [x] Keeps prayer calculation, day purpose, delivery, and UI layout in their owning specs.
- [x] Avoids creating unnecessary new subsystems.
