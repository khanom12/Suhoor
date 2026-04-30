# Design

## Layout Stability

The hero keeps fixed ordinary-mode row slots for the primary row, range row, relation row, and selector row. Quiet uses the same primary row typography scale as active wake states so switching to Quiet does not collapse the settled layout.

## Animation Responsibilities

- Selector: one stationary pill with a gliding selected capsule.
- Primary row: active Fast/Fajr changes roll the time numerically; Quiet changes crossfade.
- Relation row: fade-through only; no directional slide.
- Range row: the row and labels stay anchored; boundary labels and marker styles crossfade in place; the marker is the only element that travels.

## Marker Handoff

For `Fajr -> Fast`, the outgoing marker travels left to Fajr begins and fades; the incoming marker appears near the early-worship right boundary and travels left to the resolved Fast wake. `Fast -> Fajr` mirrors this: outgoing travels right to Fajr begins, then incoming appears near the within-Fajr left boundary and travels right to the resolved Fajr wake.

## Reduced Motion

Reduced Motion replaces marker travel and rolling time with short in-place fades while preserving final state, selected feedback, and row stability.
