## 1. Rename Build Surfaces

- [x] 1.1 Rename `Suhoor.xcodeproj`, shared scheme, source folder, test folder, and test plan to Subh names.
- [x] 1.2 Update Xcode project references, product names, target/module names, test host, and test target references.
- [x] 1.3 Rename `SuhoorApp` to `SubhApp` and update `@testable import` statements to `Subh`.

## 2. Preserve Compatibility

- [x] 2.1 Keep `PRODUCT_BUNDLE_IDENTIFIER = khanomar.Suhoor` for the app target.
- [x] 2.2 Inspect remaining Suhoor references and preserve storage/key namespaces intentionally.
- [x] 2.3 Update visible copy touched by this wave to Subh.

## 3. Verification

- [x] 3.1 Run `xcodebuild -list -project Subh.xcodeproj`.
- [x] 3.2 Run at least one focused renamed-module XCTest target.
