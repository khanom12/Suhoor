## Context

The v0.7 implementation introduced endpoint-aware relation copy and tied the red text treatment to endpoint states. The v0.8 spec narrows red to one semantic meaning: an urgent short wake-to-Fajr-end window.

## Decisions

1. **Rename the relation tone to match semantics.**
   Use `urgentRed` instead of endpoint-specific naming so the presentation model expresses why the line is red.

2. **Compute urgency from the displayed rounded minute relation.**
   The urgency threshold uses the same rounded whole-minute difference to Fajr end that powers the visible default relation copy. This keeps `Wake up 10 min before Fajr ends` red, `Wake up 11 min before Fajr ends` normal, and `Wake up as Fajr ends` red.

3. **Keep endpoint copy independent from color.**
   Fajr begin uses endpoint copy but normal tone in ordinary windows. Fajr end uses endpoint copy and urgent tone because it leaves zero minutes before Fajr ends.

4. **Use semantic danger color.**
   Render urgent relation text with the existing design danger token rather than a hardcoded platform red.

## Risks / Trade-offs

- The tone model changes name, but the display contract remains small and internal to the home presentation layer.
