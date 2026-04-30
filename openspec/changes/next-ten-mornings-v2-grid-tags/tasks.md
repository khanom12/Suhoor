## 1. OpenSpec

- [x] 1.1 Create proposal, design, and delta spec for the v2 Next 10 Mornings grid/tag refinement.
- [x] 1.2 Validate the OpenSpec change in strict mode before implementation.

## 2. Presentation Rules

- [x] 2.1 Update opportunity-only tag resolution to return `[Fajr]` plus compatible opportunity tags.
- [x] 2.2 Preserve existing replacement rules for quiet mode, Ramadan, intended fasting, Tahajjud, Monday/Thursday suppression, Shawwal 6 suppression, and visible tag capping.
- [x] 2.3 Add snapshot-level row metrics for shared date, tag, and trailing lanes.

## 3. SwiftUI Layout

- [x] 3.1 Render forecast rows with one shared date/tag/time grid across the snapshot.
- [x] 3.2 Keep tag capping inside the centered tag lane without wrapping tags or shifting the trailing wake time.
- [x] 3.3 Preserve the existing glass shell, subtle dividers, full-row tap target, and accessibility label behavior.

## 4. Validation

- [x] 4.1 Update focused tests for v2 opportunity-only `[Fajr]` anchoring and tag cap accessibility.
- [x] 4.2 Add focused tests for stable shared row metrics across mixed date/tag/time rows.
- [x] 4.3 Run OpenSpec strict validation, whitespace checks, focused Xcode tests, and a broader Xcode validation where practical.
- [x] 4.4 Commit and push the completed change to `main`.
