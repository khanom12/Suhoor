# Design: Center Interactive Weekly Fajrcast

## Current State

The compact Weekly Fajrcast is rendered by `WeeklyFajrcastCard` and uses `FajrWindowCompactSnapshot`. The snapshot is currently assembled from `activeDaysForWeeklyFajrcast`, which starts at tomorrow and returns the next seven resolved days. The card footer visually renders one summary sentence. The compact chart can expose selection callbacks, but its touch overlay is only active for the detail layout.

The current app OpenSpec defines a single Subh home surface rather than a tab-first Wake screen. This change treats the provided Wake language as the card's product identity while preserving the current app placement.

## Data Flow

1. Resolve the compact selected date.
   - If a caller provides `selectedDateKey`, parse it and use that date when possible.
   - Otherwise use the next relevant morning:
     - today if today's wake has not passed
     - tomorrow otherwise
2. Generate active days from `selectedDate - 3` through `selectedDate + 3`.
   - Use the active-day resolver when coordinates are available.
   - Avoid silently switching back to a future-only week.
3. Build the compact dataset and pass the selected date key through the surface provider.
4. Build footer data:
   - `summary.primaryText`: exact selected-day Fajr begin/end line.
   - `summary.secondaryText`: selected wake/off relation sentence.
   - `compactInsight`: week-level DST/adjusted/fasting insight when present, falling back to the existing compact insight.

## Interaction

The compact chart becomes selectable:

- `WeeklyFajrcastCard` accepts selection callbacks.
- `FajrWindowChartView` enables the existing nearest-point drag/tap overlay for compact layout.
- The home surface keeps the currently selected compact date in local view state.
- Selecting a day sets that date as selected; the schedule manager rebuilds the compact snapshot centered around that date.
- Opening the detail screen uses the current selected date.
- The card suppresses immediate open when a chart selection gesture was just handled.

For accessibility, the compact chart receives label/value/hint and increment/decrement callbacks where the host can provide them.

## Visual Updates

- Remove inline compact chart text labels for `FAJR BEGINS` and `FAJR ENDS`.
- Keep the Fajr band and two boundary lines as the visual boundary language.
- Render band and boundary lines before the selected-day guide, then non-selected markers, then selected marker.
- Increase compact axis/callout/footer base sizes:
  - x/y axis: 13 base, larger at accessibility sizes
  - callout label: 13 base
  - callout time: 18 base
  - callout suffix: 11 base
  - footer: 13 base
- Widen the selected callout and y-axis rail for larger text.
- Allow the card to grow instead of clipping footer or chart text.

## Footer

The footer becomes a two-level information area:

1. Mandatory primary line:
   `Fajr begins at {beginTime} • Fajr ends at {endTime}`
2. Optional secondary wake/off sentence:
   `Tomorrow's alarm is 30 minutes before Fajr begins.`

The first line remains the visual priority. The second line can wrap or be omitted only when data is unavailable.

## Testing

Tests should cover behavior rather than only styling:

- selected date appears at index 3 when the input active days are centered
- compact footer primary line uses selected-day Fajr begin/end times
- compact footer secondary line uses selected-day wake/off wording
- adjusted-week insight remains available outside the visual primary footer
- compact y-axis keeps four ticks
- weekday initials still match the visible seven days

## Migration Notes

No persisted schema migration is required. This change affects snapshot construction, presentation state, compact chart gestures, and tests.
