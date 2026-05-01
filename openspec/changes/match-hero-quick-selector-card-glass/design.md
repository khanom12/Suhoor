# Design

## Glass Reuse

Weekly Fajrcast and Next 10 Mornings both use `AppGlassSurface(variant: .grouped, contentPadding: 0)`. The Morning Hero quick selector should reuse that same surface variant instead of maintaining separate custom material, tint, stroke, and shadow overlays.

## Pill Geometry

The selector remains a pill-shaped segmented control. A corner-radius override on `AppGlassSurface` lets the control keep its pill geometry while inheriting the grouped-card material, tint, stroke, and shadow values from the shared glass system.

## Behavior Preservation

The selected capsule, accessibility identifiers, disabled opacity, segment layout, and mode-switching animations remain unchanged. This change affects only the outer selector background treatment.
