## Why

The atmospheric cloud layer is now visually stable, but its current drift is too slow for the desired home-screen feel. This change modestly increases the perceived motion while keeping the same calm, decorative top-hero atmosphere.

## What Changes

- Increase every atmospheric cloud band's horizontal motion speed to 2.5x its current speed by shortening each loop duration proportionally.
- Preserve the existing right-to-left direction, parallax depth ordering, seam-safe renderer, top-hero confinement, and Reduce Motion static positions.
- Do not change home content, cards, scheduling, alarm behavior, Fajr/suhoor calculations, settings, persistence, notifications, or AlarmKit behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `single-screen-morning-home`: Clarifies that atmospheric cloud motion may be tuned faster while preserving the relative depth/parallax ordering and Reduce Motion behavior.

## Impact

- Affected code: `Subh/UI/Components/AppAtmosphericCloudLayer.swift`.
- No API, dependency, storage, migration, alarm, scheduling, calendar, or persistence impact.
- Existing scheduled alarms, cached schedules, and persisted settings are unaffected.
