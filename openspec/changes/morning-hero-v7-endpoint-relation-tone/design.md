## Context

The v0.6 hero relation formatter computes all active relation text from wake time to Fajr end. The v0.7 spec adds two endpoint exceptions after clamping and rounding: Fajr begin and Fajr end.

## Decisions

1. **Model relation tone in the presentation display.**
   Add an explicit relation-tone field to the hero display instead of letting SwiftUI infer endpoint state from localized text.

2. **Determine endpoints from resolved display times.**
   The formatter checks endpoint equality after the wake time has already gone through existing clamp, rounding, and date-specific persistence paths. Since hero adjustments persist as whole minutes from midnight, endpoint detection allows the app's one-minute granularity so Fajr begin/end copy survives commit and re-resolution when prayer times include seconds.

3. **Use endpoint copy for both initial and drag displays.**
   Initial hero resolution and tentative drag resolution share the same relation formatter so endpoint behavior cannot diverge.

4. **Keep accessibility aligned with visible text.**
   The accessibility value receives the same endpoint-aware relation text, while color remains a visual-only emphasis.

## Risks / Trade-offs

- Red text is a visual exception. The visible string itself remains descriptive so the endpoint state is not conveyed by color alone.
