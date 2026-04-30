## Context

The first Next 10 Mornings pass replaced visible Morningcast subtitles with compact tags and a single `NEXT 10 MORNINGS` header. The v2 specification keeps that product direction but clarifies two gaps: opportunity-only rows must keep `[Fajr]` as the visible anchor, and all rows must share a stable date/tag/time grid so tag clusters do not drift based on date-label width.

Affected code is limited to `Subh/Features/Home/MorningHomePresentation.swift`, `Subh/Features/Home/SubhHomeView.swift`, and focused tests in `SubhTests/ScheduleServiceExtractionTests.swift`.

## Goals / Non-Goals

**Goals:**

- Align opportunity-only tag output with the v2 doctrine: `[Fajr]` plus compatible visible opportunity tags.
- Render each forecast row using a shared date lane, centered tag lane, and trailing time/status lane for a given snapshot.
- Preserve the existing glass card shell, divider treatment, row tap behavior, no-subtitle contract, and accessibility labels.
- Keep tag compatibility and Shawwal 6 suppression inside the presentation resolver, fed by existing fasting-domain output.

**Non-Goals:**

- Do not change prayer-time calculation, alarm scheduling, cache regeneration, or persistence.
- Do not implement the future quiet-mode pipeline beyond the existing resolver visual contract.
- Do not add inline editing, tag taps, horizontal scrolling, or visible explanatory prose.
- Do not introduce a new design-system dependency for layout measurement.

## Decisions

1. **Add `[Fajr]` inside `NextTenMorningsTagResolver` for opportunity-only rows.**
   The renderer still receives prepared tags and does not infer product meaning. This keeps the Fajr anchor rule testable and prevents SwiftUI layout code from recreating observance logic.

2. **Use a small snapshot-level row metrics model.**
   `NextTenMorningsSnapshot` will carry shared row metrics derived from the ten prepared rows: date lane, tag lane, and trailing lane weights/width assumptions. `NextTenMorningsCard` passes those metrics to every row so the tag cluster is centered in the same lane across rows.

3. **Use SwiftUI `Grid` lanes instead of row-local natural spacing.**
   A three-column `Grid` makes the shared alignment explicit: leading date, centered tags, trailing time/status. `ViewThatFits` remains inside the tag lane to reduce visible tag count without changing the lane center.

4. **Keep visual tests at the presentation/layout contract level.**
   The project does not currently have forecast snapshot tests. Focused tests will cover the computed row metrics and tag doctrine changes; the full Xcode UI smoke test will continue guarding home layout viability.

## Risks / Trade-offs

- [Risk] A fixed-looking lane model can become cramped at extreme Dynamic Type or narrow widths. -> Mitigation: keep `ViewThatFits` inside the shared tag lane, preserve wake time priority, and allow row height to grow while never wrapping tags.
- [Risk] Adding `[Fajr]` to opportunity-only rows changes existing tests and visual density. -> Mitigation: cap visible tags at three and preserve full tag detail in accessibility.
- [Risk] SwiftUI measurement can be fragile if over-engineered. -> Mitigation: use deterministic snapshot metrics plus `Grid`, not a custom asynchronous measurement pass.
