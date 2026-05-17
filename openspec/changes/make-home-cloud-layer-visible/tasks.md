## 1. Cloud Layer Tuning

- [x] 1.1 Inspect the current home background stack and confirm the cloud layer sits between `AppPageBackground` and `AppHomeContrastOverlay`.
- [x] 1.2 Tune the cloud band opacity, geometry, blur, and blend behavior so the clouds are visibly present after the tint/contrast overlays.
- [x] 1.3 Preserve decorative behavior with hit testing disabled and accessibility hidden.
- [x] 1.4 Preserve Reduce Motion behavior with static or dramatically reduced movement.

## 2. Verification

- [x] 2.1 Build the app with Xcode.
- [x] 2.2 Verify in simulator screenshots that the clouds are visible but home content remains readable.
- [x] 2.3 Verify screenshot comparison shows normal motion changes and Reduce Motion stays static or dramatically reduced.
- [x] 2.4 Run relevant tests or document any unrelated existing test failures.
