# Subh Wake Session Testing, Home Simulation, and Real AlarmKit Mapped Playback Spec

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-session-testing-and-simulation-harness-spec-v2.md` |
| Version | 2 |
| Spec status | Draft; proposed canonical testing/specification layer for Wake Sessions, Home Simulation Mode, and real-device AlarmKit mapped playback |
| Date | 2026-05-26 |
| Supersedes | `subh-wake-session-testing-and-simulation-harness-spec-v1.md` |
| Owning domain / surface | Developer/internal testing, personal device QA, Home Simulation Mode, Wake Session Lab, State Explorer, Real AlarmKit Mapped Playback |
| Related specs | `00-subh-spec-index-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-morning-hero-item-spec-v15.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-pricing-entitlement-spec-v3.md`, `subh-mvp-interaction-inventory-v4.md` |
| Implementation audit status | New v2 spec; not implemented |

---

## 1. Purpose

This spec defines a comprehensive internal testing layer that lets Omar and internal testers personally verify Subh's Wake Sessions, Wake Checks, Home Hero states, Fajr/Suhoor/Quiet interactions, MorningLogs, and real AlarmKit behavior without waiting for real mornings.

The testing layer has three connected utilities:

1. **State Explorer** — instantly inspect how Home and related surfaces look for any simulated date/time/state.
2. **Home Simulation Mode** — make the actual Home screen consume a simulated resolved morning so Omar can interact with the real UI.
3. **Real AlarmKit Mapped Playback** — map simulated Wake Session alarm events onto real near-future AlarmKit alarms while preserving production wake-check spacing.

The testing layer must make Subh faster and safer to test while preserving production trust.

---

## 2. Product and testing principle

Subh is one Fajr-centered morning system. Testing must respect the same product model:

```text
one morning-resolution engine
one Wake Session model
one delivery pipeline
one Hero snapshot path
one MorningLog path
```

The testing layer must not create a second product engine.

Plain-language principle:

```text
Do not fake the product logic.
Fake the world around it.
```

Meaning:

- fake the current app time;
- fake or select the simulated date;
- fake or select the simulated location;
- optionally use real prayer calculations for the selected simulated date/location;
- optionally use a custom artificial prayer window for edge-case testing;
- optionally map simulated alarm events to real AlarmKit alarms;
- then let the real resolver, Home Hero, Wake Session logic, delivery planner, and logs respond.

---

## 3. Core v2 decision

Wake-check spacing must not be compressed in Real AlarmKit Mapped Playback.

Production rule and mapped playback rule:

```text
Wake check interval = 5 minutes
Maximum wake checks after primary = 5
Maximum total attempts = primary + 5 wake checks
```

State jumps may be instant. Real mapped alarm playback preserves production wake-check spacing.

This means:

- State Explorer can instantly jump to `wake check 3 pending` without waiting.
- Real AlarmKit Mapped Playback schedules wake checks five real minutes apart.
- No v2 scenario should use one-minute or two-minute wake-check spacing.

---

## 4. Goals

The testing harness must allow Omar/internal testers to personally verify:

1. Fajr mode.
2. Suhoor mode.
3. Quiet mode.
4. Wake Sessions.
5. Wake Checks with five-minute spacing.
6. Alarm stop vs awake confirmation.
7. `I’m awake for Fajr`.
8. `I’m awake for Suhoor`.
9. `I prayed Fajr`.
10. Fasting intent after Suhoor.
11. Quiet during active wake checks.
12. Slider rescheduling.
13. Hero Action Slot states.
14. MorningLog records.
15. Pending alarm identifiers.
16. Alarm cancellation.
17. AlarmKit physical-device behavior.
18. Notification fallback/degraded behavior where applicable.
19. Permission failure vs Quiet distinction.
20. Cross-surface consistency after changes.
21. Any simulated date/time within the app's supported planning/knowledge range.
22. Seasonal timing differences across the year.
23. Ramadan, Eid, White Days, ordinary days, Monday/Thursday opportunities, and other supported date contexts.

The user should be able to inspect most UI states immediately, and run real AlarmKit sequences in a predictable near-future window.

---

## 5. Non-goals

This spec does not require:

- public production access to time travel;
- public fake Fajr windows;
- public fake prayer logs;
- public fake AlarmKit events;
- public debug buttons;
- StoreKit testing;
- paid-tier implementation;
- long-term analytics implementation;
- cloud sync testing;
- remote telemetry;
- household/family testing;
- adaptive wake-check behavior;
- public advanced wake-check settings;
- changing the iPhone system clock;
- changing production wake-check spacing.

This spec may define future hooks, but the MVP implementation must focus on internal/manual testability and core wake reliability.

---

## 6. Testing layers

Subh testing should use five layers.

| Layer | Name | Purpose | Uses real AlarmKit? | Runs on Omar’s iPhone? | Ships publicly? |
| --- | --- | --- | ---: | ---: | ---: |
| 1 | Unit tests | Prove rules and calculations | No | No | No |
| 2 | Fake scheduler integration tests | Prove scheduling/cancellation without platform delivery | No | Optional | No |
| 3 | UI/snapshot state tests | Prove Hero and surface states | No | Optional | No |
| 4 | State Explorer / Home Simulation Mode | Personal/internal simulated Home testing | No by default | Yes | No public access |
| 5 | Real AlarmKit Mapped Playback | Prove real device alarm behavior with simulated state | Yes | Yes | No public access |

The Wake Session Lab is the internal launchpad and inspector. Home Simulation Mode is the primary UX testing surface.

---

## 7. Build and access model

### 7.1 Build modes

| Build mode | Wake Session Lab / Simulation availability | Intended user |
| --- | --- | --- |
| Debug/local developer build | Fully available | Omar / developer |
| Internal TestFlight build | Available behind internal flag | Omar / trusted testers |
| App Store production build | Not available | Public users |

### 7.2 Release-build rule

Production App Store builds must not expose:

- Wake Session Lab;
- State Explorer;
- Home Simulation Mode controls;
- fake time controls;
- simulated date/time controls;
- artificial prayer-window controls;
- mapped AlarmKit playback controls;
- fake scheduler controls;
- fake log inspector editing;
- simulate alarm fired/stopped buttons;
- test prayer/fast logging that can pollute real logs.

### 7.3 Suggested implementation guard

The visible test UI should be compiled or feature-gated behind development/internal controls such as:

```text
DEBUG build flag
INTERNAL_TESTING build configuration
TestFlight internal feature flag
Developer Mode local override
```

Production builds may keep clean architecture seams such as protocols and injectable dependencies, but must not expose unsafe controls.

---

## 8. Safety rules

### 8.1 Test mode must be visually obvious

When a test scenario is active, Subh must show a visible internal banner on Home and the Wake Session Lab:

```text
TEST MODE ACTIVE
```

The user must never confuse a simulated morning with a real worship record.

### 8.2 Test data must not pollute real data

Every test-created Wake Session, MorningLog, scheduled alarm, and event must include:

```text
isTest = true
```

or an equivalent test-scope marker.

Test records must not count toward:

- real Fajr prayer history;
- real fasting history;
- streaks;
- Qada ledgers;
- Ramadan summaries;
- production analytics;
- future paid history surfaces.

### 8.3 Test alarm identifiers must be namespaced

All test scheduled events must use deterministic test identifiers.

Example:

```text
test.wakeSession.{sessionID}.primary
test.wakeSession.{sessionID}.check.1
test.wakeSession.{sessionID}.check.2
```

Test identifiers must not collide with production identifiers.

### 8.4 Clear-all safety actions are required

The Wake Session Lab and Home simulation overlay must include or route to:

```text
Cancel All Test Alarms
Clear Test Wake Sessions
Clear Test MorningLogs
Reset Test Time
Exit Test Mode
```

`Cancel All Test Alarms` must be visually prominent.

### 8.5 Exit Test Mode behavior

When the user exits test mode, Subh must:

1. cancel all mapped real AlarmKit test alarms;
2. cancel all pending fake/notification test alarms;
3. clear active simulation context;
4. restore Home to the real resolved morning;
5. preserve real user settings and real logs;
6. keep test logs only in debug/internal inspection if retention is useful;
7. never copy test confirmations into real worship history.

### 8.6 Never mutate real settings from a test scenario

Test scenarios must not permanently change:

- real location;
- real prayer calculation method;
- real Hijri adjustment;
- real default wake settings;
- real future plans;
- real paid entitlement;
- real production MorningLogs.

### 8.7 Do not rely on changing the device clock

Testing must not require manually changing iPhone system time.

Preferred approach:

```text
Fake app time for app logic.
Use mapped near-future real times only for actual AlarmKit/device QA.
```

---

## 9. Core testing architecture

### 9.1 Injectable clock

Subh must support an injectable time source.

Conceptual model:

```swift
protocol SubhClock {
    var now: Date { get }
    var timeZone: TimeZone { get }
}
```

Production implementation:

```text
RealSubhClock → current device/app time
```

Test implementation:

```text
TestSubhClock → controlled simulated now
```

Required behavior:

- all resolver, Wake Session, Hero state, and MorningLog calculations must be able to consume the injected clock;
- SwiftUI views should not directly call `Date()` for domain decisions;
- scheduling adapters may use real time only when creating real platform alarms, and only through explicit mapped playback or production scheduling paths.

### 9.2 Simulation context

Subh must support an app-wide active simulation context.

Conceptual model:

```swift
struct ActiveSimulationContext {
    let simulationID: String
    let isTest: Bool
    let scenarioKind: SimulationScenarioKind
    let mode: SimulationRunMode
    let simulatedDate: LocalDate
    let simulatedNow: Date
    let simulatedTimeZone: TimeZone
    let simulatedLocation: SimulationLocation
    let prayerWindowSource: PrayerWindowSource
    let simulatedPrayerWindow: SimulatedPrayerWindow
    let simulatedWakeSession: SimulatedWakeSession?
    let alarmMapping: AlarmKitMappingPlan?
    let clockMode: SimulationClockMode
    let createdAtRealDate: Date
}
```

Required semantics:

- when active, Home and relevant surfaces consume the simulated resolved morning snapshot;
- when inactive, Home and relevant surfaces consume the real resolved morning snapshot;
- the context must be app-wide and observable by Home, Wake Session, scheduler/test services, and the MorningLog inspector;
- it must not become a second resolver or second product engine.

### 9.3 Simulation run modes

```swift
enum SimulationRunMode {
    case stateExplorer
    case homeSimulation
    case realAlarmKitMappedPlayback
    case fakeSchedulerPlayback
    case dryRun
}
```

| Mode | Meaning | Real alarms? | Primary use |
| --- | --- | ---: | --- |
| `stateExplorer` | Instantly inspect any simulated date/time/state | No | Design/UX review |
| `homeSimulation` | Home consumes simulated state and supports real UI interactions | No by default | End-to-end UX flow |
| `realAlarmKitMappedPlayback` | Simulated events are mapped to real near-future AlarmKit alarms | Yes | Real device QA |
| `fakeSchedulerPlayback` | Scheduler records schedule/cancel calls without platform alarms | No | Integration testing |
| `dryRun` | Builds a plan but schedules nothing | No | Safe debugging |

### 9.4 Simulation clock modes

```swift
enum SimulationClockMode {
    case frozen
    case runningRealTime
    case jumpOnly
    case mappedPlayback
}
```

| Clock mode | Meaning | Use |
| --- | --- | --- |
| `frozen` | Simulated time stays fixed until changed | Screenshots, layout review |
| `runningRealTime` | Simulated time advances at normal real-time speed | Watching natural state transitions |
| `jumpOnly` | User jumps between named states | Fast state coverage |
| `mappedPlayback` | Simulated event timeline is mapped to real alarm fire dates | AlarmKit playback |

---

## 10. State Explorer

### 10.1 Purpose

State Explorer lets Omar inspect the app from any supported simulated date/time without scheduling real alarms.

Plain-language goal:

```text
Show me exactly what Subh would look like if it were this date and this time.
```

### 10.2 Required controls

State Explorer must support:

| Control | Examples |
| --- | --- |
| Date | today, tomorrow, pick date, Ramadan date, White Day, Eid, Monday/Thursday, future date |
| Time | manual time picker, named state jump, before/after boundary shortcut |
| Location | current app location, manual city, test preset if implemented |
| Mode | Suhoor, Fajr, Quiet |
| Prayer window source | real calculation for selected date/location, optional custom window |
| Clock mode | frozen, running, jump-only |
| Wake-session state | not fired, primary fired, wake checks pending, confirmed, quieted, expired |
| Outcome toggles | Suhoor confirmed, Fajr awake confirmed, Fajr prayed, fasting intent confirmed |
| Activation action | Activate on Home |

### 10.3 Real calculation default

Default State Explorer behavior should use real prayer calculations for the selected date/location.

Rationale:

- Omar wants to inspect any date/time in the year;
- seasonal Fajr window changes matter;
- Ramadan/Eid/White Day context matters;
- real date/location behavior is more valuable than arbitrary custom windows for product review.

Optional advanced mode may allow custom artificial windows for edge-case testing, but real calculations are the default.

### 10.4 Named jump points

State Explorer must provide named jump points so Omar does not need to manually calculate times.

Fajr jump points:

```text
Before Fajr begins
At Fajr begins
Before primary wake
At primary wake
Primary alarm fired
Wake check 1 pending
Wake check 2 pending
Wake check 3 pending
Wake check 4 pending
Wake check 5 pending
Awake confirmed
Prayer CTA available
Prayer confirmed
5 min before Fajr ends
After Fajr ends
```

Suhoor jump points:

```text
Before final third
At final third begins
Suhoor window open
Before primary Suhoor wake
At primary Suhoor wake
Primary Suhoor alarm fired
Wake check 1 pending
Wake check 2 pending
Wake check 3 pending
Wake check 4 pending
Wake check 5 pending
Suhoor awake confirmed
Fasting intent confirmed
Fajr begins after Suhoor
Fajr prayer CTA available
Fajr prayer confirmed
```

Quiet jump points:

```text
Fajr active
Wake checks active
User taps Quiet
Quiet confirmation sheet shown
Quiet confirmed
quietMorning logged
```

### 10.5 Acceptance

- Omar can choose a simulated date/time and immediately see Home change.
- Omar can inspect any state without waiting for real time to pass.
- No real AlarmKit alarm is scheduled by State Explorer unless he explicitly starts mapped playback.
- Test records remain isolated.

---

## 11. Home Simulation Mode

### 11.1 Purpose

Home Simulation Mode makes the actual Home screen behave as if the selected simulation is the current real morning.

The goal is to test:

- actual Home Hero layout;
- Hero Action Slot placement;
- CTA text and hierarchy;
- slider behavior;
- Suhoor/Fajr/Quiet selector behavior;
- prayer/fasting confirmation flow;
- Quiet confirmation sheet;
- wake-check pending states;
- visual spacing and whether anything jumps.

### 11.2 Activation

When the user taps `Activate on Home`, Subh should:

1. save an `ActiveSimulationContext`;
2. mark `isTest = true`;
3. route Home to the simulated resolved morning graph;
4. navigate to Home if possible;
5. display `TEST MODE ACTIVE`;
6. expose simulation controls on Home;
7. keep real user state untouched.

### 11.3 Home overlay / simulation dock

When active, Home must show a visible internal overlay or dock.

Required content:

```text
TEST MODE ACTIVE
Scenario: {scenario name}
Simulating: {Gregorian date} · {simulated time}
Location: {simulated location}
Mode: State Explorer / Real AlarmKit Mapped Playback
```

Required actions:

```text
Change Time
Jump State
Run Real AlarmKit Playback
Cancel Test Alarms
Exit Test Mode
```

For mapped playback, also show:

```text
Next real test alarm: {countdown}
Simulated event: {primary/wake check/etc.}
Real fire time: {time}
```

### 11.4 Home data source rule

When simulation is active:

```text
Home uses simulated resolved morning snapshot.
```

When simulation is inactive:

```text
Home uses real resolved morning snapshot.
```

The simulation must feed the same Hero snapshot path used by production.

Forbidden:

```text
Hardcoded fake Home screen
Separate fake Hero component
Direct SwiftUI-only simulation logic
```

### 11.5 Relative date labels

The simulated resolved snapshot may produce labels such as `Today`, `Tomorrow`, or a weekday as if the simulated clock were real.

To prevent confusion, the simulation overlay must always show the exact simulated Gregorian date/time. If Hijri context is available, the overlay may also show the simulated Hijri date.

### 11.6 Required Home states

Home Simulation Mode must support at least:

- normal Fajr planning;
- Fajr has begun before primary alarm;
- primary alarm fired;
- wake checks pending;
- awake for Fajr confirmed;
- `I prayed Fajr` available;
- Fajr prayer confirmed;
- Suhoor window open;
- primary Suhoor alarm fired;
- Suhoor wake checks pending;
- awake for Suhoor confirmed;
- fasting intent confirmed;
- Suhoor confirmed → Fajr begins → `I prayed Fajr`;
- Suhoor unconfirmed → Fajr begins → `I’m awake for Fajr` → `I prayed Fajr`;
- Quiet active;
- Quiet during pending wake checks confirmation sheet;
- quietMorning logged;
- permission failure state;
- expired unconfirmed state.

---

## 12. Real AlarmKit Mapped Playback

### 12.1 Purpose

Real AlarmKit Mapped Playback lets Omar test actual AlarmKit behavior while viewing a simulated Subh morning.

Plain-language goal:

```text
Use a simulated date/time for the app experience, but schedule real AlarmKit alarms on my phone now.
```

### 12.2 What can and cannot be mapped

Subh cannot make iOS believe the device date/time is the simulated date/time.

Subh can map simulated alarm events onto real near-future AlarmKit alarms.

Example:

```text
Simulated date: Ramadan 12, 2026
Simulated primary wake: 4:30 AM
Simulated wake check 1: 4:35 AM
Simulated wake check 2: 4:40 AM

