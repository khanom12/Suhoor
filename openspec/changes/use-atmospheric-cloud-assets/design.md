## Context

The Subh home background stack is `AppPageBackground`, `AppAtmosphericCloudLayer`, `AppHomeContrastOverlay`, then the existing foreground content and settings control. A prior procedural `Canvas` layer made cloud motion possible, but the revised parallax asset pack now supplies final transparent PNG cloud bands, a sample SwiftUI integration, README guidance, a depth model, and an asset manifest for opacity, timing, and placement.

The affected SwiftUI files are `Subh/UI/Components/AppAtmosphericCloudLayer.swift` and, only if the insertion point has drifted, `Subh/Features/Home/SubhHomeView.swift`. The asset catalog receives the five provided `.imageset` folders.

## Goals / Non-Goals

**Goals:**
- Use the provided Subh dawn cloud and mist parallax assets as horizontally repeating bands.
- Preserve the existing home layer order so clouds stay above the static background and behind the contrast/tint overlay.
- Respect `accessibilityReduceMotion` by rendering deterministic static phase offsets when enabled.
- Keep the layer decorative with hit testing disabled and hidden from the accessibility tree.
- Keep motion depth monotonic: near fastest, then low, mid, far, and mist slowest.
- Tune only opacity or vertical offsets if simulator verification shows readability issues.

**Non-Goals:**
- Change alarm scheduling, wake mode behavior, hero state, Fajr calculations, cards, settings, data models, or navigation.
- Add third-party animation/image dependencies.
- Introduce new product surfaces or copy.

## Decisions

- Replace procedural drawing with asset-backed SwiftUI bands. The assets are purpose-built, transparent, and easier to replace/tune than procedural ellipses.
- Adapt the sample integration instead of copying it blindly. The production component should keep Reduce Motion from running unnecessary animation frames and fit the existing Subh component style.
- Use three repeated image tiles per band. This follows the handoff guidance and avoids edge gaps while bands animate horizontally in either direction.
- Use README, depth-model, and manifest loop durations and opacities as the baseline. Any tuning should be limited to opacity and vertical offsets after simulator review.
- Keep every layer drifting in the same horizontal direction. Differing loop durations provide depth without visual disagreement.
- Use distinct phase offsets per layer so cloud clusters do not align in normal motion or Reduce Motion.
- Apply the recommended extra blur per band in SwiftUI. This keeps the imported images soft after the existing contrast overlay and prevents the clouds from competing with morning content.

## Risks / Trade-offs

- Clouds may appear too strong on top of the existing dawn background -> tune opacity downward while preserving inspectable motion.
- Clouds may be too faint after `AppHomeContrastOverlay` -> tune opacity upward only enough to verify presence.
- Repeating image bands add texture memory and animation work -> keep to five supplied layers, slow loop durations, and a static path for Reduce Motion.
