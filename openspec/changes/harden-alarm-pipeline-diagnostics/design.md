# Design

## Debug install reset gating
`DeveloperInstallReset` now resolves a mode from:
1. `SUBH_DEBUG_INSTALL_RESET_MODE` environment variable
2. `Subh.DebugInstallResetMode` defaults key
3. fallback `.disabled`

Only `.onInstallChange` performs persistent-domain clear + pending notification clear. This preserves nightly alarm continuity during normal debug iteration while keeping explicit reset support for clean-install testing.

## Startup observability
`SubhApp` records a startup event timeline entry for whether debug install reset ran or was skipped, including resolved mode.

## Scheduling diagnostics
Add a pure diagnostics helper that inspects the active morning snapshot after reconciliation:
- count future visible events
- count expected deliverable scheduled events
- compute expected notification identifiers for notification mode

`ScheduleManager` logs a `schedule-diagnostics` timeline entry every refresh and emits warnings when enabled scheduling yields no deliverable events, plus the count of missing pending notifications in notification mode. It does not write raw schedule identifiers into the timeline.

## Validation
- Update `AlarmConfigMigrationTests` to use explicit reset mode for reset-path tests.
- Add tests for disabled-by-default reset mode and environment mode resolution.
