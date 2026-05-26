# Subh Wake Session Testing and Simulation Harness Spec

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-session-testing-and-simulation-harness-spec-v1.md` |
| Version | 1 |
| Spec status | Draft; proposed canonical testing/specification layer for Wake Sessions and user-device QA |
| Date | 2026-05-26 |
| Owning domain / surface | Developer/internal testing, personal device QA, simulation harness, debug-only Wake Session Lab |
| Related specs | `00-subh-spec-index-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-morning-hero-item-spec-v15.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-pricing-entitlement-spec-v3.md`, `subh-mvp-interaction-inventory-v4.md` |
| Implementation audit status | New spec; not implemented |

---

## 1. Purpose

This spec defines how Subh should be tested comprehensively without requiring the developer/user to wait for real Fajr, real Suhoor, or the next actual morning.

It introduces a debug/internal testing layer called the **Wake Session Lab**.

The Wake Session Lab lets Omar and internal testers simulate Fajr/Suhoor windows, Wake Sessions, Wake Checks, Quiet cancellation, MorningLogs, Hero CTA states, and AlarmKit delivery behavior using controlled test scenarios.

The testing layer must make Subh faster and safer to test while preserving production trust.

---

## 2. Product and testing principle

Subh is a Fajr-centered morning system. Its core job is to help the user resolve, understand, and execute the next meaningful morning.

Testing must respect the same product model:

```text
one morning-resolution engine
one Wake Session model
one delivery pipeline
one Hero snapshot path
one MorningLog record path
```

The testing layer must not create a second product engine.

Instead, it provides controlled inputs to the real engine.

Plain-language principle:

```text
Do not fake the product logic.
Fake the world around it.
```

Meaning:

- fake the current time;
- fake a compressed Fajr window;
- fake a compressed Suhoor window;
- fake scheduler responses;
- fake permission states;
- fake alarm-fired events;
- then let the real resolver, hero state, Wake Session logic, delivery planner, and logs respond.

---

## 3. Goals

The testing harness must allow Omar/internal testers to personally verify:

1. Fajr mode.
2. Suhoor mode.
3. Quiet mode.
4. Wake Sessions.
5. Wake Checks.
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

The user should be able to test most of this in minutes, not days.

---

## 4. Non-goals

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
- advanced wake-check interval/count settings.

This spec may define future hooks, but the MVP implementation must focus on internal/manual testability and core wake reliability.

---

## 5. Testing layers

Subh testing should use five layers.

| Layer | Name | Purpose | Uses real AlarmKit? | Runs on Omar’s iPhone? | Ships publicly? |
| --- | --- | --- | ---: | ---: | ---: |
| 1 | Unit tests | Prove rules and calculations | No | No | No |
| 2 | Fake scheduler integration tests | Prove scheduling/cancellation without platform delivery | No | Optional | No |
| 3 | UI/snapshot state tests | Prove Hero and surface states | No | Optional | No |
| 4 | Wake Session Lab | Personal/internal simulated testing | Optional | Yes | No public access |
| 5 | Physical-device AlarmKit QA | Prove real alarm behavior | Yes | Yes | No, QA only |

The Wake Session Lab sits between automated tests and real-world device QA.

---

## 6. Build and access model

### 6.1 Build modes

The test harness must support three conceptual build modes.

| Build mode | Wake Session Lab availability | Intended user |
| --- | --- | --- |
| Debug/local developer build | Fully available | Omar / developer |
| Internal TestFlight build | Available behind internal flag | Omar / trusted testers |
| App Store production build | Not available | Public users |

### 6.2 Release-build rule

Production App Store builds must not expose:

- Wake Session Lab;
- fake time controls;
- compressed Fajr/Suhoor scenario buttons;
- fake scheduler controls;
- fake log inspector editing;
- simulate alarm fired/stopped buttons;
- test prayer/fast logging that can pollute real logs.

### 6.3 Suggested implementation guard

The visible test UI should be compiled or feature-gated behind development/internal controls such as:

```text
DEBUG build flag
INTERNAL_TESTING build configuration
TestFlight internal feature flag
Developer Mode local override
```

Production builds may keep clean architecture seams such as protocols and injectable dependencies, but must not expose unsafe controls.

---

## 7. Safety rules

### 7.1 Test mode must be visually obvious

When a test scenario is active, Subh must show a visible internal banner:

```text
TEST WAKE SESSION ACTIVE
```

or:

```text
Developer Test Mode
```

The user must never confuse a test morning with a real worship record.

### 7.2 Test data must not pollute real data

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

### 7.3 Test alarm identifiers must be namespaced

All test scheduled events must use deterministic test identifiers.

Example:

```text
test.wakeSession.{sessionID}.primary
test.wakeSession.{sessionID}.check.1
test.wakeSession.{sessionID}.check.2
```

Test identifiers must not collide with production identifiers.

### 7.4 Clear-all safety action is required

The Wake Session Lab must include:

```text
Cancel All Test Alarms
Clear Test Wake Sessions
Clear Test MorningLogs
Reset Test Time
```

This action must cancel test alarms and clear test-only state without altering real user settings or real logs.

### 7.5 Never mutate real settings from a test scenario

Test scenarios must not permanently change:

- real location;
- real prayer calculation method;
- real Hijri adjustment;
- real default wake settings;
- real future plans;
- real paid entitlement;
- real production MorningLogs.

### 7.6 Do not rely on changing the device clock

Testing should not require manually changing iPhone system time.

Preferred approach:

```text
Fake app time for app logic.
Use near-future real times only for actual AlarmKit/device QA.
```

---

## 8. Core testing architecture

### 8.1 Injectable clock

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
- scheduling adapters may still use real time when creating real platform alarms, but must receive already-resolved test fire dates from the test scenario when appropriate.

### 8.2 Prayer window provider / scenario provider

Subh must support test prayer windows without changing real prayer settings.

Conceptual model:

```text
RealPrayerWindowProvider
TestPrayerWindowProvider
```

The TestPrayerWindowProvider can create compressed windows such as:

```text
Fajr begins: now + 1 min
Primary wake: now + 2 min
Fajr ends: now + 8 min
```

or:

```text
Final third begins: now
Primary Suhoor wake: now + 2 min
Fajr begins: now + 8 min
```

### 8.3 Scheduler abstraction

Subh must support both real and fake scheduling.

```text
Real scheduler → AlarmKit/UserNotifications
Fake scheduler → records what would have been scheduled/cancelled
```

The fake scheduler must record:

- scheduled primary alarm IDs;
- scheduled wake-check IDs;
- fire dates;
- cancellation calls;
- stale identifier cancellation;
- permission/failure simulation;
- reconciliation output.

### 8.4 MorningLog store test scope

The MorningLog store must support test records.

Required fields or equivalents:

```text
isTest
scenarioID
wakeSessionID
mode
fireDate
createdAt
confirmedAt
cancelledAt
eventKind
```

Test records must be removable through Wake Session Lab.

---

## 9. Wake Session Lab surface

### 9.1 Location

Preferred internal location:

```text
Settings → Developer → Wake Session Lab
```

Alternative:

```text
Debug menu → Wake Session Lab
```

The lab must not appear in public production builds.

### 9.2 Lab sections

The Wake Session Lab should include these sections:

1. Test Mode Status.
2. Scenario Launcher.
3. Time Controls.
4. Wake Session State.
5. Pending Test Alarms.
6. MorningLog Inspector.
7. Permission / Failure Simulator.
8. Real Device AlarmKit QA Tools.
9. Cleanup / Reset Tools.

### 9.3 Test Mode Status

Display:

```text
Test Mode: Off / Active
Active Scenario: Fajr Wake Checks / Suhoor / Quiet / etc.
Simulated Now: {time}
Real Device Time: {time}
Scheduler Mode: Fake / Real AlarmKit / Real Notifications
Test Records: {count}
Pending Test Alarms: {count}
```

### 9.4 Scenario Launcher

Buttons:

```text
Start Fajr Wake Session Test
Start Suhoor Wake Session Test
Start Quiet Cancellation Test
Start Slider Reschedule Test
Start Alarm Stop vs Awake Test
Start Permission Failure Test
Start Cross-Surface Consistency Test
Start Real AlarmKit Compressed Test
```

### 9.5 Cleanup tools

Buttons:

```text
Cancel All Test Alarms
Clear Test MorningLogs
Clear Test Wake Sessions
Reset Test Clock
Exit Test Mode
```

`Cancel All Test Alarms` must be visually prominent.

---

## 10. Scenario definitions

### 10.1 Scenario A — Fajr Wake Session Test

Purpose:

Test Fajr Wake Session, primary alarm, Wake Checks, awake confirmation, and Fajr prayer CTA.

Compressed timeline:

```text
Now: T
Fajr begins: T + 1 min
Primary wake: T + 2 min
Fajr ends: T + 8 min
Wake check interval: 1 min
Max wake checks: 3
Cutoff: T + 7 min
```

Expected flow:

1. Start scenario.
2. Hero shows Fajr mode and upcoming wake.
3. At or after Fajr begins, CTA becomes available as appropriate.
4. Primary alarm fires at T + 2.
5. User stops alarm.
6. Wake Session remains unconfirmed.
7. Wake check fires at T + 3.
8. User opens app.
9. Hero shows `I’m awake for Fajr`.
10. User taps `I’m awake for Fajr`.
11. Remaining wake checks cancel.
12. Hero transitions to `I prayed Fajr` where eligible.
13. User taps `I prayed Fajr`.
14. MorningLog records awake and prayer separately.

Pass criteria:

- stop alarm does not mark awake;
- `I’m awake for Fajr` cancels remaining checks;
- `I prayed Fajr` is separate from awake confirmation;
- no `fajrMissed` is auto-created.

---

### 10.2 Scenario B — Suhoor Wake Session Test

Purpose:

Test Suhoor wake, fasting intent, wake-check cancellation, and handoff to Fajr prayer.

Compressed timeline:

```text
Now: T
Final third begins: T
Primary Suhoor wake: T + 2 min
Fajr begins: T + 8 min
Wake check interval: 1 min
Max wake checks: 3
Cutoff: T + 7 min
```

Expected flow:

1. Start scenario.
2. Hero shows Suhoor mode.
3. Primary Suhoor alarm fires.
4. User taps `I’m awake for Suhoor`.
5. Remaining Suhoor wake checks cancel.
6. MorningLog records `awakeConfirmedForSuhoor`.
7. MorningLog records `fastingIntentConfirmed`.
8. App does not record `fajrPrayerConfirmed`.
9. App does not record `fastCompletionConfirmed`.
10. After simulated Fajr begins, hero shows `I prayed Fajr` if Suhoor wake was confirmed.

Pass criteria:

- Suhoor confirmation confirms Suhoor wake only;
- fasting intent is confirmed;
- Fajr prayer remains separate;
- fast completion remains future/uncollected;
- no duplicate Wake Session is created.

---

### 10.3 Scenario C — Suhoor Not Confirmed → Fajr Begins

Purpose:

Test the transition when the user did not confirm Suhoor before Fajr begins.

Timeline:

```text
Final third begins: T
Primary Suhoor wake: T + 2 min
Fajr begins: T + 6 min
Fajr ends: T + 12 min
```

Expected flow:

1. User does not confirm `I’m awake for Suhoor`.
2. Suhoor wake expires unconfirmed.
3. Fajr begins.
4. Hero shows `I’m awake for Fajr` first.
5. After user confirms awake for Fajr, hero may show `I prayed Fajr`.

Pass criteria:

- app does not treat unconfirmed Suhoor as confirmed wake;
- app does not mark Fajr missed;
- app provides Fajr path after missed/unconfirmed Suhoor.

---

### 10.4 Scenario D — Quiet During Active Wake Checks

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

---

### 10.5 Scenario E — Slider Reschedule Test

Purpose:

Test schedule cleanup after wake-time adjustment.

Setup:

```text
Fajr Wake Session scheduled
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

