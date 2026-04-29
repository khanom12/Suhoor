## ADDED Requirements

### Requirement: Morning Hero summarizes the next Fajr-centered morning
The home surface SHALL render a centered Morning Hero summary for the next relevant Fajr-centered morning, including relative day, date, wake state or wake time, wake relation or status, and the Fajr begin/end window whenever those values are available.

#### Scenario: Active wake plan is available
- **GIVEN** the home snapshot has resolved an active wake plan for the next relevant morning
- **AND** the snapshot has Gregorian date, Hijri date, wake time, relation text, Fajr begin, and Fajr end strings
- **WHEN** the home hero renders
- **THEN** it SHALL show the relative day label
- **AND** it SHALL show `Gregorian date • Hijri date`
- **AND** it SHALL show the wake time as the primary largest value with an alarm-state indicator
- **AND** it SHALL show relation text that names `Fajr begins` or `Fajr ends`
- **AND** it SHALL show the exact Fajr begin/end line

#### Scenario: Hijri date is unavailable
- **GIVEN** the home snapshot has no Hijri date text for the target morning
- **WHEN** the home hero renders its date line
- **THEN** it SHALL show the Gregorian date without an empty delimiter

#### Scenario: Wake plan is inactive or unavailable
- **GIVEN** the home snapshot describes a no-alarm, alarm-off, quiet, or unavailable wake state
- **WHEN** the home hero renders
- **THEN** it SHALL show visible primary text describing that state
- **AND** it SHALL NOT show a guessed wake time
- **AND** it SHALL use status or fallback relation text that does not pretend an active alarm exists

#### Scenario: Fajr window data is unavailable
- **GIVEN** the home snapshot lacks resolved Fajr begin or Fajr end display text for the target morning
- **WHEN** the home hero renders
- **THEN** it SHALL show a calm missing-data fallback
- **AND** it SHALL NOT invent Fajr begin, Fajr end, or relation offset values in SwiftUI

### Requirement: Morning Hero preserves readable dynamic layout
The home surface SHALL allow all readable Morning Hero text to scale across the seven standard iPhone text-size stops and grow the hero region before clipping, truncating, or overlapping the Weekly Fajrcast card.

#### Scenario: Default text stop renders hero hierarchy
- **GIVEN** the user is at the default text-size stop
- **WHEN** the home hero renders
- **THEN** the primary wake row SHALL be the strongest text element
- **AND** the relative day, date, relation, and Fajr-window lines SHALL remain readable and centered
- **AND** the hero SHALL sit directly on the background rather than inside a visible card

#### Scenario: Larger text stop needs more space
- **GIVEN** the user chooses a larger supported text-size stop
- **WHEN** the Morning Hero content needs more vertical room
- **THEN** the hero region SHALL grow
- **AND** the Weekly Fajrcast card SHALL move down
- **AND** no essential date, wake, relation, or Fajr-window text SHALL be clipped

#### Scenario: Narrow width wraps secondary lines
- **GIVEN** the device width or localized text makes the date or Fajr-window line too long for one line
- **WHEN** the home hero renders
- **THEN** the date and Fajr-window lines SHALL prefer wrapping over clipping
- **AND** the primary wake value SHALL remain visually centered as one group

### Requirement: Morning Hero exposes one accessibility summary
The home hero SHALL expose a coherent accessibility summary containing the target day, date, wake state, relation when available, and Fajr begin/end values when available.

#### Scenario: VoiceOver reads an active wake plan
- **GIVEN** the hero has an active wake plan and resolved Fajr window
- **WHEN** VoiceOver focuses the hero
- **THEN** the accessibility label SHALL describe the relative day, Gregorian and Hijri date, wake alarm time, wake relation, Fajr begin time, and Fajr end time
- **AND** the alarm icon SHALL NOT be the only accessible indicator of wake state

#### Scenario: VoiceOver reads a non-active wake state
- **GIVEN** the hero has no-alarm, alarm-off, quiet, or unavailable wake state
- **WHEN** VoiceOver focuses the hero
- **THEN** the accessibility label SHALL describe that state in text
- **AND** it SHALL include any available Fajr begin/end information without implying an active alarm
