## 1. Assets

- [x] 1.1 Unzip the revised atmospheric cloud parallax asset pack and inspect the README, depth model, manifest, and sample integration guidance.
- [x] 1.2 Copy `SubhDawnMistVeil.imageset`, `SubhDawnCloudWispFar.imageset`, `SubhDawnCloudWispMid.imageset`, `SubhDawnCloudWispLow.imageset`, and `SubhDawnCloudWispNear.imageset` into `Subh/Resources/Assets.xcassets/`.

## 2. Implementation

- [x] 2.1 Replace the procedural/earlier cloud layer with an asset-backed SwiftUI implementation adapted from the revised parallax sample file.
- [x] 2.2 Confirm `SubhHomeView` renders `AppAtmosphericCloudLayer` between `AppPageBackground` and `AppHomeContrastOverlay`.
- [x] 2.3 Preserve decorative behavior with hit testing disabled and accessibility hidden.
- [x] 2.4 Preserve Reduce Motion behavior with deterministic static cloud phase offsets.
- [x] 2.5 Preserve monotonic depth speeds: near fastest, low, mid, far, mist slowest.

## 3. Verification

- [x] 3.1 Build the app with Xcode.
- [x] 3.2 Run the app in the simulator and tune only opacity or vertical offsets if readability requires it.
- [x] 3.3 Verify normal motion changes over time and Reduce Motion remains static.
- [x] 3.4 Verify the nearest layer moves fastest and the farthest haze moves slowest.
- [x] 3.5 Run relevant tests or document any unrelated existing failures.
