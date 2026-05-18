## 1. Renderer

- [x] 1.1 Replace the hard repeated `HStack` cloud band with a seam-safe renderer.
- [x] 1.2 Preserve the 2:1 transparent asset canvas without `.scaledToFill()` cropping.
- [x] 1.3 Add per-tile horizontal edge feathering.
- [x] 1.4 Overlap tiles by the feather width and use stride-based modulo movement.
- [x] 1.5 Add dynamic offscreen overscan/copy count coverage for different widths.
- [x] 1.6 Preserve parallax durations, top-hero vertical mask, decorative behavior, and Reduce Motion static phases.

## 2. Verification

- [x] 2.1 Validate the OpenSpec change.
- [x] 2.2 Build the app.
- [x] 2.3 Run the home screen and verify right-to-left soft entry, no visible hard tile boundary, top-hero confinement, and foreground readability.
- [x] 2.4 Verify Reduce Motion freezes the cloud layer without exposing a seam.
- [x] 2.5 Run the relevant XCTest suite.
