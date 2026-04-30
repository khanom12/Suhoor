## 1. Animation Semantics

- [x] 1.1 Remove directional relation and full-range row transitions for ordinary quick-mode changes.
- [x] 1.2 Add active-time rolling for `Fajr <-> Fast` while preserving crossfade behavior for Quiet.
- [x] 1.3 Replace range-row movement with anchored label/marker transitions and marker-only travel.

## 2. Layout and Styling

- [x] 2.1 Stabilize the primary row slot so Quiet uses the same settled row height and optical typography treatment as active wake times.
- [x] 2.2 Restyle the quick selector to match the translucent grouped-card glass language instead of a frosted gray slab.
- [x] 2.3 Preserve reduced-motion behavior with short fades and no physical travel.

## 3. Tests

- [x] 3.1 Update presentation/unit coverage for v1.2 Quiet copy and selected-mode semantics if needed.
- [x] 3.2 Update UI coverage to protect stable Quiet layout and selector mode switching.

## 4. Validation

- [x] 4.1 Run OpenSpec validation for `morning-hero-v12-stable-animations`.
- [x] 4.2 Run focused presentation tests.
- [x] 4.3 Run focused Morning Hero UI tests.
- [x] 4.4 Run `git diff --check`.
