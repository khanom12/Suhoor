## Why

The home atmospheric cloud layer needs to use the AI-generated top-hero weather cloud pack instead of the earlier procedural or parallax wisp assets. The new assets are synchronized transparent layers designed to sit behind the existing Subh home tint and appear only around the upper hero area.

## What Changes

- Copy the five `SubhDawnHeroCloud*` `.imageset` folders into `Subh/Resources/Assets.xcassets/`.
- Remove the obsolete `SubhDawnCloudWisp*` and `SubhDawnMistVeil` `.imageset` folders from earlier passes.
- Update `AppAtmosphericCloudLayer` to use the supplied top-hero sample integration with five horizontally repeating cloud layers.
- Keep the layer between `AppPageBackground` and `AppHomeContrastOverlay`.
- Confine visible cloud content to the top hero region with a clipped/faded hero-height band.
- Preserve decorative behavior, deterministic Reduce Motion frozen phases, and depth-based parallax motion.
- Do not change alarm scheduling, wake modes, Fajr/suhoor calculations, hero state logic, cards, settings, notification/AlarmKit logic, persistence, or data models.

## Capabilities

### Modified Capabilities
- `single-screen-morning-home`: The home atmospheric background shall use the provided top-hero AI weather cloud assets while staying decorative, readable, layer-ordered behind the tint, and Reduce Motion-aware.

## Impact

- Affected code: `Subh/UI/Components/AppAtmosphericCloudLayer.swift`; `Subh/Features/Home/SubhHomeView.swift` only if stack placement has drifted.
- Affected assets: remove prior `SubhDawnCloudWispFar`, `SubhDawnCloudWispMid`, `SubhDawnCloudWispLow`, `SubhDawnCloudWispNear`, and `SubhDawnMistVeil`; add `SubhDawnHeroCloudMist`, `SubhDawnHeroCloudFar`, `SubhDawnHeroCloudMid`, `SubhDawnHeroCloudLow`, and `SubhDawnHeroCloudNear`.
- No external dependencies.
- Existing scheduled alarms, cached schedules, persisted settings, prayer calculations, and alarm delivery behavior are not affected.
