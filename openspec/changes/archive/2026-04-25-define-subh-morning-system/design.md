## Context

Subh is a Fajr-centered morning system, but the current app is still organized as a Suhoor/Fajr alarm and fasting planner with multiple bottom tabs. The existing codebase contains valuable domain work: prayer-time calculation, Fajr window surfaces, Hijri adjustment settings, reliability checks, wake-list presentation, scheduling stores, and AlarmKit recovery tests. This redesign should preserve those assets while changing the product model, root navigation, and default wake behavior.

The immediate implementation must also respect first-wave compatibility constraints. The visible product identity becomes Subh, but `PRODUCT_BUNDLE_IDENTIFIER = khanomar.Suhoor` and existing persisted storage namespaces remain in place until a later, explicit data migration proposal.

## Goals / Non-Goals

**Goals:**
- Establish durable OpenSpec doctrine for the Subh product model.
- Use one morning-resolution model as the conceptual center for wake, observance, reliability, and explanation.
- Replace the bottom-tab shell with one Subh home surface for the MVP.
- Move the first-wave default wake anchor to 30 minutes before supported Fajr end.
- Preserve existing useful scheduling, Fajrcast, Hijri settings, permission/reliability, and AlarmKit test-store work.
- Rename visible app identity, project/scheme/target surfaces, and user-facing copy to Subh while preserving local data identity.

**Non-Goals:**
- No rewrite from scratch.
- No new religious authority layer, content feed, social feature, or generic Islamic superapp expansion.
- No first-wave wake customization UI beyond the existing compatibility/settings paths.
- No destructive storage migration or bundle identifier change in this wave.
- No attempt to resolve every legacy symbol containing Suhoor when the symbol is part of persisted compatibility or existing scheduling internals.

## Decisions

1. **Use OpenSpec umbrella plus child changes.**  
   The umbrella change defines doctrine-level capabilities. Implementation proceeds through smaller child changes so each slice has a focused review boundary and can be validated independently.

2. **Rebuild in place around existing providers.**  
   `FajrWindowSurfaceProvider`, `WakeSurfaceProvider`, `HomeSurfaceProvider`, `ScheduleManager`, and the current prayer-time/Hijri stores stay in service. New presentation models adapt these providers rather than moving calculation logic into SwiftUI.

3. **Make `MorningHomeSnapshot` the home contract.**  
   The first-wave home snapshot contains `tomorrow`, `weeklyFajrcast`, `morningcast`, `permissionState`, and `contextFlags`. It gives SwiftUI one object to render while keeping calculation and persistence outside the view layer.

4. **Use supported Fajr end as the MVP wake boundary.**  
   The default wake moves from Fajr-start minus 30 minutes to Fajr-end minus 30 minutes. Where the current provider uses a sunrise-derived boundary, UI and diagnostics must avoid overstating precision.

5. **Preserve data identity during rename.**  
   Xcode project, scheme, app display name, test target/module, app struct, folder names, and visible copy move to Subh. The app bundle identifier and existing storage keys remain in legacy namespaces to avoid accidental data loss.

6. **Retire tabs at the entry point, not every legacy view.**  
   `RootTabView` stops being the primary shell. Existing planning/progress/detail views may remain compiled and reachable from settings or contextual flows while product IA moves to one home screen.

## Risks / Trade-offs

- [Risk] Renaming the Xcode project and target can break test discovery or generated file references. → Mitigation: update project, scheme, test plan, imports, and verify with `xcodebuild -list`.
- [Risk] Migrating wake defaults could overwrite a user-customized schedule. → Mitigation: migrate only persisted settings matching the old factory default and preserve all custom settings.
- [Risk] Fajr end may currently be sunrise-derived in parts of the implementation. → Mitigation: call it the supported Fajr end boundary and keep approximation/provider notes visible where needed.
- [Risk] Removing tabs may strand useful legacy functionality. → Mitigation: keep detail/settings routes for retained surfaces and move only primary IA in this wave.
- [Risk] Full internal symbol rename could mix with behavior changes and create regressions. → Mitigation: prioritize visible identity and module/project rename now; leave storage-compatible legacy internals documented until a dedicated cleanup change.

## Migration Plan

1. Copy the Subh doctrine into `AGENTS.md` and update OpenSpec project context.
2. Archive the umbrella specs once validated so future changes can rely on them as main specs.
3. Implement the rename wave while preserving bundle id and storage keys.
4. Implement the Fajr-end default migration and scheduling regeneration behavior.
5. Add `MorningHomeSnapshot` and `SubhHomeView`, then route app launch into the single-screen home.
6. Adapt retained Fajrcast/Morningcast cards and remove bottom tabs from the primary experience.
7. Run OpenSpec validation, project listing, and focused XCTest coverage. Run the full suite when feasible, noting the known unrelated Hijri schedule baseline failure.

## Open Questions

- Which authority labels should be shown for each calculation method in the first public trust surface?
- Should a later wave migrate storage namespaces from `Suhoor.*` to `Subh.*`, or should legacy namespaces remain permanent for local-only stability?
- Which planning/progress surfaces deserve contextual re-entry in the MVP versus later redesigned widgets?
