## ADDED Requirements

### Requirement: Home Weekly Fajrcast reserves compact footer secondary text for non-Ramadan fasting
The Weekly Fajrcast compact footer SHALL show `summary.secondaryText` only when the currently focused day has an explicit non-Ramadan fasting intention/context.

#### Scenario: Ordinary focused day has no compact footer secondary
- **GIVEN** the Weekly Fajrcast is focused on an ordinary day with an active alarm
- **WHEN** the compact summary is generated
- **THEN** the primary footer text SHALL describe the focused day's Fajr begin/end times
- **AND** the secondary footer text SHALL be absent

#### Scenario: Off or skipped focused day has no compact footer secondary
- **GIVEN** the Weekly Fajrcast is focused on a day whose alarm is off or skipped
- **WHEN** the compact summary is generated
- **THEN** the primary footer text SHALL describe the focused day's Fajr begin/end times
- **AND** the secondary footer text SHALL be absent
- **AND** the off state SHALL remain represented by the selected-day callout and marker state

#### Scenario: Adjusted-only focused day has no compact footer secondary
- **GIVEN** the Weekly Fajrcast is focused on an adjusted day that is not an explicit non-Ramadan fasting day
- **WHEN** the compact summary is generated
- **THEN** the secondary footer text SHALL be absent
- **AND** adjusted context MAY remain available in compact insight, accessibility, or detail payloads

#### Scenario: Non-Ramadan fasting focused day has compact footer secondary
- **GIVEN** the Weekly Fajrcast is focused on a day with explicit fasting context
- **AND** the focused day is not tagged as Ramadan
- **WHEN** the compact summary is generated
- **THEN** the secondary footer text SHALL state that the focused subject is a fasting day
- **AND** the text SHALL NOT include an alarm-relation prefix or alarm-status clause

#### Scenario: Ramadan focused day has no compact footer secondary
- **GIVEN** the Weekly Fajrcast is focused on a day tagged as Ramadan
- **WHEN** the compact summary is generated
- **THEN** the secondary footer text SHALL be absent
- **AND** the footer SHALL NOT show repetitive Ramadan fasting copy

### Requirement: Home Weekly Fajrcast uses v9 footer-bottom breathing
The Weekly Fajrcast card SHALL reserve intentional bottom breathing space below the final visible footer line.

#### Scenario: Default text size uses v9 footer-bottom breathing
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the footer is laid out
- **THEN** the space below the final visible footer line SHALL be about 10 pt
- **AND** no blank secondary-line slot SHALL be reserved when secondary text is absent

#### Scenario: Smaller and larger text sizes keep footer breathing
- **GIVEN** the Weekly Fajrcast card is rendered at a non-default text-size stop
- **WHEN** the footer is laid out
- **THEN** smaller standard stops SHALL keep at least 8 pt below the final visible footer line
- **AND** larger standard stops SHALL keep at least 12 pt below the final visible footer line
- **AND** accessibility stops SHALL use at least `max(12 pt, 0.55 * scaledFooterLineHeight)`
