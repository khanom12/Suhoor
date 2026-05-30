# Fajr Time Calculation, Determination, and Selection Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-fajr-time-calculation-determination-selection-spec-v1.md` |
| Version | 1 |
| Spec status | Draft; canonical Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-early-worship-boundary-spec-v2.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md` |
| Owning domain / surface | Prayer-time calculation and method/source selection |
| Implementation audit status | Needs implementation audit |

## Purpose
Define how Subh calculates, selects, explains, and audits Fajr begin, supported Fajr end, Maghrib, calculation methods, source metadata, and related prayer-window assumptions.

## What This Spec Owns
- Calculation method catalog and selection policy.
- Fajr begin/end and Maghrib boundary calculation requirements.
- High-latitude, adjustment, rounding, and diagnostics rules that other morning specs consume.

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


## May 29 Fajr Boundary / Hero Handoff Alignment Addendum

Fajr begin/end times drive both wake-window copy and hero handoff behavior.

- Fajr purpose follow-up alarms must not continue after Fajr ends.
- Suhoor purpose follow-up alarms must not continue after Fajr begins.
- Suhoor mode still triggers the Fajr-begins event at Fajr begins.
- At Fajr end, the Home Hero switches to the next morning.
- Hero copy should use `Fajr begins at 5:21 AM`, `Fajr ends at 6:31 AM`, `30 min before Fajr begins`, and `30 min before Fajr ends` patterns.

## MVP Source-Selection Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- Local calculation-method selection remains the MVP path.
- API/provider-backed timetable sources and mosque timetable source selection are future work unless a later canonical implementation plan promotes them.
- Specs and UI must not imply provider/mosque source support is complete before code and tests prove it.
- The app should continue to preserve metadata and architecture space for future source selection, but MVP reliability work should focus on the local calculation path and honest delivery status.

## 1. Scope

This specification defines how Subh resolves, stores, adjusts, selects, validates, and exposes Fajr-related prayer-time boundaries.

It covers:

- Fajr begin calculation
- Fajr end / sunrise boundary resolution
- calculation-method modeling
- high-latitude handling
- location and timezone inputs
- user minute-by-minute manual adjustments
- API / provider feasibility
- method/source selection rules
- data contracts consumed by the Morning Hero, Weekly Fajrcast, scheduling, and alarm-resolution systems
- migration requirements from the current codebase
- test and validation requirements

It does **not** define the visual design of the Morning Hero or Weekly Fajrcast card. Those surfaces consume resolved prayer-window data from this specification.

## 2. One-sentence definition

**Subh resolves each morning’s Fajr window from a selected authority method, selected location, local timezone, high-latitude policy, optional provider source, and user minute adjustments, then exposes one consistent resolved prayer-window snapshot to all scheduling and display surfaces.**

## 3. Product intent

Subh is a Fajr-centered morning system. The prayer-time engine must therefore be calm, explicit, predictable, and trustworthy.

The user should never wonder:

- which method is being used
- whether Fajr begin was calculated locally or returned by an API
- whether Fajr end means sunrise, a mosque timetable boundary, or an invented offset
- whether a manual adjustment applies only to visible UI or also to alarms
- why their city, country, mosque, or authority differs from another published timetable
- what happens offline
- what happens at high latitudes

The system should support authority-method diversity without turning the app into a theological debate screen. The default should be reasonable, the user override should be clear, and the data contract should preserve enough metadata for diagnostics.

## 4. Current implementation audit

### 4.1 Current method list

The current `CalculationMethod` enum supports five choices:

```text
muslimWorldLeague
 المصري / Egyptian
