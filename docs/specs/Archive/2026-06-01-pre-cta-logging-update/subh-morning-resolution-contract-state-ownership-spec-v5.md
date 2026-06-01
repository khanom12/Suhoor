# Subh Morning Resolution Contract and State Ownership Specification v5 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-resolution-contract-state-ownership-spec-v5.md` |
| Version | 5 |
| Spec status | Active resolved-morning ownership contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Quick Mutation, Day Purpose, Quiet/Pause, Hero, Detail, Next 7, Wake Sessions, Alarm Delivery |
| Owning domain / surface | Shared resolved morning model and ownership boundaries |

## May 31, 2026 update status

Version 5 aligns the resolver with the May 31 morning-state framework: visible selector order, Today/Tomorrow Morning labels, Next 7 layout needs, wake-session boundary fields, optional Fajr follow-up after Suhoor, and late Fajr logging below the context card.

## 1. Purpose

Morning Resolution is the source of truth that tells each surface what one morning means and what the user can do.

It must prevent these concepts from collapsing into one mode:

```text
calendar meaning
user intention
wake purpose
alarm activation
delivery status
execution status
wake acknowledgement
prayer completion
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
  active | quiet | pausedInherited | ringsOnceDespitePause | blocked | issue | unavailable | fajrStartEventOnly

WakeExecutionState
  notStarted | scheduled | ringing | followUpPending | awakeAcknowledged | quietCancelled | fastingLogged | fajrLogged | endedNoResponse | issue

Outcome / Log State
  wake acknowledgement, fasting status/intention log, Fajr prayer log, late Fajr log, no-response record, error record
```

Visible selector order is presentation-only:

