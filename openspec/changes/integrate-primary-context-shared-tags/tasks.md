## 1. Documentation and OpenSpec

- [x] 1.1 Place all four attached specification documents under `docs/specs/`.
- [x] 1.2 Update the working spec index with the new shared tag and primary context specs plus integration notes.
- [x] 1.3 Create OpenSpec proposal, design, delta specs, and implementation tasks for the change.

## 2. Shared Presentation Layer

- [x] 2.1 Add shared day tag presentation models and resolver output derived from `ResolvedDayPurpose`.
- [x] 2.2 Add primary morning context presentation models and compact/expanded builders derived from the shared tag snapshot.
- [x] 2.3 Preserve opportunity-only, selected purpose, Ramadan, forbidden-day, and Quiet-overlay distinctions in copy and accessibility.

## 3. Surface Integration

- [x] 3.1 Update Next 7 Days tag resolution to consume the shared tag snapshot while preserving existing row layout.
- [x] 3.2 Add compact Primary Morning Context between the Home Hero and Next 7 Days when visible.
- [x] 3.3 Update Alarm Detail context copy to reuse expanded Primary Morning Context.

## 4. Tests and Validation

- [x] 4.1 Add focused tests for shared tags and primary context across opportunity-only, selected Suhoor, Qada-on-opportunity, Ramadan, forbidden-day, and Quiet-overlay cases.
- [x] 4.2 Run OpenSpec validation for `integrate-primary-context-shared-tags`.
- [x] 4.3 Run the relevant Xcode test suite or the narrowest available Swift validation command.
- [x] 4.4 Review the diff for presentation-only scope and absence of alarm delivery, prayer calculation, persistence, or analytics source changes.
