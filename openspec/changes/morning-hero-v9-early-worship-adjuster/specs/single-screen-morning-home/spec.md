## MODIFIED Requirements

### Requirement: Morning Hero wake-boundary adjuster supports default and early-worship windows
The Morning Hero SHALL render a compact wake-boundary range visual for eligible active wake mornings and SHALL choose the adjustment window from the resolved morning context.

#### Scenario: Ordinary wake inside Fajr window uses default mode
- **GIVEN** the resolved morning is not an intended fasting or Tahajjud morning
- **AND** the active wake time is inside Fajr begins through Fajr ends
- **WHEN** the Morning Hero renders the wake-boundary row
- **THEN** it SHALL show Fajr begin and Fajr end as the visible boundary times
- **AND** it SHALL render endpoint circles at both ends
- **AND** dragging SHALL clamp between Fajr begin and Fajr end
- **AND** non-endpoint relation copy SHALL say `Wake up {X} min before Fajr ends`

#### Scenario: Intended fasting wake before Fajr uses early-worship mode
- **GIVEN** the resolved morning has intended fasting, Ramadan fasting support, Qada/custom fast support, or another resolved intended fasting state
- **AND** final-third start and Fajr begin are available
- **AND** the active wake time is inside final-third start through Fajr begins
- **WHEN** the Morning Hero renders the wake-boundary row
- **THEN** it SHALL show final-third start and Fajr begin as the visible boundary times
- **AND** it SHALL render a left vertical line/tick and a right endpoint circle
- **AND** dragging SHALL clamp between final-third start and Fajr begin
- **AND** non-endpoint relation copy SHALL say `Wake up {X} min before Fajr begins`

#### Scenario: Intended Tahajjud wake before Fajr uses early-worship mode
- **GIVEN** the resolved morning has intended Tahajjud
- **AND** final-third start and Fajr begin are available
- **AND** the active wake time is inside final-third start through Fajr begins
- **WHEN** the Morning Hero renders the wake-boundary row
- **THEN** it SHALL use the early-worship visual and relation rules

#### Scenario: Early-worship endpoints use dedicated copy
- **GIVEN** the early-worship adjuster is visible
- **WHEN** the wake time is clamped to final-third start
- **THEN** the relation line SHALL say `Wake up for the last third of the night`
- **WHEN** the wake time is clamped to Fajr begins
- **THEN** the relation line SHALL say `Wake up as Fajr begins`
- **AND** it SHALL NOT say `Wake up 0 min before Fajr begins`

#### Scenario: Missing final-third data hides early-worship visual
- **GIVEN** the resolved morning has intended fasting or Tahajjud
- **AND** final-third start is unavailable
- **WHEN** the Morning Hero renders
- **THEN** it SHALL NOT show the early-worship adjuster
- **AND** it SHALL NOT invent a final-third boundary

#### Scenario: Fasting opportunity alone does not activate early-worship mode
- **GIVEN** the morning only has fasting opportunity tags and is not resolved as intended fasting
- **WHEN** the Morning Hero renders
- **THEN** it SHALL NOT use the early-worship adjuster

### Requirement: Morning Hero urgent relation tone uses v0.9 threshold
The Morning Hero SHALL use urgent red relation tone only when the rounded wake time is 14 minutes or less before Fajr ends.

#### Scenario: Fourteen-minute warning uses urgent red
- **GIVEN** the active or tentative wake time is 14 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the relation line
- **THEN** the relation line SHALL use urgent red tone

#### Scenario: Fifteen-minute wake remains normal
- **GIVEN** the active or tentative wake time is 15 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the relation line
- **THEN** the relation line SHALL use normal tone
