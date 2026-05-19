## Context

`AppAtmosphericCloudLayer` owns the decorative home-screen cloud timing. The current seam-safe renderer, layer order, clipping, feathering, opacity, and Reduce Motion behavior are correct and should remain unchanged. The requested adjustment is only to make the existing right-to-left cloud drift 2.5x faster.

## Goals / Non-Goals

**Goals:**

- Shorten each atmospheric cloud layer loop duration by the same 2.5x factor.
- Preserve relative depth ordering: mist remains slowest and near remains fastest.
- Keep the seam-safe renderer, top-hero confinement, decorative accessibility flags, and Reduce Motion frozen phases unchanged.

**Non-Goals:**

- No changes to `SubhHomeView`, overlays, assets, cards, navigation, alarm scheduling, Fajr/suhoor calculations, settings, persistence, notifications, or AlarmKit.
- No new dependencies or runtime configuration.

## Decisions

- Update only `HeroCloudLayer.duration` values in `Subh/UI/Components/AppAtmosphericCloudLayer.swift`. This is the narrowest code path for changing perceived speed because the renderer already derives horizontal progress from each layer duration.
- Use proportional duration reduction rather than changing tile stride, frame cadence, phase, opacity, or position. This keeps visual composition and seam behavior stable while increasing speed evenly.
- Keep `TimelineView` cadence unchanged. The request is motion speed, not animation frame-rate or power behavior.

## Risks / Trade-offs

- Faster clouds could feel less calm than the prior atmospheric treatment -> keep the same parallax ordering and only apply the requested uniform 2.5x speed multiplier.
- Shorter loop durations could make reset points easier to notice -> the existing stride-based modulo, feathered tiles, and overscan renderer remain unchanged to preserve seamless loops.
