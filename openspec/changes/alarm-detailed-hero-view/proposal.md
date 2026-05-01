# Alarm Detailed Hero View

## Summary
Replace the current alarm day detail presentation with a calm hero-style editor for one selected morning, reusing the existing wake resolution, quick-mode, slider, and daily override pipeline.

## Motivation
The detailed alarm screen should feel like the Home hero expanded into its own focused screen. It should answer what morning this is, what time the user will be woken, and how to adjust that specific day without exposing delivery diagnostics, provenance, or unrelated settings.

## Scope
- Render the selected morning with Gregorian and Hijri date context instead of location context.
- Reuse or extract Home hero wake display, relative text, adjustment slider, and quick mode selector behavior.
- Support `Fajr`, `Early`, and `Quiet` states through the same daily override and scheduling pathway used by the Home hero.
- Show compact purpose context only for Early, Ramadan, and fasting-opportunity cases.
- Keep the detail screen visually aligned with the Home liquid-glass background and frosted surfaces.
- Add focused coverage for active, early, quiet, Ramadan, and fasting-opportunity presentation states where practical.

## Non-Goals
- Do not create a second alarm resolver, scheduler, or persistence model.
- Do not add global alarm settings or recurring plan management.
- Do not show AlarmKit, fallback notification, reliability, source, rule, or calculation diagnostics by default.
- Do not add full fasting-purpose management or religious-source education to this screen.
