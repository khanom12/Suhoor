## Overview

The intended architecture is:

1. Inputs enter through settings, location, calculation method, context flags, and overrides.
2. `MorningScheduleResolver` resolves the prayer window, wake anchor, wake time, wake state, explanation, and event sequence.
3. `DaySchedule` and UI snapshots are legacy-compatible projections of that resolved morning.
4. Caches store projections and decision logs, but never define wake timing independently.

This lets Subh optimize performance with caching while keeping one conceptual and code-level source for wake determination.

## Resolver Boundary

`MorningScheduleResolver` owns:

- Fajr start and supported Fajr end prayer-window resolution.
- Wake anchor selection.
- Wake time computation for `preFajr`, `inFajr`, `postFajr`, and fixed wake rules.
- Latest-wake cap behavior.
- Resolved wake state classification.
- Decision-log values consumed by detail surfaces.

Compatibility code may still produce `DaySchedule` because much of the app reads that model, but it must either adapt a `ResolvedDaySnapshot` or call resolver-owned wake helpers.

## Caching

Schedule caches remain useful for performance. A cache entry is valid only when its inputs still match the current resolver-relevant configuration. The cache wake-rule signature protects the app from showing older `preFajr/fajrStart/45` output after a migration to the Subh MVP default.

## Legacy Surfaces

The first cleanup pass does not remove every old setting, onboarding label, or compatibility model. Those areas may remain while they are not reachable as independent authorities for Tomorrow Morning, Morningcast, Fajrcast, alarm scheduling, or detail views. Later OpenSpec changes can retire or redesign legacy customization controls deliberately.

## Commit And Main Branch Plan

Before committing to `main`, validate:

- OpenSpec strict validation.
- Focused tests for default migration, stale-cache rejection, resolver-backed schedule building, and home snapshot card shape.
- Project listing/build sanity for the renamed `Subh.xcodeproj`.

Pushing to `main` should happen only after the active redesign changes validate together, because the rename creates a large file move and the commit should represent a coherent app state.
