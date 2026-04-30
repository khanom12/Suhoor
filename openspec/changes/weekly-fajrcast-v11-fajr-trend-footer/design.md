## Overview

Weekly Fajrcast v11 keeps the v10 anchored chart and scrub model intact, but changes what the compact footer is allowed to say. The footer should no longer summarize the weekly alarm plan or generic fasting state. Instead, it should describe how Fajr begins shifts from the first visible day to the last visible day, and optionally surface a named special non-Ramadan fasting opportunity when the data layer already supplies that context.

## Data And Copy

- Build footer primary text from the resolved weekly rows, using the first and last visible rows' `fajrStartMinutes`.
- If the final visible Fajr begin is earlier than the first by at least two minutes, use `Fajr begins {n} minutes earlier by week’s end.`
- If the final visible Fajr begin is later than the first by at least two minutes, use `Fajr begins {n} minutes later by week’s end.`
- If the absolute delta is less than two minutes, use `Fajr begins around the same time this week.`
- Use `1 minute` for a one-minute delta if the threshold later allows that case.
- Keep annual earliest/latest detection out of this pass unless the resolved dataset exposes an explicit annual-extreme marker. The renderer must not infer annual extremes from seven rows.
- Build footer secondary text only from qualifying special non-Ramadan tags already present on resolved rows.
- Suppress Ramadan, White Days, Monday/Thursday, generic fasting, no-fasting, adjusted, quiet, no-alarm, and default-alarm footer copy.

## Qualifying Special Fasting

Use existing resolved context tags rather than inventing new religious logic:

- `arafah` -> `Arafah`
- `ashura` -> `Ashura`
- `dhulHijjahFirstNine` -> `Dhul Hijjah days`

If the row is also a fasting context, treat the opportunity as planned and use `Fasting planned: {name} on {weekday}.` for single-day observances. Otherwise use `Fasting opportunity: {name} on {weekday}.`

If multiple qualifying days are present for Dhul Hijjah, use `Fasting planned on {count} special days this week.` when fasting is explicitly planned, otherwise `Fasting opportunity: Dhul Hijjah days this week.`

## Layout

- Update non-accessibility minimum card heights to v11: 266, 268, 270, 272, 284, 296, 310 for the seven standard stops.
- Increase footer bottom breathing space to 16, 20, or 22 points depending on the text stop, with accessibility using `max(22, 0.75 * scaledFooterLineHeight)`.
- Reduce bottom callout-to-divider spacing to 4, 5, or 6 points depending on the text stop, with accessibility using `max(6, 0.28 * scaledCalloutLineHeight)`.
- Do not change the static plot scale height or y-axis rail model in this pass.

## Accessibility

The selected-day accessibility value should continue to include focused-day alarm/off state and Fajr begin/end tense. The card-level accessibility summary will naturally include the new week-level Fajr trend through the compact summary value.

## Risks

- The current data model exposes only string tags and fasting-context booleans, not a dedicated `SpecialFastingSummary`; this implementation maps existing resolved tags conservatively and suppresses ambiguous routine contexts.
- Annual earliest/latest copy is intentionally not generated without an explicit data-layer marker.
