## 1. OpenSpec

- [x] 1.1 Validate the v0.2 Morning Hero range visual change in strict mode.

## 2. Presentation Contract

- [x] 2.1 Update hero display data for date-first formatting, compact Hijri token, Fajr begin/end labels, marker ratio, indicator state, and accessibility text.
- [x] 2.2 Preserve missing-data and no-marker states without inventing Fajr or wake positions.
- [x] 2.3 Add focused presentation tests for compact date, marker ratio, missing Fajr fallback, and inactive states.

## 3. SwiftUI Rendering

- [x] 3.1 Reorder hero rows and restyle the relation line to match the date line.
- [x] 3.2 Implement the compact Fajr range visual with begin/end times, subtle track, active/off/overflow marker behavior, and no marker for no-alarm states.
- [x] 3.3 Adjust icon and AM/PM alignment to be optically centered with the large wake digits.
- [x] 3.4 Preserve seven-stop dynamic type guardrails and multiline/growth behavior.

## 4. Validation

- [x] 4.1 Run focused home/presentation tests.
- [x] 4.2 Run OpenSpec strict validation and available lint/type/build checks.
