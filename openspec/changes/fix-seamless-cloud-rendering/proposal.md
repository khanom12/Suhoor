## Why

The atmospheric home clouds currently drift in the right direction, but the repeated image strip can reveal hard vertical boundaries or abrupt cloud entry when a tile edge crosses the hero region. This is a renderer issue caused by hard tiling, full-width modulo movement, and image cropping risk, not a product logic issue.

## What Changes

- Replace the hard repeated `HStack` cloud-band renderer with a seam-safe renderer.
- Preserve each 2:1 transparent cloud canvas without using `.scaledToFill()` cropping.
- Feather each repeated tile horizontally so left and right tile edges fade out.
- Overlap repeated tiles by the feather width so adjacent tiles crossfade instead of meeting at a hard edge.
- Add offscreen overscan and dynamic copy counts so every device width has coverage before, during, and after modulo reset.
- Keep right-to-left parallax motion, top-hero-only clipping, foreground readability, decorative-only behavior, and Reduce Motion static phases.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: clarifies that atmospheric cloud bands must render as seamless, feathered, overlapping, overscanned right-to-left fields without visible tile boundaries.

## Impact

- Affected code: `Subh/UI/Components/AppAtmosphericCloudLayer.swift`.
- Affected specs: `single-screen-morning-home`.
- No API, dependency, scheduling, AlarmKit, persistence, notification, settings, card, pricing, or data model changes.
- Existing scheduled alarms, cached schedules, and persisted settings are not affected.
