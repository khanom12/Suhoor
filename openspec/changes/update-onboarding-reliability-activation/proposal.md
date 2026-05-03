## Why

Subh onboarding currently has the right four-step shape, but it still presents wake activation as notification-fallback tolerant and uses setup copy that is broader than the v1 product promise. This change makes first-run activation honest, short, and Fajr-centered: location/city plus resolvable prayer times plus AlarmKit authorization are required before the app says the first wake is ready.

## What Changes

- Keep the existing four-step onboarding flow: value preview, location, permissions, success.
- Revise onboarding copy so the user understands Subh prepares the next wake around Fajr, with the default wake 30 minutes before Fajr ends.
- Hide calculation-method selection during normal onboarding; keep city selection as the location fallback.
- Require AlarmKit authorization for onboarding completion and repair routing.
- Make notifications recommended and explicitly non-blocking for onboarding completion.
- Remove onboarding copy that describes notifications as wake fallback delivery.
- Add a guarded Ready state: `isConfigured` is written only when location, prayer-time preview, and AlarmKit readiness are all true.
- Update onboarding visuals to use the Subh dawn background, contrast overlay, glass surfaces, and a read-only Home-hero-like wake preview.
- Update purpose-string copy that participates in onboarding trust, without changing alarm scheduling semantics or persisted settings.

## Capabilities

### New Capabilities

- `onboarding-activation`: Defines first-run and repair onboarding behavior for location readiness, prayer-time preview readiness, AlarmKit-required wake activation, optional notifications, and the Home handoff.

### Modified Capabilities

- None.

## Impact

- Affected app areas:
  - `Subh/App/OnboardingPreviewModels.swift`
  - `Subh/App/OnboardingViewModel.swift`
  - `Subh/App/OnboardingView.swift`
  - `Subh/Core/Services/BootstrapEvaluator.swift`
  - `Subh/Core/Services/ScheduleService.swift`
  - `Subh/Core/Utilities/Strings.swift`
  - `Info.plist`
  - focused tests under `SubhTests`
- Existing scheduled alarms are not migrated, cancelled, or rescheduled by this change beyond the existing forced schedule refresh on onboarding completion.
- Cached schedules and persisted user settings remain compatible. The only persistent write changed by this proposal is stricter guarding before `AppSettings.isConfigured` can become true.
- No new production dependency is expected.
