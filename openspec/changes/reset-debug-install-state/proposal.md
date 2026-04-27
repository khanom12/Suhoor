# Reset Debug Install State

## Summary
Add a DEBUG-only developer install reset so Xcode installs on test devices start from fresh Subh defaults instead of preserving old `UserDefaults` state from previous developer builds.

## Motivation
When a debug build is installed over an existing app on a physical iPhone, iOS can preserve the app container. That means old alarm settings can survive into a new developer install and make the app appear to “start over” with pre-Subh Fajr-start behavior. A true fresh install should use the current Subh default: wake 30 minutes before supported Fajr end.

## Scope
- Detect a new debug app binary/install using a local install fingerprint.
- Before settings and alarm stores initialize, clear local persisted app state for DEBUG builds when that fingerprint changes.
- Preserve release behavior and compatibility migrations for real users.
- Add focused tests for the reset decision helper.

## Out Of Scope
- Changing production migration behavior for existing users.
- Removing compatibility-bound `Suhoor.*` key names.
- Changing wake calculation or scheduling rules.
- Adding a user-facing reset UI.

## User Impact
Developer/test installs on physical devices begin from clean onboarding and current Subh defaults, avoiding misleading stale alarm settings during testing.
