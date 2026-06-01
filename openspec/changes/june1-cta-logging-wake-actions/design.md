## Context

The active June 1 spec package makes `subh-cta-logging-and-wake-action-spec-v2.md` canonical for CTA/logging behavior. The existing codebase already has a single morning engine, wake-session store/planner, completion models, context-card presentation, Home actions, and a wake-session simulation harness. This pass should extend those paths rather than introducing a second wake/logging engine.

Relevant constraints from the product doctrine:

- Subh is a Fajr-centered morning system, not a generic alarm clock.
- UI must not own prayer-time or wake-session business rules.
- Alarm reliability and degraded/ambiguous delivery states must remain explicit.
- Silence, dismissal, and expired prompts must not be treated as explicit failure.
- No broad Qada UI, pricing redesign, social/accountability surface, or unrelated visual redesign.

## Goals / Non-Goals

**Goals:**

- Make explicit active wake confirmation purpose-specific and visible in the Hero.
- Keep Fajr wake acknowledgement and Fajr prayer completion sequential and separately logged.
- Keep logging and early-awake affordances in the existing context-card action area.
- Preserve Fajr-beginning adhan/event after early/active Suhoor confirmation, while silencing current-morning Fajr delivery after early Fajr confirmation.
- Advance the Hero primary time to the next pending wake attempt after non-awake dismissal.
- Add tri-state completion/prompt foundations with explicit no as the only source of future Qada relevance.

**Non-Goals:**

- No full historical logging UI if no existing surface can be safely aligned.
- No Qada engine UI or exemption/fiqh rules.
- No separate post-Suhoor `Set Fajr Wake Alarm` CTA.
- No new production dependencies.

## Decisions

1. Use the wake-session store as the source for explicit awake and dismissal events.
   - Rationale: wake acknowledgement affects scheduling, pending check cancellation, and audit/debug behavior.
   - Alternative considered: view-local flags. Rejected because it would make alarm reliability and next-attempt display untestable.

2. Represent non-awake dismissal separately from awake confirmation.
   - Rationale: ordinary system/AlarmKit dismissal is not proof the user is awake.
   - Consequence: the session remains unresolved and the next pending check remains eligible unless the user explicitly confirms awake.

3. Keep action eligibility in presentation models assembled from domain state.
   - Rationale: Home can render a compact action area, but it should not calculate religious/time windows or infer logging outcomes.

4. Extend completion records with tri-state prompt semantics only where needed.
   - Rationale: existing completion records already represent Fajr/fast outcomes; the June 1 pass needs explicit yes/no/unrecorded/expired without a large historical UI.

5. Preserve post-Suhoor Fajr as a Fajr-start event unless the user commits a later slider wake time.
   - Rationale: this follows the active spec and avoids silently firing both Fajr adhan and a wake-check session.

## Risks / Trade-offs

- [Risk] AlarmKit dismissal callbacks may not expose every source with full fidelity in local tests. Mitigation: model dismissal source explicitly and cover deterministic store/presentation behavior.
- [Risk] Some historical logging surfaces may not exist yet. Mitigation: add shared data/model hooks and TODOs where safe, without inventing a large UI.
- [Risk] The Home view may currently conflate active wake and logging actions. Mitigation: move eligibility into reusable presentation structures and keep SwiftUI changes scoped.
- [Risk] Simulator tests cannot prove OS delivery reliability. Mitigation: cover schedule and store transitions with XCTest and keep manual scenarios in the completion report.

## Migration Plan

1. Reconcile `docs/specs` and the Desktop working specification folder against the June 1 package.
2. Validate OpenSpec artifacts before implementation.
3. Implement store/domain transitions first.
4. Wire Home presentation/actions to the updated model.
5. Add focused tests for wake action sequencing, dismissal, early-awake behavior, check/X logging, and Qada candidate foundations.
6. Run OpenSpec validation, focused tests, and a build/typecheck where available.

Rollback is code-level: revert this change's implementation and restore archived pre-June root specs if the June 1 package needs to be withdrawn. No destructive data migration is planned.
