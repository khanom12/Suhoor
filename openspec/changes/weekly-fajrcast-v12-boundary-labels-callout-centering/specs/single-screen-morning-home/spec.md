## MODIFIED Requirements

### Requirement: Weekly Fajrcast In-Chart Fajr Boundary Labels

The Weekly Fajrcast compact chart SHALL show `Fajr begins` and `Fajr ends` labels as readable annotations attached to their corresponding Fajr boundary lines.

#### Scenario: Boundary labels follow rendered boundary tangent

- **WHEN** the compact chart renders `Fajr begins` and `Fajr ends` labels
- **THEN** each label SHALL rotate from the local rendered tangent of its corresponding boundary path
- **AND** the renderer SHALL NOT use a fixed decorative angle unrelated to the rendered boundary line.

#### Scenario: Boundary labels use outward normal offset

- **WHEN** the boundary labels are placed near the left side of the plot
- **THEN** `Fajr begins` SHALL sit on the outward side above the Fajr-begin boundary
- **AND** `Fajr ends` SHALL sit on the outward side below the Fajr-end boundary
- **AND** both labels SHALL remain visually attached to their boundary lines.

### Requirement: Weekly Fajrcast Bottom Callout Geometry

The Weekly Fajrcast compact chart SHALL geometrically center the bottom focused-day callout between the lower plot boundary and the footer-divider boundary.

#### Scenario: Callout pocket is geometrically balanced

- **WHEN** the compact chart computes the selected-day callout frame
- **THEN** it SHALL treat the callout as a measured block
- **AND** it SHALL position the callout so the gap above and below the block are equal within normal pixel rounding tolerance
- **AND** default Dynamic Type SHOULD use about 5 points on each side when content fits.

#### Scenario: Callout centering preserves minimum gaps

- **WHEN** scaled text would make the callout pocket too tight
- **THEN** the chart/card SHALL preserve minimum side gaps before overlap
- **AND** it SHALL grow the chart/card rather than push the callout toward only the chart or only the footer divider.
