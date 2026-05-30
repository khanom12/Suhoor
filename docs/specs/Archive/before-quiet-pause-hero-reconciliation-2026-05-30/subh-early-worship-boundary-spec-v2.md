# Subh Early Worship Boundary Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-early-worship-boundary-spec-v2.md` |
| Version | 2 |
| Spec status | Draft; canonical Desktop working spec; aligned to Next 7 Mornings horizon |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-fajr-time-calculation-determination-selection-spec-v1.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-morning-hero-item-spec-v15.md` |
| Owning domain / surface | Suhoor before-Fajr boundary model; legacy early-worship terminology |
| Implementation audit status | Needs implementation audit |

## Purpose
Define the final-third and before-Fajr boundary semantics used for Suhoor wake planning and explanation.

## What This Spec Owns
- Final-third calculation ownership and boundary terminology.
- Suhoor before-Fajr boundary warnings and user-facing explanation rules.
- Integration expectations for morning resolution and visual surfaces.

## Normative Requirements
The normative requirements in this spec are the explicit MUST, SHALL, required, acceptance, and scenario statements below. Recommendations, implementation guidance, examples, and future-direction notes are advisory unless this spec or a later canonical spec promotes them to requirements.

## Out of Scope / Deferred
- Code/spec divergence classification is deferred to a later implementation audit.
- App code, tests, and OpenSpec library artifacts are out of scope for this docs-only cleanup.
- Historical archive filenames are kept only as historical references and are not promoted back into the active spec set.

## Open Questions and Deferred Work
Open questions, TODO-style notes, future ideas, and implementation audit prompts below are retained as the working queue for later spec improvement. This cleanup standardizes them as deferred work rather than claiming they are resolved.

## Cleanup Notes
- This file was renamed and header-normalized in the Desktop working-spec cleanup pass.
- The Desktop folder remains the canonical working-spec location.
- Implementation completeness claims in older prose should be treated as historical context until the later audit updates this field.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- The user-facing before-Fajr boundary is used for `Suhoor`.
- `Suhoor` is the only MVP exposed before-Fajr mode.
- `Tahajjud only`, `Other early worship`, and generic `Pre-Fajr` planning are deferred and must not be presented as selectable MVP states.
- The implementation may retain an internal boundary name such as `earlyWorship` for the final-third-to-Fajr-begins window, but user-facing surfaces should call the mode `Suhoor`.
- For MVP, the final-third boundary applies when the resolved morning has Suhoor/fasting intent. It must not be activated by a mere fasting opportunity.
- Fajr mode continues to use the Fajr-begins-to-Fajr-ends window.

## 1. Purpose

This spec defines how Subh calculates and uses the **final third of the night** as a before-Fajr wake boundary for Suhoor/fasting states.

The goal is to preserve a clean distinction between:

1. **Default Fajr mornings**, where the earliest meaningful wake boundary is **Fajr begins**.
2. **Suhoor mornings**, where the earliest meaningful wake boundary is the **start of the final third of the night**.

This rule supports Subh’s core product model: a Fajr-centered morning system where Suhoor, Ramadan, and other special cases are layered states over the default morning rhythm.

---

## 2. Core decision

For each resolved morning:

```text
If the day has intended Suhoor/fasting:
    earliestWakeBoundary = finalThirdStart

Else:
    earliestWakeBoundary = fajrBegins
