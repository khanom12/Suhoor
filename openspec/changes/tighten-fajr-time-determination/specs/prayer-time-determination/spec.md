## ADDED Requirements

### Requirement: Local calculation uses selected timezone
The system SHALL calculate local prayer boundaries using the selected location timezone for day-of-year, start-of-day, timezone offset, adjustment, and date-key behavior.

#### Scenario: Location timezone differs from device timezone
- **GIVEN** a selected location timezone that differs from the device timezone
- **WHEN** Subh calculates Fajr begin, Fajr end, or Maghrib for a local date
- **THEN** the calculation SHALL use the selected location timezone for all Gregorian date decomposition
- **AND** the resulting boundary SHALL be anchored to that selected local date.

### Requirement: Final local boundaries are rounded to minute precision
The system SHALL round adjusted local prayer boundaries to minute precision before they are stored, scheduled, or displayed.

#### Scenario: Solar calculation returns seconds
- **GIVEN** the solar algorithm returns a boundary with fractional seconds
- **WHEN** Subh applies user adjustments
- **THEN** the final boundary SHALL be rounded to the nearest minute
- **AND** scheduling SHALL NOT use arbitrary seconds from floating-point solar math.

### Requirement: Method profiles preserve canonical IDs and legacy aliases
The system SHALL model built-in prayer calculation methods as authority profiles with stable canonical IDs, display metadata, and Fajr angles while preserving legacy persisted IDs.

#### Scenario: Existing legacy method setting is loaded
- **GIVEN** persisted settings contain `northAmerica`, `makkah`, or `egyptian`
- **WHEN** Subh decodes the calculation method
- **THEN** the method SHALL resolve to the existing equivalent method profile
- **AND** newly exposed method IDs SHALL use `isna`, `ummAlQura`, or `egyptianGeneralAuthority` respectively.

#### Scenario: Current five method angles are requested
- **GIVEN** the built-in method catalog is available
- **WHEN** Subh reads the Fajr angle for MWL, ISNA, Egyptian General Authority, Karachi, or Umm al-Qura
- **THEN** it SHALL return 18.0, 15.0, 19.5, 18.0, and 18.5 degrees respectively.

### Requirement: Fajr end is resolved source data
The system SHALL resolve Fajr end as a first-class boundary in the prayer-window data layer, normally using sunrise in local-calculation mode.

#### Scenario: Local calculation resolves a valid sunrise
- **GIVEN** local calculation can resolve Fajr begin, sunrise, and Maghrib for the selected date
- **WHEN** Subh publishes the daily prayer window
- **THEN** the prayer window SHALL include adjusted Fajr begin and adjusted Fajr end
- **AND** the Fajr end source SHALL be `solarSunrise`.

### Requirement: Manual boundary adjustments are independent
The system SHALL apply Fajr begin, Fajr end, and Maghrib minute adjustments to their own boundaries without silently moving another boundary.

#### Scenario: User changes Fajr begin adjustment
- **GIVEN** Fajr end adjustment remains unchanged
- **WHEN** the user changes Fajr begin adjustment
- **THEN** the adjusted Fajr begin SHALL change by the selected minutes
- **AND** the adjusted Fajr end SHALL NOT change because of that Fajr begin adjustment.

#### Scenario: User changes Fajr end adjustment
- **GIVEN** Fajr begin adjustment remains unchanged
- **WHEN** the user changes Fajr end adjustment
- **THEN** the adjusted Fajr end SHALL change by the selected minutes
- **AND** the adjusted Fajr begin SHALL NOT change because of that Fajr end adjustment.

### Requirement: Invalid prayer windows are rejected
The system SHALL reject local prayer windows where adjusted boundaries do not maintain a valid Fajr begin, Fajr end, and Maghrib order.

#### Scenario: Adjusted boundaries are not ordered
- **GIVEN** local calculation produces adjusted boundaries where Fajr begin is not before Fajr end or Fajr end is after Maghrib
- **WHEN** Subh resolves the daily prayer window
- **THEN** the window SHALL be marked invalid or unavailable
- **AND** downstream scheduling and chart surfaces SHALL NOT receive guessed replacement boundaries.

### Requirement: Local diagnostics describe calculation inputs
The system SHALL expose local calculation diagnostics sufficient to explain method, source, adjustments, high-latitude fallback, timezone, and validation warnings.

#### Scenario: Prayer window is resolved locally
- **GIVEN** Subh resolves a local prayer window
- **WHEN** diagnostics are inspected
- **THEN** they SHALL include calculation source, method ID, method display name, Fajr angle, selected timezone, applied adjustments, high-latitude requested/applied rule, fallback-used status, and validation warnings.
