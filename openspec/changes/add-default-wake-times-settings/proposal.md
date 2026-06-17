# Add Default Wake Times Settings

## Summary

Add Settings > Wake Alarms > Default Wake Times so users can choose default Fajr and Suhoor wake rules for future mornings. The rules must feed the existing morning planning, wake-session, wake-check, and scheduling pipeline rather than creating a separate preference-only path.

## Motivation

Subh currently has hard-coded or compatibility-derived wake defaults in the morning engine. Users need a clear settings surface for future default Fajr and Suhoor wake times while preserving the product model: a morning is the planning unit, wake purpose is separate from delivery, and date-specific manual changes always win over global defaults.

## Scope

- Persist default Fajr and Suhoor wake rules through the existing alarm config model.
- Resolve defaults through the existing morning plan and schedule resolver spine.
- Validate Fajr defaults against the shortest Fajr window across the next 12 months with a 10-minute safety buffer before Fajr ends.
- Keep Suhoor anchored before Fajr begins.
- Add Settings navigation, detail controls, review copy, summaries, and accessibility labels.
- Refresh schedules after valid default changes while preserving manual overrides and protected wake sessions.
- Add deterministic tests for defaults, validation, resolver behavior, manual override protection, scheduling integration, and Settings presentation.

## Non-Goals

- Redesign Settings information architecture beyond adding the Default Wake Times row under Wake Alarms.
- Merge wake-check configuration into wake-time defaults.
- Add historical fasting, Qada, or prayer-log features.
- Create a second schedule generator or a disconnected default-wake store.
