## Why

The updated v2 planning specs tighten Subh's Home planning hierarchy and compact-row doctrine: users should see near-term planning first, then longer-range month planning, with surfaces consistently described as mornings rather than days. This keeps planning centered on resolved Fajr mornings while removing routine state tags that made compact rows feel like alarm/debug summaries.

## What Changes

- Replace visible `Next 7 Days` / `7-Day Wake Forecast` language with `NEXT 7 MORNINGS`.
- Place the expanded/collapsed Next 7 Mornings card inside Home's `Plan ahead` section above `Calendar Months` and `Hijri Months`.
- Add the helper copy `View and plan your next seven mornings` to the forecast header.
- Update compact forecast rows so the middle lane only shows opportunity/context tags and Quiet appears as trailing `Quiet`.
- Update Month Planning Home tiles, Month Picker cards, and Month Detail rows to match the v2 tile/grid/row direction.
- Add v2 working specs to `docs/specs/` and update the spec index/source map so the v2 planning specs are canonical.
- Preserve the existing entitlement, Hijri, Fajr, resolver, Day Detail, persistence, and scheduling seams.

## Capabilities

### New Capabilities
- `next-7-mornings-wake-forecast`: Defines the Home Plan ahead forecast card, naming, collapsed/expanded behavior, row anatomy, context tag doctrine, Quiet trailing status, and accessibility.
- `month-planning-gregorian-hijri`: Defines Gregorian and Hijri month planning v2 placement, picker grid, detail row anatomy, entitlement use, and no-persistence/no-scheduling guardrails.

### Modified Capabilities
- `single-screen-morning-home`: Updates the Home MVP card/section requirements so Plan ahead contains Next 7 Mornings above Calendar/Hijri month planning, with high-contrast heading treatment.

## Impact

- Affected SwiftUI surfaces: `SubhHomeView`, Home forecast row/card views, `PlanAheadTiles`, `MonthPlanningPickerView`, `MonthPlanningDetailView`.
- Affected presentation/domain adapters: `MorningHomeSnapshot`, `MorningHomePresentation`, `MonthPlanningPresentation`, and the shared tag presentation consumed by those display models.
- Affected tests: Home/forecast presentation tests and Month Planning presentation tests.
- Documentation impact: add v2 Next 7 and Month Planning specs and a v2 spec index/source map.
- No migration impact, no stored-setting change, no StoreKit/purchase logic, and no platform alarm scheduling change.