```

The final third of the night should **not** replace Fajr begins. It is an earlier boundary used only when the day has an early-worship intent.

---

## 3. Canonical definitions

### 3.1 Morning date

A **morning date** is the civil date on which Fajr occurs.

For a morning date `D`:

- `fajrBegins` occurs on date `D`.
- `nightStart` is the previous evening’s Maghrib/sunset, usually on date `D - 1`.
- `nightEnd` is `fajrBegins` on date `D`.

This is important because the night associated with a Fajr morning usually begins on the previous civil date.

### 3.2 Night window

The night used for final-third calculation is:

```text
nightStart = Maghrib/sunset for the evening before the morning date
nightEnd   = Fajr begins for the morning date
```

The app should use the same resolved prayer-time source it already uses for local prayer times.

### 3.3 Final third of the night

```text
nightDuration = nightEnd - nightStart
oneThird      = nightDuration / 3
finalThirdStart = nightEnd - oneThird
finalThirdEnd   = nightEnd
```

So the final third window is:

```text
finalThirdStart → fajrBegins
```

### 3.4 Fajr boundary

The **Fajr boundary** begins at `fajrBegins`.

For default Fajr mornings, this is the earliest meaningful wake boundary because the user’s primary objective is to wake for Fajr rather than pre-Fajr worship.

### 3.5 Early worship boundary

The **Early Worship Boundary** begins at `finalThirdStart`.

It applies when the morning is marked by:

- intended fasting;
- intended Tahajjud;
- both intended fasting and intended Tahajjud.

This boundary represents the earliest meaningful time Subh should use for pre-Fajr worship and preparation.

---

## 4. Boundary types

```swift
enum WakeBoundaryKind {
    case fajrBegins
    case finalThirdOfNight
}
```

Recommended canonical model:

```swift
struct WakeBoundaryResolution {
    let kind: WakeBoundaryKind
    let morningDate: Date
    let nightStart: Date
    let nightEnd: Date
    let finalThirdStart: Date?
    let earliestWakeBoundary: Date
    let fajrBegins: Date
    let fajrEnds: Date?
    let reason: WakeBoundaryReason
    let isEstimated: Bool
}

