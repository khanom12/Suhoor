## 1. Readiness And Routing

- [x] 1.1 Add explicit onboarding readiness, blocked reason, and ready-state presentation models.
- [x] 1.2 Update `OnboardingViewModel` navigation and skip rules so AlarmKit authorization is required and notifications are non-blocking.
- [x] 1.3 Guard onboarding completion so `AppSettings.isConfigured` is written only after location, prayer-time, and AlarmKit readiness pass.
- [x] 1.4 Update bootstrap/permission blocking so configured users repair missing location or AlarmKit while notification denial alone still allows Home.

## 2. Copy And Trust

- [x] 2.1 Replace onboarding value, location, reliability, ready, permission-row, blocked-state, and preview copy with the v1 copy library.
- [x] 2.2 Remove onboarding notification fallback language and update onboarding-related purpose strings.
- [x] 2.3 Hide calculation-method summary during normal onboarding.

## 3. Visual And Accessibility Implementation

- [x] 3.1 Apply Subh dawn background, contrast overlay, glass surfaces, and app controls to onboarding.
- [x] 3.2 Add a read-only Home-hero-like preview for value and ready screens using shared hero visual pieces where practical.
- [x] 3.3 Add ready blocked state, loading state, reliability badges, and accessible labels for preview and permission rows.
- [x] 3.4 Preserve Dynamic Type, Reduce Motion, full-size controls, and reachable CTAs on small screens.

## 4. Tests

- [x] 4.1 Add focused tests for onboarding readiness: AlarmKit required, notifications non-blocking, missing location/prayer time blocking, and blocked reason precedence.
- [x] 4.2 Add focused tests for bootstrap permission repair: AlarmKit denied/unavailable blocks Home and notification denial does not.
- [x] 4.3 Update any affected existing tests for intentional copy or readiness changes.

## 5. Validation

- [x] 5.1 Run OpenSpec validation for `update-onboarding-reliability-activation`.
- [x] 5.2 Run focused unit tests for onboarding readiness/bootstrap behavior.
- [x] 5.3 Run app build or the narrowest available Xcode validation.
- [x] 5.4 Run `git diff --check`.
