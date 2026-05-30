# Subh Suhoor Boundary and Before-Fajr Window Specification v3 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-early-worship-boundary-spec-v3.md` |
| Version | 3 |
| Spec status | Active Suhoor boundary specification; filename retained for compatibility |
| Date | 2026-05-30 |
| Related specs | Index, Fajr Time Calculation, Morning Resolution, Hero, Detail, Alarm Delivery |
| Owning domain / surface | Suhoor before-Fajr boundary and final-third calculation semantics |

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

This spec defines the before-Fajr timing boundary used by Suhoor wake planning.

The historical filename contains `early-worship`, but active MVP user-facing behavior is Suhoor/fasting-oriented only.

## 2. Boundaries

For a morning date `D`:

```text
nightStart = Maghrib/sunset on D - 1
nightEnd = Fajr begins on D
finalThirdStart = nightEnd - ((nightEnd - nightStart) / 3)
```

The two relevant wake windows are:

```text
Suhoor window: finalThirdStart → Fajr begins
Fajr window: Fajr begins → Fajr ends
```

If final-third data is unavailable, Suhoor may fall back to an approved before-Fajr window anchored to Fajr begins, but the app must be truthful about missing/estimated data where required.

## 3. State-to-boundary mapping

| Resolved morning | Earliest meaningful wake boundary |
| --- | --- |
| Default Fajr | Fajr begins |
| User-selected Fajr | Fajr begins |
| User-selected Suhoor | finalThirdStart, if available |
| Ramadan Suhoor | finalThirdStart, if available |
| Qada/Voluntary/Other fast under Suhoor | finalThirdStart, if available |
| Fasting opportunity only | Fajr begins |
| Quiet Fajr/Suhoor | Same underlying boundary, inactive alarm |
| Paused Fajr/Suhoor | Same underlying boundary, inactive alarm unless ring-once |

Do not activate the Suhoor/final-third boundary from a mere opportunity tag.

## 4. Follow-up boundary

For wake-session follow-ups:

```text
Suhoor follow-ups stop at Fajr begins.
Fajr follow-ups stop at Fajr ends.
```

## 5. Deferred behavior

These are not active MVP boundary drivers:

```text
Tahajjud-only wake
Other early worship wake
Generic non-fasting Pre-Fajr wake
```

A future spec may reintroduce them, but they must not appear in MVP UI/resolution.

## 6. Acceptance criteria

1. Suhoor uses the before-Fajr/final-third window when available.
2. Fajr uses the Fajr-begins-to-Fajr-ends window.
3. Fasting opportunities alone do not shift the boundary.
4. Quiet/Pause preserve the underlying boundary but do not ring.
5. Active copy uses Suhoor, not Pre-Fajr/Early/Fast mode.
