# Subh Wake Session Testing, Simulation, and Real Alarm Validation Harness Spec v6 — June 1 CTA, Early-Awake, and Wake-Check Display Test Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-session-testing-and-simulation-harness-spec-v6.md` |
| Version | 6 |
| Spec status | Active testing and simulation harness specification |
| Date | 2026-06-01 |
| Supersedes | `subh-wake-session-testing-and-simulation-harness-spec-v5.md` |
| Owning domain / surface | Developer/internal testing, Wake Session Lab UX, Home Simulation Mode, Day Detail simulation, Next 7 / Month / Weekly Fajrcast verification, Real AlarmKit mapped playback, diagnostics, test-data safety |
| Related specs | Active versions in `00-subh-spec-index`; especially Morning Resolution, Morning Hero, Alarm Detail, Quiet Morning, Wake Sessions / Wake Checks / Morning Logs, Alarm Delivery / Schedule Reliability, Next 7 Mornings, Month Planning, Weekly Fajrcast, Shared Day Tag Presentation, Pricing / Entitlement, and MVP Interaction Inventory |
| Implementation audit status | Specification update; implementation pending |

---

## 0A. v5 May 31 morning-state simulation update

Version 5 adds the May 31 Morning State Framework test requirements. The harness must let Omar simulate the daily cycle that began from the live Toronto May 31, 2026 state and then scrub through daytime, evening, midnight, Suhoor window, Fajr begins, Fajr window, Fajr end, and post-Fajr next-morning rollover.

The harness must support:

- minute-by-minute scrubbing through at least the next 24 hours, preferably 48 hours;
- boundary presets for daytime, evening, before midnight, midnight, before Suhoor window, Suhoor window start, Suhoor cutoff, Fajr begins, Fajr active window, default wake time, final check, Fajr end, and after Fajr;
- action-branching while simulated time is active, including purpose switching, slider adjustment, Quiet confirmation, Next 7 Quiet toggle, `I’m Awake`, `I’m Awake for Fajr`, `I Prayed Fajr`, late Fajr logging, and slider-activated Fajr wake checks after Suhoor after Suhoor;
- live preview of the real Home Hero, context card, late logging prompt, and Next 7 row output;
- readable expected-vs-actual state summaries that do not clip or run off screen;
- simulation backlog entries for DST, high-latitude, Ramadan, Eid/fasting-unavailable, location change, and prayer-time calculation-change cases.

Version 5 supersedes older test expectations where they conflict with the May 31 decisions: visible purpose selector order is `Suhoor | Fajr`; Next 7 has a right-column Quiet toggle; active-session Quiet cancellation may be tested as a confirmed cancellation edge case; Suhoor acknowledgement does not automatically create Fajr wake checks; and late Fajr logging appears inside the context-card action area, not inside the Hero after rollover.

## 0. v4 update summary

Version 4 replaces the v3 testing harness direction with a fuller implementation-grade and tester-friendly specification aligned to the current Subh model:

```text
Wake purpose values: Fajr, Suhoor
Visible purpose selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
```

The v4 testing harness must prove that Subh behaves correctly across planning, Quiet, Pause, ring-once exceptions, wake execution, Suhoor-to-Fajr handoff, date contexts, scheduler behavior, logs, and cross-surface UI display.

Major v4 changes:

1. Quiet is no longer a test “mode.” It is a one-morning alarm-state override.
2. Pause is explicitly covered as a global indefinite alarm policy.
3. Active-session Quiet cancellation is an approved edge-case scenario only when exposed through a confirmed alarm-state control. It is not the primary active wake action, and it must cancel remaining checks without logging wake or prayer completion.
4. `Stop checks` is forbidden as an active user-facing control.
5. For MVP, explicit system / AlarmKit dismissal is tested as an awake acknowledgement, with acknowledgement source captured separately.
6. The harness must test Suhoor wake acknowledgement, fasting status, Fajr wake acknowledgement, and Fajr prayer logging as separate facts.
7. Standard scenarios must always pre-calculate and show valid times. They must not accidentally display `No time available` in the Hero.
8. The testing UX is specified in detail: layout, labels, card structure, font sizing, button hierarchy, scenario organization, and instructions.
9. The harness must use the real app resolver and view-model paths. It must not create a fake duplicate Hero or fake duplicate product engine.
10. Diagnostics are deep but secondary. The primary experience is guided scenario testing.

Plain-language v4 standard:

```text
Omar should be able to choose a scenario, understand what it proves, see the exact simulated times, preview the real Home and Detail UI, inspect every affected surface, and optionally run real mapped AlarmKit tests without waiting for an actual morning and without polluting real user data.
```

---

## June 1, 2026 CTA/logging reconciliation

This version is reconciled with `subh-cta-logging-and-wake-action-spec-v2.md`. If earlier text in this file conflicts with the CTA spec, use the June 1 rules below:

- Active wake CTAs live in the Hero: **I’m Awake for Suhoor** and **I’m Awake for Fajr**.
- Logging and early-awake actions live in the context-card action area, not in the Hero and not as a separate standalone CTA card.
- Ordinary system/AlarmKit dismissal does not by itself mean the user is awake. It dismisses the current alarm attempt and the Hero must advance to the next pending wake-check time when one exists.
- Only explicit awake confirmation, confirmed early-awake action, or an explicitly supported platform action mapped to awake confirmation cancels remaining wake checks as wake success.
- **I’m Awake for Fajr** and **I Prayed Fajr** must not appear simultaneously.
- Late Fajr and fast completion use compact check/X prompt rows and must distinguish ✓, ✕, and unrecorded.
- Silence/unanswered is never treated as no.

## 1. Purpose

This spec defines Subh’s internal testing layer for Wake Sessions, wake checks, Quiet, Pause, Home Hero states, Day Detail states, planning surfaces, scheduler consequences, logs, and real AlarmKit delivery.

The harness exists because the wake system is time-dependent. Omar must be able to verify morning states without waiting for real Fajr/Suhoor windows.

The harness has three visible utilities:

1. **Preview Home UI** — instantly preview real app UI using simulated date/time/state, without real alarms.
2. **Run Real Alarm Test** — map a simulated wake session onto real near-future AlarmKit alarms.
3. **Diagnostics** — inspect resolver snapshots, Hero slots, scheduled test alarms, logs, permission/setup simulations, and reset tools.

The harness must be both:

- deep enough for implementation and regression confidence;
- simple enough for Omar to use without reading developer internals.

---

## 2. Product model under test

The testing harness must be built around the current canonical product model.

### 2.1 Wake purpose

Wake purpose answers why/when the user intends to wake.

Allowed active MVP values:

```text
Fajr
Suhoor
```

Forbidden active MVP wake-purpose values:

```text
Quiet
Pause
Pre-Fajr
Early
Fast mode
Fasting mode
Tahajjud only
Other early worship
```

Legacy references may exist only in migration, archive, or explicitly deprecated documentation.

### 2.2 Alarm state

Alarm state answers whether Subh will ring and why.

Required state concepts:

```text
active
quiet
paused
rings-once
blocked
issue
unavailable
```

Implementation may use exact enum names from the active resolution spec, but the testing harness must expose these plain-language states.

### 2.3 Separation of facts

The testing harness must verify that these facts remain separate:

```text
Fajr/Suhoor wake purpose
Date-level Quiet override
Global Pause policy
Ring-once exception while paused
Wake Session execution
Suhoor wake acknowledgement
Fajr wake acknowledgement
Fast completion prompt status
Fajr prayer logged
No response
Setup / permission issue
```

### 2.4 Non-negotiable behavioral rules

The harness must test and protect these rules:

1. Quiet is not a wake purpose.
2. Pause is not a wake purpose.
3. Quiet suppresses alarms for one selected morning only.
4. Pause turns wake alarms off globally until resumed.
5. Ring-once is a one-morning exception while global Pause remains active.
6. Quiet preserves the selected Fajr/Suhoor wake purpose and saved purpose-specific alarm settings.
7. Pause preserves saved plans and manual Quiet decisions.
8. Quiet is available before alarm execution begins.
9. Quiet is not exposed as the primary active wake action after the first alarm begins; if active-session Quiet cancellation is exposed through an approved alarm-state control, it requires confirmation and cancels remaining checks without wake acknowledgement.
10. Active wake execution exposes `I’m Awake`, not `Stop checks`.
11. For MVP, explicit system / AlarmKit dismissal counts as awake acknowledgement if the platform callback supports it; the acknowledgement source must be captured.
12. Suhoor `I’m Awake` does not equal Fajr `I’m Awake for Fajr`.
13. `I’m Awake`, `I completed my fast today? ✓ ✕`, and `I Prayed Fajr` are separate actions/log facts.
14. Setup/permission failure is not Quiet.
15. Quiet/Paused/Rings once/setup issue appear as alarm statuses, not as opportunity tags.
16. Core current-morning testing flows must not be gated by paid entitlements.

