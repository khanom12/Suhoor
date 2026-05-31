# Subh Suhoor Boundary and Before-Fajr Window Specification v4 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-early-worship-boundary-spec-v4.md` |
| Version | 4 |
| Spec status | Active Suhoor boundary specification; filename retained for compatibility |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Fajr Time Calculation, Morning Resolution, Hero, Detail, Alarm Delivery, Wake Sessions |
| Owning domain / surface | Suhoor before-Fajr boundary, final-third calculation semantics, and late-session cutoff rules |

## May 31, 2026 update status

Version 4 confirms that Suhoor window start is the daily calculated last third of the night and adds the latest Suhoor scheduling cutoff from the May 31 walkthrough.

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

Example times such as `1:32 AM` from the May 31 Toronto walkthrough are examples only and must not be hard-coded.

## 3. State-to-boundary mapping

| Resolved morning | Earliest meaningful wake boundary | Relevant window end |
| --- | --- | --- |
| Default Fajr | Fajr begins | Fajr ends |
| User-selected Fajr | Fajr begins | Fajr ends |
| User-selected Suhoor | finalThirdStart, if available | Fajr begins |
| Ramadan Suhoor | finalThirdStart, if available | Fajr begins |
| Qada/Voluntary/Other fast under Suhoor | finalThirdStart, if available | Fajr begins |
| Fasting opportunity only | Fajr begins | Fajr ends unless user selects Suhoor |
| Quiet Fajr/Suhoor | Same underlying boundary, inactive alarm | Same underlying boundary, inactive alarm |
| Paused Fajr/Suhoor | Same underlying boundary, inactive alarm unless ring-once | Same underlying boundary, inactive alarm unless ring-once |

Do not activate the Suhoor/final-third boundary from a mere opportunity tag.

## 4. Scheduling cutoffs

Wake-session scheduling uses the same timing rules for Suhoor and Fajr:

```text
Earliest newly scheduled wake time = current time + 1 minute
Latest wake time = relevant window end - 5 minutes
Latest new session creation time = relevant window end - 6 minutes
Wake-check interval = 5 minutes
```

For Suhoor:

```text
relevant window end = Fajr begins
latest Suhoor wake time = Fajr begins - 5 minutes
latest new Suhoor scheduling/switch time = Fajr begins - 6 minutes
```

If the user tries to switch into or newly schedule Suhoor after the cutoff, the app must not create a fake/invalid Suhoor wake session.

Suggested copy:

```text
It’s too close to Fajr to schedule Suhoor for Today Morning.
You can still wake for Fajr.
```

## 5. Follow-up boundary

For wake-session follow-ups:

```text
Suhoor follow-ups stop no later than 5 minutes before Fajr begins.
Fajr follow-ups stop no later than 5 minutes before Fajr ends.
No follow-up occurs at the exact boundary.
```

## 6. Mode switching during Suhoor window

Before Suhoor window begins, the user may switch between Suhoor and Fajr normally.

During the Suhoor window:

- switching from Suhoor to Fajr may cancel an active/pending Suhoor session and must require confirmation when it has execution consequences;
- switching from Fajr into Suhoor is allowed only until `Fajr begins - 6 minutes`;
- after Fajr begins, Suhoor is no longer newly schedulable for Today Morning.

Suggested confirmation:

```text
Title: Switch to Fajr for Today Morning?
Body: This will cancel your Suhoor wake session for this morning.
Actions: Keep Suhoor / Switch to Fajr
```

## 7. Deferred behavior

These are not active MVP boundary drivers:

```text
Tahajjud-only wake
Other early worship wake
Generic non-fasting Pre-Fajr wake
```

A future spec may reintroduce them, but they must not appear in MVP UI/resolution.

## 8. Acceptance criteria

1. Suhoor uses the before-Fajr/final-third window when available.
2. Fajr uses the Fajr-begins-to-Fajr-ends window.
3. Fasting opportunities alone do not shift the boundary.
4. Quiet/Pause preserve the underlying boundary but do not ring.
5. Active copy uses Suhoor, not Pre-Fajr/Early/Fast mode.
6. New Suhoor scheduling is blocked after Fajr begins minus 6 minutes.
7. Latest Suhoor wake time is Fajr begins minus 5 minutes.
8. No Suhoor follow-up is scheduled at Fajr begins.
