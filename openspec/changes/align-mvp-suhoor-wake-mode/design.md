## Context

The Desktop working specs and implementation had accumulated competing before-Fajr concepts: `Fast`, `Pre-Fajr`, `Early`, Tahajjud-only, and other early worship. That created a risk of parallel morning engines and unclear product promises.

The MVP product decision is narrower and easier to trust: before-Fajr waking exists only as Suhoor. Fajr remains the ordinary Fajr wake mode, and Quiet remains the only user-facing alarm-off mode.

## Decisions

### Canonical MVP Mode Set

The canonical MVP quick wake modes are:

- `Suhoor`: wake before Fajr begins for Suhoor and fasting preparation.
- `Fajr`: wake at the supported Fajr wake anchor.
- `Quiet`: suppress the alarm for the selected morning while preserving the rest of the resolved context where possible.

The app may keep lower-level implementation names such as an early-worship boundary where they describe time geometry, but user-facing mode labels and MVP domain semantics must not expose Tahajjud-only or other early worship as selectable modes.

### Suhoor Intention Semantics

Suhoor carries the fasting intention path. When a date has a known fasting opportunity, Suhoor should default to that opportunity. When there is no specific opportunity, Suhoor should default to voluntary fasting. Existing supported overrides for fasting intention remain available.

Forbidden-fasting and special-calendar handling remain governed by the day-purpose and opportunity resolver. This change does not invent new religious rulings or hard-code authority beyond existing resolver inputs.

### Legacy Compatibility

Persisted values from previous builds should decode safely:

- Legacy quick wake values such as `Fast`, `Pre-Fajr`, or `Early` normalize to Suhoor.
- Legacy early-purpose values such as Tahajjud-only or other early worship normalize to the fasting/Suhoor path where a saved date needs compatibility.

This keeps existing installs from breaking while preventing old concepts from reappearing in active MVP UI.

### Alarm Detail Persistence

Alarm Detail changes save immediately. Reset to default applies immediately as well. The spec is updated to match this behavior rather than requiring a staged-save box or Done-gated persistence.

### Reliability Scope

Automated tests can verify resolver behavior, persistence compatibility, presentation labels, and simulator-level schedule handoff. Physical-device alarm reliability remains a required QA pass because AlarmKit permission, audible wake behavior, Focus/silent behavior, reboot, app termination, timezone changes, and device scheduling limits cannot be proven by static inspection alone.

## Risks and Follow-ups

- Physical-device alarm QA is still required before claiming production alarm reliability.
- Older OpenSpec changes that refer to `Pre-Fajr` and Tahajjud-only are historical and should be treated as superseded by this change.
- If a future version reintroduces non-Suhoor before-Fajr worship, it should be proposed as a post-MVP product decision rather than leaking through legacy names.
