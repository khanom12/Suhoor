## 1. OpenSpec and Documentation

- [x] 1.1 Add the supplied Next 7 Mornings v2 and Month Planning v2 specs to `docs/specs/` while preserving prior specs.
- [x] 1.2 Update the spec index/source map so the v2 planning specs are canonical.
- [x] 1.3 Create and validate the OpenSpec change for the v2 planning update.

## 2. Home and Next 7 Mornings

- [x] 2.1 Move the forecast card into Home `Plan ahead` above Calendar/Hijri tiles and make the section heading high contrast.
- [x] 2.2 Update visible and accessibility copy from Next 7 Days to Next 7 Mornings with the required helper line.
- [x] 2.3 Update compact tag resolution so only opportunity/context tags render in the middle lane and routine state tags are hidden.
- [x] 2.4 Render Quiet as trailing `Quiet` and keep row geometry stable.

## 3. Month Planning V2

- [x] 3.1 Update Home month tiles for stable paired tile behavior under the Plan ahead section.
- [x] 3.2 Update Month Picker to use grid/tile cards with complementary Gregorian/Hijri range context.
- [x] 3.3 Update Month Detail rows to mirror the Next 7 Mornings three-lane row doctrine.
- [x] 3.4 Preserve existing entitlement, Hijri, resolver, persistence, Day Detail, and scheduling seams.

## 4. Tests and Validation

- [x] 4.1 Update or add focused tests for v2 naming, tag doctrine, Quiet trailing status, month picker card context, and month row display.
- [x] 4.2 Run OpenSpec validation.
- [x] 4.3 Run focused XCTest and the normal Xcode build/test validation where practical.
- [x] 4.4 Review the diff for no duplicate engines, no browsing persistence, no scheduling side effects, no broad rename, and no unrelated staging.

## 5. Release Hygiene

- [x] 5.1 Show `git status`.
- [x] 5.2 Stage only relevant files.
- [x] 5.3 Commit with `Implement Next 7 Mornings and Month Planning v2`.
- [x] 5.4 Push to `origin main`.