enum WakeBoundaryReason {
    case defaultFajrMorning
    case intendedFasting
    case intendedTahajjud
    case intendedFastingAndTahajjud
    case fallbackMissingNightData
}
```

Notes:

- `finalThirdStart` is optional because it may be unavailable if Maghrib or Fajr data is missing.
- `fajrEnds` may already mean sunrise or the app’s resolved end of Fajr window, depending on existing Subh terminology.
- `isEstimated` should be true when the underlying prayer time was estimated through high-latitude or fallback rules.

---

## 5. State-to-boundary mapping

| Resolved day state | Earliest wake boundary | Boundary kind | Notes |
|---|---:|---|---|
| Default Fajr day | Fajr begins | `fajrBegins` | Normal Fajr-centered morning. |
| Fajr intended only | Fajr begins | `fajrBegins` | Same as default unless other early-worship intent is active. |
| Manually adjusted default day | Fajr begins | `fajrBegins` | Manual time changes do not automatically imply Tahajjud or fasting. |
| Tahajjud intended | Final third start | `finalThirdOfNight` | Opens early-worship window. |
| Fasting intended | Final third start | `finalThirdOfNight` | Opens suhoor/pre-Fajr preparation window. |
| Fasting + Tahajjud intended | Final third start | `finalThirdOfNight` | Shared early boundary; do not create competing boundaries. |
| Ramadan fasting day | Final third start | `finalThirdOfNight` | Applies when Ramadan fasting support is active for the user. |
| Qada fast intended | Final third start | `finalThirdOfNight` | Treated as fasting intended. |
| Sunnah fast intended | Final third start | `finalThirdOfNight` | Treated as fasting intended. |
| Fasting opportunity only | Fajr begins | `fajrBegins` | Do not shift boundary unless the user intends/activates the fast. |
| Observance-only day | Fajr begins | `fajrBegins` | Informational tags alone should not alter wake semantics. |
| Quiet / paused day | Same resolved boundary, but inactive wake | Depends | Boundary can still be calculated for explanation, but alarm is inactive. |

---

## 6. Intention semantics

### 6.1 Intended fasting

A morning should be treated as `intendedFasting` when at least one of the following is true:

- the user explicitly marks the day as a fasting day;
- the user schedules a Qada/makeup fast;
- the user schedules a Sunnah/voluntary fast;
- the user schedules a custom fast;
- the day is a Ramadan fasting day and Ramadan fasting support is active.

### 6.2 Fasting opportunity

A fasting opportunity is not the same as intended fasting.

Examples:

- Monday/Thursday opportunity;
- White Day opportunity;
- Ashura opportunity;
- six days of Shawwal opportunity;
- first nine days of Dhul Hijjah opportunity.

These may appear as opportunity tags, education, or suggestions, but they should not shift the earliest wake boundary unless the user chooses/intends the fast or the app has an explicit user setting that auto-activates that category.

### 6.3 Intended Tahajjud

A morning should be treated as `intendedTahajjud` when the user explicitly marks the day or plan for Tahajjud support.

Tahajjud intent may exist independently of fasting intent.

### 6.4 Manual wake adjustment

A manually adjusted wake time does not automatically create an early-worship state.

Example:

```text
User manually drags a default wake earlier.
Result: boundary kind remains fajrBegins unless fasting or Tahajjud intent is active.
```

This prevents the app from inferring religious intention from a purely mechanical time edit.

---

## 7. Resolver logic

### 7.1 High-level resolver

```swift
func resolveWakeBoundary(
    for morning: ResolvedDayContext,
    prayerTimes: PrayerTimes
) -> WakeBoundaryResolution {
    let fajrBegins = prayerTimes.fajrBegins
    let fajrEnds = prayerTimes.fajrEnds
    let nightStart = prayerTimes.previousEveningMaghrib
    let nightEnd = fajrBegins

    guard let finalThirdStart = calculateFinalThirdStart(
        nightStart: nightStart,
        nightEnd: nightEnd
    ) else {
        return WakeBoundaryResolution(
            kind: .fajrBegins,
            morningDate: morning.date,
            nightStart: nightStart,
            nightEnd: nightEnd,
            finalThirdStart: nil,
            earliestWakeBoundary: fajrBegins,
            fajrBegins: fajrBegins,
            fajrEnds: fajrEnds,
            reason: .fallbackMissingNightData,
            isEstimated: prayerTimes.isEstimated
        )
    }

    if morning.hasIntendedFasting && morning.hasIntendedTahajjud {
        return earlyWorshipResolution(
            reason: .intendedFastingAndTahajjud,
            finalThirdStart: finalThirdStart,
            prayerTimes: prayerTimes,
            morning: morning
        )
    }

    if morning.hasIntendedFasting {
        return earlyWorshipResolution(
            reason: .intendedFasting,
            finalThirdStart: finalThirdStart,
            prayerTimes: prayerTimes,
            morning: morning
        )
    }

    if morning.hasIntendedTahajjud {
        return earlyWorshipResolution(
            reason: .intendedTahajjud,
            finalThirdStart: finalThirdStart,
            prayerTimes: prayerTimes,
            morning: morning
        )
    }

    return WakeBoundaryResolution(
        kind: .fajrBegins,
        morningDate: morning.date,
        nightStart: nightStart,
        nightEnd: nightEnd,
        finalThirdStart: finalThirdStart,
        earliestWakeBoundary: fajrBegins,
        fajrBegins: fajrBegins,
        fajrEnds: fajrEnds,
        reason: .defaultFajrMorning,
        isEstimated: prayerTimes.isEstimated
    )
}
```

### 7.2 Final-third calculation

```swift
func calculateFinalThirdStart(nightStart: Date?, nightEnd: Date?) -> Date? {
    guard let nightStart, let nightEnd else { return nil }

    let duration = nightEnd.timeIntervalSince(nightStart)
    guard duration > 0 else { return nil }

    return nightEnd.addingTimeInterval(-(duration / 3.0))
}
```

Implementation notes:

- Use real `Date` instants, not local clock-hour math.
- Duration must be calculated across midnight safely.
- Daylight saving time changes must be handled by the platform date/time system.
- The same calculation method and user offsets that resolve prayer times should feed this calculation.

---

## 8. Relationship to actual wake time

The boundary is not the same as the wake time.

```text
Boundary = earliest meaningful point in the relevant morning window
Wake time = actual scheduled alarm/reminder time
```

Example:

```text
Maghrib: 8:30 PM
Fajr begins: 5:00 AM
Night length: 8h 30m
Final third starts: 2:10 AM

