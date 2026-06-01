## Why

The June 1 active specification package resolves several consequential wake-action and logging ambiguities. Subh must separate explicit wake acknowledgement from ordinary alarm dismissal, keep wake confirmation distinct from Fajr prayer and fast completion logging, show the next pending wake attempt in the Hero, and make early-awake confirmations purpose-specific without creating a parallel wake engine.

## What Changes

- Promote the June 1 active spec package so `00-subh-spec-index-v6.md` is the active root index and superseded pre-June root specs are archived.
- Show active wake CTAs in the Hero as `I’m Awake for Suhoor` and `I’m Awake for Fajr`, and cancel remaining checks only after explicit awake confirmation.
- Prevent `I’m Awake for Fajr` and `I Prayed Fajr` from rendering at the same time by applying a short post-awake cooldown before the prayer action appears in the context-card action area.
- Place logging and early-awake actions in the existing context-card action area, including compact check/X rows for late Fajr and fast completion prompts.
- Add confirmed early-awake paths for Suhoor and Fajr with different delivery consequences: Suhoor preserves the Fajr-beginning adhan/event, while Fajr silences the current morning Fajr adhan/alarm/checks.
- Treat ordinary system or AlarmKit dismissal as a non-awake attempt dismissal: stop the current attempt, keep the session unresolved, keep later valid wake checks scheduled, update the Hero to the next pending wake-check time, and record dismissal source.
- Align Fajr/fast completion logging with tri-state semantics: explicit yes, explicit no, unrecorded, and expired unresolved, with Qada relevance created only from explicit no where specified.
- Preserve the June 1 post-Suhoor Fajr model: no separate `Set Fajr Wake Alarm` CTA, no automatic Fajr wake-check session, and normal Fajr session activation only when the user commits a valid later slider value.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: Hero active wake CTAs, context-card action rows, sequential Fajr wake/prayer flow, late check/X prompts, and next wake-check display.
- `wake-session-execution`: Explicit awake confirmations, early-awake confirmations, non-awake dismissal handling, next pending attempt resolution, and Suhoor-to-Fajr delivery behavior.
- `morning-resolution`: Resolved action eligibility, tri-state logging outputs, fast prompt eligibility, and Qada-candidate foundations.

## Impact

- Affected code: `Subh/Core/Morning`, `Subh/Core/Services`, `Subh/Features/Home`, and focused XCTest coverage under `SubhTests`.
- Affected systems: local wake session store, wake attempt scheduling/reconciliation, Home presentation state, completion logging records, and wake-session simulation fixtures.
- Persistence/migration: add only backward-compatible fields/defaults where needed. Existing wake-session and completion records must decode safely.
- Dependencies: no new production dependency is planned.
