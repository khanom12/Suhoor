## Context

The single-screen home already resolves a `MorningHomeSnapshot` outside SwiftUI and renders its Tomorrow Morning hero above Weekly Fajrcast and Morningcast. The current hero presents a relative label, Gregorian date, wake time, and a compact wake relation, but it does not expose Hijri date or the exact Fajr begin/end window in the hero.

This change affects:

- `Subh/Features/Home/MorningHomeSnapshot.swift`
- `Subh/Features/Home/MorningHomePresentation.swift`
- `Subh/Features/Home/SubhHomeView.swift`
- Focused tests in `SubhTests/`

No services, stores, alarm scheduling, prayer-time calculation, or persistence namespaces need to change. The hero must consume resolved snapshot values and presentation strings.

## Goals / Non-Goals

**Goals:**

- Add a `MorningHeroSnapshot`-style contract inside the home snapshot/presentation layer.
- Keep Fajr-window and Hijri display strings preformatted before SwiftUI rendering.
- Render the hero as a centered five-row summary with dynamic type-aware sizing and a visible Fajr begin/end line.
- Preserve the single home surface and existing supporting cards.
- Add focused tests for presentation strings and fallback state behavior.

**Non-Goals:**

- Do not change prayer-time calculation, Fajr-end source, wake scheduling, alarm delivery, or stored settings.
- Do not introduce chips, badges, a second home screen, or new onboarding behavior.
- Do not add broad special-observance logic beyond passing through precomposed relation/context text already available to the snapshot.

## Decisions

1. **Use a nested home hero presentation model.**
   Add a dedicated hero value to `MorningHomeSnapshot` rather than letting `SubhHomeView` compose dates, state labels, or Fajr-window strings. This matches the existing presentation-model pattern and keeps SwiftUI from becoming a business-rule surface.

2. **Use current resolved schedule values for Fajr begin/end.**
   The hero window line will use the same resolved Fajr start and supported end values that already feed home and Weekly Fajrcast presentation. The renderer will only display the supplied `fajrWindowLineText`.

3. **Represent wake state explicitly for rendering and accessibility.**
   The snapshot will distinguish active, off-with-anchor, no-alarm, quiet, and unavailable states enough for icon selection, primary text, relation/status copy, and accessibility summary. Where the current app cannot infer a richer state safely, it will use the honest fallback state rather than guessing.

4. **Implement seven-stop guardrails as layout tokens.**
   The view will map dynamic type size to the seven standard stops, scale typography from the spec baseline, and reserve hero height as the max of the stop guardrail and measured/estimated text need. SwiftUI can then push Weekly Fajrcast down instead of clipping the Fajr line.

## Risks / Trade-offs

- **Risk: Current data may not cover every future wake state.** → Mitigation: implement explicit fallbacks and keep unsupported states visible as unavailable/no-alarm instead of inventing a relation.
- **Risk: Very large localized date/window strings may wrap more than the first pass estimates.** → Mitigation: allow multiline date, relation, and Fajr-window text and keep the hero region growing with dynamic type.
- **Risk: UI-only tests cannot fully prove measured layout on every iPhone size.** → Mitigation: cover presentation contract with XCTest and leave no fixed clipping/truncation in the SwiftUI hierarchy.
