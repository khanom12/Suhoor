## Context

The Subh home background currently renders `AppPageBackground`, `AppAtmosphericCloudLayer`, `AppHomeContrastOverlay`, and foreground content. The asset-backed cloud layer is correctly placed below the contrast overlay, but the existing single overlay applies strong black/tint values across the top hero area and can obscure cloud detail.

This change affects only SwiftUI presentation in `Subh/Features/Home/SubhHomeView.swift`, `Subh/UI/Components/AppGlassSystem.swift`, and `Subh/UI/Components/AppAtmosphericCloudLayer.swift`. It does not touch schedule calculation, alarm scheduling, AlarmKit, wake mode selection, Fajr/suhoor logic, settings, persistence, notifications, or data models.

## Goals / Non-Goals

**Goals:**

- Make the top-hero cloud layer clearly visible but still subtle behind the home hero.
- Preserve text, card, and control readability through a softer foreground contrast layer.
- Keep cloud content clipped to the upper hero region instead of visually extending down the full screen.
- Preserve deterministic parallax ordering and Reduce Motion static cloud positions.

**Non-Goals:**

- No changes to morning-resolution logic, alarm behavior, scheduling, persistence, settings, notifications, or pricing/tier behavior.
- No new third-party dependencies.
- No redesign of cards, hero ownership, navigation, or home information architecture.

## Decisions

- Split home contrast into two named overlays: a weak `AppHomeAtmosphereBaseOverlay` below clouds and a softer `AppHomeForegroundContrastOverlay` above clouds. This embeds the static dawn background without crushing cloud detail, while keeping readability concerns explicit.
- Keep the existing `AppHomeContrastOverlay` default behavior intact for non-home call sites that still use the previous full overlay.
- Use the initial requested opacity model: base atmosphere black `0.06` with gradient stops `0.16`, `0.10`, `0.04`, `0.015`; foreground readability black `0.12` with gradient stops `0.38`, `0.24`, `0.12`, `0.05`.
- Increase cloud asset opacities into the recommended range and keep normal alpha compositing instead of adding an aggressive blend mode. This keeps the clouds realistic under tint rather than bright or pasted onto the interface.
- Compute the cloud region from the top hero area using a responsive clamped height, and make band offsets relative to that region. The cloud stack remains clipped and faded at the bottom edge.

## Risks / Trade-offs

- Clouds could become visually competitive with hero text or glass surfaces -> tune opacity and foreground overlay values within the specified range and verify screenshots.
- The split overlay changes only the home screen stack; other screens retain the legacy overlay -> preserve `AppHomeContrastOverlay` as the default to avoid unrelated visual churn.
- Simulator screenshot diffs can confirm motion and Reduce Motion behavior, but visual subtlety still needs human review -> inspect screenshots after launch in addition to automated build/test validation.
