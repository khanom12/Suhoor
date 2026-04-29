## Context

Subh has already moved toward a daily morning model, but some startup paths still let persisted cache and legacy compatibility state become the first rendered active window. When that window is sparse, implicit Ramadan generation can make a future Ramadan date, notably February 8, 2027, appear as the active morning after onboarding or app launch.

The affected code spans `MorningPlanStore`, `ScheduleManager`, `ActiveWindowSnapshotBuilder`, `OnboardingViewModel`, home presentation, UI-test launch configuration, and scheduling tests.

## Goals / Non-Goals

**Goals:**
- Make the device clock the normal source of current date/time for active-window resolution.
- Keep fixed clocks available only for DEBUG/UI tests and unit tests.
- Prevent new current-product profiles from creating `.legacyCompat` morning-plan activation.
- Reject cache that does not represent the current local today/tomorrow daily window.
- Preserve user settings, overrides, and existing storage namespaces.

**Non-Goals:**
- Do not change prayer-time calculation assumptions or Hijri baseline dates.
- Do not add a production time override setting.
- Do not redesign onboarding or Home beyond making their date source correct.
- Do not intentionally cancel unrelated already-scheduled alarm events.

## Decisions

1. **Use an injected clock at the scheduling boundary.** `TimeProviding` remains internal and defaults to `SystemTimeProvider`; tests pass `FixedTimeProvider`. This keeps production behavior tied to device time while making regressions repeatable.

2. **Make legacy compatibility migration-only.** `MorningPlanStore` decodes and migrates persisted `.legacyCompat`, but a missing `MorningPlanState` now initializes as `.dailyActive` even when older Suhoor settings exist. This prevents the sparse Ramadan fallback from being recreated.

3. **Validate cache by active-window shape, not only timestamps.** Cache reuse requires same-day generation, same-day last scheduling, and for daily activation, visible entries for today and tomorrow. A cache generated today but pointing at future Ramadan is therefore rejected.

4. **Refresh before showing Home after onboarding.** Completing onboarding updates configured state only after forcing a schedule refresh path, so the first Home render is based on fresh current-date resolution rather than stale persisted state.

5. **Keep UI-test fixed time explicit.** DEBUG launch arguments parse a fixed ISO-8601 date only when the app is running under the UI-test fixture path; release and TestFlight builds do not read or honor that argument.

## Risks / Trade-offs

- **Risk:** Rejecting more cached windows can briefly show loading or locating states. → Mitigation: recompute immediately when location/settings are available and keep permission messaging clear when they are not.
- **Risk:** Tests that assumed legacy compatibility on first load will fail. → Mitigation: update them to assert the current Subh product model or explicitly seed persisted legacy state when testing migration.
- **Risk:** Some direct `Date()` calls remain in peripheral logging or persistence timestamps. → Mitigation: only core resolution/presentation decisions use the injected clock in this change; remaining calls are acceptable where they do not choose the active morning.
- **Risk:** Physical-device AlarmKit behavior cannot be fully proven on simulator. → Mitigation: unit/UI tests cover date anchoring; manual device verification remains required for real alarm delivery.
