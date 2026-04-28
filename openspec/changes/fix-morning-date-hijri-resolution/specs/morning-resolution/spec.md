## MODIFIED Requirements

### Requirement: Morning window anchors to the real current day
The system SHALL resolve the active morning window from the user's real current day in the selected timezone, not from sparse legacy scheduled-date sources.

#### Scenario: Migrated profile opens the app outside Ramadan
- **GIVEN** a persisted profile was previously in legacy compatibility activation mode
- **AND** today is outside Ramadan
- **WHEN** the app resolves the active morning window
- **THEN** the window SHALL include today and the next contiguous mornings
- **AND** home labels, Hijri labels, and prayer-time presentation SHALL correspond to those real calendar days
- **AND** the system SHALL NOT anchor "today" to a future Ramadan date.