Real now: 2:00 PM
Mapped primary wake: 2:02 PM
Mapped wake check 1: 2:07 PM
Mapped wake check 2: 2:12 PM
```

The Home overlay must show both simulated and real mapped times.

### 12.3 Default mapping strategy

Default strategy:

```text
Pin selected simulated anchor event to real now + start delay.
Preserve all later event deltas exactly.
```

Recommended default start delay:

```text
90 seconds
```

Allowed start-delay range:

```text
60–120 seconds
```

Implementation may choose the nearest practical delay based on platform constraints.

### 12.4 Mapping formula

Let:

```text
S_anchor = selected simulated anchor event time
R_anchor = real now + selected start delay
S_event = simulated event time
R_event = mapped real fire time
```

Then:

```text
R_event = R_anchor + (S_event - S_anchor)
```

For the default case where the primary alarm is the anchor:

```text
R_primary = real now + start delay
R_wakeCheck1 = R_primary + 5 min
R_wakeCheck2 = R_primary + 10 min
R_wakeCheck3 = R_primary + 15 min
R_wakeCheck4 = R_primary + 20 min
R_wakeCheck5 = R_primary + 25 min
```

### 12.5 Wake-check interval rule

Mapped playback must preserve the production wake-check interval:

```text
5 minutes
```

Forbidden:

```text
1-minute wake checks
2-minute wake checks
compressed wake-check spacing
```

Allowed:

```text
instant state jumps in State Explorer
mapping the primary alarm to real now + short delay
preserving wake-check deltas after the mapped primary alarm
```

### 12.6 Sequence length selector

The builder must let Omar choose how many real mapped wake events to schedule.

Options:

```text
Primary only
Primary + 1 wake check
Primary + 2 wake checks
Primary + 3 wake checks
Primary + 4 wake checks
Primary + 5 wake checks
```

Default:

```text
Primary + 5 wake checks
```

If the simulated mode-specific cutoff allows fewer wake checks than selected, schedule only the eligible wake checks and show an explanation.

Example:

```text
Requested: Primary + 5 wake checks
Eligible before cutoff: Primary + 3 wake checks
Scheduled: Primary + 3 wake checks
Reason: Later wake checks would be after the Suhoor/Fajr cutoff.
```

### 12.7 Mode-specific cutoff still applies

Fajr mapped playback:

```text
No wake check later than 5 minutes before Fajr ends.
```

Suhoor mapped playback:

```text
No wake check later than 5 minutes before Fajr begins.
```

The cutoff is evaluated in the simulated timeline before mapping to real alarm times.

### 12.8 Required confirmation before scheduling

Before starting Real AlarmKit Mapped Playback, show a confirmation sheet:

```text
Schedule real test alarms?

