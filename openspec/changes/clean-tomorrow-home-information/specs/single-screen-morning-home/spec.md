## ADDED Requirements

### Requirement: Tomorrow hero prioritizes actionable morning information
The Subh home hero SHALL show tomorrow identity, compact date, wake time, meaningful wake status, and one concise wake relationship without duplicating ordinary/default context.

#### Scenario: Ordinary tomorrow morning renders
- **GIVEN** tomorrow has a resolved ordinary wake plan
- **WHEN** the Subh home hero renders
- **THEN** it SHALL show `Tomorrow`, a compact date, the wake alarm time, `Wake alarm`, and the wake relationship
- **AND** it SHALL NOT show ordinary/default context labels or provider diagnostic text in the hero

#### Scenario: Meaningful context applies
- **GIVEN** tomorrow has a fasting, Qada, Tahajjud, changed, skipped, or fixed-wake state
- **WHEN** the Subh home hero renders
- **THEN** it SHALL show a short status or detail that identifies that meaningful state
- **AND** it SHALL limit any context chips to non-redundant actionable chips

### Requirement: Weekly Fajrcast supports tomorrow without repeating it
The compact Weekly Fajrcast home card SHALL select tomorrow by default when tomorrow exists in the active window and SHALL avoid repeating the selected wake relationship as footer copy.

#### Scenario: Tomorrow is in the weekly window
- **GIVEN** the active Fajr window contains tomorrow
- **WHEN** the compact Weekly Fajrcast snapshot is built for the home
- **THEN** its selected day SHALL be tomorrow

#### Scenario: No meaningful weekly signal exists
- **GIVEN** the week has no DST, adjusted, fasting, or similar meaningful summary signal
- **WHEN** the compact Weekly Fajrcast summary renders
- **THEN** it SHALL show neutral week-level copy
- **AND** it SHALL NOT repeat the selected day's wake relationship

### Requirement: Morningcast starts after the hero morning
The home Morningcast list SHALL exclude today and tomorrow so it supports the hero rather than repeating it.

#### Scenario: Morningcast entries are built
- **GIVEN** resolved schedule entries include today, tomorrow, and later mornings
- **WHEN** the home Morningcast entries are selected
- **THEN** the list SHALL start after tomorrow
- **AND** it SHALL still respect the configured maximum Morningcast count

#### Scenario: Future row has no exception
- **GIVEN** a future Morningcast row has an ordinary enabled wake plan
- **WHEN** the row renders on the home surface
- **THEN** it SHALL show compact date and wake time
- **AND** it SHALL omit redundant ordinary/default subtitle text
