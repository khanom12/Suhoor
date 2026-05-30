# Subh Wake Session Testing, Home Simulation, and Real AlarmKit Mapped Playback Spec

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-session-testing-and-simulation-harness-spec-v3.md` |
| Version | 3 |
| Spec status | Draft; proposed canonical testing/specification layer with simplified tester-first Wake Session Lab UX |
| Date | 2026-05-27 |
| Supersedes | `subh-wake-session-testing-and-simulation-harness-spec-v2.md`; `subh-wake-session-testing-and-simulation-harness-spec-v1.md` |
| Owning domain / surface | Developer/internal testing, personal device QA, Wake Session Lab UX, Home Simulation Mode, State Explorer, Real AlarmKit Mapped Playback, diagnostics, test-data safety |
| Related specs | `00-subh-spec-index-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-morning-hero-item-spec-v15.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-pricing-entitlement-spec-v3.md`, `subh-mvp-interaction-inventory-v4.md` |
| Implementation audit status | New v3 spec; not implemented |

---

## 1. Purpose

This spec defines a comprehensive internal testing layer that lets Omar and internal testers personally verify Subh's Wake Sessions, Wake Checks, Home Hero states, Fajr/Suhoor/Quiet interactions, MorningLogs, and real AlarmKit behavior without waiting for real mornings.

Version 3 preserves the technical capability from v2, but changes the testing harness product design from a subsystem-heavy developer panel into a tester-friendly workflow.

The testing layer has three visible utilities:

1. **Preview Home UI** — choose a scenario or custom simulated date/time and inspect the real Home UI instantly.
2. **Run Real Alarm Test** — map a simulated wake session onto real near-future AlarmKit alarms while preserving five-minute wake-check spacing.
3. **Diagnostics** — inspect scheduled test alarms, test event logs, permission simulations, and reset tools only when needed.

Plain-language purpose:

```text
Let Omar choose what he wants to test, understand what will happen, open Home, and see the real UI behave as if that morning state is happening.
```

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

## 3. v3 usability doctrine

The Wake Session Lab must be task-oriented, not subsystem-oriented.

The lab should not present a long list of technical sections such as:

```text
Test Mode Status
State Explorer
Real AlarmKit Mapped Playback
Scenario Launcher
Time Controls
Wake Session Actions
Pending Test Alarms
MorningLog Inspector
Permission Failure Simulator
Cleanup Reset Tools
```

Those concepts may still exist internally, but the visible tester experience must be organized around what Omar wants to do:

```text
Preview the Home UI
Run a real alarm test
Troubleshoot with diagnostics
```

### 3.1 Lab mental model

```text
Wake Session Lab = launchpad
Home = testing stage
Diagnostics = troubleshooting drawer
```

### 3.2 UX simplification requirements

1. The main Wake Session Lab screen must expose only three top-level areas:
   - `Preview Home UI`
   - `Real Alarm Test`
   - `Diagnostics`
2. `Preview Home UI` must be the default first area.
3. Diagnostics must be collapsed or secondary by default.
4. Time controls should appear in the Home simulation dock while testing, not as a large standalone settings section.
5. Wake Session actions should appear contextually inside the simulated Home flow, not as an unexplained settings section.
6. No screen should expose more than 3–5 primary actions at once unless the screen is explicitly an advanced diagnostic inspector.
7. Each scenario card must explain:
   - what it tests;
   - whether real alarms will ring;
   - approximate duration;
   - what to expect;
   - the primary action.
8. Technical names may be used internally, but user-visible labels must be plain-language.
9. A tester should be able to run the default Fajr, Suhoor, and Quiet UI previews without understanding scheduler internals, fake clocks, pending identifiers, or MorningLog data structures.

### 3.3 Preferred visible labels

| Internal / technical label | Preferred visible label |
| --- | --- |
| `State Explorer` | `Preview Home UI` or `Custom Home Preview` |
| `Real AlarmKit Mapped Playback` | `Real Alarm Test` |
| `ActiveSimulationContext` | `Test Mode` / `Active Test` in UI only |
| `MorningLog Inspector` | `Test Event Log` |
| `Pending Test Alarms` | `Scheduled Test Alarms` |
| `Permission Failure Simulator` | `Permission Simulation` |
| `Wake Session Actions` | Contextual Home actions or `Test Actions` only where needed |
| `Cleanup Reset Tools` | `Reset Test Mode` / `Safety Tools` |
| `Activate Scenario` | `Preview on Home` |
| `Exit Simulation` | `Exit Test Mode` |

---

## 4. Core v3 decisions

### 4.1 Wake-check spacing

Wake-check spacing must not be compressed in Real AlarmKit Mapped Playback.

Production rule and mapped playback rule:

```text
Wake check interval = 5 minutes
Maximum wake checks after primary = 5
Maximum total attempts = primary + 5 wake checks
```

State jumps may be instant. Real mapped alarm playback preserves production wake-check spacing.

This means:

- Preview Home UI can instantly jump to `wake check 3 pending` without waiting.
- Real Alarm Test schedules wake checks five real minutes apart.
- No v3 scenario should use one-minute or two-minute wake-check spacing.

### 4.2 Two complementary test modes

| Utility | Purpose | Real alarms? | Wait required? |
| --- | --- | ---: | ---: |
| Preview Home UI | Instantly inspect any date/time/state on the real Home UI | No | No |
| Real Alarm Test | Test actual AlarmKit ringing, Lock Screen behavior, Stop/Open Subh, sound, and cancellation | Yes | Yes, with true 5-minute spacing |

### 4.3 Real alarm sequence selector

Real Alarm Test must let Omar choose:

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

---

## 5. Goals

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

## 6. Non-goals

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

## 7. Testing layers

Subh testing should use five layers.

| Layer | Name | Purpose | Uses real AlarmKit? | Runs on Omar’s iPhone? | Ships publicly? |
| --- | --- | --- | ---: | ---: | ---: |
| 1 | Unit tests | Prove rules and calculations | No | No | No |
| 2 | Fake scheduler integration tests | Prove scheduling/cancellation without platform delivery | No | Optional | No |
| 3 | UI/snapshot state tests | Prove Hero and surface states | No | Optional | No |
| 4 | Preview Home UI / Home Simulation | Personal/internal simulated Home testing | No by default | Yes | No public access |
| 5 | Real Alarm Test | Prove real device alarm behavior with simulated state | Yes | Yes | No public access |

The Wake Session Lab is the internal launchpad and inspector. Home Simulation Mode is the primary UX testing surface.

---

## 8. Build and access model

### 8.1 Build modes

| Build mode | Wake Session Lab / Simulation availability | Intended user |
| --- | --- | --- |
| Debug/local developer build | Fully available | Omar / developer |
| Internal TestFlight build | Available behind internal flag | Omar / trusted testers |
| App Store production build | Not available | Public users |

### 8.2 Release-build rule

Production App Store builds must not expose:

- Wake Session Lab;
- Preview Home UI controls;
- Home Simulation Mode controls;
- fake time controls;
- simulated date/time controls;
- artificial prayer-window controls;
- real test alarm controls;
- fake scheduler controls;
- fake log inspector editing;
- simulate alarm fired/stopped buttons;
- test prayer/fast logging that can pollute real logs.

### 8.3 Suggested implementation guard

The visible test UI should be compiled or feature-gated behind development/internal controls such as:

```text
DEBUG build flag
INTERNAL_TESTING build configuration
TestFlight internal feature flag
Developer Mode local override
```

Production builds may keep clean architecture seams such as protocols and injectable dependencies, but must not expose unsafe controls.

---

## 9. Wake Session Lab information architecture

### 9.1 Top-level structure

The visible Wake Session Lab must use this top-level structure:

```text
Wake Session Lab
Test Subh mornings without waiting for real Fajr.

