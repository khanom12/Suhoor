## 1. Presentation Contract

- [x] 1.1 Rename the relation tone semantics from endpoint red to urgent red.
- [x] 1.2 Apply urgent tone only when the rounded minutes before Fajr end are 10 or less.
- [x] 1.3 Preserve endpoint copy and inactive-state copy.

## 2. SwiftUI Rendering

- [x] 2.1 Render urgent relation text with the app's semantic danger color and normal relation text with the existing secondary treatment.

## 3. Validation

- [x] 3.1 Update focused presentation, schedule-manager, and UI assertions for v0.8 urgent relation behavior.
- [x] 3.2 Run OpenSpec strict validation, focused tests, and diff checks.
