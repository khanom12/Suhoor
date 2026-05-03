## OpenSpec Setup and Validation

- [x] Read repo guidance and current OpenSpec state.
- [x] Confirm no existing active planning-horizon/intention-anchoring capability owns this exact domain.
- [x] Create `planning-horizon-intention-anchoring` change.
- [x] Validate `openspec validate planning-horizon-intention-anchoring --strict` before code changes.

## Current Implementation Audit

- [x] Audit `ScheduledDateSource`, source resolver, Hijri adjustment, active-window, and delivery handoff anchors.
- [x] Identify previous morning-resolution and delivery pieces to reuse.
- [x] Re-check tests/build commands after implementation.

## Model Reuse / Model Additions

- [x] Add compatible planning anchor metadata to existing scheduled-date sources.
- [x] Add resolved provenance anchor metadata.
- [x] Add calendar/review metadata for Hijri movement explanations.
- [x] Avoid adding a duplicate planning store.

## Horizon Separation

- [x] Add a planning-window snapshot adapter that separates visible, editable, active scheduled, and historical date keys.
- [x] Preserve `visibleDays` vs `scheduledDays` as the delivery boundary.
- [x] Ensure display-only rows do not become durable records.

## Intention Anchoring

- [x] Represent Gregorian-date, Hijri-date, observance, weekday, Hijri-month-window, default-setting, immediate-alarm, and completion-history anchors.
- [x] Keep future observance/Hijri anchors movable.
- [x] Keep Gregorian-date anchors fixed.
- [x] Keep completed history fixed.

## Hijri Adjustment and Review

- [x] Record anchor/review metadata when future Hijri anchored plans move.
- [x] Preserve date-specific overrides for moved future Hijri plans where existing logic supports it.
- [x] Do not move completion history.

## Morning Resolution Handoff

- [x] Thread anchor metadata through resolved provenance into the canonical morning pipeline.
- [x] Keep generated default days out of durable user intention records.

## Delivery Handoff

- [x] Confirm delivery plans only `scheduledDays`.
- [x] Add/adjust tests for visible-only rows not scheduling.
- [x] Ensure delivery failure cannot rewrite planning anchors.

## Tests

- [x] Anchor persistence/defaulting tests.
- [x] Hijri movement versus Gregorian fixed-date tests.
- [x] Display horizon versus active scheduled horizon test.
- [x] Completion/history immobility test.
- [x] Relevant regression tests for delivery and morning status mapping.

## Validation / Build

- [x] Run `openspec validate planning-horizon-intention-anchoring --strict`.
- [x] Run relevant focused tests.
- [x] Run an app build or documented equivalent.
- [x] Run `git diff --check`.

## Cleanup / Commit / Push

- [x] Review changed files for unrelated noise.
- [x] Commit with a clear message.
- [x] Merge or fast-forward to `main` as appropriate.
- [x] Push `main` without force-push.
