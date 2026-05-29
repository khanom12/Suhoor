## ADDED Requirements

### Requirement: Home Hero uses fixed six-slot state structure
The Home Hero SHALL render the same six physical slots across planning, Quiet, Pause, setup, active alarm, post-awake, completed, ended, and issue states.

#### Scenario: State changes do not resize the Hero
- **GIVEN** Home transitions between active Fajr, active Suhoor, Quiet, Alarms paused, rings once, active alarm, post-awake, Fajr complete, and alarm issue states
- **WHEN** the Hero updates state
- **THEN** the Hero frame height, slot baselines, text sizes, Slot 6 height, and vertical spacing SHALL remain stable
- **AND** the transition SHALL use in-place content changes such as crossfade or symbol changes rather than adding or removing vertical rows

#### Scenario: Slot order stays constant
- **GIVEN** the Home Hero is visible
- **WHEN** any supported alarm state is displayed
- **THEN** Slot 1 SHALL be location
- **AND** Slot 2 SHALL be the morning label
- **AND** Slot 3 SHALL be the primary alarm-state button or status
- **AND** Slot 4 SHALL be the alarm slider or timeline surface
- **AND** Slot 5 SHALL be one line of supporting copy
- **AND** Slot 6 SHALL be the primary action row

### Requirement: Planning Hero exposes Fajr and Suhoor selector only
The Home Hero planning state SHALL expose `Fajr | Suhoor` as the only wake-purpose selector.

#### Scenario: User scans the planning selector
- **GIVEN** the target morning is not actively ringing or executing
- **WHEN** the user views Slot 6
- **THEN** Slot 6 SHALL show `Fajr | Suhoor`
- **AND** it SHALL NOT show Quiet, Pause, Pre-Fajr, Early, Early Worship, Fast Mode, Fasting mode, or Quiet mode as selector choices

#### Scenario: Quiet is controlled by alarm-state button
- **GIVEN** the target morning is in a planning state
- **WHEN** the user opens the Slot 3 alarm-state action sheet
- **THEN** Quiet controls SHALL be available there when allowed
- **AND** selecting Quiet SHALL NOT change the wake-purpose selector into a three-option selector

### Requirement: Home Hero copy follows final alarm-state vocabulary
The Home Hero SHALL use the May 29 user-facing alarm-state and action vocabulary.

#### Scenario: Planning and silent states use approved copy
- **GIVEN** Home displays active, Quiet, paused, ring-once, setup, blocked, or issue planning states
- **WHEN** Slot 3 and Slot 5 copy are rendered
- **THEN** visible copy SHALL use terms such as `Quiet`, `Alarms paused`, `Turn on alarms`, `Set location`, `Alarm saved for 5:42 AM`, `Rings tomorrow only`, `Rings this morning only`, and `Alarm issue`
- **AND** it SHALL NOT use `Saved wake`, `Saved Fajr wake`, `Saved Suhoor wake`, `Active despite pause`, `Delivery suppressed`, or `Permission blocked` as primary user-facing Hero copy

#### Scenario: Morning label follows current phase
- **GIVEN** Home displays the target morning
- **WHEN** the morning phase changes
- **THEN** Slot 2 SHALL use `Tomorrow morning`, `This morning`, `Now`, or `Later this morning` according to the resolved phase
- **AND** Fajr end SHALL switch the Hero to the next morning

### Requirement: Active alarm Hero has one primary button
The Home Hero SHALL show exactly one active alarm action during ringing and follow-up states.

#### Scenario: First alarm rings
- **GIVEN** the first alarm for the current morning is ringing
- **WHEN** Home renders the Hero
- **THEN** Slot 2 SHALL show `Now`
- **AND** Slot 3 SHALL show `Time to wake`
- **AND** Slot 5 SHALL show `Tap when you’re awake`
- **AND** Slot 6 SHALL show one full-width `I’m awake` action
- **AND** Quiet, the Fajr/Suhoor selector, and `Stop checks` SHALL NOT be visible in Slot 6

#### Scenario: Follow-up alarm pending
- **GIVEN** a follow-up alarm is pending after the primary alarm
- **WHEN** Home renders the Hero
- **THEN** Slot 3 SHALL show `Next alarm soon`
- **AND** Slot 5 SHALL show the next-alarm timing or `Final alarm this morning`
- **AND** Slot 6 SHALL still show only `I’m awake`

### Requirement: Post-awake Hero uses contextual CTAs
After acknowledgement, the Home Hero SHALL show checked status pills and one contextual CTA at a time based on timing and purpose.

#### Scenario: Fajr acknowledgement delays prayer CTA
- **GIVEN** the user has acknowledged a Fajr alarm
- **WHEN** fewer than 60 seconds have passed since acknowledgement
- **THEN** Slot 6 SHALL NOT show `I prayed Fajr`
- **WHEN** at least 60 seconds have passed, Fajr has begun, and Fajr has not ended
- **THEN** Slot 6 SHALL show `I prayed Fajr`

#### Scenario: Suhoor acknowledgement delays fasting CTA
- **GIVEN** the user has acknowledged a Suhoor alarm before Fajr begins
- **WHEN** fewer than 60 seconds have passed since acknowledgement
- **THEN** Slot 6 SHALL NOT show `I’m fasting today`
- **WHEN** at least 60 seconds have passed and Fajr has not begun
- **THEN** Slot 6 SHALL show `I’m fasting today`

#### Scenario: Fajr begins after Suhoor
- **GIVEN** the user acknowledged Suhoor before Fajr began
- **WHEN** Fajr begins
- **THEN** the Hero SHALL show the Fajr-begun phase
- **AND** it SHALL NOT show a second `I’m awake` prompt
- **AND** it SHALL prioritize `I prayed Fajr` when the prayer CTA becomes eligible

### Requirement: Supporting Home planning rows inherit alarm-state vocabulary
The Home plan-ahead rows SHALL inherit the same resolved alarm-state vocabulary without exposing full Quiet/Pause controls inline.

#### Scenario: Next 7 row renders a paused date
- **GIVEN** a Next 7 Mornings row resolves to inherited Pause
- **WHEN** the row is displayed
- **THEN** the trailing status SHALL display `Paused`
- **AND** the row SHALL navigate to Day Detail rather than exposing a row-level Pause toggle

#### Scenario: Next 7 row renders manual Quiet
- **GIVEN** a Next 7 Mornings row resolves to manual Quiet
- **WHEN** the row is displayed
- **THEN** the trailing status SHALL display `Quiet`
- **AND** Quiet SHALL NOT appear as a middle-lane opportunity/context tag