---

### 10.6 Scenario F — Alarm Stop vs Awake Confirmation

Purpose:

Test the most important Wake Session rule.

Expected flow:

1. Primary alarm fires.
2. User taps system Stop/dismiss.
3. Wake Session remains unconfirmed.
4. Wake check remains pending.
5. Wake check fires.
6. User opens Subh and taps `I’m awake for Fajr`.
7. Only then is the Wake Session confirmed.

Pass criteria:

```text
Alarm stopped ≠ awake confirmed
```

---

### 10.7 Scenario G — Permission Failure Test

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

---

### 10.8 Scenario H — Real AlarmKit Compressed Test

Purpose:

Test actual physical-device delivery.

Real timeline example:

```text
Primary alarm: now + 2 min
Wake check 1: now + 3 min
Wake check 2: now + 4 min
Wake check 3: now + 5 min
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
- wake checks are cancelled after confirmation.

---

### 10.9 Scenario I — MorningLog Inspector Test

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

---

### 10.10 Scenario J — Cross-Surface Consistency Test

Purpose:

Verify that Home, Next 7 Mornings/Days, Weekly Fajrcast, Day Detail, and delivery agree.

Expected flow:

1. Start Fajr test session.
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

## 11. Time controls

Wake Session Lab may include controlled time movement.

Allowed controls:

```text
Jump to before final third
Jump to final third begins
Jump to before Fajr begins
Jump to Fajr begins
Jump to primary alarm time
Jump to after primary fired
Jump to wake check 1
Jump to wake check 2
Jump to 5 min before cutoff
Jump to after Fajr ends
Return to real time
```

Rules:

- time jumps affect app-domain simulation only;
- time jumps must not change iPhone system time;
- time jumps must not mutate real settings;
- active test time must be shown visibly.

---

## 12. Scheduler modes

Wake Session Lab should support these scheduler modes.

| Mode | Meaning | Use case |
| --- | --- | --- |
| Fake Scheduler | Does not schedule platform alarms; records expected schedule/cancel calls | Fast logic testing |
| Real Notifications | Uses local notifications if available | Fallback/degraded delivery testing |
| Real AlarmKit | Uses AlarmKit on physical device | Final device QA |
| Dry Run | Builds plan but schedules nothing | Safe review/debug |

The default lab scheduler mode should be **Fake Scheduler**.

Real AlarmKit mode should require explicit confirmation.

---

## 13. MorningLog inspector

The Wake Session Lab must include a readable MorningLog inspector.

Recommended display:

```text
WakeSessionID: test-fajr-2026-05-26-1400
Scenario: Fajr Wake Session Test
Mode: Fajr
Status: wakeChecksPending
Primary alarm: scheduled 2:04 PM
Wake checks: 2:05, 2:06, 2:07
Confirmed awake: none
Fajr prayer: unconfirmed
Fasting intent: not applicable
Events:
- 2:00 wakeSessionCreated
- 2:00 primaryAlarmScheduled
- 2:00 wakeCheckScheduled x3
- 2:04 primaryAlarmFired
- 2:04 alarmStopped
```

Actions:

```text
Copy Test Report
Clear Test Logs
Export Debug Summary
```

Export must remain local/user-initiated.

---

## 14. Pending alarm inspector

The lab must show pending test alarms.

Fields:

```text
identifier
role: primary | wakeCheck
mode: Fajr | Suhoor
fireDate
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

