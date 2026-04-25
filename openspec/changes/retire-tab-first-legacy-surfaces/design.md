## Context

`RootTabView` currently owns primary navigation and exposes Home, Wake, Plans, and Progress as tabs. The single-screen Subh home should become the launch surface without forcing a broad deletion of legacy feature code.

## Goals / Non-Goals

**Goals:**
- Replace the post-onboarding root with `SubhHomeView`.
- Remove the visible bottom tab bar from primary IA.
- Keep existing settings/detail surfaces usable where still needed.

**Non-Goals:**
- No deletion of all legacy Plan/Progress/Wake files.
- No complete route audit for every notification/deep-link path beyond maintaining safe app startup.

## Decisions

- Change `ContentView` to instantiate `SubhHomeView` when onboarding is complete.
- Leave `RootTabView` compiled temporarily if other code still references it.
- Add tests or compile checks around root/home surface behavior where feasible.

## Risks / Trade-offs

- [Risk] Existing navigator intents may assume tabs. → Mitigation: keep the old shell compiled and handle the important home/settings/detail paths in `SubhHomeView`.
