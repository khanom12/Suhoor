## ADDED Requirements

### Requirement: Morning Hero uses v0.2 date-first anatomy
The home surface SHALL render the Morning Hero in v0.2 order: compact date line, relative day label, primary wake row, wake relation/status line, and Fajr-window range visual or missing-data fallback.

#### Scenario: Active wake plan is available
- **GIVEN** the home snapshot has resolved an active wake plan for the next relevant morning
- **AND** the snapshot has Gregorian date, Hijri date, wake time, relation text, Fajr begin, and Fajr end strings
- **WHEN** the home hero renders
- **THEN** it SHALL show the compact date line as the first visible row
- **AND** the visible Gregorian date SHALL omit weekday
- **AND** it SHALL show the relative day label directly below the date line
- **AND** it SHALL show the wake time as the primary largest value with an alarm-state indicator
- **AND** it SHALL show relation text that names `Fajr begins` or `Fajr ends`

#### Scenario: Hijri date is unavailable
- **GIVEN** the home snapshot has no Hijri date text for the target morning
- **WHEN** the home hero renders its date line
- **THEN** it SHALL show the weekday-free Gregorian date without an empty delimiter

### Requirement: Morning Hero renders a Fajr-window range visual
The home hero SHALL render resolved Fajr begin and Fajr end times as a compact range visual with an optional wake/off-anchor marker positioned relative to the resolved Fajr window.

#### Scenario: Active wake marker is within Fajr window
- **GIVEN** the hero has Fajr begin time, Fajr end time, and an active wake time inside that interval
- **WHEN** the range visual renders
- **THEN** it SHALL show only the begin and end times as visible text in the range row
- **AND** it SHALL render a horizontal Fajr-window bar between those times
- **AND** it SHALL position a visible active wake marker on the bar according to the resolved wake ratio
- **AND** it SHALL NOT show visible `Fajr begins` or `Fajr ends` labels in the default range row

#### Scenario: Wake marker is outside Fajr window
- **GIVEN** the hero has Fajr begin time, Fajr end time, and a resolved wake time before Fajr begin or after Fajr end
- **WHEN** the range visual renders
- **THEN** it SHALL preserve the out-of-window meaning with a distinct overflow marker treatment
- **AND** it SHALL NOT silently clamp the marker as if it occurred exactly at Fajr begin or Fajr end

#### Scenario: No active wake anchor is available
- **GIVEN** the hero has Fajr begin and Fajr end times but no active wake or planned wake anchor
- **WHEN** the range visual renders
- **THEN** it SHALL show the begin time, horizontal bar, and end time
- **AND** it SHALL NOT show a wake marker

#### Scenario: Fajr data is unavailable
- **GIVEN** the hero lacks resolved Fajr begin or Fajr end display text
- **WHEN** the home hero renders
- **THEN** it SHALL show a calm missing-data fallback
- **AND** it SHALL NOT render a guessed range bar or guessed marker position

### Requirement: Morning Hero preserves v0.2 visual hierarchy and accessibility
The home hero SHALL keep the date line and relation line in matching secondary typography, vertically center the alarm icon and AM/PM with the large time digits, and expose the range visual's full meaning through accessibility.

#### Scenario: Default text stop renders hierarchy
- **GIVEN** the user is at the default text-size stop
- **WHEN** the home hero renders
- **THEN** the date line SHALL use the same visual style as the v0.1 date line
- **AND** the relation line SHALL match the date line style
- **AND** the primary wake row SHALL remain the strongest text element
- **AND** the alarm icon and AM/PM marker SHALL be optically centered with the wake time digits

#### Scenario: VoiceOver reads range meaning
- **GIVEN** the hero has resolved Fajr begin and Fajr end values
- **WHEN** VoiceOver focuses the hero
- **THEN** the accessibility label SHALL include date, relative day, wake state, wake relation, Fajr begin time, and Fajr end time
- **AND** the visible range bar SHALL NOT be the only indicator of Fajr begin/end meaning

#### Scenario: Larger text stop needs more space
- **GIVEN** the user chooses a larger supported text-size stop
- **WHEN** the Morning Hero content needs more vertical room
- **THEN** the hero region SHALL grow
- **AND** the Weekly Fajrcast card SHALL move down
- **AND** no essential date, wake, relation, Fajr time, or range-marker meaning SHALL be clipped
