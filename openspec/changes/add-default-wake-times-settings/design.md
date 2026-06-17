# Design

## Data Model

`DefaultWakeRule` records purpose, Fajr boundary, direction, and minutes. It is exposed through `DefaultAlarmConfig` so existing persisted defaults remain the compatibility source and old installs can decode safely. The canonical defaults are:

- Fajr: 30 minutes before Fajr ends.
- Suhoor: 60 minutes before Fajr begins.

Legacy factory Suhoor values remain available for migration tests, but the app default moves to the product-required Suhoor value.

## Resolution

The resolver accepts a default rule, a date-specific prayer window, and purpose. Valid combinations resolve as:

- Fajr at Fajr begins.
- Fajr after Fajr begins.
- Fajr before Fajr ends.
- Suhoor before Fajr begins.

Invalid combinations return an invalid resolution instead of silently switching boundaries.

## Validation

Fajr validation computes the shortest and longest Fajr windows over the next 12 months using deterministic prayer-time calculation inputs. Fajr begins supports at-start and safe after-start values up to the shortest window minus 10 minutes. Fajr ends supports before-end values from 10 minutes through the shortest window. Invalid saved Fajr rules surface as needing review and provide a safe temporary rule for scheduling.

Suhoor validation keeps the rule before Fajr begins. The current app does not expose a separate earliest Suhoor boundary in this settings pass; existing early-worship/final-third logic remains in the morning resolver and hero surfaces.

## Scheduling Integration

`DefaultAlarmConfig` feeds `EffectiveDailyConfig`, `MorningPlanResolver`, `MorningScheduleResolver`, `ScheduleService`, and `WakeSessionStore`. Generated early-worship plans consume the Suhoor default rule. Default Fajr plans consume the Fajr default rule. Settings changes call schedule refresh after freezing protected default-based mornings.

No parallel scheduling path is introduced.

## Manual Override Protection

Date-specific overrides continue to take precedence over defaults. Schedule refresh protects manual days, past mornings, quiet mornings, completed sessions, active/fired sessions, and sessions whose primary wake has already passed. Existing cancelled-Suhoor to Fajr handoff remains allowed because it is an execution transition, not a global default rewrite.

## Settings UX

Settings adds Wake Alarms > Default Wake Times. The detail screen includes Fajr and Suhoor sections, preset/custom controls, a manual-change notice, concise summaries, unavailable-option explanations, and non-color-only review states. Public copy avoids implementation terms.

## Validation Plan

- OpenSpec strict validation.
- Focused ScheduleServiceExtraction tests for model defaults, resolver, validation, manual override protection, schedule integration, wake checks, and Settings presentation.
- Focused UI tests for Morning Hero interactions affected by the new Suhoor default.
- Xcode build and broader test run where practical.
