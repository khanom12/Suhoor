# Fajr-Centered Refactor Migration Matrix

## Staged Passes
- Pass 1: domain seams and compatibility layer
- Pass 2: resolver pipeline
- Pass 3: migration and scheduler reconciliation
- Pass 4: UI/IA refactor
- Pass 5: terminology cleanup and regression hardening

## Persistence Migration Matrix
| Existing store/type | Target store/type | Mapping | Idempotency | Duplicate-notification avoidance | Failure fallback |
| --- | --- | --- | --- | --- | --- |
| `Suhoor.AppSettings` / `AppSettings` | `Suhoor.MorningPlanState` + profile adapters | Seed the default daily morning plan from legacy wake/reminder/Fajr settings | Upsert the singleton state by schema version | Scheduler reconciliation only runs after migration validation succeeds | Keep legacy settings authoritative and skip activation |
| `Suhoor.DefaultAlarmConfig` / `DefaultAlarmConfig` | `MorningPlan.defaultDailyPlan` | Relative wake stays anchor-based; fixed wake is preserved through transitional compatibility fields | Rebuild the default daily plan deterministically from legacy defaults | Cancel legacy identifiers before fresh materialization | Retain legacy defaults and retry later |
| `Suhoor.DailyAlarmOverrides` / `DailyAlarmOverride` | `PlanDateAssignment` + compatibility override adapter | Day-specific overrides remain day-specific and keep precedence over the default plan | Upsert by `dateKey` | Day-scoped cancel/reschedule only after commit | Read the legacy override directly |
| `Suhoor.ScheduledDateSources` | Overlay plan assignments | Observance/Qada/special-day sources remain overlays on top of the default plan | Stable IDs derived from `sourceID`/`groupID`/`dateKey` | Overlay migration does not schedule until the active window is rebuilt | Legacy source resolution stays active |
| `Suhoor.FastIntentSelections` | `ResolvedDayContext` inputs | Existing intent selections become context hints and supporting tags | Upsert by `dateKey` | No schedule mutation during pure context migration | Continue reading legacy selections |
| `Suhoor.FastLogEntries` | `CompletionRecord` adapter | Legacy fast logs are exposed as completion/progress records | Upsert by `dateKey` | No notification impact | Continue using the fast log store |
| `Suhoor.QadaBacklogState`, `Suhoor.QadaBatchState`, legacy `Suhoor.QadaPlanState` | `QadaLedger` + overlay assignments | Preserve Qada obligations and planned dates, but resolve them through the new context pipeline | Upsert by stable ledger IDs and `dateKey` | Reconciliation waits until the full date set is known | Keep legacy Qada stores authoritative |
| `Suhoor.ScheduleCache` | refreshed active-window cache | Rebuild cached schedules from the new resolver output | Cache decode failures fall back to empty and recompute | Cancel-and-rebuild inside the scheduled horizon | Drop cache and refresh |

## Event Taxonomy
| Event | Relative to | User-visible | Affects completion |
| --- | --- | --- | --- |
| `wakeReminder` | Fajr anchor or fixed-clock compatibility | Yes | No |
| `wakeAlarm` | Wake anchor + delta or fixed-clock compatibility | Yes | Yes |
| `wakeFollowUp` | Wake alarm + snooze/follow-up offset | Yes | No |
| `fajrBoundaryNotice` | Fajr start boundary | Yes, optional | No |
| `iftarReminder` | Maghrib boundary | Yes | No |

## Migration Notes
- `fajrEnd` stays abstract in the model. If a resolver uses sunrise as a proxy, that stays internal to `RuleDecisionLog` and provider notes.
- Fixed-time wake support is transitional compatibility only. New planning remains anchor + delta based.
- Existing installs preserve current effective wake behavior by defaulting migrated plan state to legacy-compatible activation, so the app does not surprise users with new daily alarms.

## Out of Scope
- Live masjid/jama'ah integration
- Advanced analytics
- Educational/content overhaul
- Broad multi-prayer expansion
- Full visual redesign beyond what the new IA requires