---

## 3. Testing principle

Subh must have one product engine.

Plain-language rule:

```text
Do not fake the product logic. Fake the world around it.
```

The testing harness may simulate:

- current app time;
- selected date;
- selected location;
- prayer-time source;
- date context such as Ramadan, White Days, Eid, DST, or ordinary morning;
- wake purpose;
- alarm state;
- execution state;
- permission/setup condition;
- scheduler adapter;
- real AlarmKit mapping.

But the harness must feed the real:

- morning resolver;
- Home Hero snapshot/view model;
- Day Detail view model;
- Next 7 row resolver;
- Month row resolver;
- Weekly Fajrcast resolver;
- alarm scheduler/reconciler;
- Wake Session engine;
- MorningLog writer;
- entitlement gates.

Forbidden:

```text
Hardcoded fake Home screen
Separate fake Hero component
Second wake-resolution engine
Scenario-only business rules that bypass the app resolver
Mock UI that looks right but does not exercise real app state
```

---

## 4. v4 tester UX doctrine

The testing harness is an internal product surface. It must be designed with the same care as user-facing Subh screens.

### 4.1 UX goal

The tester should always know:

1. what scenario is being tested;
2. which date/time/location it uses;
3. what times Subh has calculated;
4. which screen should be inspected;
5. what the expected Hero/Detail/row state is;
6. whether real alarms will ring;
7. how to advance, inspect, or exit safely.

### 4.2 Top-level mental model

```text
Wake Session Lab = launchpad
Home = primary testing stage
Day Detail / rows = consistency surfaces
Diagnostics = troubleshooting drawer
Real Alarm Test = physical-device validation
```

### 4.3 Top-level IA

The visible Wake Session Lab must expose exactly three primary sections:

```text
Preview Home UI
Run Real Alarm Test
Diagnostics
```

`Preview Home UI` must be the default section.

Diagnostics must be available but visually secondary. It must not be the first thing Omar has to understand.

### 4.4 Main screen layout

Recommended structure:

```text
Wake Session Lab
Test Subh mornings without waiting for real Fajr.

Status card
- No test running
  or
- TEST MODE ACTIVE · {scenario} · {simulated date} · {simulated time}

[ Preview Home UI | Real Alarm Test | Diagnostics ]

Primary section content
```

When a test is active, the status card must include:

```text
Scenario name
Wake purpose
Alarm state
Simulated Gregorian date
Simulated Hijri date if available
Simulated current time
Location
Prayer-time source
Primary calculated alarm time
Real alarms scheduled? yes/no
```

Required active-test actions:

```text
Return to Home
Open Day Detail
Inspect All Surfaces
Exit Test Mode
Cancel Test Alarms, when any real mapped alarms exist
```

### 4.5 Typography and sizing guidance

The implementation should use native platform typography where possible, but must follow this hierarchy:

| Element | Recommended size / style | UX purpose |
| --- | ---: | --- |
| Screen title | 28–34 pt, bold | Clear orientation |
| Active test banner title | 17–22 pt, semibold | Obvious test state |
| Section heading | 20–24 pt, semibold | Easy scanning |
| Scenario card title | 17–20 pt, semibold | Clear scenario choice |
| Scenario card body | 14–16 pt | Readable instructions |
| Metadata chips | 12–13 pt | Compact secondary details |
| Diagnostic table labels | 12–14 pt | Dense but readable |
| Monospaced identifiers | 11–13 pt | Debug-only IDs |
| Primary buttons | 16–17 pt, semibold; 48–56 pt height | Confident action |
| Secondary buttons | 15–16 pt; at least 44 pt height | Accessible secondary action |
| Small helper copy | 13–15 pt | Explain consequences |

Minimum touch target:

```text
44 pt × 44 pt
```

Preferred primary button height:

```text
48–56 pt
```

No critical scenario action may be shown only as a tiny text link.

### 4.6 Card layout standard

Every scenario card must include:

```text
Title
One-sentence purpose
Wake purpose
Alarm state
Date context
Calculated times summary
Real alarms: No / Yes
Estimated test time
Primary action
Secondary action: View details / Inspect expected states
```

Example card skeleton:

```text
Quiet Fajr
Preview a Fajr morning where Subh will not ring.

Purpose: Fajr
Alarm state: Quiet
Date: Tomorrow · Ordinary morning
Times: Fajr 5:02 AM–6:41 AM · Saved alarm 6:11 AM
Real alarms: No
Takes: 1–2 minutes

[Preview on Home]
[View expected states]
```

### 4.7 Scenario grouping

Scenarios must be grouped by tester task, not subsystem:

1. **Plan & Preview**
2. **Quiet & Pause**
3. **Wake Execution**
4. **Suhoor → Fajr Handoff**
5. **Date Contexts**
6. **Setup / Issue States**
7. **Cross-Surface Checks**

Only the most common scenarios should be visible by default. Less common scenarios must be one tap away under `Show all scenarios` or grouped packs.

### 4.8 Maximum visible complexity

On the main `Preview Home UI` screen, show:

- 3–5 primary scenario cards;
- a compact `Custom Test Builder` entry;
- no raw enum pickers by default;
- no long technical log tables by default.

Advanced controls may exist, but they must be collapsed under clear labels such as:

```text
Advanced State Builder
Diagnostics
Technical Details
```

### 4.9 Plain-language labels

Preferred visible labels:

| Internal concept | Visible label |
| --- | --- |
| `ActiveSimulationContext` | `Active Test` |
| `ResolvedMorningSnapshot` | `Morning State` |
| `DateAlarmOverride.quiet` | `Quiet for this morning` |
| `GlobalWakeAlarmPolicy.pausedIndefinitely` | `Alarms paused` |
| `ringDespitePause` | `Ring this morning only` / `Ring tomorrow only` |
| `permissionBlocked` | `Alarm setup issue` |
| `acknowledgedBy.systemAlarmDismiss` | `Confirmed from system alarm` |
| `fakeScheduler` | `Preview scheduler` |
| `mappedPlayback` | `Real alarm test` |
| `MorningLog Inspector` | `Test Event Log` |
| `Pending Test Alarms` | `Scheduled Test Alarms` |

Forbidden active user-facing labels in the harness:

```text
Pre-Fajr
Early mode
Fast mode
Fasting mode
Quiet mode as a selector option
Pause mode as a selector option
Stop checks
```

The phrase `Quiet mode` may appear only in migration notes or deprecated-term audits, not in active test labels.

---

## 5. Time availability and “real deal” calculation contract

The harness must make time testing reliable. Standard scenarios must not produce ambiguous or placeholder Hero timing.

### 5.1 Standard scenario time rule

Every standard scenario card must have a complete time model before it can be launched.

Required calculated values:

```text
Simulated current time
Fajr begins
Fajr ends / sunrise boundary used by app
Selected wake purpose
Selected saved alarm time
Primary alarm fire time
Follow-up alarm times, when applicable
Follow-up cutoff boundary
Location
Time zone
Prayer-time source
```

For Suhoor scenarios, also show:

```text
Suhoor alarm time
Fajr begins
Last allowed follow-up before Fajr begins
```

For Fajr scenarios, also show:

```text
Fajr alarm time
Fajr ends / sunrise boundary
Last allowed follow-up before Fajr ends
```

### 5.2 No accidental “No time available” rule

Standard guided scenarios must never launch into a Hero state where the main alarm time says:

```text
No time available
```

or equivalent placeholder copy.

If a standard scenario cannot calculate times, the scenario card must be blocked before launch and show a repair message:

```text
Test setup issue: prayer times could not be calculated for this scenario.
Choose a different location/date or open Diagnostics.
```

The harness must not hide this as a normal product state.

### 5.3 Dedicated missing-time scenarios

The only scenarios that may intentionally show unavailable time/setup repair states are dedicated setup/issue scenarios, such as:

```text
Missing location
Missing prayer times
Prayer calculation failure
Alarm permission blocked
```

These scenarios must be clearly labelled as issue-state tests.

Example:

```text
Missing Prayer Times
Verify that Subh shows a repair state when prayer times cannot be calculated.

This scenario intentionally shows an alarm setup issue.
It should not be used to validate normal Fajr/Suhoor timing.
```

### 5.4 Real calculation by default

Default scenario behavior:

```text
Use the app’s real prayer-time calculation path for the selected date and location.
```

Allowed advanced behavior:

```text
Use a custom artificial prayer window only under Advanced Options.
```

The harness must clearly mark artificial windows:

```text
Prayer-time source: Custom test window
```

Artificial windows must not be the default for standard scenarios.

### 5.5 Time display surfaces

Calculated times must appear in all relevant testing surfaces:

1. scenario card;
2. scenario detail/review sheet;
3. Home simulation dock;
4. Day Detail test header;
5. Real Alarm Setup schedule preview;
6. Diagnostics time inspector;
7. cross-surface consistency report.

### 5.6 Time validation before preview