## 15. Permission/failure simulator

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

## 16. User-facing personal QA checklist

This section is written for Omar as a tester.

### 16.1 Fajr basic test

1. Open Developer → Wake Session Lab.
2. Tap `Start Fajr Wake Session Test`.
3. Confirm hero shows Fajr state.
4. Wait for primary alarm.
5. Stop the alarm.
6. Confirm app does not mark you awake.
7. Wait for wake check.
8. Tap `I’m awake for Fajr`.
9. Confirm remaining wake checks are cancelled.
10. Tap `I prayed Fajr`.
11. Open MorningLog inspector.
12. Confirm awake and prayer are separate records.

### 16.2 Suhoor basic test

1. Tap `Start Suhoor Wake Session Test`.
2. Confirm hero shows Suhoor state.
3. Wait for primary Suhoor alarm.
4. Tap `I’m awake for Suhoor`.
5. Confirm fasting intent is recorded.
6. Confirm Fajr prayer is not recorded.
7. Jump to Fajr begins.
8. Confirm `I prayed Fajr` appears.

### 16.3 Quiet active-session test

1. Start Fajr test.
2. Let primary alarm fire.
3. Do not confirm awake.
4. Select Quiet.
5. Confirm sheet appears.
6. Tap `Keep wake checks` once.
7. Verify wake checks remain pending.
8. Select Quiet again.
9. Tap `Stop for this morning`.
10. Confirm `quietMorning` is logged.
11. Confirm no missed prayer is auto-logged.