Status: No test running

[ Preview Home UI | Real Alarm Test | Diagnostics ]
```

If a test is active:

```text
Wake Session Lab
TEST MODE ACTIVE

{Scenario name} · {Location} · {Date} · {Simulated time}

[Return to Home]
[Exit Test Mode]
[Cancel Test Alarms]

[ Preview Home UI | Real Alarm Test | Diagnostics ]
```

### 9.2 Top-level areas

| Area | Purpose | Default visibility |
| --- | --- | --- |
| Preview Home UI | Start guided UI previews and custom date/time simulations | First/default |
| Real Alarm Test | Schedule real AlarmKit test alarms with mapped simulated state | Second |
| Diagnostics | Inspect logs, scheduled test alarms, permission simulations, and reset tools | Third/collapsed-first |

### 9.3 Redundant v2 sections and new homes

| v2 section / control group | v3 location |
| --- | --- |
| Test Mode Status | Compact header |
| State Explorer | Preview Home UI → Custom Date & Time |
| Real AlarmKit Mapped Playback | Real Alarm Test |
| Scenario Launcher | Preview Home UI scenario cards |
| Time Controls | Home simulation dock |
| Wake Session Actions | Home simulation dock/contextual flow |
| Pending Test Alarms | Diagnostics → Scheduled Test Alarms |
| MorningLog Inspector | Diagnostics → Test Event Log |
| Permission Failure Simulator | Diagnostics → Permission Simulation |
| Cleanup Reset Tools | Diagnostics → Reset Test Mode / Safety Tools |

---

## 10. Scenario card standard

Every scenario card must be self-explanatory.

Required card fields:

```text
Title
Plain-language description
What this tests
Real alarms: Yes / No
Approximate duration
What to expect
Primary action
```

### 10.1 Preview card example

```text
Fajr Flow

Preview the Home Hero from Fajr beginning to prayer confirmation.

What this tests:
The awake confirmation, wake-check pending state, Hero Action Slot, and Fajr prayer confirmation.

Real alarms:
No. This is a Home preview.

Approximate time:
1–2 minutes.

What to expect:
Home will open with TEST MODE ACTIVE. Use Next State to move through the Fajr flow.

[Start Fajr Preview]
```

### 10.2 Real alarm card example

```text
Fajr Alarm Test

Map a simulated Fajr wake session onto real alarms starting soon.

What this tests:
Real AlarmKit ringing, Stop, Open Subh, and five-minute wake checks.

Real alarms:
Yes. Your iPhone will ring.

Approximate time:
Primary only: a few minutes.
Full sequence: about 25–30 minutes.

What to expect:
The primary alarm rings first. If you stop it without confirming awake, the next wake check rings five minutes later.

