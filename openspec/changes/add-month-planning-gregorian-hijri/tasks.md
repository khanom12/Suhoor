## 1. OpenSpec

- [x] 1.1 Add the provided Month Planning spec to the working docs/spec location.
- [x] 1.2 Create and validate the OpenSpec change in strict mode.

## 2. Domain and Entitlement

- [x] 2.1 Add a shared entitlement gate for Month Planning with Free locked and Plus/Complete access.
- [x] 2.2 Add Month Planning mode, month identity, picker item, detail snapshot, row, and Monthly Fajrcast placeholder models.
- [x] 2.3 Generate Gregorian current month plus next 12 month buckets without arbitrary past browsing.
- [x] 2.4 Generate Hijri current month plus next 12 month buckets through the existing adjusted Hijri calendar.
- [x] 2.5 Filter current month detail rows through the existing actionability boundary and keep future months complete.

## 3. UI and Navigation

- [x] 3.1 Add Home `Plan ahead` tiles using the existing Subh glass/card language.
- [x] 3.2 Add Gregorian and Hijri Month Picker screens with locked, loading, unavailable, and accessible row states.
- [x] 3.3 Add Month Detail screens with navigation title, Monthly Fajrcast placeholder, `mornings` section label, empty state, and rows.
- [x] 3.4 Route month rows into the existing Day Detail screen while preserving Month Detail back navigation and passing source context.
- [x] 3.5 Keep Free locked/preview behavior and Plus/Complete access aligned to the shared entitlement model.

## 4. Verification

- [x] 4.1 Add focused tests for Month Planning horizon, filtering, labels, and entitlement.
- [x] 4.2 Run OpenSpec validation.
- [x] 4.3 Run focused XCTest and the repo's normal Xcode validation where practical.
- [x] 4.4 Review the diff for no parallel Fajr/Hijri engine, no persistence from browsing, no scheduling from browsing, approved copy, and unrelated-file cleanliness.

## 5. Release Hygiene

- [x] 5.1 Stage only relevant files.
- [x] 5.2 Commit with `Add Gregorian and Hijri month planning`.
- [x] 5.3 Push to `origin main`.
