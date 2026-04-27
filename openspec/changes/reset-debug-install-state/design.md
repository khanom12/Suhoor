# Design

## Approach
Introduce a small debug-only reset utility that runs at the very start of `SubhApp.init()`, before `SuhoorSettingsStore` and `AlarmConfigStore` read persisted state.

## Debug Install Fingerprint
The reset utility records a fingerprint derived from the installed app executable metadata. On a debug install where the app binary changes, the fingerprint changes. If the stored fingerprint differs from the current fingerprint, the utility clears the app's standard `UserDefaults` persistent domain and then stores the new fingerprint.

This avoids resetting on every launch of the same installed build while still making a new Xcode-installed build behave like a clean test install.

## Release Safety
The reset is compiled and called only under `#if DEBUG`. Release/TestFlight/App Store builds continue using existing compatibility and migration behavior.

## Scope Of Reset
The utility clears local app `UserDefaults` state, which includes alarm config, settings, schedule cache, scheduled date sources, suppression state, Hijri corrections, and similar persisted development state. It also cancels pending local notifications in debug after a reset, so old notification fallback requests do not linger across developer installs.

## Testing
The reset decision logic is factored so tests can verify:
- no reset happens when the fingerprint is unchanged,
- reset happens when no fingerprint exists,
- reset happens when the fingerprint changes,
- and the new fingerprint is persisted after reset.
