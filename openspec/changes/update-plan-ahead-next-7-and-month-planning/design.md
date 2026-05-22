## Current Implementation Anchors

- `Subh/Features/Home/SubhHomeView.swift` owns the single Home `NavigationStack`, hero, primary context card, forecast card, month planning tiles, Weekly Fajrcast, and detail navigation.
- `Subh/Features/Home/MorningHomeSnapshot.swift` and `Subh/Features/Home/MorningHomePresentation.swift` own the current seven-row forecast title, row display models, row metrics, date labels, tag resolver, and accessibility copy.
- `Subh/Core/ProductSurfacePresentation.swift` is the shared source for day/context tag presentation and already exposes the compact forecast surface.
- `Subh/Features/MonthPlanning/MonthPlanningPresentation.swift` owns month horizon, picker month, detail snapshot, and row display models.
- `Subh/Features/MonthPlanning/MonthPlanningViews.swift` owns Home month tiles, picker/detail SwiftUI, locked state, and Monthly Fajrcast placeholder.
- `AlarmDayDetailView` remains the only day-editing surface reached from forecast and month rows.

## Approach

1. Keep the existing "NextTen" internal type names for this pass where they are already entrenched, but update all visible product copy and accessibility copy to `Next 7 Mornings`.
2. Restructure Home's Plan ahead section so the heading wraps the Next 7 Mornings card first, followed by the two month planning tiles. Remove the heading from the standalone month-tile component to avoid duplicate section labels.
3. Centralize compact context-tag filtering in the existing forecast presentation model. It will consume shared tag snapshots and surface only calendar/opportunity context tags visually while preserving hidden wake/intention meanings for accessibility/detail.
4. Change Quiet rows to provide trailing `Quiet` from the display model instead of rendering Quiet as a middle-lane chip.
5. Reuse the forecast context-tag display and row-grid concepts for Month Detail rows. Month rows keep primary/secondary date labels in the left lane, context tags in the center lane, and wake/status in the trailing lane.
6. Update Month Picker from a full-width list to a two-column card grid where space allows, with stable near-square card shells and complementary date-range context.
7. Add v2 docs/spec files without deleting the older v1 files. Add a v2 index/source map that marks the new planning specs as canonical.

## Guardrails

- Do not add new prayer-time, Hijri, fasting-observance, entitlement, alarm, or scheduling engines.
- Do not parse visible strings to derive tags.
- Do not persist generated month rows or schedule platform alarms from rendering Home, picker, or detail surfaces.
- Do not introduce purchase/paywall logic.
- Do not reintroduce Tahajjud or non-fasting pre-Fajr product behavior.

## Verification

- OpenSpec validation for this change.
- Focused XCTest for Next 7 tag doctrine, naming, Quiet trailing status, and Month Planning row/picker presentation.
- Xcode build/tests for the Subh scheme where practical.
- Manual diff review for no broad rename, no unrelated file staging, no new persistence side effects, and no scheduling calls from planning views.
