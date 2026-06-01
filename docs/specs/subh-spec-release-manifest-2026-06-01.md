# Subh Spec Release Manifest — 2026-06-01

## 1. Release intent

This release reconciles the active Subh specification suite with the June 1 CTA/logging, early-awake, wake-check display, historical logging, and future Qada-candidate decisions.

## 2. Promoted active files

Use the root files in this package as the active implementation-facing specs. The active index is:

```text
00-subh-spec-index-v6.md
```

The new canonical feature specification is:

```text
subh-cta-logging-and-wake-action-spec-v2.md
```

## 3. Key confirmed rules

- Active wake CTAs live in the Hero.
- Logging and early-awake actions live in the context-card action area.
- **I’m Awake for Fajr** and **I Prayed Fajr** are sequential, never simultaneous.
- A short anti-double-tap cooldown separates Fajr wake confirmation from Fajr prayer logging.
- Ordinary system/AlarmKit dismissal does not equal wake acknowledgement.
- The Hero primary time advances to the next pending wake check after each non-awake dismissal.
- Confirmed early Suhoor silences Suhoor attempts while preserving the Fajr adhan/event.
- Confirmed early Fajr silences the Fajr adhan/alarm/checks.
- Fast completion appears after Maghrib when Suhoor was selected, and every Ramadan day.
- Late Fajr and fast completion use compact check/X prompt rows with ✓, ✕, and unrecorded states.
- Explicit Fajr ✕ and Ramadan fast ✕ feed future Qada-candidate foundations.
- Post-Suhoor Fajr behaviour uses the Hero/Fajr slider, not a separate **Set Fajr Wake Alarm** CTA.

## 4. Implementation caution

This release is intentionally scoped. Do not invent a complete Qada engine, full historical logging UI, new pricing tiers, or new Pause model unless those surfaces already exist and can be updated safely within the current codebase.
