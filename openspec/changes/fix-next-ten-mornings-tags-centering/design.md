## Decisions

1. **Merge opportunity sources at the presentation resolver boundary.**
   Opportunity-only tags should be derived from both the existing date-derived opportunity input and the row's resolved day context. The resolver remains the single place where `[Fajr]`, suppression, completion-aware Shawwal 6 behavior, and visible tag capping are applied.

2. **Balance outer row lanes for visual centering.**
   The date label and trailing time/status should each occupy the same outer lane width, based on the wider of the shared date lane and shared trailing lane. This keeps the tag lane center aligned with the row center while preserving leading date alignment and trailing time alignment inside their lanes.

3. **Remove extra tag-lane padding.**
   The chips already include internal padding and a controlled inter-chip gap. Extra lane padding reduces the usable center lane on compact devices and can force a valid two-tag row to collapse unnecessarily.

## Risks

- Very narrow widths can still require visible tag reduction. The existing `ViewThatFits` fallback remains in place and accessibility continues to preserve full tag meaning.
- Balancing side lanes can slightly reduce tag lane width when the date lane is narrower than the time lane. Removing the additional tag-lane padding offsets that on compact iPhone widths.