Before launching any scenario, the harness must validate:

```text
valid location
valid time zone
valid simulated date
valid Fajr begins
valid Fajr ends / sunrise boundary
valid purpose-specific alarm time
valid follow-up schedule or explicit no-follow-up reason
valid date context
```

If validation fails, show a blocking review state instead of launching a broken Hero.

### 5.7 Time labels in Home simulation dock

The Home simulation dock must always display:

```text
Simulated now: {time}
Date: {weekday, month day, year}
Location: {city or test location}
Fajr: {begins}–{ends}
Alarm: {alarm time}
Source: {real calculation | custom test window}
```

When follow-ups are part of the state, show:

```text
Next follow-up: {time}
Cutoff: {time}
```

For mapped real alarms, also show:

```text
Next real alarm: {real fire time} · {countdown}
Simulated event: {simulated event time}
```

---

## 6. Simulation architecture

### 6.1 Injectable clock

Subh must support a testable time source.

Conceptual model:

```swift
protocol SubhClock {
    var now: Date { get }
    var timeZone: TimeZone { get }
}
```

Production:

```text
RealSubhClock → current app/device time
```

Testing:

```text
TestSubhClock → controlled simulated now
```

Required behavior:

- resolver logic consumes the injected clock;
- Hero state consumes the resolved snapshot from the injected clock path;
- Day Detail and forecast rows consume the same resolution path;
- SwiftUI views must not use `Date()` directly for domain decisions;
- scheduling adapters use real time only for real platform alarm scheduling or mapped playback.

### 6.2 Active simulation context

The app must support an app-wide active simulation context.

Conceptual structure:

```swift
struct ActiveSimulationContext {
    let simulationID: String
    let isTest: Bool
    let scenarioID: String
    let scenarioName: String
    let runMode: SimulationRunMode
    let simulatedDate: LocalDate
    let simulatedNow: Date
    let simulatedTimeZone: TimeZone
    let simulatedLocation: SimulationLocation
    let prayerWindowSource: PrayerWindowSource
    let calculatedPrayerWindow: CalculatedPrayerWindow
    let wakePurpose: WakePurpose
    let dateAlarmOverride: DateAlarmOverride
    let globalWakeAlarmPolicy: GlobalWakeAlarmPolicy
    let executionState: SimulatedExecutionState
    let logState: SimulatedMorningLogState
    let schedulerMode: SimulationSchedulerMode
    let alarmMapping: AlarmMappingPlan?
    let createdAtRealDate: Date
}
```

Exact implementation names may differ, but the information must be representable.

### 6.3 Run modes

```swift
enum SimulationRunMode {
    case previewHomeUI
    case realAlarmTest
    case fakeSchedulerPlayback
    case crossSurfaceAudit
    case dryRun
}
```

| Mode | Meaning | Real alarms? | Primary use |
| --- | --- | ---: | --- |
| `previewHomeUI` | Instantly inspect UI using simulated state | No | UX and state review |
| `realAlarmTest` | Map simulated events to real near-future AlarmKit alarms | Yes | Device QA |
| `fakeSchedulerPlayback` | Record schedule/cancel calls without platform alarms | No | Integration testing |
| `crossSurfaceAudit` | Compare Home/Detail/rows/scheduler/logs | No | Regression validation |
| `dryRun` | Build a resolved plan but schedule nothing | No | Safe debugging |

### 6.4 Clock modes

```swift
enum SimulationClockMode {
    case frozen
    case jumpOnly
    case runningRealTime
    case mappedPlayback
}
```

| Clock mode | Meaning | Use |
| --- | --- | --- |
| `frozen` | Time stays fixed | Layout screenshots |
| `jumpOnly` | Tester jumps between named states | Fast coverage |
| `runningRealTime` | Simulated time advances normally | Natural transition review |
| `mappedPlayback` | Simulated events map to real AlarmKit fire times | Real Alarm Test |

Default for Preview Home UI:

```text
jumpOnly
```

Default for Real Alarm Test:

```text
mappedPlayback
```

### 6.5 Scheduler modes

| Scheduler mode | Meaning | Default visibility |
| --- | --- | --- |
| Preview scheduler | Records expected schedule/cancel calls; no platform alarms | Default for previews |
| Real AlarmKit mapped playback | Schedules actual near-future AlarmKit alarms | Visible only in Real Alarm Test |
| Local notification fallback simulation | Tests degraded/fallback path | Diagnostics only |
| Dry run | Builds plan but schedules nothing | Advanced diagnostics |

---

## 7. Preview Home UI

### 7.1 Purpose

Preview Home UI is the primary testing experience.

Plain-language goal:

```text
Show me exactly what Subh would look like if it were this morning, at this time, with this wake/alarm state.
```

### 7.2 Default view

Default content:

```text
Preview Home UI
Choose a scenario. No real alarms will ring.

Primary scenario cards:
- Active Fajr Morning
- Active Suhoor Morning
- Quiet & Pause Pack
- Suhoor → Fajr Handoff

Secondary:
- Custom Test Builder
- Show all scenarios
```

### 7.3 Required primary scenario cards

#### Active Fajr Morning

```text
Preview the normal Fajr planning and wake flow.
```

Required summary:

```text
Purpose: Fajr
Alarm state: Active
Date: Tomorrow or selected ordinary morning
Times: Fajr {begins}–{ends} · Alarm {time}
Real alarms: No
```

Primary action:

```text
Preview on Home
```

#### Active Suhoor Morning

```text
Preview the normal Suhoor wake and fasting flow.
```

Required summary:

```text
Purpose: Suhoor
Alarm state: Active
Date: Ramadan example or selected fasting-capable morning
Times: Fajr begins {time} · Suhoor alarm {time}
Real alarms: No
```

Primary action:

```text
Preview on Home
```

#### Quiet & Pause Pack

```text
Preview Quiet, global Pause, and ring-once exception states.
```

The pack opens a simple list of cards:

```text
Quiet Fajr
Quiet Suhoor
Alarms Paused
Ring Tomorrow Only
Quiet Preserved After Resume
Quiet Unavailable During Active Alarm
```

#### Suhoor → Fajr Handoff

```text
Preview Suhoor wake, fasting status, Fajr wake acknowledgement, and Fajr prayer logging as separate steps.
```

Required summary:

```text
Purpose: Suhoor
Alarm state: Active
Date: Ramadan or fasting-capable morning
Times: Suhoor alarm {time} · Fajr {begins}–{ends}
Real alarms: No
```

### 7.4 Scenario detail/review sheet

Before activating a scenario, show a review sheet:

```text
Review Test Scenario

Scenario: {name}
Purpose: {Fajr/Suhoor}
Alarm state: {active/quiet/paused/rings-once/issue}
Date: {Gregorian date}
Hijri: {Hijri date, if available}
Location: {location}
Prayer-time source: {real calculation/custom test window}
Fajr: {begins}–{ends}
Alarm: {alarm time or saved alarm time}
Follow-ups: {times or reason none}
Surfaces to inspect: Home, Detail, Next 7, Month, Weekly Fajrcast
Real alarms: No

Expected first Hero state:
Slot 3: {expected alarm status}
Slot 5: {expected supporting copy}
Slot 6: {expected action row}

[Cancel]
[Preview on Home]
```

This sheet is required to prevent launching unclear or broken scenarios.

### 7.5 Custom Test Builder

The Custom Test Builder must be powerful but simple.

Default visible fields:

```text
Morning date
Location
Wake purpose
Alarm state
Execution point
```

Required options:

#### Morning date

```text
Today
Tomorrow
Pick date
Ordinary example
Ramadan example
Monday example
Thursday example
White Days example
Eid / fasting unavailable example
DST transition example
Very early Fajr example
Very late Fajr example
```

#### Location

```text
Current app location
Toronto preset
Choose city
Saved test location
```

Implementation may use other presets, but at least one reliable complete-time preset must exist so standard scenarios never fail due to missing location.

#### Wake purpose

```text
Fajr
Suhoor
```

No Quiet/Pause options may appear in this selector. Visible order is `Suhoor | Fajr`.

#### Alarm state

```text
Active
Quiet for this morning
Alarms paused
Ring this morning only
Alarm setup issue
```

#### Execution point

The execution point picker must adapt to the selected alarm state.

For Active Fajr:

```text
Planning before Fajr
Fajr has begun
Before primary alarm
Primary alarm active
Follow-up pending
Awake for Fajr confirmed
Prayer ready
Fajr prayer logged
Fajr window ended
```

For Active Suhoor:

```text
Planning before Suhoor
Suhoor alarm active
Suhoor follow-up pending
Awake for Suhoor confirmed
Fast completion answered yes
Fajr has begun
Awake for Fajr confirmed
Prayer ready
Fajr prayer logged
Fajr window ended
```

For Quiet:

```text
Quiet planned before execution
Quiet shown on Home
Turn alarm back on
```

For Pause:

```text
Paused inherited
Ring this morning only
Resume alarms
```