Tahajjud intended:
    earliestWakeBoundary = 2:10 AM
    actual wake might be 4:30 AM

Default Fajr day:
    earliestWakeBoundary = 5:00 AM
    actual wake might be 5:25 AM or 30 minutes before Fajr ends
```

The app should not automatically schedule the alarm at `finalThirdStart`. Instead, it should use that value as the earliest available boundary for early-worship wake planning.

---

## 9. Wake-time validation rules

### 9.1 Default/Fajr days

For default Fajr mornings:

```text
allowed semantic wake region begins at fajrBegins
```

If a user manually selects a wake before Fajr begins without marking fasting or Tahajjud, the app may allow the edit as a custom wake but should not reinterpret the day as an early-worship state.

Recommended behavior:

- keep boundary kind as `fajrBegins`;
- show no early-worship explanation;
- optionally show neutral copy such as “Custom earlier wake”.

### 9.2 Fasting/Tahajjud days

For intended fasting or Tahajjud mornings:

```text
preferred wake region = finalThirdStart → fajrBegins
```

If the user schedules a wake after Fajr begins on a fasting/Tahajjud day:

- the wake may still support Fajr prayer;
- it no longer supports suhoor or pre-Fajr Tahajjud;
- the app should warn or explain in detail surfaces, but not overcomplicate list rows.

Recommended warning copy:

```text
This wake is after Fajr begins, so it may be too late for suhoor or pre-Fajr Tahajjud.
```

### 9.3 Boundary minimums

The app should not create a second “earliest” boundary for fasting and Tahajjud separately. Both share `finalThirdStart`.

---

## 10. UI and copy rules

### 10.1 Next 7 Mornings wake forecast

The Next 7 Mornings wake forecast should remain simple.

Rows should not explain the full boundary calculation. They should show only the date, relevant tags, and wake/alarm time according to the row spec.

Boundary logic should influence the row through:

- selected wake time;
- available adjustment range;
- active tags;
- detail-screen explanation when tapped.

### 10.2 Tags

Recommended tags related to this spec:

| Tag | Meaning | Boundary effect |
|---|---|---|
| `Fajr` | Default Fajr-centered morning | Uses Fajr begins unless another active intent overrides. |
| `Fasting opportunity` | A recommended/meaningful day to fast | No boundary shift by itself. |
| `Fasting intended` | User intends to fast | Uses final-third boundary. |
| `Tahajjud intended` | User intends Tahajjud support | Uses final-third boundary. |
| `Ramadan` | Ramadan fast day for observing user | Uses final-third boundary. |
| `Qada` | Makeup fast intended | Uses final-third boundary. |

Tag display must not force extra explanatory text into compact rows.

### 10.3 Detail view explanation

Detail surfaces may explain the boundary.

For default Fajr days:

```text
This morning uses Fajr begins as the earliest wake boundary.
```

For fasting days:

```text
Because fasting is intended, this morning can use the final third of the night as the early wake boundary.
```

For Tahajjud days:

```text
Because Tahajjud is intended, this morning can use the final third of the night as the early wake boundary.
```

For fasting + Tahajjud:

```text
Because fasting and Tahajjud are intended, this morning uses the final third of the night as the early wake boundary.
```

### 10.4 User-facing glossary copy

Recommended glossary definition:

```text
Final third of the night
The blessed period before Fajr, calculated by dividing the time from Maghrib to Fajr into three parts and taking the last part.
```

Recommended app term:

```text
Early worship window
The pre-Fajr period used for fasting preparation, Tahajjud, du‘a, Qur’an, and other worship.
```

Avoid implying that the app knows the user’s religious intention unless the user explicitly set it or the state is derived from an enabled plan.

---

## 11. Data ownership

This spec should be implemented in the domain/resolver layer, not inside individual SwiftUI views.

Recommended ownership:

- Prayer-time calculation source resolves Maghrib, Fajr begins, and Fajr ends.
- Day resolver determines fasting/Tahajjud intention state.
- Wake boundary resolver combines prayer times and day state.
- Surface providers consume the resolved boundary.
- Views display the resolved values without recalculating them.

Recommended dependency direction:

```text
PrayerTimes + DayIntentions
        ↓
