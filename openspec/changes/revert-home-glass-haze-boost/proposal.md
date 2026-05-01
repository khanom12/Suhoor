## Summary

Revert the home liquid-glass haze boost introduced by `refine-home-liquid-glass-settings-control` while preserving the settings button's top-right placement and shared home-glass hook.

## Problem

The prior home glass refinement increased the native glass kind, fallback material, tint, stroke, and overlay values to approximate stronger diffusion. In practice this produced an egg-gray haze over the home cards and controls rather than the intended stronger background diffusion.

The desired direction is glass thickness or true behind-glass diffusion, not a blanket frost or opacity increase.

## Scope

- Restore the home grouped glass rendering values to the prior grouped baseline.
- Keep the home-specific glass variant as a stable hook for future home surfaces.
- Keep the top-right settings button placement and its shared glass styling.
- Document that the currently installed SwiftUI SDK does not expose a public `Glass` thickness control.

## Non-Goals

- Do not move the settings button back to the bottom right.
- Do not change home card order, content, copy, data resolution, navigation, or interactions.
- Do not introduce private SwiftUI APIs or speculative visual hacks.
