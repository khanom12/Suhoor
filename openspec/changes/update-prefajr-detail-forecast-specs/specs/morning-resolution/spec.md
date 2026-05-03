## ADDED Requirements

### Requirement: Pre-Fajr selection defaults to Tahajjud-only outside Ramadan
The shared date-specific wake-state resolver SHALL treat Pre-Fajr as a wake-before-Fajr mode whose non-Ramadan default intention is Tahajjud-only, not fasting.

#### Scenario: User selects Pre-Fajr on an ordinary non-Ramadan date
- **GIVEN** a selected date is not Ramadan
- **AND** the date is not forbidden for fasting
- **WHEN** the user selects `Pre-Fajr`
- **THEN** the date-specific override SHALL set the wake anchor to 30 minutes before Fajr begins
- **AND** the Pre-Fajr intention SHALL resolve to `Tahajjud only`
- **AND** the resolver SHALL NOT mark fasting as intended unless the user selects `Fasting`

#### Scenario: User selects Fasting after Pre-Fajr
- **GIVEN** a non-Ramadan date is in `Pre-Fajr`
- **WHEN** the user selects the `Fasting` intention
- **THEN** the date-specific override SHALL mark fasting as intended
- **AND** applicable Sunnah opportunity tags SHALL be used as the default fasting intention when available
- **AND** Voluntary fast SHALL be used when no specific opportunity applies

#### Scenario: User switches away and returns to Pre-Fajr
- **GIVEN** a date has a selected Pre-Fajr intention
- **WHEN** the user switches to `Fajr` or `Quiet` and later returns to `Pre-Fajr`
- **THEN** the resolver SHALL restore the preserved Pre-Fajr intention for that date
- **AND** Ramadan or Eid rules MAY override that preserved intention where required
- **AND** manual wake-time adjustments SHALL NOT be preserved across mode changes

### Requirement: Ramadan locks Pre-Fajr fasting intent
The shared resolver SHALL treat Ramadan dates as locked Pre-Fajr fasting dates when Pre-Fajr is selected.

#### Scenario: Ramadan date selects Pre-Fajr
- **GIVEN** the selected date is Ramadan
- **WHEN** `Pre-Fajr` is selected or restored
- **THEN** the Pre-Fajr intention SHALL be locked to `Fasting`
- **AND** the fasting intention SHALL be `Ramadan fast`
- **AND** non-Ramadan fast types and opportunity alternatives SHALL NOT be selectable

### Requirement: Quiet is the only user-facing alarm-off mode
The shared wake-state model SHALL distinguish alarm activation from audio choice.

#### Scenario: Fajr mode uses Fajr adhan audio
- **GIVEN** `Fajr` mode is selected
- **WHEN** the wake audio is Fajr adhan
- **THEN** the wake alarm SHALL remain enabled
- **AND** the date SHALL NOT be treated as alarm-off

#### Scenario: Quiet mode is selected
- **GIVEN** the user selects `Quiet`
- **WHEN** the date-specific state is resolved
- **THEN** the wake alarm SHALL be suppressed for that date
- **AND** the underlying mode and explicit Pre-Fajr intention SHALL be preserved for restoration where possible
