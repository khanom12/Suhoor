## Context

The current implementation already has a domain separation that matches the new specs: `ResolvedDayPurpose` models opportunities, intention, wake classification, required actions, and analytics credits, while `ResolvedDaySnapshot` carries that result alongside `ResolvedDayContext`. The drift is in presentation. `NextTenMorningsTagResolver` derives tags from `ResolvedDayContext` and raw tag results, and `AlarmDayDetailPresentation` derives context sentences and opportunity chips locally.

The new specs require a shared presentation layer, not a second morning engine. The affected modules are:

- `Subh/Core/ProductSurfacePresentation.swift`
- `Subh/Features/Home/MorningHomePresentation.swift`
- `Subh/Features/Home/SubhHomeView.swift`
- `Subh/Features/Alarms/AlarmDayDetailView.swift`
- `SubhTests/TagComputationEngineTests.swift`

## Goals / Non-Goals

**Goals:**
- Add shared tag presentation models derived from `ResolvedDayPurpose`.
- Add primary morning context presentation derived from the same resolved payload.
- Make Home, Next 7 Days, and Alarm Detail consume those presentation outputs.
- Preserve opportunity-only versus selected Suhoor/fast purpose in visible copy and accessibility.
- Keep Quiet as a presentation overlay that preserves underlying day meaning in expanded context.

**Non-Goals:**
- No prayer-time, Fajr begin/end, alarm delivery, cache migration, storage namespace, entitlement, or pricing changes.
- No new resolver for observance opportunities or analytics credit.
- No new production dependency.
- No broad redesign of the Hero, Fajr window chart, or Weekly Fajrcast geometry.

## Decisions

1. Add the shared presentation adapter inside `ProductSurfacePresentation`.
   - Rationale: the codebase already keeps cross-surface schedule presentation helpers there, and placing the adapter in Core keeps SwiftUI views from owning business meaning.
   - Alternative considered: a new file under `Core/Morning/Presentation`; this is cleaner long-term, but adding to the existing presentation module keeps this pass scoped and avoids Xcode project churn for tests.

2. Derive tags primarily from `ResolvedDayPurpose`.
   - Rationale: `ResolvedDayPurpose` already distinguishes opportunities, selected intention, required actions, and credits. Tags must remain output, not source of truth.
   - Alternative considered: continue feeding `ResolvedDayContext` and `TagComputationResult`; that preserves current behavior but keeps the local-inference drift the specs are trying to remove.

3. Keep `NextTenMorningsTagDisplay` as the row-specific visual DTO, but map it from `SharedDayTagPresentationSnapshot`.
   - Rationale: the Next 7 Days row has existing no-wrap and lane-measurement behavior that should remain owned by the surface.
   - Alternative considered: render shared tags directly in SwiftUI. That would blur visual row concerns into the shared contract.

4. Let Primary Morning Context compact hide ordinary default Fajr on Home, while Alarm Detail uses expanded density for every selected date.
   - Rationale: Home should stay centered on tomorrow’s execution, but detail surfaces should explain the selected day when the user asks for it.

## Risks / Trade-offs

- [Risk] Copy can regress by repeating Hero wake mechanics. -> Mitigation: context presentation copy is generated without wake-offset/no-alarm relation lines, and tests cover Quiet copy.
- [Risk] Surface-specific visual DTOs can reintroduce local meaning. -> Mitigation: row tags map from shared tag semantics and tests assert MVP labels like `Suhoor`, `Fajr`, `Quiet`, `Ramadan`, and `Qada`.
- [Risk] Existing `ResolvedDayContext` remains in the app. -> Mitigation: this pass keeps it as compatibility context while moving new context/tag presentation to `ResolvedDayPurpose`.
- [Risk] New Home context module adds clutter. -> Mitigation: compact presentation hides ordinary default Fajr and caps chips to meaningful cases.

## Migration Plan

No persisted data migration is required. The change is presentation-only over already resolved snapshots. Rollback is to remove the shared adapter consumption and restore local tag/context rendering; scheduled alarms and stored settings are unaffected.