Subh will schedule real AlarmKit alarms on this device using your selected alarm sound.
These are test alarms mapped from the simulated morning.
Wake checks remain 5 minutes apart.

[Cancel]
[Schedule Test Alarms]
```

The confirmation must show:

- selected simulated date;
- selected scenario;
- sequence length;
- mapped real alarm fire times;
- sound role/asset if available;
- `Cancel All Test Alarms` availability.

### 12.9 Real AlarmKit playback behavior

When a mapped primary alarm fires:

- iOS shows the real AlarmKit alarm;
- Stop stops only the current alarm;
- Open Subh opens the simulated Home state where supported;
- the Wake Session remains unconfirmed until the user taps `I’m awake` inside Subh;
- pending mapped wake checks remain scheduled unless cancelled by confirmation, Quiet, or Exit Test Mode.

When the user taps `I’m awake for Fajr` or `I’m awake for Suhoor`:

- mark the test Wake Session confirmed;
- cancel remaining mapped test alarms;
- update Home simulated state;
- write test-only MorningLog records.

When the user exits test mode:

- cancel all mapped AlarmKit test alarms;
- clear active simulation context;
- restore real Home state.

---

## 13. Simulation Builder

### 13.1 Location

Preferred internal location:

```text
Settings → Developer → Wake Session Lab → Simulation Builder
```

The builder may also be accessible from the Home simulation dock when test mode is active.

### 13.2 Builder sections

Recommended sections:

1. Simulation Type.
2. Date and Location.
3. Time / State.
4. Mode and Scenario.
5. Prayer Window Source.
6. Wake Session State.
7. Real AlarmKit Mapping.
8. Activate / Schedule.
9. Safety.

### 13.3 Simulation Type

Options:

```text
State Explorer
Home Simulation
Real AlarmKit Mapped Playback
Fake Scheduler Playback
Dry Run
```

### 13.4 Date and Location

Controls:

```text
Date picker
Quick date presets
Location picker
Current app location
Manual city
```

Quick date presets may include:

```text
Today
Tomorrow
Ordinary day
Ramadan day
Eid day
White Day
Monday
Thursday
Summer long-Fajr example
Winter short-Fajr example
```

### 13.5 Time / State

Controls:

```text
Manual simulated time
Frozen/running/jump clock
Named jump points
```

### 13.6 Mode and scenario

Options:

```text
Fajr
Suhoor
Quiet
Permission failure
Slider reschedule
Alarm stop vs awake
Suhoor not confirmed → Fajr begins
```

### 13.7 Prayer window source

Options:

```text
Use real prayer calculation for selected date/location
Use custom artificial window
```

Default:

```text
Use real prayer calculation for selected date/location
```

### 13.8 Real AlarmKit Mapping

Controls:

```text
Enable Real AlarmKit Mapped Playback
Anchor event: primary alarm / wake check 1 / wake check 2 / Fajr begins / custom supported event
Real start delay: 60–120 sec
Sequence length: primary only through primary + 5 wake checks
Use selected alarm sound: yes
```

Wake-check spacing is not configurable in this mode. It remains five minutes.

### 13.9 Activation actions

```text
Preview State
Activate on Home
Schedule Real Mapped Alarms
Cancel All Test Alarms
Exit Test Mode
```

---

## 14. Scenario definitions

### 14.1 Scenario A — Fajr State Explorer

Purpose:

Inspect Fajr states instantly without scheduling real alarms.

Required states:

```text
Before Fajr begins
At Fajr begins
Before primary wake
Primary alarm fired
Wake check 1 pending
Wake check 2 pending
Wake check 3 pending
Wake check 4 pending
Wake check 5 pending
Awake confirmed
Prayer CTA available
Prayer confirmed
After Fajr ends
```

Pass criteria:

- Home changes immediately when state is selected;
- Hero Action Slot shows the correct CTA/state;
- no real alarms are scheduled;
- logs remain test-only if interactions occur.

### 14.2 Scenario B — Suhoor State Explorer

Purpose:

Inspect Suhoor and fasting-intent states instantly.

Required states:

```text
Before final third
At final third begins
Suhoor window open
Before primary Suhoor wake
Primary Suhoor alarm fired
Wake check 1 pending
Wake check 2 pending
Wake check 3 pending
Wake check 4 pending
Wake check 5 pending
Suhoor awake confirmed
Fasting intent confirmed
Fajr begins after Suhoor
Fajr prayer CTA available
Fajr prayer confirmed
```

Pass criteria:

- `I’m awake for Suhoor` is separate from `I prayed Fajr`;
- fasting intent is separate from fast completion;
- no real alarms are scheduled unless mapped playback is explicitly enabled.

### 14.3 Scenario C — Suhoor Not Confirmed → Fajr Begins

Purpose:

Test the transition when the user did not confirm Suhoor before Fajr begins.

Expected flow:

1. User does not confirm `I’m awake for Suhoor`.
2. Suhoor wake expires unconfirmed.
3. Simulated Fajr begins.
4. Home shows `I’m awake for Fajr` first.
5. After the user confirms awake for Fajr, Home may show `I prayed Fajr`.

Pass criteria:

- app does not treat unconfirmed Suhoor as confirmed wake;
- app does not mark Fajr missed;
- app provides Fajr path after missed/unconfirmed Suhoor.

### 14.4 Scenario D — Quiet During Active Wake Checks

Purpose:

Test that Quiet requires intentional confirmation during an active session.

Setup:

```text
Wake Session active
Primary alarm already fired
Wake checks pending
```

Expected flow:

1. User selects Quiet.
2. App shows confirmation sheet:

```text
Stop wake checks for this morning?
Subh will cancel the remaining alarms and mark this morning as quiet.