For Setup Issue:

```text
Alarm permission blocked
Location missing
Prayer times missing
Schedule failure
Sound missing
```

### 7.6 Validity constraints

The builder must prevent invalid combinations rather than letting the user create nonsense states.

Examples:

| Attempted combination | Required behavior |
| --- | --- |
| Wake purpose = Quiet | Not possible; Quiet is an alarm state |
| Wake purpose = Pause | Not possible; Pause is global alarm policy |
| Alarm state = Quiet + Execution point = Primary alarm active | Invalid; show `Quiet is only available before alarm execution begins` |
| Alarm state = Paused + Ring this morning only simultaneously without exception flag | Use explicit ring-once exception model |
| Date context = Eid + fasting CTA expected | Block or show fasting unavailable expectation |
| Missing prayer times + normal Fajr planning | Block normal scenario; redirect to issue-state scenario |

---

## 8. Home Simulation Mode

### 8.1 Purpose

Home Simulation Mode makes the real Home screen behave as if the selected simulated morning is happening now.

The goal is to test:

- actual Hero layout;
- six-slot Hero state;
- alarm-state button/status;
- slider/timeline behavior;
- Fajr/Suhoor selector behavior;
- Quiet/Pause/ring-once status display;
- `I’m Awake` / `I’m Awake for Fajr` / `I completed my fast today? ✓ ✕` / `I Prayed Fajr` actions;
- follow-up pending states;
- time display accuracy;
- cross-surface navigation.

### 8.2 Activation behavior

When the tester taps `Preview on Home`, Subh must:

1. create an `ActiveSimulationContext`;
2. validate complete time data;
3. mark all scenario data as test-only;
4. route Home to the simulated resolved morning snapshot;
5. navigate to Home;
6. display `TEST MODE ACTIVE`;
7. show the simulation dock;
8. keep real user settings/logs untouched.

### 8.3 Simulation dock layout

The dock must be compact and must not hide the Hero being tested.

Preferred placement:

```text
Collapsible bottom dock below/over the lower safe area, with a compact collapsed header and expandable details.
```

Required collapsed header:

```text
TEST MODE ACTIVE · {scenario name}
{simulated time} · {date} · {alarm status}
[Next]
[Exit]
```

Required expanded content:

```text
Scenario: {name}
Wake purpose: {Fajr/Suhoor}
Alarm state: {active/quiet/paused/rings-once/issue}
Simulated now: {time}
Date: {Gregorian date}
Location: {location}
Fajr: {begins}–{ends}
Alarm: {alarm time or saved alarm time}
Expected Hero: Slot 3 {value} · Slot 6 {value}
```

Required dock actions:

```text
Previous State
Next State
Jump to State
Inspect Surfaces
Exit Test Mode
```

When real mapped alarms are scheduled, also show:

```text
Next real alarm: {real fire time} · {countdown}
Cancel Test Alarms
```

### 8.4 Expected-state copy

Each guided preview state must show expected-state copy in plain language.

Examples:

```text
Expected: The Hero should show the Fajr alarm time and the Fajr/Suhoor selector.
Expected: Quiet should appear as the alarm status, not as a third selector option.
Expected: The only active-alarm CTA should be “I’m Awake”.
Expected: After Suhoor is acknowledged, Fajr prayer must not be logged automatically.
Expected: After Fajr begins, show “I’m Awake for Fajr” before “I Prayed Fajr”.
Expected: This issue state should show repair guidance, not Quiet.
```

### 8.5 Hero slot inspector

The Home simulation dock must provide one-tap access to a Hero Slot Inspector.

Required table:

| Slot | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Slot 1 — Location | value | value | yes/no |
| Slot 2 — Morning label | value | value | yes/no |
| Slot 3 — Alarm state/status | value | value | yes/no |
| Slot 4 — Timeline/slider | value | value | yes/no |
| Slot 5 — Supporting copy | value | value | yes/no |
| Slot 6 — Action row | value | value | yes/no |

The inspector must be readable by Omar. Raw enum names may be available only after expanding technical details.

---

## 9. Required Hero state assertions

Every standard scenario must define expected Hero output for all six slots.

The table below provides minimum required assertions. Exact copy may follow the active Hero spec, but the meaning must match.

| Scenario state | Slot 3 — Alarm state/status | Slot 4 — Timeline/slider | Slot 5 — Supporting copy | Slot 6 — Action row |
| --- | --- | --- | --- | --- |
| Active Fajr planning | Fajr alarm time | Enabled Fajr timeline | Wake time relative to Fajr end | `[ Suhoor | Fajr ]` |
| Active Suhoor planning | Suhoor alarm time | Enabled Suhoor timeline | Wake time relative to Fajr begins | `[ Suhoor | Fajr ]` |
| Quiet Fajr | `Quiet` | Saved Fajr time visible but inactive/quieted | Saved alarm time + will not ring this morning | `[ Suhoor | Fajr ]` |
| Quiet Suhoor | `Quiet` | Saved Suhoor time visible but inactive/quieted | Saved alarm time + will not ring this morning | `[ Suhoor | Fajr ]` |
| Global Pause | `Alarms paused` | Saved purpose time visible but paused/ghosted | Wake alarms stay off until resumed | `[ Suhoor | Fajr ]` |
| Ring this/tomorrow only | `Rings this morning only` or `Rings tomorrow only` | Active one-morning timeline | Global pause remains after this morning | `[ Suhoor | Fajr ]` |
| Alarm setup issue | Clear issue label | Timeline disabled or repair state | Repair guidance | Repair CTA, not Quiet |
| Primary alarm active | `Time to wake` | Active wake-session state | Tap when you are awake | purpose-specific `[ I’m Awake for Suhoor/Fajr ]` |
| Follow-up pending | next pending wake-check time or `Next alarm soon` | Follow-up countdown/sequence state | Next alarm time/countdown | purpose-specific `[ I’m Awake for Suhoor/Fajr ]` |
| System dismissal advanced to next attempt | next pending wake-check time or `Next alarm soon` | Remaining valid checks stay scheduled | Current attempt dismissed without wake confirmation | same purpose-specific awake CTA remains available |
| In-app awake acknowledged | `You’re awake` | Remaining alarms cancelled | Confirmed in Subh | checked awake state / next valid CTA |
| Suhoor acknowledged | `You’re awake for Suhoor` | Suhoor session complete | Fajr begins at calculated time | context-card fast completion prompt after Maghrib when eligible |
| Fast completion logged | fasting status visible where specified | no alarm mutation | Fast completion record captured when eligible | checked fasting state or next valid CTA |
| Fajr begins after Suhoor | `Fajr has begun` or Fajr wake/check status | Fajr window timeline | Fajr ends at calculated time | `[ I’m Awake for Fajr ]` unless already acknowledged |
| Fajr wake confirmed | `You’re awake for Fajr` | Fajr window timeline | Prayer confirmation available/soon | no Hero logging CTA; context-card shows `[ I Prayed Fajr ]` after cooldown |
| Fajr prayer logged | `Fajr complete` or checked state | Fajr complete state | Logged for this test morning | checked `I Prayed Fajr` state |
| Fajr window ended | Next relevant morning or ended state | Next morning timeline | Handoff to next morning | Planning selector for next morning |

Required negative assertion:

```text
No standard Hero scenario may show Quiet inside the Fajr/Suhoor selector.
No standard Hero scenario may show Pause inside the Fajr/Suhoor selector.
No active alarm scenario may show Stop checks.
No standard normal scenario may show No time available.
```

---

## 10. Day Detail, Next 7, Month, and Weekly Fajrcast simulation

### 10.1 Cross-surface rule

All surfaces must consume the same canonical resolved morning state.

Required surfaces:

```text
Home Hero
Day Detail
Next 7 Mornings
Month Planning
Weekly Fajrcast
Scheduler preview
Morning Log preview
Diagnostics
```

Forbidden:

```text
Home says Quiet but Day Detail says Active
Next 7 shows Quiet as a middle-lane tag
Month invents a different alarm state
Weekly Fajrcast mutates Quiet/Pause state
Scheduler schedules an alarm for Quiet
Logs treat Quiet as missed Fajr
```

### 10.2 Inspect All Surfaces flow

From Home simulation dock and the Wake Session Lab status card, provide:

```text
Inspect All Surfaces
```

This opens a consistency review:

```text
Resolved scenario summary
Home Hero expected/actual
Day Detail expected/actual
Next 7 row expected/actual
Month row expected/actual
Weekly Fajrcast expected/actual
Scheduler expected/actual
Morning Log expected/actual
```

### 10.3 Row-display assertions

For Next 7 and Month rows:

- middle lane is opportunity/context tags only;
- Quiet/Paused/Rings once/setup issue appear in trailing status;
- routine state tags are not shown in the middle lane.

Forbidden middle-lane tags:

```text
[Fajr]
[Suhoor]
[Quiet]
[Paused]
[Fasting]
```

