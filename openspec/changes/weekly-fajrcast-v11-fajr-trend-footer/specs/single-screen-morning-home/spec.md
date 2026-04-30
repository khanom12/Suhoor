## MODIFIED Requirements

### Requirement: Weekly Fajrcast Compact Footer

The Wake surface SHALL render the Weekly Fajrcast compact footer as a week-level Fajr trend/context summary, not as a focused-day Fajr-time readout and not as a weekly alarm-plan summary.

#### Scenario: Footer primary explains Fajr-begin trend

- **WHEN** the compact snapshot has resolved Fajr begin times for the first and last visible days
- **THEN** the footer primary text SHALL describe whether Fajr begins earlier, later, or around the same time by the end of the anchored visible week
- **AND** the trend SHALL be computed from resolved local Fajr-begin times
- **AND** the text SHALL use plain language such as `Fajr begins 6 minutes earlier by week’s end.`

#### Scenario: Footer suppresses alarm-plan summaries

- **WHEN** the visible week contains default alarms, adjusted mornings, quiet/off mornings, or no wake alarms
- **THEN** the compact footer SHALL NOT show default-alarm, adjusted-count, quiet-day, off-state, or no-alarm summary copy
- **AND** those states SHALL remain represented through markers, callouts, accessibility, detail payloads, or other non-footer surfaces.

#### Scenario: Footer suppresses routine fasting copy

- **WHEN** the visible week contains Ramadan, White Days, ordinary Monday/Thursday fasting, or no explicit fasting plan
- **THEN** the compact footer secondary text SHALL be omitted
- **AND** the compact footer SHALL NOT show generic negative copy such as `No fasting days are planned this week.`

#### Scenario: Footer secondary shows qualifying special non-Ramadan fasting context

- **WHEN** the visible week contains a resolved qualifying special non-Ramadan fasting observance such as Arafah, Ashura, or Dhul Hijjah days
- **THEN** the compact footer MAY show a concise secondary line such as `Fasting opportunity: Ashura on Friday.`
- **AND** if the user has an explicit fasting context for that qualifying observance, the line MAY use planned wording such as `Fasting planned: Arafah on Thursday.`

### Requirement: Weekly Fajrcast v11 Vertical Breathing

The Weekly Fajrcast card SHALL preserve v11 layout guardrails for the bottom focused-day callout and compact footer.

#### Scenario: Standard text-size card heights match v11 guardrails

- **WHEN** the card is rendered at the seven standard Dynamic Type stops
- **THEN** its minimum card height SHALL be at least 266, 268, 270, 272, 284, 296, and 310 points respectively
- **AND** measured content MAY grow beyond those minimums.

#### Scenario: Bottom callout spacing is balanced

- **WHEN** the bottom focused-day callout is rendered below the plot
- **THEN** the bottom callout-to-footer-divider spacing SHALL be about 5 points at the default text stop
- **AND** at smaller stops it SHALL be at least 4 points
- **AND** at larger standard stops it SHALL be at least 6 points.

#### Scenario: Footer bottom breathing space is enlarged

- **WHEN** the compact footer renders one or two visible lines
- **THEN** the final visible footer line SHALL keep enlarged bottom breathing space before the card's lower inner edge
- **AND** that space SHALL be about 20 points at the default text stop, at least 16 points at smaller stops, and at least 22 points at larger standard stops.