[Set Up Fajr Alarm Test]
```

---

## 11. Preview Home UI

### 11.1 Purpose

Preview Home UI is the default testing experience.

It lets Omar inspect the app from any supported simulated date/time without scheduling real alarms.

Plain-language goal:

```text
Show me exactly what Subh would look like if it were this date and this time.
```

### 11.2 Required preview cards

Preview Home UI must show these default cards:

1. `Fajr Flow`
2. `Suhoor Flow`
3. `Quiet During Wake Checks`
4. `Custom Date & Time`

No more than these four cards should be visible by default unless a later usability review approves additional cards.

### 11.3 Fajr Flow card

Purpose:

```text
Preview the Home Hero from Fajr beginning to prayer confirmation.
```

Required states available through Home dock:

```text
Before Fajr begins
Fajr has begun
Before primary alarm
Primary alarm fired
Wake checks pending
Awake confirmed
Prayer ready
Prayer confirmed
After Fajr ends
```

Primary action:

```text
Start Fajr Preview
```

### 11.4 Suhoor Flow card

Purpose:

```text
Preview Suhoor wake, fasting intention, and the handoff to Fajr prayer.
```

Required states available through Home dock:

```text
Before final third
Suhoor window open
Before primary Suhoor alarm
Primary Suhoor alarm fired
Wake checks pending
Suhoor confirmed
Fasting intent confirmed
Fajr has begun
Prayer ready
Prayer confirmed
```

Primary action:

```text
Start Suhoor Preview
```

### 11.5 Quiet During Wake Checks card

Purpose:

```text
Preview what happens when Quiet is selected while wake checks are active.
```

Required states:

```text
Wake checks active
Quiet tapped
Confirmation sheet shown
Keep wake checks
Stop for this morning
quietMorning logged
```

Primary action:

```text
Start Quiet Preview
```

### 11.6 Custom Date & Time card

Purpose:

```text
Choose any date, time, location, and state to preview on Home.
```

Primary action:

```text
Open Custom Preview
```

---

## 12. Custom Home Preview

### 12.1 Purpose

Custom Home Preview replaces the overwhelming v2 State Explorer form with a small task-based screen.

Title:

```text
Custom Home Preview
Choose a simulated morning and see it on Home.
```

### 12.2 Required fields

The default form should show only:

```text
Date
Location
Mode
State
```

Advanced controls may be hidden under:

```text
Advanced Options
```

### 12.3 Date controls

Required simple options:

```text
Today
Tomorrow
Pick date
Ramadan example
Eid example
White Day example
Monday example
Thursday example
```

Optional later additions:

```text
Summer long-Fajr example
Winter short-Fajr example
Random ordinary day
```

### 12.4 Location controls

Required:

```text
Current app location
Choose city
```

Optional later additions:

```text
Toronto preset
Makkah preset
Saved test locations
```

### 12.5 Mode controls

Required:

```text
Fajr
Suhoor
Quiet
```

### 12.6 State controls

The State picker should adapt to the selected mode.

#### Fajr states

```text
Before Fajr begins
Fajr has begun
Before primary alarm
Primary alarm fired
Wake checks pending
Awake confirmed
Prayer ready
Prayer confirmed
After Fajr ends
```

#### Suhoor states

```text
Before final third
Suhoor window open
Before primary alarm
Primary alarm fired
Wake checks pending
Suhoor confirmed
Fajr has begun
Prayer ready
Prayer confirmed
```

#### Quiet states

```text
Quiet planned
Quiet during wake checks
Quiet confirmed
```

### 12.7 Primary action

```text
Preview on Home
```

### 12.8 Advanced options

Advanced Options may include:

```text
Prayer window source
Clock mode
Outcome toggles
Permission simulation
Custom artificial window
```

Advanced Options must be collapsed by default.

---

## 13. Home Simulation Mode

### 13.1 Purpose

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

### 13.2 Activation

When the user taps `Preview on Home` or starts a guided preview, Subh should:

1. save an `ActiveSimulationContext`;
2. mark `isTest = true`;
3. route Home to the simulated resolved morning graph;
4. navigate to Home if possible;
5. display `TEST MODE ACTIVE`;
6. expose simulation controls on Home;
7. keep real user state untouched.

### 13.3 Home data source rule

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

### 13.4 Home simulation dock

When active, Home must show a visible internal dock.

Required content:

```text
TEST MODE ACTIVE
{Scenario name} · {simulated date} · {simulated time}
Expected: {what Omar should currently see}
```

Required actions:

```text
Previous State
Next State
Change State
Exit
```

Optional secondary actions:

```text
Change Time
Run Real Alarm Test
Cancel Test Alarms
```

For mapped playback, also show:

```text
Next real test alarm: {countdown}
Simulated event: {primary/wake check/etc.}
Real fire time: {time}
```

### 13.5 Home dock UX rules

1. The dock must not obscure the Hero in a way that prevents testing layout and interactions.
2. The dock should be compact and visually separate from production UI.
3. The dock should explain the expected current state in plain language.
4. `Exit` must always be visible.
5. When real test alarms are scheduled, `Cancel Test Alarms` must be visible or one tap away.

### 13.6 Guided expectation copy

Each guided preview state should show `Expected:` copy.

Examples:

```text
Expected: The Hero should show “I’m awake for Fajr.”
Expected: The Hero should show “I’m awake for Suhoor.”
Expected: Tapping Quiet should show the stop wake checks sheet.
Expected: The Hero should show “I prayed Fajr.”
```

This is required because the lab must help Omar know what he is evaluating.

### 13.7 Relative date labels

The simulated resolved snapshot may produce labels such as `Today`, `Tomorrow`, or a weekday as if the simulated clock were real.

To prevent confusion, the simulation dock must always show the exact simulated Gregorian date/time. If Hijri context is available, the overlay may also show the simulated Hijri date.

### 13.8 Required Home states

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

## 14. Real Alarm Test

### 14.1 Purpose

Real Alarm Test is the plain-language surface for Real AlarmKit Mapped Playback.

Title:

```text
Real Alarm Test
Schedule real AlarmKit test alarms on this iPhone.
```

Required warning copy:

```text
These alarms will actually ring. Wake checks stay 5 minutes apart.
```

### 14.2 Required real alarm cards

Real Alarm Test must show two primary cards:

1. `Fajr Alarm Test`
2. `Suhoor Alarm Test`

### 14.3 Fajr Alarm Test card

```text
Fajr Alarm Test

