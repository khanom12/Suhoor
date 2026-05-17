## Context

Home currently still exposes a `morningcast` support list whose presentation title is `NEXT 10 MORNINGS`, while `MorningHomeSnapshot.maximumMorningcastCount` caps the list at ten. The compact Weekly Fajrcast is built by resolving seven days centered around its anchor date, which can include previous mornings. The attached specs make both surfaces describe one shared upcoming seven-day window: the next immediate alarm or next relevant morning plus six following mornings.

Affected modules:

- `Subh/Features/Home/MorningHomeSnapshot.swift` owns the Home support forecast count and user-facing title.
- `Subh/Features/Home/MorningHomePresentation.swift` owns forecast row/tag presentation.
- `Subh/Features/Home/SubhHomeView.swift` owns the collapsed card header, rows, accessibility labels, and row routing.
- `Subh/Core/Services/ScheduleService.swift` owns Home snapshot generation and compact Weekly Fajrcast active-day selection.
- `SubhTests/ScheduleServiceExtractionTests.swift` and `SubhTests/AlarmConfigMigrationTests.swift` protect the presentation contract and snapshot behavior.

## Goals / Non-Goals

**Goals:**

- Make the visible Home forecast read `NEXT 7 DAYS` and expand to seven rows.
- Include the same first visible day in the Home forecast and compact Weekly Fajrcast.
- Build Weekly Fajrcast as the forecast start day plus six following mornings, not a centered previous/current/future window.
- Preserve the existing resolver, wake-state, tag, detail-routing, and collapsed-by-default behavior.
- Add deterministic tests for count/title and date-key alignment.

**Non-Goals:**

- Rename every internal `Morningcast` or `NextTenMornings` type in this patch.
- Change prayer-time calculation, alarm delivery horizons, scheduling reconciliation, persistence keys, or stored user settings.
- Redesign card styling, Fajrcast geometry, tag priority, or detail screens beyond the horizon/naming alignment.

## Decisions

1. Keep the existing presentation-model shape and reduce its active horizon from ten to seven.
   - Rationale: this is the narrowest reviewable patch and avoids creating parallel forecast models while the product surface is being aligned.
   - Alternative considered: rename all Swift types to `NextSevenDays*`. That would better match the recommended spec names but would create a broad mechanical diff with little user-visible value in this change.

2. Derive the Home forecast start from the same existing target morning decision already used by the hero.
   - Rationale: the spec says row 1 is the next immediate alarm or next relevant morning, including today when today's relevant wake is still upcoming. The Home snapshot already computes that target morning.
   - Alternative considered: keep filtering strictly after today's date. That would preserve old behavior but fail the new same-window rule when today's wake is still upcoming.

3. Build compact Weekly Fajrcast days from the resolved anchor/forecast-start date forward.
   - Rationale: the attached v14 spec explicitly removes the centered chart window and says previous mornings should not be included in the aligned MVP behavior.
   - Alternative considered: leave the centered seven-day chart intact and only rename the list. That would keep an active mismatch between the two support surfaces.

4. Leave alarm delivery and scheduling windows unchanged.
   - Rationale: the specs distinguish display horizon from active scheduled horizon. Showing seven rows must not schedule every visible day or rewrite persisted intentions.

## Risks / Trade-offs

- Internal type names may still say `NextTenMornings` or `morningcast` temporarily -> Mitigated by changing user-visible copy, constants, and tests while keeping the implementation diff scoped.
- If the active window cannot resolve seven days, the list may show fewer rows -> Existing empty/partial data behavior remains truthful; the ready path is capped at seven and tests cover normal resolved data.
- Weekly Fajrcast anchor changes may affect snapshot tests that assumed centered geometry -> Mitigated with focused test updates that assert forward seven-day order and Home alignment.