[Keep wake checks]
[Stop for this morning]
```

3. If user taps `Keep wake checks`, no cancellation occurs.
4. If user taps `Stop for this morning`, remaining alarms cancel.
5. MorningLog records `quietMorning`.
6. App does not record `fajrMissed`.

Pass criteria:

- Quiet is intentional;
- Quiet does not equal missed prayer;
- Quiet does not erase underlying user meaning beyond the session rules.

### 14.5 Scenario E — Slider Reschedule Test

Purpose:

Test schedule cleanup after wake-time adjustment.

Setup:

```text
Fajr or Suhoor Wake Session scheduled
Primary alarm pending
Wake checks pending
```

Expected flow:

1. User drags wake slider later or earlier.
2. Hero previews the new wake time while dragging.
3. On release, app commits `adjustWakeTime(...)`.
4. Old primary alarm ID cancels.
5. Old wake-check IDs cancel.
6. New primary alarm schedules.
7. New wake checks schedule within cutoff.
8. No duplicate identifiers remain.

Pass criteria:

- no duplicate alarms;
- stale alarms removed;
- Hero reconciles to canonical resolved snapshot;
- delivery schedule matches the latest resolved Wake Session.

### 14.6 Scenario F — Alarm Stop vs Awake Confirmation

Purpose:

Test the most important Wake Session rule.

Expected flow:

1. Primary alarm fires.
2. User taps system Stop/dismiss.
3. Wake Session remains unconfirmed.
4. Wake checks remain pending.
5. Next wake check fires if it was scheduled.
6. User opens Subh and taps `I’m awake for Fajr` or `I’m awake for Suhoor`.
7. Only then is the Wake Session confirmed.

Pass criteria:

```text
Alarm stopped ≠ awake confirmed
```

### 14.7 Scenario G — Permission Failure Test

Purpose:

Test that permission failure is not Quiet.

Expected flow:

1. Simulate AlarmKit denied.
2. Simulate Notification permission denied or fallback unavailable.
3. Fajr/Suhoor intent remains active.
4. Hero or settings shows reliability warning.
5. App does not display Quiet.
6. MorningLog/delivery diagnostics record permission blocked.

Pass criteria:

- blocked delivery does not mutate intent;
- blocked delivery does not become Quiet;
- user receives repair guidance.

### 14.8 Scenario H — Real AlarmKit Mapped Playback

Purpose:

Test actual physical-device AlarmKit delivery while Home uses simulated state.

Default mapped playback:

```text
Real primary alarm: real now + 90 sec
Real wake check 1: primary + 5 min
Real wake check 2: primary + 10 min
Real wake check 3: primary + 15 min
Real wake check 4: primary + 20 min
Real wake check 5: primary + 25 min
```

Sequence selector:

```text
Primary only
Primary + 1 wake check
Primary + 2 wake checks
Primary + 3 wake checks
Primary + 4 wake checks
Primary + 5 wake checks
```

Default:

```text
Primary + 5 wake checks
```

Required variants:

1. App foreground.
2. App background.
3. Phone locked.
4. App terminated.
5. Silent mode on.
6. Focus mode on.
7. Stop primary and verify wake check still fires.
8. Confirm awake and verify remaining checks do not fire.

Pass criteria:

- AlarmKit presentation appears correctly;
- sound behavior is acceptable;
- Open Subh path works where supported;
- Stop does not confirm awake;
- wake checks are cancelled after confirmation;
- wake checks remain five minutes apart.

### 14.9 Scenario I — MorningLog Inspector Test

Purpose:

Verify the event log is factual and non-judgmental.

Expected test log examples:

```text
wakeSessionCreated
primaryAlarmScheduled
wakeCheckScheduled
primaryAlarmFired
alarmStopped
wakeCheckFired
confirmedAwakeForFajr
wakeChecksCancelled
fajrPrayerConfirmed
```

For Suhoor:

```text
confirmedAwakeForSuhoor
fastingIntentConfirmed
```

Forbidden automatic records:

```text
fajrMissed
fastMissed
fastCompletionConfirmed
```

Pass criteria:

- wake, prayer, fasting intent, and fast completion remain separate;
- test logs are marked test-only;
- logs can be cleared.

### 14.10 Scenario J — Cross-Surface Consistency Test

Purpose:

Verify that Home, near-term forecast, Weekly Fajrcast, Day Detail, and delivery agree.

Expected flow:

1. Start a simulated Fajr or Suhoor test session.
2. Change mode from Home.
3. Open near-term forecast.
4. Open Day Detail.
5. Confirm visible mode/time alignment.
6. Trigger schedule refresh.
7. Confirm pending alarm identifiers match resolved state.

Pass criteria:

- surfaces consume the same resolved morning graph;
- no surface invents its own Fajr/Suhoor/Quiet state;
- visible forecast rows do not become scheduled alarms unless in active scheduled horizon.

---

## 15. Scheduler modes

Wake Session Lab should support these scheduler modes.

| Mode | Meaning | Use case |
| --- | --- | --- |
| Fake Scheduler | Does not schedule platform alarms; records expected schedule/cancel calls | Fast logic testing |
| Real Notifications | Uses local notifications if available | Fallback/degraded delivery testing |
| Real AlarmKit Mapped Playback | Uses AlarmKit on physical device with mapped real times | Final device QA |
| Dry Run | Builds plan but schedules nothing | Safe review/debug |

The default lab scheduler mode should be **Fake Scheduler** for non-alarm tests.

Real AlarmKit Mapped Playback must require explicit confirmation.

---

## 16. MorningLog inspector

The Wake Session Lab must include a readable MorningLog inspector.

Recommended display:

```text
WakeSessionID: test-fajr-2026-05-26-1400
Scenario: Fajr Mapped Playback
Mode: Fajr
Status: wakeChecksPending
Simulated date/time: Ramadan 12, 2026 · 4:30 AM
Mapped real primary alarm: 2:02 PM
Mapped real wake checks: 2:07, 2:12, 2:17, 2:22, 2:27
Confirmed awake: none
Fajr prayer: unconfirmed
Fasting intent: not applicable
Events:
- wakeSessionCreated
- primaryAlarmScheduled
- wakeCheckScheduled x5
- primaryAlarmFired
- alarmStopped
```

Actions:

```text
Copy Test Report
Clear Test Logs
Export Debug Summary
```

Export must remain local/user-initiated.

---

## 17. Pending alarm inspector

The lab must show pending test alarms.

Fields:

```text
identifier
role: primary | wakeCheck
mode: Fajr | Suhoor
simulatedFireDate
mappedRealFireDate
channel: fake | AlarmKit | notification
status: pending | fired | cancelled | failed
isTest
```

Required actions:

```text
Refresh Pending Test Alarms
Cancel Selected Test Alarm
Cancel All Test Alarms
```

The inspector must clearly distinguish production pending alarms from test pending alarms.

---

## 18. Permission/failure simulator

For fake/integration mode, the lab may simulate:

```text
AlarmKit authorized
AlarmKit denied
AlarmKit unavailable
Notification authorized
Notification denied
Notification fallback degraded
Schedule failure
Missing pending alarm
Mismatched fire date
Duplicate identifier
Sound asset missing
```

These simulations must not change real iOS permission settings.

---

## 19. User-facing personal QA checklist

This section is written for Omar as a tester.

### 19.1 State Explorer / Home Simulation test

1. Open Developer → Wake Session Lab.
2. Open State Explorer or Simulation Builder.
3. Choose a simulated date, location, time, and mode.
4. Tap `Activate on Home`.
5. Confirm Home shows `TEST MODE ACTIVE`.
6. Confirm Home Hero uses the simulated state.
7. Jump through Fajr/Suhoor/Quiet states.
8. Confirm the Hero Action Slot, CTA placement, and layout feel correct.
9. Tap simulated CTAs and confirm state changes.
10. Exit Test Mode and confirm real Home state returns.

### 19.2 Fajr mapped playback test

1. Open Developer → Wake Session Lab.
2. Choose Real AlarmKit Mapped Playback.
3. Choose a simulated Fajr date/time.
4. Choose sequence length, default `Primary + 5 wake checks`.
5. Confirm mapped real fire times.
6. Schedule test alarms.
7. Lock phone.
8. Wait for primary alarm.
9. Stop the alarm.
10. Confirm Wake Session is not marked awake.
11. Wait five minutes for wake check 1.
12. Open Subh.
13. Tap `I’m awake for Fajr`.
14. Confirm remaining wake checks cancel.
15. Tap `I prayed Fajr`.
16. Open MorningLog inspector.
17. Confirm awake and prayer are separate test records.

### 19.3 Suhoor mapped playback test

1. Choose Real AlarmKit Mapped Playback.
2. Choose a simulated Suhoor/Ramadan date/time.
3. Choose sequence length.
4. Schedule mapped alarms.
5. Let primary Suhoor alarm fire.
6. Tap `I’m awake for Suhoor`.
7. Confirm remaining mapped wake checks cancel.
8. Confirm fasting intent is recorded.
9. Confirm Fajr prayer is not recorded.
10. Jump or wait to simulated Fajr begins.
11. Confirm `I prayed Fajr` appears.

### 19.4 Quiet active-session test

1. Start a Fajr or Suhoor simulation with wake checks pending.
2. Select Quiet.
3. Confirm sheet appears.
4. Tap `Keep wake checks` once.
5. Verify wake checks remain pending.
6. Select Quiet again.
7. Tap `Stop for this morning`.
8. Confirm `quietMorning` is logged.
9. Confirm no missed prayer is auto-logged.

---

## 20. Automated test requirements

### 20.1 Unit tests

Codex should add tests for:

- State Explorer date/time selection;
- simulated clock injection;
- simulated resolved morning selection;
- Fajr wake-check schedule math with five-minute intervals;
- Suhoor wake-check schedule math with five-minute intervals;
- cutoff behavior;
- no wake check after cutoff;
- primary wake too close to cutoff;
- alarm stop does not confirm awake;
- awake confirmation cancels checks;
- Suhoor confirmation sets fasting intent only;
- `I prayed Fajr` separate from awake confirmation;
- Quiet active-session cancellation;
- permission failure not becoming Quiet;
- test records marked `isTest`;
- clear test records action.

### 20.2 Integration tests

Codex should add tests for:

- Wake Session creation from simulated resolved morning;
- Home consuming active simulation context;
- exiting simulation restoring real resolved morning;
- fake scheduler schedule/cancel calls;
- Real AlarmKit mapping plan generation;
- sequence selector: primary only through primary + 5 wake checks;
- mapped playback preserving five-minute wake-check deltas;
- stale test alarm cleanup;
- Hero state from simulated clock;
- MorningLog record sequence;
- rescheduling after slider change;
- cross-surface consistency from one resolved graph.

### 20.3 UI tests / previews

Codex should add preview fixtures for:

- normal planning state;
- active Fajr window before alarm;
- primary fired and unconfirmed;
- wake checks pending;
- awake confirmed;
- Fajr prayer CTA;
- Suhoor confirmed;
- Suhoor-to-Fajr handoff;
- Quiet active session;
- expired unconfirmed;
- permission blocked;
- test mode banner;
- simulation dock;
- mapped playback countdown.

---

## 21. Physical-device QA matrix

Physical device QA is required for actual delivery confidence.

| Test | Required? | Notes |
| --- | ---: | --- |
| AlarmKit authorization prompt | Yes | Must be tested on real device. |
| Primary alarm audible | Yes | Test normal volume/sound behavior. |
| Wake check after primary stop | Yes | Core Wake Session behavior. |
| Five-minute wake-check spacing | Yes | Must be preserved in mapped playback. |
| Confirm awake cancels checks | Yes | Must verify no later ringing. |
| Lock Screen presentation | Yes | Title, Stop, Open Subh. |
| App backgrounded | Yes | Alarm should still fire. |
| App terminated | Yes | Alarm should still fire if platform supports. |
| Silent mode | Yes | Confirm actual behavior. |
| Focus mode | Yes | Confirm actual behavior. |
| Reboot | Optional pre-MVP, recommended before launch | Harder but valuable. |
| Timezone change | Recommended | Must not corrupt intent. |
| Permission denial | Yes | Must show reliability warning, not Quiet. |
| Sound asset missing fallback | Developer QA | Should not crash/fail silently. |

---

## 22. Production guardrails

Before release, CI or a manual release checklist must verify:

- Wake Session Lab is not visible in production;
- State Explorer is not visible in production;
- Home Simulation controls are not visible in production;
- Real AlarmKit Mapped Playback controls are not visible in production;
- fake scenario buttons are not visible in production;
- fake clock is not active in production;
- test records cannot appear in real history;
- test alarms are not scheduled by default;
- production app does not show `TEST MODE ACTIVE`;
- production code does not default to fake scheduler;
- production code does not use fake prayer windows;
- production wake checks remain five minutes apart;
- production can still cancel stale test alarms if any were accidentally left from internal builds.

---

## 23. Acceptance criteria

### 23.1 Personal testing acceptance

- [ ] Omar can set a simulated date and time.
- [ ] Omar can choose a simulated location.
- [ ] Omar can activate the simulated state on Home.
- [ ] Omar can inspect Fajr, Suhoor, Quiet, wake-check, confirmation, prayer, and permission states without waiting for real mornings.
- [ ] Omar can jump between named states instantly.
- [ ] Omar can run real AlarmKit mapped playback on his iPhone.
- [ ] Omar can choose sequence length from primary only through primary + 5 wake checks.
- [ ] The default mapped sequence is primary + 5 wake checks.
- [ ] Real mapped wake checks are five minutes apart.
- [ ] Omar can see pending test alarms.
- [ ] Omar can clear all test alarms.
- [ ] Omar can inspect MorningLog records.
- [ ] Omar can exit test mode and restore real Home state.

### 23.2 Architecture acceptance

- [ ] Resolver and Hero can consume injected time in test mode.
- [ ] Home can consume an active simulation context.
- [ ] The simulation feeds the canonical resolved morning graph / snapshot path.
- [ ] Fake scheduler can be used without AlarmKit.
- [ ] Real AlarmKit can be used for mapped device tests.
- [ ] Test records are marked and isolated.
- [ ] Test scenarios do not mutate real settings.
- [ ] Production builds do not expose the lab.

### 23.3 Product acceptance

- [ ] Testing preserves Subh as one Fajr-centered morning system.
- [ ] Testing does not create a second wake engine.
- [ ] Testing does not pollute real worship logs.
- [ ] Testing does not create guilt/judgment records.
- [ ] Testing supports the complete MVP Wake Session loop.

---

## 24. Codex implementation prompt

Use this as the implementation prompt after this spec is accepted.

```text
Implement the v2 debug/internal Wake Session Testing, Home Simulation, and Real AlarmKit Mapped Playback harness for Subh according to `subh-wake-session-testing-and-simulation-harness-spec-v2.md`.

