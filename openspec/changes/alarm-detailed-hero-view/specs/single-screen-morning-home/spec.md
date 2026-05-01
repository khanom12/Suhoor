## ADDED Requirements

### Requirement: Alarm detail opens as a hero-style selected-morning editor
The system SHALL present a selected Morningcast day detail as a focused hero-style editor for that date, reusing the same wake resolution and daily override pipeline as the Home hero.

#### Scenario: User opens a Morningcast day
- **GIVEN** the user is viewing the next 10 Morningcast list
- **WHEN** the user opens a specific day
- **THEN** the detail screen SHALL show the selected Gregorian date and Hijri date separated by a centered dot
- **AND** the detail screen SHALL show the primary wake time or a quiet state
- **AND** the detail screen SHALL show boundary-relative wake text for active wake modes
- **AND** the detail screen SHALL NOT show location in the date line

#### Scenario: User adjusts an active wake
- **GIVEN** the selected day is in Fajr or Early mode
- **WHEN** the user drags the wake adjustment slider
- **THEN** the primary wake time and relative wake text SHALL update immediately
- **AND** releasing the slider SHALL commit a date-specific override through the existing scheduling pathway

#### Scenario: User selects a wake mode
- **GIVEN** the selected day detail is visible
- **WHEN** the user selects Fajr, Early, or Quiet
- **THEN** the selected mode SHALL update through the same quick wake mode override path used by the Home hero
- **AND** downstream schedule snapshots SHALL be refreshed by the existing resolver flow

#### Scenario: Quiet mode is selected
- **GIVEN** the selected day is in Quiet mode
- **WHEN** the detail screen renders
- **THEN** the primary display SHALL read "Quiet Mode"
- **AND** the relative text SHALL clearly indicate that no wake alarm will ring for this date
- **AND** the wake adjustment slider region SHALL remain visually stable while becoming inactive or fixed-height
- **AND** purpose controls SHALL be hidden

#### Scenario: Early mode has a purpose
- **GIVEN** the selected day is in Early mode
- **WHEN** the detail screen renders
- **THEN** the screen SHALL show a compact purpose control with only Fast and Tahajjud as user-selectable purposes
- **AND** the screen SHALL NOT show Fast + Tahajjud as a purpose option

#### Scenario: Early mode is used for fasting
- **GIVEN** the selected day is in Early mode with Fast purpose
- **WHEN** the detail screen renders
- **THEN** the screen SHALL show a compact fast-type control
- **AND** the default fast type SHALL be the strongest fasting opportunity for that date when one exists
- **AND** the default fast type SHALL be Voluntary fast when no opportunity exists
- **AND** user-selected fast-type overrides SHALL persist only for that date

#### Scenario: Ramadan behavior is shown
- **GIVEN** the selected day is Ramadan
- **WHEN** the detail screen renders in an active wake mode
- **THEN** the fast type SHALL be locked to Ramadan fast
- **AND** Fajr adhan SHALL remain enabled and locked on for that date
- **AND** Ramadan SHALL NOT be presented as a configurable source or rule

#### Scenario: Ramadan quiet mode is selected
- **GIVEN** the selected day is Ramadan
- **WHEN** the user selects Quiet
- **THEN** the wake alarm SHALL be suppressed for that date
- **AND** Fajr adhan SHALL remain enabled for Ramadan
- **AND** the screen SHALL show a compact locked note that Fajr adhan remains on

#### Scenario: Active mode audio is editable
- **GIVEN** the selected day is in Fajr or Early mode
- **WHEN** the detail screen renders
- **THEN** the screen SHALL show a compact audio control for Wake alarm and Fajr adhan behavior
- **AND** Fajr mode SHALL offer Fajr adhan, Wake alarm, and Both where allowed
- **AND** Early mode SHALL offer Wake alarm + Fajr adhan and Wake alarm only where allowed
- **AND** audio selections SHALL persist only for that date using the existing scheduling pipeline

#### Scenario: User inspects default detail content
- **GIVEN** the selected day detail is visible
- **WHEN** no explicit diagnostics view has been opened
- **THEN** the screen SHALL NOT show wake delivery status, AlarmKit status, notification fallback status, source provenance, rule explanations, trust notes, or Fajr support tables by default
