## Context

`AlarmKitTestSettingsStore` and `AlarmKitTestRunStore` persist small diagnostic/test-mode models in `UserDefaults` using JSON. Both stores currently decode with `try?`, which prevents crashes but leaves invalid data in place after a failed decode. That makes recovery implicit and repeat failures possible.

This change is intentionally narrow: it affects AlarmKit test-mode persistence only, not normal alarm preferences, schedule caches, or scheduled alarm reconciliation.

## Goals / Non-Goals

**Goals:**
- Keep valid persisted AlarmKit test settings and test-run state behavior unchanged.
- Recover deterministically from invalid JSON or incompatible persisted values.
- Add focused tests that use isolated `UserDefaults` suites.

**Non-Goals:**
- Do not change the user-facing alarm scheduling workflow.
- Do not introduce a shared persistence abstraction for all stores.
- Do not migrate unrelated settings stores.

## Decisions

- Inject `UserDefaults` into the AlarmKit test stores, defaulting to `.standard`.
  - Rationale: isolated suites make recovery behavior directly testable without touching real app defaults.
  - Alternative considered: add test-only cleanup hooks around `.standard`; this is more brittle and less explicit.
- Replace invalid test settings with encoded defaults on load.
  - Rationale: settings have a known safe default, and persisting it prevents repeated decode failures.
  - Alternative considered: remove the key and rely on fallback each time; this preserves repeated failed-load ambiguity.
- Remove invalid test-run state on load.
  - Rationale: a test-run state represents one scheduled diagnostic run and has no meaningful default run identity or dates.
  - Alternative considered: synthesize a default run; that could imply scheduled alarms that do not exist.

## Risks / Trade-offs

- Invalid test-mode diagnostic data is discarded during load -> mitigated by limiting the behavior to AlarmKit test-only stores.
- `UserDefaults` injection slightly expands store initializers -> mitigated by default parameters preserving existing call sites.

## Migration Plan

No app-wide migration is required. The first load after this change will normalize invalid AlarmKit test settings to defaults and remove invalid test-run state.

Rollback is straightforward: reverting the store changes returns to silent fallback behavior. Any defaults written during this change remain valid settings data.
