## MODIFIED Requirements

### Requirement: Weekly Fajrcast In-Chart Fajr Boundary Labels

The Weekly Fajrcast compact chart SHALL show `Fajr begins` and `Fajr ends` labels as readable annotations attached near their corresponding Fajr boundary lines without sitting directly on top of those lines or plot boundaries.

#### Scenario: Boundary labels follow rendered boundary tangent

- **WHEN** the compact chart renders `Fajr begins` and `Fajr ends` labels
- **THEN** each label SHALL rotate from the local rendered tangent of its corresponding boundary path
- **AND** the renderer SHALL NOT use a fixed decorative angle unrelated to the rendered boundary line.

#### Scenario: Boundary labels clear their boundary strokes

- **WHEN** the renderer places a Fajr boundary label
- **THEN** it SHALL compute label separation from the nearest edge of the rotated label box
- **AND** the rotated label box SHALL clear the corresponding Fajr boundary stroke by at least the minimum boundary clearance
- **AND** the label SHALL remain close enough to read as an annotation for that boundary.

#### Scenario: Boundary labels avoid plot edges

- **WHEN** a boundary label is anchored near the leading side of the compact plot
- **THEN** the rotated label box SHALL preserve leading plot-edge clearance after rotation
- **AND** it SHALL avoid touching the top or bottom plot boundary wherever possible
- **AND** plot-edge clarity SHALL take priority over decorative placement.

#### Scenario: Fajr begins side responds to pre-Fajr wake pattern

- **WHEN** the resting Weekly Fajrcast wake pattern places relevant active wake markers before Fajr begins
- **THEN** the `Fajr begins` label SHALL sit below the Fajr-begin boundary
- **AND** this placement SHALL avoid the pre-Fajr marker lane above the line
- **AND** the label SHALL NOT move with temporary scrub focus.

#### Scenario: Default label sides remain stable

- **WHEN** the visible week is quiet, has no active wake markers, or relevant wake markers sit inside the Fajr window
- **THEN** `Fajr begins` SHALL sit above its boundary
- **AND** `Fajr ends` SHALL sit below its boundary in normal states.
