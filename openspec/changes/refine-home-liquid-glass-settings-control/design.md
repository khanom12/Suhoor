## Decisions

1. **Create a home-specific glass variant.**
   The existing grouped glass variant is reused outside the main home surface. A dedicated home grouped variant prevents accidental drift in settings and detail surfaces while giving the home screen a stable default for current and future cards/buttons.

2. **Use regular native glass for home diffusion.**
   SwiftUI's native glass API exposes glass kind rather than a direct numeric blur radius. The home variant will use regular native glass, with overlay/tint/stroke strengths increased by roughly 12.5% from the existing grouped baseline. Fallback material also moves from thin to regular material for older OS paths.

3. **Keep the settings control as a home control.**
   The settings button should move to a top-right overlay so it no longer consumes bottom screen space. It should keep the same tap target, icon, accessibility label, and settings sheet behavior.

## Risks

- Native glass diffusion is not exposed as a direct percentage control, so the 10-15% increase is represented through the available glass kind plus a measured 12.5% increase to supporting overlay/tint/stroke values.
- Moving the control to the top right can visually compete with the hero top area; the overlay should stay small, safe-area-aware, and use the existing top spacing rhythm.
