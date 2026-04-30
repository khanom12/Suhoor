## Design Notes

### Snapshot Scope

The current app already passes a `FajrWindowCompactSnapshot` into `WeeklyFajrcastCard`. For v10, keep that shape and map:

- `summary.primaryText` -> week-level footer alarm-plan summary
- `summary.secondaryText` -> optional week-level fasting/special context summary
- `selectedDay` -> focused-day callout and focused-day accessibility text

This keeps the change narrow while preserving the product distinction from v10: the visible footer is anchored to the seven-day window, while focused-day exact Fajr text moves to accessibility/detail surfaces and the chart.

### Header Pill

The compact pill should no longer use Hijri text. Resting mode composes full-month Gregorian range text from the visible seven days. Active inspection mode composes the focused single Gregorian date.

The SwiftUI implementation cannot cheaply measure every localized range candidate without adding a more invasive measurement pass. For this iteration, use a stable layout width derived from the English design reference (`September 30-October 6`) scaled by Dynamic Type, with room for future localization measurement. The rendered content itself still uses `DateFormatter` with the current locale.

### Chart Layout

The compact chart currently models the top region as callout space and the bottom region as x-axis space. v10 swaps those roles:

1. top x-axis label row
2. x-axis-to-plot gap
3. static plot scale
4. plot-to-callout gap
5. bottom focused callout
6. bottom callout-to-divider spacing

The selected guide, selected marker, top weekday label, and bottom callout continue to use the same selected date key and column position.

### In-Chart Boundary Labels

`Fajr begins` and `Fajr ends` labels are visual identifiers for the two band boundaries. They should be anchored near the plot's leading edge, not to the focused day. Use the first visible render point for vertical placement because it represents the left/past side of the visible window. Clamp the labels inside the plot with small offsets so they remain visible.

### Footer Summary

Line 1 should be generated from the anchored visible rows:

- adjusted rows win when any explicit override/skipped row is visible
- otherwise, the common relation text produces `Default alarm: ...`
- if no rows are available, use a calm missing-data summary

Line 2 should summarize fasting at week level:

- explicit non-Ramadan fasting rows produce day-list or count copy
- Ramadan rows do not produce repetitive fasting copy
- ordinary non-Ramadan rows may show `No fasting days are planned this week.` to exercise the fuller v10 footer treatment

The visible footer must not include focused-day exact Fajr begin/end times or day-specific fasting sentences.

### Accessibility

The card and chart accessibility value should still communicate the focused day, alarm/off status, and exact Fajr begin/end times with correct tense. This restores the focused-day exact information removed from the visible footer.