### 16.4 Real-device test

1. Start `Real AlarmKit Compressed Test`.
2. Confirm primary alarm is scheduled within 2 minutes.
3. Lock phone.
4. Wait for alarm.
5. Stop alarm.
6. Confirm wake check still fires.
7. Tap `Open Subh` if available.
8. Tap `I’m awake`.
9. Confirm remaining wake checks are cancelled.

---

## 17. Automated test requirements

### 17.1 Unit tests

Codex should add tests for:

- Fajr wake-check schedule math;
- Suhoor wake-check schedule math;
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

### 17.2 Integration tests

Codex should add tests for:

- Wake Session creation from resolved morning;
- fake scheduler schedule/cancel calls;
- stale test alarm cleanup;
- Hero state from simulated clock;
- MorningLog record sequence;
- rescheduling after slider change;
- cross-surface consistency from one resolved graph.

### 17.3 UI tests / previews

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
- test mode banner.

---

## 18. Physical-device QA matrix

Physical device QA is required for actual delivery confidence.

| Test | Required? | Notes |
| --- | ---: | --- |
| AlarmKit authorization prompt | Yes | Must be tested on real device. |
| Primary alarm audible | Yes | Test normal volume/sound behavior. |
| Wake check after primary stop | Yes | Core Wake Session behavior. |
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