Use OpenSpec first.
Do not change production wake rules.
Do not expose the Wake Session Lab, State Explorer, Home Simulation controls, or Real AlarmKit Mapped Playback in App Store production builds.
Do not implement paid features, StoreKit, analytics, adaptive wake checks, household features, or cloud sync.

Important v2 rule:
- Do not use one-minute or two-minute wake-check intervals.
- State jumps may be instant.
- Real mapped alarm playback must preserve the production five-minute wake-check interval.
- The mapped playback builder must let the tester choose primary only, primary + 1, primary + 2, primary + 3, primary + 4, or primary + 5 wake checks.
- Default mapped playback sequence is primary + 5 wake checks.

Implement:
1. Injectable clock/time provider for resolver, Wake Session, Hero state, and MorningLog testing.
2. ActiveSimulationContext / TestScenarioContext app-wide store.
3. State Explorer for selecting simulated date, time, location, mode, and state.
4. Home Simulation Mode so Home consumes the simulated resolved morning snapshot.
5. Home simulation overlay/dock with TEST MODE ACTIVE, simulated date/time, jump controls, mapped alarm countdown, cancel test alarms, and Exit Test Mode.
6. Real AlarmKit Mapped Playback:
   - map selected simulated anchor event to real now + start delay;
   - preserve simulated event deltas after the anchor;
   - preserve five-minute wake-check spacing;
   - use deterministic test AlarmKit identifiers;
   - allow sequence length primary only through primary + 5;
   - default to primary + 5;
   - cancel all remaining mapped alarms when awake is confirmed, Quiet is confirmed, or test mode exits.
