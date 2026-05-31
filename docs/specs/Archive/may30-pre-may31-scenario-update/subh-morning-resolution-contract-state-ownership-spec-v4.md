# Subh Morning Resolution Contract and State Ownership Specification v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-resolution-contract-state-ownership-spec-v4.md` |
| Version | 4 |
| Spec status | Active state-ownership and resolution contract |
| Date | 2026-05-30 |
| Related specs | Index, Alignment, Quick Mutation, Day Purpose, Planning Horizon, Alarm Delivery, Hero, Detail, Quiet/Pause |
| Owning domain / surface | Canonical morning resolver and resolved snapshot semantics |

## May 30, 2026 reconciliation status

This active spec has been reconciled against the finalized Quiet / Pause / Hero / Wake Flow direction. It is implementation-facing. Older wording preserved in `Archive/originals-before-may30-reconciliation/` is historical only and must not be implemented when it conflicts with this active file.

Canonical MVP doctrine used across the active spec set:

```text
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes. `Suhoor` is the only exposed MVP before-Fajr wake purpose and is fasting/suhoor-oriented. Generic non-fasting `Pre-Fajr`, `Early`, `Tahajjud only`, and `Other early worship` flows are deferred unless a later approved spec explicitly reintroduces them.


## 1. Purpose

This spec defines who owns each layer of the resolved morning and how the app derives one canonical morning snapshot for Home, Day Detail, Next 7, Month, Weekly Fajrcast, Wake Sessions, and Alarm Delivery.

The resolver must prevent these concepts from collapsing into one mode:

```text
calendar meaning
user intention
wake purpose
alarm activation
delivery status
execution status
completion/logging
analytics credit
```

## 2. Canonical resolved model

A resolved morning is produced from these layers, in this order:

```text
MorningContext
  date, location, prayer times, Hijri/Gregorian context, Ramadan/Eid/observance context

WakePurpose
  Fajr | Suhoor

FastingPurpose
  none | Ramadan | Sunnah opportunity default | Voluntary | Qada | Vow/Nadhr | Kaffarah | Other fast

PurposeSpecificAlarmConfig
  fajrAlarmConfig
  suhoorAlarmConfig

DateAlarmOverride
  none | quiet | ringDespitePause

GlobalWakeAlarmPolicy
  active | pausedIndefinitely

DeliveryCapability
  allowed | blockedByPermission | blockedByFocusOrSystem | missingLocation | missingPrayerTimes | platformUnavailable | issue

ResolvedAlarmState
  active | quiet | pausedInherited | ringsOnceDespitePause | blocked | issue | unavailable

WakeExecutionState
  notStarted | scheduled | ringing | followUpPending | awakeAcknowledged | fastingLogged | fajrLogged | endedNoResponse | issue

Outcome / Log State
  wake acknowledgement, fasting status/intention log, Fajr prayer log, no-response record, error record
