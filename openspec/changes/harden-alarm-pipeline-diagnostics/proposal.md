# Harden Alarm Pipeline Diagnostics

## Summary
Prevent silent missed alarms on debug installs by making install-state reset opt-in and adding schedule diagnostics that detect when enabled mornings have no deliverable future events.

## Motivation
A recent debug install reset cleared persisted app state and pending notifications by default on every new build fingerprint. That can erase expected wake setup before the next morning and create a silent failure mode. We need clearer plumbing checks so alarm pipeline breakage is visible immediately.

## Scope
- Make debug install reset disabled by default, with explicit opt-in via environment/defaults mode.
- Log startup reset decisions to timeline diagnostics.
- Add scheduling diagnostics that check for missing deliverable events and missing pending notification requests in notification mode.
- Add/update tests for reset mode behavior.

## Out Of Scope
- Changing release build migration behavior.
- Adding new UI surfaces for diagnostics.
- Refactoring wake resolution rules.

## User Impact
Developers and testers keep configured morning alarms unless they explicitly opt into install resets, and diagnostics now surface alarm pipeline failures faster when scheduling says “Scheduled” but delivery state is empty.
