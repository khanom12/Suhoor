## Context

Current post-onboarding UI is tab-first. Existing `TodayHomeView`, `WakeScreen`, Fajr window providers, wake-list snapshots, and settings routes provide useful pieces. The new home should adapt those pieces through a snapshot so SwiftUI does not own calculation logic.

## Goals / Non-Goals

**Goals:**
- Introduce `MorningHomeSnapshot`.
- Introduce `SubhHomeView` as the primary home surface.
- Reuse existing Fajrcast and wake-list providers.
- Keep settings reachable and details navigable.

**Non-Goals:**
- No full redesign of every detail screen.
- No first-wave fasting/observance widget expansion beyond context flags.
- No prayer-time calculation inside SwiftUI.

## Decisions

- Build a small home snapshot provider/extension from existing `ScheduleManager` provider outputs.
- Reuse `WeeklyFajrcastCard` and existing alarm detail surfaces initially.
- Keep the home in one `NavigationStack` owned by `SubhHomeView`.

## Risks / Trade-offs

- [Risk] Reusing legacy detail views can expose older alarm language. → Mitigation: adapt primary home copy now and leave detail cleanup to focused follow-up changes where needed.
- [Risk] New home can duplicate provider logic. → Mitigation: pull data from existing providers and keep model construction outside view layout.
