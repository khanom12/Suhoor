## MODIFIED Requirements

### Requirement: Delivery consumes resolver-materialized events
The delivery layer SHALL schedule only resolver-materialized `ScheduledEvent`s from the active scheduled horizon and delivery metadata. It SHALL NOT calculate prayer boundaries, religious meaning, wake intent, wake boundary, wake time, visual tags, or completion credit.

#### Scenario: Visible-only rows are not delivery scope
- **GIVEN** the active window contains visible days that are not included in `scheduledDays`
- **WHEN** delivery planning runs
- **THEN** expected deliveries SHALL be built only from `scheduledDays`
- **AND** visible-only Next 10, Weekly Fajrcast, or month-browsing rows SHALL NOT be scheduled merely because they were displayed

#### Scenario: Hijri movement is resolved upstream
- **GIVEN** a Hijri or observance anchored plan moves after calendar adjustment
- **WHEN** delivery refreshes schedule state
- **THEN** delivery SHALL consume the re-resolved active scheduled date keys from the window builder
- **AND** it SHALL NOT decide whether the underlying anchor should move or stay fixed
