## Why

The new context/tag specs close a drift risk between Home, Next 7 Days, Weekly Fajrcast, and Alarm Detail: each surface has enough local tag and context copy to disagree about whether a day is merely meaningful, selected for Suhoor, locked by Ramadan, forbidden for fasting, or quietly suppressed.

This change makes day-context presentation a shared adapter over the existing resolved morning spine. `ResolvedDayPurpose` remains the source of opportunity, intention, required-action, and credit separation; visible tags and context copy become presentation outputs rather than local surface inference.

## What Changes

- Add the four attached working specifications to `docs/specs/` and update the spec index with the primary context/shared tag alignment decision.
- Introduce shared day-tag presentation models and a resolver derived from `ResolvedDayPurpose`, `ResolvedMorningWakeState`, and the existing resolved day snapshot.
- Introduce a primary morning context presentation adapter for compact Home context and expanded Alarm Detail context.
- Place the Home Primary Morning Context module between the Hero and Next 7 Days when the resolved context is meaningful, selected, Quiet, forbidden, Ramadan, or unavailable.
- Update Next 7 Days tags to consume the shared tag snapshot instead of locally deriving wake mode, opportunity, Ramadan, Quiet, or fasting-purpose labels from raw tags.
- Update Alarm Detail context copy to reuse the same primary context payload instead of maintaining a separate opportunity/context sentence engine.
- Add focused presentation tests for opportunity-only, Suhoor-on-opportunity, Qada-on-opportunity, Ramadan, forbidden-day, and Quiet-overlay cases.

## Capabilities

### New Capabilities

- `shared-day-tag-presentation`: Shared tag/chip presentation across compact rows, primary context, Alarm Detail, and future forecast surfaces.
- `primary-morning-context-presentation`: Shared Home and Alarm Detail day-meaning context presentation derived from the resolved morning graph.

### Modified Capabilities

- `single-screen-morning-home`: Home order and support-surface tag semantics now require Hero, Primary Morning Context, Next 7 Days, then Weekly Fajrcast; Next 7 Days consumes shared tags.
- `morning-resolution`: Clarifies that shared tags and primary context are presentation adapters over `ResolvedDayPurpose` and do not create a second resolver, scheduler, or analytics source.

## Impact

- Affected Swift code: `Subh/Core/ProductSurfacePresentation.swift`, `Subh/Features/Home/MorningHomePresentation.swift`, `Subh/Features/Home/SubhHomeView.swift`, and `Subh/Features/Alarms/AlarmDayDetailView.swift`.
- Affected tests: focused presentation coverage in `SubhTests/TagComputationEngineTests.swift`.
- Documentation changes are limited to `docs/specs/` and this OpenSpec change.
- No production dependencies are added.
- Existing scheduled alarms, cached schedules, persisted settings, storage namespaces, prayer-time calculation, Fajr begin/end behavior, and alarm delivery semantics are not migrated or rewritten by this change.
