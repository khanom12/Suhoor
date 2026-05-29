## Context

The May 29 Desktop spec bundle makes `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md` normative for this pass. The current app already has the important building blocks: `WakeStateSelectionResolver`, `MorningWakeResolutionService`, `MorningPlanStore`, `WakeSessionStore`, `WakeSessionTestingHarness`, `MorningHomePresentation`, `SubhHomeView`, `AlarmDayDetailView`, forecast/month presentation models, Settings surfaces, and scheduling/reconciliation services. Some legacy naming remains intentionally compatible with earlier storage and AlarmKit identifier choices.

The implementation should therefore align behavior and visible copy without a broad storage rewrite. The controlling model is one resolved morning with separate wake purpose, date alarm override, global wake-alarm policy, resolved delivery/alarm state, and execution state.

## Goals / Non-Goals

**Goals:**

- Keep Fajr and Suhoor as the only user-facing MVP wake purposes.
- Model Quiet as a date-level alarm override and Pause as an indefinite app-wide wake-alarm policy.
- Preserve purpose-specific Fajr and Suhoor alarm settings when switching purpose, Quiet, Pause, resume, or ring-once exceptions.
- Keep Home Hero height and slot baselines stable while state copy and actions change.
- Make active alarm execution one-button: `I’m awake`.
- Treat explicit system alarm dismissal as equivalent to `I’m awake` for MVP while preserving acknowledgement source where the current model can hold it.
- Add focused XCTest coverage for resolution precedence, persistence, presentation copy, and wake-session/harness states.

**Non-Goals:**

- No date-range pause, recurring pause, or pause reason picker.
- No generic Tahajjud-only, Other early worship, or non-fasting Pre-Fajr user-facing purpose for MVP.
- No broad persistence namespace rename that risks existing user data.
- No new paid gate for Quiet, Pause, acknowledgement, current-morning fasting, or Fajr prayer CTAs.
- No new platform reliability claims beyond the app's current AlarmKit/notification capabilities.

## Decisions

1. **Add a compatibility layer instead of renaming every internal legacy enum.** Existing enum cases such as historical Pre-Fajr or Quiet selection may remain internally if they are decoded from persisted data, but presentation and mutation APIs must normalize visible MVP choices to Fajr/Suhoor plus alarm-state overrides. This reduces migration risk while removing product-language drift.

2. **Store Pause as global app settings and ring-once as a date-level override.** `AppSettings` or the existing wake-alarm settings store should own `pausedIndefinitely`; `MorningPlanStore` should own date overrides such as quiet and ring despite pause. This matches the spec precedence and keeps one-off exceptions from disabling global Pause.

3. **Resolve final alarm state in domain/presentation assembly, not inside SwiftUI controls.** `MorningWakeResolutionService`, `WakeStateSelectionResolver`, and `MorningHomePresentation` should expose resolved states that views render. SwiftUI should not infer Quiet, Pause, blocked, or issue states from local booleans.

4. **Keep scheduling changes scoped by date/session identifiers.** Quiet, Pause, acknowledgement, and stale-state reconciliation should cancel only the affected Subh wake primary/follow-up identifiers. This preserves the alarm reliability rule that unrelated alarms are not cancelled by one morning's edit.

5. **Use fixed slots in presentation contracts.** Home Hero should expose a stable Slot 6 model for selector, active acknowledgement, post-awake CTA, or checked pill. Views can crossfade contents, but they should not add/remove vertical rows by state.

6. **Expand the test harness through scenario inputs, not a second resolver.** Wake Session Lab scenarios should feed the same snapshot/presentation path used by Home. Test-only state remains marked and isolated from real user settings, plans, logs, and scheduled production alarms.

## Risks / Trade-offs

- **Risk: legacy values still exist in storage** -> Normalize to MVP-visible Fajr/Suhoor behavior at read/presentation boundaries and avoid destructive migrations in this pass.
- **Risk: partial Pause implementation could suppress the wrong alarms** -> Add date-key/session-scoped tests and keep cancellation through existing scheduling identifier helpers.
- **Risk: fixed-height Hero can regress Dynamic Type behavior** -> Preserve existing typography/accessibility behavior while keeping state transitions in fixed slots; validate by tests/simulator where available.
- **Risk: system alarm dismissal source may not be available in every current adapter path** -> Treat dismissal as acknowledgement at the Wake Session layer and store source only where the current event/delegate path can distinguish it. Document any remaining source fidelity gap in the implementation report.
- **Risk: this pass crosses many surfaces** -> Prioritize authoritative domain state, Home/Detail visible copy, and safety-critical delivery state first; avoid unrelated visual rewrites.

## Migration Plan

1. Add/extend typed models for date alarm overrides, global pause policy, resolved alarm state, and acknowledgement source while preserving existing decoded values.
2. Update stores and resolvers to preserve separate Fajr/Suhoor alarm configurations and apply the May 29 precedence order.
3. Update Home, Detail, forecast/month, Settings, and harness presentation to consume resolved alarm state and copy.
4. Update scheduling and Wake Session handling so Quiet/Pause suppress or cancel only affected Subh wake alarms; acknowledgement cancels remaining follow-up alarms for that morning.
5. Add tests around model precedence, setting persistence, copy mapping, and wake-session state.
6. Validate with OpenSpec, XCTest/build, and targeted manual/simulator inspection where feasible.

Rollback is a normal code rollback. No irreversible user-data migration is planned.

## Open Questions

- Whether current AlarmKit callbacks can always distinguish explicit system dismissal from other stop/silence events. If not, MVP behavior still treats explicit dismissal as acknowledgement, with source precision documented as a follow-up.
- Whether the current UI test harness can assert fixed Hero height directly, or whether that check remains manual/snapshot-oriented for this pass.
