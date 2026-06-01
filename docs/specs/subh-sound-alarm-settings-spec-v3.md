# Subh Sound and Alarm Settings Specification v3 — June 1 Fajr Adhan and Post-Suhoor Delivery Alignment

| Field | Value |
| --- | --- |
| Canonical filename | `subh-sound-alarm-settings-spec-v3.md` |
| Version | 3 |
| Spec status | Active sound/alarm settings specification |
| Date | 2026-06-01 |
| Related specs | Index, Quiet/Pause, Alarm Delivery, Hero, Wake Sessions |
| Owning domain / surface | Sound roles, alarm settings, and settings UI |

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

This spec defines sound and alarm settings without confusing sound roles with alarm activation state.

## 2. Sound roles

Possible sound roles may include:

```text
primary wake alarm sound
follow-up wake alarm sound
adhan/Fajr cue if supported
preview sound
haptic/vibration treatment
```

Sound selection does not decide whether a morning rings. Morning Resolution and Alarm Delivery decide that from purpose, Quiet/Pause, setup, and delivery capability.

## 3. Quiet/Pause interaction

Quiet suppresses the wake alarm family for one morning.

Pause suppresses Subh wake alarms until resumed.

These controls should not silently disable unrelated future non-wake notifications unless a later notification spec explicitly groups them.

## 4. Purpose-specific settings

Fajr and Suhoor may have separate alarm timing and sound preferences where product-approved.

Switching Fajr/Suhoor must not erase the other purpose’s saved settings.

## 5. Settings entry points

Settings / Wake Alarms owns:

- global wake alarms enabled/disabled where supported;
- indefinite Pause/resume;
- default Fajr alarm configuration;
- default Suhoor alarm configuration;
- sound previews;
- troubleshooting links for permissions/setup.

One-morning Quiet remains primarily a Home/Detail action.

## 6. Acceptance criteria

1. Sound settings are separate from wake purpose.
2. Quiet/Pause suppress wake delivery without deleting sound preferences.
3. Fajr and Suhoor settings can be preserved separately.
4. Permission/setup problems do not masquerade as Quiet.
5. Settings uses `Alarms paused`, not `Pause mode`.

---

## June 1 Addendum: Fajr Adhan / Event Behaviour

Sound settings must support the delivery distinction introduced by the CTA spec:

- after confirmed **I’m Already Awake for Suhoor**, Suhoor alarms/checks are silenced but the Fajr-beginning adhan/event remains by default;
- after confirmed **I’m Already Awake for Fajr**, the Fajr adhan/alarm/checks for that morning are silenced;
- after Suhoor wake acknowledgement, the default same-morning Fajr delivery is the Fajr-beginning adhan/event;
- if the user commits a later Fajr slider value after Suhoor, that later slider target should replace the Fajr-beginning wake delivery target unless a future explicit setting supports both.

