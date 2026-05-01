## Decisions

1. **Replace the existing image asset in place.**
   `AppPageBackground` reads `Image("WakeScreenBackground")`, and the asset catalog already contains a universal `1x` image. Replacing the PNG content preserves the app code path and avoids unnecessary layout churn.

2. **Keep the existing scale and rendering behavior.**
   The provided image is portrait-oriented and the app already uses `.resizable().scaledToFill()`. No additional crop, blur, overlay, or SwiftUI changes are needed.

3. **Use the existing contrast overlay for readability.**
   The existing home contrast overlay is the right boundary for background readability. Add a uniform 25% black tint there so lower-screen text and controls remain legible over the brighter part of the new image.

## Risks

- The new background may affect contrast behind existing glass/text surfaces. The added tint improves the bright lower region while preserving the existing gradient overlay shape.
