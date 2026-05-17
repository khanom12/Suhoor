## Context

The Subh home background stack is `AppPageBackground`, `AppAtmosphericCloudLayer`, `AppHomeContrastOverlay`, then the existing foreground content and settings control. The AI weather cloud pack supersedes the earlier procedural and full-screen parallax cloud assets with five coordinated transparent image layers intended for the upper hero region only.

The affected SwiftUI file is `Subh/UI/Components/AppAtmosphericCloudLayer.swift`; `Subh/Features/Home/SubhHomeView.swift` should remain unchanged if the insertion point is still correct. The asset catalog removes the old wisp/mist image sets and receives the five new `SubhDawnHeroCloud*` image sets.

## Goals / Non-Goals

**Goals:**
- Use the provided AI-generated hero cloud assets as horizontally repeating bands.
- Preserve the existing home layer order so clouds stay above the static background and below the contrast/tint overlay.
- Constrain visible cloud content to the top hero area, not the full screen or scroll view.
- Respect `accessibilityReduceMotion` by rendering deterministic static phase offsets when enabled.
- Keep the layer decorative with hit testing disabled and hidden from the accessibility tree.
- Keep motion depth monotonic: near fastest, then low, mid, far, and mist slowest.
- Tune only opacity, `yOffset`, or `heroCloudHeight` if simulator verification shows readability issues.

**Non-Goals:**
- Change alarm scheduling, wake mode behavior, hero state logic, Fajr/suhoor calculations, cards, settings, persistence, data models, notifications, or AlarmKit behavior.
- Add third-party animation/image dependencies.
- Introduce new product surfaces or copy.

## Decisions

- Adapt the provided sample instead of preserving the prior full-screen implementation. The new assets are built on a shared 1024 x 512 top-hero canvas and should not be stretched down the home surface.
- Use `heroCloudHeight = min(max(height * 0.40, 320), 430)` from the handoff to keep the cloud field localized around the hero.
- Keep all layers drifting in the same horizontal direction. Loop durations provide the depth cue: near `78s`, low `116s`, mid `168s`, far `235s`, mist `290s`.
- Use three repeated image tiles per layer for seamless horizontal looping.
- Keep deterministic phase offsets per layer so clusters do not align in normal motion or Reduce Motion.
- Keep the component self-contained and decorative: callers only place it in the background stack.

## Risks / Trade-offs

- Clouds may appear too strong over the hero -> tune opacity downward while preserving visible motion.
- Clouds may be too faint after `AppHomeContrastOverlay` -> tune opacity upward only enough to verify presence.
- Repeating image bands add texture memory and animation work -> keep to five supplied layers, slow loop durations, and a non-animated path for Reduce Motion.
