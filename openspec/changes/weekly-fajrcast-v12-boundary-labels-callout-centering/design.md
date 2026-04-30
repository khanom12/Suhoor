## Overview

Weekly Fajrcast v12 is a presentation refinement. The implementation should keep the existing seven-day anchored chart and footer semantics intact while improving the geometry of two chart elements.

## Boundary Label Geometry

- Use the rendered compact plot frame and visible day x-positions to sample the local slope of the Fajr begin and Fajr end boundary paths.
- Anchor labels near the plot's leading edge, clamped inside the plot content frame.
- Sample the boundary at `anchorX - radius` and `anchorX + radius`, where radius is based on day-column width and clamped to a small range.
- Convert the sampled screen-space delta into a rotation angle with `atan2`.
- Place `Fajr begins` above its boundary and `Fajr ends` below its boundary using a normal offset based on scaled label line height.
- Keep labels readable, near the left/past side, and independent of scrub focus.

This keeps the labels attached to the actual rendered Fajr lines without adding religious or calculation logic to the renderer.

## Bottom Callout Centering

- Treat the selected-day callout as one measured block.
- Compute the callout top from the interstitial area between the plot bottom and the bottom edge of the compact chart layout.
- The top and bottom gaps around the callout should match geometrically after pixel snapping.
- Minimum gap values remain the v11/v12 values: 4 points for smaller stops, 5 at default, 6 at larger standard stops, and `max(6, 0.28 * scaledCalloutLineHeight)` for accessibility.
- Grow chart/card height before allowing overlap.

The chart view owns this geometry; the surrounding card should not add unrelated blank space inside the chart pocket.

## Risks

- SwiftUI does not expose post-render glyph bounds directly, so collision handling remains conservative. The implementation uses measured label width and local tangent geometry to avoid the most obvious floating-label drift.
- Pixel-perfect equality may differ by platform font metrics, so tests should validate deterministic geometry helpers rather than screenshot pixels.