## 19. Production guardrails

Before release, CI or a manual release checklist must verify:

- Wake Session Lab is not visible in production;
- fake scenario buttons are not visible in production;
- fake clock is not active in production;
- test records cannot appear in real history;
- test alarms are not scheduled by default;
- production app does not show `TEST MODE ACTIVE`;
- production code does not default to fake scheduler;
- production code does not use compressed intervals;
- production code uses real prayer windows and real clock;
- production can still cancel stale test alarms if any were accidentally left from internal builds.

---

## 20. Acceptance criteria

### 20.1 Personal testing acceptance

- [ ] Omar can start a Fajr test and complete it within 10 minutes.
- [ ] Omar can start a Suhoor test and complete it within 10 minutes.
- [ ] Omar can test alarm stop vs awake confirmation without waiting until morning.
- [ ] Omar can test Quiet cancellation during active wake checks.
- [ ] Omar can see pending test alarms.
- [ ] Omar can clear all test alarms.
- [ ] Omar can inspect MorningLog records.
- [ ] Omar can run at least one real AlarmKit compressed test on his iPhone.

### 20.2 Architecture acceptance

- [ ] Resolver and Hero can consume injected time in test mode.
- [ ] Fake scheduler can be used without AlarmKit.
- [ ] Real scheduler can be used for compressed device tests.
- [ ] Test records are marked and isolated.
- [ ] Test scenarios do not mutate real settings.
- [ ] Production builds do not expose the lab.

### 20.3 Product acceptance

- [ ] Testing preserves Subh as one Fajr-centered morning system.
- [ ] Testing does not create a second wake engine.
- [ ] Testing does not pollute real worship logs.
- [ ] Testing does not create guilt/judgment records.
- [ ] Testing supports the complete MVP Wake Session loop.

---

## 21. Codex implementation prompt

Use this as the implementation prompt after this spec is accepted.

```text
Implement a debug/internal Wake Session Testing and Simulation Harness for Subh according to `subh-wake-session-testing-and-simulation-harness-spec-v1.md`.

Do not change production wake rules.
Do not expose the Wake Session Lab in App Store production builds.
Do not implement paid features, StoreKit, analytics, adaptive wake checks, household features, or cloud sync.

Implement:
1. Injectable clock/time provider for resolver, Wake Session, Hero state, and MorningLog testing.
2. Test prayer-window/scenario provider for compressed Fajr and Suhoor windows.
3. Fake scheduler adapter that records schedule/cancel/reconciliation calls without platform alarms.
4. Developer/internal Wake Session Lab screen.
5. Scenario buttons:
   - Fajr Wake Session Test
   - Suhoor Wake Session Test
   - Suhoor Not Confirmed → Fajr Begins
   - Quiet During Wake Checks
   - Slider Reschedule Test
   - Alarm Stop vs Awake Confirmation
   - Permission Failure Test
   - Real AlarmKit Compressed Test
6. MorningLog inspector for test records.
7. Pending test alarm inspector.
8. Cancel All Test Alarms / Clear Test Logs safety actions.
9. Production guardrails so test UI is unavailable in release builds.
10. Unit/integration/UI tests covering the scenarios in the spec.

Rules:
- Test sessions must be visibly marked.
- Test records must use `isTest = true` or equivalent.
- Test alarm identifiers must be namespaced.
- Stopping an alarm must not confirm awake.
- Confirming awake must cancel remaining wake checks.
- Suhoor confirmation must set fasting intent but not Fajr prayer or fast completion.
- Quiet must log quietMorning, not missed prayer.
- Permission failure must not become Quiet.
- Real AlarmKit compressed tests must be explicit and cancellable.

After implementation:
- Run targeted tests.
- Provide files changed, tests added, tests run, and known limitations.
```

---

## 22. Open decisions

| Decision | Recommendation |
| --- | --- |
| Should Wake Session Lab be available in internal TestFlight? | Yes, behind explicit internal flag. |
| Should test records be exportable? | Yes, local/manual export only. |
| Should real AlarmKit tests default to compressed 1-minute wake checks? | Yes, only in test mode. |
| Should production include safe diagnostics? | Yes, but not fake time/scenario controls. |
| Should the test harness ship before Wake Sessions? | It can ship alongside Wake Sessions; at minimum, fake scheduler and unit tests should exist before full implementation. |

---

## 23. Final rule

The Wake Session Lab exists to make Subh testable without weakening Subh’s product truth.

```text
Real product logic.
Fake time and fake scenarios.
Clear test labels.
No production exposure.
No real-log pollution.
```

