## Context

`WeeklyFajrcastCard` is the compact Fajrcast surface currently rendered from the home flow and implemented in `Subh/Features/Wake`. The provided recreation spec treats the component as a dark glass signature visual with a strict five-part content structure and a selected-day summary model.

## Goals / Non-Goals

**Goals:**
- Match the provided component structure, shell parameters, spacing, typography, opacity, marker, and footer-summary rules.
- Keep chart computation in `FajrWindowSurfaceProvider` and chart drawing in `FajrWindowChartView`.
- Preserve Dynamic Type and accessibility behavior.
- Preserve the secondary summary data model even though the visual footer only renders the primary sentence.

**Non-Goals:**
- No movement to a Wake primary tab or separate Wake screen in this change.
- No Fajr calculation, wake resolution, scheduling, or persistence changes.
- No detail-screen redesign and no added analytics/dependencies.

## Decisions

- Remove the extra chart context strip (`Wake time / Earlier / Later`) because it is not part of the recreation structure and makes the card denser than specified.
- Pass explicit `tint: .black` and `tintOpacityMultiplier: 4.5` into `AppGlassSurface` so the card owns its intended shell treatment instead of inheriting the global default multiplier.
- Keep compact chart opacity values local to `FajrWindowChartView`, using the spec's white-opacity map for scaffold, band, boundary, marker, and axis roles.
- Reuse the existing `compactSubject` and `compactRelationClause` helpers to build the footer primary sentence in `FajrWindowSurfaceProvider`.
- Store DST/adjusted/fasting compact summary text in `secondaryText`; the card accessibility summary already includes it while the visual footer stays concise.

## Risks / Trade-offs

- [Risk] Removing the chart context strip may reduce explicit axis explanation. -> Mitigation: the selected callout, weekday axis, y-axis labels, interval labels, and accessibility summary preserve the functional explanation.
- [Risk] The provided placement language differs from current OpenSpec primary-home IA. -> Mitigation: this pass aligns the component wherever it renders and leaves placement unchanged until the product IA spec is deliberately updated.
