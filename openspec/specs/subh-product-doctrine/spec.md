# subh-product-doctrine Specification

## Purpose
TBD - created by archiving change define-subh-morning-system. Update Purpose after archive.
## Requirements
### Requirement: Fajr-centered product category
The system SHALL present and organize Subh as a Fajr-centered morning system for Muslims, not as a generic alarm app, fasting-only app, or broad Islamic superapp.

#### Scenario: App identity describes the product category
- **GIVEN** the user sees primary app surfaces or product documentation
- **WHEN** the product category is described
- **THEN** the language SHALL center Fajr, morning alignment, clarity, and reliable execution
- **AND** the language SHALL NOT frame the product as only arbitrary time entry or only fasting management

### Requirement: Tomorrow morning is the primary object
The system SHALL model the next meaningful morning as the primary product unit.

#### Scenario: User opens the primary app surface
- **GIVEN** the user has completed onboarding
- **WHEN** the user opens Subh
- **THEN** the first screen SHALL answer what tomorrow morning requires before asking the user to configure arbitrary times

### Requirement: Contexts layer onto one morning engine
The system SHALL treat fasting, Ramadan, holidays, Qada, special observances, travel, work constraints, masjid alignment, reliability state, and temporary overrides as context flags on one morning model.

#### Scenario: A fasting context applies
- **GIVEN** a morning has a fasting or observance context
- **WHEN** the system resolves that morning
- **THEN** the fasting context SHALL modify the same resolved morning object
- **AND** the system SHALL NOT create a parallel fasting wake engine for that morning

### Requirement: Doctrine rejects guilt and engagement traps
The system SHALL optimize for morning clarity, dignity, privacy, and reliable execution rather than shame, guilt, maximal engagement, or notification volume.

#### Scenario: User misses a morning
- **GIVEN** the user missed or dismissed a wake flow
- **WHEN** Subh explains the result
- **THEN** the copy SHALL be operational and respectful
- **AND** the system SHALL NOT use guilt-heavy or manipulative language