Map a simulated Fajr wake session onto real alarms starting soon.

Real alarms will ring.
Default: primary + 5 wake checks.
Full test takes about 25–30 minutes.

[Set Up Fajr Alarm Test]
```

### 14.4 Suhoor Alarm Test card

```text
Suhoor Alarm Test

Map a simulated Suhoor wake session onto real alarms starting soon.

Real alarms will ring.
Default: primary + 5 wake checks.
Full test takes about 25–30 minutes.

[Set Up Suhoor Alarm Test]
```

---

## 15. Real Alarm Setup

### 15.1 Purpose

Real Alarm Setup should be focused and understandable.

Required fields:

```text
Scenario
Start delay
Sequence length
Sound
```

### 15.2 Scenario

Options:

```text
Fajr
Suhoor
```

### 15.3 Start delay

Default:

```text
Primary alarm starts in 90 seconds
```

Allowed options:

```text
60 seconds
90 seconds
120 seconds
```

### 15.4 Sequence length

Default selected:

```text
Primary + 5 wake checks
```

Options:

```text
Primary only
Primary + 1
Primary + 2
Primary + 3
Primary + 4
Primary + 5
```

### 15.5 Sound

Show current selected sound when available:

```text
Sound: Gentle Fajr Adhan
```

If unavailable:

```text
Sound: Default test sound
```

### 15.6 Mapping preview

The setup screen must show both real and simulated schedules.

Example real schedule:

```text
Real alarm schedule

Primary       2:15 PM
Wake check 1  2:20 PM
Wake check 2  2:25 PM
Wake check 3  2:30 PM
Wake check 4  2:35 PM
Wake check 5  2:40 PM
```

Example simulated schedule:

```text
Simulated as

Primary       4:30 AM
Wake check 1  4:35 AM
Wake check 2  4:40 AM
Wake check 3  4:45 AM
Wake check 4  4:50 AM
Wake check 5  4:55 AM
```

### 15.7 Primary action

```text
Schedule Real Test Alarms
```

### 15.8 Required confirmation sheet

Before starting Real Alarm Test, show:

```text
Schedule real test alarms?

These alarms will ring on this iPhone using your selected alarm sound. Wake checks remain 5 minutes apart.

[Cancel]
[Schedule Test Alarms]
```

The confirmation must show:

- selected scenario;
- sequence length;
- mapped real alarm fire times;
- simulated event times;
- sound role/asset if available;
- `Cancel All Test Alarms` availability.

---

## 16. Real AlarmKit mapping rules

### 16.1 What can and cannot be mapped

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

The Home dock and setup screen must show both simulated and real mapped times.

### 16.2 Default mapping strategy

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

### 16.3 Mapping formula

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

### 16.4 Wake-check interval rule

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
instant state jumps in Preview Home UI
mapping the primary alarm to real now + short delay
preserving wake-check deltas after the mapped primary alarm
```

### 16.5 Mode-specific cutoff still applies

Fajr mapped playback:

```text
No wake check later than 5 minutes before Fajr ends.
```

Suhoor mapped playback:

```text
No wake check later than 5 minutes before Fajr begins.
```

The cutoff is evaluated in the simulated timeline before mapping to real alarm times.

### 16.6 Real Alarm Test behavior

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

## 17. Diagnostics

### 17.1 Purpose

Diagnostics are for troubleshooting, not ordinary scenario testing.

Title:

```text
Diagnostics
Use these only when a test does not behave as expected.
```

Default presentation:

```text
Scheduled Test Alarms
Test Event Log
Permission Simulation
Reset Test Mode
```

All diagnostic sections should be collapsed by default unless there is an active warning or active scheduled test alarm.

### 17.2 Scheduled Test Alarms

This replaces the v2 label `Pending Test Alarms`.

Purpose:

