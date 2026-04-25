## Context

The app target uses a filesystem-synchronized `Subh` group, so every Swift file under `Subh/` is compiled unless removed or excluded. Previous prune work disconnected the tab-era surfaces from navigation, but the source files, supporting providers, and some tests still remain as compiled or orphaned legacy code.

## Goals / Non-Goals

**Goals:**
- Delete retired production UI families rather than leaving unreachable screens in the app target.
- Remove ScheduleManager APIs/providers whose only consumers are retired surfaces.
- Keep the MVP home, Fajrcast, Morningcast, Tomorrow Morning detail, settings, prayer/Hijri configuration, and scheduling behavior working.
- Keep dormant local data undisturbed.
- Reduce code and compile surface area more than adding replacement code.

**Non-Goals:**
- Do not change the MVP wake rule or prayer-time calculations.
- Do not delete existing `Suhoor.*` storage keys or migrate user data.
- Do not build future fasting/Qada/observance widgets in this pass.
- Do not remove Hijri, prayer-time, reliability, or alarm scheduling tests that still protect MVP behavior.

## Decisions

- Delete unreachable SwiftUI feature folders first: `Plan`, `Progress`, and legacy `Today` dashboard components have no production entry point after the single-screen home redesign.
- Keep shared engines only when they feed current MVP behavior or active tests. Engines used solely by deleted surfaces can be removed with their tests.
- Keep Fajrcast detail and reusable wake row presentation because the single home still uses Weekly Fajrcast and Morningcast.
- Collapse onboarding to the MVP path: value preview, location, reliability permissions, success. The old offset picker and Ramadan/future-visualization/support-behavior branches are removed so onboarding does not contradict the shared Fajr-end wake resolver.
- Replace legacy navigation intent cases with the reduced live intents instead of redirecting old plan/Qada intents forever.
- Prune stale copy constants and unused editor controls that only described deleted screens, while keeping settings scaffolding used by the current app.
- Remove disabled countdown, AlarmKit test-mode, alarm-state/test-record, debug-event, and sound-check scheduling paths because they have no live UI entry point and still expanded the launch/build surface.
- Treat the full XCTest suite result as valid if the only remaining failure is the documented baseline `ensureScheduleWindowRetagsWhenSelectionRevisionChanges`.

## Risks / Trade-offs

- Removing old UI files can expose hidden references from settings or tests -> mitigate by compiling frequently and deleting dependent code in the same pass.
- Some legacy stores remain because schedule resolution still carries compatibility fields -> keep data dormant until a later domain-model simplification pass can safely collapse persisted models.
- Full suite has a known baseline failure -> record it separately from regressions introduced by this prune.
