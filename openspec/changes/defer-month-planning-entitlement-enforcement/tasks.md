## 1. OpenSpec

- [x] 1.1 Add an OpenSpec clarification for deferring Month Planning entitlement enforcement in development.
- [x] 1.2 Update the Month Planning working spec with the development entitlement enforcement note.
- [x] 1.3 Validate the OpenSpec change in strict mode.

## 2. Implementation

- [x] 2.1 Add a centralized Debug/development effective entitlement override without changing raw production entitlement snapshots.
- [x] 2.2 Update Month Planning entry, picker, detail, placeholder, and Day Detail source context to read effective entitlements.
- [x] 2.3 Preserve a debug opt-out path for verifying locked/preview behavior.

## 3. Verification

- [x] 3.1 Add or update focused tests for the development override and opt-out behavior.
- [x] 3.2 Run focused XCTest for Month Planning entitlement behavior.
- [x] 3.3 Run the repo's normal Xcode validation where practical.
- [x] 3.4 Review the diff for no purchase logic, no broad entitlement deletion, no persistence/scheduling from browsing, and no unrelated files.

## 4. Release Hygiene

- [x] 4.1 Stage only relevant files.
- [x] 4.2 Commit with `Defer Month Planning entitlement enforcement in development`.
- [x] 4.3 Push to `origin main`.
