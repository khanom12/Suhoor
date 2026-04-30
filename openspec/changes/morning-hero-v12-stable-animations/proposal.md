# Morning Hero v1.2 Stable Animations

## Summary

Refine the Morning Hero quick wake-state interactions to match the v1.2 item spec: preserve stable layout when entering or leaving Quiet, keep the range row anchored during Fast/Fajr transitions, roll active wake times between Fast and Fajr, and restyle the quick selector so it shares the translucent glass language used by the forecast cards.

## Motivation

The v1.1 implementation made the quick selector functional, but its surrounding animation still felt too directional and the Quiet state could visually shrink the hero. The selector also read as a frosted segmented control instead of the clearer glass treatment used by the rest of the home forecast surfaces.

## Scope

- Morning Hero SwiftUI presentation only.
- Focused tests for presentation and UI behavior.
- No changes to prayer-time calculation, wake resolution, scheduling policy, persistence precedence, or downstream forecast plumbing.

## Out of Scope

- New wake-state modes beyond Fast, Fajr, and Quiet.
- New fallback visuals for out-of-range wake times.
- Date-row reactivation.