Examples:

| State | Middle lane | Trailing status |
| --- | --- | --- |
| Ordinary active Fajr | empty or context only | alarm time |
| Quiet Fajr | context only | Quiet |
| Paused Suhoor | context only | Paused |
| Ring tomorrow only | context only | Rings tomorrow only |
| Eid / fasting unavailable | Fasting unavailable / Eid context | alarm status if applicable |
| White Days Suhoor opportunity | White Days context | alarm time / Quiet / Paused as applicable |

### 10.4 Day Detail assertions

Day Detail must show:

```text
Wake purpose selector: Suhoor | Fajr
Alarm-state control: active / Quiet / Alarms paused / Rings this morning only / issue
Calculated times
Timeline
Relevant action/log states
```

Forbidden:

```text
Pre-Fajr | Fajr | Quiet selector
Quiet as wake purpose
Pause as wake purpose
```

---

## 11. Scenario library

The harness must include the following scenario library. The UI may group scenarios into packs, but the scenarios must be available and testable.

### 11.1 Plan & Preview scenarios

| ID | Scenario | Purpose | Must prove |
| --- | --- | --- | --- |
| P1 | Active Fajr ordinary morning | Normal Fajr planning | Time available; Fajr alarm shown; selector only Fajr/Suhoor |
| P2 | Active Suhoor fasting-capable morning | Normal Suhoor planning | Suhoor alarm shown; Fajr begins shown; selector only Fajr/Suhoor |
| P3 | Switch Fajr → Suhoor | Purpose mutation | Purpose changes; alarm state preserved; times recalculate |
| P4 | Switch Suhoor → Fajr | Purpose mutation | Purpose changes; alarm state preserved; times recalculate |
| P5 | Slider adjustment | Schedule mutation | Old alarms cancelled; new times scheduled; no duplicates |

### 11.2 Quiet scenarios

| ID | Scenario | Purpose | Must prove |
| --- | --- | --- | --- |
| Q1 | Active Fajr → Quiet | One-morning suppression | Hero shows Quiet; Fajr purpose preserved; no alarm scheduled |
| Q2 | Active Suhoor → Quiet | One-morning suppression | Hero shows Quiet; Suhoor purpose preserved; no alarm scheduled |
| Q3 | Quiet → Turn alarm on | Clear Quiet | Active alarm returns for same purpose |
| Q4 | Quiet + switch Fajr/Suhoor | Preserve Quiet while purpose changes | Quiet remains; saved/displayed time updates by purpose |
| Q5 | Quiet while global Pause active | Override persistence | Manual Quiet survives resume |
| Q6 | Quiet unavailable after first alarm begins | Active execution boundary | Quiet control not exposed; only wake acknowledgement path |
| Q7 | Quiet logs | Logging semantics | quiet/test status, not missed prayer/fast/delivery failure |

### 11.3 Pause scenarios

| ID | Scenario | Purpose | Must prove |
| --- | --- | --- | --- |
| PA1 | Global Pause Fajr | Pause display | Hero shows Alarms paused; saved Fajr alarm visible but off |
| PA2 | Global Pause Suhoor | Pause display | Hero shows Alarms paused; saved Suhoor alarm visible but off |
| PA3 | Pause → Ring tomorrow only | One-morning exception | Target morning rings; global pause remains active |
| PA4 | Clear ring-once exception | Return to inherited pause | State returns to paused, not Quiet |
| PA5 | Pause → Resume | Resume behavior | Inherited paused days become active; manual Quiet remains Quiet |
| PA6 | Pause during active wake execution | Boundary behavior | Does not retroactively relabel current active wake as Quiet |
| PA7 | Pause logs | Logging semantics | pausedInherited/ringOnce state, not missed prayer |

### 11.4 Wake execution scenarios

| ID | Scenario | Purpose | Must prove |
| --- | --- | --- | --- |
| W1 | Fajr primary alarm active | Active execution UI | Slot 6 shows only `I’m Awake` |
| W2 | post-Suhoor Fajr slider activation pending | Follow-up UI | Next alarm time visible; `I’m Awake` cancels remaining |
| W3 | Fajr in-app acknowledgement | In-app wake confirmation | acknowledgedBy = inAppButton; checks cancelled |
| W4 | Fajr system dismissal without explicit awake confirmation | System wake confirmation | acknowledgedBy = systemAlarmDismiss; checks cancelled where supported |
| W5 | Fajr no response | No response | endedNoResponse test status; not Quiet |
| W6 | Wake too close to cutoff | Boundary | No illegal follow-up alarms scheduled |
| W7 | Setup issue during active plan | Reliability | Issue is shown as issue, not Quiet |

### 11.5 Suhoor → Fajr handoff scenarios

| ID | Scenario | Purpose | Must prove |
| --- | --- | --- | --- |
| S1 | Suhoor alarm → I’m Awake | Suhoor wake | Suhoor wake logged; Fajr wake not yet logged |
| S2 | Suhoor awake → I completed my fast today? ✓ ✕ | Fasting status | Fast completion logged separately; no fast completion |
| S3 | Suhoor awake → Fajr begins | Handoff | `I’m Awake for Fajr` appears before `I Prayed Fajr` |
| S4 | Fajr wake confirmed → I Prayed Fajr | Prayer path | Fajr wake and Fajr prayer are separate |
| S5 | Suhoor awake but fasting not logged | Missing fasting action | Fajr path still works; fasting not assumed |
| S6 | Suhoor not acknowledged → Fajr begins | Unconfirmed Suhoor | App does not assume Suhoor wake; Fajr wake path remains available as specified |
| S7 | Fajr prayer not logged before Fajr end | Incomplete morning | Handoff/next morning behavior is correct; no false completion |

### 11.6 Date-context scenarios

| ID | Date context | Must prove |
| --- | --- | --- |
| D1 | Ordinary non-Ramadan morning | Normal timing and tags |
| D2 | Ramadan morning | Suhoor planning and fasting context |
| D3 | Monday fasting opportunity | Opportunity tag rules; no routine-state tags |
| D4 | Thursday fasting opportunity | Opportunity tag rules; no routine-state tags |
| D5 | White Days | Context tag rules; Suhoor support |
| D6 | Eid / fasting unavailable | Fasting unavailable appears as context; fasting CTA suppressed when appropriate |
| D7 | Very early Fajr season | Timeline remains readable; alarm time available |
| D8 | Very late Fajr season | Timeline remains readable; alarm time available |
| D9 | DST spring transition | Correct local time calculation; no duplicate/missing alarm confusion |
| D10 | DST fall transition | Correct local time calculation; no ambiguous alarm display |
| D11 | Timezone/location change | Recalculation and display stay coherent |
| D12 | Missing location | Dedicated issue state, not normal scenario |
| D13 | Missing prayer times | Dedicated issue state, not normal scenario |
| D14 | Past morning | No invalid future scheduling; logs/history state only |
| D15 | Today/this morning | Current-morning logic |
| D16 | Tomorrow | Planning logic |
| D17 | Future inside planning horizon | Planning row/detail logic |
| D18 | Future outside planning horizon | Disabled/limited planning logic as specified |

### 11.7 Cross-surface scenarios

| ID | Scenario | Must prove |
| --- | --- | --- |
| C1 | Quiet Suhoor tomorrow | Home, Detail, Next 7, Month, Scheduler, Logs agree |
| C2 | Paused Fajr tomorrow | Home, Detail, Next 7, Month, Scheduler, Logs agree |
| C3 | Ring tomorrow only while paused | Exception appears only on target date |
| C4 | Ramadan Suhoor handoff | Home and Detail agree on separate Suhoor/Fajr facts |
| C5 | Permission issue | All surfaces show issue/repair, not Quiet |
| C6 | Pricing/free gate check | Current wake actions remain available |

---

## 12. Real Alarm Test

### 12.1 Purpose

Real Alarm Test validates actual device behavior.

It must be explicit, safe, and easy to understand.

Title:

```text
Real Alarm Test
Schedule real test alarms on this iPhone.
```

Warning copy:

```text
These alarms will actually ring. Follow-up alarms stay 5 minutes apart.
```

### 12.2 Real Alarm Test cards

Required cards:

```text
Fajr Alarm Test
Suhoor Alarm Test
System Dismissal Test
Cancel Remaining Alarms Test
```

Each card must show:

```text
Real alarms: Yes
Estimated duration
Primary starts in {delay}
Follow-up spacing: 5 minutes
Sequence length
```

### 12.3 Setup wizard

Real Alarm Setup must use a short wizard or single focused setup screen.

Required fields:

```text
Scenario
Start delay
Sequence length
Sound
Mapped schedule preview
```

#### Scenario options

```text
Fajr alarm test
Suhoor alarm test
System dismissal test
Cancel remaining alarms test
```

#### Start delay options

Default:

```text
90 seconds
```

Allowed:

```text
1.5 seconds
90 seconds
120 seconds
```