```text
See which test alarms are scheduled and cancel them if needed.
```

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
Refresh
Cancel selected
Cancel all test alarms
```

The inspector must clearly distinguish production pending alarms from test pending alarms.

### 17.3 Test Event Log

This replaces the v2 label `MorningLog Inspector`.

Purpose:

```text
Review what happened during the test.
```

Expected examples:

```text
Fajr preview started
Primary alarm scheduled
Alarm stopped
Wake check fired
Awake confirmed
Prayer confirmed
```

Actions:

```text
Copy report
Clear test log
```

Export must remain local/user-initiated.

### 17.4 Permission Simulation

Purpose:

```text
Preview how Subh reacts when alarm permissions are unavailable. This does not change real iOS settings.
```

Options:

```text
AlarmKit unavailable
AlarmKit denied
Notification denied
Sound missing
Schedule failure
```

These simulations must not change real iOS permission settings.

### 17.5 Reset Test Mode

Required safety actions:

```text
Cancel all test alarms
Clear test sessions
Clear test logs
Exit test mode
```

`Cancel all test alarms` must be prominent whenever any mapped real alarm is scheduled.

---

## 18. Safety rules

### 18.1 Test mode must be visually obvious

When a test scenario is active, Subh must show a visible internal banner on Home and the Wake Session Lab:

```text
TEST MODE ACTIVE
```

The user must never confuse a simulated morning with a real worship record.

### 18.2 Test data must not pollute real data

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

### 18.3 Test alarm identifiers must be namespaced

All test scheduled events must use deterministic test identifiers.

Example:

```text
test.wakeSession.{sessionID}.primary
test.wakeSession.{sessionID}.check.1
test.wakeSession.{sessionID}.check.2
```

Test identifiers must not collide with production identifiers.

### 18.4 Clear-all safety actions are required

The Wake Session Lab and Home simulation dock must include or route to:

```text
Cancel All Test Alarms
Clear Test Wake Sessions
Clear Test MorningLogs
Reset Test Time
Exit Test Mode
```

### 18.5 Exit Test Mode behavior

When the user exits test mode, Subh must:

1. cancel all mapped real AlarmKit test alarms;
2. cancel all pending fake/notification test alarms;
3. clear active simulation context;
4. restore Home to the real resolved morning;
5. preserve real user settings and real logs;
6. keep test logs only in debug/internal inspection if retention is useful;
7. never copy test confirmations into real worship history.

### 18.6 Never mutate real settings from a test scenario

Test scenarios must not permanently change:

- real location;
- real prayer calculation method;
- real Hijri adjustment;
- real default wake settings;
- real future plans;
- real paid entitlement;
- real production MorningLogs.

### 18.7 Do not rely on changing the device clock

Testing must not require manually changing iPhone system time.

Preferred approach:

```text
Fake app time for app logic.
Use mapped near-future real times only for actual AlarmKit/device QA.
```

---

## 19. Core testing architecture

### 19.1 Injectable clock

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

### 19.2 Simulation context

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
- the context must be app-wide and observable by Home, Wake Session, scheduler/test services, and the Test Event Log;
- it must not become a second resolver or second product engine.

### 19.3 Simulation run modes

```swift
enum SimulationRunMode {
    case previewHomeUI
    case homeSimulation
    case realAlarmTest
    case fakeSchedulerPlayback
    case dryRun
}
```

| Mode | Meaning | Real alarms? | Primary use |
| --- | --- | ---: | --- |
| `previewHomeUI` | Instantly inspect any simulated date/time/state | No | Design/UX review |
| `homeSimulation` | Home consumes simulated state and supports real UI interactions | No by default | End-to-end UX flow |
| `realAlarmTest` | Simulated events are mapped to real near-future AlarmKit alarms | Yes | Real device QA |
| `fakeSchedulerPlayback` | Scheduler records schedule/cancel calls without platform alarms | No | Integration testing |
| `dryRun` | Builds a plan but schedules nothing | No | Safe debugging |

### 19.4 Simulation clock modes

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

## 20. Scenario definitions

### 20.1 Scenario A — Fajr Preview

Purpose:

Inspect Fajr states instantly without scheduling real alarms.

Required states:

```text
Before Fajr begins
Fajr has begun
Before primary alarm
Primary alarm fired
Wake checks pending
Awake confirmed
Prayer ready
Prayer confirmed
After Fajr ends
```

Pass criteria:

- Home changes immediately when state is selected;
- Hero Action Slot shows the correct CTA/state;
- no real alarms are scheduled;
- logs remain test-only if interactions occur.

### 20.2 Scenario B — Suhoor Preview

Purpose:

Inspect Suhoor and fasting-intent states instantly.

Required states:

```text
Before final third
Suhoor window open
Before primary Suhoor alarm
Primary Suhoor alarm fired
Wake checks pending
Suhoor confirmed
Fasting intent confirmed
Fajr has begun
Prayer ready
Prayer confirmed
```

Pass criteria:

- `I’m awake for Suhoor` is separate from `I prayed Fajr`;
- fasting intent is separate from fast completion;
- no real alarms are scheduled unless Real Alarm Test is explicitly enabled.

### 20.3 Scenario C — Suhoor Not Confirmed → Fajr Begins

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

### 20.4 Scenario D — Quiet During Active Wake Checks

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
5. Test Event Log records `quietMorning`.
6. App does not record `fajrMissed`.

Pass criteria:

- Quiet is intentional;
- Quiet does not equal missed prayer;
- Quiet does not erase underlying user meaning beyond the session rules.

### 20.5 Scenario E — Slider Reschedule Test

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

### 20.6 Scenario F — Alarm Stop vs Awake Confirmation

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

### 20.7 Scenario G — Permission Failure Test

Purpose:

Test that permission failure is not Quiet.

Expected flow:

1. Simulate AlarmKit denied.
2. Simulate Notification permission denied or fallback unavailable.
3. Fajr/Suhoor intent remains active.
4. Hero or settings shows reliability warning.
5. App does not display Quiet.
6. Delivery diagnostics record permission blocked.

Pass criteria:

- blocked delivery does not mutate intent;
- blocked delivery does not become Quiet;
- user receives repair guidance.

### 20.8 Scenario H — Real Alarm Test

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

### 20.9 Scenario I — Test Event Log

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

### 20.10 Scenario J — Cross-Surface Consistency Test

Purpose:

Verify that Home, near-term forecast, Weekly Fajrcast, Day Detail, and delivery agree.

Expected flow:

1. Start a simulated Fajr or Suhoor test session.
2. Change mode from Home.
3. Open near-term forecast.
4. Open Day Detail.
5. Confirm visible mode/time alignment.
6. Trigger schedule refresh.
7. Confirm scheduled test alarm identifiers match resolved state.

Pass criteria:

- surfaces consume the same resolved morning graph;
- no surface invents its own Fajr/Suhoor/Quiet state;
- visible forecast rows do not become scheduled alarms unless in active scheduled horizon.

---

## 21. Scheduler modes

Wake Session Lab should support these scheduler modes, but ordinary testers should not need to choose them for the common flows.

| Mode | Meaning | Use case | Default visibility |
| --- | --- | --- | --- |
| Fake Scheduler | Does not schedule platform alarms; records expected schedule/cancel calls | Fast logic testing | Hidden/internal default for previews |
| Real Notifications | Uses local notifications if available | Fallback/degraded delivery testing | Diagnostics/advanced |
| Real Alarm Test | Uses AlarmKit on physical device with mapped real times | Final device QA | Visible under Real Alarm Test |
| Dry Run | Builds plan but schedules nothing | Safe review/debug | Diagnostics/advanced |

The default lab scheduler mode should be **Fake Scheduler** for non-alarm previews.

Real Alarm Test must require explicit confirmation.

---

## 22. Permission/failure simulation

For fake/integration mode, Diagnostics may simulate:

```text
AlarmKit authorized
AlarmKit denied
AlarmKit unavailable
Notification authorized
Notification denied
Notification fallback degraded
Schedule failure
Missing scheduled alarm
Mismatched fire date
Duplicate identifier
Sound asset missing
```

These simulations must not change real iOS permission settings.

---

## 23. User-facing personal QA checklist

This section is written for Omar as a tester.

### 23.1 Preview Home UI: Fajr

1. Open Developer → Wake Session Lab.
2. Select `Preview Home UI`.
3. Tap `Start Fajr Preview`.
4. Confirm Home opens and shows `TEST MODE ACTIVE`.
5. Confirm the dock says what the current expected state is.
6. Use `Next State` to step through:
   - Fajr has begun;
   - primary alarm fired;
   - wake checks pending;
   - awake confirmed;
   - prayer ready;
   - prayer confirmed.
7. Confirm the Hero Action Slot, CTA placement, and layout feel correct.
8. Exit Test Mode and confirm real Home state returns.

### 23.2 Preview Home UI: Suhoor

1. Open Developer → Wake Session Lab.
2. Select `Preview Home UI`.
3. Tap `Start Suhoor Preview`.
4. Confirm Home opens and shows `TEST MODE ACTIVE`.
5. Tap `I’m awake for Suhoor` when available.
6. Confirm fasting intent is shown/logged as test-only.
7. Jump to Fajr begins.
8. Confirm `I prayed Fajr` appears when appropriate.
9. Exit Test Mode.

### 23.3 Preview Home UI: Quiet

1. Start `Quiet During Wake Checks` preview.
2. Confirm Home shows wake checks pending.
3. Select Quiet.
4. Confirm the stop wake checks sheet appears.
5. Tap `Keep wake checks` once.
6. Confirm wake checks remain pending.
7. Select Quiet again.
8. Tap `Stop for this morning`.
9. Confirm `quietMorning` is logged.
10. Confirm no missed prayer is auto-logged.

### 23.4 Real Alarm Test: Fajr

1. Open Developer → Wake Session Lab.
2. Select `Real Alarm Test`.
3. Open `Fajr Alarm Test`.
4. Choose sequence length, default `Primary + 5 wake checks`.
5. Confirm mapped real fire times.
6. Tap `Schedule Real Test Alarms`.
7. Confirm the real-alarm warning sheet.
8. Lock phone.
9. Wait for primary alarm.
10. Stop the alarm.
11. Confirm Wake Session is not marked awake.
12. Wait five minutes for wake check 1.
13. Open Subh.
14. Tap `I’m awake for Fajr`.
15. Confirm remaining wake checks cancel.
16. Tap `I prayed Fajr`.
17. Open Diagnostics → Test Event Log.
18. Confirm awake and prayer are separate test records.

### 23.5 Real Alarm Test: Suhoor

1. Open Developer → Wake Session Lab.
2. Select `Real Alarm Test`.
3. Open `Suhoor Alarm Test`.
4. Choose sequence length.
5. Confirm mapped real fire times.
6. Schedule mapped alarms.
7. Let primary Suhoor alarm fire.
8. Tap `I’m awake for Suhoor`.
9. Confirm remaining mapped wake checks cancel.
10. Confirm fasting intent is recorded.
11. Confirm Fajr prayer is not recorded.
12. Jump or wait to simulated Fajr begins.
13. Confirm `I prayed Fajr` appears.

### 23.6 Troubleshooting

1. Open Developer → Wake Session Lab.
2. Select `Diagnostics`.
3. Use `Scheduled Test Alarms` to inspect or cancel alarms.
4. Use `Test Event Log` to inspect events.
5. Use `Reset Test Mode` if anything feels stuck.

---

## 24. Automated test requirements

### 24.1 Unit tests

Codex should add tests for:

- Custom Home Preview date/time selection;
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
- clear test records action;
- scenario card metadata validation.

### 24.2 Integration tests

Codex should add tests for:

- Wake Session creation from simulated resolved morning;
- Home consuming active simulation context;
- exiting simulation restoring real resolved morning;
- fake scheduler schedule/cancel calls;
- Real Alarm Test mapping plan generation;
- sequence selector: primary only through primary + 5 wake checks;
- mapped playback preserving five-minute wake-check deltas;
- stale test alarm cleanup;
- Hero state from simulated clock;
- Test Event Log record sequence;
- rescheduling after slider change;
- cross-surface consistency from one resolved graph.

### 24.3 UI tests / previews

Codex should add preview fixtures for:

- Wake Session Lab default state;
- active test mode header;
- Preview Home UI tab;
- Real Alarm Test tab;
- Diagnostics collapsed state;
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

## 25. Physical-device QA matrix

Physical device QA is required for actual delivery confidence.

| Test | Required? | Notes |
| --- | ---: | --- |
| AlarmKit authorization prompt | Yes | Must be tested on real device. |
| Primary alarm audible | Yes | Test normal volume/sound behavior. |
| Wake check after primary stop | Yes | Core Wake Session behavior. |
| Five-minute wake-check spacing | Yes | Must be preserved in Real Alarm Test. |
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

## 26. Production guardrails

Before release, CI or a manual release checklist must verify:

- Wake Session Lab is not visible in production;
- Preview Home UI controls are not visible in production;
- Home Simulation controls are not visible in production;
- Real Alarm Test controls are not visible in production;
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

## 27. Acceptance criteria

### 27.1 Personal testing acceptance

- [ ] Omar can open Wake Session Lab without facing more than three top-level sections.
- [ ] Omar can understand the difference between `Preview Home UI`, `Real Alarm Test`, and `Diagnostics` from the screen copy.
- [ ] Omar can start Fajr, Suhoor, and Quiet previews from simple scenario cards.
- [ ] Each scenario card explains what it tests, whether real alarms ring, approximate duration, and what to expect.
- [ ] Omar can set a simulated date and time through Custom Home Preview.
- [ ] Omar can choose a simulated location.
- [ ] Omar can activate the simulated state on Home.
- [ ] Omar can inspect Fajr, Suhoor, Quiet, wake-check, confirmation, prayer, and permission states without waiting for real mornings.
- [ ] Omar can jump between named states instantly from Home.
- [ ] Omar can run Real Alarm Test on his iPhone.
- [ ] Omar can choose sequence length from primary only through primary + 5 wake checks.
- [ ] The default mapped sequence is primary + 5 wake checks.
- [ ] Real mapped wake checks are five minutes apart.
- [ ] Omar can see scheduled test alarms.
- [ ] Omar can clear all test alarms.
- [ ] Omar can inspect Test Event Log records.
- [ ] Omar can exit test mode and restore real Home state.

### 27.2 Architecture acceptance

- [ ] Resolver and Hero can consume injected time in test mode.
- [ ] Home can consume an active simulation context.
- [ ] The simulation feeds the canonical resolved morning graph / snapshot path.
- [ ] Fake scheduler can be used without AlarmKit.
- [ ] Real AlarmKit can be used for mapped device tests.
- [ ] Test records are marked and isolated.
- [ ] Test scenarios do not mutate real settings.
- [ ] Production builds do not expose the lab.

### 27.3 Product acceptance

- [ ] Testing preserves Subh as one Fajr-centered morning system.
- [ ] Testing does not create a second wake engine.
- [ ] Testing does not pollute real worship logs.
- [ ] Testing does not create guilt/judgment records.
- [ ] Testing supports the complete MVP Wake Session loop.
- [ ] The testing harness is usable by Omar without requiring him to understand internal scheduler architecture.

---

## 28. Codex implementation prompt

Use this as the implementation prompt after this spec is accepted.

```text
Implement the v3 debug/internal Wake Session Testing, Home Simulation, and Real Alarm Test harness for Subh according to `subh-wake-session-testing-and-simulation-harness-spec-v3.md`.

