## Why

The home atmospheric cloud layer now needs to use the revised Subh-specific parallax cloud asset pack instead of procedural placeholder drawing or the earlier four-layer asset pack. This makes the background easier to tune visually while preserving the existing calm, readable home screen and adding clear depth-based motion.

## What Changes

- Copy the five provided atmospheric `.imageset` folders into `Subh/Resources/Assets.xcassets/`.
- Replace the procedural cloud drawing in `AppAtmosphericCloudLayer` with asset-backed, horizontally repeating SwiftUI bands based on the revised parallax sample integration.
- Keep the layer between `AppPageBackground` and `AppHomeContrastOverlay`.
- Preserve decorative behavior, Reduce Motion static rendering with deterministic phase offsets, and slow seamless horizontal motion.
- Use the supplied depth ordering and loop durations so the near wisp moves fastest, followed by low, mid, far, and mist as the slowest layer.
- Do not change alarm scheduling, wake mode behavior, hero state, Fajr calculations, cards, settings, data models, or unrelated UI.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: The home atmospheric background shall use the provided Subh dawn parallax cloud assets while staying decorative, readable, and Reduce Motion-aware.

## Impact

- Affected code: `Subh/UI/Components/AppAtmosphericCloudLayer.swift` and `Subh/Features/Home/SubhHomeView.swift` only if stack placement needs correction.
- Affected assets: `Subh/Resources/Assets.xcassets/SubhDawnCloudWispFar.imageset`, `SubhDawnCloudWispMid.imageset`, `SubhDawnCloudWispLow.imageset`, `SubhDawnCloudWispNear.imageset`, and `SubhDawnMistVeil.imageset`.
- No external dependencies.
- Existing scheduled alarms, cached schedules, persisted settings, prayer calculations, and alarm delivery behavior are not affected.
