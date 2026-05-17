## Why

The atmospheric home background layer exists, but the current rendering is too faint under the existing home tint and contrast overlay for a user to reliably confirm it is present. This change makes the decorative clouds visibly inspectable while keeping the home screen calm, readable, and non-interactive.

## What Changes

- Tune the home atmospheric cloud layer so wispy cloud bands are visibly present above the static wake background and below the contrast overlay.
- Preserve slow seamless horizontal motion for normal motion settings.
- Preserve a static decorative rendering when Reduce Motion is enabled.
- Keep the layer decorative only, with no hit-testing or accessibility exposure.
- Do not change wake resolution, alarm scheduling, settings, data models, hero state logic, or forecast behavior.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: The home background shall include a decorative atmospheric cloud layer that is visibly present, remains readable under overlays, and respects Reduce Motion.

## Impact

- Affected code: `Subh/UI/Components/AppAtmosphericCloudLayer.swift` and the home background stack in `Subh/Features/Home/SubhHomeView.swift` if needed.
- No external dependencies.
- No persisted settings, cached schedules, scheduled alarms, prayer calculations, or alarm delivery behavior are affected.
