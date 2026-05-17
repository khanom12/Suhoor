## Context

The Subh home background currently stacks `AppPageBackground`, `AppAtmosphericCloudLayer`, `AppHomeContrastOverlay`, and foreground scroll content. The cloud layer is deterministic and decorative, but its opacity and soft shapes are faint enough that the existing dark contrast overlay can make the effect effectively invisible in normal use.

The affected SwiftUI files are `Subh/UI/Components/AppAtmosphericCloudLayer.swift` and, only if layering needs correction, `Subh/Features/Home/SubhHomeView.swift`.

## Goals / Non-Goals

**Goals:**
- Make the atmospheric cloud layer plainly visible during visual inspection while remaining calm behind the home content.
- Preserve slow seamless horizontal motion in normal motion mode.
- Preserve a static rendering when Reduce Motion is enabled.
- Keep the layer decorative, non-interactive, and hidden from accessibility.

**Non-Goals:**
- Change alarm scheduling, wake mode behavior, hero state, charts, settings, persistence, or calculation logic.
- Introduce image assets or third-party animation dependencies.
- Make the background visually dominant over the resolved morning content.

## Decisions

- Keep a deterministic SwiftUI `Canvas` implementation. This avoids new assets, keeps the future visual system replaceable, and prevents random redraw differences during body refreshes.
- Increase visibility through opacity, band geometry, and blend behavior rather than changing the home contrast overlay. This keeps foreground readability and existing glass surfaces stable.
- Use layered elongated ellipses with blur and a light material-like overlay. The shapes are simple enough for reasonable performance and obvious enough to verify visually.
- Use `TimelineView(.animation(minimumInterval: 1 / 24))` only when motion is allowed. Reduce Motion skips the timeline entirely and renders a fixed frame.

## Risks / Trade-offs

- Visible clouds could compete with low-contrast text or glass edges -> keep the bands soft, broad, and behind `AppHomeContrastOverlay`, and verify on the home screen.
- Stronger opacity could feel less subtle than intended -> tune for inspectability first because the current issue is non-visibility; future art assets can replace this component without changing the stack.
- Canvas animation may use extra GPU work -> cap timeline updates at 24 fps and use a small number of deterministic cloud bands.
