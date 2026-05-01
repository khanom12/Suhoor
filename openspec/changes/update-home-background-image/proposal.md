## Summary

Replace the Subh main-screen background asset with the provided dawn gradient image.

## Problem

The home screen should use the newly supplied portrait background image as its main visual backdrop. The existing background asset name and SwiftUI rendering path already support this through `WakeScreenBackground`, so the change should be limited to the asset content.

## Scope

- Replace `WakeScreenBackground` image content with the provided image.
- Add a subtle dark tint over the home background so text remains readable near the bottom of the screen.
- Preserve the existing asset name, image-set metadata, and `AppPageBackground` rendering behavior.

## Non-Goals

- Do not change home layout, card order, glass styling, text, navigation, or data resolution.
- Do not alter settings/detail backgrounds beyond any screens that already consume `AppPageBackground`.
- Do not introduce alternate background selection or dynamic theming.
