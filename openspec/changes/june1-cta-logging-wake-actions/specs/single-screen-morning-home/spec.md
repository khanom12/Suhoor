## MODIFIED Requirements

### Requirement: May 31 Hero presentation
The Home Hero and Detail hero-like alarm panel SHALL use the active morning model for morning label, alarm-state control, slider feedback, active wake CTAs, and purpose selection.

#### Scenario: Hero shows active Suhoor wake CTA
- **GIVEN** Today Morning has an active Suhoor wake session with awake still unconfirmed
- **WHEN** the Home Hero renders
- **THEN** the primary Hero CTA SHALL be `I’m Awake for Suhoor`
- **AND** it SHALL NOT log Fajr prayer or fast completion when tapped

#### Scenario: Hero shows active Fajr wake CTA
- **GIVEN** Today Morning has an active Fajr wake session with awake still unconfirmed
- **WHEN** the Home Hero renders
- **THEN** the primary Hero CTA SHALL be `I’m Awake for Fajr`
- **AND** it SHALL NOT render `I Prayed Fajr` at the same time

#### Scenario: Hero shows next pending wake-check time
- **GIVEN** an active wake session has a primary attempt that has fired or been dismissed without explicit awake confirmation
- **AND** a later wake check remains pending
- **WHEN** the Home Hero renders the primary time
- **THEN** it SHALL show the next pending wake-check time
- **AND** it SHALL NOT show the stale initial alarm time
- **AND** it SHALL NOT show `No time available` when prayer-time and wake-session data are valid

### Requirement: Sentence-based context card
The primary context card SHALL be the explanatory layer below the Hero and SHALL use sentence-based copy plus a compact action area for logging and early-awake actions.

#### Scenario: Context card shows Fajr prayer action after cooldown
- **GIVEN** a Fajr wake session has explicit awake confirmation
- **AND** Fajr is still in-window
- **AND** Fajr prayer is unresolved
- **WHEN** the 1.5 second post-awake cooldown has elapsed
- **THEN** the context-card action area SHALL show `I Prayed Fajr`
- **AND** the Hero SHALL NOT show `I’m Awake for Fajr` for that morning

#### Scenario: Context card hides prayer action during cooldown
- **GIVEN** the user just tapped `I’m Awake for Fajr`
- **WHEN** the 1.5 second anti-double-tap cooldown is still active
- **THEN** the context-card action area SHALL NOT show `I Prayed Fajr`

#### Scenario: Context card shows early Suhoor awake action before Suhoor window
- **GIVEN** the local time is after midnight and before the Suhoor window begins
- **AND** Today Morning has a Suhoor wake plan with awake still unconfirmed
- **WHEN** the context-card action area renders
- **THEN** it SHALL include `I’m Already Awake for Suhoor`
- **AND** tapping it SHALL require confirmation before mutating delivery

#### Scenario: Context card shows early Fajr awake action before Fajr begins
- **GIVEN** the local time is after midnight and before Fajr begins
- **AND** Today Morning has a Fajr wake plan or Fajr-start delivery with awake still unconfirmed
- **WHEN** the context-card action area renders
- **THEN** it SHALL include `I’m Already Awake for Fajr`
- **AND** tapping it SHALL require confirmation before mutating delivery

#### Scenario: Context card shows compact late Fajr check/X prompt
- **GIVEN** Fajr prayer completion is late-eligible and unresolved
- **WHEN** the context-card action area renders
- **THEN** it SHALL show `I prayed Fajr earlier today?` or `I prayed Fajr yesterday morning?`
- **AND** it SHALL provide compact check and X controls for explicit yes and explicit no

#### Scenario: Context card shows compact fast completion check/X prompt
- **GIVEN** fast completion is eligible and unresolved after Maghrib or after midnight rollover
- **WHEN** the context-card action area renders
- **THEN** it SHALL show `I completed my fast today?` or `I completed my fast yesterday?`
- **AND** it SHALL provide compact check and X controls for explicit yes and explicit no