#### Sequence length options

```text
Primary only
Primary + 1 follow-up alarm
Primary + 2 follow-up alarms
Primary + 3 follow-up alarms
Primary + 4 follow-up alarms
Primary + 5 follow-up alarms
```

Default:

```text
Primary + 5 follow-up alarms
```

#### Sound field

Show actual selected sound if available:

```text
Sound: {current alarm sound}
```

Fallback copy:

```text
Sound: Default test sound
```

Sound unavailable issue copy:

```text
Sound issue: selected asset unavailable. Test will use fallback sound.
```

### 12.4 Mapped schedule preview

The setup screen must show both simulated and real schedules before scheduling.

Example:

```text
Simulated schedule
Primary alarm        4:30 AM
Follow-up alarm 1   4:35 AM
Follow-up alarm 2   4:40 AM
Follow-up alarm 3   4:45 AM
Follow-up alarm 4   4:50 AM
Follow-up alarm 5   4:55 AM

Real alarm schedule
Primary alarm        2:15 PM
Follow-up alarm 1   2:20 PM
Follow-up alarm 2   2:25 PM
Follow-up alarm 3   2:30 PM
Follow-up alarm 4   2:35 PM
Follow-up alarm 5   2:40 PM
```

If a follow-up is omitted due to cutoff, show:

```text
Follow-up alarm 4 omitted: beyond Fajr cutoff.
```

Do not silently omit scheduled events.

### 12.5 Confirmation sheet

Before scheduling:

```text
Schedule real test alarms?

These alarms will ring on this iPhone. Follow-up alarms remain 5 minutes apart.

Scenario: {scenario}
Sequence: {sequence length}
Primary real fire time: {time}
Sound: {sound}

[Cancel]
[Schedule Test Alarms]
```

The confirmation must provide access to full mapped times.

### 12.6 Mapping rule

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

Default anchor:

```text
Primary alarm
```

Default mapping:

```text
R_primary = real now + 90 seconds
R_followUp1 = R_primary + 5 minutes
R_followUp2 = R_primary + 10 minutes
R_followUp3 = R_primary + 15 minutes
R_followUp4 = R_primary + 20 minutes
R_followUp5 = R_primary + 25 minutes
```

### 12.7 Follow-up spacing rule

Real Alarm Test must preserve production follow-up spacing:

```text
5 minutes
```

Forbidden in Real Alarm Test:

```text
1-minute follow-ups
2-minute follow-ups
compressed spacing
unlabelled speed mode
```

Preview Home UI may use instant state jumps because no real alarms ring.

### 12.8 System dismissal behavior

For the reconciled June 1 model, explicit system / AlarmKit dismissal must be tested as dismissal of the current attempt only unless the dismissal surface explicitly maps to an awake-confirmation action.

Required expected behavior where the platform provides a dismissal callback:

```text
system alarm dismissed
→ current attempt dismissed
→ dismissalSource = systemAlarmDismiss
→ remaining follow-up alarms stay scheduled when the window allows
→ Home updates to the next pending wake-check time
→ test log records dismissal without wake acknowledgement
```

If the platform does not provide enough callback information in a given build/environment, the Real Alarm Test must report this clearly in Diagnostics and provide a debug-only manual event injection under Diagnostics:

```text
Simulate system dismissal callback
```

The manual injection is for platform callback testing only and must not be visible in production.

### 12.9 Real Alarm Test active dock

During Real Alarm Test, the Home simulation dock must show:

```text
REAL TEST ALARMS SCHEDULED
Next real alarm: {time} · {countdown}
Simulated event: {primary/follow-up} at {simulated time}
Sequence: {primary + N}
[Cancel Test Alarms]
[Inspect Schedule]
[Exit Test Mode]
```

`Cancel Test Alarms` must always be visible or one tap away.

---

## 13. Scheduler and log assertions

### 13.1 Quiet scheduler assertions

When a morning is Quiet:

```text
No primary alarm scheduled
No follow-up alarms scheduled
No Wake Session starts
Saved purpose-specific alarm time remains available for display
quiet/test status may be recorded if system records state
No missed Fajr inferred
No missed fast inferred
No delivery failure inferred
```

### 13.2 Pause scheduler assertions

When global Pause is active:

```text
No inherited paused morning schedules alarms
Saved plans remain
Manual Quiet remains after resume
Ring-once exception schedules only target morning
Clearing ring-once returns target morning to inherited Pause
Resume does not wipe manual Quiet
```

### 13.3 Active wake assertions

When wake execution is active:

```text
Primary alarm scheduled
Follow-up alarms scheduled only within cutoff
I’m Awake cancels remaining follow-ups
System dismissal without explicit awake confirmation cancels remaining follow-ups where supported
No response records endedNoResponse/test equivalent
No response does not become Quiet
```

### 13.4 Setup/issue assertions

When setup fails:

```text
Permission blocked does not become Quiet
Location missing does not become Quiet
Prayer times missing does not become Quiet
Delivery failure does not become Quiet
Issue states show repair guidance
Issue states do not mutate wake purpose
```

### 13.5 Test log requirements

Every test-created event must be marked test-only.

Required log/event fields:

```text
isTest
simulationID
scenarioID
timestampReal
simulatedTimestamp
wakePurpose
alarmState
executionState
eventType
acknowledgedBy, when applicable
sourceSurface
```

Required event examples:

```text
scenarioStarted
timesCalculated
homePreviewOpened
quietApplied
quietCleared
globalPauseApplied
ringOnceApplied
primaryAlarmScheduled
followUpScheduled
primaryAlarmFired
followUpAlarmFired
awakeAcknowledgedInApp
awakeAcknowledgedFromSystemDismissal
remainingFollowUpsCancelled
suhoorWakeAcknowledged
fastingTodayConfirmed
fajrWakeAcknowledged
fajrPrayerLogged
noResponseRecorded
setupIssueShown
scenarioExited
testAlarmsCancelled
```

Forbidden automatic event records:

```text
fajrMissed because Quiet was selected
fastMissed because Quiet was selected
fastCompletionConfirmed from fasting intent
fajrPrayerLogged from Suhoor wake acknowledgement
```

---

## 14. Diagnostics

### 14.1 Purpose

Diagnostics are for troubleshooting and confirmation, not for the primary testing journey.

Title:

```text
Diagnostics
Use these when a test does not behave as expected.
```

Default sections:

```text
Hero Slot Inspector
Time Inspector
Surface Consistency
Scheduled Test Alarms
Test Event Log
Permission / Setup Simulation
Reset Test Mode
Advanced Technical Details
```

All diagnostic sections except active warnings should be collapsed by default.

### 14.2 Time Inspector

The Time Inspector is required in v4.

It must show:

```text
Simulated now
Time zone
Location
Prayer-time source
Fajr begins
Fajr ends / sunrise boundary
Selected purpose
Saved Fajr alarm time
Saved Suhoor alarm time
Resolved displayed alarm time
Primary alarm time
Follow-up alarm times
Cutoff boundary
Omitted follow-up reasons
Real mapped fire times, if applicable
```

It must show whether standard time validation passed:

```text
Time validation: Passed
```

or:

```text
Time validation: Failed · {reason}
```

### 14.3 Surface Consistency inspector

Required table:

| Surface | Expected state | Actual state | Pass? |
| --- | --- | --- | --- |
| Home Hero | value | value | yes/no |
| Day Detail | value | value | yes/no |
| Next 7 row | value | value | yes/no |
| Month row | value | value | yes/no |
| Weekly Fajrcast | value | value | yes/no |
| Scheduler | value | value | yes/no |
| Morning Log | value | value | yes/no |
| Entitlement gate | value | value | yes/no |

### 14.4 Scheduled Test Alarms

Fields:

```text
identifier
role: primary | followUp
wakePurpose: Fajr | Suhoor
simulatedFireDate
mappedRealFireDate
channel: fake | AlarmKit | notification
status: pending | fired | cancelled | failed
isTest
scenarioID
```

Actions:

```text
Refresh
Cancel selected
Cancel all test alarms
Copy schedule report
```

Production alarms and test alarms must be clearly distinguished.

### 14.5 Permission / Setup Simulation

Options:

```text
AlarmKit unavailable
AlarmKit denied
Notification denied
Sound missing
Location missing
Prayer calculation failure
Schedule failure
Duplicate identifier
Mismatched fire date
```

These simulations must not alter real iOS settings.

### 14.6 Reset Test Mode

Required safety actions:

```text
Cancel all test alarms
Clear active simulation
Clear test wake sessions
Clear test logs
Exit test mode
```

When any real mapped alarm is scheduled, `Cancel all test alarms` must be prominent.

---

## 15. Safety and data isolation

### 15.1 Test visibility

When simulation is active, Subh must visibly show:

```text
TEST MODE ACTIVE
```

When real mapped alarms are scheduled, Subh must visibly show:

```text
REAL TEST ALARMS SCHEDULED
```

