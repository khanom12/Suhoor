## 1. Transition State and Layout Stability

- [x] 1.1 Add local hero transition state for previous/current quick mode, transition direction, and reduced-motion handling.
- [x] 1.2 Give the primary wake row a stable transition frame so active wake text and `Quiet mode on` occupy the same slot.
- [x] 1.3 Keep the eligible range row visually stable when switching among active and Quiet modes.

## 2. Selector and Range Animations

- [x] 2.1 Refine the quick selector to use a single moving liquid-glass selected highlight with equal segment hit areas.
- [x] 2.2 Add mode-aware transitions for primary row text, relation/status text, boundary labels, and range visual changes.
- [x] 2.3 Add directional marker transitions for `Fajr -> Fast` and `Fast -> Fajr`, with reduced-motion crossfade fallback.

## 3. Accessibility and Tests

- [x] 3.1 Include the selected quick mode in the hero accessibility summary when the selector is visible.
- [x] 3.2 Add or update presentation tests for selected-mode accessibility and Quiet layout/state semantics.
- [x] 3.3 Add or update UI tests for selector transitions, Quiet no-marker state, and mode switching stability.

## 4. Validation

- [x] 4.1 Run OpenSpec validation for `morning-hero-v11-mode-transitions`.
- [x] 4.2 Run focused presentation tests.
- [x] 4.3 Run focused Morning Hero UI tests.
- [x] 4.4 Run `git diff --check`.
