## Context

`DefaultAlarmConfig.default` previously represented the old factory wake default, and existing installs may also have an AppSettings-derived inherited default such as 45 minutes before Fajr start. The first Subh MVP needs fresh installs and inherited pre-Subh defaults to use supported Fajr end minus 30 minutes, while clearly custom settings must not be overwritten.

## Goals / Non-Goals

**Goals:**
- Update default wake anchor and state to supported Fajr end minus 30 minutes.
- Add a migration path that detects inherited pre-Subh Fajr-start defaults, including the 30-minute and 45-minute variants already seen in local installs.
- Persist the migrated new default after loading old factory-default settings.

**Non-Goals:**
- No new wake customization UI.
- No changes to bundle id or storage keys.
- No reinterpretation of Fajr end beyond the existing supported boundary provider.

## Decisions

- Represent the old factory default as a static legacy value on the config model or store, and treat known inherited Fajr-start preset defaults as migration candidates.
- Migrate during config load so existing scheduling paths receive the new default.
- Detect old-default equivalence with a focused predicate instead of broad field replacement: pre-Fajr, Fajr-start, relative timing, no latest-wake cap, matching wake/suhoor offsets, and a known inherited preset offset.
- Bump the migration version when the predicate expands so devices that previously passed through migration still receive the correction.

## Risks / Trade-offs

- [Risk] A broad migration could overwrite user choices. → Mitigation: only migrate known inherited Fajr-start preset defaults, and preserve non-preset/custom wake settings.
- [Risk] Existing tests may assume Fajr-start defaults. → Mitigation: update expectations where they describe factory defaults and add explicit migration coverage.