Use OpenSpec first.
Do not change production wake rules.
Do not expose the Wake Session Lab, Preview Home UI controls, Home Simulation controls, Diagnostics debug controls, or Real Alarm Test controls in App Store production builds.
Do not implement paid features, StoreKit, analytics, adaptive wake checks, household features, or cloud sync.

Important v3 UX rule:
- The Wake Session Lab must be task-oriented, not subsystem-oriented.
- The visible top-level sections are: Preview Home UI, Real Alarm Test, Diagnostics.
- Preview Home UI is the default.
- Diagnostics are secondary/collapsed by default.
- Time controls belong on the Home simulation dock, not as a large settings section.
- Each scenario card must explain what it tests, whether real alarms ring, approximate duration, what to expect, and the primary action.

Important v3 timing rule:
- Do not use one-minute or two-minute wake-check intervals.
- State jumps may be instant.
- Real Alarm Test must preserve the production five-minute wake-check interval.
- The Real Alarm Test builder must let the tester choose primary only, primary + 1, primary + 2, primary + 3, primary + 4, or primary + 5 wake checks.
- Default Real Alarm Test sequence is primary + 5 wake checks.

Implement:
1. Injectable clock/time provider for resolver, Wake Session, Hero state, and Test Event Log testing.
2. ActiveSimulationContext / TestScenarioContext app-wide store.
3. Simplified Wake Session Lab with three top-level sections:
   - Preview Home UI
   - Real Alarm Test
   - Diagnostics
