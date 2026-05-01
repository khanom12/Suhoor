## MODIFIED Requirements

### Requirement: Weekly Fajrcast Shared Card Surface

The Weekly Fajrcast compact card SHALL use the same grouped dark-glass surface family, divider treatment, content grid, and eyebrow-style header language as the Next 10 Mornings card while preserving its chart-first composition.

#### Scenario: Card shell matches grouped Home card family

- **WHEN** the Weekly Fajrcast card renders on the Home/Wake surface
- **THEN** it SHALL use the shared grouped app glass surface
- **AND** it SHALL NOT use a bespoke opaque or heavily tinted card shell
- **AND** its dividers and horizontal content grid SHALL visually align with the Next 10 Mornings grouped card family.

#### Scenario: Header title uses shared eyebrow style

- **WHEN** the Weekly Fajrcast header renders
- **THEN** the title SHALL read `WEEKLY FAJRCAST`
- **AND** it SHALL use the shared app eyebrow/header text role used by Next 10 Mornings
- **AND** it SHALL remain a single-line left header title.

### Requirement: Weekly Fajrcast Gregorian Header Pill

The Weekly Fajrcast header pill SHALL be Gregorian-only, fixed width for the current locale/text size, and stable across rest and active inspection.

#### Scenario: Resting pill shows anchored Gregorian range

- **WHEN** no chart inspection gesture is active
- **THEN** the pill SHALL show the anchored visible seven-day Gregorian range using full month names
- **AND** it SHALL NOT include Hijri or secondary-calendar text.

#### Scenario: Inspection pill shows weekday plus date

- **WHEN** the user is actively tapping, pressing, dragging, scrubbing, or accessibly inspecting a visible day
- **THEN** the pill SHALL show the inspected day's weekday plus Gregorian date
- **AND** the pill SHALL return to the anchored range when inspection ends.

#### Scenario: Pill width remains stable

- **WHEN** the pill switches between range mode and inspection-date mode
- **THEN** the capsule width SHALL remain stable
- **AND** it SHALL be measured from a maximum Gregorian reference for the current text size rather than resized for the current week or current scrubbed day.

### Requirement: Weekly Fajrcast Live Wake Preview

The Weekly Fajrcast compact card SHALL update live when the Morning Hero wake slider supplies a provisional wake time for a visible day.

#### Scenario: Provisional wake updates visible chart

- **WHEN** the user moves the Morning Hero wake-boundary slider
- **AND** the adjusted date is one of the seven visible Weekly Fajrcast days
- **THEN** the matching marker SHALL move to the provisional wake time before commit
- **AND** the compact y-axis scale SHALL include the provisional wake time
- **AND** the seven-day window SHALL NOT pan, recenter, or load another week.

#### Scenario: Provisional wake updates focused presentation

- **WHEN** the adjusted date is also the resting or currently inspected focus
- **THEN** the focused marker and bottom callout SHALL reflect the provisional wake time before commit.

#### Scenario: Preview does not persist itself

- **WHEN** the provisional wake is committed, cancelled, rejected, or rolled back
- **THEN** the compact card SHALL render the latest supplied resolved snapshot
- **AND** it SHALL NOT persist provisional wake values itself.

### Requirement: Weekly Fajrcast In-Chart Fajr Boundary Labels

The Weekly Fajrcast compact chart SHALL keep `Fajr begins` and `Fajr ends` labels clear of boundary strokes, plot boundaries, the focused guide, and the left-side marker lane.

#### Scenario: Begin label avoids pre-Fajr or left-marker collisions

- **WHEN** the resting wake pattern is before Fajr begins
- **OR** the default above-line begin label would collide with left-side marker geometry
- **THEN** `Fajr begins` SHALL use below-line placement
- **AND** it SHALL keep rotated-box boundary and plot-edge clearance.

#### Scenario: Boundary label geometry follows live chart state

- **WHEN** live wake preview changes marker positions or y-axis scale
- **THEN** Fajr boundary label side, angle, normal offset, and collision placement SHALL be recalculated from the live rendered chart geometry.
