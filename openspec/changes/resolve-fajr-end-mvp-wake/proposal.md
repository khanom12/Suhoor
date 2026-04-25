## Why

The MVP should wake the user relative to the Fajr window they need to meet, not before the start of Fajr as an inherited alarm default. The first-wave default becomes 30 minutes before the supported Fajr end boundary while preserving custom user settings.

## What Changes

- Change fresh-install default wake settings from Fajr-start minus 30 minutes to supported-Fajr-end minus 30 minutes.
- Migrate persisted settings only when they exactly match the old factory default.
- Preserve all user-customized wake settings.
- Add focused XCTest coverage for default creation, old-default migration, and custom preservation.

## Capabilities

### New Capabilities

### Modified Capabilities
- `fajr-end-mvp-wake`: Implement the Fajr-end default and compatibility migration.

## Impact

- Affects default alarm configuration, alarm config loading/migration, schedule generation through existing resolver paths, and tests.
- Existing customized settings are preserved.
- Existing old-factory-default installs adopt the Subh MVP default and may regenerate future scheduled wake times.
