## Why

Subh needs a visible product identity that matches the new Fajr-centered morning-system doctrine, but the first rename wave must not accidentally reset local user data. This change renames app/project/test surfaces while preserving the existing app bundle identifier and legacy storage namespaces.

## What Changes

- Rename visible product surfaces from Suhoor to Subh, including app display name, Xcode project/scheme, target/module, app struct, source/test folder names, and primary copy touched in this wave.
- Preserve `PRODUCT_BUNDLE_IDENTIFIER = khanomar.Suhoor` for the app target.
- Preserve existing UserDefaults and store keys, including Suhoor-era namespaces, as intentional legacy compatibility.
- Update tests and project references to build against the renamed `Subh` module.

## Capabilities

### New Capabilities

### Modified Capabilities
- `subh-rename-compatibility`: Implement the first-wave rename while preserving local data identity.

## Impact

- Affects `Subh.xcodeproj`, shared schemes, test plan, app/test folders, `Info.plist`, app entry point, test imports, and visible copy.
- Existing installed data is preserved because the bundle id and storage keys do not change.
- No existing scheduled alarms are intentionally canceled by this rename.
