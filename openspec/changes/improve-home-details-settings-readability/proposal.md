# Improve Home, Details, And Settings Readability

## Summary
Improve the existing premium gradient/glass Subh UI without redesigning the app. The change focuses on making the next morning easier to understand: daily details must clearly explain Fajr start, wake time, supported end, wake rule, and delivery reliability; home must respect safe areas and clarify that Fajrcast shows wake-time pattern; settings must become readable, structured, and reliability-oriented.

## Motivation
Subh’s primary job is to help the user understand and trust the next meaningful Fajr morning. Current surfaces are close visually, but several details weaken trust:

- The daily detail header can show wake and Fajr start in a way that makes the wake look late, even when it is correctly 30 minutes before supported Fajr end.
- Internal copy such as “supported end marker” and “resolved from” leaks implementation language.
- Home chart labels can be clipped or hard to interpret, especially near the Dynamic Island/status area.
- Settings currently has weak readability and row structure, with status pills competing against titles.
- Reliability exists, but it is not prominent enough in settings or daily details.

## Scope
- Improve daily detail presentation and copy.
- Improve home safe-area spacing, Fajrcast chart labeling, selected marker clarity, and bottom padding.
- Improve settings readability, row layout, warning card copy, and neutral/accent color use.
- Add a Reliability section/summary on settings root and strengthen the existing reliability detail screen.
- Add or update focused presentation tests where behavior can be validated outside visual inspection.

## Out Of Scope
- Replacing the home visual direction.
- Changing Fajr calculation, wake scheduling, AlarmKit, notification, or permission logic.
- Renaming compatibility-bound storage, bundle identifiers, or legacy persistence keys.
- Adding new product areas or broad settings taxonomy changes beyond the requested readability and reliability cleanup.

## User Impact
The user should be able to open Subh and immediately understand:

- when they will wake,
- why that wake time was chosen,
- which Fajr boundary supports that choice,
- whether delivery is using AlarmKit or notification fallback,
- and where to fix setup if delivery is limited.
