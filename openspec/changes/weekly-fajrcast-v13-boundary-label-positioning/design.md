## Overview

Weekly Fajrcast v13 is a narrow presentation refinement for the compact chart's in-chart Fajr boundary labels. It keeps the v12 tangent-following behavior and bottom-callout geometry intact while improving how the labels separate from the boundary strokes and plot boundaries.

## Boundary Label Placement

- Continue sampling each rendered boundary line near the plot's leading side and converting the local screen-space slope to `labelAngleRadians`.
- Treat each label as a rotated bounding box for placement purposes.
- Use a leading label lane with preferred 6 point clearance from the plot's left boundary after rotation.
- Keep the rotated label box inside the plot with preferred 6 point clearance, and at least 4 points where constrained, from the top, bottom, and left plot boundaries.
- Offset the label center along the selected boundary normal by the requested boundary clearance plus the rotated box's half-extent along that normal.

## Boundary Side Selection

- `Fajr ends` remains below the Fajr-end boundary line in normal states.
- `Fajr begins` sits above the Fajr-begin boundary by default.
- If the resting focus or visible active wake pattern places the relevant wake markers before Fajr begins, `Fajr begins` moves below the begin boundary to avoid the pre-Fajr marker lane.
- The side decision is tied to the resting/static Weekly Fajrcast pattern, not to temporary scrub focus, so labels do not chase the user's finger.

## Clearance Constants

- `minimumBoundaryClearance = max(5, 0.30 * scaledBoundaryLabelLineHeight)`.
- `preferredBoundaryClearance = max(6, 0.35 * scaledBoundaryLabelLineHeight)`.
- Plot-edge clearance should prefer 6 points and remain at least 4 points where possible.
- If preferred boundary clearance would press a label into a plot boundary, reduce toward the minimum clearance before changing the label side.

## Risks

- SwiftUI does not expose exact post-render glyph bounds. The implementation therefore uses measured text width, scaled line height, and rotated rectangle math as the deterministic approximation.
- Extreme localized text or accessibility sizes may still require broader chart/card height growth in a later pass; this change should not hide labels or shrink them below axis-label size to solve collisions.