7. Test prayer-window/scenario provider using real prayer calculations by default for selected date/location, with optional custom artificial window support.
8. Fake scheduler adapter that records schedule/cancel/reconciliation calls without platform alarms.
9. Developer/internal Wake Session Lab screen as launchpad and inspector.
10. MorningLog inspector for test records.
11. Pending test alarm inspector showing simulated fire time and mapped real fire time.
12. Cancel All Test Alarms / Clear Test Logs / Exit Test Mode safety actions.
13. Production guardrails so test UI is unavailable in release builds.
14. Unit/integration/UI tests covering the scenarios in the spec.

Rules:
- Test sessions must be visibly marked.
- Test records must use `isTest = true` or equivalent.
- Test alarm identifiers must be namespaced.
- Stopping an alarm must not confirm awake.
- Confirming awake must cancel remaining wake checks.
- Suhoor confirmation must set fasting intent but not Fajr prayer or fast completion.
- Quiet must log quietMorning, not missed prayer.
- Permission failure must not become Quiet.
- Real AlarmKit mapped tests must be explicit, confirmable, and cancellable.

After implementation:
- Run OpenSpec validation.
- Run targeted tests.
- Provide files changed, tests added, tests run, manual device QA steps, and known limitations.
```

---

## 25. Open decisions

| Decision | Recommendation / current status |
| --- | --- |
| Should Wake Session Lab be available in internal TestFlight? | Yes, behind explicit internal flag. |
| Should test records be exportable? | Yes, local/manual export only. |
| Should real AlarmKit mapped tests preserve five-minute wake checks? | Yes. Locked in v2. |
| Should State Explorer allow instant jumps? | Yes. Locked in v2. |
| Should mapped playback default to full sequence? | Yes: primary + 5 wake checks. |
| Should mapped playback allow shorter sequence choices? | Yes: primary only through primary + 5. |
| Should production include safe diagnostics? | Yes, but not fake time/scenario controls. |
| Should the test harness ship before Wake Sessions? | It can ship alongside Wake Sessions; at minimum, fake scheduler and unit tests should exist before full implementation. |

---

## 26. Final rule

The testing harness exists to make Subh testable without weakening Subh’s product truth.

```text
Real product logic.
Simulated date/time and state.
Mapped real AlarmKit alarms when explicitly requested.
Five-minute wake checks preserved.
Clear test labels.
No production exposure.
No real-log pollution.
```
