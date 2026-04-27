# single-screen-morning-home Delta

## Modified Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a 10-item Morningcast list.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the Weekly Fajrcast
- **AND** it SHALL show the next 10 Morningcast items

#### Scenario: Home renders on devices with status cutouts
- **GIVEN** the home is shown on a device with a Dynamic Island, notch, or status bar
- **WHEN** the user scrolls to the top of the home
- **THEN** hero and Fajrcast content SHALL remain below readable safe-area spacing
- **AND** no important card title, chart label, or selected-day callout SHALL be clipped by the system status area

#### Scenario: Fajrcast chart appears on home
- **GIVEN** the Weekly Fajrcast card is visible
- **WHEN** the user scans the chart
- **THEN** the card SHALL make clear that the plotted markers represent wake times
- **AND** the selected day marker SHALL be visually distinct from inactive days
- **AND** chart labels SHALL have sufficient contrast against the glass surface

#### Scenario: Floating settings control is visible
- **GIVEN** the 10-item Morningcast list is scrollable
- **WHEN** the user reaches the lower rows
- **THEN** bottom content padding SHALL keep list content from being covered by the floating settings button

### Requirement: Cards navigate to details
The system SHALL allow the user to open detail surfaces from home cards while keeping settings available from the floating home settings control.

#### Scenario: User taps a home card
- **GIVEN** the Subh home is visible
- **WHEN** the user taps Tomorrow Morning, Weekly Fajrcast, or a Morningcast item
- **THEN** the app SHALL navigate to a relevant detail screen
- **AND** settings SHALL remain reachable from the floating settings control
