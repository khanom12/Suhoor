## ADDED Requirements

### Requirement: Morning Hero uses v0.3 date and spacing
The home hero SHALL render the v0.3 anatomy with a full-month Gregorian/Hijri date row, the relative day label below it, the reduced relative-to-primary gap, the primary wake row, the wake relation line, and a conditional Fajr window visual.

#### Scenario: Hero has resolved Hijri date
- **GIVEN** the home snapshot has a resolved target morning and Hijri date
- **WHEN** the Morning Hero renders the date row
- **THEN** it SHALL show a weekday-free full Gregorian month date
- **AND** it SHALL show a full Hijri month date
- **AND** it SHALL separate Gregorian and Hijri text with `•`
- **AND** it SHALL NOT show compact Hijri tokens such as `ZQ12`

#### Scenario: Hero has no Hijri date
- **GIVEN** the home snapshot has a resolved target morning but no Hijri date text
- **WHEN** the Morning Hero renders the date row
- **THEN** it SHALL show the weekday-free Gregorian date without an empty delimiter

#### Scenario: Default text stop renders v0.3 spacing
- **GIVEN** the user is at the default text-size stop
- **WHEN** the Morning Hero renders
- **THEN** the spacing between the relative day label and primary wake row SHALL be roughly half of the previous 22 pt treatment
- **AND** the date line and relation line SHALL keep matching secondary typography

### Requirement: Morning Hero renders only eligible within-Fajr visual rows
The home hero SHALL render the Fajr window row only when the target morning has available Fajr begin/end times and the current wake or planned anchor is eligible for the v0.3 within-Fajr treatment.

#### Scenario: Active wake is inside Fajr window
- **GIVEN** the hero has Fajr begin time, Fajr end time, and an active wake time inside that interval
- **WHEN** the Fajr row renders
- **THEN** it SHALL show begin and end times as the only visible text in that row
- **AND** it SHALL show visible endpoint circles for Fajr begin and Fajr end
- **AND** it SHALL position an alarm icon marker according to the wake ratio

#### Scenario: No active wake anchor is available
- **GIVEN** the hero has Fajr begin and Fajr end times but no active wake or planned wake anchor
- **WHEN** the Fajr row renders
- **THEN** it SHALL show the begin time, endpoint circles, track, and end time
- **AND** it SHALL NOT show a draggable alarm icon

#### Scenario: Wake is outside Fajr window
- **GIVEN** the hero has a wake time before Fajr begin or after Fajr end
- **WHEN** the Morning Hero renders
- **THEN** it SHALL NOT show the v0.3 within-Fajr adjuster
- **AND** it SHALL keep the relation line visible

#### Scenario: Fasting day
- **GIVEN** the target morning has fasting context
- **WHEN** the Morning Hero renders
- **THEN** it SHALL hide the Fajr window visual for v0.3
- **AND** it SHALL NOT reserve an empty fifth row

#### Scenario: Fajr data unavailable
- **GIVEN** Fajr begin or Fajr end data is unavailable
- **WHEN** the Morning Hero renders
- **THEN** it SHALL show the missing-data fallback when needed
- **AND** it SHALL NOT render a guessed bar, endpoint circles, or marker position

### Requirement: Morning Hero supports immediate wake adjustment
The home hero SHALL expose the within-Fajr active alarm marker as a wake adjustment control that updates local display during interaction and commits the new wake to the resolved morning engine on release.

#### Scenario: User drags active alarm marker
- **GIVEN** the hero has an active wake alarm inside the Fajr begin/end window
- **WHEN** the user drags the alarm icon marker inside the Fajr row
- **THEN** the large primary wake time SHALL update to the tentative wake time
- **AND** the relation line SHALL update to describe the tentative wake relative to Fajr
- **AND** the dragged wake time SHALL clamp to Fajr begin and Fajr end

#### Scenario: Drag commits adjusted wake
- **GIVEN** the user has dragged the active alarm marker to a new within-Fajr wake time
- **WHEN** the user releases the drag
- **THEN** the app SHALL persist the new wake time through the existing schedule engine
- **AND** the hero SHALL reconcile with the resolved snapshot after persistence

#### Scenario: Accessible adjustment changes wake
- **GIVEN** the hero has an active wake alarm inside the Fajr begin/end window
- **WHEN** an accessibility increment or decrement action occurs on the Fajr row
- **THEN** the tentative wake time SHALL move by the configured minute step
- **AND** it SHALL clamp to Fajr begin and Fajr end
- **AND** it SHALL commit through the existing schedule engine

#### Scenario: Ineligible rows are not adjustable
- **GIVEN** the Fajr row is hidden or static because the morning is fasting, missing data, no-alarm, off, unavailable, or out-of-window
- **WHEN** assistive technology inspects the hero
- **THEN** the hero SHALL NOT expose a phantom adjustable wake control
