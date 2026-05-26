# Subh Sound and Alarm Settings Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-sound-alarm-settings-spec-v1.md` |
| Version | 1 |
| Spec status | Canonical working spec; created to fill missing sound/alarm-settings ownership gap |
| Related specs | `00-subh-spec-index-v3.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-morning-hero-item-spec-v15.md` |
| Owning domain / surface | Alarm sound roles, alarm sound settings, ramped audio asset policy |
| Implementation audit status | Needs implementation audit |

## Purpose

Define how Subh chooses, names, presents, and constrains alarm sounds for Fajr, Suhoor, and Wake Checks. This spec captures the product decision that gentle wake behavior should be created primarily through the audio asset’s waveform/envelope, not by promising app-level runtime control of system alarm volume.

## What This Spec Owns

- Alarm sound roles and sound selection terminology.
- Ramped audio asset expectations.
- MVP and future sound profiles.
- Wake-check sound behavior.
- User-facing alarm sound settings.
- Test sound expectations.
- Boundaries between sound choice, alarm activation, and delivery status.

## What This Spec Does Not Own

- Prayer-time calculation.
- Wake Session scheduling rules.
- AlarmKit authorization or delivery reconciliation.
- Religious/legal guidance on adhan usage.
- StoreKit or paid sound packs.
- Device-level volume settings.

## Core principles

1. **Sound role is not alarm activation.** Turning an adhan cue or sound preference on/off must not be interpreted as turning the wake alarm on/off unless the user selects Quiet or another explicit alarm-suppression state.
2. **Ramping belongs in the audio file for MVP.** The file itself should begin quietly and build in perceived intensity.
3. **Do not promise runtime volume control.** Subh should not present a per-alarm volume ramp unless implementation and platform testing prove it exists and is reliable.
4. **Default sound should be gentle but effective.** The first alarm should begin calmly while still becoming audible enough to wake the user.
5. **Wake checks may repeat the same chosen profile.** Escalating wake-check profiles are future/advanced scope unless separately specified.
6. **Test before trust.** The app should eventually let users test the chosen sound because perceived loudness depends on device, environment, and system settings.

## Sound roles

Conceptual sound roles:

```text
fajrWake
suhoorWake
wakeCheck
fajrBeginsCue
silentOrNone // only where delivery policy allows a silent/non-audible reminder
iftarCue // future
```

Rules:

- `fajrWake` is the audible wake sound for ordinary Fajr mode.
- `suhoorWake` is the audible wake sound for Suhoor mode.
- `wakeCheck` is the audible sound used by follow-up Wake Check alarms.
- `fajrBeginsCue` is distinct from the wake alarm. Disabling a Fajr-begins cue must not disable an earlier Suhoor wake.
- A sound role may map to the same underlying asset in MVP.
- Sound roles should be carried by resolved events or delivery inputs so the delivery layer does not infer religious meaning from filenames.

## Ramped audio asset policy

Required asset behavior:

```text
The audio waveform itself starts softly and gradually increases in perceived intensity.
```

Recommended asset family:

```text
adhan_fajr_gentle_ramp
adhan_fajr_balanced_ramp
adhan_fajr_strong_ramp
subh_chime_gentle_ramp
subh_chime_balanced_ramp
subh_chime_strong_ramp
```

MVP options:

1. Replace the current bundled Fajr adhan file with a ramped version while keeping the existing code reference stable; or
2. Add a new ramped asset and update the selected sound reference to that asset.

Rules:

- The ramp is not treated as metadata. It is part of the audio waveform/envelope.
- The first seconds should be gentle enough to avoid a startling start.
- The sound should still become clear enough to serve as a wake alarm.
- The app must not apply a misleading UI label such as “volume ramp” unless the actual implementation controls the delivered alarm volume reliably.
- If a non-adhan fallback is offered, it should follow the same ramp policy.

## MVP sound behavior

Minimum MVP behavior:

- Use a bundled ramped wake sound for Fajr and Suhoor alarms.
- Use the same selected profile for wake checks unless another approved spec defines escalation.
- Keep alarm activation separate from sound selection.
- Allow implementation to be completed by replacing/adding the asset without requiring a full settings UI in the same pass.

MVP non-goals:

```text
per-alarm volume slider
runtime fade-in engine
per-wake-check escalation
paid sound packs
custom user-imported sounds
complex sound mixer
```

## Future sound settings

A future settings surface may expose:

| Setting | MVP status | Future status |
|---|---|---|
| Alarm sound profile | May be fixed/default | User-selectable |
| Gentle / Balanced / Strong | Asset-ready | User-selectable |
| Adhan vs chime | Optional | User-selectable |
| Test alarm sound | Recommended later | User-visible setting |
| Wake-check escalation | Not MVP | Advanced/heavy-sleeper setting |
| Custom imported sound | Not MVP | Requires separate review |

User-facing profile copy should describe the asset honestly:

```text
Gentle Fajr Adhan
Balanced Fajr Adhan
Strong Fajr Adhan
Soft Subh Chime
```

Avoid copy that implies device/system volume control:

```text
Start at 10% volume and rise to 80%
Control iPhone alarm volume from Subh
Guaranteed quiet start regardless of system settings
```

## Wake Check sound behavior

Default:

```text
Wake checks use the same selected sound profile as the primary alarm.
```

Allowed future enhancement:

```text
Primary alarm: gentle profile
Wake check 1–2: balanced profile
Final wake check: strong profile
```

Rules for future escalation:

- It must be opt-in or clearly explained.
- It must respect the user’s maximum wake-check settings.
- It must not be silently enabled as punishment for unconfirmed mornings.
- It must not bypass Quiet or confirmed-awake cancellation.

## Settings placement

A future Sound / Alarm Settings section should live under the broader Settings or Alarm Settings surface, not inside the Home hero.

Possible settings layout:

```text
Alarm sound
[Gentle Fajr Adhan]

Wake check sound
[Use same sound]

Test sound
[Play sample]
```

Rules:

- The Home hero should not expose sound selection.
- Day Detail may show sound summary only if that screen already owns alarm-detail controls.
- Sound settings changes should trigger delivery refresh for future scheduled alarms inside the active scheduled horizon.
- If the selected sound asset is missing, delivery must fall back to a safe default and log a diagnostic.

## Accessibility and user trust

- Sound settings should be accompanied by clear text for users who cannot evaluate audio visually.
- A test sound should be cancellable immediately.
- The app should avoid surprising the user with a much louder asset after an update. If the default asset changes significantly, use release notes or an in-app note where appropriate.
- If the user has system-level settings that affect audible delivery, Subh may show reliability guidance through the permission/reliability warning surfaces rather than pretending to control system volume.

## Acceptance criteria

1. Given a Fajr or Suhoor Wake Session is scheduled, the resolved delivery carries a sound role distinct from alarm activation.
2. Given the current Fajr adhan asset is replaced with a ramped file, Subh should deliver the same wake event using the ramped audio without requiring a new runtime volume-ramp mechanism.
3. Given the user confirms awake or confirms Quiet, pending wake-check alarms are cancelled regardless of sound profile.
4. Given a Fajr-begins cue is disabled, the earlier Suhoor wake alarm remains active unless the user also suppresses that wake alarm through Quiet or another explicit alarm state.
5. Given a future settings UI exposes sound profiles, the labels describe the sound profile and do not claim unsupported per-alarm system volume control.
