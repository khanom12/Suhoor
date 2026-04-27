# morning-resolution Delta

## Modified Requirements

### Requirement: Explanation is part of the resolved morning
The system SHALL store or expose enough derived state to explain why a morning resolved the way it did.

#### Scenario: User opens a morning detail
- **GIVEN** a resolved morning has a wake time based on supported Fajr end
- **WHEN** the user opens detail
- **THEN** the system SHALL explain the relevant anchor, buffer, calculation method, provider or approximation state, and any applied context flags
- **AND** it SHALL present this explanation as a daily Fajr morning plan or Fajr support window rather than as internal resolver terminology
- **AND** the explanation SHALL distinguish Fajr start from supported Fajr end so the user can understand why the wake time was selected

### Requirement: Reliability state participates in presentation
The system SHALL expose reliability state to presentation surfaces without putting scheduling logic inside SwiftUI views.

#### Scenario: Settings or daily detail needs reliability copy
- **GIVEN** permission and scheduling mode state is available from platform services
- **WHEN** a presentation surface needs reliability text
- **THEN** it SHALL consume existing scheduling or permission presentation state
- **AND** it SHALL avoid duplicating alarm scheduling decisions inside the view
