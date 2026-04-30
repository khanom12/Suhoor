## ADDED Requirements

### Requirement: Home Weekly Fajrcast uses a Gregorian-only fixed header pill
The Weekly Fajrcast compact header pill SHALL display Gregorian date text only and SHALL use a stable width across resting and active inspection modes.

#### Scenario: Resting pill shows anchored Gregorian range
- **GIVEN** the Weekly Fajrcast has seven visible days
- **WHEN** no chart inspection gesture is active
- **THEN** the header pill SHALL show the visible Gregorian week range with full month names
- **AND** it SHALL NOT include Hijri or secondary-calendar text

#### Scenario: Active inspection pill shows focused Gregorian date
- **GIVEN** the user is inspecting a visible day in the Weekly Fajrcast chart
- **WHEN** the focused day changes during the gesture
- **THEN** the header pill SHALL show that focused day's single Gregorian date
- **AND** the pill SHALL return to the anchored range when inspection ends

#### Scenario: Pill width remains stable across content changes
- **GIVEN** the Weekly Fajrcast header pill changes between range and single-date text
- **WHEN** the week or focused day changes
- **THEN** the pill capsule SHALL keep a stable width for the current text-size stop

### Requirement: Home Weekly Fajrcast uses v10 top-axis and bottom-callout layout
The Weekly Fajrcast compact chart SHALL render weekday initials above the plot and the focused-day callout below the plot.

#### Scenario: Weekday labels render above the plot
- **GIVEN** the Weekly Fajrcast compact chart is rendered
- **WHEN** the chart lays out its compact axis labels
- **THEN** the seven weekday initials SHALL sit above the plotted Fajr band
- **AND** the selected weekday initial SHALL align with the selected guide and selected marker

#### Scenario: Focused callout renders below the plot
- **GIVEN** the Weekly Fajrcast compact chart is rendered
- **WHEN** the focused-day callout is drawn
- **THEN** the callout SHALL sit below the plotted Fajr band
- **AND** it SHALL align with the focused day column
- **AND** it SHALL keep the prior callout contents, typography, and snap-back behavior

### Requirement: Home Weekly Fajrcast shows in-chart Fajr boundary labels
The Weekly Fajrcast compact chart SHALL show readable `Fajr begins` and `Fajr ends` labels near the left side of the plot.

#### Scenario: Boundary labels identify the band
- **GIVEN** the compact chart has renderable Fajr begin and Fajr end values
- **WHEN** the chart is drawn
- **THEN** `Fajr begins` SHALL appear near the Fajr begin boundary
- **AND** `Fajr ends` SHALL appear near the Fajr end boundary
- **AND** both labels SHALL be at least the compact axis-label size
- **AND** the labels SHALL NOT move with scrub focus

### Requirement: Home Weekly Fajrcast footer summarizes the anchored week
The Weekly Fajrcast compact footer SHALL describe the anchored seven-day window rather than the focused day.

#### Scenario: Ordinary week shows default alarm and no-fasting context
- **GIVEN** the visible week follows a common default alarm rule
- **WHEN** the compact summary is generated
- **THEN** the primary footer line SHALL summarize the default alarm rule
- **AND** the secondary footer line MAY state that no fasting days are planned this week
- **AND** neither line SHALL include focused-day exact Fajr begin/end times

#### Scenario: Adjusted week shows adjusted wake summary
- **GIVEN** the visible week includes date-specific wake overrides or skipped days
- **WHEN** the compact summary is generated
- **THEN** the primary footer line SHALL summarize the adjusted wake morning count
- **AND** the footer SHALL NOT show focused-day alarm relation copy

#### Scenario: Non-Ramadan fasting week shows week-level fasting summary
- **GIVEN** the visible week includes explicit non-Ramadan fasting context
- **WHEN** the compact summary is generated
- **THEN** the secondary footer line SHALL summarize fasting at the week level
- **AND** it SHALL NOT use day-specific copy such as `Tomorrow is a fasting day.`

#### Scenario: Ramadan week suppresses repetitive fasting footer line
- **GIVEN** the visible week is tagged as Ramadan
- **WHEN** the compact summary is generated
- **THEN** the footer SHALL NOT show a line implying every Ramadan day is a fasting day

### Requirement: Home Weekly Fajrcast accessibility preserves focused Fajr detail
The Weekly Fajrcast accessibility summary SHALL continue to describe the focused day with exact Fajr begin/end times even though the visible footer is week-level.

#### Scenario: Focused day accessibility includes exact Fajr boundaries
- **GIVEN** the Weekly Fajrcast has a focused selected day
- **WHEN** the card accessibility value is composed
- **THEN** it SHALL include the focused day label
- **AND** it SHALL include alarm/off status
- **AND** it SHALL include exact Fajr begin and end times with correct tense
