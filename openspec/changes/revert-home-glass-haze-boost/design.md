## Decisions

1. **Revert the haze-producing boost.**
   `homeGrouped` should resolve to the same baseline style as `grouped` for now: clear native glass, thin fallback material, and the original overlay/tint/stroke values.

2. **Keep the home variant hook.**
   The dedicated `homeGrouped` variant still prevents future home tuning from drifting into settings and detail surfaces. It just should not currently alter visual diffusion through blanket opacity or material changes.

3. **Do not fake thickness with color overlays.**
   Inspection of the installed SwiftUI/SwiftUICore interface shows public `Glass` support for `.regular`, `.clear`, `.identity`, `.tint(_)`, and `.interactive(_)`, but no public thickness/diffusion/refraction control. Until a real public property is available, the app should avoid substituting stronger tint/frost for the intended effect.

## Risks

- This returns home glass diffusion to the prior baseline, so it does not yet achieve the desired Weather-like thicker glass. It removes the incorrect haze and leaves a cleaner extension point for a future implementation.
