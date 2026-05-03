## ADDED Requirements

### Requirement: Home hero exposes Pre-Fajr quick mode
The Morning Hero SHALL present the shared quick wake-state selector as `Pre-Fajr`, `Fajr`, and `Quiet` in that order.

#### Scenario: Ordinary Fajr morning renders
- **GIVEN** the next target morning has no stronger explicit Pre-Fajr, Ramadan, or Quiet state
- **WHEN** the Home hero renders
- **THEN** the quick selector SHALL show `Pre-Fajr`, `Fajr`, and `Quiet`
- **AND** `Fajr` SHALL be selected
- **AND** the wake relation SHALL use the default Fajr-end wording

#### Scenario: User selects Pre-Fajr outside Ramadan
- **GIVEN** the target morning is not Ramadan and fasting is not locked
- **WHEN** the user selects `Pre-Fajr`
- **THEN** the hero SHALL route the intent through the shared wake-state resolver
- **AND** the resulting wake SHALL be 30 minutes before Fajr begins
- **AND** the Pre-Fajr intention SHALL default to `Tahajjud only`
- **AND** the early-worship range visual SHALL render when final-third start and Fajr begin are available

#### Scenario: Quiet mode renders without layout collapse
- **GIVEN** the user selects `Quiet`
- **WHEN** the Home hero renders the resolved state
- **THEN** the primary row SHALL say `Quiet mode`
- **AND** the moon icon SHALL remain visible when available
- **AND** the Fajr begin/end visual SHALL be static and non-interactive when Fajr data is available

### Requirement: Alarm Detailed View mirrors the Home hero mode model
The Alarm Detailed View SHALL use the same `Pre-Fajr | Fajr | Quiet` mode labels, order, selector treatment, slider behavior, and resolver path as the Home hero.

#### Scenario: Detail view title and hero context render
- **GIVEN** a selected date is opened from the forecast
- **WHEN** Alarm Detailed View appears
- **THEN** the navigation title SHALL be `Detailed View for the Day`
- **AND** the selected Gregorian and Hijri date SHALL appear directly above the primary wake row
- **AND** location and relative-day hero lines SHALL NOT appear in the detail hero

#### Scenario: Detail Fajr mode has no opportunities
- **GIVEN** a selected non-Ramadan date has no Sunnah fasting opportunities
- **WHEN** `Fajr` mode is selected
- **THEN** the context card SHALL state that there are no Sunnah fasting opportunities for this day
- **AND** it MAY say the user can choose `Pre-Fajr` and select `Fasting` for another fast type
- **AND** it SHALL NOT show source, delivery, rule, fallback, trust, or reliability sections

#### Scenario: Detail Pre-Fajr Tahajjud-only mode
- **GIVEN** a selected non-Ramadan date is in `Pre-Fajr`
- **AND** the Pre-Fajr intention is `Tahajjud only`
- **WHEN** the context card renders
- **THEN** it SHALL say the user is waking before Fajr for Tahajjud only
- **AND** it SHALL keep fasting opportunities informational
- **AND** it SHALL hide the fasting-intention selector

#### Scenario: Detail Pre-Fajr Fasting mode
- **GIVEN** a selected non-Ramadan date is in `Pre-Fajr`
- **AND** the Pre-Fajr intention is `Fasting`
- **WHEN** compatible Sunnah fasting opportunities exist
- **THEN** the selected fasting intention SHALL default to all applicable opportunity chips
- **AND** choosing Qada, Vow, Kaffarah, or Other SHALL replace the opportunity chips with the selected fast-type chip
- **AND** choosing Voluntary fast SHALL return to opportunity chips when opportunities exist

#### Scenario: Detail reset action appears
- **GIVEN** the selected date has date-specific user adjustments
- **WHEN** the context card renders
- **THEN** it SHALL show a prominent `Reset to Defaults` action
- **AND** reset SHALL restore the date's default state through the existing date-specific override path

### Requirement: Next 10 Mornings is collapsed by default
The Home surface SHALL show the `NEXT 10 MORNINGS` card collapsed by default with the header visible and rows hidden.

#### Scenario: Home first renders
- **GIVEN** forecast data is available
- **WHEN** the Home surface first appears
- **THEN** the `NEXT 10 MORNINGS` header SHALL be visible
- **AND** the ten forecast rows SHALL be hidden until the user expands the card

#### Scenario: User expands the card
- **GIVEN** the `NEXT 10 MORNINGS` card is collapsed
- **WHEN** the user activates the header or expansion affordance
- **THEN** the card SHALL show the ten forecast rows when ready
- **AND** row taps SHALL continue to open the selected day detail view
- **AND** expansion SHALL NOT mutate wake mode, intention, overrides, scheduling, or alarm delivery