### 15.2 Test data isolation

Test data must not pollute real records.

Test-created records must not count toward:

```text
real Fajr prayer history
real fasting history
streaks
qada ledgers
Ramadan summaries
production analytics
paid history surfaces
behavior-shaping insights
```

### 15.3 Test identifiers

All test scheduled events must be namespaced.

Example:

```text
test.wakeSession.{simulationID}.primary
test.wakeSession.{simulationID}.followUp.1
test.wakeSession.{simulationID}.followUp.2
```

Test identifiers must not collide with production identifiers.

### 15.4 No real settings mutation

Test scenarios must not permanently mutate:

```text
real location
real prayer calculation settings
real Hijri adjustment
real default wake settings
real future plans
real paid entitlement
real production MorningLogs
real analytics
```

### 15.5 Exit behavior

Exiting Test Mode must:

1. cancel all mapped real test alarms;
2. cancel all pending fake/notification test alarms;
3. clear active simulation context;
4. restore Home to real resolved morning;
5. preserve real user settings and logs;
6. retain test logs only in internal/debug storage if useful;
7. never copy test confirmations into real worship history.

---

## 16. Build and access model

| Build mode | Harness availability | Intended user |
| --- | --- | --- |
| Debug/local developer build | Fully available | Omar / developer |
| Internal TestFlight build | Available behind explicit internal flag | Omar / trusted testers |
| App Store production build | Not available | Public users |

Production builds must not expose:

```text
Wake Session Lab
Preview Home UI controls
Home Simulation dock
fake time controls
scenario launcher
real test alarm controls
fake scheduler controls
test log editing
manual event injection
permission simulation controls
```

Production code may retain safe dependency-injection seams, but unsafe controls must not be visible.

---

## 17. Automated test requirements

### 17.1 Unit tests

Required tests:

```text
resolver separates WakePurpose from AlarmState
Quiet is not a wake purpose
Pause is not a wake purpose
Quiet applies to one morning only
Pause applies globally until resumed
ring-once exception overrides pause only for target morning
manual Quiet survives pause/resume
standard scenarios calculate times
standard scenarios never produce No time available
Fajr alarm/follow-up schedule math
Suhoor alarm/follow-up schedule math
cutoff behavior
no follow-up after cutoff
Quiet prevents scheduling
Pause prevents inherited scheduling
ring-once schedules target date only
system dismissal without explicit awake confirmation records source
in-app acknowledgement records source
acknowledgement cancels remaining follow-ups
Suhoor wake acknowledgement does not log Fajr wake
Fast completion prompt logs completion only after Maghrib eligibility
Fajr prayer logging is separate from Fajr wake acknowledgement
setup issue does not become Quiet
row middle-lane tags exclude Fajr/Suhoor/Quiet/Paused/Fasting
core current-morning actions are free
```

### 17.2 Integration tests

Required tests:

```text
ActiveSimulationContext feeds canonical resolver
Home consumes simulated resolved snapshot
Day Detail consumes same simulated resolved snapshot
Next 7 consumes same simulated resolved snapshot
Month consumes same simulated resolved snapshot
Weekly Fajrcast remains inspection-only
scheduler responds to Quiet/Pause/ring-once
test logs marked isTest
exit test mode restores real Home state
Real Alarm mapping plan generation
primary only through primary + 5 mapping
mapped playback preserves five-minute deltas
cancel all test alarms clears mapped alarms
surface consistency inspector detects mismatch
```

### 17.3 UI / snapshot tests

Required UI states:

```text
Wake Session Lab default screen
active test status card
Preview Home UI scenario cards
Quiet & Pause pack
Custom Test Builder collapsed
Custom Test Builder expanded
scenario review sheet with times
Home test banner
Home simulation dock collapsed
Home simulation dock expanded
Hero Slot Inspector
Time Inspector
Surface Consistency inspector
Real Alarm Test setup
Real alarm confirmation sheet
Scheduled Test Alarms inspector
Test Event Log
Reset Test Mode
```

Required Hero snapshots:

```text
Active Fajr planning
Active Suhoor planning
Quiet Fajr
Quiet Suhoor
Paused Fajr
Paused Suhoor
Ring tomorrow only
Alarm setup issue
Primary alarm active
Follow-up pending
System dismissal advanced to next attempt
In-app awake acknowledged
Suhoor awake
Fast completion logged
Fajr begins after Suhoor
Awake for Fajr
Fajr prayer logged
Fajr window ended / next morning handoff
```

### 17.4 End-to-end scenario tests

Required E2E simulated tests:

```text
Quiet Suhoor tomorrow across Home/Detail/Next7/Month/Scheduler/Logs
Paused Fajr with ring-once exception
Manual Quiet preserved after pause/resume
Suhoor wake → Fajr transition → Fajr wake/prayer → after-Maghrib fast completion
System dismissal → source captured → next follow-up shown unless explicit awake confirmation
No response → endedNoResponse → no Quiet mutation
Missing prayer times → issue state only
Eid fasting unavailable → no fasting CTA
DST date → valid calculated times and no No time available placeholder
```

---

## 18. Personal QA checklist for Omar

### 18.1 Preview Active Fajr

1. Open `Wake Session Lab`.
2. Open `Preview Home UI`.
3. Choose `Active Fajr Morning`.
4. Confirm the card shows Fajr begins, Fajr ends, and the Fajr alarm time.
5. Tap `Preview on Home`.
6. Confirm `TEST MODE ACTIVE` appears.
7. Confirm the Hero shows an actual alarm time, not `No time available`.
8. Confirm Slot 6 shows only `[ Suhoor | Fajr ]` before execution.
9. Use `Next State` through primary alarm, follow-up pending, awake confirmed, prayer ready, and prayer logged.
10. Open `Inspect Surfaces` and confirm all surfaces agree.
11. Exit Test Mode.

### 18.2 Preview Quiet and Pause

1. Open `Quiet & Pause Pack`.
2. Preview `Quiet Fajr`.
3. Confirm Quiet is in the alarm-state/status area, not in the purpose selector.
4. Confirm saved Fajr time is still visible.
5. Confirm scheduler preview shows no primary/follow-up alarms.
6. Preview `Alarms Paused`.
7. Confirm saved alarm time is visible but paused/ghosted.
8. Preview `Ring Tomorrow Only`.
9. Confirm only the target morning rings while global Pause remains active.
10. Preview `Quiet Preserved After Resume`.
11. Confirm manual Quiet survives Pause → Resume.

### 18.3 Preview Suhoor → Fajr handoff

1. Open `Suhoor → Fajr Handoff`.
2. Confirm Suhoor alarm time and Fajr begins/end times are shown.
3. Preview on Home.
4. Tap or step to `I’m Awake` for Suhoor.
5. Confirm Fajr wake is not automatically confirmed.
6. Jump to after Maghrib and answer the fast completion check/X prompt if eligible.
7. Jump to Fajr begins.
8. Confirm the Hero shows `I’m Awake for Fajr` before `I Prayed Fajr`.
9. Confirm `I Prayed Fajr` logs only Fajr prayer.
10. Open Diagnostics → Test Event Log and confirm separate events.

### 18.4 Run Real Alarm Test

1. Open `Run Real Alarm Test`.
2. Select `Fajr Alarm Test` or `Suhoor Alarm Test`.
3. Confirm real and simulated schedules are shown.
4. Choose `Primary + 1` for a short test or `Primary + 5` for a full test.
5. Confirm follow-up spacing is five minutes.
6. Schedule test alarms.
7. Confirm the real-alarm warning sheet.
8. Let the primary alarm ring.
9. Test either system dismissal or in-app `I’m Awake`.
10. Confirm remaining follow-ups are cancelled after acknowledgement.
11. Open Diagnostics → Scheduled Test Alarms.
12. Confirm no stale test alarms remain.
13. Exit Test Mode.

### 18.5 Test time availability

For any standard scenario:

1. Confirm the card shows actual calculated times.
2. Confirm the review sheet shows actual calculated times.
3. Confirm the Home dock shows actual calculated times.
4. Confirm the Hero shows actual alarm/time context.
5. If `No time available` appears in a normal scenario, mark the scenario as failed.

---

## 19. Physical-device QA matrix

| Test | Required? | Notes |
| --- | ---: | --- |
| AlarmKit authorization prompt | Yes | Real device only |
| Primary alarm audible | Yes | Test selected sound/fallback |
| Lock Screen presentation | Yes | Confirm title/actions |
| App backgrounded | Yes | Alarm should still fire |
| App terminated | Yes | Verify platform-supported behavior |
| System dismissal callback | Yes | Must record source if callback available |
| System dismissal advances to next follow-up unless explicit awake confirmation | Yes | Current MVP model |
| In-app `I’m Awake` cancels follow-ups | Yes | Core behavior |
| Five-minute follow-up spacing | Yes | No compressed spacing |
| Silent mode | Yes | Confirm actual behavior |
| Focus mode | Yes | Confirm actual behavior |
| Permission denial | Yes | Issue/repair state, not Quiet |
| Sound missing fallback | Yes | No crash/silent failure |
| Timezone change | Recommended | Verify recalculation and no stale state |
| Reboot with scheduled alarm | Recommended before launch | Harder but valuable |

