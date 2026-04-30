## Context

The Subh home already contains a Tomorrow Morning hero, Weekly Fajrcast, and a 10-item Morningcast list. The existing Morningcast card reuses `WakePagePresentation.row(...)`, which produces visible subtitles such as ordinary-day prose, adjustment state, and Fajr relation text. The provided v1 specification requires a dedicated Next 10 Mornings surface whose compact rows show exactly three concepts: Gregorian-first date label, compact tags, and wake time/status.

## Goals / Non-Goals

**Goals:**

- Keep the card inside the existing single Subh home surface.
- Add a dedicated presentation pipeline that maps `WakeRowEntry` into `NextTenMorningsRowDisplay` without parsing visible strings.
- Reuse existing glass, divider, time-lockup, and tag color vocabulary.
- Keep the renderer passive: it receives prepared display rows and does not infer fasting or observance compatibility.
- Cover the tag doctrine and header contract with deterministic tests.

**Non-Goals:**

- No prayer-time, wake-resolution, scheduling, alarm delivery, or storage behavior changes.
- No full day-detail redesign.
- No quiet-mode pipeline implementation beyond supporting the future visual contract when a row is classified that way.
- No new analytics, telemetry, dependencies, or persisted schema.

## Decisions

- Create `NextTenMorningsPresentation` beside the home presentation layer rather than extending `WakePagePresentation`.
  - Rationale: the forecast card has a different visible contract from the Wake list. Reusing wake-row subtitles would keep operational prose in the compact home forecast.
  - Alternative considered: mutate `WakePagePresentation.row(...)`. That would risk regressing existing wake list/detail surfaces that still need explanatory text.

- Use `WakeRowEntry.activeDay.tagResult`, `resolvedDayContext`, `effectiveConfig`, and existing `FastIntentEngine.displaySecondaryTags(...)` ordering as the resolver inputs.
  - Rationale: the tag resolver consumes normalized domain output and existing compatibility ordering instead of recreating observance rules inside SwiftUI.
  - Alternative considered: build tags from `rowPresentation.chipTitles`; rejected because those chips include operational labels such as `Changed`, `Skipped`, and `Fixed wake`.

- Keep Shawwal 6 suppression future-ready through a small `ShawwalSixProgressSummary` input while defaulting to incomplete until completion-specific data is wired into the forecast.
  - Rationale: the compact resolver can satisfy the visual suppression contract in tests without inventing completion counts from generic fast history.
  - Alternative considered: infer completion from all completed Shawwal fasts; rejected because the spec requires counting only intended Shawwal 6 fasts.

- Render tags as text-only capsules using existing fast-tag colors and glass chip vocabulary.
  - Rationale: this preserves the existing tag visuals while keeping the compact row readable and calm.
  - Alternative considered: reuse `WakeFilterChip` directly; rejected because it is icon-capable and tuned for filter controls rather than a non-tappable forecast row.

## Risks / Trade-offs

- Row-width constraints may require tag capping before all valid tags are visible. Mitigation: cap visible tags at three, hide overflow visually, and keep full tag meaning in accessibility labels.
- Quiet mode is not a complete upstream state yet. Mitigation: model it as a resolver input and leave default production rows unchanged until the pipeline provides the state.
- The current forecast entries may contain fewer than ten rows if schedule data is unavailable. Mitigation: preserve truthful partial/empty behavior rather than invent wake times.

## Migration Plan

This is a presentation-only replacement on the home surface. The existing schedule snapshots, day detail navigation, alarm scheduling, and persisted user settings remain unchanged. Rollback is limited to restoring the previous Morningcast card view and its old header constants.
