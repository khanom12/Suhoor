## Context

`AppAtmosphericCloudLayer` renders five transparent 1024 x 512 top-hero cloud canvases as horizontally repeating SwiftUI image bands. The current band implementation uses a fixed three-tile `HStack`, `.scaledToFill()`, hard clipping, and full tile-width modulo movement. Because the cloud assets are not guaranteed to be perfectly edge-seamless, and because `.scaledToFill()` can crop transparent canvas margins, the user can see vertical tile boundaries or sudden cloud entry during drift.

The home stack and overlay model are already correct: `AppPageBackground`, weak atmosphere overlay, `AppAtmosphericCloudLayer`, foreground contrast overlay, and foreground content. This change should only alter cloud-band rendering inside `Subh/UI/Components/AppAtmosphericCloudLayer.swift`.

## Goals / Non-Goals

**Goals:**

- Render each cloud band as a continuous right-to-left atmospheric field without visible tile boundaries.
- Preserve the full transparent 2:1 asset canvas instead of cropping cloud margins.
- Use tile feathering, overlap/crossfade, offscreen overscan, and stride-based modulo movement.
- Keep top-hero confinement, vertical fade-out, parallax duration ordering, and Reduce Motion static phases.

**Non-Goals:**

- No changes to home content, glass overlays, navigation, cards, settings, alarm scheduling, AlarmKit, persistence, notifications, or Fajr/suhoor calculations.
- No new assets or third-party dependencies.
- No faster production animation durations.

## Decisions

- Replace `RepeatingHeroCloudLayer` with a seam-safe renderer that computes `tileWidth`, `featherWidth`, `tileStride`, overscan, and dynamic copy count from the active container size. Dynamic copy count avoids assumptions that fail on wide screens or rotated layouts.
- Preserve asset canvas by rendering with `.aspectRatio(2, contentMode: .fit)` in a stable tile frame instead of `.scaledToFill().clipped()`. The images are 2:1 RGBA canvases, so this keeps their designed transparent side margins intact.
- Apply a horizontal mask to every tile using transparent edges and an opaque middle. Adjacent tiles overlap by the feather width so the fading-out edge of one tile crossfades with the fading-in edge of the next.
- Move by `tileStride`, not `tileWidth`, and reset modulo by the stride. Since the repeated visual state is equivalent at stride intervals, modulo reset stays invisible.
- Add subtle whole-track horizontal edge feathering to ease cloud entry from the right and exit to the left without weakening the center of the hero.

## Risks / Trade-offs

- More repeated tile copies can increase rendering work -> compute the minimum dynamic count needed for viewport plus overscan and keep the existing five-layer count and 30 fps timeline.
- Feathering may reduce cloud visibility near screen edges -> keep edge masks subtle and preserve existing layer opacities.
- Device-specific visual checks cannot wait for a full 78-second near-layer loop in automated tests -> verify with screenshots, static Reduce Motion diffing, and code inspection of stride/modulo behavior; optionally use local-only faster durations during manual inspection without committing them.
