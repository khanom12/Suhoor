## ADDED Requirements

### Requirement: Context and tag presentation are adapters
Primary Morning Context and Shared Day Tag Presentation SHALL consume the canonical resolved morning graph without creating a second resolver, scheduler, or analytics source.

#### Scenario: Presentation is generated
- **GIVEN** the morning engine has resolved a `ResolvedDaySnapshot`
- **WHEN** shared tags or primary context are generated
- **THEN** the presentation layer SHALL consume `ResolvedDayPurpose`, resolved wake state, and existing snapshot fields
- **AND** it SHALL NOT recalculate prayer times, observance compatibility, wake scheduling, required actions, completion credit, or analytics credit

#### Scenario: Opportunity-only date is presented
- **GIVEN** a resolved date has an opportunity
- **AND** the resolved intention is default Fajr
- **WHEN** presentation adapters generate tags or context copy
- **THEN** the date SHALL remain opportunity-only
- **AND** presentation SHALL NOT turn it into Suhoor, a planned fast, a fast-completion requirement, or a completed credit

#### Scenario: Quiet overlay is presented
- **GIVEN** a resolved date has Quiet selected
- **AND** the date also has an underlying opportunity or selected purpose
- **WHEN** presentation adapters generate compact and expanded context
- **THEN** Quiet MAY suppress compact delivery-oriented tags
- **AND** it SHALL preserve the underlying day meaning in expanded or accessible presentation
