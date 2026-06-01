## 1. Spec Sync and OpenSpec

- [x] 1.1 Archive superseded active root specs and promote the June 1 package in the Desktop working specification folder.
- [x] 1.2 Mirror the June 1 active spec package into `docs/specs/` and keep older root specs out of the active root.
- [x] 1.3 Validate OpenSpec artifacts before code changes.

## 2. Wake Session Domain and Scheduling

- [x] 2.1 Add explicit active Suhoor/Fajr awake confirmations that cancel only matching remaining wake checks and do not log Fajr prayer or fast completion.
- [x] 2.2 Add non-awake dismissal handling that records source, keeps the session unresolved, preserves later checks, and exposes the next pending attempt time.
- [x] 2.3 Add confirmed early-awake Suhoor/Fajr paths with the June 1 delivery consequences.
- [x] 2.4 Preserve post-Suhoor Fajr as a same-morning Fajr-start event unless a valid later slider value activates a normal Fajr wake session.

## 3. Home Presentation and Actions

- [x] 3.1 Render Hero active wake CTAs as `I’m Awake for Suhoor` and `I’m Awake for Fajr`.
- [x] 3.2 Enforce Fajr wake/prayer sequencing with a 1.5 second anti-double-tap cooldown before `I Prayed Fajr` appears in the context-card action area.
- [x] 3.3 Place early-awake and logging actions inside the context-card action area, with compact/collapsible rows when multiple actions are eligible.
- [x] 3.4 Ensure active Hero primary time advances to the next pending wake-check time and never falls back to stale first-alarm time when a later check is pending.

## 4. Logging and Qada Foundations

- [x] 4.1 Align late Fajr prompts with yes/no/unrecorded/expired semantics.
- [x] 4.2 Align fast completion prompt eligibility and yes/no/unrecorded/expired semantics.
- [x] 4.3 Ensure Qada candidate relevance is created only by explicit Fajr no and Ramadan fast no, not silence or prompt expiry.
- [x] 4.4 Add historical logging hooks/TODOs only where existing surfaces cannot safely be extended in this pass.

## 5. Verification

- [x] 5.1 Add or update focused unit/simulation/UI tests for the June 1 required scenarios.
- [x] 5.2 Run focused XCTest suites for wake session, completion/logging, and Home presentation behavior.
- [x] 5.3 Run a build/typecheck command or document why it could not run.
- [x] 5.4 Re-run OpenSpec validation and review the diff for product-model drift, privacy/reliability regressions, and unrelated changes.