4. Preview Home UI cards:
   - Fajr Flow
   - Suhoor Flow
   - Quiet During Wake Checks
   - Custom Date & Time
5. Custom Home Preview with default fields only:
   - Date
   - Location
   - Mode
   - State
   Advanced options collapsed by default.
6. Home Simulation Mode so Home consumes the simulated resolved morning snapshot.
7. Home simulation dock with:
   - TEST MODE ACTIVE
   - scenario name
   - simulated date/time
   - expected current state
   - Previous State
   - Next State
   - Change State
   - Exit
   - Cancel Test Alarms when applicable.
8. Real Alarm Test tab with:
   - Fajr Alarm Test
   - Suhoor Alarm Test
9. Real Alarm Setup screen with:
   - Scenario
   - Start delay
   - Sequence length
   - Sound
   - Real alarm schedule preview
   - Simulated schedule preview
   - Schedule Real Test Alarms button
   - required confirmation sheet.
10. Real Alarm Test mapping:
   - map selected simulated anchor event to real now + start delay;
   - preserve simulated event deltas after the anchor;
   - preserve five-minute wake-check spacing;
   - use deterministic test AlarmKit identifiers;
   - allow sequence length primary only through primary + 5;
   - default to primary + 5;
   - cancel all remaining mapped alarms when awake is confirmed, Quiet is confirmed, or test mode exits.
