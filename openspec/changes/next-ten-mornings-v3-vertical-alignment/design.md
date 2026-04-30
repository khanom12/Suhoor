## Decisions

1. **Use measured date/time lanes plus fixed minimum gaps.**
   `NextTenMorningsRowMetrics` will expose a shared date lane, trailing lane, and minimum gaps. Resolved lanes will compute the tag lane as the remaining middle space. This matches the v3 geometry while keeping the deterministic snapshot-level metrics already in place.

2. **Center-align the outer row.**
   The SwiftUI row will use `.center` alignment for the date, tag lane, and trailing lockup. Internal time text may keep its baseline relationship between the main time and meridiem suffix.

3. **Use forecast-local compact chip metrics.**
   The Next 10 Mornings tag chip will use smaller local horizontal/vertical padding and tighter inter-tag spacing instead of broader shared chip tokens.

## Differences From v3 Spec

- The implementation still uses deterministic text-width estimates for snapshot row metrics rather than a live SwiftUI measurement pass. This preserves the current simple, testable presentation boundary. The v3 spec allows measured helpers/custom layouts, but does not require a specific mechanism as long as the alignment result is stable.