WakeBoundaryResolver
        ↓
ResolvedDaySnapshot / WakeSurfaceSnapshot / DetailSnapshot
        ↓
SwiftUI views
```

Do not duplicate final-third math in:

- row views;
- chart views;
- detail headers;
- alarm scheduling views;
- notification copy builders.

---

## 12. Interaction with prayer-time settings

The final-third calculation must be based on the resolved prayer times after applying:

- selected prayer calculation method;
- selected madhhab/asr setting, if relevant to shared prayer-time infrastructure;
- high-latitude rule, if relevant;
- user manual offsets for Maghrib and Fajr;
- location and timezone;
- date-specific prayer-time adjustments.

If the user adjusts Fajr begins, the final-third start should shift because `nightEnd` changed.

If the user adjusts Maghrib/sunset, the final-third start should shift because `nightStart` changed.

---

## 13. Edge cases

### 13.1 Missing Maghrib

If Maghrib/sunset for the previous evening is unavailable:

- do not calculate final third;
- fall back to Fajr begins;
- mark reason as `fallbackMissingNightData`;
- show a detail warning only if the day required early-worship support.

### 13.2 Missing Fajr

If Fajr begins is unavailable:

- wake-boundary resolution is invalid;
- the app should use the existing prayer-time error/recovery path;
- do not attempt to calculate final third.

### 13.3 High-latitude locations

If Fajr or Maghrib is estimated using a selected high-latitude method:

- final third may still be calculated from the estimated resolved times;
- set `isEstimated = true`;
- detail surfaces may say “Estimated from your selected calculation settings.”

### 13.4 Daylight saving time

Calculate using actual `Date` instants, not manually counted wall-clock hours.

Expected behavior:

- spring-forward nights may have a shorter actual duration;
- fall-back nights may have a longer actual duration;
- final-third start should reflect the real elapsed duration between resolved Maghrib and Fajr.

### 13.5 Very short or abnormal night

If `nightDuration <= 0`, treat final-third calculation as invalid and fall back to Fajr begins.

If the night is valid but unusually short, still calculate final third unless the prayer-time engine marks the times invalid.

### 13.6 Date boundaries

Never use the Maghrib on the same civil date as the Fajr morning unless that Maghrib is actually the previous evening in the local calendar system.

For morning date `D`, use Maghrib from `D - 1`.

---

## 14. Testing requirements

### 14.1 Basic calculation

Given:

```text
Maghrib = 6:00 PM
Fajr begins = 6:00 AM
```

Expected:

```text
nightDuration = 12h
finalThirdStart = 2:00 AM
```

### 14.2 Uneven duration

Given:

```text
Maghrib = 8:30 PM
Fajr begins = 5:00 AM
```

Expected:

```text
nightDuration = 8h 30m
oneThird = 2h 50m
finalThirdStart = 2:10 AM
```

### 14.3 Default day

Given:

```text
hasIntendedFasting = false
hasIntendedTahajjud = false
```

Expected:

```text
kind = fajrBegins
earliestWakeBoundary = fajrBegins
```

### 14.4 Fasting intended

Given:

```text
hasIntendedFasting = true
hasIntendedTahajjud = false
```

Expected:

```text
kind = finalThirdOfNight
earliestWakeBoundary = finalThirdStart
reason = intendedFasting
```

### 14.5 Tahajjud intended

Given:

```text
hasIntendedFasting = false
hasIntendedTahajjud = true
```

Expected:

```text
kind = finalThirdOfNight
earliestWakeBoundary = finalThirdStart
reason = intendedTahajjud
```

### 14.6 Fasting opportunity only

Given:

```text
isFastingOpportunity = true
hasIntendedFasting = false
hasIntendedTahajjud = false
```

Expected:

```text
kind = fajrBegins
earliestWakeBoundary = fajrBegins
```

### 14.7 Fasting and Tahajjud intended

Given:

```text
hasIntendedFasting = true
hasIntendedTahajjud = true
```

Expected:

```text
kind = finalThirdOfNight
earliestWakeBoundary = finalThirdStart
reason = intendedFastingAndTahajjud
```

### 14.8 Missing Maghrib

Given:

```text
previousEveningMaghrib = nil
fajrBegins = valid
hasIntendedFasting = true
```

Expected:

```text
kind = fajrBegins
earliestWakeBoundary = fajrBegins
finalThirdStart = nil
reason = fallbackMissingNightData
```

### 14.9 Manual default wake before Fajr

Given:

```text
userWakeTime < fajrBegins
hasIntendedFasting = false
hasIntendedTahajjud = false
```

Expected:

```text
kind remains fajrBegins
manual wake is treated as custom earlier wake
no fasting or Tahajjud intent is inferred
```

### 14.10 Prayer-time offset changes

Given:

```text
fajrBegins changes by +10 minutes due to user offset
```

Expected:

```text
finalThirdStart recalculates from the adjusted fajrBegins
```

---

## 15. Acceptance criteria

This feature is complete when:

1. The app calculates final-third start from previous evening Maghrib/sunset to current morning Fajr begins.
2. Default/Fajr-only days use Fajr begins as the earliest wake boundary.
3. Intended fasting days use final-third start as the earliest wake boundary.
4. Intended Tahajjud days use final-third start as the earliest wake boundary.
5. Fasting opportunity tags do not alter the boundary unless the fast is intended or auto-activated by an explicit user setting.
6. The calculation is centralized in a resolver/service layer.
7. SwiftUI views consume resolved boundary values and do not recalculate final-third logic.
8. Manual wake edits do not imply fasting or Tahajjud intent.
9. Missing Maghrib data falls back safely to Fajr begins.
10. Unit tests cover standard, uneven, fasting, Tahajjud, opportunity-only, fallback, and offset cases.

---

## 16. Non-goals

This spec does not define:

- the full prayer-time calculation method system;
- the full fasting tag taxonomy;
- the full Tahajjud planning feature;
- the alarm scheduling engine;
- the Next 7 Mornings wake forecast row layout;
- the full legal/fiqh treatment of Tahajjud, Qiyam al-Layl, Suhoor, or fasting intention.

This spec only defines the timing boundary semantics needed by those features.

---

## 17. Open decisions

### 17.1 Ramadan auto-activation

Recommended default:

```text
If the user has Ramadan fasting support enabled, Ramadan fasting days count as intended fasting unless the user disables or pauses that day.
```

This should be confirmed in the broader Ramadan/Fasting spec.

### 17.2 Adjustment range behavior

Open UX decision:

```text
Should the time adjuster hard-limit early-worship days to finalThirdStart → Fajr begins, or allow later Fajr-window wakes with warnings?
```

Recommended direction:

- allow later wakes if needed;
- warn in detail surfaces when the selected wake is after Fajr begins on a fasting/Tahajjud day;
- keep compact rows visually simple.

### 17.3 Terminology

Recommended internal term:

```text
Early Worship Boundary
```

Recommended user-facing term:

```text
Final third of the night
```

The internal term is broader and better for product architecture. The user-facing term is religiously recognizable and educational.

---

## 18. Summary

Subh should preserve two distinct wake-boundary regimes:

```text
Default / Fajr-only morning:
    earliest boundary = Fajr begins

Fasting or Tahajjud morning:
    earliest boundary = final third of the night
```

The final third is calculated from the previous evening’s Maghrib/sunset to the morning’s Fajr begins. It should be treated as the earliest meaningful boundary for early worship, not as an automatic alarm time.

This keeps Subh simple, religiously meaningful, and consistent with its product doctrine: Fajr is the daily anchor, while fasting and Tahajjud are meaningful states layered onto that anchor.