```text
Suhoor | Fajr
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
4. Active resolved Fajr/Suhoor alarm or eligible Fajr-start event.
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

| Date context | Default wake purpose | Default alarm relation |
| --- | --- | --- |
| Ordinary non-Ramadan morning | Fajr | User/default Fajr alarm config, commonly before Fajr ends |
| Ramadan fasting morning where Ramadan support is active | Suhoor | User/default Suhoor alarm config, commonly before Fajr begins |
| User-selected Suhoor morning | Suhoor | Saved Suhoor alarm config |
| User-selected Fajr morning | Fajr | Saved Fajr alarm config |

Legacy `Pre-Fajr`, `Early`, or `Fast` top-level states normalize to Suhoor for MVP compatibility. Non-fasting before-Fajr states are deferred and must not become active resolver output.

## 6. Timing outputs

A resolved morning must include enough timing data for surfaces and delivery:

```text
fajrBegins
fajrEnds
nightStart
suhoorWindowStart = start of last third of night
relevantWindowEndForSelectedPurpose
latestWakeTime = relevantWindowEnd - 5 minutes
latestNewSessionCreationTime = relevantWindowEnd - 6 minutes
defaultWakeTime
selectedWakeTime
wakeAttemptSchedule
```

The resolver should provide the timing reason in user-facing terms such as `30 min before Fajr ends` or `30 min before Fajr begins`. Do not expose technical `anchor` copy in the public UI.

## 7. Alarm state resolution examples

| Inputs | Resolved purpose | Resolved alarm state | User-facing primary status |
| --- | --- | --- | --- |
| Purpose Fajr, no override, alarms active | Fajr | active | Wake time, e.g. `5:42 AM` |
| Purpose Suhoor, no override, alarms active | Suhoor | active | Wake time, e.g. `4:51 AM` |
| Purpose Fajr, date Quiet | Fajr | quiet | `Quiet` |
| Purpose Suhoor, date Quiet | Suhoor | quiet | `Quiet` |
| Global Pause active, no date exception | Fajr/Suhoor | pausedInherited | `Alarms paused` |
| Global Pause active + ring once | Fajr/Suhoor | ringsOnceDespitePause | Wake time + `Rings tomorrow only` |
| Suhoor acknowledged, no Fajr follow-up requested | Suhoor/Fajr phase | fajrStartEventOnly | Fajr-start event only |
| Permission blocked | Fajr/Suhoor | blocked | `Turn on alarms` |
| Delivery expected but failed | Fajr/Suhoor | issue | `Alarm issue` |

## 8. Quiet/Pause invariants

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

## 9. Wake execution resolution

When wake execution starts, execution state temporarily becomes the primary Hero driver.

Execution states:

| Execution state | Hero implication |
| --- | --- |
| `ringing` | Slot 3 `Time to wake`; Slot 6 `I’m awake` |
| `followUpPending` | Slot 3 `Next alarm soon`; Slot 6 `I’m awake` |
| `awakeAcknowledged` | Remaining follow-ups cancelled; post-action CTAs may appear after delay |
| `quietCancelled` | Remaining follow-ups cancelled by deliberate Quiet cancellation; not wake acknowledgement |
| `fastingLogged` | `Fasting today` / checked status before Fajr begins |
| `fajrLogged` | `Fajr complete` / checked status |
| `endedNoResponse` | `Alarm ended`; `No response recorded` |
| `issue` | `Alarm issue`; review path |

## 10. Snapshot requirements

A resolved snapshot must provide enough data for all visible surfaces without each surface recalculating its own truth.

Minimum fields:

```text
morningDate
relativeMorningLabel            // Today Morning / Tomorrow Morning for Hero
locationDisplayName
gregorianDate
hijriDate
fajrBegins
fajrEnds
suhoorWindowStart
wakePurpose
visiblePurposeSelectorOrder      // Suhoor | Fajr
fastingPurpose
fajrAlarmConfig
suhoorAlarmConfig
selectedAlarmTime
savedInactiveAlarmTime
resolvedAlarmState
wakeExecutionState
alarmStatusCopy
supportingCopy
contextCardCopy
opportunityTags
next7PurposeLine                 // Awake for Fajr / Awake for Suhoor
next7LeftValue                   // wake time or Quiet
next7QuietToggleState
trailingRowStatus
availableActions
acknowledgementSource
logState
lateFajrPromptState
reconciliationWarnings
```

## 11. Suhoor-to-Fajr outcome separation

Suhoor and Fajr acknowledgement are not the same fact.

```text
Suhoor wake acknowledgement = user woke for Suhoor before Fajr
Fajr-start event           = single event when Fajr begins after Suhoor
Fajr wake acknowledgement   = user is awake for Fajr after Fajr begins / optional follow-up
Fajr prayer completion      = user reports praying Fajr
```

For a Suhoor-selected morning:

1. `I’m awake` during the Suhoor alarm records `suhoorWakeOutcome`.
2. `I’m fasting today` before Fajr records fasting intention/status for the day.
3. At Fajr begins, a single Fajr-start event may occur.
4. A full Fajr wake-check session is not automatic.
5. If the user opts into Fajr follow-up, `I’m awake for Fajr` records `fajrWakeOutcome`.
6. `I prayed Fajr` records Fajr prayer completion separately.

For a Fajr-selected morning, the active wake CTA `I’m awake` records `fajrWakeOutcome` directly.

## 12. Late Fajr prompt resolution

After Fajr end, the Hero switches to the next relevant morning. If Fajr prayer completion is not logged, resolver may expose a late prompt below the context card.

```text
lateFajrPromptState = hidden | visibleEarlierToday | visibleYesterdayMorning | expired
```

Copy:

```text
visibleEarlierToday      → I Prayed Fajr Earlier Today
visibleYesterdayMorning  → I Prayed Fajr Yesterday Morning
```

Expiry:

- if next selected purpose is Fajr, expire at next Fajr window begins;
- if next selected purpose is Suhoor, expire at next Suhoor window begins;
- hide immediately once prayer completion is logged.

## 13. Surface consumption rules

| Surface | Consumes | May mutate? |
| --- | --- | --- |
| Home Hero | Current/next resolved snapshot | Yes: purpose, Quiet, ring-once, awake/log CTAs, alarm time |
| Context card / late prompt | Current snapshot + previous unresolved Fajr log state | Yes: late Fajr logging CTA only |
| Day Detail | Selected date snapshot | Yes: purpose, Quiet, ring-once, alarm time, fasting purpose, reset |
| Next 7 Mornings | Seven resolved snapshots | Yes: one-morning Quiet toggle only; row body navigates to Detail |
| Month | Month/list snapshots | No inline Quiet/Pause; selected day navigates to Day Detail |
| Weekly Fajrcast | Same seven visible dates | No mutation |
| Alarm Delivery | Active scheduled horizon snapshots | Schedules/cancels only from resolver output |
| Wake Session | Executing snapshot | Updates execution/log state only |

## 14. Acceptance criteria

1. Resolver output exposes `WakePurpose.fajr` or `WakePurpose.suhoor`, not Quiet as a purpose.
2. Visible purpose selector order is `Suhoor | Fajr`.
3. Quiet and Pause are alarm-state/policy layers.
4. Purpose-specific Fajr/Suhoor alarm configs survive purpose switching and Quiet/Pause.
5. Missing permissions or delivery failure never appear as Quiet.
6. Quiet never creates missed-prayer or missed-fast records.
7. Pause inherited rows return to active plans after resume; manual Quiet rows stay Quiet.
8. Ring-once rows while paused do not resume all alarms.
9. Wake execution state overrides planning controls after the first alarm starts.
10. System dismissal produces an awake acknowledgement with source `systemAlarmDismiss`.
11. Next 7, Month, and Weekly Fajrcast render from the same resolver output as Home/Detail.
12. Next 7 may mutate one-morning Quiet through its row toggle.
13. Suhoor completion does not automatically create a Fajr wake-check session.
14. Late Fajr logging is resolved separately from the next-morning Hero state.
