## Why

The home atmospheric cloud layer is present but too easy to miss because the full home contrast overlay darkens and tints the top hero area after the clouds render. This change makes the clouds clearly perceptible while preserving the calm, readable Fajr-centered home surface.

## What Changes

- Split the home background contrast treatment into a weak atmosphere-embedding overlay below the clouds and a softer foreground readability overlay above the clouds.
- Keep the cloud system confined to the upper hero region so the lower home remains the existing dawn background and glass treatment.
- Increase cloud layer visibility only enough for realistic, subtle motion to be visible behind the hero content.
- Preserve the depth/parallax model, decorative-only behavior, and Reduce Motion static phase behavior.
- Do not change alarm scheduling, wake modes, Fajr/suhoor calculations, persistence, notifications, settings, cards, or other product logic.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: clarifies atmospheric cloud visibility, split contrast layering, top-hero confinement, depth ordering, and Reduce Motion behavior for the home background stack.

## Impact

- Affected code: `Subh/Features/Home/SubhHomeView.swift`, `Subh/UI/Components/AppGlassSystem.swift`, and `Subh/UI/Components/AppAtmosphericCloudLayer.swift`.
- Affected specs: `single-screen-morning-home`.
- No API, dependency, scheduling, persistence, notification, or alarm behavior changes.
- Existing scheduled alarms, cached schedules, and persisted settings are not affected.