karachi
northAmerica
makkah
```

Current Fajr depression angles:

| Current enum case | Display name | Current Fajr angle |
|---|---|---:|
| `muslimWorldLeague` | Muslim World League | 18.0° |
| `egyptian` | Egyptian | 19.5° |
| `karachi` | Karachi | 18.0° |
| `northAmerica` | North America | 15.0° |
| `makkah` | Umm al-Qura | 18.5° |

The current enum stores only a Fajr angle and a display name. It does not store full method metadata, Isha rules, Maghrib rules, midnight mode, high-latitude recommendations, country/authority hints, or method-source metadata.

### 4.2 Current local Fajr calculation path

Current `PrayerTimeCalculator.fajrDate(...)` does the following:

1. Reads latitude and longitude.
2. Reads `method.fajrAngle`.
3. Selects `.middleOfNight` high-latitude fallback when `abs(latitude) > 55`; otherwise `.none`.
4. Calls `solarTime(...)` with `zenith = 90.0 + fajrAngle` and `isMorning = true`.
5. Converts returned fractional local hours into `startOfDay + hours`.
6. Applies `adjustmentMinutes` to the resulting Fajr date.

### 4.3 Current Fajr end path

Current code resolves Fajr end by calculating sunrise with solar zenith `90.833` and no adjustment.

The current Fajr-window surface explicitly describes this as a sunrise-derived proxy. That is directionally acceptable because Fajr ends at sunrise, but the data model and copy need to stop treating it as an incidental renderer concept. It must be a first-class resolved boundary with a clear source.

### 4.4 Current downstream consumers

Current `MorningScheduleResolver.resolvePrayerWindow(...)` resolves:

```text
DailyPrayerWindow
- date
- fajrStart
- fajrEnd optional
- maghrib
```

Fajr start is calculated with the selected method and `settings.fajrAdjustmentMinutes`.

Fajr end is calculated as sunrise with no adjustment.

Maghrib is calculated as sunset with `settings.maghribAdjustmentMinutes`.

Wake anchors, wake-state classification, reminders, Fajr boundary notices, Morning Hero data, and Fajrcast data consume the resolved prayer window.

### 4.5 Current settings surface

The current settings UI supports:

- manual calculation-method selection
- Fajr adjustment from `-30...30` minutes in one-minute steps
- Maghrib adjustment from `-30...30` minutes in one-minute steps

When a setting changes, the schedule manager requests a refresh.

### 4.6 Current default method selection

The current default method selection uses timezone prefix:

```text
America/* -> North America
Europe/* or Africa/* -> Muslim World League
Asia/* -> Karachi
fallback -> Muslim World League
```

This is too coarse for a prayer-time authority system. Timezone prefix is a weak proxy for region, country, authority, or mosque practice.

### 4.7 Current data gaps

Current `DaySchedule` stores:

```text
fajrDate
maghribDate
wakeDate
reminderDate optional
boundaryDate optional
iftarDate optional
calculationMethodName
```

It does not store Fajr end / sunrise. That forces later surfaces to recover Fajr end from `DailyPrayerWindow`, decision logs, or provider-specific structures. For the product direction, Fajr begin and Fajr end must travel together as a resolved prayer-window unit.

### 4.8 Current correction list

The current implementation should be corrected in these areas:

1. **Timezone correctness:** the solar algorithm must compute day-of-year using the selected location timezone, not an implicit system timezone calendar.
2. **Method metadata:** method definitions should become full authority profiles, not only Fajr-angle values.
3. **Default selection:** method auto-selection should be country/region/authority-aware before falling back to timezone-prefix rules.
4. **High-latitude policy:** high-latitude handling should be explicit, configurable, and represented in diagnostics.
5. **Fajr end:** Fajr end should be a first-class resolved boundary, normally sunrise-derived, never a renderer-invented offset.
6. **Manual adjustments:** Fajr begin adjustment should remain; Fajr end / sunrise adjustment should be considered as a separate field if the product wants manual correction for the end boundary.
7. **Source metadata:** every resolved window should expose whether it came from local calculation, API provider, mosque timetable, or user override.
8. **Rounding:** final persisted/displayed/scheduled boundaries should use a documented minute-rounding policy.
9. **API fallback:** network APIs should not be required for alarms to work offline.
10. **Diagnostics:** resolved prayer windows should carry method ID, authority name, angle, high-latitude rule, adjustment values, location, timezone, and provider status.

## 5. Research summary

### 5.1 Prayer-time methods are authority profiles, not just labels

Most published method systems are profiles containing at least Fajr angle, Isha angle or minutes-after-Maghrib rules, and sometimes Maghrib, midnight, school, or high-latitude behavior.

For Subh’s current Fajr-centered product, the most important value is the Fajr angle. However, the data model should still support full method metadata so the app can grow without renaming or rebuilding the method system.

### 5.2 Common Fajr angles

Common published Fajr method values include:

| Method / authority | Common Fajr angle |
|---|---:|
| Muslim World League | 18.0° |
| Islamic Society of North America | 15.0° |
| Egyptian General Authority of Survey | 19.5° |
| University of Islamic Sciences, Karachi | 18.0° |
| Umm al-Qura, Makkah | 18.5° |
| Institute of Geophysics, University of Tehran | 17.7° |
| Shia Ithna-Ashari / Jafari | 16.0° |

The current Subh values for MWL, Egyptian, Karachi, North America/ISNA, and Umm al-Qura are aligned with these common values.

### 5.3 High-latitude determination is a separate policy

At high latitudes, astronomical twilight may not reach the selected Fajr depression angle on some dates. A method can therefore fail even when sunrise and sunset exist.

Common high-latitude approaches include:

```text
none
middle of night
one-seventh of night
angle-based night portion
```

Subh currently has only an automatic middle-of-night fallback at latitudes above 55°, and only when the direct solar-angle calculation fails. The new model should expose this as policy rather than hiding it in the calculator.

### 5.4 AlAdhan API feasibility

AlAdhan is feasible as an optional online provider or validation source. It supports many named calculation methods, method tuning, custom method settings, high-latitude adjustment, and calendar/time endpoints.

Use cases:

- compare Subh local results against a public provider
- fetch provider-resolved monthly calendars
- support an online provider mode for users who prefer that source
- validate new method mappings during development

Constraints:

- network availability cannot be guaranteed
- alarms must still work offline
- provider outages or changed definitions could affect user trust
- provider responses must be cached and stamped with source metadata

### 5.5 Mawaqit feasibility

Mawaqit is best treated as a mosque-timetable or partnership source, not as a generic public API provider. Available documentation indicates that its API is private and that mosque calendars or direct prayer-time links may be available through mosque/admin flows.

Use cases:

- future mosque-specific timetable import
- future selected-mosque source mode
- mosque calendar download/import where available

Constraints:

- not guaranteed as a public app-wide API
- likely requires partnership, mosque ID, or admin/user flow
- should not be the default dependency for core alarms

### 5.6 Recommended source strategy

Subh should use this strategy:

1. **Default canonical path:** in-app local calculation.
2. **Optional provider path:** AlAdhan-compatible API provider for online source mode and validation.
3. **Future mosque source:** mosque timetable import/selection, including Mawaqit-like integrations where supported.
4. **Always preserve manual adjustments:** user minute offsets apply regardless of the source.

## 6. Definitions

### Fajr begin

The start of Fajr for a local date and selected location, resolved by one of:

```text
local calculation method
provider API
mosque timetable
explicit user override
```

When locally calculated, Fajr begin is normally computed as the time when the sun is below the horizon by the method’s Fajr angle.

### Fajr end

The end of Fajr for a local date and selected location.

For Subh, the default Fajr end is the location-resolved sunrise boundary. It must be represented as a first-class boundary, not as a card-specific offset from Fajr begin.

### Sunrise proxy

A solar sunrise calculation used as Fajr end. This is the normal local-calculation source for Fajr end.

Preferred internal source label:

```text
solarSunrise
```

Allowed legacy compatibility label:

```text
sunriseProxy
```

### Calculation method

An authority profile containing prayer-time parameters and metadata.

A method is not only a display name. It includes values such as Fajr angle, Isha rule, method origin, supported region hints, and optional high-latitude recommendations.

### Determination source

The source that produced the prayer boundary:

```text
localCalculated
providerAPI
mosqueTimetable
userOverride
fallback
unavailable
```

### Manual adjustment

A user-controlled minute offset applied after the base boundary is resolved.

Manual adjustment is a correction layer. It must not silently change the calculation method definition.

### High-latitude rule

The fallback or adjustment strategy used when the direct solar depression-angle calculation is impossible or not reliable for a local date.

## 7. Core mental model

> **Choose a source, choose a method, resolve local boundaries, apply user minute adjustments, then publish one prayer-window snapshot to every surface.**

There are four separate concepts:

1. **Source:** local calculation, API provider, mosque timetable, or override.
2. **Method:** authority profile such as MWL, ISNA, Egyptian, Karachi, Umm al-Qura, etc.
3. **Boundary:** Fajr begin, Fajr end/sunrise, Maghrib, and optional future prayers.
4. **Adjustment:** user minute-level correction applied after the source/method boundary is resolved.

The renderer must not decide these values. Scheduling, Morning Hero, Weekly Fajrcast, notifications, logs, and diagnostics should consume the same resolved prayer-window snapshot.

## 8. Locked calculation requirements

1. Fajr begin is resolved by the selected prayer-time determination source and method.
2. Fajr end is a resolved boundary, normally sunrise-derived, not a renderer-invented offset.
3. Fajr begin and Fajr end must be resolved for the same local date, location, and timezone.
4. Manual Fajr begin adjustment applies after base Fajr begin is resolved.
5. Manual Fajr end adjustment, if supported, applies after base Fajr end/sunrise is resolved.
6. Adjusting Fajr begin must not move Fajr end unless the user explicitly adjusts Fajr end.
7. All scheduling and UI surfaces must use the same adjusted resolved values.
8. Local calculation must work offline.
9. API/provider data may be used only when enabled, available, valid for the selected date/location, and clearly marked.
10. Provider/API failure must fall back to a known local calculation or cached provider values according to policy.
11. High-latitude fallback must be explicit in diagnostics.
12. The app must preserve a user’s manual calculation-method choice.
13. Auto-selection may suggest or set a default method, but must not silently override a manual choice.
14. Method display names must be localizable.
15. Method raw identifiers must be stable and migration-safe.
16. A source/method change must trigger schedule refresh.
17. A location/timezone change must trigger schedule refresh.
18. Manual adjustment changes must trigger schedule refresh.
19. Missing Fajr data must not produce guessed alarms or guessed chart values.
20. Resolved values must carry enough metadata for support/debugging.

## 9. Calculation method model

### 9.1 Recommended type

Replace or wrap the current enum with a richer profile model.

```text
PrayerCalculationMethod
- id
- legacyIds[] optional
- displayName
- shortDisplayName optional
- authorityName optional
- countryOrRegionHints[]
- fajrAngleDegrees
- maghribRule optional
- ishaRule optional
- midnightMode optional
- defaultHighLatitudeRule optional
- asrJuristicMethod optional future
- sourceNotes optional
- isBuiltIn true | false
- isDeprecated true | false
```

### 9.2 Method ID rules

Use stable IDs:

```text
muslimWorldLeague
isna
northAmerica legacy alias for isna
egyptianGeneralAuthority
karachi
ummAlQura
makkah legacy alias for ummAlQura
tehran
jafari
gulf
kuwait
qatar
singapore
muis legacy alias for singapore
franceUOIF
turkeyDiyanet
russia
moonsightingCommittee
jakim
indonesiaKemenag
morocco
lisbon
custom
```

Legacy raw values must continue decoding:

| Legacy raw value | New canonical ID |
|---|---|
| `northAmerica` | `isna` |
| `makkah` | `ummAlQura` |
| `egyptian` | `egyptianGeneralAuthority` |

The visible display name may stay user-friendly even if the ID changes.

### 9.3 Minimum built-in method catalog

Subh should support the current five methods, renamed and modeled as profiles, plus a broader optional catalog.

#### Required v1 built-ins

| Canonical ID | Display name | Fajr angle | Notes |
|---|---|---:|---|
| `muslimWorldLeague` | Muslim World League | 18.0° | Existing value retained. |
| `isna` | Islamic Society of North America | 15.0° | Existing `northAmerica` value retained. |
| `egyptianGeneralAuthority` | Egyptian General Authority of Survey | 19.5° | Existing `egyptian` value retained. |
| `karachi` | University of Islamic Sciences, Karachi | 18.0° | Existing value retained. |
| `ummAlQura` | Umm al-Qura, Makkah | 18.5° | Existing `makkah` value retained. |

#### Recommended v2+ built-ins

| Canonical ID | Display name | Fajr angle / source behavior | Notes |
|---|---|---|---|
| `tehran` | Institute of Geophysics, University of Tehran | 17.7° | Useful for users following Tehran settings. |
| `jafari` | Shia Ithna-Ashari / Jafari | 16.0° | Useful for Shia/Jafari settings. |
| `gulf` | Gulf Region | Provider/profile-defined | Common API method. |
| `kuwait` | Kuwait | Provider/profile-defined | Common API method. |
| `qatar` | Qatar | Provider/profile-defined | Common API method. |
| `singapore` | Singapore / MUIS | Provider/profile-defined | Common API method. |
| `franceUOIF` | Muslims of France / UOIF | Provider/profile-defined | Common API method. |
| `turkeyDiyanet` | Turkey / Diyanet | Provider/profile-defined | Common API method. |
| `russia` | Russia | Provider/profile-defined | Common API method. |
| `moonsightingCommittee` | Moonsighting Committee | Provider/profile-defined | Common API method. |
| `jakim` | Malaysia / JAKIM | Provider/profile-defined | Common API method. |
| `indonesiaKemenag` | Indonesia / Kemenag | Provider/profile-defined | Common API method. |
| `morocco` | Morocco | Provider/profile-defined | Common API method. |
| `lisbon` | Lisbon / Comunidade Islâmica de Lisboa | Provider/profile-defined | Common API method. |

If Subh cannot confidently encode a method’s full parameters locally, the method can still appear as a provider-only option when using an API source.

### 9.4 Custom method

A future custom method should support:

```text
customFajrAngleDegrees
customIshaAngleOrMinutes optional
customMaghribAngleOrMinutes optional
customDisplayName optional
```

Custom method values must be validated:

```text
Fajr angle: 10.0°...25.0° recommended allowed range
Minute offsets: -120...180 recommended allowed range
```

Custom method settings should be hidden behind an advanced setting, not shown as the default path for ordinary users.

## 10. Determination source model

### 10.1 Source types

```text
PrayerTimeDeterminationSource
- localCalculated
- providerAPI
- mosqueTimetable
- userOverride
- fallbackLocalCalculated
- cachedProviderAPI
- unavailable
```

### 10.2 Source priority

For a given local date, location, and user settings, resolve source in this order:

1. Explicit one-day user override for that date.
2. Selected mosque timetable, if enabled, valid, and available for the date.
3. Selected API provider, if enabled, available, valid, and permitted by network/cache policy.
4. Local calculation using the selected/manual method.
5. Local calculation using auto-selected method.
6. Local calculation using fallback method.
7. Missing data.

### 10.3 Offline behavior

Subh must remain usable offline.

Required behavior:

- If API provider mode is enabled and fresh cached provider values exist, use cached values and mark source `cachedProviderAPI`.
- If no fresh provider values exist, fall back to local calculation unless the user explicitly configured “provider only.”
- If “provider only” is configured and no provider/cached value exists, show missing-data state and avoid guessed alarms.
- Alarm scheduling should prefer local calculation unless a provider/timetable snapshot is already available for the scheduling horizon.

### 10.4 Provider staleness

Recommended cache policy:

```text
single day value: valid until local date rollover unless provider revision changes
monthly calendar: valid for that local Hijri/Gregorian month unless location/method/settings change
yearly calendar: valid for that year unless provider revision/location/method/settings change
```

Provider responses should store:

```text
providerName
providerMethodId
providerRequestParameters
responseFetchedAt
responseTimeZone
responseLocation
responseCalendarMonth optional
responseCalendarYear optional
rawResponseHash
```

## 11. Method selection algorithm

### 11.1 Selection modes

```text
manual
autoByLocation
autoByProvider
mosqueSelected
custom
```

### 11.2 Manual method selection

If the user manually selects a method, preserve it.

Rules:

- Location changes do not silently change a manual method.
- The app may show a suggestion when the selected method appears unusual for the new region.
- The user can accept or ignore that suggestion.

### 11.3 Auto-by-location selection

Auto-selection should use best available locality data:

1. Fixed location country/region, if available.
2. Reverse-geocoded country/region from auto location, if available.
3. Coordinate-based country lookup, if available.
4. Timezone country hints, if available.
5. Timezone prefix fallback.
6. Muslim World League fallback.

### 11.4 Recommended auto-default map

This table is a product default map, not a religious ruling.

| Region / country hint | Suggested default method |
|---|---|
| United States, Canada | `isna` |
| Saudi Arabia | `ummAlQura` |
| Egypt | `egyptianGeneralAuthority` |
| Pakistan, India, Bangladesh, Afghanistan | `karachi` |
| Turkey | `turkeyDiyanet` if locally supported, else `muslimWorldLeague` |
| Malaysia | `jakim` if locally supported, else `muslimWorldLeague` |
| Indonesia | `indonesiaKemenag` if locally supported, else `muslimWorldLeague` |
| Singapore | `singapore` if locally supported, else `muslimWorldLeague` |
| Morocco | `morocco` if locally supported, else `muslimWorldLeague` |
| Kuwait | `kuwait` if locally supported, else `ummAlQura` or `muslimWorldLeague` based on product decision |
| Qatar | `qatar` if locally supported, else `ummAlQura` or `muslimWorldLeague` based on product decision |
| UAE / Gulf fallback | `gulf` if locally supported, else `ummAlQura` or `muslimWorldLeague` based on product decision |
| France | `franceUOIF` if locally supported, else `muslimWorldLeague` |
| Russia | `russia` if locally supported, else `muslimWorldLeague` |
| Europe general fallback | `muslimWorldLeague` |
| Africa general fallback | `muslimWorldLeague` unless country-specific method exists |
| Asia general fallback | `karachi` only when South Asia is likely; otherwise `muslimWorldLeague` |
| Unknown | `muslimWorldLeague` |

The current timezone-prefix rule should become a final fallback only.

### 11.5 Method suggestion copy

When auto-selection changes because of location:

```text
Subh suggests Islamic Society of North America for this location. You can keep your current method or switch.
```

When the user has manual method selected:

```text
Your prayer-time method is set manually. Location changes will not change it unless you choose a new method.
```

## 12. Local calculation engine spec

### 12.1 Inputs

```text
localDate
coordinate latitude/longitude
timeZone
calculationMethod
highLatitudeRule
adjustments
roundingPolicy
```

### 12.2 Date/timezone rule

All date decomposition must use the selected location timezone.

Required behavior:

```text
calendar = Gregorian calendar
calendar.timeZone = selected/resolved timeZone
```

The day-of-year, start-of-day, date keys, and displayed local dates must all be based on the same timezone.

### 12.3 Fajr begin local calculation

For methods defined by Fajr angle:

```text
zenith = 90.0 + fajrAngleDegrees
isMorning = true
```

The raw Fajr begin boundary is produced by the solar-angle algorithm for the local date and location.

Then apply:

```text
fajrBeginAdjusted = roundToMinute(fajrBeginRaw + fajrBeginAdjustmentMinutes)
```

### 12.4 Fajr end local calculation

For local calculation, Fajr end is sunrise.

```text
zenith = 90.833
isMorning = true
```

Then apply:

```text
fajrEndAdjusted = roundToMinute(sunriseRaw + fajrEndAdjustmentMinutes)
```

If `fajrEndAdjustmentMinutes` is not yet exposed, store it as `0`.

### 12.5 Maghrib local calculation

For current Subh needs, Maghrib is sunset.

```text
zenith = 90.833
isMorning = false
maghribAdjusted = roundToMinute(sunsetRaw + maghribAdjustmentMinutes)
```

### 12.6 Rounding policy

Recommended policy:

```text
roundingPolicy = nearestMinute
```

Rules:

- Store adjusted boundaries rounded to minute precision for scheduling and display.
- Keep raw unrounded values only for diagnostics.
- Do not schedule alarms at arbitrary seconds caused by floating-point solar calculations.
- If a provider returns minute-precision strings, treat them as already minute-rounded.

### 12.7 Boundary validation

After calculation and adjustment:

```text
fajrBeginAdjusted < fajrEndAdjusted
fajrEndAdjusted <= maghribAdjusted
```

If validation fails:

1. Mark the window `invalid`.
2. Record diagnostics.
3. Try configured fallback source/method if allowed.
4. If no fallback succeeds, return missing data.

### 12.8 Day rollover handling

The engine must intentionally represent boundaries that fall outside the nominal `00:00...23:59` range.

Rules:

- Do not blindly normalize every computed local hour into the same date if that loses date semantics.
- If an algorithm produces `-0.25` hours, represent that as previous local date at `23:45` only if the selected high-latitude rule intentionally requires it.
- If an algorithm produces `24.10` hours, represent that as next local date at `00:06` only if the selected rule intentionally requires it.
- Diagnostics must record when a boundary crosses local date.

For typical Fajr begin and sunrise boundaries, cross-date output should be rare and should trigger validation scrutiny.

## 13. High-latitude policy

### 13.1 Supported policies

```text
none
middleOfNight
oneSeventhOfNight
angleBased
automatic
```

### 13.2 Recommended default

Use:

```text
automatic
```

Where automatic means:

1. Attempt direct solar-angle calculation.
2. If direct calculation succeeds and passes validation, use it.
3. If direct calculation fails, apply the method’s/default high-latitude rule.
4. If no method-specific rule exists, use `angleBased`.
5. If `angleBased` fails or cannot be computed, fall back to `middleOfNight`.
6. Record the applied rule in diagnostics.

### 13.3 Existing behavior migration

Current behavior is effectively:

```text
if abs(latitude) > 55 and direct calculation fails:
    middleOfNight
else:
    none
```

Migration should preserve user-visible times as much as possible but introduce diagnostics and settings.

Recommended migration:

- Existing users keep local method and adjustments.
- New high-latitude rule defaults to `automatic`.
- If a user is above 55° latitude, show a quiet settings note explaining that Subh may use a high-latitude fallback when twilight calculation is unavailable.

### 13.4 High-latitude diagnostics

Resolved windows should include:

```text
highLatitudeRuleRequested
highLatitudeRuleApplied
highLatitudeFallbackWasUsed true | false
highLatitudeFallbackReason optional
nightLengthMinutes optional
sunriseRaw optional
sunsetRaw optional
```

## 14. Manual adjustment rules

### 14.1 Current preserved setting

Preserve existing:

```text
fajrAdjustmentMinutes
```

Recommended rename in new contract:

```text
fajrBeginAdjustmentMinutes
```

Legacy migration:

```text
fajrBeginAdjustmentMinutes = existing fajrAdjustmentMinutes
```

### 14.2 Recommended new setting

Add:

```text
fajrEndAdjustmentMinutes
```

Default:

```text
0
```

UI label:

```text
Fajr end adjustment
```

Helper copy:

```text
Adjust the sunrise/Fajr-end boundary earlier or later for your location.
```

### 14.3 Existing Maghrib setting

Preserve:

```text
maghribAdjustmentMinutes
```

### 14.4 Adjustment range

Recommended range:

```text
-30...30 minutes
step 1 minute
```

This matches the existing Fajr and Maghrib adjustment behavior.

### 14.5 Application order

For local calculation:

```text
raw boundary -> high-latitude fallback if needed -> source-specific base boundary -> user adjustment -> rounding -> validation -> publish
```

For provider/API:

```text
provider boundary -> user adjustment -> rounding/parse normalization -> validation -> publish
```

For mosque timetable:

```text
timetable boundary -> user adjustment if enabled for timetable source -> validation -> publish
```

### 14.6 Adjustment source metadata

Resolved windows should expose:

```text
adjustmentsApplied
- fajrBeginMinutes
- fajrEndMinutes
- maghribMinutes
```

This supports debugging and transparent settings screens.

## 15. Fajr end requirements

### 15.1 Product rule

Fajr end must be resolved by the prayer-window data layer.

The Morning Hero and Weekly Fajrcast must not derive Fajr end locally from Fajr begin or from visual layout.

### 15.2 Supported Fajr end sources

```text
solarSunrise
providerSunrise
providerFajrEnd
mosqueTimetable
userOverride
fallbackToFajrBegin invalid/last-resort only
unavailable
```

### 15.3 Preferred copy

Default display copy should say:

```text
Fajr ends at {time}
```

Diagnostics/support copy may say:

```text
Fajr end is based on sunrise for this date.
```

Avoid exposing “proxy” to ordinary users unless in advanced diagnostics.

### 15.4 Data rule

Every resolved day used by Morning Hero or Weekly Fajrcast should include:

```text
fajrBeginTime
fajrEndTime
fajrBeginSource
fajrEndSource
```

## 16. Provider/API specification

### 16.1 Provider role

Provider APIs are optional data sources. They are not required for core scheduling.

Allowed provider roles:

```text
validationOnly
onlinePreferredWithLocalFallback
onlineRequired
mosqueTimetableImport
```

Recommended default:

```text
validationOnly for development
local calculation for production default
```

### 16.2 AlAdhan provider

AlAdhan can be implemented as:

```text
Provider name: AlAdhan
Provider type: publicPrayerTimeAPI
```

Supported request modes:

```text
by coordinates
by city/country
by calendar month
yearly calendar if needed
custom method settings
manual tune offsets
high latitude adjustment method
```

Required mapping:

```text
AlAdhan Fajr -> fajrBeginRawProvider
AlAdhan Sunrise -> fajrEndRawProvider when no explicit FajrEnd is returned
AlAdhan Maghrib -> maghribRawProvider
method parameter -> providerMethodId
methodSettings -> custom method parameters
tune Fajr -> provider-side Fajr tuning, if used
tune Sunrise -> provider-side Fajr end/sunrise tuning, if used
```

Subh should prefer applying user adjustments locally after provider response rather than encoding user adjustments into provider `tune`, unless the selected provider mode requires provider-side tuning.

Recommended behavior:

```text
Provider returns base times.
Subh applies user adjustments.
Subh stores both provider base and adjusted final values.
```

### 16.3 Provider request metadata

Store:

```text
providerName
providerEndpointType
providerMethodId
providerLatitudeAdjustmentMethod
providerTuneUsed true | false
requestLatitude
requestLongitude
requestTimeZone
requestDateOrMonth
fetchedAt
rawResponseHash
```

### 16.4 Provider fallback behavior

If provider request fails:

| Mode | Behavior |
|---|---|
| `validationOnly` | Ignore provider failure; use local calculation. |
| `onlinePreferredWithLocalFallback` | Use cached provider if valid; else use local calculation and mark source fallback. |
| `onlineRequired` | Use cached provider if valid; else return missing data and do not guess. |
| `mosqueTimetableImport` | Use imported timetable if valid; else return missing source for affected date. |

### 16.5 Mawaqit provider

Mawaqit should be modeled as a future mosque timetable source rather than a default public API.

Recommended implementation track:

1. Add `mosqueTimetable` source type.
2. Add a provider interface that can import a mosque calendar or direct timetable feed.
3. Store mosque ID, provider name, and timetable date range.
4. Use local calculation as fallback only if user permits fallback.
5. Add explicit UI copy that the selected mosque timetable may differ from calculation methods.

### 16.6 Provider privacy

Provider requests may reveal approximate location and religious schedule usage.

Settings copy should disclose:

```text
Online prayer-time providers may receive your selected location and date range. Subh can also calculate times locally without sending location data to a prayer-time provider.
```

## 17. Data contract

### 17.1 PrayerCalculationSettings

```text
PrayerCalculationSettings
- methodSelectionMode manual | autoByLocation | autoByProvider | mosqueSelected | custom
- methodId
- sourcePreference localCalculated | providerAPI | mosqueTimetable
- providerId optional
- mosqueTimetableId optional
- highLatitudeRule automatic | none | middleOfNight | oneSeventhOfNight | angleBased
- fajrBeginAdjustmentMinutes
- fajrEndAdjustmentMinutes
- maghribAdjustmentMinutes
- roundingPolicy nearestMinute | floorMinute | ceilMinute
- allowLocalFallbackFromProvider true | false
- allowManualAdjustmentsForTimetableSource true | false
```

### 17.2 ResolvedPrayerWindow

```text
ResolvedPrayerWindow
- dateKey
- localDate
- coordinate
- locationDescription optional
- timeZoneIdentifier
- calculationSource localCalculated | providerAPI | cachedProviderAPI | mosqueTimetable | userOverride | fallbackLocalCalculated | unavailable
- methodId
- methodDisplayName
- authorityName optional
- fajrAngleDegrees optional
- highLatitudeRuleRequested
- highLatitudeRuleApplied optional
- highLatitudeFallbackWasUsed true | false
- fajrBeginRaw optional
- fajrBeginAdjusted optional
- fajrBeginDisplayText optional
- fajrBeginSource localSolarAngle | providerAPI | mosqueTimetable | userOverride | unavailable
- fajrEndRaw optional
- fajrEndAdjusted optional
- fajrEndDisplayText optional
- fajrEndSource solarSunrise | providerSunrise | providerFajrEnd | mosqueTimetable | userOverride | unavailable
- sunriseRaw optional
- sunriseAdjusted optional
- maghribRaw optional
- maghribAdjusted optional
- maghribSource localSolarSunset | providerAPI | mosqueTimetable | userOverride | unavailable
- adjustmentsApplied
- diagnostics
- loadingState ready | loading | partial | missingData | error
```

### 17.3 PrayerBoundaryAdjustment

```text
PrayerBoundaryAdjustment
- fajrBeginMinutes
- fajrEndMinutes
- maghribMinutes
```

### 17.4 PrayerCalculationDiagnostics

```text
PrayerCalculationDiagnostics
- engineVersion
- methodVersion
- sourceVersion optional
- locationAccuracyMeters optional
- inputLatitude
- inputLongitude
- inputTimeZoneIdentifier
- dayOfYearUsed
- solarAlgorithmName
- rawFajrHour optional
- rawSunriseHour optional
- rawSunsetHour optional
- highLatitudeFailureReason optional
- validationWarnings[]
- providerRequestMetadata optional
- fallbackChain[]
```

### 17.5 DaySchedule extension

Extend the current day schedule or replace it with a structure that includes the full prayer window.

Recommended:

```text
DaySchedule
- date
- prayerWindow ResolvedPrayerWindow
- wakeDate
- reminderDate optional
- boundaryDate optional
- iftarDate optional
- calculationMethodName derived from prayerWindow
```

If maintaining legacy fields:

```text
fajrDate = prayerWindow.fajrBeginAdjusted
fajrEndDate = prayerWindow.fajrEndAdjusted
maghribDate = prayerWindow.maghribAdjusted
```

### 17.6 WeeklyFajrcast integration fields

Every `FajrcastDay` should receive:

```text
fajrBeginTime = ResolvedPrayerWindow.fajrBeginAdjusted
fajrEndTime = ResolvedPrayerWindow.fajrEndAdjusted
fajrBeginSource
fajrEndSource
calculationMethodId
calculationSource
adjustmentsApplied
```

### 17.7 MorningHero integration fields

`MorningHeroSnapshot` should receive:

```text
fajrBeginTime
fajrEndTime
fajrBeginDisplayText
fajrEndDisplayText
fajrBeginSource
fajrEndSource
calculationMethodId
calculationSource
adjustmentsApplied
```

## 18. Settings requirements

### 18.1 Prayer-time settings section

The settings section should include:

```text
Calculation source
Calculation method
High-latitude handling
Fajr begin adjustment
Fajr end adjustment
Maghrib adjustment
Diagnostics / last resolved method optional
```

### 18.2 Calculation source UI

Recommended values:

```text
Calculate in Subh
Use online provider
Use mosque timetable
```

Default:

```text
Calculate in Subh
```

### 18.3 Calculation method UI

The method picker should show:

```text
method display name
authority/region subtitle
Fajr angle when useful
selected checkmark
```

Examples:

```text
Islamic Society of North America
Common North America setting • Fajr 15°

Muslim World League
Common global fallback • Fajr 18°

Umm al-Qura, Makkah
Saudi Arabia setting • Fajr 18.5°
```

### 18.4 Auto-selection UI

If the method is auto-selected:

```text
Automatically selected for {location/region}
```

If manually selected:

```text
Manually selected
```

### 18.5 Adjustment UI

Preserve the current relative offset control behavior:

```text
range: -30...30
step: 1
```

Suggested labels:

```text
Fajr begin adjustment
Fajr end adjustment
Maghrib adjustment
```

Helper copy:

```text
Use this only if your local authority or mosque publishes slightly different times.
```

### 18.6 Diagnostics UI

Optional advanced diagnostics:

```text
Resolved by Subh local calculation
Method: Islamic Society of North America
Fajr angle: 15°
Fajr begin adjustment: +2 min
Fajr end source: Sunrise
High-latitude rule: Not used
Location: Toronto, Canada
Timezone: America/Toronto
```

## 19. Morning Hero integration

The Morning Hero must consume a resolved prayer window.

Rules:

- The hero must not calculate Fajr begin.
- The hero must not calculate Fajr end.
- The hero must not infer method selection.
- The hero may display method/source metadata only if a future design requires it.
- The hero must use the same Fajr begin/end values that scheduling and Weekly Fajrcast use.
- If Fajr begin or Fajr end is missing, the hero must show missing-data copy and avoid guessed relation text.

Recommended mapping:

```text
MorningHeroSnapshot.fajrBeginTime = ResolvedPrayerWindow.fajrBeginAdjusted
MorningHeroSnapshot.fajrEndTime = ResolvedPrayerWindow.fajrEndAdjusted
MorningHeroSnapshot.fajrEndSource = ResolvedPrayerWindow.fajrEndSource
```

## 20. Weekly Fajrcast integration

The Weekly Fajrcast card must consume resolved prayer windows for each visible day.

Rules:

- Fajr begin/end values come from the data layer.
- The chart band connects the resolved Fajr begin and resolved Fajr end values.
- The footer uses the same values as the chart.
- The renderer must not derive Fajr end from Fajr begin.
- If a day is missing Fajr end, that day is partial/missing and must not be connected with fake continuity.
- The data layer should precompose footer strings using the resolved begin/end values.

Recommended mapping:

```text
FajrcastDay.fajrBeginTime = ResolvedPrayerWindow.fajrBeginAdjusted
FajrcastDay.fajrEndTime = ResolvedPrayerWindow.fajrEndAdjusted
FajrcastDay.fajrEndSource = ResolvedPrayerWindow.fajrEndSource
```

## 21. Scheduling integration

Wake scheduling must use the adjusted resolved prayer window.

Rules:

- Wake anchors referencing Fajr begin use `fajrBeginAdjusted`.
- Wake anchors referencing Fajr end use `fajrEndAdjusted`.
- Fajr-start boundary notices use `fajrBeginAdjusted`.
- Fajr window classification uses `fajrBeginAdjusted` and `fajrEndAdjusted`.
- Reminders relative to Fajr begin use `fajrBeginAdjusted`.
- Fasting/Tahajjud comparisons use the same resolved prayer-window snapshot.

## 22. Migration plan

### 22.1 Settings migration

Existing fields:

```text
calculationMethod
fajrAdjustmentMinutes
maghribAdjustmentMinutes
```

New fields:

```text
calculationMethodId
methodSelectionMode
fajrBeginAdjustmentMinutes
fajrEndAdjustmentMinutes
maghribAdjustmentMinutes
highLatitudeRule
sourcePreference
```

Migration:

```text
calculationMethodId = migrated existing calculationMethod
methodSelectionMode = manual if user changed method, otherwise autoByLocation if detectable, else manual/current
fajrBeginAdjustmentMinutes = existing fajrAdjustmentMinutes
fajrEndAdjustmentMinutes = 0
maghribAdjustmentMinutes = existing maghribAdjustmentMinutes
highLatitudeRule = automatic
sourcePreference = localCalculated
```

If it is not possible to know whether the user manually changed the calculation method, preserve current method as manual for existing users. New users can use auto-by-location.

### 22.2 Method ID migration

```text
muslimWorldLeague -> muslimWorldLeague
egyptian -> Egyptian General Authority / canonical egyptianGeneralAuthority
karachi -> karachi
northAmerica -> isna with legacy alias northAmerica
makkah -> ummAlQura with legacy alias makkah
```

### 22.3 Data model migration

Add `fajrEndDate` or `prayerWindow` to schedule snapshots.

For existing cached schedules:

- If decision log has `prayerWindow.fajrEnd`, use it.
- Else recompute schedules.
- Else mark cache stale and refresh.

### 22.4 Cache invalidation

Invalidate cached schedules when any of these change:

```text
location
timezone
calculation source
provider ID
method ID
custom method params
high latitude rule
fajrBeginAdjustmentMinutes
fajrEndAdjustmentMinutes
maghribAdjustmentMinutes
rounding policy
engine version
```

## 23. Testing requirements

### 23.1 Unit tests

Add tests for:

- current five method angle mappings
- legacy raw value migration
- manual Fajr begin adjustment applied
- manual Fajr end adjustment applied when added
- Maghrib adjustment applied
- Fajr begin adjustment does not alter Fajr end
- Fajr end is sunrise-derived in local mode
- timezone-specific day-of-year calculation
- DST transition day
- high-latitude fallback path
- invalid window detection
- provider fallback chain
- missing-data behavior

### 23.2 Golden-date tests

Maintain golden tests for representative locations:

```text
Toronto / America/Toronto / ISNA
New York / America/New_York / ISNA
Makkah / Asia/Riyadh / Umm al-Qura
Cairo / Africa/Cairo / Egyptian
Karachi / Asia/Karachi / Karachi
London / Europe/London / MWL or configured UK default
Stockholm / Europe/Stockholm / high-latitude case
Tromsø / Europe/Oslo / high-latitude fallback case
Singapore / Asia/Singapore / Singapore/MUIS or MWL fallback
Kuala Lumpur / Asia/Kuala_Lumpur / JAKIM or MWL fallback
Jakarta / Asia/Jakarta / Indonesia/Kemenag or MWL fallback
```

Golden tests should compare:

```text
fajrBeginAdjusted
fajrEndAdjusted
maghribAdjusted
source metadata
high-latitude rule applied
```

### 23.3 Cross-surface tests

Add tests proving:

- Morning Hero and Weekly Fajrcast receive identical Fajr begin/end values for the same date.
- Wake scheduling uses the same Fajr begin/end values shown in the UI.
- Changing method refreshes schedules and surfaces.
- Changing manual adjustment refreshes schedules and surfaces.
- Offline mode still resolves schedules locally.

### 23.4 API validation tests

When API provider mode is implemented:

- Stub provider responses.
- Verify response parsing.
- Verify provider Fajr maps to Fajr begin.
- Verify provider Sunrise maps to Fajr end when needed.
- Verify user adjustments are applied after provider response.
- Verify local fallback on network failure.
- Verify `onlineRequired` missing-data behavior.

## 24. Implementation plan

### Phase 1 — Correct and stabilize local calculation

1. Set timezone on the calendar used for day-of-year in the solar calculator.
2. Add minute-rounding policy.
3. Add calculation diagnostics.
4. Add explicit `fajrEndSource = solarSunrise`.
5. Add Fajr end to schedule/day data model.
6. Preserve existing method and adjustment behavior.
7. Add tests for the current five methods and adjustment path.

### Phase 2 — Rich method model and migration

1. Introduce `PrayerCalculationMethod` profile model.
2. Migrate current enum raw values.
3. Rename `northAmerica` display to ISNA / Islamic Society of North America.
4. Rename `makkah` canonical ID to `ummAlQura` while preserving legacy decode.
5. Add method metadata and region hints.
6. Add country/region-aware auto-selection.
7. Add settings copy for auto/manual method state.

### Phase 3 — High-latitude policy

1. Add high-latitude rule setting.
2. Implement `automatic`, `angleBased`, `oneSeventhOfNight`, `middleOfNight`, and `none`.
3. Add diagnostics and support copy.
4. Add high-latitude golden tests.

### Phase 4 — Fajr end adjustment

1. Add `fajrEndAdjustmentMinutes` to settings.
2. Add UI control.
3. Apply adjustment after sunrise/provider/timetable boundary resolution.
4. Update scheduling and Fajr window snapshots.
5. Add tests proving Fajr begin and end adjust independently.

### Phase 5 — Provider interface

1. Add provider protocol.
2. Implement AlAdhan provider in validation-only mode.
3. Add provider cache.
4. Add provider source metadata.
5. Add optional online-preferred mode.
6. Add privacy copy.

### Phase 6 — Mosque timetable source

1. Add `mosqueTimetable` source model.
2. Support static imported timetables.
3. Add Mawaqit-style provider adapter only if a reliable feed/partnership/import path exists.
4. Add source fallback settings.

## 25. Acceptance criteria

### Local calculation

- [ ] Current five methods continue to produce expected Fajr begin values.
- [ ] Solar day-of-year uses the selected timezone.
- [ ] Fajr begin adjustment applies in one-minute increments.
- [ ] Fajr end resolves as sunrise in local mode.
- [ ] Fajr end source metadata is present.
- [ ] Maghrib adjustment still works.
- [ ] All final boundaries are rounded to minute precision.
- [ ] Invalid windows are detected.

### Method selection

- [ ] Existing user method settings migrate safely.
- [ ] Manual method selections are preserved across location changes.
- [ ] Auto selection uses region/country when available.
- [ ] Timezone-prefix fallback remains only as fallback.
- [ ] Method picker displays clear names and descriptions.

### High latitude

- [ ] High-latitude rule is explicit in settings or diagnostics.
- [ ] Automatic fallback is documented.
- [ ] Fallback-used status is stored in diagnostics.
- [ ] High-latitude missing-data cases do not produce guessed alarms.

### Provider/API

- [ ] Provider source is optional.
- [ ] Local calculation works offline.
- [ ] Provider values include source metadata.
- [ ] Provider failures fall back according to selected policy.
- [ ] User adjustments apply after provider response unless explicitly configured otherwise.

### Cross-surface consistency

- [ ] Morning Hero and Weekly Fajrcast use the same Fajr begin/end values.
- [ ] Scheduling uses the same values shown to the user.
- [ ] Fajr end is never derived by a renderer.
- [ ] Manual adjustment changes refresh schedules and all visible surfaces.

## 26. Open questions for next iteration

1. Should existing users be marked as `manual` method selection during migration, or should the app infer whether the current method was default-selected?
2. Should Fajr end adjustment be exposed immediately, or added only to advanced settings?
3. Should API provider mode ever be enabled by default, or remain validation/advanced only?
4. Should the app support custom Fajr angles in the first release of this spec?
5. Should auto-selection rely on reverse geocoded country, coordinate boundary lookup, or both?
6. Should mosque timetable sources allow manual adjustments by default?
7. Should provider-returned tuning be represented as source data or merged with user adjustments?
8. What exact region defaults should be used for countries with multiple common local authorities?
9. Should high-latitude `automatic` default to angle-based, one-seventh, or preserve current middle-of-night compatibility for existing users?
10. Should diagnostics be visible to ordinary users, or only through a support/debug screen?

## 27. Final design intent

The Fajr calculation system should be boring in the best possible way: stable, transparent, precise, offline-capable, and consistent across the app.

Subh should calculate locally by default, preserve the user’s manual method and minute adjustments, expose Fajr begin and Fajr end as resolved data-layer truth, and treat APIs as optional provider sources rather than mandatory infrastructure. Fajr end should be understood as the selected location’s sunrise/Fajr-end boundary, not as a chart approximation. High-latitude behavior should be explicit and testable. Method selection should become region-aware without taking control away from the user.

When this spec is implemented, the Morning Hero, Weekly Fajrcast, schedule builder, notification scheduler, and alarm resolver should all point to the same resolved prayer-window snapshot. A user changing method, source, location, high-latitude rule, or manual adjustment should see one coherent recalculation everywhere.

## Appendix A — Repository audit basis

Current code paths reviewed:

```text
Subh/Core/Services/PrayerTimeCalculator.swift
Subh/Core/Models/CalculationMethod.swift
Subh/Core/Models/AppSettings.swift
Subh/Core/Services/DayScheduleBuilder.swift
Subh/Core/Models/DaySchedule.swift
Subh/Core/Services/ScheduleService.swift
Subh/Core/Services/ResolvedDayPipeline.swift
Subh/Core/Scheduling/MorningResolver.swift
Subh/Features/Settings/PrayerTimeSettingsView.swift
Subh/Core/Services/LocationService.swift
Subh/Core/Services/FajrWindowSurfaceProvider.swift
Subh/Core/FajrWindowSurfaceModels.swift
```

Uploaded product specs reviewed:

```text
subh-weekly-fajrcast-card-spec-v8.md
subh-morning-hero-item-spec-v3.md
```

External research reviewed:

```text
AlAdhan calculation method documentation
AlAdhan timing API parameter documentation
PrayTimes calculation method documentation
PrayTimes high-latitude and tuning documentation
PrayTime.info high-latitude method notes
Mawaqit API and calendar availability documentation
```
