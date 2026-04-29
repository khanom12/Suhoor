## Context

The v0.4 Morning Hero already renders the location line first, keeps the date hidden, places the Fajr-window visual above the relation line, and supports live wake adjustment. The v0.5 spec changes the language of the final relation line and adjusts spacing around the visual.

## Decisions

1. **Keep active relation copy in presentation.**
   `MorningHomePresentation` remains the place that composes the user-visible relation string from resolved wake data. The UI continues to render the supplied display model.

2. **Separate offset phrases from active instructions.**
   Offset text such as `30 minutes before Fajr ends` remains useful for inactive copy like `Planned wake was ...`. Active relation lines wrap that offset with `Wake up ...`.

3. **Apply full-word minutes consistently.**
   Active relation lines, drag relation lines, planned-wake inactive copy, and the adjuster accessibility value use `minute` / `minutes` instead of compact `min`.

4. **Do not change no-alarm state copy.**
   Off, no-alarm, missing-Fajr, quiet, and unavailable states continue to describe state rather than manufacturing a wake instruction.

5. **Keep spacing as metrics, not local padding.**
   The v0.5 baseline is expressed in `MorningHeroMetrics` so the SwiftUI stack stays readable across dynamic type sizes.

## Risks / Trade-offs

- Full-word relation copy is longer at large text sizes. Existing multiline relation behavior remains in place so the hero grows rather than truncating the final explanation.
- Existing tests that asserted compact `min` copy must be updated to v0.5 wording.
