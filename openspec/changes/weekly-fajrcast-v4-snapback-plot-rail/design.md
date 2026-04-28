## Context

The v3 implementation leaves the anchored seven-day window stable while allowing the user to focus another visible day. That focus currently persists until another app state change. The v4 spec changes the mental model: interaction is temporary inspection, and release returns the card to the next alarm/resting focus.

The compact chart currently accepts `selectedDateKey` through the chart snapshot and uses it for guide, callout, x-axis emphasis, marker emphasis, and the selected range backdrop. The current backdrop follows the selected/focused day, which conflicts with the v4 static elapsed overlay rule.

## Goals / Non-Goals

**Goals:**

- Add a release/snap-back path for compact chart touch gestures.
- Preserve accessible increment/decrement inspection while allowing visual reset to the resting focus.
- Keep the static elapsed overlay based on the snap-back/resting focus rather than the inspected day.
- Increase card/chart guardrails to v4 values and preserve a 160 pt minimum plot scale height.
- Make compact y-axis labels trailing aligned to a fixed right boundary.

**Non-Goals:**

- Add a new detail destination payload.
- Introduce new no-alarm/quiet domain states.
- Change alarm scheduling or MorningPlan resolution.
- Replace SwiftUI layout with a fully custom measured layout engine.

## Decisions

1. **Represent snap-back target with the existing anchor date key.**
   - The current data layer already resolves the anchor as the next relevant morning and exposes `anchorDateKey`.
   - v4 allows the snap-back target to normally equal the anchor. A distinct `snapBackTargetDateKey` can be added later if the data layer needs a non-center resting focus.

2. **Keep temporary inspection state in `SubhHomeView`.**
   - The existing `weeklyFajrcastFocusedDateKey` already rebuilds the compact snapshot for an inspected day.
   - On gesture end, the view clears that state so the card returns to the base snapshot and its anchor/resting focus.

3. **Add chart gesture end callback.**
   - `FajrWindowChartView` already owns hit testing from x-coordinate to visible day. It should also notify when inspection ends.

4. **Use an explicit static backdrop date key.**
   - Compact chart rendering gets a `compactStaticBackdropDateKey` separate from `chart.selectedDateKey`.
   - During scrub, guide/callout/marker emphasis follow selected date, while the elapsed overlay remains anchored to the static key.

5. **Encode v4 size guardrails directly in layout profiles.**
   - Stop 4 baseline becomes 292 card height, 214 chart region, 160 static plot height, 46 rail width.
   - Accessibility sizes continue growing above the seven standard stops.

## Risks / Trade-offs

- **Risk: A tap may flash the inspected day only briefly.** → Mitigation: v4 defines tap as short inspection; persistent selection can be reintroduced only with a separate explicit selection model.
- **Risk: Accessibility inspection does not have a physical release moment.** → Mitigation: adjustable actions can inspect and leave focus long enough to hear it; visual reset can occur when default action/navigation or subsequent blur support is added.
- **Risk: Static overlay remains column-based rather than marker-time refined.** → Mitigation: v4 permits default column-based overlay when no explicit boundary geometry is supplied.
