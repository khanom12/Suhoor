# Codex Prompt — Reconcile and Implement Subh CTA/Logging, Early-Awake, Wake-Check Display, and Historical Logging Spec Package

You are working on the Subh codebase and specification library.

I will attach a zipped specification package containing the updated June 1 specs. Treat the active index as the entry point:

```text
00-subh-spec-index-v6.md
```

Treat this file as the canonical feature specification for this implementation pass:

```text
subh-cta-logging-and-wake-action-spec-v2.md
```

## Objective

Using OpenSpec, reconcile the specification folder and implement only the scoped June 1 CTA/logging changes. Be careful, precise, and conservative. Do not drift into unrelated redesigns.

## Required spec-folder work first

1. Locate the desktop/local specifications folder used by this project.
2. Back up or archive superseded active specs whose version numbers are replaced by the June 1 package.
3. Promote the June 1 package root files as the active specs.
4. Ensure the active index is `00-subh-spec-index-v6.md`.
5. Ensure older versions of updated specs are not left as competing active root specs.
6. Preserve historical reports in an archive/reference area if needed, but do not let them override the active June 1 index.
7. Run an OpenSpec validation/check before code changes.

## Scope to implement

Implement the June 1 decisions only:

### 1. Hero active wake CTAs

- Active Suhoor wake state shows **I’m Awake for Suhoor** in the Hero.
- Active Fajr wake state shows **I’m Awake for Fajr** in the Hero.
- These active wake CTAs cancel remaining wake checks for their respective purpose.
- They do not log Fajr prayer or fast completion.

### 2. Sequential Fajr flow

- Do not show **I’m Awake for Fajr** and **I Prayed Fajr** at the same time.
- After **I’m Awake for Fajr**, apply a short anti-double-tap cooldown, starting target 1.5 seconds.
- After cooldown, show **I Prayed Fajr** in the context-card action area if Fajr is still in-window and prayer is unresolved.

### 3. Context-card action area

- Logging and early-awake actions live inside the context-card action area.
- Do not create a separate standalone CTA card unless the existing architecture already requires it.
- Support collapsed/expanded action rows when multiple actions are available.
- Use compact check/X prompt rows for late Fajr and fast completion.

### 4. Early-awake actions with confirmation

Add or update actions:

```text
I’m Already Awake for Suhoor
I’m Already Awake for Fajr
```

Both live in the context-card action area before the active wake window.

MVP availability:

- Suhoor: from midnight until Suhoor window begins.
- Fajr: from midnight until Fajr begins.

Both require confirmation.

Confirmed early Suhoor:

- logs Suhoor wake as early;
- cancels/silences upcoming Suhoor alarms/checks;
- preserves the default Fajr-beginning adhan/event;
- transitions the Hero to same-morning Fajr;
- exposes the Fajr slider where valid;
- does not log Fajr prayer or fast completion.

Confirmed early Fajr:

- logs Fajr wake as early;
- cancels/silences Fajr adhan/alarm/checks for the current morning;
- prevents **I’m Awake for Fajr** from appearing later for that morning;
- does not show **I Prayed Fajr** until Fajr begins;
- does not log Fajr prayer or fast completion.

### 5. System/AlarmKit dismissal behaviour

Ordinary system or AlarmKit dismissal must not be treated as **I’m Awake** unless the platform action is explicitly an awake-confirmation action.

If a primary alarm/check is dismissed without explicit awake confirmation:

- stop the current attempt;
- keep the session unresolved;
- keep later valid wake checks scheduled;
- update the Hero primary time to the next pending wake-check time;
- record dismissal source for analytics/debugging;
- do not log wake success.

### 6. Hero next wake-check display

During active Suhoor/Fajr wake sessions, the Hero main time must represent the next pending wake attempt.

- Before the first alarm fires: show initial alarm time.
- After each fired/dismissed attempt without explicit awake confirmation: show the next wake-check time.
- After explicit **I’m Awake**: stop remaining checks and move to the appropriate resolved state.
- Never show stale initial alarm time after later checks are pending.
- Never show “No time available” when prayer-time and wake-session data are valid.

### 7. Post-Suhoor Fajr behaviour

After active or early Suhoor wake confirmation:

- cancel remaining Suhoor wake checks;
- transition the Hero to same-morning Fajr;
- default Fajr delivery target is Fajr beginning/adhaan/event;
- do not automatically create Fajr wake checks;
- do not introduce a separate **Set Fajr Wake Alarm** CTA;
- if the user commits a later Fajr slider value, create/activate a normal Fajr wake session with wake checks;
- unless a future explicit setting supports dual delivery, do not silently fire both Fajr-beginning adhan and a later wake session after slider adjustment.

### 8. Fajr and fast check/X logging

Late Fajr prompts:

```text
I prayed Fajr earlier today? ✓ ✕
I prayed Fajr yesterday morning? ✓ ✕
```

Fast completion prompts:

```text
I completed my fast today? ✓ ✕
I completed my fast yesterday? ✓ ✕
```

Prompt semantics:

- ✓ = explicit completed/prayed.
- ✕ = explicit not completed/not prayed.
- no response = unresolved/unrecorded.
- expiry = expired unresolved.

Do not infer ✕ from silence.

Fast prompt eligibility:

- after Maghrib if Suhoor was selected for that morning;
- after Maghrib every Ramadan day;
- not merely for optional fasting opportunities if Suhoor was not selected.

Qada foundations:

- Fajr ✕ creates future Qada Fajr relevance.
- Ramadan fast ✕ creates future Qada fast relevance.
- optional fast ✕ supports statistics/encouragement but not the same Qada fast requirement.
- expired unresolved prompts do not create Qada candidates.

### 9. Historical logging foundations

If historical Fajr/Fasting logging surfaces already exist, align them with tri-state rows:

```text
unrecorded | ✓ | ✕
```

If those surfaces do not exist, do not invent a large new UI unless it fits the current architecture. Add data/model hooks and TODOs/stubs only where safe.

Home CTA logs and historical rows must point to the same underlying record where both exist.

## Do not implement

Do not invent or broaden scope into:

- a full Qada engine UI;
- full Ramadan exemption/fiqh rules;
- a new pricing strategy;
- a new Pause model;
- new social/accountability features;
- unrelated visual redesign;
- removal of existing unrelated features.

## Testing requirements

Add or update unit/UI/simulation tests for:

1. active Suhoor **I’m Awake for Suhoor**;
2. active Fajr **I’m Awake for Fajr**;
3. Fajr wake/prayer sequential flow;
4. anti-double-tap cooldown;
5. early Suhoor confirmation preserves Fajr adhan/event;
6. early Fajr confirmation silences Fajr adhan/alarm/checks;
7. alarm/check dismissal without awake advances to the next wake-check time;
8. Hero never shows stale first alarm time after a later check is pending;
9. late Fajr check/X yes/no/unrecorded;
10. fast completion eligibility and yes/no/unrecorded;
11. Qada candidate creation only on explicit ✕;
12. prompt expiry without Qada creation;
13. post-Suhoor Fajr slider activation.

## Completion report required

When complete, provide a detailed report including:

- specs promoted/archived;
- OpenSpec validation results;
- code files changed;
- data model changes;
- UI changes;
- scheduler/alarm changes;
- tests added/updated;
- manual test scenarios run;
- known limitations or deferred items;
- confirmation that unrelated features were not removed.

Commit and push changes only after validation and tests pass.
