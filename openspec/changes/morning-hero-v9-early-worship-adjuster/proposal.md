# Morning Hero v0.9 Early-Worship Adjuster

## Summary
Implement the v0.9 Morning Hero behavior for wake times before Fajr begins on intended fasting and Tahajjud mornings.

## Motivation
The v0.9 spec makes the wake-boundary visual mode-aware. Ordinary mornings continue to use the Fajr-begin to Fajr-end adjuster, while intended fasting and Tahajjud mornings use an early-worship window from final-third start to Fajr begins. The current implementation hides fasting rows and only persists adjustments inside the default Fajr window.

## Scope
- Add early-worship visual mode to the Morning Hero presentation contract.
- Resolve final-third start from existing prayer-window data in the presentation/data layer.
- Render the early-worship left boundary as a vertical tick and the right boundary as the Fajr-begin endpoint circle.
- Use early-worship relation copy while dragging and after resolution.
- Commit early-worship hero adjustments as date-specific wake overrides without mutating defaults.
- Update tests for relation copy, visual eligibility, boundary clamping, and UI rendering.

## Non-Goals
- Do not add chips or special-context badges to the hero.
- Do not change the hidden date-row behavior.
- Do not add a separate wake engine or global default mutation.
- Do not invent final-third values in SwiftUI rendering.
