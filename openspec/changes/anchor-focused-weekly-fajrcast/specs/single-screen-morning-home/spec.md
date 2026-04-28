## ADDED Requirements

### Requirement: Weekly Fajrcast separates anchor day from focused day
The compact Weekly Fajrcast snapshot SHALL expose a centered anchor day and a focused day independently.

#### Scenario: Anchor day defines visible window
- **GIVEN** a compact Weekly Fajrcast anchor day is resolved
- **WHEN** the compact snapshot is built
- **THEN** the visible days SHALL remain anchor day minus 3 through anchor day plus 3
- **AND** the anchor day SHALL be the fourth visible column
- **AND** the snapshot SHALL expose the anchor day key separately from the focused day key

#### Scenario: Initial focus uses anchor
- **GIVEN** no explicit focused day exists
- **WHEN** the compact snapshot is built
- **THEN** the focused day SHALL be the anchor day
- **AND** the callout, guide, marker emphasis, footer, and accessibility value SHALL describe the anchor day

### Requirement: Weekly Fajrcast scrubbing changes focus without recentering
The compact Weekly Fajrcast chart SHALL keep the same seven visible dates while the user inspects visible days.

#### Scenario: User focuses another visible day
- **GIVEN** the compact chart displays the anchored seven-day window
- **WHEN** the user taps, presses, drags, scrubs, or uses an accessible action to focus another visible day
- **THEN** the focused day SHALL change to that visible day
- **AND** the visible dates SHALL remain unchanged
- **AND** the week pill SHALL remain unchanged
- **AND** the Fajr band and x-axis labels SHALL remain unchanged
- **AND** the focused guide, focused marker treatment, callout, footer, and accessibility value SHALL update to the focused day

#### Scenario: User scrubs beyond an edge
- **GIVEN** the compact chart has seven visible days
- **WHEN** interaction moves beyond the left or right edge
- **THEN** focus SHALL clamp to the first or seventh visible day
- **AND** the card SHALL NOT load an eighth day
- **AND** the card SHALL NOT recenter around the edge day

### Requirement: Weekly Fajrcast footer describes the focused day
The compact Weekly Fajrcast footer SHALL always describe the focused day, not the anchor day unless the anchor day is focused.

#### Scenario: Non-center focused day
- **GIVEN** the anchored week remains unchanged
- **AND** the focused day is a non-center visible day
- **WHEN** the footer renders
- **THEN** the primary line SHALL show Fajr begin/end for the focused day
- **AND** the secondary line SHALL describe the focused day's alarm, off state, or available status

### Requirement: Weekly Fajrcast v2 product change is documented
The OpenSpec change SHALL document the v2 product distinction between anchor day and focused day and the current implementation boundary for future no-alarm/quiet marker policies.

#### Scenario: Change is reviewed
- **GIVEN** the OpenSpec change is inspected
- **WHEN** reviewers read the proposal and design artifacts
- **THEN** they SHALL find the anchor/focus product distinction
- **AND** they SHALL find the no-alarm/quiet marker policy boundary noted as future data-contract work unless exposed by the morning engine