11. Test prayer-window/scenario provider using real prayer calculations by default for selected date/location, with optional advanced custom artificial window support.
12. Fake scheduler adapter that records schedule/cancel/reconciliation calls without platform alarms.
13. Diagnostics section with collapsed subsections:
   - Scheduled Test Alarms
   - Test Event Log
   - Permission Simulation
   - Reset Test Mode
14. Scheduled Test Alarms inspector showing simulated fire time and mapped real fire time.
15. Test Event Log for test records.
16. Cancel All Test Alarms / Clear Test Logs / Exit Test Mode safety actions.
17. Production guardrails so test UI is unavailable in release builds.
18. Unit/integration/UI tests covering the scenarios in the spec.

Rules:
- Test sessions must be visibly marked.
- Test records must use `isTest = true` or equivalent.
- Test alarm identifiers must be namespaced.
- Stopping an alarm must not confirm awake.
- Confirming awake must cancel remaining wake checks.
- Suhoor confirmation must set fasting intent but not Fajr prayer or fast completion.
- Quiet must log quietMorning, not missed prayer.
- Permission failure must not become Quiet.
- Real Alarm Test must be explicit, confirmable, and cancellable.

After implementation:
- Run OpenSpec validation.
- Run targeted tests.
- Provide files changed, tests added, tests run, manual device QA steps, and known limitations.
```

---

## 29. Open decisions

| Decision | Recommendation / current status |
| --- | --- |
| Should Wake Session Lab be available in internal TestFlight? | Yes, behind explicit internal flag. |
| Should test records be exportable? | Yes, local/manual export only. |
| Should real AlarmKit mapped tests preserve five-minute wake checks? | Yes. Locked in v2/v3. |
| Should Preview Home UI allow instant jumps? | Yes. Locked in v3. |
| Should mapped playback default to full sequence? | Yes: primary + 5 wake checks. |
| Should mapped playback allow shorter sequence choices? | Yes: primary only through primary + 5. |
| Should Diagnostics be visible by default? | Visible as a tab/section, but its subsections are collapsed/secondary by default. |
| Should production include safe diagnostics? | Yes, but not fake time/scenario controls. |
| Should the test harness ship before Wake Sessions? | It can ship alongside Wake Sessions; at minimum, fake scheduler and unit tests should exist before full implementation. |

---

## 30. Final rule

The testing harness exists to make Subh testable without weakening Subh’s product truth.

```text
Real product logic.
Tester-friendly launchpad.
Home as the testing stage.
Diagnostics as troubleshooting, not the default path.
Simulated date/time and state.
Mapped real AlarmKit alarms when explicitly requested.
Five-minute wake checks preserved.
Clear test labels.
No production exposure.
No real-log pollution.
```