```

## 3. Ownership matrix

| Layer | Owner | Must not own |
| --- | --- | --- |
| Calendar/prayer context | Prayer-time and context resolvers | User alarm activation, Quiet/Pause, completion credit |
| Observance opportunity | Day-purpose/opportunity resolver | Alarm scheduling by itself |
| Wake purpose | Shared mutation contract + durable plan/intention store | Delivery permission, execution status |
| Fasting purpose | Day-purpose / fasting domain | Top-level wake mode labels |
| Purpose-specific alarm config | Alarm settings + date-specific overrides | Global Pause or delivery reliability |
| DateAlarmOverride | Quiet/Pause contract and mutation contract | Wake purpose or fasting purpose |
| GlobalWakeAlarmPolicy | Settings / Wake Alarms | Date-specific user intention |
| ResolvedAlarmState | Morning resolver | Raw permission errors hidden as Quiet |
| WakeExecutionState | Wake Sessions / Alarm Delivery reconciliation | Fajr/Suhoor selection or calendar meaning |
| Logs/analytics | Morning logs + analytics resolvers | Alarm activation truth by themselves |

## 4. Resolution precedence

Resolve final alarm state using this precedence:

```text
1. Required setup/capability states, if they prevent truthful ringing.
2. Manual DateAlarmOverride.quiet.
3. GlobalWakeAlarmPolicy.pausedIndefinitely, unless DateAlarmOverride.ringDespitePause exists.
4. Active resolved Fajr/Suhoor alarm.
5. Delivery issue/reconciliation state, if scheduling failed after an active state was expected.
```

Manual Quiet beats `ringDespitePause` if both somehow exist. The implementation should avoid creating that combination; if it occurs, treat the date as Quiet and surface a reconciliation note internally.

## 5. Purpose resolution

The resolver exposes only these active MVP wake purposes:

```text
Fajr
Suhoor
```

Defaults:

| Date context | Default wake purpose | Default alarm anchor |
| --- | --- | --- |
| Ordinary non-Ramadan morning | Fajr | User/default Fajr alarm config, commonly before Fajr ends |
| Ramadan fasting morning where Ramadan support is active | Suhoor | User/default Suhoor alarm config, commonly before Fajr begins |
| User-selected Suhoor morning | Suhoor | Saved Suhoor alarm config |
| User-selected Fajr morning | Fajr | Saved Fajr alarm config |

Legacy `Pre-Fajr`, `Early`, or `Fast` top-level states normalize to Suhoor for MVP compatibility. Non-fasting before-Fajr states are deferred and must not become active resolver output.

## 6. Alarm state resolution examples

| Inputs | Resolved purpose | Resolved alarm state | User-facing primary status |
| --- | --- | --- | --- |
| Purpose Fajr, no override, alarms active | Fajr | active | Wake time, e.g. `5:42 AM` |
| Purpose Suhoor, no override, alarms active | Suhoor | active | Wake time, e.g. `4:51 AM` |
| Purpose Fajr, date Quiet | Fajr | quiet | `Quiet` |
| Purpose Suhoor, date Quiet | Suhoor | quiet | `Quiet` |
| Global Pause active, no date exception | Fajr/Suhoor | pausedInherited | `Alarms paused` |
| Global Pause active + ring once | Fajr/Suhoor | ringsOnceDespitePause | Wake time + `Rings tomorrow only` |
| Permission blocked | Fajr/Suhoor | blocked | `Turn on alarms` |
| Delivery expected but failed | Fajr/Suhoor | issue | `Alarm issue` |

## 7. Quiet/Pause invariants

Quiet and Pause do not delete:

- selected Fajr/Suhoor purpose;
- saved Fajr alarm config;
- saved Suhoor alarm config;
- fasting-purpose metadata;
- observance opportunity context;
- existing logs.

Quiet/Pause do not imply:

- missed Fajr;
- missed fast;
- skipped worship;
- delivery failure;
- permission failure.

## 8. Wake execution resolution

When wake execution starts, execution state temporarily becomes the primary Hero driver.

Execution states:

| Execution state | Hero implication |
| --- | --- |
| `ringing` | Slot 3 `Time to wake`; Slot 6 `I’m awake` |
| `followUpPending` | Slot 3 `Next alarm soon`; Slot 6 `I’m awake` |
| `awakeAcknowledged` | Remaining follow-ups cancelled; post-action CTAs may appear after delay |
| `fastingLogged` | `Fasting today` / checked status before Fajr begins |
| `fajrLogged` | `Fajr complete` / checked status |
| `endedNoResponse` | `Alarm ended`; `No response recorded` |
| `issue` | `Alarm issue`; review path |

After execution begins, Quiet is not available for that executing wake.

## 9. Snapshot requirements

A resolved snapshot must provide enough data for all visible surfaces without each surface recalculating its own truth.

Minimum fields:

```text
morningDate
relativeMorningLabel
locationDisplayName
gregorianDate
hijriDate
fajrBegins
fajrEnds
wakePurpose
fastingPurpose
fajrAlarmConfig
suhoorAlarmConfig
selectedAlarmTime
savedInactiveAlarmTime
resolvedAlarmState
wakeExecutionState
alarmStatusCopy
supportingCopy
opportunityTags
trailingRowStatus
availableActions
acknowledgementSource
logState
reconciliationWarnings
```


## 10. Suhoor-to-Fajr outcome separation

Suhoor and Fajr acknowledgement are not the same fact.

```text
Suhoor wake acknowledgement = user woke for Suhoor before Fajr
Fajr wake acknowledgement   = user is awake for Fajr after Fajr begins
Fajr prayer completion      = user reports praying Fajr
```

For a Suhoor-selected morning:

1. `I’m awake` during the Suhoor alarm records `suhoorWakeOutcome`.
2. `I’m fasting today` before Fajr records fasting intention/status for the day.
3. At Fajr begins, if `fajrWakeOutcome` is unconfirmed, Home may show `I’m awake for Fajr`.
4. After Fajr wake acknowledgement and delay, Home may show `I prayed Fajr`.

For a Fajr-selected morning, the active wake CTA `I’m awake` records `fajrWakeOutcome` directly.

## 11. Surface consumption rules

| Surface | Consumes | May mutate? |
| --- | --- | --- |
| Home Hero | Current/next resolved snapshot | Yes: purpose, Quiet, ring-once, awake/log CTAs, alarm time |
| Day Detail | Selected date snapshot | Yes: purpose, Quiet, ring-once, alarm time, fasting purpose, reset |
| Next 7 Mornings | Seven resolved snapshots | No inline Quiet/Pause; row navigates to Day Detail |
| Month | Month/list snapshots | No inline Quiet/Pause; selected day navigates to Day Detail |
| Weekly Fajrcast | Same seven visible dates | No mutation |
| Alarm Delivery | Active scheduled horizon snapshots | Schedules/cancels only from resolver output |
| Wake Session | Executing snapshot | Updates execution/log state only |

## 11. Acceptance criteria

1. Resolver output exposes `WakePurpose.fajr` or `WakePurpose.suhoor`, not Quiet as a purpose.
2. Quiet and Pause are alarm-state/policy layers.
3. Purpose-specific Fajr/Suhoor alarm configs survive purpose switching and Quiet/Pause.
4. Missing permissions or delivery failure never appear as Quiet.
5. Quiet never creates missed-prayer or missed-fast records.
6. Pause inherited rows return to active plans after resume; manual Quiet rows stay Quiet.
7. Ring-once rows while paused do not resume all alarms.
8. Wake execution state overrides planning controls after the first alarm starts.
9. System dismissal produces an awake acknowledgement with source `systemAlarmDismiss`.
10. Next 7, Month, and Weekly Fajrcast render from the same resolver output as Home/Detail.