---


### May 31 required scenario pack

The harness must include a named scenario pack such as `May 31 Morning State Walkthrough — Toronto` with these presets and branches:

| Scenario | Simulated moment / branch | Expected verification |
| --- | --- | --- |
| MSF-001 | May 31 daytime planning | Hero shows `Tomorrow Morning`; Fajr default; context and Next 7 row match current plan. |
| MSF-002 | Evening same day | No unnecessary state change from daytime planning. |
| MSF-003 | 11:59 PM → 12:00 AM | Label rolls from `Tomorrow Morning` to `Today Morning`; plan preserved. |
| MSF-004 | Suhoor window starts | Window start derived from last third of night; not hard-coded. |
| MSF-005 | During Suhoor window before cutoff | Switching into Suhoor allowed if session can be valid. |
| MSF-006 | Fajr begins minus 6 minutes | Last valid new Suhoor scheduling moment. |
| MSF-007 | Fajr begins minus 5 minutes | Too late to newly schedule Suhoor. |
| MSF-008 | Suhoor acknowledgement | Remaining Suhoor checks cancel; no automatic Fajr wake-check session. |
| MSF-009 | Fajr begins after Suhoor | Single Fajr-start event, no wake checks by default. |
| MSF-010 | Slider-activated Fajr wake checks after Suhoor | User opts in; normal Fajr wake checks are generated. |
| MSF-011 | Fajr wake default | 30/25/20/15/10/5-minute attempts before Fajr end. |
| MSF-012 | Fajr wake moved later | Wake checks compress naturally. |
| MSF-013 | Fajr end | Hero rolls to next morning. |
| MSF-014 | Late Fajr log same day | Prompt inside context-card action area says `I prayed Fajr earlier today? ✓ ✕`. |
| MSF-015 | Late Fajr log after midnight | Prompt says `I prayed Fajr yesterday morning? ✓ ✕`. |
| MSF-016 | Late prompt expiry | Prompt disappears when next relevant wake window begins. |
| MSF-017 | Next 7 row layout | Left time/Quiet + date; middle purpose line + tags; right Quiet toggle. |
| MSF-018 | Next 7 Quiet toggle | Toggle mutates only one-morning Quiet. |
| MSF-019 | Active-session Quiet cancellation | Confirmed cancellation cancels checks and does not log awake/prayed facts. |
| MSF-020 | DST/high-latitude backlog | Scenarios listed but may remain exploratory until prayer-time engine supports stable fixtures. |

### Scrubber requirements

The scenario player must provide:

- a 24-hour scrubber, preferably extendable to 48 hours;
- minute-by-minute stepping;
- jump-to-boundary buttons;
- visible calculated times for location, Fajr begins, Fajr ends, Suhoor window start, latest wake time, latest new-session time, and generated attempts;
- branch controls that let Omar tap or skip CTAs and continue the simulation from that branch;
- a clear reset branch button so the same scenario can be re-run from a known state.

The preview must not show `No time available` when the scenario fixture has valid prayer-time data.

## 20. Acceptance criteria

### 20.1 UX acceptance

- [ ] Omar sees only three top-level sections: Preview Home UI, Real Alarm Test, Diagnostics.
- [ ] Preview Home UI is the default.
- [ ] Scenario cards are plain-language and self-explanatory.
- [ ] Scenario cards show purpose, alarm state, date context, calculated times, real-alarm status, estimated test time, and primary action.
- [ ] The interface does not overload Omar with subsystem names by default.
- [ ] Advanced controls are collapsed.
- [ ] Typography and buttons are readable and tappable.
- [ ] The Home simulation dock does not obscure the Hero.
- [ ] The dock always shows simulated date/time and calculated prayer/alarm times.
- [ ] Expected-state copy tells Omar what to look for.
- [ ] Exit Test Mode is always visible.
- [ ] Cancel Test Alarms is prominent when real alarms are scheduled.

### 20.2 Time acceptance

- [ ] Every standard scenario pre-calculates Fajr begins/end and alarm time.
- [ ] Every standard scenario blocks launch if time calculation fails.
- [ ] Standard scenarios do not show `No time available` in the Hero.
- [ ] Missing-time states exist only as explicit issue scenarios.
- [ ] Time Inspector shows calculation source and all relevant times.
- [ ] Real Alarm Test shows both simulated and real mapped times before scheduling.

### 20.3 Product acceptance

- [ ] Wake purpose selector contains only Fajr and Suhoor.
- [ ] Quiet is tested as one-morning alarm-state override.
- [ ] Pause is tested as global indefinite alarm policy.
- [ ] Ring-once exception is tested while Pause remains active.
- [ ] Quiet is unavailable as a primary active wake action after first alarm begins; approved active-session Quiet cancellation may be tested as a confirmed cancellation edge case.
- [ ] Active alarm states show `I’m Awake`, not `Stop checks`.
- [ ] System dismissal is tested as a current-attempt dismissal; it must not cancel remaining follow-ups unless the user explicitly confirms awake.
- [ ] Suhoor wake acknowledgement and Fajr wake acknowledgement are separate.
- [ ] Fast completion and Fajr prayer logging are separate.
- [ ] Quiet/Pause do not create missed-prayer or missed-fast records.
- [ ] Setup/permission issues do not become Quiet.

### 20.4 Cross-surface acceptance

- [ ] Home, Day Detail, Next 7, Month, Weekly Fajrcast, Scheduler, and Logs consume the same resolved state.
- [ ] Next 7 and Month use trailing status for Quiet/Paused/Rings once/issues.
- [ ] Middle-lane tags remain opportunity/context tags only.
- [ ] Weekly Fajrcast remains inspection-only unless the active spec says otherwise.
- [ ] Surface Consistency inspector can show expected vs actual.

### 20.5 Architecture acceptance

- [ ] The harness feeds the canonical resolver path.
- [ ] The harness does not create a second product engine.
- [ ] Test records are marked and isolated.
- [ ] Test identifiers are namespaced.
- [ ] Test scenarios do not mutate real settings.
- [ ] Production builds do not expose the lab or fake controls.

---

## 21. Codex implementation guidance

When implementing this spec, Codex must treat the following as the core v4 scope:

1. Replace the v3 scenario model with the v4 wake-purpose/alarm-state model.
2. Remove Quiet-as-mode and active-session Quiet testing flows.
3. Add full Pause/ring-once testing coverage.
4. Add time validation so standard scenarios always produce calculated times.
5. Ensure Preview Home UI uses the canonical resolver and real view models.
6. Add Hero slot expected/actual inspection.
7. Add cross-surface consistency inspection.
8. Add scenario cards and UI structure according to the tester-first UX doctrine.
9. Add Real Alarm Test schedule preview with simulated and real times.
10. Update tests so they assert the new model and forbid the old one.

Implementation must not:

- expose test controls in production;
- create fake product logic;
- gate current-morning core actions behind paid tiers;
- mutate real logs/settings from test scenarios;
- leave standard scenarios capable of showing `No time available` accidentally.

---

## 22. Final rule

The v4 testing harness exists to make Subh testable without weakening Subh’s product truth.

```text
Real product logic.
Real calculated times by default.
Tester-friendly scenario cards.
Home as the main testing stage.
Deep diagnostics underneath.
Quiet and Pause tested as alarm states/policies, not purposes.
Suhoor and Fajr facts kept separate.
Mapped real AlarmKit tests when explicitly requested.
No accidental No time available states.
No production exposure.
No real-log pollution.
```

---

## June 1 Addendum: Required New Simulation Coverage

The harness must add or verify scenarios for:

1. early Suhoor action shown after midnight before Suhoor window;
2. early Suhoor confirmation preserves Fajr adhan/event;
3. early Fajr action shown after midnight before Fajr begins;
4. early Fajr confirmation silences Fajr adhan/alarm/checks;
5. active Suhoor alarm dismissal without awake confirmation advances Hero time to next check;
6. active Fajr alarm dismissal without awake confirmation advances Hero time to next check;
7. **I’m Awake for Fajr** followed by anti-double-tap cooldown, then **I Prayed Fajr** in context-card action area;
8. late Fajr check/X prompt with yes/no/unrecorded states;
9. fast completion prompt after Maghrib when Suhoor was selected;
10. fast completion prompt after Maghrib on every Ramadan day;
11. optional fasting opportunity with no Suhoor selected does not show fast completion prompt;
12. history row sync where implemented or stubbed;
13. Qada candidate creation only on explicit ✕, not on prompt expiry.

The harness must never treat ordinary system dismissal as wake acknowledgement unless the test explicitly uses a supported awake-confirmation action.

