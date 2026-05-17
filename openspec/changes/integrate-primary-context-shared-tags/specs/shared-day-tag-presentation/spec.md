## ADDED Requirements

### Requirement: Shared tags are presentation outputs
The system SHALL derive shared visible and accessible day tags from the resolved morning graph, with `ResolvedDayPurpose` as the source for day meaning, selected intention, and opportunity separation.

#### Scenario: Surface requests tags for a resolved day
- **GIVEN** a resolved day has a `ResolvedDayPurpose`
- **WHEN** a Home, Next 7 Days, Alarm Detail, or accessibility surface requests tag presentation
- **THEN** the system SHALL return a shared tag snapshot derived from the resolved purpose
- **AND** the surface SHALL NOT infer opportunity, fasting intention, Ramadan, forbidden-day, or Quiet meaning from raw tag strings alone

#### Scenario: Tags are rendered
- **GIVEN** a shared tag is visible on a surface
- **WHEN** the user sees the tag
- **THEN** the tag SHALL represent resolved presentation meaning only
- **AND** the tag SHALL NOT become analytics truth, completion credit, or resolver input

### Requirement: MVP wake-mode vocabulary is normalized
The shared tag presentation SHALL use `Suhoor`, `Fajr`, and `Quiet` as the active MVP wake-mode vocabulary.

#### Scenario: Selected Suhoor day renders compact tags
- **GIVEN** a resolved day has a selected Suhoor or fasting intention
- **WHEN** compact row tags are resolved
- **THEN** the shared tag snapshot SHALL include `Suhoor` as the wake-mode tag
- **AND** it SHALL NOT use `Pre-Fajr`, `Fast`, `Early`, `Tahajjud only`, or `Other early worship` as active MVP wake-mode labels

#### Scenario: Ordinary opportunity-only day renders compact tags
- **GIVEN** a resolved day has a fasting opportunity but the intention is default Fajr
- **WHEN** compact row tags are resolved
- **THEN** the shared tag snapshot SHALL include `Fajr`
- **AND** it SHALL NOT include `Suhoor`

#### Scenario: Quiet day renders compact tags
- **GIVEN** a resolved day has Quiet selected
- **WHEN** compact row tags are resolved
- **THEN** the shared tag snapshot SHALL show `Quiet` as the compact visible tag
- **AND** it SHALL preserve underlying meaningful tags for expanded or accessibility output when they exist

### Requirement: Opportunity and intention tags remain distinct
The shared tag presentation SHALL distinguish opportunity-only context from selected fasting purpose.

#### Scenario: Arafah is available but not selected
- **GIVEN** a resolved day has an Arafah opportunity
- **AND** the resolved intention is default Fajr
- **WHEN** tags are resolved for a compact row
- **THEN** the visible tags SHALL represent `Fajr` plus Arafah opportunity where the surface allows it
- **AND** the visible tags SHALL NOT imply a planned Suhoor fast

#### Scenario: Qada is selected on a White Days opportunity
- **GIVEN** a resolved day has a White Days opportunity
- **AND** the resolved fasting purpose is Qada
- **WHEN** tags are resolved for expanded context
- **THEN** the visible or accessible tags SHALL include Qada as the selected purpose
- **AND** they SHALL preserve White Days as day meaning
- **AND** they SHALL NOT imply White Days completion credit

### Requirement: Suppression rules are surface-specific
The shared tag presentation SHALL preserve full resolved meaning while allowing each surface to suppress visible tags for density.

#### Scenario: Ramadan date has other computed opportunities
- **GIVEN** a resolved day is Ramadan
- **WHEN** compact or expanded tags are resolved
- **THEN** Ramadan SHALL suppress alternative Sunnah opportunity tags from active visible presentation
- **AND** Ramadan SHALL remain the visible locked fasting context

#### Scenario: Monday opportunity appears in compact row
- **GIVEN** a resolved day is only a Monday or Thursday opportunity
- **AND** the user has not selected Suhoor
- **WHEN** Next 7 Days compact row tags are resolved
- **THEN** the shared tag snapshot MAY hide the Monday or Thursday opportunity from visible compact tags
- **AND** it SHALL keep the opportunity available to expanded context or accessibility when useful

### Requirement: Tag accessibility preserves hidden meaning
The shared tag snapshot SHALL expose an accessibility summary that includes visible tags and suppressed meaningful tags when those hidden tags affect user understanding.

#### Scenario: Compact row suppresses a lower-priority tag
- **GIVEN** compact density hides a meaningful opportunity tag
- **WHEN** the row accessibility label is built
- **THEN** the accessibility summary SHALL include the hidden opportunity where it does not mislead the user
- **AND** it SHALL preserve whether the opportunity is selected or opportunity-only
