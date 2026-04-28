## ADDED Requirements

### Requirement: Home Weekly Fajrcast uses temporary inspection
The Subh home Weekly Fajrcast card SHALL temporarily inspect visible days during chart gestures and return to the resting focus when interaction ends.

#### Scenario: Home card snap-back after scrub
- **GIVEN** the Subh home Weekly Fajrcast is visible
- **WHEN** the user scrubs to a non-resting visible day and releases
- **THEN** the card SHALL return to the resting next-alarm focus
- **AND** the week pill, visible days, Fajr band, and y-axis scale SHALL remain unchanged

#### Scenario: Home card keeps static overlay during scrub
- **GIVEN** the Subh home Weekly Fajrcast shows a static elapsed overlay
- **WHEN** the user inspects another visible day
- **THEN** the overlay SHALL remain anchored to the resting focus boundary
