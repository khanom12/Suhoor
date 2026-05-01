## 1. OpenSpec

- [x] 1.1 Document v15 shared surface, Gregorian pill, live preview, and boundary label requirements.
- [x] 1.2 Validate the OpenSpec change in strict mode.

## 2. Implementation

- [x] 2.1 Align Weekly Fajrcast shell/header/dividers/content grid with Next 10 Mornings grouped styling.
- [x] 2.2 Update the header pill to show weekday-plus-date during inspection and keep fixed-width Gregorian-only sizing.
- [x] 2.3 Add live wake preview plumbing from Morning Hero adjustment state into the Weekly Fajrcast compact snapshot.
- [x] 2.4 Apply provisional wake values to the matching visible chart point, selected callout, and compact y-axis scale without persisting them.
- [x] 2.5 Refine `Fajr begins` placement to account for pre-Fajr patterns and left-side marker collisions while preserving v13 rotated-box clearance.

## 3. Validation

- [x] 3.1 Add/update focused tests for live preview and pill/geometry behavior where practical.
- [x] 3.2 Run OpenSpec strict validation.
- [x] 3.3 Run focused Weekly Fajrcast/Home tests.
- [x] 3.4 Run diff whitespace validation.
- [x] 3.5 Commit and push the v15 change to `main`.
