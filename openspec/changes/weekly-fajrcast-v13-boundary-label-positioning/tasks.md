## 1. OpenSpec

- [x] 1.1 Document v13 Fajr boundary label positioning and clearance requirements.
- [x] 1.2 Validate the OpenSpec change in strict mode.

## 2. Implementation

- [x] 2.1 Update compact Fajr boundary label placement to use rotated-box boundary clearance.
- [x] 2.2 Preserve leading/top/bottom plot-edge clearance for rotated labels.
- [x] 2.3 Add state-aware `Fajr begins` placement below the begin line for pre-Fajr wake patterns while keeping scrub focus independent.
- [x] 2.4 Preserve existing Weekly Fajrcast window, scrub/snap-back, callout, footer, and scheduling behavior.

## 3. Validation

- [x] 3.1 Run OpenSpec strict validation.
- [x] 3.2 Run focused Weekly Fajrcast/Home tests where practical.
- [x] 3.3 Run diff whitespace validation.
- [x] 3.4 Commit and push the v13 change to `main`.
