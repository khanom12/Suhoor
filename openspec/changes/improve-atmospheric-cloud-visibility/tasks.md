## 1. Contrast Layering

- [x] 1.1 Add clearly named home background overlay components for the weak atmosphere base layer and softer foreground readability layer.
- [x] 1.2 Update the Subh home background stack to render the base overlay below clouds and the foreground overlay above clouds.

## 2. Cloud Visibility and Placement

- [x] 2.1 Tune top-hero cloud opacity, blur, and vertical offsets so clouds remain subtle but visible after foreground tinting.
- [x] 2.2 Keep cloud placement relative to a clamped top hero region and clip/fade the cloud system before it reaches the lower home content.
- [x] 2.3 Preserve depth-based parallax ordering and deterministic Reduce Motion static phases.

## 3. Verification

- [x] 3.1 Validate the OpenSpec change.
- [x] 3.2 Build and run the app on simulator, then verify visibility, top-hero confinement, readability, parallax ordering, and Reduce Motion freeze behavior.
- [x] 3.3 Run the relevant XCTest suite.
