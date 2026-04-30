## Context

The current resolver already produces a `ResolvedDaySnapshot` with prayer window, resolved context, selected plan, behavior profile, materialized events, completion records, and daily completion. The fasting domain already understands Ramadan, forbidden days, qada, voluntary fasts, secondary virtue tags, and strict normalization. The missing layer is the durable product meaning between calendar/context facts, user intention, execution outcome, and future analytics credit.

## Decisions

1. **Separate meaning from intention.**
   A date may expose one or more `ObservanceOpportunity` values. These are date meanings and do not schedule early wake, require fast completion, or produce missed-fast analytics by themselves.

2. **Use intention to explain active purpose.**
   `ResolvedDayIntention` classifies the day as default Fajr, fast, Tahajjud, or quiet. The MVP derives fast intentions from existing `fastTagSelections` and auto-Ramadan behavior; quiet and Tahajjud remain future hooks unless existing state already supplies them.

3. **Keep the existing scheduling engine authoritative.**
   Existing `MorningPlanResolver`, wake rules, `WakeResolutionResult`, behavior profiles, and event materialization remain the source of alarm behavior. The first implementation classifies the resolved wake result instead of replacing wake selection.

4. **Keep tags as presentation metadata.**
   `DayTag` and `ResolvedDayContext` remain compatibility and UI data. Analytics must use opportunity IDs and `ObservanceCredit` values rather than raw visual tags.

5. **Emit credits as derived facts.**
   The credit resolver emits available/planned/completed/missed-after-planning/kept-default/quiet-suppressed/invalid-forbidden facts from the resolved opportunity, intention, and completion combination.

6. **Keep qada primary.**
   A completed qada fast on a White Day or Monday/Thursday date credits qada, not the secondary Sunnah opportunity, unless a future explicit coexistence policy is introduced.

## Risks / Trade-offs

- Adding a resolved layer increases model surface area, but prevents analytics ambiguity and avoids overloading `DayTag`.
- The first implementation computes purpose after completion so it can classify current pipeline output without changing alarm behavior.
- Existing UI may initially show only the legacy context output; future presentation work can consume the purpose aggregate directly.
- Quiet and Tahajjud persistence are intentionally left as future hooks to avoid inventing storage before the product flow exists.
